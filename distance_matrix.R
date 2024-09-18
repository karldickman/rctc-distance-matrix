library(dplyr)
library(ggplot2)
library(readr)
library(scales)

read.distance.matrix <- function(distance.matrix.file.path) {
  read_csv(distance.matrix.file.path) |>
    filter(status == "OK")
}

distance.matrix.box.plot <- function (data) {
  ggplot(data, aes(x = destination, y = duration_min)) +
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

usage <- function (error = NULL) {
  if (!is.null(error)) {
    cat(error, "\n")
  }
  cat("distance_matrix.R DISTANCE_MATRIX_PATH [OPTIONS]\n")
  cat("    -h, --help  Display this message and exit\n")
  opt <- options(show.error.messages = FALSE)
  on.exit(options(opt))
  stop()
}

main <- function(args = c()) {
  if ('-h' %in% args | '--help' %in% args) {
    usage()
  }
  if (length(args) < 1) {
    usage("Missing required argument DISTANCE_MATRIX_PATH\n")
  }
  distance.matrix.file.path = args[[1]]
  data <- read.distance.matrix(distance.matrix.file.path)
  quartiles <- data |>
    group_by(destination) |>
    summarise(
      median_duration_min = median(duration_min),
      third_quartile = quantile(duration_min, 0.75)
    ) |>
    arrange(median_duration_min, third_quartile)
  data$destination <- factor(data$destination, levels = quartiles$destination)
  data |>
    distance.matrix.box.plot() +
    #distance.matrix.histogram() +
    ggtitle(label = "Distribution of travel times to selected run locations")
}
