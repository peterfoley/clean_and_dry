# Map walks
library(dplyr)
library(purrr)
library(furrr)
library(readr)
library(fs)
library(xml2)

source("utils_mapping.R")

future::plan(future::multiprocess())

here <- here::here

km_per_mile <- 1.60934
dog_walks <- get_all_activities() %>%
  filter(`Activity Name` == "Pasadena Walking",
         `Distance (km)` %>%
           between(1.25 * km_per_mile,
                   1.4 * km_per_mile)) %>%
  filter(`Activity ID` != 2858485459,
         `Activity ID` != 3062996451) %>%
  mutate(data = future_map(`Activity ID`, get_activity_data, .progress = TRUE))

all_flat <- dog_walks %>%
  tidyr::unnest(col="data") %>%
  mutate(ele = altitude,
         lat = position_lat,
         lon = position_long)

library(ggmap)
basemap <- latlon_bb(all_flat) %>%
  pad_bb(2.0,1.1) %>%
  get_map(location=., maptype="toner", source="stamen", messaging=T, zoom=16)
ggmap(basemap, extent="device") +
  geom_path(data=all_flat, aes(x=lon,y=lat, group=`Activity ID`))

pl_dat <- all_flat %>%
  group_by(`Activity ID`) %>%
  mutate(ele_norm = (ele - min(ele))/(max(ele)-min(ele)))

walk_plot <- ggmap(basemap, extent="device") +
  geom_path(data=pl_dat, aes(x=lon,y=lat, group=`Activity ID`, color=ele_norm)) +
  scale_colour_gradient(low="green", high="red")

ggsave(walk_plot,
       file="dog_walks.png",
       )
