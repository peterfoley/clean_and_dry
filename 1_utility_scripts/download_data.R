## Get all the activity data
library(here)
library(reticulate)
library(keyring)
library(purrr)
library(dplyr)
library(readr)

# get garmin creds
gc_user <- strict_config("garmin_connect_username")
gc_service <- strict_config("garmin_connect_keyring_service")
gc_pass <- keyring::key_get(gc_service, username = gc_user)

# run the downloader tool with reticulate
output_dir <- strict_config("gcexport_data_dir")
# most recent N, or "all" gets everything
max_activities <- "all"
gcexport_dir <- strict_config("exporter_tool_dir")
gcexport <- import_from_path("gcexport", path = gcexport_dir)
export_args <- c(
  "--username", gc_user,
  "--password", gc_pass,
  "--count", max_activities,
  "--format", "original",
  "--directory", output_dir,
  "--subdir", "fit",
  "--unzip"
)
res <- gcexport$main(c("gcexport.py", export_args))


# deduplicate the csv file that it created
# read_lines instead of read_csv to preserve weird quoting
# and to preserve CRLF
read_lines(file.path(output_dir, "activities.csv")) %>%
  unique %>%
  write_lines(file.path(output_dir, "activities.csv"),
              sep = "\r\n")
