# clone or update the downloader tool
library(here)
library(fs)

source("utils/config.R")

exporter_dir <- strict_config("exporter_dir")
dir.create(exporter_dir, showWarnings = FALSE, recursive = TRUE)
repo_already_cloned <- file_exists(path(exporter_dir,".git/"))
if(repo_already_cloned) {
  pull_retval <- system2("git",c("-C", exporter_dir, "pull"), stdout = FALSE, stderr=FALSE)
  if(!identical(pull_retval,0L)) {
    warning("update of downloader tool failed")
  }
} else {
  clone_retval <- system2("git",c("clone","https://github.com/pe-st/garmin-connect-export",exporter_dir), stdout = FALSE, stderr=FALSE)
  if(!identical(clone_retval,0L)) {
    stop("clone of downloader tool failed")
  }
}

