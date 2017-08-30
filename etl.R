#!/usr/bin/env Rscript

# Run model and save it to memory along with
# df containing brightness values per y.
library(aws.s3)
library(jsonlite)
library(tidyr)
library(dplyr)
library(caret)

set.seed(998)
source('/home/pi/home_iot/hue/functions.R')

# Run model and save it to memory along with
# df containing brightness values per y.
run_model_save_data <- function(...){
        
        aws.signature::use_credentials()
        print("reading from aws")
        df <- s3read_using(object=paste0("hue_full_",Sys.Date(),".json"),
                           fromJSON, bucket = "ams-hue-data")
        
        print("reading completed, now cleaning data")
        tidy_df <- df %>% gather(key, value, -log_time) %>%
                separate(key, into = c("variable", "lamp"), sep = "\\.") %>%
                spread(variable, value)
        
        binned_df <- tidy_df %>% filter(lamp == "1") %>%
                mutate(bri = as.numeric(replace(bri, on=="FALSE" | reachable=="FALSE",0)),
                       y = as.factor(ifelse(bri == 0, "zero",
                                            ifelse(between(bri,0,80), "dim",
                                                   ifelse(between(bri,80,160),"mid","bright")))))
        
        off_days <- binned_df %>% group_by(date = as.Date(log_time,tz="Europe/Amsterdam")) %>%
                dplyr::summarise(total_bri = sum(bri)) %>%
                filter(total_bri == 0 ) %>%
                select(date)
        
        binned_df <- binned_df %>% filter(!as.Date(log_time) %in% off_days$date)
        
        # for predictions
        median_values <- binned_df %>% filter(bri > 0) %>% 
                mutate(hour = lubridate::hour(as.POSIXct(log_time, tz = "Europe/Amsterdam"))) %>%
                select(hour,bri, y) %>% 
                group_by(y, hour) %>%
                dplyr::summarise(med = median(bri)) %>%
                ungroup()
        
        df_vars <- binned_df %>% add_vars(extra_var = "yes") %>%
                select(-log_time, -date)
        
        # new feature idea: mins since start of time of day
        
        print("data cleaning completed, now modeling")
        library(caret)
        
        # create model weights vector
        model_weights <- ifelse(df_vars$y == "zero",0.2,
                                ifelse(df_vars$y == "mid",1.2,1))
        
        # cross validation logic
        fitControl <- trainControl(method = "none")
        
        # create tunegrid
        gbmGrid <-  expand.grid(interaction.depth = 3, 
                                n.trees = 20, 
                                shrinkage = 0.1,
                                n.minobsinnode = 5)
        
        # train model
        gbmFit <- train(y ~ ., data = df_vars, 
                        method = "gbm", 
                        trControl = fitControl,
                        #preProc = c("center", "scale"),
                        metric = "AUC",
                        weights = model_weights,
                        ## This last option is actually one
                        ## for gbm() that passes through
                        verbose = FALSE,
                        tuneGrid = gbmGrid)
        
        
        print("modeling finished, saving objects to S3")
        s3saveRDS(gbmFit, 
                  bucket = "ams-hue-data", 
                  object = paste0("gbmFit_",Sys.Date(),".rds")
        )
        
        s3saveRDS(median_values, 
                  bucket = "ams-hue-data", 
                  object = paste0("median_values_",Sys.Date(),".rds")
        )
}

run_model_save_data()

