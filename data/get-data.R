##########################
#
# Downloading daily avg temperatures from several sites around Portland, OR
#
##########################

library(rnoaa)
library(dplyr)
library(httr)
library(reshape2)

date_min <- '1980-01-01'
date_max <- as.character(Sys.Date())
#start and end date for records


station_data <- ghcnd_stations()
#create a staion object of all stations in US. Can take a while! Minutes

portland <- data.frame(id = 'portland', latitude = 45.5051, longitude = -122.6750)
#create a DF of portland's locations

nearby_portland <- meteo_nearby_stations(lat_lon_df = portland, station_data = station_data,
                      radius = 25, var = 'TMAX', year_min = 1980)
#get a list of stations near portland (using the portland DF) that collect avg temp going back to
#1960 and are within 25km of portland
#note this returns a list with a single data frame column

station_ids <- nearby_portland[[1]]$id
#extract the station ids of the stations that meet the criteria above
#because the line above returns a list containing a dataframe, this syntax is required
#in english, it is accessing the first row of the list which is a dataframe, then accessing
#the 'id' column

station_id_string <- paste(unlist(station_ids), collapse =',')
#takes the station ids and converts it into a single string separated by a , with no spaces

get_string <- 'https://www.ncei.noaa.gov/access/services/data/v1?dataset=daily-summaries'
#create the beginning of the GET string

data_types <- paste(c('TMAX', 'TMIN'), collapse = ',')
#desired measurement types. Called data types in the API

get_string <- paste(get_string, '&dataTypes=', data_types, sep = '')
get_string <- paste(get_string, '&stations=', station_id_string, sep = '')
get_string <- paste(get_string, '&startDate=', date_min, sep = '')
get_string <- paste(get_string, '&endDate=', date_max, sep = '')
get_string <- paste(get_string,
                    '&units=standard&includeStationName=true&includeStationLocation=true',
                    sep = '')
#creating the API call


weather_data <- GET(get_string)
#pull min, max temp from the stations extracted above going back to the start date defined earlier
weather_data <- tibble(content(weather_data))
#extract a dataframe from the httr GET request

col_ids <- names(weather_data)
col_ids <- col_ids[-c(length(col_ids), (length(col_ids) - 1))]
#drop the last two columns which should be the measurement values

weather_data_melted <- tibble(melt(weather_data, id.vars = col_ids,
                            variable.name = 'measurement', value.name = 'temperature'))
#convert the data into easier to display format. This will leave the date and station columns alone
#but melt the all the other columns into a single column called measurement and the value is the
#temperature reading for that row

#station_data <- inner_join(station_data, nearby_portland[[1]], by = 'id')
#not sure this is needed now as I'm moving away from RNOAA package and a straight API call
#add info about the station to the df. includes station name, lat, long, and distance from
#portland's lat and long

weather_data <- weather_data %>%
  rename_at(names(weather_data), .funs = tolower)
#convert column headers to lowercase

write.csv(weather_data, file = 'data/daily-temp-data.csv')
#write the data to a csv for faster reading of the data in other files. This script only has to be
#run when the data needs to be updated, as opposed to every time another program calls this script
