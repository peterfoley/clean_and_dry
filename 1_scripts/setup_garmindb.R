# download and set up https://github.com/tcgoetz/GarminDB/
library(here)
library(dplyr)
library(fs)
library(keyring)
library(reticulate)
library(purrr)
use_condaenv("r-reticulate", required=TRUE)

repo_url <- "https://github.com/tcgoetz/GarminDB.git"

tool_dir <- here("external_tools","garmindb")
data_dir <- here("private_data","garmindb")
mkdir <- . %>% dir.create(., showWarnings = F, recursive = F)
dir_create(c(tool_dir, data_dir))

repo_already_cloned <- file_exists(path(tool_dir,".git/"))
if(repo_already_cloned) {
  pull_retval <- system2("git",c("-C", tool_dir, "pull"), stdout = FALSE, stderr=FALSE)
  if(!identical(pull_retval,0L)) {
    warning("update of garmindb tool failed")
  }
} else {
  clone_retval <- system2("git",c("clone",
                                  "-b", "v1.0.8",
                                  "--depth", "1",
                                  "--recursive",
                                  repo_url,tool_dir), stdout = FALSE, stderr=FALSE)
  if(!identical(clone_retval,0L)) {
    stop("clone of downloader tool failed")
  }
}


# Set up all the credentials and config json file

# get garmin creds
gc_user <- "pwfoley@gmail.com"
gc_pass <- keyring::key_get("sso.garmin.com",username=gc_user)

gcconfig <- jsonlite::fromJSON(path(tool_dir,"GarminConnectConfig.json.example"))
gcconfig$credentials$user <- gc_user
# setting config password False will fallback to Keychain that will be set later
gcconfig$credentials$password <- gc_pass

# set datest to pull everything since jan 1 2016
gcconfig$data$weight_start_date <-
  gcconfig$data$sleep_start_date <-
  gcconfig$data$rhr_start_date <-
  gcconfig$data$monitoring_start_date <-
  "01/01/2016"

gcconfig$data$download_days <- 365*5
gcconfig$data$download_latest_activities <- 20
gcconfig$data$download_all_activities <- 1000
gcconfig$data$download_days_overlap <- 3
gcconfig$copy$mount_dir <- "/dev/null"

cat(jsonlite::toJSON(gcconfig, pretty=TRUE, auto_unbox = TRUE),
    file=path("GarminConnectConfig.json"))

deps <- c("sqlalchemy", "requests", "python-dateutil", "enum34", "progressbar2", "PyInstaller", "matplotlib", "lxml")
reticulate::py_install(deps, method="conda")

tcxparser <- reticulate::import_from_path("tcxparser",path(tool_dir,"python-tcxparser"))
garmin <- reticulate::import_from_path("garmin",tool_dir)

garmin$GarminDBConfigManager$GarminDBConfig$directories$relative_to_home <- FALSE
garmin$GarminDBConfigManager$GarminDBConfig$directories$base_dir <- data_dir


debug = TRUE
test = FALSE
overwrite = FALSE
latest = FALSE # only gets the latest dataa

monitoring = TRUE
sleep = TRUE
weight = TRUE
rhr = TRUE
activities = TRUE


possible_gets <- c("weight","monitoring","sleep","rhr","activities") %>%
  set_names

results <- lapply(possible_gets, function(doget) {
  get_args <- unlist(possible_gets) %in% doget
  download_args <- c(overwrite, latest, get_args)
  dl_result <- try(do.call(garmin$download_data, as.list(download_args)))
  import_args <- c(debug, test, latest, get_args)
  import_result <- try(do.call(garmin$import_data, as.list(import_args)))
  list(download = dl_result, import = import_result)
})
print(results)
garmin$analyze_data(debug)
