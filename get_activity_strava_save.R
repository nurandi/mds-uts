#get_activity_strava_save.r
#mengambil data strava untuk pertama kalinya
#dan menyimpan pada database

library(rvest)
library(xml2)
library(jsonlite)
library(tidyverse)

usr_id <- Sys.getenv("STRAVA_ID")

get_data <- function(type = "recentActivities", id=id){

  if(type == "recentActivities"){
    url <- paste0("https://www.strava.com/athletes/",id)
  } else {
    url <- paste0("https://www.strava.com/activities/",id)
  }
  
  out <- read_html(url) %>% 
    html_nodes("[data-react-class]") %>%
    xml_attr('data-react-props') %>%
    fromJSON() %>%
    `[[`(type)
  
  return(out)
  
}

# get recent activity
recent_act <- get_data(type = "recentActivities", id = usr_id)

data <- recent_act %>% select(id,name,type,distance,startDateLocal,elevation,movingTime)
data <- as.data.frame(data)


#convert data
data$distance <- as.integer(gsub('.{3}$', '', data$distance))
data$elevation <- gsub('.{2}$', '', data$elevation)
data$elevation <- as.integer(gsub(",", "", data$elevation))
data$startDateLocal <- as.Date(data$startDateLocal, "%B %d, %Y")

#jika startDateLocal = NA diisi dengan tanggal hari ini
data["startDateLocal"][is.na(data["startDateLocal"])] <- Sys.Date()

#insert data to database
#make connection to database
library(RPostgreSQL)
tryCatch({
  drv <- dbDriver("PostgreSQL")
  print("Connecting to Database.")
  con <- dbConnect(drv,
                 dbname = Sys.getenv("STRAVA_ELEPHANT_SQL_DBNAME"), 
                 host = Sys.getenv("STRAVA_ELEPHANT_SQL_HOST"),
                 port = 5432,
                 user = Sys.getenv("STRAVA_ELEPHANT_SQL_USER"),
                 password = Sys.getenv("STRAVA_ELEPHANT_SQL_PASSWORD"))
  print("Database Connected!")
},
error=function(cond) {
  print("Unable to connect to Database.")
}
)

dbWriteTable(conn=con, name='activity', value=data, append = TRUE, row.names = FALSE, overwrite=FALSE)    
    

l <- length(data$id)
for(k in 1:l){
  # most recent activity detail
  id_activity <- recent_act[k,1]
  recent_act_detail <- get_data(type = "activity", id = recent_act[k,1])
  
  latlng <- recent_act_detail[["streams"]][["latlng"]]
  
  if(length(latlng)>0){
    df <- as.data.frame(latlng)
    
    #lat <- df$V1
    #lng <- df$V2
    n <- length(df$V1)
    time <- seq(0.001,10,length.out=n)
    df$time <- time
    df$id <- id_activity
    
    dbWriteTable(conn=con, name='posisi_new', value=df, append = TRUE, row.names = FALSE, overwrite=FALSE)
  }
}

on.exit(dbDisconnect(con)) 
