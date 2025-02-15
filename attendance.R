library(dplyr)
library(ggplot2)
library(googlesheets4)
library(readr)

fetch.attendance <- function (cache = FALSE) {
  file.path <- "attendance.csv"
  if (cache & file.exists(file.path)) {
    return(read_csv(file.path))
  }
  columns <- data.frame(
    name = c("Attendee", "Actual?", "Event", "Date", "Location", "Note", "From", "To", "Ever a member?", "Contemporary status"),
    type = c("c",        "c",       "c",     "D",    "c",        "c",    "D",    "D",  "l",              "c")
  )
  data <- read_sheet(
    "https://docs.google.com/spreadsheets/d/18VXvuxgnlPdGizA4prGbejZdAbWws7DwK_CE-u_qdzA/",
    "Attendance",
    col_types = paste(columns$type, collapse = "")
  ) |>
    mutate(`Contemporary status` = ifelse(`Contemporary status` == "#N/A", NA, `Contemporary status`))
  write.csv(data, file.path, row.names = FALSE)
  data
}

fetch.roster <- function (cache = FALSE) {
  file.path <- "roster.csv"
  if (cache & file.exists(file.path)) {
    return(read_csv(file.path))
  }
  columns <- data.frame(
    name = c("Name", "Slack status", "Status", "From", "To", "Required?", "Calc attendance from", "Calc attendance to", "Days", "Required", "Attended", "RSVPed", "Total days", "Events/day", "Events/week", "Events/month", "Deficit/Surplus", "Last event", "Last reach-out", "Monday Strength", "Wednesday Strength", "Strength Average", "Duniwednesday", "Open Gym", "Foodie Friday", "Team Race", "Social", "Long Run", "Recorded from", "Days not recorded"),
    type = c("c",    "c",            "c",       "D",    "D", "l",         "D",                    "D",                  "d",    "d",        "d",        "d",      "d",          "d",          "d",           "d",            "d",               "D",          "D",              "d",               "d",                  "d",                "d",             "d",        "d",             "d",         "d",      "d",        "D",             "d")
  )
  data <- read_sheet(
    "https://docs.google.com/spreadsheets/d/18VXvuxgnlPdGizA4prGbejZdAbWws7DwK_CE-u_qdzA/",
    "Roster",
    col_types = paste(columns$type, collapse = "")
  )
  write.csv(data, file.path, row.names = FALSE)
  data
}

process.attendance <- function (data, roster, from_date) {
  dates_left <- roster |>
    group_by(name) |>
    summarise(date_left = max(to))
  data |>
    filter(is.na(`Actual?`)) |>
    filter(`Ever a member?`) |>
    transmute(name = Attendee, event = Event, date = Date, contemporary_status = `Contemporary status`) |>
    filter(date >= from_date) |>
    filter(!(event %in% c("Board meeting", "Board Meeting"))) |>
    left_join(dates_left, by = join_by(name)) |>
    mutate(current_status = ifelse(is.na(date_left), "Current member", "Departed"))
}

get.team.member.order <- function (data, roster, from_date) {
  # Numerator: number of practices attended
  total.attendance <- data |>
    filter(contemporary_status == "Member") |>
    group_by(name) |>
    summarise(
      total_attended = n(),
      last_event = max(date)
    )
  # Denominator: number of days of membership
  membership.dates <- roster |>
    transmute(name, membership_status, date_joined = from, date_left = as.Date(ifelse(is.na(to), Sys.Date() + 1, to))) |>
    mutate(effective_date_joined = as.Date(ifelse(date_joined < from_date, from_date, date_joined)))
  duration.of.membership <- membership.dates |>
    filter(membership_status == "Member") |>
    mutate(days = ifelse(
      from_date < date_left,
      as.numeric(date_left - effective_date_joined + 1),
      0
    )) |>
    group_by(name) |>
    summarise(days_of_membership = sum(days))
  membership.dates <- membership.dates |>
    group_by(name) |>
    summarise(
      date_joined = min(date_joined),
      date_left = max(date_left),
      effective_date_joined = min(effective_date_joined)
    )
  # Additional criterion: join and departure dates
  membership.dates |>
    left_join(duration.of.membership, by = join_by(name)) |>
    left_join(total.attendance, by = join_by(name)) |>
    mutate(total_attended = ifelse(is.na(total_attended), 0, total_attended)) |>
    mutate(attendance_per_year = ifelse(total_attended != 0, total_attended / days_of_membership, 0) * 365.24) |>
    arrange(-as.double(effective_date_joined), attendance_per_year, date_left, last_event)
}

