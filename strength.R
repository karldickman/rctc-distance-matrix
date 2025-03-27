library(dplyr)
library(ggplot2)

source("attendance.R")

fetch.strength <- function (cache = FALSE) {
  fetch.attendance(cache) |>
    filter(grepl("trength", Event)) |>
    filter(is.na(`Actual?`)) |>
    filter(Date > as.Date("2023-12-31")) |>
    filter(!(Date %in% as.Date(c("2024-02-26", "2024-03-04"))))
}

main <- function () {
  fetch.strength() |>
    group_by(Date, Event, Location) |>
    tally() |>
    rename(Attendance = n) |>
    mutate(Event = substr(Event, 1, nchar(Event) - nchar(" Strength"))) |>
    mutate(Event = paste(Event, Location)) |>
    ggplot(aes(x = Date, y = Attendance, col = Event)) +
    geom_vline(xintercept = as.Date("2025-03-24"), linetype = "dashed", alpha = 0.3) +
    geom_point() +
    geom_smooth(se = F) +
    ggtitle("NLPT strength attendance over time") +
    theme(legend.position = "bottom")
}
