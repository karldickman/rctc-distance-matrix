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
    name = c("Attendee", "Actual?", "Event", "Date", "Location", "Note", "Deficit/Surplus", "Last Event"),
    type = c("c",        "c",       "c",     "D",    "c",        "c",    "d",               "D")
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

process.attendance <- function (data, roster) {
  policy.date <- as.Date("2023-09-04")
  roster <- roster |>
    group_by(Name) |>
    summarise(date_joined = min(`Date joined`), date_left = max(`Date left`)) |>
    mutate(effective_date_joined = as.Date(ifelse(
      date_joined < policy.date,
      policy.date,
      date_joined
    )))
  data <- data |>
    select(!c(`Deficit/Surplus`, `Last Event`)) |>
    inner_join(roster, by = join_by(Attendee == Name)) |>
    filter(Date >= policy.date & Date >= date_joined) |>
    filter(policy.date < date_left | is.na(date_left)) |>
    filter(is.na(`Actual?`))
  totals <- data |>
    group_by(Attendee) |>
    summarise(
      total_attended = n(),
      last_event = max(Date),
      effective_date_joined = min(effective_date_joined),
      date_left = max(date_left)) |>
    mutate(effective_date_left = as.Date(ifelse(is.na(date_left), Sys.Date(), date_left))) |>
    mutate(days_of_membership = as.double(effective_date_left - effective_date_joined) + 1) |>
    mutate(attendance_per_year = total_attended / days_of_membership * 365.24) |>
    arrange(-as.double(effective_date_joined), attendance_per_year, last_event)
  data |>
    left_join(totals) |>
    mutate(Attendee = factor(Attendee, levels = totals$Attendee), membership_status = ifelse(is.na(date_left), "Current member", "Departed"))
}

plot.attendance <- function (data) {
  ggplot(data, aes(Date, Attendee, fill = membership_status)) +
    geom_tile() +
    scale_fill_manual(values = c("black", "red")) +
    theme(
      axis.title.y = element_blank(),
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      legend.position = "bottom",
      legend.title = element_blank()
    )
}

usage <- function () {
  cat("attendance.R [OPTIONS]\n")
  cat("    --cache     Use cached files")
  cat("    -h, --help  Display this message and exit")
}

main <- function (argv = c()) {
  if ("-h" %in% argv | "--help" %in% argv) {
    usage()
  }
  attendance <- fetch.attendance("--cache" %in% argv)
  roster <- fetch.roster("--cache" %in% argv)
  attendance |>
    process.attendance(roster) |>
    plot.attendance()
}
