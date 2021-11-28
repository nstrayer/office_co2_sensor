library(plumber)
library(DBI)

con <- dbConnect(RSQLite::SQLite(), "air_quality.db")


#* Echo message to check for working server
#* @get /echo
function() {
	list(msg = "Connection is working")
}

#* Add reading to db
#* @param time time of reading
#* @param co2 co2 in parts per million 
#* @param temp temperature in degrees C
#* @param humidity relative humidity in percent
#* @post /record
function(req, res, time, co2, temp, humidity) {
 dbWriteTable(con, "air_quality",  
  data.frame(
    time = as.POSIXlt(time, format = "%m/%d/%y %H:%M:%S"),
    co2 = co2, 
    temp = temp, 
    humidity = humidity),
  append = TRUE)
  return("thanks")
}

#* Get observations from database
#* @get /echo
function(nobs = 1000) {
  res <- dbGetQuery(con, paste("SELECT * FROM air_quality LIMIT", nobs))
  
  list(res = res)
}