expand.attendance.availability <- function (roster, from_date, to_date) {
  roster <- roster |> filter(membership_status == "Member")
  membership.date.ranges <- roster |>
    group_by(name) |>
    summarise(from = min(from), to = max(to))
  repeat.members <- roster |>
    group_by(name) |>
    tally() |>
    filter(n > 1) |>
    inner_join(roster, by = join_by(name)) |>
    select(!n)
  membership.gaps <- repeat.members |>
    inner_join(repeat.members, by = join_by(name), relationship = "many-to-many") |>
    select(
      name,
      membership_status = membership_status.x,
      from = from.x,
      to = to.x,
      next_membership_status = membership_status.y,
      next_from = from.y,
      next_to = to.y
    ) |>
    filter(from < next_from) |>
    group_by(name, to) |>
    summarise(next_from = min(next_from), .groups = "drop") |>
    filter(to < next_from) |>
    select(name, from = to, to = next_from)
  dates <- tibble(date = seq(from_date, to_date, "days"))
  before.or.after.membership <- dates |>
    cross_join(membership.date.ranges) |>
    filter(date < from | date >= to) |>
    select(date, name)
  during.gaps.in.membership <- dates |>
    cross_join(membership.gaps) |>
    filter(date >= from & date < to) |>
    select(date, name)
  bind_rows(before.or.after.membership, during.gaps.in.membership)
}

plot.attendance <- function (data, from, to) {
  ggplot(data, aes(date, name, fill = current_status)) +
    geom_tile() +
    geom_vline(xintercept = as.Date("2024-01-01"), linetype = "dotted") +
    scale_x_date(
      limits = c(from, to + 1),
      expand = c(0, 0),
      date_breaks = "1 month",
      date_labels = "%Y-%m"
    ) +
    scale_fill_manual(values = c("black", "red"), na.value = "white") +
    theme(
      axis.text.x = element_text(angle = -45, hjust = 0),
      axis.title.y = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      legend.position = "bottom",
      legend.title = element_blank()
    )
}

usage <- function () {
  cat("attendance.R [OPTIONS]\n")
  cat("    --cache     Use cached files\n")
  cat("    --from      Show data from this data\n")
  cat("    -h, --help  Display this message and exit\n")
}

parse_args <- function (argv) {
  from <- as.Date("2024-01-01")
  if (length(argv) > 0) {
    for (i in 1:length(argv)) {
      if (argv[[i]] == "--from") {
        from = as.Date(argv[[i + 1]])
      } else if (startsWith(argv[[i]], "--from=")) {
        from = as.Date(gsub("--from=", "", argv[[i]]))
      }
    }
  }
  list(
    cache = "--cache" %in% argv,
    from = from
  )
}

main <- function (argv = c()) {
  if ("-h" %in% argv | "--help" %in% argv) {
    usage()
  }
  args <- parse_args(argv)
  from <- args$from
  to <- Sys.Date()
  roster <- fetch.roster(args$cache) |>
    transmute(name = Name, membership_status = Status, from = From, to = To)
  attendance.availability.per.date <- expand.attendance.availability(roster, from, to)
  attendance <- fetch.attendance(args$cache) |>
    process.attendance(roster, from)
  team.member.order <- get.team.member.order(attendance, roster, from) |>
    pull(name)
  attendance <- attendance.availability.per.date |>
    full_join(attendance, by = join_by(date, name))
  event.count <- attendance |>
    group_by(name) |>
    summarise(n = sum(ifelse(is.na(event), 0, 1)))
  attendance <- attendance |>
    inner_join(event.count, by = join_by(name)) |>
    filter(n > 0)
  attendance |>
    mutate(chr_name = name, name = factor(attendance$name, levels = team.member.order)) |>
    filter(!is.na(name)) |>
    plot.attendance(from, to)
}
