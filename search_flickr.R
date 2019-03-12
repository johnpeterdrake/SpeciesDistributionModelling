### ----------------------------------------------------------------------------------------------
### -- Credit to Francesca Mancini:
### -- https://github.com/FrancescaMancini/Flickr-API/blob/master/Flickr.photos.search.R
### -- Much of this code is modified from her repo
### ----------------------------------------------------------------------------------------------

### -----------------------------------------------
### -- Connect to Flickr

# Libraries for reading data
library(RCurl)
library(XML)
library(httr)

# Define keys
api_key <- "api_key_goes_here"
secret_key <- "secret_key_goes_here"

# Create app to get authorization for
myapp <- oauth_app("Invasive Species Virtual Distribution Map",
                   key=api_key, secret=secret_key)

# Where to authenticate
endpoint <- oauth_endpoint(request="https://www.flickr.com/services/oauth/request_token",
                           authorize="https://www.flickr.com/services/oauth/authorize",
                           access="https://www.flickr.com/services/oauth/access_token")

# Authenticate
sig <- oauth1.0_token(endpoint, myapp, cache=F)
fl_sig <- sign_oauth1.0(myapp, sig)


### -----------------------------------------------
### -- Search Flickr

# Set the base URL
baseURL <- paste("https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=",api_key,sep="")

# Search parameters
year <- 2010:2018
text <- "kudzu"
woeid <- NULL # use NULL for world, 24865675 for Europe, and 24865672 for North America
hasgeo <- "1"
extras <- "geo,tags"
perpage <- 100
format <- "rest"

# Data frame to store image data
pics <- NULL

# Search
for (y in year) {
  for (m in 1:12) {
    
    ## ---------------
    ## - Get dates
    
    # Set min day
    daymin <- "01"
    # Set max day
    daymax <- ifelse((m==4|m==6|m==9|m==11), "30", "31")
    if (m==2) {
      if (y%%4==0) {daymax <- 29}
      else         {daymax <- 28}
    }
    # Transform to dates
    m <- substr(paste(c("0",m),collapse=""),nchar(m),nchar(m)+1)
    mindate <- as.character(paste(y,m,daymin,sep="-"))
    maxdate <- as.character(paste(y,m,daymax,sep="-"))
    
    ## ---------------
    ## - Get data
    
    # Create URL for search
    getPhotos <- paste(baseURL,
                       "&text=", text,
                       "&min_taken_date=", mindate,
                       "&max_taken_date=", maxdate,
                       "&woe_id=", woeid,
                       "&has_geo=", hasgeo,
                       "&extras=", extras,
                       "&per_page=", perpage,
                       "&format=", format,
                       sep="")
    
    # Get data from photos
    getPhotos_data <- xmlRoot(xmlTreeParse(getURL(getPhotos,
                                                  ssl.verifypeer=F,
                                                  useragent="flickr")))
    
    ## ---------------
    ## - Find the total number of pages
    
    # Find the total number of pages
    attrs <- xmlAttrs(getPhotos_data[["photos"]])
    if (as.numeric(attrs[["total"]])!=0) {
      pages_data <- data.frame(attrs)
      pages_data[] <- lapply(pages_data, as.character)
      pages_data[] <- lapply(pages_data, as.integer)
      colnames(pages_data) <- "value"
      total_pages <- pages_data["pages","value"]}
    else {total_pages <- 0}
    
    ## ---------------
    ## - Loop through pages and save list of images as data frame
    
    # Data frame to store data from the given month
    pics_tmp <- NULL
    
    # Loop through each page to get image data
    if (total_pages!=0) {
      for (i in 1:total_pages) {
        # Get URLs for photos
        getPhotos <- paste(baseURL,
                           "&text=",text,
                           "&min_taken_date=",mindate,
                           "&max_taken_date=",maxdate,
                           "&woe_id=",woeid,
                           "&has_geo=",hasgeo,
                           "&extras=",extras,
                           "&per_page=",perpage,
                           "&format=",format,
                           "&page=",i,
                           sep="")
        # Get the XML data from each image
        getPhotos_data <- xmlRoot(xmlTreeParse(getURL(getPhotos,
                                                      ssl.verifypeer=F,
                                                      useragent="flickr"),
                                               useInternalNodes=T))
        # Store id, datetaken, latitude, longitude, and tags in the temporary data frame
        id <- xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "id")
        datetaken <- xpathSApply(getPhotos_data,"//photo", xmlGetAttr,"datetaken")
        latitude  <- xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "latitude")
        longitude <- xpathSApply(getPhotos_data, "//photo", xmlGetAttr, "longitude")
        tags <- xpathSApply(getPhotos_data,"//photo", xmlGetAttr,"tags")
        tmp_df <- data.frame(cbind(id, datetaken, latitude, longitude, tags), stringsAsFactors=F)
        tmp_df$page <- i
        pics_tmp <- rbind(pics_tmp, tmp_df)
      }
    }
    
    # Store the data in the final data frame
    pics <- rbind(pics, pics_tmp)
    # Print status
    print(paste(y,m,sep="-"))
    
  }
}

# Remove photos without coordinates and convert coordinates to numeric
pics_geo <- pics[pics$latitude!=0 & pics$longitude!=0,]
pics_geo$latitude  <- as.numeric(pics_geo$latitude)
pics_geo$longitude <- as.numeric(pics_geo$longitude)
