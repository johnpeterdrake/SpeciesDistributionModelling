# SpeciesDistributionModelling

## Purpose
The code here uses R to crawl Flickr for geotagged pictures of kudzu, fit a species distribution model based on these observations, and then present the results.

## Repo structure
Each of the three tasks above are performed by one file.
1. search_flickr.R searches Flickr for mentions of kudzu that have location data
1. fit_sdm.R fits a species distribution model using bioclim data and the occurrence data from search_flickr.R
1. map_results.R plots the occurrence data along with 

## Attributions
The idea for this project was inspired by the discussion of a similar idea with Dr. Kim Cuddington. Dr. Cuddington is not involved with this project in any way.

Some of the code here is modified from other sources. I've provided references in the code where necessary.

The decision to use Flickr was based on a paper that uses Flickr to map honeybee and flowering plant distributions [1].

[1] ElQadi, M. M., Dorin, A., Dyer, A., Burd, M., Bukovac, Z., & Shrestha, M. (2017). Mapping species distributions with social media geo-tagged images: Case studies of bees and flowering plants in Australia. *Ecological informatics*, 39, 23-31.
