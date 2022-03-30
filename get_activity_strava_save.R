library(rvest)
library(xml2)
library(jsonlite)
library(dplyr)
library(RPostgreSQL)
library(rtweet)
library(gganimate)
library(ggplot2)


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

usr_id <- Sys.getenv("STRAVA_ID")
data <- get_data(type = "recentActivities", id = usr_id)

data <- data %>% 
  filter(hasGps) %>%
  select(id, name, type, distance, startDateLocal, elevation, movingTime)

data <- as.data.frame(data)
data$distance <- as.integer(gsub('.{3}$', '', data$distance))
data$elevation <- gsub('.{2}$', '', data$elevation)
data$elevation <- as.integer(gsub(",", "", data$elevation))
data$startDateLocal <- as.Date(data$startDateLocal, "%B %d, %Y")

data["startDateLocal"][is.na(data["startDateLocal"])] <- Sys.Date()

drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv,
                 dbname = Sys.getenv("STRAVA_ELEPHANT_SQL_DBNAME"), 
                 host = Sys.getenv("STRAVA_ELEPHANT_SQL_HOST"),
                 port = 5432,
                 user = Sys.getenv("STRAVA_ELEPHANT_SQL_USER"),
                 password = Sys.getenv("STRAVA_ELEPHANT_SQL_PASSWORD"))


query <- 'SELECT MAX("id") FROM "public"."activity" '
last_id <- dbGetQuery(con, query)

if(is.na(last_id)){
  last_id <- 0
}

recent_data <- data %>%
  filter(id > last_id[1,1])

dbWriteTable(conn=con, name='activity', value=recent_data, append = TRUE, row.names = FALSE, overwrite=FALSE)    

kambing_token <- rtweet::create_token(
  app = "kambingBot",
  consumer_key =    Sys.getenv("STRAVA_TWITTER_CONSUMER_API_KEY"),
  consumer_secret = Sys.getenv("STRAVA_TWITTER_CONSUMER_API_SECRET"),
  access_token =    Sys.getenv("STRAVA_TWITTER_ACCESS_TOKEN"),
  access_secret =   Sys.getenv("STRAVA_TWITTER_ACCESS_TOKEN_SECRET")
)

l <- length(recent_data$id)
if(l > 0){
  for(k in 1:l){
    
    id_activity <- recent_data[k,1]
    recent_act_detail <- get_data(type = "activity", id = recent_data[k,1])
    
    latlng <- recent_act_detail[["streams"]][["latlng"]]
    distance_stream <- recent_act_detail[["streams"]][["distance"]]
    altitude <- recent_act_detail[["streams"]][["altitude"]]
    name <- recent_act_detail[["name"]]
    distance <- recent_act_detail[["distance"]]
    elevation <- recent_act_detail[["elevation"]]
    movingTime <- recent_act_detail[["time"]]
    
    if(length(latlng)>0){
      df <- as.data.frame(latlng)
      df$distance <- distance_stream
      df$altitude <- altitude
      
      p <- ggplot(df, aes(x=V2, y=V1)) + 
        geom_path() + 
        geom_point(aes(group = distance)) +
        transition_reveal(along = distance) +
        xlab("Longitude") + ylab("Latitude")
      
      p <- animate(p,renderer = gifski_renderer())
      anim_save("anime.gif", animation = p)
      
      status_details <- paste0(
        "Activity Name: ", name, "\n",
        "Distance: ", distance, " \n",
        "Elevation: ", elevation, " \n",
        "Time: ", movingTime, "\n"
      )
      
      rtweet::post_tweet(
        status = status_details,
        media = "anime.gif",
        token = kambing_token
      )
      
    }
  }
}
