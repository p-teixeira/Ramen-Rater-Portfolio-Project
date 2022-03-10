# Ramen Rater Portfolio Project

The main purpose of this project is to showcase data analysis skills and strategies, using SQL, Python, R, and Tableau. As interesting as the findings may be, they should not be taken at face value as the validity of the data sources have not been properly verified.


The data analyzed pertains to instant noodles around the world, using a custom dataset with data gathered from three different sources:

The first is an instant noodle review database with over 4,000 reviews run by Mr. Hans "The Ramen Rater" Lienesch at https://www.theramenrater.com. Hans generously provides a basic set of this data for free (referred to as "The Big List" on his site) in xlsx and PDF formats, which I extensively cleaned, standardized, and updated to include the latest reviews, all their corresponding URL, and complete record of his Top Ten Lists over the years.

The second data source is the United Nations Total Population Database, which provides the population estimates included in this dataset. You can find this database and more at https://www.un.org/en/development/desa/population/publications/database/index.asp.

The final one is the global instant noodles demand ranking from the World Instant Noodles Association (WINA), which provides the data on noodle consumption per country.※ The ranking can be accessed here: https://instantnoodles.org/en/noodles/demand/table/.

This data is gathered in the provided Excel file, "Ramen Full List (last updated date)".

※　Please note there are a few differences between the data provided by WINA and the data in the set used for this project. For one, China and Hong Kong's values have been split for this project, and are approximated based on the proportion between their relative populations. The "Others" value in WINA's data has also been further split to approximate the noodle consumption of nations not originally included in their ranking. Similar to how China and Hong Kong were split, this approximation was calculated by multiplying the Others' consumption by the proportion of the population of the nation in question relative to the total remaining world population (i.e., the population of the "Others").

