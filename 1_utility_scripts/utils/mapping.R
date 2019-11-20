# mapping-related utilities

get_all_activities <- function() {
  activity_file <- file.path(strict_config("gcexport_data_dir"),"activities.csv")
  activities <- read_csv(activity_file)
  distinct(activities)
}

get_activity_data <- function(id) {
  fit_path <- path(strict_config("gcexport_data_dir"),"fit",paste0("activity_",id,".fit"))
  fit_data <- fit::read.fit(fit_path)
  fit_data$record
}

# grab the bounding box from a dataframe with lat/long columns
latlon_bb <- function(df, lat=df$lat, lon=df$lon) {
  # left/bottom/right/top
  clean <- function(x) {
    x <- na.omit(x)
    x <- x[!near(abs(x), 180, tol=.001)]
    x
  }
  lat <- clean(lat)
  lon <- clean(lon)
  c(min(lon, na.rm=T),
    min(lat, na.rm=T),
    max(lon, na.rm=T),
    max(lat, na.rm=T))
}

# pad the bounding box to make ggmap plots prettier
pad_bb <- function(bb, lat=1.1, lon=lat) {
  center = c(lon = bb[1] + bb[3], lat = bb[2] + bb[4]) / 2
  halfwidth = c(lon = bb[3] - bb[1], lat = bb[4] - bb[2]) / 2

  c(left   = center[['lon']] - halfwidth[['lon']]*lon,
    bottom = center[['lat']] - halfwidth[['lat']]*lat,
    right  = center[['lon']] + halfwidth[['lon']]*lon,
    top    = center[['lat']] + halfwidth[['lat']]*lat
  )
}
