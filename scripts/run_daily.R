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
  n_sims <- 10000
  test_year <- 2027L

  test_teams <- PremPredict2::get_teams(year_season_end = test_year)

  # Get data ----
  test_schedule <- PremPredict2::get_openData_schedule(
    value_path = "https://raw.githubusercontent.com/openfootball/football.json/refs/heads/master/2026-27/en.1.json",
    table_teams = test_teams,
    value_yearEnd = test_year
  )

  test_football <- PremPredict2::get_footballData(
    value_link = "https://www.football-data.co.uk/mmz4281/2627/E0.csv",
    table_schedule = test_schedule,
    table_teams = test_teams,
    value_yearEnd = test_year
  )

  test_previousSeasons <- PremPredict2::get_data_previous(
    year_season_end = test_year,
    number_seasons = 2
  )

  test_results <- PremPredict2::get_results(
    results_thisSeason = test_football,
    results_previousSeasons = test_previousSeasons
  )

  test_game_latest <- PremPredict2::calc_game_latest(results = test_results)

  test_results_filtered <- PremPredict2::get_results_filtered(
    results = test_results,
    index_game_latest = test_game_latest,
    lookback_rounds = 82L
  )

  test_table_current <- test_football |>
    PremPredict2::calc_table_current()

  # Model the data ----
  test_results_BT2 <- PremPredict2::get_results_BT2(
    results = test_results_filtered,
    teams = test_teams,
    expanded = FALSE
  )

  test_results_BT2_tri <- PremPredict2::get_results_BT2(
    results = test_results_filtered,
    teams = test_teams,
    expanded = TRUE
  )

  test_model <- PremPredict2::get_model(results_expanded = test_results_BT2_tri)

  # Project remaining games ----
  test_predictions <- PremPredict2::get_predictions(
    object_model = test_model,
    results_thin = test_results_BT2
  )

  readr::write_csv(
    x = test_predictions,
    file = "out/predictions",
    append = FALSE
  )

  # placeholders for your functions

  # htmlwidgets::saveWidget(pp2::your_chart(res), "out/chart.html", selfcontained = TRUE)
  # htmlwidgets::saveWidget(pp2::your_table(res), "out/table.html", selfcontained = TRUE)

  file.create("out/.nojekyll")
}
