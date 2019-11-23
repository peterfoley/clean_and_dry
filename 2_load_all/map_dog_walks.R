# Map walks
library(furrr)

devtools::load_all("myutils")

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

all_flat <- flatten_activities(dog_walks)

library(ggmap)
basemap <- make_basemap(all_flat)

pl_dat <- all_flat %>%
  group_by(`Activity ID`) %>%
  mutate(ele_norm = (ele - min(ele))/(max(ele)-min(ele)))

walk_plot <- basemap +
  geom_path(data=pl_dat, aes(x=lon,y=lat, group=`Activity ID`, color=ele_norm)) +
  scale_colour_gradient(low="green", high="red")

ggsave(walk_plot,
       file="dog_walks.png",
       height=3.75, width=7
)
