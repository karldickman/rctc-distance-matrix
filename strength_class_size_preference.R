library(googlesheets4)
library(dplyr)
library(ggplot2)
library(zoo)

fetch.data <- function (cache = FALSE) {
  file.path <- "class_size.csv"
  if (cache & file.exists(file.path)) {
    return(read_csv(file.path))
  }
  data <- read_sheet(
    "https://docs.google.com/spreadsheets/d/1D1FO-wNzNWsi7jEjp_eeK_CPaAIY76SQH2s75e43xrI/",
    "Response"
  ) |>
    select(c(Name, Size, Category, Score))
  write.csv(data, file.path, row.names = FALSE)
  data
}

plot.data <- function (data) {
  ggplot(data, aes(x = Size, y = Score)) +
    geom_jitter(width = 0.2, height = 0.02, alpha = 0.5) +
    geom_line(aes(y = avg, linetype = "Mean")) +
    #geom_line(aes(y = Will, linetype = "Will Jenkins")) +
    scale_linetype_manual("", values = c("Mean" = "dotted", "Will Jenkins" = "dashed")) +
    xlab("Class size") +
    ylab("−2 = too big, −1 = reasonable, 0 = ideal, −1 = too small") +
    theme(legend.position = "bottom")
}

main <- function () {
  data <- fetch.data()
  means <- data |>
    group_by(Size) |>
    summarise(avg = mean(Score))
  will <- data |>
    filter(Name == "Will Jenkins") |>
    select(Size, Will = Score)
  data |>
    inner_join(means, by = join_by(Size)) |>
    inner_join(will, by = join_by(Size)) |>
    plot.data()
}
