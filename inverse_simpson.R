library(dplyr)
library(lubridate)

source("attendance.R")

usage <- function () {
  cat("inverse_simpson.R [OPTIONS]\n")
  cat("    --cache     Use cached files")
  cat("    -h, --help  Display this message and exit")
}

inverse_simpson <- function (data) {
  data <- data |>
    mutate(year = year(Date), quarter = quarter(Date))
  population_size <- data |>
    group_by(year, quarter) |>
    tally() |>
    rename(population = n)
  data |>
    group_by(year, quarter, Attendee) |>
    tally() |>
    rename(name = Attendee, attendance = n) |>
    inner_join(population_size) |>
    mutate(term = (attendance / population) ^ 2) |>
    group_by(year, quarter) |>
    summarise(simpson_index = sum(term)) |>
    mutate(inverse_simpson_index = 1 / simpson_index)
}

main <- function (argv = c()) {
  if ("-h" %in% argv | "--help" %in% argv) {
    usage()
  }
  roster <- fetch.roster("--cache" %in% argv)
  from <- as.Date("2023-09-04")
  fetch.attendance("--cache" %in% argv) |>
    process.attendance(roster, from) |>
    inverse_simpson()
}
