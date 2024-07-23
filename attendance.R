library(dplyr)
library(readr)

source("distance_matrix.R")

read.attendance <- function (file.path) {
  read_csv(file.path) |>
    filter(`Deficit/Surplus` != "#N/A") |>
    filter(Event == "Long Run") |>
    filter(is.na(`Actual?`)) |>
    transmute(date = Date, location = Location, Type = coalesce(Note, "Ordinary"))
}

main <- function (args = c()) {
  if (length(args) < 2) {
    cat("Missing required arguments\n")
    return()
  }
  # Read files
  attendance.file.path <- args[[1]]
  distance.matrix.file.path <- args[[2]]
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
  proximity.attendance.relationship <- merge(total.attendance, median.travel.duration, how = "left")
  proximity.attendance.relationship |>
    ggplot(aes(x = duration_min, y = attendance, col = Type)) +
    geom_point() +
    geom_smooth(method = "lm") +
    ggtitle("Relationship between proximity and attendance") +
    xlab("Median travel duration (minutes)") +
    ylab("Total teammates attending")
}

main(c("attendance.csv", "distance_matrix.csv"))
