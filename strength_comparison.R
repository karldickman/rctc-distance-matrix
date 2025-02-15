library(ggplot2)
library(tidyr)

source("distance_matrix.R")

main <- function () {
  read.distance.matrix("strength_distance_matrix.csv") |>
    pivot_wider(names_from = destination, values_from = duration_min) |>
    transmute(name = name, diff = Northwest - Southeast) |>
    arrange(desc(diff)) |>
    mutate(name = factor(name, levels = name)) |>
    ggplot(aes(x = name, y = diff)) +
    geom_col() +
    theme(
      axis.ticks.x = element_blank(),
      axis.title.x = element_blank(),
      axis.text.x = element_blank()
    )
}
