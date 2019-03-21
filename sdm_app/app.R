### -----------------------------------------------
### -- Get setup with shiny

library(shiny)
library(csv)
library(raster)
library(maps)
library(reshape2)
library(maxnet)
library(rgdal)


### -----------------------------------------------
### -- Read list of models

# List all flickr models
flickr_maxent_files <- list.files(path="./models/flickr/maxent")
flickr_files <- sort(unique(c(flickr_maxent_files)))

# List all twitter models
twitter_maxent_files <- list.files(path="./models/twitter/maxent")
twitter_files <- sort(unique(c(twitter_maxent_files)))

# Get list of all species
species_models <- sort(unique(c(flickr_files,twitter_files)))

# Create data frame indicating where data can come from
Species <- c(flickr_files,twitter_files)
species_df <- as.data.frame(Species)
species_df$Source <- c(rep("Flickr",times=length(flickr_files)),
                       rep("Twitter",times=length(twitter_files)))


### -----------------------------------------------
### -- Read in bioclim data

# NOTE: The bioclim data has been compressed by removing NAs
# In order to reconstruct the data you need to insert the NAs back in
# Finally, convert each to a raster

# Read in the bioclim data
bioclim_compressed <- read.csv("./bioclim/bioclim_vars.csv")

# Read in an empty raster
zero_raster <- raster("./bioclim/zero_raster.tif")

# Use the empty raster to find NAs
bioclim_nas <- which(!is.na(melt(values(zero_raster))))


### -----------------------------------------------
### -- Text to use in user interface

# Introduction
warning_hours <- "Please do stay on this webpage for too long. I only have 25 active hrs/month on this service."

# Social media data
data_source <- "Data for the 'Occurrence data' plot was found by scraping Flickr in R. 
  The R script finds all images from 2010 to 2018 tagged with the species name. 
  I then filter by images that have location data and save the locations as a csv file. 
  The data set contains data from around the world, 
  but I only plot part of North America since the free version of shinyapps.io has very little memory."
future_scraping <- "The decision to use Flickr was inspired by a paper [1] that uses Flickr to track four native species in Australia. 
  I decided to use Flickr to search for invasive species; however, few invasive species have enough records in Flickr in order to fit a species distribution model. 
  In future versions of this app I will work with Twitter's API to find geotagged images of invasive species posted on Twitter. 
  Twitter will likely have larger data sets with which I can fit species distribution models."
paper_citation1 <- "[1] ElQadi MM, Dorin A, Dyer A, Burd M, Bukovac Z, Shrestha M. 
  Mapping species distributions with social media geo-tagged images: Case studies of bees and flowering plants in Australia. 
  Ecological informatics. 2017 May 1;39:23-31."

# Machine learning model
model_selection <- "Searching social media can only produce species presence data without any species absence data. 
  Therefore, I had to use a species distribution model that could be fit using presence-only data. 
  The model I selected was maxent."
maxent_desc <-"Maxent seeks to find the conditional probability of occurrence given several covariates (in this case climate variables) 
  by finding the log of the ratio of two probability density functions [2]. 
  The first density function is the conditional density of covariates in presence-sites 
  and it's divided by the marginal density of covariates in the entire study area. 
  The marginal density of covariates is found by randomly sampling sites in the study area;
  however, the conditional density of covariates in presence-sites can be any function that's consistent with the presence data. 
  In order to choose from the possible density functions, maxent selects the model that minimizes the distance between the two densities."
implementation <- "The maxent algorithm is implemented in the 'maxnet' package in R. 
  I fit the model using global occurrence and climate data; however, I only show a subset of the output in this app. 
  The range plotted is restricted due to limitations with my free account on shinyapps.io."

# R Shiny
shiny_desc <- "This app is implemented in R Shiny. 
  The occurrence data is stored in a 'data' folder while the climate data is stored in a 'bioclim' folder. 
  The maxent models are fit on my laptop and uploaded as an RDS file. 
  When the species and source are selected along with 'Occurrence data' the app reads the occurrence data and plots it. 
  When the species and source are selected along with 'Species distribution model' the app reads in the RDS file and the bioclim data and predicts the potential species distribution."
paper_citation2 <- "[2] Elith J, Phillips SJ, Hastie T, Dudík M, Chee YE, Yates CJ. 
  A statistical explanation of MaxEnt for ecologists. 
  Diversity and distributions. 2011 Jan;17(1):43-57."


### -----------------------------------------------
### -- Create user interface

ui <- fluidPage(
  
  # Application title
  titlePanel("Virtual Species Distribution Map"),
  
  # Sidebar
  sidebarLayout(
    # The app has two inputs: species and source data
    sidebarPanel(
      selectInput(inputId="species",
                  label="Species",
                  choices=c("Select species",sort(unique(Species)))),
      selectInput(inputId="mapType",
                  label="Map Type",
                  choices=c("Select map","Occurrence data","Species distribution model")),
      selectInput(inputId="source",
                  label="Data Source",
                  choices=c("Select data source","Flickr"))
    ),
    # The app outputs a map of potential species distribution
    mainPanel(
      h3("Plot"),
      strong(warning_hours),
      plotOutput("modelMap"),
      h3("Web Scraping"),
      p(data_source),
      p(future_scraping),
      h3("Species Distribution Modelling"),
      p(model_selection),
      p(maxent_desc),
      p(implementation),
      h3("R Shiny"),
      p(shiny_desc),
      h3("Citation"),
      p(paper_citation1),
      p(paper_citation2),
      h5("© Jonathan Drake, 2019")
    )
  )
)


### -----------------------------------------------
### -- Server

server <- function(input, output) {
  output$modelMap <- renderPlot({
    # Plot species occurrence data
    if (input$species!="Select species" & input$source!="Select data source" & input$mapType=="Occurrence data") {
      if (input$source=="Flickr") {src_path <- "flickr"}
      # Read in the occurrence data
      obs_data <- read.csv(paste(c("./data/",src_path,"/",input$species,".csv"),collapse=""))
      #map("world", fill=T, col="grey", bg="white")
      breakpoints <- c(-1,1)
      colors <- c("grey")
      plot(zero_raster,breaks=breakpoints,col=colors)
      points(obs_data$longitude,obs_data$latitude,
             col="red",pch=16)
    }
    # Plot SDM output
    if (input$species!="Select species" & input$source!="Select data source" & input$mapType=="Species distribution model") {
      # Read in the relevant model
      model <- readRDS(paste("./models/flickr/maxent/",input$species,sep=""))
      # Predict ecological niche with the model
      #sdm_pred <- predict(model,bioclim_compressed)
      sdm_probs <- 1/(1+exp(-predict(model,bioclim_compressed)-model$entropy))
      # Convert to probabilities (for maxent)
      #exponent_part <- sdm_pred + model$entropy
      #sdm_probs <- 1/(1+exp(-exponent_part))
      # Put in a vector with the NAs
      pred_vec <- rep(NA,times=dim(zero_raster)[1]*dim(zero_raster)[2])
      pred_vec[bioclim_nas] <- sdm_probs
      # Cast to matrix form
      pred_raster <- raster(zero_raster)
      values(pred_raster) <- matrix(pred_vec,nrow=nrow(pred_raster),byrow=T)
      # Plot the results
      plot(pred_raster)
    }
  })
}


### -----------------------------------------------
### -- Run the application

shinyApp(ui=ui, server=server)

