# Map walks
library(dplyr)
library(purrr)
library(furrr)
library(readr)
library(here)
library(fs)
library(xml2)

future::plan(future::multiprocess())

here <- here::here
gcexport_dir <- here("private_data/gcexport")
garmindb_dir <- here("private_data/garmindb")

activities <- read_csv(file.path(data_dir,"activities.csv")) %>%
  distinct

fit_from_id <- function(id) {
  fit_path <- path(garmindb_dir,"FitFiles","Activities",paste0(id,".fit"))
  fit_data <- fit::read.fit(fit_path)
  fit_data$record
}

km_per_mile <- 1.60934
dog_walks <- activities %>%
  filter(`Activity Name` == "Pasadena Walking",
         `Distance (km)` %>%
           between(1.25 * km_per_mile,
                   1.4 * km_per_mile)) %>%
  mutate(data = future_map(`Activity ID`, fit_from_id, .progress = TRUE))

all_flat <- dog_walks %>%
  filter(`Activity ID` != 2858485459,
         `Activity ID` != 3062996451) %>%
  tidyr::unnest(col="data") %>%
  mutate(ele = altitude,
         lat = position_lat,
         lon = position_long)

latlon_bb <- function(df) {
  # left/bottom/right/top
  clean <- function(x) {
    x <- na.omit(x)
    x <- x[!near(abs(x), 180, tol=.001)]
    x
  }
  lat <- clean(df$lat)
  lon <- clean(df$lon)
  c(min(lon, na.rm=T),
    min(lat, na.rm=T),
    max(lon, na.rm=T),
    max(lat, na.rm=T))
}
pad_bb <- function(bb, lat=1.1, lon=lat) {
  center = c(lon = bb[1] + bb[3], lat = bb[2] + bb[4]) / 2
  halfwidth = c(lon = bb[3] - bb[1], lat = bb[4] - bb[2]) / 2

  c(left   = center[['lon']] - halfwidth[['lon']]*lon,
    bottom = center[['lat']] - halfwidth[['lat']]*lat,
    right  = center[['lon']] + halfwidth[['lon']]*lon,
    top    = center[['lat']] + halfwidth[['lat']]*lat
  )
}

library(ggmap)
basemap <- latlon_bb(all_flat) %>%
  pad_bb(2.0,1.1) %>%
  get_map(location=., maptype="toner", source="stamen", messaging=T, zoom=16)
ggmap(basemap, extent="device") +
  geom_path(data=all_flat, aes(x=lon,y=lat, group=`Activity ID`))

pl_dat <- all_flat %>%
  group_by(`Activity ID`) %>%
  mutate(ele_norm = (ele - min(ele))/(max(ele)-min(ele)))

ggmap(basemap, extent="device") +
  geom_path(data=pl_dat, aes(x=lon,y=lat, group=`Activity ID`, color=ele_norm)) +
  scale_colour_gradient(low="green", high="red")
