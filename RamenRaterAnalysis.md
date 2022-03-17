Here I show how R can be used for data manipulation, analysis, and
graphing. More specifically, I demonstrate how to load the data, some
examples of cleaning and manipulating (filtering, renaming columns,
pivoting, merging, etc.), and a bit of analysis (total review count over
time, noodle consumption per capita, and appearance count in the Ramen
Rater’s Top 10 rankings by brand).

First thing’s first, loading the necessary packages and data. Each Excel
sheet is loaded into their own data frame.

``` r
library(tidyverse) #for essential data manipulation packages like dplyr and ggplot2
library(readxl) #to read the Excel file
library(plotly) #to improve graphing, enabling to zoom in and out of graphs among other things
library(lubridate) #for easier date manipulation
library(DT) #to use datatable() instead of View() for viewing data in markdown

ramenrev <- read_excel(
  "/Users/pedroteixeira/Desktop/Data Analysis/Portfolio/Ramen/Ramen Dataset/Ramen Full List 2022.03.15.xlsx",
  sheet = "Reviewed")

ramenran <- read_excel(
  "/Users/pedroteixeira/Desktop/Data Analysis/Portfolio/Ramen/Ramen Dataset/Ramen Full List 2022.03.15.xlsx",
  sheet = "Ranking")

ramenctr <- read_excel(
  "/Users/pedroteixeira/Desktop/Data Analysis/Portfolio/Ramen/Ramen Dataset/Ramen Full List 2022.03.15.xlsx",
  sheet = "Country Info")

ramencon <- read_excel(
  "/Users/pedroteixeira/Desktop/Data Analysis/Portfolio/Ramen/Ramen Dataset/Ramen Full List 2022.03.15.xlsx",
  sheet = "Instant Noodle Consumption")

ramenurl <- read_excel(
  "/Users/pedroteixeira/Desktop/Data Analysis/Portfolio/Ramen/Ramen Dataset/Ramen Full List 2022.03.15.xlsx",
  sheet = "URL")
```

I remember when I was compiling the data into Excel that some of the
ramen styles weren’t really ramen noodles. In fact, some weren’t even
food. Let me show you what I mean by grouping the data by the **Style**
column in **ramenrev** and outputting the count.

``` r
stylecount <- ramenrev %>% 
  group_by(Style) %>% 
  count(Style) %>% 
  rename(Count = n)

datatable(stylecount)
```

![](RamenRaterAnalysis_files/figure-gfm/unnamed-chunk-2-1.png)<!-- -->

The styles with single digit review counts (bar, bottle, can,
restaurant, and toy) aren’t noodles, so it doesn’t make sense to include
these in this analysis. So we will remove them shortly. But first, out
of curiosity, what *were* these items? Let’s see.

``` r
notramenstyle <- c('Bar', 'Bottle','Can','Restaurant', 'Toy')
notramen <- ramenrev[ramenrev$Style %in% notramenstyle, ]

datatable(notramen)
```

![](RamenRaterAnalysis_files/figure-gfm/unnamed-chunk-3-1.png)<!-- -->

Here we see ramen flavored Pringles (the “can” entry), a few restaurant
reviews, and… *ramen chocolate?!* I’ll query the URL for those reviews
later so you can check them out for yourself, but for now we can confirm
that they’re irrelevant to this analysis.

Before we drop those though, I also want to filter out some countries
with low noodle entries to focus our analysis with fewer outliers. First
let’s see what the review distribution is per **Country_ID**.

``` r
ctrcount <- ramenrev %>% 
  group_by(Country_ID) %>% 
  count(Country_ID) %>% 
  rename(Count = n)

datatable(ctrcount)
```

![](RamenRaterAnalysis_files/figure-gfm/unnamed-chunk-4-1.png)<!-- -->

And here’s a quick bar graph so we can visualize it more easily.

``` r
ggplotly(
  ggplot(ramenrev, aes(Country_ID)) + geom_bar()
)
```

![](RamenRaterAnalysis_files/figure-gfm/unnamed-chunk-5-1.png)<!-- -->

Let’s focus our analysis to countries with at least 50 noodle entries in
the database, and remove the non-noodle entries mentioned earlier.

