setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(dplyr)      # for inline selects
library(data.table) # useful table functions
library(rgdal)      # for readOGR(...)
library(ggplot2)    # for plots
library(readr)      # for read_csv
library(maps)       # required for map_data
library(mapproj)    # required for maps
library(usmap)

# when complete, run: magick convert -delay 5 -loop 1 *.jpg covid_death_pcts.gif

# County COVID data: 
# writeup: https://github.com/nytimes/covid-19-data
# data...: https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv
covid_data <- read_csv("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv")
#covid_data <- read_csv("us-counties.csv")

# County population data:
# writeup: https://www.census.gov/data/datasets/time-series/demo/popest/2010s-counties-total.html#par_textimage_70769902
# data...: https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv
county_data <- read_csv("co-est2019-alldata.csv")
county_data$fips <- paste(county_data$STATE,county_data$COUNTY,sep="")
county_data <- select(county_data, fips, POPESTIMATE2019, DEATHS2019)

covid_detail <- inner_join(covid_data, county_data, by = "fips")
covid_detail$covid_case_pct <- 100 * covid_detail$cases / covid_detail$POPESTIMATE2019
covid_detail$covid_death_pct <- 100 * covid_detail$deaths / covid_detail$POPESTIMATE2019
covid_detail$fipsc <- covid_detail$fips
covid_detail$fips <- NULL
covid_detail$fips <- as.numeric(covid_detail$fipsc)

# covid_subset <- subset(covid_detail, date="2020-03-27")
covid_subset <- covid_detail

US_counties <- readOGR(dsn="./gz_2010_us_050_00_20m",layer="gz_2010_us_050_00_20m")
#leave out AK, HI, and PR (state FIPS: 02, 15, and 72)
US_counties <- US_counties[!(US_counties$STATE %in% c("02","15","72")),]
US_county_data <- US_counties@data
US_county_data <- cbind(id=rownames(US_county_data),US_county_data)
US_county_data <- data.table(US_county_data)
US_county_data[,fipsc:=paste0(STATE,COUNTY)] # this is the state + county FIPS code

US_county_detail <- inner_join(US_county_data,covid_subset,by="fipsc")
US_county_detail$cdate <- as.character(US_county_detail$date)
US_county_detail <- data.table(US_county_detail)
US_county_detail$pdate <- US_county_detail$date

colfunc <- colorRampPalette(c("yellow","red"))
pcolors = colfunc(20)
theme_set(theme_bw())

plot_dates <- sort(unique(US_county_detail$cdate))
#plot_dates <- c("2020-01-21")
#plot_date = "2020-01-21"

for (plot_date in plot_dates)
{
  death_pcts_filename = paste("./plots/death_pcts/img_deaths_",gsub("-","_",plot_date),".jpg",sep="")
  
  US_county_detail_current = subset(US_county_detail, pdate == plot_date)
  
  # plot death pcts
  if (!file.exists(death_pcts_filename))
  {
    upper_limit = 0.5
    mapDeathPcts.df <- data.table(fortify(US_counties))
    setkey(mapDeathPcts.df,id)
    US_county_detail_current[US_county_detail_current$covid_death_pct > upper_limit,]$covid_death_pct = upper_limit
    mapDeathPcts.df[US_county_detail_current,covid_death_pct:=covid_death_pct]
    mapDeathPcts.df[US_county_detail_current,pdate:=pdate]
    setkey(mapDeathPcts.df,id)
    
    mapDeathPcts.df.current <- subset(mapDeathPcts.df,pdate == plot_date)
    
    jpeg(filename = death_pcts_filename,width = 1200, height = 800 )
    pc <- ggplot(mapDeathPcts.df.current, aes(x=long, y=lat, group=group, fill=covid_death_pct)) +
      scale_fill_gradientn("", colours=pcolors ,na.value = "white", limits = c(0.000000001,upper_limit) ) +
      labs(title=paste("Covid 19 Deaths by County as Pct of County Population (",plot_date,")",sep = ""), x="",y="") +
      geom_polygon() + coord_map() + borders("state")
    print(pc)
    dev.off()
  }
}
