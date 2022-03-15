# First, loading packages
library(tidyverse)
library(readxl)
library(plotly)
library(lubridate)

#Then, loading data
ramenrev <- read_excel("Desktop/Portfolio/Ramen/Ramen Full List 2022.03.15.xlsx", 
                       sheet = "Reviewed")

ramenran <- read_excel("Desktop/Portfolio/Ramen/Ramen Full List 2022.03.15.xlsx", 
                       sheet = "Ranking")

ramenctr <- read_excel("Desktop/Portfolio/Ramen/Ramen Full List 2022.03.15.xlsx", 
                       sheet = "Country Info")

ramencon <- read_excel("Desktop/Portfolio/Ramen/Ramen Full List 2022.03.15.xlsx", 
                       sheet = "Instant Noodle Consumption")

ramenurl <- read_excel("Desktop/Portfolio/Ramen/Ramen Full List 2022.03.15.xlsx", 
                       sheet = "URL")

#Check how many of each Style there are in ramenrev
stylecount <- ramenrev %>% 
  group_by(Style) %>% 
  count(Style) %>% 
  rename(Count = n)
View(stylecount)

#Check how many of each Country there are in ramenrev
ctrcount <- ramenrev %>% 
  group_by(Country_ID) %>% 
  count(Country_ID) %>% 
  rename(Count = n)
View(ctrcount)

#Filter from ramenrev styles with at least 5 entries and countries with at least 50 entries
filterrev <- ramenrev %>% 
  group_by(Style) %>% 
  filter(n()>=5) %>% 
  ungroup() %>% 
  group_by(Country_ID) %>% 
  filter(n()>=50) %>% 
  ungroup()
View(filterrev)

#We can compare the count of unique values by column between the filtered and unfiltered data frames
sapply(ramenrev,n_distinct)
sapply(filterrev,n_distinct)

#Let's combine the ramenctr and ramencon data frames. We will do a left join (all.x=TRUE)
ctrcon <- merge(x=ramenctr, y=ramencon, by='Country', all.x=TRUE)

#And remove the World entry
ctrcon <- ctrcon[!(ctrcon$Country == 'World'), ]

# Let's check the data types for the columns
str(ctrcon)

#For whatever reason, the 2016 and 2017 noodle consumption columns are character instead of numeric.
#Let's change that.

ctrcon$`2016_Consumption` <- as.numeric(ctrcon$`2016_Consumption`)
ctrcon$`2017_Consumption` <- as.numeric(ctrcon$`2017_Consumption`)

#Let's add some columns with the consumption per capita for each year
ctrcon <- mutate(ctrcon, `2016_Per_Capita_Consumption` = `2016_Consumption`/`2016_Population`) %>% 
  mutate(ctrcon, `2017_Per_Capita_Consumption` = `2017_Consumption`/`2017_Population`) %>% 
  mutate(ctrcon, `2018_Per_Capita_Consumption` = `2018_Consumption`/`2018_Population`) %>% 
  mutate(ctrcon, `2019_Per_Capita_Consumption` = `2019_Consumption`/`2019_Population`) %>% 
  mutate(ctrcon, `2020_Per_Capita_Consumption` = `2020_Consumption`/`2020_Population`) %>% 
  mutate(ctrcon, Avg_Per_Capita_Consumption = Avg_Consumption/Avg_Population)

#And round the per capita values to 2 decimal points
ctrcon <- ctrcon %>% 
  mutate(across(`2016_Per_Capita_Consumption`:Avg_Per_Capita_Consumption, round, 2))

#Let's make a separate data frame with only the per capita values, and make it tall instead of wide
concap <- select(ctrcon, Country, Subregion, Region, 
                 `2016_Per_Capita_Consumption`:`2020_Per_Capita_Consumption`)
concap <- gather(concap, Year, Per_Capita_Consumption, 
                 `2016_Per_Capita_Consumption`:`2020_Per_Capita_Consumption`)

#Remove NaN values from concap
concap <- na.omit(concap)

#Now, change the values in the new Year column so they are less verbose
concap$Year[concap$Year == '2016_Per_Capita_Consumption'] <- '2016'
concap$Year[concap$Year == '2017_Per_Capita_Consumption'] <- '2017'
concap$Year[concap$Year == '2018_Per_Capita_Consumption'] <- '2018'
concap$Year[concap$Year == '2019_Per_Capita_Consumption'] <- '2019'
concap$Year[concap$Year == '2020_Per_Capita_Consumption'] <- '2020'

#How does it look?
View(concap)

#Now let's do some graphing. Let's graph the average consumption per capita per year,
#grouping by region. We will use ggplotly to add labels
ggplotly(
  concap %>%  
    group_by(Region, Year) %>% 
    summarize(Avg_Per_Capita_Consumption = mean(Per_Capita_Consumption)) %>% 
    ggplot(aes(x=Year, y=Avg_Per_Capita_Consumption, fill=Region, 
               text = paste0("Consumption: ", round(Avg_Per_Capita_Consumption, 2)))) + 
    geom_bar(position = 'stack', stat = 'identity'), tooltip = "text"
)

#Next let's look at the review count over time, using the ramenrev data frame
ggplotly(
  ramenrev %>% 
    mutate(Review_Date = format(Review_Date, "%Y")) %>%
    group_by(Review_Date) %>%
    summarise(Review_Count = n()) %>% 
    arrange(Review_Date) %>% 
    filter(Review_Date<2022) %>%
    ggplot(aes(x = Review_Date, y = Review_Count, group = 1))+geom_line()
)

#Moving on, let's take a look at brands and the rankings data. I want to see which brands
#showed up most frequently on Top 10 lits. For this I will merge some parts of the ramenrev
#data frame with the #ramenran data frame, calling it "brandran".

brandran <- merge(x=select(ramenrev, Review_ID, Brand), 
                     y=select(ramenran, Review_ID, Rank_Category, Rank), by='Review_ID')

# I don't think I want to use all Top 10 rank categories though, as some are country-specific
#(which would skew the results for some brands) and others are not necessarily "good" rankings
#(like the Bottom Ten or Top Spicy rankings). Let's see which rankings there are...

unique(testran$Rank_Category)

#... and then filter out a subset of them into a new data frame, "brandbest".

brandbest <- subset(brandran, Rank_Category %in% 
                      c('Top Pack', "Reader's Choice", 'Top Rice Noodle', 
                        'Top Bowl', 'Top Cup', 'Top Tray', 'Top Boxed' )
                    )
# Now group by brand, and see how many times each brand appeared in a Top 10 Count
# and the average placement in the ranking.

brandbest <- brandbest %>% group_by(Brand) %>% 
  summarize(Top_10_Count = n(), Mean_Rank = mean(Rank))

# Let's clean the data a bit, rounding the values and arranging it first from 
# most appearances to least, and second from best placement to worst.

brandbest$Mean_Rank <- round(brandbest$Mean_Rank, digits = 2)
brandbest <- brandbest %>% arrange(desc(Top_10_Count), Mean_Rank)

# Let's view the data frame, and get a summary of the data as well.
View(brandbest)
summary(brandbest)
