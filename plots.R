library(dplyr)
library(ggplot2)
library(readr)

read.data <- function(distance.matrix.file.path) {
  read_csv(distance.matrix.file.path) |>
    filter(status == "OK")
}

distance.matrix.box.plot <- function (data) {
  ggplot(data, aes(x = reorder(destination, duration_min), y = duration_min)) +
    geom_boxplot()
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
  read.data(distance.matrix.file.path) |>
    #distance.matrix.box.plot()
    distance.matrix.histogram()
}

main("distance_matrix.csv")
