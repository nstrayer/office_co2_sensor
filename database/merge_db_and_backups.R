# Some code for merging backup csv with database in case of failure of database
library(dplyr)
library(DBI)
setwd("database/")

con <- dbConnect(RSQLite::SQLite(), "../database/air_quality.db")
airquality_db <- tbl(con, "air_quality")

db_data <- airquality_db %>% collect()

backup_data <- read.csv("../sensing/air_quality.csv", col.names = c("time", "co2", "temp", "humidity"), stringsAsFactors = FALSE) %>%
  as_tibble() %>% 
  mutate(
    time = as.POSIXct(time, format = "%m/%d/%y %H:%M:%S"),
  )

combined_data <- db_data %>% 
  mutate(time = as.POSIXct(time, origin="1970-01-01")) %>% 
  bind_rows(backup_data) %>% 
  arrange(time) %>% 
  distinct()

 