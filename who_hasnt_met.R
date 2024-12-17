library(dplyr)
library(tidyr)

source("attendance.R")

main <- function () {
  attendance <- fetch.attendance() |>
    filter(is.na(`Actual?`)) |>
    select(name = Attendee, event = Event, date = Date)
  common_events <- attendance |>
    inner_join(rename(attendance, other_name = name), relationship = "many-to-many") |>
    filter(name != other_name) |>
    select(event, date, name, other_name) |>
    group_by(name, other_name) |>
    summarise(events = n())
  members <- fetch.roster() |>
    filter(`Required?`) |>
    select(name = Name)
  members |>
    crossing(rename(members, other_name = name)) |>
    filter(name != other_name) |>
    left_join(common_events) |>
    filter(is.na(events)) |>
    select(!events)
}
