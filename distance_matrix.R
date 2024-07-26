library(dplyr)
library(ggplot2)
library(readr)
library(scales)
library(stringr)

read.distance.matrix <- function(distance.matrix.file.path) {
  read_csv(distance.matrix.file.path) |>
    filter(status == "OK")
}

distance.matrix.box.plot <- function (data) {
  ggplot(data, aes(x = reorder(destination, duration_min), y = duration_min)) +
    geom_boxplot() +
    scale_x_discrete(labels = label_wrap(10)) +
    xlab("Destination") +
    ylab("Median travel duration (minutes)")
}

distance.matrix.histogram <- function (data) {
  ggplot(data, aes(x = duration_min)) +
  geom_histogram(binwidth = 5) +
  facet_wrap(~factor(destination, levels = c(
    "McKenzie Building",
    "Willamette Boulevard",
    "Fairmount",
    "Sellwood Riverfront Park",
    "Thurman",
    "Germantown",
    "Lake Oswego",
    "Sauvie Island",
    "Gresham",
    "Banks-Vernonia Trail",
    "Crown-Zellerbach Trail"
  )))
}

main <- function(args = c()) {
  if (length(args) < 1) {
    cat("Missing required argument DISTANCE_MATRIX_PATH\n")
    return()
  }
  distance.matrix.file.path = args[[1]]
  read.distance.matrix(distance.matrix.file.path) |>
    mutate(across("destination", str_replace, "-", " ")) |>
    distance.matrix.box.plot() +
    #distance.matrix.histogram() +
    ggtitle(label = "Distribution of travel times to selected run locations")
}
