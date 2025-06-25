library(PSInetR)
library(DBI)
library(duckdb)
library(dplyr)
library(dbplyr)
library(lutz)

# Connect to database
db_path <- get_db_path()
con <- dbConnect(duckdb::duckdb(), db_path)

# Identify only automated datasets
auto_wp_all <- tbl(con, "auto_wp") |> 
  collect()

auto_only_datasets <- auto_wp_all |> 
  count(dataset_name) |> 
  filter(n > 1) |> 
  pull(dataset_name)


# 
site <- tbl(con, "study_site") |> 
  filter(dataset_name %in% auto_only_datasets) |> 
  select(-remarks, uid) |> 
  collect() |> 
  mutate(timezone = tz_lookup_coords(lat = latitude_wgs84,
                                     lon = longitude_wgs84)) 
trt <- tbl(con, "treatment") |> 
  filter(dataset_name %in% auto_only_datasets) |> 
  select(-uid) |> 
  collect()
plt <- tbl(con, "plot") |> 
  filter(dataset_name %in% auto_only_datasets) |> 
  select(-remarks, -uid) |> 
  rename(plot_leaf_area_index_m2_m2 = leaf_area_index_m2_m2) |> 
  collect()
plant <- tbl(con, "plant") |> 
  filter(dataset_name %in% auto_only_datasets) |> 
  select(-remarks, -uid) |> 
  collect()
auto_sens <- tbl(con, "auto_wp_sensor") |> 
  filter(dataset_name %in% auto_only_datasets) |> 
  select(-remarks, -uid) |> 
  collect()
auto_wp <- tbl(con, "auto_wp") |> 
  filter(dataset_name %in% auto_only_datasets) |> 
  select(-organ, -canopy_position, -uid) |> 
  collect()

# Disconnect from database
dbDisconnect(con, shutdown = TRUE)

# Join tables
all_meta <- site |>  
  full_join(trt) |> 
  full_join(plt) |> 
  full_join(plant) |> 
  full_join(auto_sens) |> 
  mutate(start_date = as.Date(start_date, tz = timezone),
         end_date = as.Date(end_date, tz = timezone))


temp <- auto_wp |> 
  left_join(site) |> 
  mutate(date = as.Date(date, tz = timezone)) |> 
  select(-colnames(site)) 

all_auto <- temp |> 
  left_join(all_meta, 
            by = join_by(individual_id,
                         plot_id,
                         sensor_id, 
                         between(date, start_date, end_date))) |> 
    # Screen out NA's
  filter(!is.na(water_potential_mean))


# Write out as csv
write_csv(all_auto, file = "data/all_auto_joined.csv")


# 
plant_sum <- plant |> 
  group_by(genus, specific_epithet) |> 
  summarize(n = n()) |> 
  arrange(desc(n))
