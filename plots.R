library(dplyr)
library(ggplot2)
library(readr)

main <- function(args = c()) {
  if (length(args) < 1) {
    cat("Missing required argument DISTANCE_MATRIX_PATH\n")
    return()
  }
  distance.matrix.file.path = args[[1]]
  distance.matrix <- read_csv(distance.matrix.file.path)
  distance.matrix |>
    filter(status == "OK" & destination != "Willamette Boulevard") |>
    ggplot(aes(x = duration_min)) +
    geom_histogram(binwidth = 5) +
    facet_wrap(~factor(destination, levels = c(
      "Fairmount",
      "Thurman",
      "Sellwood Riverfront Park",
      "Sauvie Island",
      "Gresham",
      "Banks-Vernonia Trail",
      "Crown-Zellerbach Trail"
    )), ncol = 1)
}

main("distance_matrix.csv")