``` r
filterrev <- ramenrev %>% 
  filter(!Style %in% notramenstyle) %>% 
  group_by(Country_ID) %>% 
  filter(n()>=50) %>% 
  ungroup()

datatable(filterrev)
```

![](RamenRaterAnalysis_files/figure-gfm/unnamed-chunk-6-1.png)<!-- -->

We can compare the count of unique values by column between the filtered
and unfiltered data frames.

``` r
sapply(ramenrev,n_distinct)
```

    ##   Review_ID Review_Date       Brand     Variety       Style  Country_ID 
    ##        4106        3422         562        3810          10          46 
    ##       Stars 
    ##          41

``` r
sapply(filterrev,n_distinct)
```

    ##   Review_ID Review_Date       Brand     Variety       Style  Country_ID 
    ##        3775        3170         504        3508           5          14 
    ##       Stars 
    ##          41

Great. Before moving on, let’s pull up the URLs for the non-ramen
entries like I mentioned earlier. The links are in the **ramenurl** data
frame, so we will merge that with the **notramen** data frame binding on
the **Review_ID** column.

``` r
notramen <- merge(x=notramen, y=ramenurl, by='Review_ID')

datatable(notramen)
```

![](RamenRaterAnalysis_files/figure-gfm/unnamed-chunk-8-1.png)<!-- -->

Okay a quick first exercise, let’s look at the review count over time,
using the **ramenrev** data frame again. Note that we will only use the
year part of the **Review_Date** column. We are also removing entries
submitted in 2022 as the year is still ongoing.

``` r
ggplotly(
  ramenrev %>% 
    mutate(Review_Date = format(Review_Date, "%Y")) %>%
    group_by(Review_Date) %>%
    summarise(Review_Count = n()) %>% 
    arrange(Review_Date) %>% 
    filter(Review_Date<2022) %>%
    ggplot(aes(x = Review_Date, y = Review_Count, group = 1))+geom_line()
)
```

![](RamenRaterAnalysis_files/figure-gfm/unnamed-chunk-9-1.png)<!-- -->

Next, something a little more involved: calculating the noodle
consumption per capita. For this we need the country population data in
the **ramenctr** data frame and the noodle consumption by country data
in the **ramencon** data frame.

So let’s combine the two data frames. We will do a left join
(all.x=TRUE) here because the **ramencon** data frame includes data on
countries that don’t appear in the ramen review database. This is in
contrast to **ramenctr**, which only includes countries that have at
least one noodle review (with exception of the ‘World’ population entry
which we will drop).

``` r
# Merging the data frames on column 'Country'
ctrcon <- merge(x=ramenctr, y=ramencon, by='Country', all.x=TRUE)

# Removing the 'World' column, which is irrelevant
ctrcon <- ctrcon[!(ctrcon$Country == 'World'), ]
```

Let’s make sure the data types are as expected before we proceed by
checking the data types for the columns.

``` r
str(ctrcon)
```

    ## 'data.frame':    64 obs. of  16 variables:
    ##  $ Country         : chr  "Argentina" "Australia" "Bangladesh" "Belgium" ...
    ##  $ Country_ID      : num  47 1 2 48 3 4 5 49 6 7 ...
    ##  $ Subregion       : chr  "South America" "Australasia" "South Asia" "Western Europe" ...
    ##  $ Region          : chr  "Americas" "Oceania" "Asia" "Europe" ...
    ##  $ 2016_Population : num  4.35e+07 2.43e+07 1.58e+08 1.14e+07 2.06e+08 ...
    ##  $ 2017_Population : num  4.39e+07 2.46e+07 1.60e+08 1.14e+07 2.08e+08 ...
    ##  $ 2018_Population : num  4.44e+07 2.49e+07 1.61e+08 1.15e+07 2.09e+08 ...
    ##  $ 2019_Population : num  4.48e+07 2.52e+07 1.63e+08 1.15e+07 2.11e+08 ...
    ##  $ 2020_Population : num  4.52e+07 2.55e+07 1.65e+08 1.16e+07 2.13e+08 ...
    ##  $ Avg_Population  : num  4.44e+07 2.49e+07 1.61e+08 1.15e+07 2.09e+08 ...
    ##  $ 2016_Consumption: chr  "1.0E7" "3.8E8" "2.9E8" "1.0E7" ...
    ##  $ 2017_Consumption: chr  "1.0E7" "3.9E8" "3.5E8" "1.0E7" ...
    ##  $ 2018_Consumption: num  1.00e+07 4.10e+08 3.10e+08 1.00e+07 2.39e+09 ...
    ##  $ 2019_Consumption: num  1.00e+07 4.20e+08 3.70e+08 2.00e+07 2.45e+09 ...
    ##  $ 2020_Consumption: num  4.00e+06 4.40e+08 3.70e+08 2.00e+07 2.72e+09 ...
    ##  $ Avg_Consumption : num  8.80e+06 4.08e+08 3.38e+08 1.40e+07 2.44e+09 ...

