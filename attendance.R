library(dplyr)
library(ggplot2)
library(googlesheets4)
library(readr)

fetch.attendance <- function (file.path) {
  if (file.exists(file.path)) {
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

fetch.roster <- function (file.path) {
  if (file.exists(file.path)) {
    return(read_csv(file.path))
  }
  data <- read_sheet(
    "https://docs.google.com/spreadsheets/d/18VXvuxgnlPdGizA4prGbejZdAbWws7DwK_CE-u_qdzA/",
    "Roster"
  ) |>
    select(!`Last event`)
  write.csv(data, file.path, row.names = FALSE)
  data
}

process.attendance <- function (data, roster) {
  policy.date <- as.Date("2023-09-04")
  roster <- roster |>
    group_by(Name) |>
    summarise(date_joined = min(`Date joined`)) |>
    mutate(effective_date_joined = as.Date(ifelse(
      date_joined < policy.date,
      policy.date,
      date_joined
    )))
  data <- data |>
    select(!c(`Deficit/Surplus`, `Last Event`)) |>
    inner_join(roster, by = join_by(Attendee == Name)) |>
    filter(Date >= policy.date & Date >= date_joined) |>
    filter(is.na(`Actual?`))
  totals <- data |>
    group_by(Attendee) |>
    summarise(n = n(), last_event = max(Date), effective_date_joined = min(effective_date_joined)) |>
    arrange(-as.double(effective_date_joined), n, last_event)
  data |>
    left_join(totals) |>
    mutate(Attendee = factor(Attendee, levels = totals$Attendee))
}

plot.attendance <- function (data) {
  ggplot(data, aes(Date, Attendee)) +
    geom_tile() +
    theme(axis.title.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank())
}

main <- function (argv = c()) {
  if (length(argv) < 2) {
    cat("Missing required arguments\n")
    return()
  }
  attendance.file.path <- argv[[1]]
  roster.file.path <- argv[[2]]
  attendance <- fetch.attendance(attendance.file.path)
  roster <- fetch.roster(roster.file.path)
  attendance |>
    process.attendance(roster) |>
    plot.attendance()
}
