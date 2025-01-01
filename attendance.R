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
    name = c("Attendee", "Actual?", "Event", "Date", "Location", "Note", "Date Joined", "Date Left", "Membership"),
    type = c("c",        "c",       "c",     "D",    "c",        "c",    "D",           "D",         "c")
  )
  data <- read_sheet(
    "https://docs.google.com/spreadsheets/d/18VXvuxgnlPdGizA4prGbejZdAbWws7DwK_CE-u_qdzA/",
    "Attendance",
    col_types = paste(columns$type, collapse = "")
  )
  write.csv(data, file.path, row.names = FALSE)
  data
}

fetch.roster <- function (cache = FALSE) {
  file.path <- "roster.csv"
  if (cache & file.exists(file.path)) {
    return(read_csv(file.path))
  }
  columns <- data.frame(
    name = c("Name", "Slack status", "Status", "Required?", "Date joined", "Date left", "From", "To", "Days", "Required", "Attended", "RSVPed", "Total days", "Events/day", "Events/week", "Events/month", "Deficit/Surplus", "Last event", "Last reach-out", "Monday Strength", "Wednesday Strength", "Strength Average", "Duniwednesday", "Open Gym", "Foodie Friday", "Team Race", "Social", "Long Run"),
    type = c("c",    "c",            "c",       "l",        "D",           "D",         "D",    "D",  "d",    "d",        "d",        "d",      "d",          "d",          "d",           "d",            "d",               "D",          "D",              "d",               "d",                  "d",                "d",             "d",        "d",             "d",         "d",      "d")
  )
  data <- read_sheet(
    "https://docs.google.com/spreadsheets/d/18VXvuxgnlPdGizA4prGbejZdAbWws7DwK_CE-u_qdzA/",
    "Roster",
    col_types = paste(columns$type, collapse = "")
  ) |>
    select(!`Last event`)
  write.csv(data, file.path, row.names = FALSE)
  data
}

process.attendance <- function (data, roster, from) {
  roster <- roster |>
    group_by(Name) |>
    summarise(date_joined = min(`Date joined`), date_left = max(`Date left`)) |>
    mutate(effective_date_joined = as.Date(ifelse(
      date_joined < from,
      from,
      date_joined
    )))
  data |>
    filter(!(Event %in% c("Board meeting", "Board Meeting"))) |>
    select(!c(`Date Joined`, `Date Left`, Membership)) |>
    inner_join(roster, by = join_by(Attendee == Name)) |>
    filter(Date >= from & Date >= date_joined & (Date <= date_left | is.na(date_left))) |>
    filter(from < date_left | is.na(date_left)) |>
    filter(is.na(`Actual?`)) |>
    mutate(membership_status = ifelse(is.na(date_left), "Current member", "Departed"))
}

get.team.member.order <- function (data, roster, from) {
  totals <- data |>
    group_by(Attendee) |>
    summarise(
      total_attended = n(),
      last_event = max(Date),
      effective_date_joined = min(effective_date_joined),
      date_left = max(date_left)
    )
  never.attended <- roster |>
    filter(!(Status %in% c("Satellite", "Pause"))) |>
    filter(`Date left` >= from) |>
    left_join(data, by = join_by(Name == Attendee)) |>
    filter(is.na(Event) | Date > `Date left`) |>
    transmute(
      Attendee = Name,
      effective_date_joined = as.Date(ifelse(
        `Date joined` < from,
        from,
        `Date joined`
      )),
      date_left = `Date left`,
      total_attended = 0
    )
  totals |>
    bind_rows(never.attended) |>
    mutate(effective_date_left = as.Date(ifelse(is.na(date_left), Sys.Date(), date_left))) |>
    mutate(days_of_membership = as.double(effective_date_left - effective_date_joined) + 1) |>
    mutate(attendance_per_year = total_attended / days_of_membership * 365.24) |>
    arrange(-as.double(effective_date_joined), attendance_per_year, date_left, last_event) |>
    pull(Attendee)
}

dates.not.on.team <- function (roster, from, to) {
  had.pause <- roster |>
    filter(Status == "Pause") |>
    select(Name, `Date joined`) |>
    inner_join(select(roster, Name, `Date left`), join_by(Name == Name)) |>
    group_by(Name) |>
    summarise(`Date joined` = min(`Date joined`), `Date left` = max(`Date left`))
  had.no.pause <- roster |>
    filter(!(Name %in% had.pause$Name))
  roster <- bind_rows(had.no.pause, had.pause)
  names <- c()
  dates <- c()
  reasons <- c()
  # Had not joined team
  had.not.joined.team <- roster|>
    filter(`Date joined` >= from)
  for (i in 1:nrow(had.not.joined.team)) {
    row <- had.not.joined.team[i,]
    dates.not.joined <- from:(row$`Date joined` - 1)
    for (date in dates.not.joined) {
      names <- c(names, row$Name)
      dates <- c(dates, date)
      reasons <- c(reasons, "not yet joined")
    }
  }
  # Left team
  left.team <- roster |>
    filter(`Date left` >= from)
  for (i in 1:nrow(left.team)) {
    row <- left.team[i,]
    dates.left <- row$`Date left`:to
    for (date in dates.left) {
      names <- c(names, row$Name)
      dates <- c(dates, date)
      reasons <- c(reasons, "left team")
    }
  }
  # Combine joined and left
  dates <- as.Date(dates)
  tibble(Attendee = names, Date = dates, not_on_team_reason = reasons)
}

plot.attendance <- function (data, from, to) {
  ggplot(data, aes(Date, Attendee, fill = membership_status)) +
    geom_tile() +
    geom_vline(xintercept = as.Date("2024-01-01")) +
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
  roster <- fetch.roster(args$cache)
  from <- args$from
  to <- Sys.Date()
  not.on.team <- dates.not.on.team(roster, from, to)
  attendance <- fetch.attendance("--cache" %in% argv) |>
    process.attendance(roster, from)
  team.member.order <- get.team.member.order(attendance, roster, from)
  attendance <- bind_rows(attendance, not.on.team)
  attendance |>
    mutate(Attendee = factor(attendance$Attendee, levels = team.member.order)) |>
    filter(!is.na(Attendee)) |>
    plot.attendance(from, to)
}
