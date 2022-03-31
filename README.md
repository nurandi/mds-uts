# Strava to Twitter Bot

[![](https://img.shields.io/badge/Twitter-@ansa52bot-white?style=flat&labelColor=blue&logo=Twitter&logoColor=white)](https://twitter.com/ansa52bot) [![strava_to_tweet](https://github.com/nurandi/mds-uts/actions/workflows/publish.yml/badge.svg)](https://github.com/nurandi/mds-uts/actions/workflows/publish.yml)

Twitter bot [@ansa52bot](https://www.twitter.com/ansa52bot)'s source code. The bot posts [nurandi](https://www.strava.com/athletes/27731166)'s strava activities, mainly running. The system use [{rvest}](https://rvest.tidyverse.org/), gif file is made using [{ggplot2}](https://ggplot2.tidyverse.org/) and [{gganimate}](https://gganimate.com/) , the file send to twitter using [{rtweet}](https://docs.ropensci.org/rtweet/) and [GitHub Actions](https://docs.github.com/en/actions).

## Flow chart

![Flow chart](flowchart.png "Flow chart")

Bot triggered by cron scheduler every 3th hour.
