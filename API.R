#!/usr/bin/env Rscript
library(aws.s3)
library(dplyr)
library(jug)
source('/home/pi/home_iot/hue/functions.R')

aws.signature::use_credentials()

# Get latest model and prediction values
l <- get_bucket(bucket = 'ams-hue-data')
obs <- sapply(l, function(x) x$Key)
# models
models <- obs[grep("gbmFit",obs)]
last_model <- sort(models, decreasing = F)[1]
# values
meds <- obs[grep("median",obs)]
latest_med <- sort(meds, decreasing = F)[1]

# Expose model stored on S3 as a prediction API
gbmFit<-s3readRDS(last_model, 
                 bucket = "ams-hue-data")

median_values <- s3readRDS(latest_med, 
                 bucket = "ams-hue-data")

jug() %>% post("/predict-hue", decorate(predict_hue)) %>%
        simple_error_handler_json() %>%
        serve_it()
