# SpeciesDistributionModelling

## Purpose
The code here uses R to crawl Flickr for geotagged pictures of kudzu, fits a species distribution model based on these observations, and then saves the results. The folder 'sdm_app' contains the code for an R Shiny app that reads in the saved files and plots occurrence data and the results of the species distribution model.

## Repo structure
- 'search_flickr.R' searches Flickr for mentions of kudzu that have location data then saves the data as a csv file
- 'fit_sdm.R' reads in the species presence data and bioclim data and uses them to fit a species distribution model
- 'map_results.R' reads in the species presence data, bioclim data, and species distribution model and maps the output
- 'sdm_app' is a folder containing all the code for the app at https://johnpeterdrake.shinyapps.io/sdm_app.
  * 'app.R' produces the app
  * 'bioclim' contains data from worldclim at 10 arcminute resolution, limited to part of North America to save space
  * 'data' contains occurrence data for the species
  * 'models' contains RDS files containing maxent models fit using the occurrence data

## Notes
1. In order to run 'search_flickr.R' you will need an API key and secret key from Flickr.
1. 'search_flickr.R' must be run before you run 'fit_sdm.R' since 'fit_sdm.R' requires presence data.
1. The bioclim data is downloaded using the 'getData' function from the raster library. I've left the code to download it in the file 'fit_sdm.R', but it's commented out so that it doesn't download the data every run. Please uncomment it the first time you run that file.
1. 'search_flickr.R' and 'fit_sdm.R' must be run before 'map_results.R'.

## Attributions
The idea for this project was inspired by the discussion of a similar idea with Dr. Kim Cuddington. Dr. Cuddington is not involved with this project in any way.

Some of the code in this repo is modified from other sources. I've provided references in the code where necessary.

The decision to use Flickr was based on a paper that uses Flickr to map honeybee and flowering plant distributions [1].

[1] ElQadi, M. M., Dorin, A., Dyer, A., Burd, M., Bukovac, Z., & Shrestha, M. (2017). Mapping species distributions with social media geo-tagged images: Case studies of bees and flowering plants in Australia. *Ecological informatics*, 39, 23-31.
