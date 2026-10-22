# Add

is_file_unchanged <- PremPredict2::calc_unchanged(
  value_url = "https://www.football-data.co.uk/mmz4281/2627/E0.csv",
  file_local = "data/results_latest.csv"
)

force_build <- identical(Sys.getenv("FORCE_BUILD"), "true")
build <- !is_file_unchanged || force_build

# Heartbeat: changes every run, so the repo always shows activity
writeLines(
  format(Sys.time(), tz = "UTC", usetz = TRUE),
  "data/last_checked.txt"
)

if (build) {
  dir.create("out", showWarnings = FALSE)
  library(PremPredict2)
  n_sims <- 50000
  test_year <- 2027L

  test_teams <- get_teams(year_season_end = test_year)

  # Get data ----
  test_schedule <- get_openData_schedule(
    value_path = "https://raw.githubusercontent.com/openfootball/football.json/refs/heads/master/2026-27/en.1.json",
    table_teams = test_teams,
    value_yearEnd = test_year
  )

  test_football <- get_footballData(
    value_link = "https://www.football-data.co.uk/mmz4281/2627/E0.csv",
    table_schedule = test_schedule,
    table_teams = test_teams,
    value_yearEnd = test_year
  )

  test_previousSeasons <- get_data_previous(
    year_season_end = test_year,
    number_seasons = 2
  )

  test_results <- get_results(
    results_thisSeason = test_football,
    results_previousSeasons = test_previousSeasons
  )

  test_game_latest <- calc_game_latest(results = test_results)

  test_results_filtered <- get_results_filtered(
    results = test_results,
    index_game_latest = test_game_latest,
    lookback_rounds = 82L
  )

  test_table_current <- test_football |>
    calc_table_current()

  # Model the data ----
  test_results_BT2 <- get_results_BT2(
    results = test_results_filtered,
    teams = test_teams,
    expanded = FALSE
  )

  test_results_BT2_tri <- get_results_BT2(
    results = test_results_filtered,
    teams = test_teams,
    expanded = TRUE
  )

  test_model <- get_model(results_expanded = test_results_BT2_tri)

  # Project remaining games ----
  test_predictions <- get_predictions(
    object_model = test_model,
    results_thin = test_results_BT2
  )

  # readr::write_csv(
  #   x = test_predictions,
  #   file = "data/predictions.csv",
  #   append = FALSE
  # )

  # Simulate entire season ----
  test_simulations <- get_simulations(
    predictions = test_predictions,
    n_sims = n_sims,
    current_points = test_table_current$Points,
    current_gd = test_table_current$GD
  )

  # Importantance of next game ----
  test_games_next <- calc_games_next(
    teams = test_teams,
    predictions = test_predictions
  )

  test_scenarios <- get_scenarios(
    teams = test_teams,
    games_next = test_games_next,
    table_current = test_table_current,
    results_filtered = test_results_filtered,
    value_yearEnd = test_year,
    n_sims = n_sims,
    n_daemons = 3L
  )

  data_detail <- get_data_dotty(
    simulations = test_simulations,
    scenarios = test_scenarios,
    games_next = test_games_next,
    n_sims = n_sims,
    teams = test_teams
  )

  readr::write_csv(x = data_detail, file = "data/data_detail.csv")

  # output_chart <- generate_chart_dotty(data_dotty = data_detail)

  # ggplot2::ggsave(filename = "out/plot_dotty.svg", plot = output_chart)

  # htmlwidgets::saveWidget(pp2::your_chart(res), "out/chart.html", selfcontained = TRUE)
  # htmlwidgets::saveWidget(pp2::your_table(res), "out/table.html", selfcontained = TRUE)

  rmarkdown::render("README.Rmd")

  file.create("out/.nojekyll")
}
