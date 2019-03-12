# Set working directory
setwd("working directory")

### -----------------------------------------------
### -- Read in the occurrence data

# Library to work with csv files
library(csv)

# Read data
pics_geo <- read.csv("kudzu_occurrence_data.csv")


### -----------------------------------------------
### -- Get bioclim data

# Libraries for spatial data
library(raster) # also loads sp
library(rgdal)

# Library for machine learning
library(maxnet)

# Libraries for manipulating data
library(reshape2) # melt
library(stringr)  # str_sub

# Library to let me know when the model is done
library(beepr)

# Download bioclim data using 'raster' package
#  Credit to user 'aldo_tapia' from stackexchange:
#  https://gis.stackexchange.com/a/227595
# Uncomment the line below for your first run
# bioclim_data <- getData("worldclim", var="bio", res=10)

# Load bioclim data
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
### -- Remove NAs and melt to a usable form

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


### -----------------------------------------------
### -- Fit maxent model

# Only use relevant climate variables (Callen & Miller, 2015)
clim_var <- c("bio6","bio9","bio12","bio13","bio15","bio18","bio19")
predictors_cm <- predictors_full[,which(names(rb) %in% clim_var)]

# Get data in the form needed for maxnet
observations <- obs_vector[!is.na(obs_vector)]
predictors <- as.data.frame(predictors_cm[na_vector,])

# Fit the model (takes ~24 minutes on my laptop)
start_time <- Sys.time()
model <- maxnet(observations,predictors)
beep() # go watch tv or something until you hear the beep
print(Sys.time()-start_time)


### -----------------------------------------------
### -- Save output

# Save model output so I don't have to run it again
saveRDS(model, file="maxnet_model")

# Save predictors 
write.csv(predictors, "bioclim_vars.csv")
