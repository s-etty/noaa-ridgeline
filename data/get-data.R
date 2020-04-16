##########################
#
# Downloading daily avg temperatures from several sites around Portland, OR
#
##########################

library(rnoaa)
library(dplyr)

date_min <- as.POSIXct('1960-01-01')
#start date for records

station_data <- ghcnd_stations()
#create a staion object of all stations in US. Can take a while! Minutes

portland <- data.frame(id = 'portland', latitude = 45.5051, longitude = -122.6750)
#create a DF of portland's locations

nearby_portland <- meteo_nearby_stations(lat_lon_df = portland, station_data = station_data,
                      radius = 25, var = 'TAVG', year_min = 1960)
#get a list of stations near portland (using the portland DF) that collect avg temp going back to
#1960 and are within 25km of portland
#note this returns a list with a single data frame column

station_ids <- nearby_portland[[1]]$id
#extract the station ids of the stations that meet the criteria above
#because the line above returns a list containing a dataframe, this syntax is required
#in english, it is accessing the first row of the list which is a dataframe, then accessing
#the 'id' column


station_data <- meteo_pull_monitors(monitors = station_ids, date_min = date_min, var = 'TAVG')
#pull avg temp from the stations extracted above going back to the start date defined at the top

station_data <- inner_join(station_data, nearby_portland[[1]], by = 'id')
#add info about the station to the df. includes station name, lat, long, and distance from
#portland's lat and long

write.csv(station_data, file = 'data/avg-temp-data.csv')
#write the data to a csv for faster reading of the data in other files. This script only has to be
#run when the data needs to be updated, as opposed to every time another program calls this script
