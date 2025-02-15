library(dplyr)
library(ggplot2)

source("attendance.R")

fetch.strength <- function () {
  fetch.attendance() |>
    filter(grepl("trength", Event)) |>
    filter(is.na(`Actual?`)) |>
    filter(Date > as.Date("2023-12-31")) |>
    filter(!(Date %in% as.Date(c("2024-02-26", "2024-03-04"))))
}

strength.experience <- function () {
  strength <- fetch.strength() |>
    select(Attendee, Date)
  roster <- fetch.roster() |>
    group_by(Name) |>
    summarise(date_joined = min(From))
  start.date <- as.Date("2024-01-01")
  strength |>
    inner_join(select(strength, c(Attendee, Date)), join_by(Attendee), relationship = "many-to-many") |>
    filter(Date.y <= Date.x) |>
    rename(Date = Date.x) |>
    group_by(Attendee, Date) |>
    tally() |>
    arrange(Date, Attendee) |>
    group_by(Date) |>
    summarise(proportion_with_required_experience = sum(n >= 24) / n()) |>
    ggplot(aes(x = Date, y = proportion_with_required_experience)) +
    geom_point() +
    geom_smooth() +
    ggtitle("Development of a group of strength regulars") +
    ylab("Proportion who have attended a minimum of 24 classes")
}

main <- function () {
  fetch.strength() |>
    group_by(Date, Event) |>
    tally() |>
    rename(Attendance = n) |>
    ggplot(aes(x = Date, y = Attendance, col = Event)) +
    geom_point() +
    geom_smooth() +
    ggtitle("NLPT strength attendance over time")
}
