## Get all the activity data
library(here)
library(reticulate)
library(keyring)
library(purrr)
library(dplyr)

# get garmin creds
gc_user <- "pwfoley@gmail.com"
key_name <- paste0("gcexport ", gc_user)
safeSecretGetter <- possibly(
  rstudioapi::askForSecret,
  otherwise=keyring::key_get("RStudio Keyring Secrets", key_name))
gc_pass <- safeSecretGetter(
    key_name,
    message = paste("Garmin Connect password for ", gc_user, ":", sep = ""),
    title = paste("Garmin Connect Password"))
if(is.null(gc_pass)) {
  stop(paste0("No password supplied for Garmin Connect user ", gc_user))
}

# run the downloader tool with reticulate
output_dir <- here("private_data/gcexport")
# most recent N, or "all" gets everything
max_activities <- "all"
gcexport_dir <- here("external_tools/garmin-connect-export")
gcexport <- import_from_path("gcexport", path = gcexport_dir)
export_args <- c(
  "--username", gc_user,
  "--password", gc_pass,
  "--count", max_activities,
  "--format", "gpx",
  "--directory", output_dir,
  "--subdir", "gpx",
  "--unzip"
)
res <- gcexport$main(c("gcexport.py",export_args))
