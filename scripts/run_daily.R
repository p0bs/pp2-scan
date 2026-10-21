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

  # placeholders for your functions

  # htmlwidgets::saveWidget(pp2::your_chart(res), "out/chart.html", selfcontained = TRUE)
  # htmlwidgets::saveWidget(pp2::your_table(res), "out/table.html", selfcontained = TRUE)

  file.create("out/.nojekyll")
}