The 2016 and 2017 noodle consumption columns are character type instead
of numeric. This is because we don’t have this consumption data for all
countries, and the missing NaN values default the column to “character”.
Let’s change it back to numeric. We will get a warning about those NAs,
but that is fine.

``` r
ctrcon$`2016_Consumption` <- as.numeric(ctrcon$`2016_Consumption`)
```

    ## Warning: NAs introduced by coercion

``` r
ctrcon$`2017_Consumption` <- as.numeric(ctrcon$`2017_Consumption`)
```

    ## Warning: NAs introduced by coercion

Good, now let’s calculate the consumption per capita for each country by
year, all in their own column…

``` r
ctrcon <- mutate(ctrcon, `2016_Per_Capita_Consumption` = `2016_Consumption`/`2016_Population`) %>% 
  mutate(ctrcon, `2017_Per_Capita_Consumption` = `2017_Consumption`/`2017_Population`) %>% 
  mutate(ctrcon, `2018_Per_Capita_Consumption` = `2018_Consumption`/`2018_Population`) %>% 
  mutate(ctrcon, `2019_Per_Capita_Consumption` = `2019_Consumption`/`2019_Population`) %>% 
  mutate(ctrcon, `2020_Per_Capita_Consumption` = `2020_Consumption`/`2020_Population`) %>% 
  mutate(ctrcon, Avg_Per_Capita_Consumption = Avg_Consumption/Avg_Population)
```

…and round the per capita values to 2 decimal points.

``` r
ctrcon <- ctrcon %>% 
  mutate(across(`2016_Per_Capita_Consumption`:Avg_Per_Capita_Consumption, round, 2))

datatable(ctrcon)
```

![](RamenRaterAnalysis_files/figure-gfm/unnamed-chunk-14-1.png)<!-- -->

I want to graph the consumption per capita per region over the years,
but we can’t do so easily with the data in this state. To do that, we
will have to make the data frame tall rather than wide. So let’s isolate
only the per capita columns into their own data frame so it’s easier to
work with (**concap**), and then change it from wide to tall.

``` r
concap <- select(ctrcon, Country, Subregion, Region, 
                 `2016_Per_Capita_Consumption`:`2020_Per_Capita_Consumption`)
concap <- gather(concap, Year, Per_Capita_Consumption, 
                 `2016_Per_Capita_Consumption`:`2020_Per_Capita_Consumption`)
datatable(concap)
```

![](RamenRaterAnalysis_files/figure-gfm/unnamed-chunk-15-1.png)<!-- -->

Looking good, but those rows with missing entries need to go (see lines
53 or 117 for example). Having those in there will interfere with the
graphing, so let’s get rid of them. Incidentally, we didn’t do this
earlier in the **ctrcon** data frame because that would mean dropping
the entire row of the country with missing data. Now that the data is
tall, we can drop only what we don’t have.

``` r
concap <- na.omit(concap)
```

Next, since this is only per capita data, we don’t need such wordy
entries in the Year column. Let’s change it so that only the year is
listed.

``` r
concap$Year[concap$Year == '2016_Per_Capita_Consumption'] <- '2016'
concap$Year[concap$Year == '2017_Per_Capita_Consumption'] <- '2017'
concap$Year[concap$Year == '2018_Per_Capita_Consumption'] <- '2018'
concap$Year[concap$Year == '2019_Per_Capita_Consumption'] <- '2019'
concap$Year[concap$Year == '2020_Per_Capita_Consumption'] <- '2020'
```

