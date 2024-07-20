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
    filter(status == "OK") |>
    ggplot(aes(x = duration_min)) +
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

main("distance_matrix.csv")
