#load library
library(RPostgreSQL)

drv <- dbDriver("PostgreSQL")

con <- dbConnect(drv,
                 dbname = Sys.getenv("STRAVA_ELEPHANT_SQL_DBNAME"), 
                 host = Sys.getenv("STRAVA_ELEPHANT_SQL_HOST"),
                 port = 5432,
                 user = Sys.getenv("STRAVA_ELEPHANT_SQL_USER"),
                 password = Sys.getenv("STRAVA_ELEPHANT_SQL_PASSWORD")
)


query <- 'SELECT * FROM "public"."activity" ORDER BY "startDateLocal" DESC LIMIT 1'
data <- dbGetQuery(con, query)

query1 <- paste0('SELECT * FROM "public"."posisi_new" WHERE "id" = ',data$id)
posisi <- dbGetQuery(con, query1)

## animate plot
library(gganimate)
library(ggplot2)

p <- ggplot(posisi, aes(x=V2,y=V1)) + geom_path() + geom_point(aes(group = time)) +
  transition_reveal(along = time)
p <- animate(p,renderer = gifski_renderer())
anim_save("anime.gif", animation = p)


## Status Message
status_details <- paste0(
  "Name: ", data$name, "\n",
  "Distance: ", data$distance, " km\n",
  "Elevation: ", data$elevation, " m\n",
  "Moving Time: ", data$movingTime, "\n"
)

# Publish to Twitter
library(rtweet)

## Create Twitter token
kambing_token <- rtweet::create_token(
  app = "kambingBot",
  consumer_key =    Sys.getenv("STRAVA_TWITTER_CONSUMER_API_KEY"),
  consumer_secret = Sys.getenv("STRAVA_TWITTER_CONSUMER_API_SECRET"),
  access_token =    Sys.getenv("STRAVA_TWITTER_ACCESS_TOKEN"),
  access_secret =   Sys.getenv("STRAVA_TWITTER_ACCESS_TOKEN_SECRET")
)

## Post the image to Twitter
rtweet::post_tweet(
  status = status_details,
  media = "anime.gif",
  token = kambing_token
)

on.exit(dbDisconnect(con))
