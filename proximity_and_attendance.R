library(dplyr)
library(googlesheets4)
library(readr)

source("attendance.R")
source("distance_matrix.R")

process.attendance <- function (attendance) {
  attendance |>
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
  attendance <- fetch.atthendance(attendance.file.path) |>
    process.attendance()
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
    geom_jitter(height = 0) +
    geom_smooth(method = "lm") +
    ylim(0, NA) +
    ggtitle("Relationship between proximity and attendance") +
    xlab("Median travel duration (minutes)") +
    ylab("Total teammates attending")
}

main(c("attendance.csv", "distance_matrix.csv"))
