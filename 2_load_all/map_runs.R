# Map walks
library(furrr)

devtools::load_all("myutils")

future::plan(future::multiprocess())

here <- here::here

km_per_mile <- 1.60934
all_flat <- get_all_activities() %>%
  filter(`Activity Name` == "Pasadena Running",
         `Distance (km)` %>%
           between(4.5 * km_per_mile,
                   6  * km_per_mile)) %>%
  mutate(data = future_map(`Activity ID`, get_activity_data, .progress = TRUE)) %>%
  flatten_activities()

smaller_area <- all_flat %>%
  group_by(`Activity ID`) %>%
  filter(min(lon) > -118.0807)

library(ggmap)
basemap <- make_basemap(smaller_area, zoom=15)

pl_dat <- all_flat %>%
  group_by(`Activity ID`) %>%
  mutate(ele_norm = (ele - min(ele))/(max(ele)-min(ele)))

run_plot <- basemap +
  geom_path(data=pl_dat, aes(x=lon,y=lat, group=`Activity ID`, color=ele_norm)) +
  scale_colour_gradient(low="green", high="red")

ggsave(run_plot,
       file="runs.png",
       height=2.5, width=7
)