How does it look?

``` r
datatable(concap)
```

![](RamenRaterAnalysis_files/figure-gfm/unnamed-chunk-18-1.png)<!-- -->

Much better! Finally, let’s do some graphing. Let’s graph the average
consumption per capita per year, grouping by region. We will use
ggplotly to add labels.

``` r
ggplotly(
  concap %>%  
    group_by(Region, Year) %>% 
    summarize(Avg_Per_Capita_Consumption = mean(Per_Capita_Consumption)) %>% 
    ggplot(aes(x=Year, y=Avg_Per_Capita_Consumption, fill=Region, 
               text = paste0("Consumption: ", round(Avg_Per_Capita_Consumption, 2)))) + 
    geom_bar(position = 'stack', stat = 'identity'), tooltip = "text"
)
```

    ## `summarise()` has grouped output by 'Region'. You can override using the `.groups` argument.

![](RamenRaterAnalysis_files/figure-gfm/unnamed-chunk-19-1.png)<!-- -->

Moving on, let’s take a look at brands and the rankings data. I want to
see which brands showed up most frequently on Top 10 lists. For this I
will merge some parts of the **ramenrev** data frame with the
**ramenran** data frame, calling it **brandran**.

``` r
brandran <- merge(x=select(ramenrev, Review_ID, Brand), 
                     y=select(ramenran, Review_ID, Rank_Category, Rank), by='Review_ID')
```

I don’t want to use all Top 10 rank categories though, as some are
country-specific (which would skew the results for some brands) and
others are not necessarily “good” rankings (like the Bottom Ten or Top
Spicy rankings). Let’s see which rankings there are…

``` r
unique(brandran$Rank_Category)
```

    ##  [1] "Unlabeled List"  "Top Pack"        "Reader's Choice" "Top Spicy"      
    ##  [5] "Top Japan"       "Easy to Find"    "Top Taiwan"      "Bottom Ten"     
    ##  [9] "Anomaly"         "Top Bowl"        "Top Philippines" "Top Hong Kong"  
    ## [13] "Top Rice Noodle" "Top USA"         "Top Cup"         "Top South Korea"
    ## [17] "Top China"       "Top Indonesia"   "Top Thai"        "Top Tray"       
    ## [21] "Top Malaysia"    "Top Singapore"   "Healthy Options" "Top India"      
    ## [25] "Top Boxed"

… and then filter out a subset of them into a new data frame,
**brandbest**.

``` r
brandbest <- subset(brandran, Rank_Category %in% 
                      c('Top Pack', "Reader's Choice", 'Top Rice Noodle', 
                        'Top Bowl', 'Top Cup', 'Top Tray', 'Top Boxed' )
                    )
```

Now group by brand, and see how many times each brand appeared in a Top
10 Count and the average placement in the ranking.

``` r
brandbest <- brandbest %>% group_by(Brand) %>% 
  summarize(Top_10_Count = n(), Mean_Rank = mean(Rank))
```

Let’s clean the data a bit, rounding the values and arranging it first
from most appearances to least, and second from best placement to worst.
Then we’ll view the data frame and get a statistical summary of it.

``` r
brandbest$Mean_Rank <- round(brandbest$Mean_Rank, digits = 2)
brandbest <- brandbest %>% arrange(desc(Top_10_Count), Mean_Rank)

datatable(brandbest)
```

![](RamenRaterAnalysis_files/figure-gfm/unnamed-chunk-24-1.png)<!-- -->

``` r
summary(brandbest)
```

    ##     Brand            Top_10_Count      Mean_Rank    
    ##  Length:73          Min.   : 1.000   Min.   : 1.00  
    ##  Class :character   1st Qu.: 1.000   1st Qu.: 4.50  
    ##  Mode  :character   Median : 2.000   Median : 6.50  
    ##                     Mean   : 4.726   Mean   : 6.38  
    ##                     3rd Qu.: 5.000   3rd Qu.: 8.33  
    ##                     Max.   :42.000   Max.   :10.00

It seems Nissin had the most appearances in Top 10 lists with a mean
rank of 5.45. Second is MyKuali which, although has fewer appearances
than Nissin, has a mean rank within the top 4. Pretty impressive!

This has been data analysis with R.
