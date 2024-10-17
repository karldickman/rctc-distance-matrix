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
      Type = ifelse(Note == "Big Fun Long Run", Note, NA)
    ) |>
    mutate(Type = coalesce(Type, "Ordinary"))
}

usage <- function (error = NA) {
  if (!is.na(error)) {
    cat(error, "\n")
  }
  cat("proximity_and_attendance.R DISTANCE_MATRIX_FILE_PATH\n")
  cat("    -h, --help  Display this message and exit")
  stop()
}

main <- function (args = c()) {
  if ('-h' %in% args | '--help' %in% args) {
    usage()
  }
  if (length(args) < 1) {
    usage("Missing required arguments")
  }
  # Read files
  distance.matrix.file.path <- args[[1]]
  attendance <- fetch.attendance() |>
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
    geom_jitter(height = 0, width = 0.5) +
    geom_smooth(method = "lm") +
    ylim(0, NA) +
    ggtitle("Relationship between proximity and attendance") +
    xlab("Median travel duration (minutes)") +
    ylab("Total teammates attending") +
    theme(legend.position="bottom")
}
