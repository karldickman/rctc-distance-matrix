library(dplyr)
library(googlesheets4)
library(readr)

source("distance_matrix.R")

fetch.atthendance <- function (file.path) {
  if (file.exists(file.path)) {
    return()
  }
  columns <- data.frame(
    name = c("Attendee", "Actual?", "Event", "Date", "Location", "Note", "Deficit/Surplus", "Last Event"),
    type = c("c",        "c",       "c",     "D",    "c",        "c",    "d",               "D")
  )
  read_sheet(
    "https://docs.google.com/spreadsheets/d/18VXvuxgnlPdGizA4prGbejZdAbWws7DwK_CE-u_qdzA/",
    col_types = paste(columns$type, collapse = "")
  ) |>
    write.csv(file.path, row.names = FALSE)
}

read.attendance <- function (file.path) {
  read_csv(file.path) |>
    filter(`Deficit/Surplus` != "#N/A") |>
    filter(Event == "Long Run") |>
    filter(is.na(`Actual?`)) |>
    transmute(
      date = Date,
      location = ifelse(Location == "The Stacks", "Willamette Boulevard", Location),
      Type = coalesce(Note, "Ordinary"))
}

main <- function (args = c()) {
  if (length(args) < 2) {
    cat("Missing required arguments\n")
    return()
  }
  # Read files
  attendance.file.path <- args[[1]]
  distance.matrix.file.path <- args[[2]]
  fetch.atthendance(attendance.file.path)
  attendance <- read.attendance(attendance.file.path)
  distance.matrix <- read.distance.matrix(distance.matrix.file.path)
  # Analysis
  total.attendance <- attendance |>
    count(location, date, Type) |>
    rename(attendance = n)
  median.travel.duration <- distance.matrix |>
    group_by(destination) |>
    summarise(duration_min = median(duration_min, na.rm = TRUE)) |>
    rename(location = destination)
  proximity.attendance.relationship <- left_join(total.attendance, median.travel.duration)
  proximity.attendance.relationship |>
    ggplot(aes(x = duration_min, y = attendance, col = Type)) +
    geom_point() +
    geom_smooth(method = "lm") +
    ggtitle("Relationship between proximity and attendance") +
    xlab("Median travel duration (minutes)") +
    ylab("Total teammates attending")
}

main(c("attendance.csv", "distance_matrix.csv"))
