library(googlesheets4)
library(readr)

fetch.atthendance <- function (file.path) {
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

main <- function (argv = c()) {
  if (length(argv) < 1) {
    cat("Missing required arguments\n")
    return()
  }
  attendance.file.path <- argv[[1]]
  fetch.atthendance(attendance.file.path)
}
