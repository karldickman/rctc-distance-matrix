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

main <- function (argv = c()) {
  new.location.date <- as.Date("2025-03-24")
  data <- fetch.strength("--cache" %in% argv) |>
    mutate(Event = substr(Event, 1, nchar(Event) - nchar(" Strength")))
  total <- data |>
    group_by(Date, Event) |>
    tally() |>
    rename(Attendance = n) |>
    mutate(Event = paste(Event, "Total"))
  by.location <- data |>
    filter(Date >= new.location.date) |>
    group_by(Date, Event, Location) |>
    tally() |>
    rename(Attendance = n) |>
    mutate(Event = paste(Event, Location))
  bind_rows(total, by.location) |>
    mutate(Event = factor(Event, levels = c("Monday Total", "Monday Northwest", "Monday Southeast", "Wednesday Total", "Wednesday Northwest", "Wednesday Southeast"))) |>
    ggplot(aes(x = Date, y = Attendance, col = Event)) +
    geom_vline(xintercept = new.location.date, linetype = "dashed", alpha = 0.3) +
    geom_hline(yintercept = c(16.5, 20.5), linetype = "dashed", alpha = 0.3) +
    geom_point() +
    geom_smooth(se = F) +
    ggtitle("NLPT strength attendance over time") +
    theme(legend.position = "bottom") +
    guides(col = guide_legend(byrow = TRUE))
}
