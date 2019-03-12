# Set working directory
setwd("working directory")

### -----------------------------------------------
### -- Read in occurrence data

# Library to work with csv files
library(csv)

# Read occurrence data
pics_geo <- read.csv("kudzu_occurrence_data.csv")


### -----------------------------------------------
### -- Read in bioclim data

# Libraries for spatial data
library(raster) # also loads sp
library(rgdal)

# Libraries for manipulating data
library(reshape2) # melt
library(stringr)  # str_sub

# Read climate data that was downloaded in 'fit_sdm.R'
files <- list.files(path="./wc10")
files <- files[grepl(".bil",str_sub(files,-4,-1))]

r1 <- raster(paste("./wc10/",files[1],sep=""))
rb <- brick(r1, values=T)
for (i in 2:length(files)) {
  r_new <- raster(paste("./wc10/",files[i],sep=""))
  rb <- addLayer(rb,r_new)
}


### -----------------------------------------------
### -- Rasterize occurrence data

# Credit to Amy Whitehead for her blog post showing how to do this:
# https://amywhiteheadresearch.wordpress.com/2013/05/27/creating-a-presence-absence-raster-from-point-data/

# Transform points into a 'SpatialPoints' object
pts <- cbind(pics_geo["longitude"],pics_geo["latitude"])
names(pts) <- c("x","y")
coordinates(pts) <- ~x+y

# Rasterize points
zero_raster <- raster(r1$bio1)
values(zero_raster) <- ifelse(is.na(values(r1)),NA,0)

obs_raster <- rasterize(pts, zero_raster, field=1)
obs_raster <- merge(obs_raster, zero_raster)


### -----------------------------------------------
### -- Get data in a form the model can use

# Melt the raster of occurrence data into a vector
obs_vector <- melt(values(obs_raster))

# Keep track of which values are not NA
na_vector <- which(!is.na(obs_vector))

# Store predictors in matrix form
predictors_full <- matrix(NA, nrow=nrow(obs_vector), ncol=length(files))
for (i in 1:dim(rb)[3]) {
  predictors_full[,i] <- values(rb[[paste("bio",i,sep="")]])
}
names(predictors_full) <- names(rb)

# Only use relevant climate variables (Callen & Miller, 2015)
clim_var <- c("bio6","bio9","bio12","bio13","bio15","bio18","bio19")
predictors_cm <- predictors_full[,which(names(rb) %in% clim_var)]

# Get data in the final form
observations <- obs_vector[!is.na(obs_vector)]
predictors <- as.data.frame(predictors_cm[na_vector,])


### -----------------------------------------------
### -- Read in maxnet model

# Library
library(maxnet)

# Read model
maxnet_model <- readRDS("maxnet_model")


### -----------------------------------------------
### -- Create map of search results

# Credit to 'Sharp Sight' for their blog post this section is based on:
# https://www.r-bloggers.com/how-to-make-a-global-map-in-r-step-by-step/

# Libraries for presenting data
library(maps)
library(ggmap)
library(ggplot2)
library(rworldmap)

# Get world map
map_world <- map_data("world")

# Plot!
ggplot() +
  geom_polygon(data=map_world, aes(x=long, y=lat, group=group)) +
  geom_point(data=pics_geo, aes(x=longitude, y=latitude), color="red")


### -----------------------------------------------
### -- Create map of maxent predictions

# Predict ecological niche using maxent
sdm_pred <- predict(maxnet_model,predictors)

# Convert to probabilities since I didn't specify type during training
exponent_part <- sdm_pred + maxnet_model$entropy
sdm_probs <- 1/(1+exp(-exponent_part))

# Put in a vector with the NAs
pred_vec <- rep(NA,times=nrow(obs_vector))
pred_vec[na_vector] <- sdm_probs

# Cast to raster form
pred_raster <- raster(r1$bio1)
values(pred_raster) <- matrix(pred_vec,nrow=nrow(pred_raster),byrow=T)

# Plot the results
plot(pred_raster)
