#!/usr/bin/env Rscript
library(aws.s3)
library(dplyr)
library(jug)
source('/home/pi/home_iot/hue/functions.R')

aws.signature::use_credentials()

# Expose model stored on S3 as a prediction API
gbmFit<-s3readRDS(paste0("gbmFit_",Sys.Date(),".rds"), 
                 bucket = "ams-hue-data")

median_values <- s3readRDS(paste0("median_values_",Sys.Date(),".rds"), 
                 bucket = "ams-hue-data")

predict_hue <- function(timestamp){
        
        df <- data.frame(log_time =as.POSIXct(timestamp)) %>% 
                add_vars(extra_var = "no")
        
        pred <- predict(gbmFit, newdata = df)
        
        if (pred=="zero") {
                x <- 0
        } else {
                x <- median_values %>% filter(y == pred & hour == lubridate::hour(timestamp)) %>%
                select(med) %>% unlist()
        }
        
        return(x)
}

jug() %>% post("/predict-hue", decorate(predict_hue)) %>%
        simple_error_handler_json() %>%
        serve_it()
