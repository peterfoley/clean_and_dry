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
data_dir <- here("private_data/gcexport")

activities <- read_csv(file.path(data_dir,"activities.csv")) %>%
  distinct

flatten_fully <- function(alist) {
  times <- purrr::vec_depth(alist)
  for(i in seq_len(max(0,times-2))) {
    alist <- purrr::flatten(alist)
  }
  alist
}

flatten_trkpt <- function(trkpt) {
  exclude_attrs <- c("names","class")
  extra_attrs <- attributes(trkpt)
  extra_attrs <- extra_attrs[!names(extra_attrs) %in% exclude_attrs]
  c(flatten_fully(trkpt), extra_attrs)
}

gpx_to_df <- function(gpx_path) {
  xml <- xml2::read_xml(gpx_path) %>%
    xml_ns_strip()
  tracks <- xml_find_all(xml, "trk") %>%
    as_list()
  nested <- tracks %>%
    map(
      ~modify_at(., "trkseg",
        ~modify_at(.,"trkpt",. %>% flatten_trkpt) %>%
          set_names(NULL) %>%
          bind_rows(.id = "segment_in_track") %>%
          as.list) %>%
        modify_at(., c("name","type"), unlist))

  flat <- nested %>% map(. %>% flatten %>% as_tibble) %>%
    bind_rows(.id="track_in_activity") %>%
    readr::type_convert(col_types = cols())

  flat
}

km_per_mile <- 1.60934
dog_walks <- activities %>%
  filter(`Activity Name` == "Pasadena Walking",
         `Distance (km)` %>%
           between(1.25 * km_per_mile,
                   1.4 * km_per_mile)) %>%
  mutate(filename = paste0("activity_",`Activity ID`,".gpx"),
         filepath = fs::path(data_dir, "gpx", filename)) %>%
  mutate(data = future_map(filepath, gpx_to_df))

all_flat <- dog_walks %>%
  filter(`Activity ID` != 2858485459,
         `Activity ID` != 3062996451) %>%
  tidyr::unnest(col="data")

latlon_bb <- function(df) {
  # left/bottom/right/top
  c(min(df$lon), min(df$lat), max(df$lon), max(df$lat))
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
