# "The Ramen Rater" Portfolio Project

Note: the main purpose of this portfolio project is to showcase data analysis methods and skills, using SQL, Tableau, Python and R. As interesting as the findings may be, they are for demonstration purposes only as the validity of the data sources have not been properly verified.
<br />
<br />
<br />
Here I analyze data on instant noodles from around the world, using a custom dataset assembled from three different sources.

The first is an [instant noodle review database](https://www.theramenrater.com) with over 4,000 reviews run by Mr. Hans "The Ramen Rater" Lienesch. Hans generously provides a basic set of this data for free (referred to as "The Big List" on his site) in XLSX and PDF formats, which I <em>**extensively cleaned, standardized, and updated**</em> through Google Sheets to include the latest reviews, all their corresponding URL, and complete record of his Top Ten Lists over the years.

The second data source is the global instant noodles demand ranking from the World Instant Noodles Association (WINA), which provides the data on noodle consumption per country<sup>※</sup>. This ranking can be accessed [here](https://instantnoodles.org/en/noodles/demand/table/).

The final one is the United Nations Total Population Database, which provides the population estimates included in my dataset. You can find this database and more [here](https://web.archive.org/web/20220720010057/https://www.un.org/en/development/desa/population/publications/database/index.asp). I use this to calculate ramen consumption per capita.
<br />
<br />
Data from these three sources were compiled along with "The Big List" raw data in the provided Excel file, "Ramen Full List (last updated date)".
<br />
<br />
<br />
In addition to the files in the repository, you can also see my R code in Markdown [here](https://p-teixeira.github.io/Ramen-Rater-Portfolio-Project/) and my Tableau visualization [here](https://public.tableau.com/views/AnalyzingTheRamenRatersData/AnalyzingTheRamenRater?:language=en-US&publish=yes&:display_count=n&:origin=viz_share_link).
<br />
<br />
<br />
<sup>※</sup> Please note there are a few differences between the data provided by WINA and the data in the set used for this project. For one, China and Hong Kong's values have been split for this project, and are approximated based on the proportion between their relative populations. The "Others" value in WINA's data has also been further split to approximate the noodle consumption of nations not originally included in their ranking. Similar to how China and Hong Kong were split, this approximation was calculated by multiplying the Others' consumption by the proportion of the population of the nation in question relative to the total remaining world population (i.e., the population of the "Others").

