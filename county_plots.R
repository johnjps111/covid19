setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(dplyr)    # for inline selects
library(rgdal)    # for readOGR(...)
library(ggplot2)  # for plots
library(readr)    # for read_csv

# County COVID data: 
# writeup: https://github.com/nytimes/covid-19-data
# data...: https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv
#covid_data <- read_csv("https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv")
covid_data <- read_csv("us-counties.csv")

# County population data:
# writeup: https://www.census.gov/data/datasets/time-series/demo/popest/2010s-counties-total.html#par_textimage_70769902
# data...: https://www2.census.gov/programs-surveys/popest/datasets/2010-2019/counties/totals/co-est2019-alldata.csv
county_data <- read_csv("co-est2019-alldata.csv")
county_data$fips <- paste(county_data$STATE,county_data$COUNTY,sep="")
county_data <- select(county_data, fips, STNAME, CTYNAME, POPESTIMATE2019, DEATHS2019)

covid_detail <- inner_join(covid_data, county_data, by = "fips")
covid_detail$covid_case_pct <- 100 * covid_detail$cases / covid_detail$POPESTIMATE2019
covid_detail$covid_death_pct <- 100 * covid_detail$deaths / covid_detail$POPESTIMATE2019
covid_detail$fipsc <- covid_detail$fips
covid_detail$fips <- NULL
covid_detail$fips <- as.numeric(covid_detail$fipsc)

covid_data <- NULL
county_data <- NULL

outliers <- subset(covid_detail, covid_death_pct < 0 | covid_death_pct > 1 | is.na(covid_death_pct))

cDeathMin <- min(covid_detail$deaths)
cDeathMax <- max(covid_detail$deaths)
cCaseMin <- min(covid_detail$cases)
cCaseMax <- max(covid_detail$cases)
cCasePctMin <- min(covid_detail$covid_case_pct)
cCasePctMax <- max(covid_detail$covid_case_pct)
cDeathPctMin <- min(covid_detail$covid_death_pct)
cDeathPctMax <- max(covid_detail$covid_death_pct)

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

colfunc <- colorRampPalette(c("green","yellow","red"))
pcolors = colfunc(100)
theme_set(theme_bw())

plot_dates <- sort(unique(US_county_detail$cdate))
#plot_dates <- c("2020-01-21")
#plot_date = "2020-01-21"

for (plot_date in plot_dates)
{
  cases_filename = paste("./plots/cases/img_cases_",gsub("-","_",plot_date),".jpg",sep="")
  deaths_filename = paste("./plots/deaths/img_deaths_",gsub("-","_",plot_date),".jpg",sep="")
  case_pcts_filename = paste("./plots/case_pcts/img_cases_",gsub("-","_",plot_date),".jpg",sep="")
  death_pcts_filename = paste("./plots/death_pcts/img_deaths_",gsub("-","_",plot_date),".jpg",sep="")
  
  US_county_detail_current = subset(US_county_detail, pdate == plot_date)
  
  # plot cases
  if (!file.exists(cases_filename))
  {
    mapCases.df <- data.table(fortify(US_counties))
    setkey(mapCases.df,id)
    mapCases.df[US_county_detail_current,cases:=cases]
    mapCases.df[US_county_detail_current,pdate:=pdate]

    mapCases.df.current <- subset(mapCases.df,pdate == plot_date)

    jpeg(filename = paste("./plots/cases/img_cases_",gsub("-","_",plot_date),".jpg",sep=""), width = 1200, height = 800 )
    pc <- ggplot(mapCases.df.current, aes(x=long, y=lat, group=group, fill=cases)) +
      scale_fill_gradientn("", colours=pcolors, na.value = "white", limits = c(0.000000001,15000) ) +
      labs(title=paste("Covid 19 Cases by County (",plot_date,")",sep = ""), x="",y="")+
      geom_polygon() + coord_map() + borders("state")
    print(pc)
    dev.off()
    mapCases.df <- NULL
  }

  # plot deaths
  if (!file.exists(deaths_filename))
  {
    mapDeaths.df <- data.table(fortify(US_counties))
    setkey(mapDeaths.df,id)
    mapDeaths.df[US_county_detail_current,deaths:=deaths]
    mapDeaths.df[US_county_detail_current,pdate:=pdate]

    mapDeaths.df.current <- subset(mapDeaths.df,pdate == plot_date)

    jpeg(filename = paste("./plots/deaths/img_deaths_",gsub("-","_",plot_date),".jpg",sep=""), width = 1200, height = 800 )
    pc <- ggplot(mapDeaths.df.current, aes(x=long, y=lat, group=group, fill=deaths)) +
      scale_fill_gradientn("",colours=pcolors ,na.value = "white", limits = c(0.000000001,500) ) +
      labs(title=paste("Covid 19 Deaths by County (",plot_date,")",sep = ""), x="",y="")+
      geom_polygon() + coord_map() + borders("state")
    print(pc)
    dev.off()
    mapCases.df <- NULL
  }

  # plot case pcts
  if (!file.exists(case_pcts_filename))
  {
    mapCases.df <- data.table(fortify(US_counties))
    setkey(mapCases.df,id)
    mapCases.df[US_county_detail_current,covid_case_pct:=covid_case_pct]
    mapCases.df[US_county_detail_current,pdate:=pdate]

    mapCases.df.current <- subset(mapCases.df,pdate == plot_date)

    jpeg(filename = paste("./plots/case_pcts/img_cases_",gsub("-","_",plot_date),".jpg",sep=""), width = 1200, height = 800 )
    pc <- ggplot(mapCases.df.current, aes(x=long, y=lat, group=group, fill=covid_case_pct)) +
      scale_fill_gradientn("",colours=pcolors ,na.value = "white", limits = c(0.000000001,2) ) +
      labs(title=paste("Covid 19 Cases by County as Pct of County Population (",plot_date,")",sep = ""), x="",y="")+
      geom_polygon() + coord_map() + borders("state")
    print(pc)
    dev.off()
    mapCases.df <- NULL
  }
  
  # plot death pcts
  if (!file.exists(death_pcts_filename))
  {
    mapDeaths.df <- data.table(fortify(US_counties))
    setkey(mapDeaths.df,id)
    mapDeaths.df[US_county_detail_current,covid_death_pct:=covid_death_pct]
    mapDeaths.df[US_county_detail_current,pdate:=pdate]
    
    mapDeaths.df.current <- subset(mapDeaths.df,pdate == plot_date)
    
    jpeg(filename = paste("./plots/death_pcts/img_deaths_",gsub("-","_",plot_date),".jpg",sep=""),width = 1200, height = 800 )
    pc <- ggplot(mapDeaths.df.current, aes(x=long, y=lat, group=group, fill=covid_death_pct)) +
      scale_fill_gradientn("",colours=pcolors ,na.value = "white", limits = c(0.000000001,0.03) ) +
      labs(title=paste("Covid 19 Deaths by County as Pct of County Population (",plot_date,")",sep = ""), x="",y="")+
      geom_polygon() + coord_map() + borders("state")
    print(pc)
    dev.off()
    mapCases.df <- NULL
  }
}

