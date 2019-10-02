#### code to diagnose methods ####

# load libs and data
library(data.table); library(tidyverse)
library(glue); library(sf)

# source distance function
source("codeMoveMetrics/functionEuclideanDistance.r")

# function for resPatches arranged by time
source("codeMakeResults/func_residencePatch.r")

# read in recurse data for selected birds
dataRevFiles <- list.files("../data2018/oneHertzData/recurseData/", full.names = T)[1]

# get time to high tide from written data
dataHtFiles <- list.files("../data2018/oneHertzData/recursePrep/", full.names = T)[1]

# read in subset of data
data <- purrr::map2_df(dataRevFiles, dataHtFiles, function(filename, htData){
  
  # read the file in
  df <- fread(filename)
  
  print(glue('individual {unique(df$id)} in tide {unique(df$tidalcycle)} has {nrow(df)} obs'))
  
  # prep to assign sequence to res patches
  # to each id.tide combination
  # remove NA vals in fpt
  # set residence time to 0 or 1 predicated on <= 10 (mins)
  df <- df[!is.na(fpt),][,resTime:= ifelse(resTime <= 2, F, T)
                         # get breakpoints where F changes to T and vice versa
                         ][,resPatch:= c(as.numeric(resTime[1]),
                                         diff(resTime))
                           # keeping fixes where restime > 10
                           ][resTime == T,
                             # assign res patch as change from F to T
                             ][,resPatch:= cumsum(resPatch)]
  
  
  dataHt <- fread(htData)
  # merge to recurse data
  df <- merge(df, dataHt, all = FALSE)
  
  # get patch data
  patchData <- funcGetResPatches(df)
  
  # remove htData
  rm(htData)
  
  patchData$data <- NULL
  
  return(patchData)
  
})

#### diagnostic plots ####
# get griend
griend <- st_read("../griend_polygon/griend_polygon.shp")
