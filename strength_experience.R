source("strength.R")

main <- function () {
  strength <- fetch.strength() |>
    select(Attendee, Date)
  roster <- fetch.roster() |>
    group_by(Name) |>
    summarise(date_joined = min(From))
  start.date <- as.Date("2024-01-01")
  strength |>
    inner_join(select(strength, c(Attendee, Date)), join_by(Attendee), relationship = "many-to-many") |>
    filter(Date.y <= Date.x) |>
    rename(Date = Date.x) |>
    group_by(Attendee, Date) |>
    tally() |>
    arrange(Date, Attendee) |>
    group_by(Date) |>
    summarise(proportion_with_required_experience = sum(n >= 24) / n()) |>
    ggplot(aes(x = Date, y = proportion_with_required_experience)) +
    geom_point() +
    geom_smooth() +
    ggtitle("Development of a group of strength regulars") +
    ylab("Proportion who have attended a minimum of 24 classes")
}
