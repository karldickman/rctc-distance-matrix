library(dplyr)
library(ggplot2)
library(googlesheets4)
library(readr)

fetch.attendance <- function (file.path) {
  if (file.exists(file.path)) {
    return(read_csv(file.path))
  }
  columns <- data.frame(
    name = c("Attendee", "Actual?", "Event", "Date", "Location", "Note", "Deficit/Surplus", "Last Event"),
    type = c("c",        "c",       "c",     "D",    "c",        "c",    "d",               "D")
  )
  data <- read_sheet(
    "https://docs.google.com/spreadsheets/d/18VXvuxgnlPdGizA4prGbejZdAbWws7DwK_CE-u_qdzA/",
    col_types = paste(columns$type, collapse = "")
  )
  write.csv(data, file.path, row.names = FALSE)
  data
}

process.attendance <- function (data) {
  data <- data |>
    filter(Date >= as.Date("2023-09-04")) |>
    filter(is.na(`Actual?`)) |>
    filter(!(Attendee %in% c("Allie Shaich", "Ashley Meagher", "Bisrat Tewelde", "Dorothy Davenport", "Emma Gabriel", "Heather Holt", "Heather Nielsen", "Brendy Hale", "Jamie Zamrin", "Jenna Hui", "John Danstrom", "Keenan Rebera", "Makenna Edwards", "Jesse Burns", "Joey Bomber", "Annika Sullivan", "Mark Deligero", "Molly Evjen", "Reagan Ellis", "Tanvir Kalam", "Talia Staiger", "Jacob Goertz", "David Stingle", "Andy Buhler", "Joby Olguin", "Joseph da Fonseca", "Katie Orchard", "Kirk Sutherland", "Kyle Moredock", "Lucah Katauskas", "Patrick Emami", "James Lum", "Will Kirschner", "Gabe Asch", "Katie Rominger")))
  totals <- data |>
    group_by(Attendee) |>
    summarise(n = n(), last_event = max(Date)) |>
    arrange(n, last_event)
  data |>
    left_join(totals) |>
    mutate(Attendee = factor(Attendee, levels = totals$Attendee))
}

plot.attendance <- function (data) {
  ggplot(data, aes(Date, Attendee)) +
    geom_tile() +
    theme(axis.title.y = element_blank(), axis.text.y = element_blank(), axis.ticks.y = element_blank())
}

main <- function (argv = c()) {
  if (length(argv) < 1) {
    cat("Missing required arguments\n")
    return()
  }
  attendance.file.path <- argv[[1]]
  attendance.file.path |>
    fetch.attendance() |>
    process.attendance() |>
    plot.attendance()
}
