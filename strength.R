library(dplyr)
library(ggplot2)

source("attendance.R")

main <- function () {
  fetch.attendance() |>
    filter(grepl("trength", Event)) |>
    filter(is.na(`Actual?`)) |>
    filter(Date > as.Date("2023-12-31")) |>
    filter(!(Date %in% as.Date(c("2024-02-26", "2024-03-04")))) |>
    group_by(Date, Event) |>
    tally() |>
    rename(Attendance = n) |>
    ggplot(aes(x = Date, y = Attendance, col = Event)) +
    geom_point() +
    geom_smooth() +
    ggtitle("NLPT strength attendance over time")
}
