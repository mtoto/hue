library(aws.s3)
library(dplyr)
library(jug)

# Expose model stored on S3 as a prediction API
gbmFit<-s3readRDS(paste0("gbmfit_",Sys.Date(),".rds"), 
                 bucket = "ams-hue-data")

for_sample <- s3readRDS(paste0("for_sample_",Sys.Date(),".rds"), 
                 bucket = "ams-hue-data")

predict_hue <- function(timestamp){
        
        df <- data.frame(log_time =as.POSIXct(timestamp)) %>% 
                add_vars(extra_var = "no")
        
        pred <- predict(gbmFit, newdata = df)
        
        if (pred=="zero") {
                x <- 0
        } else {
                x <- for_sample %>% filter(y == pred & hour == lubridate::hour(timestamp)) %>%
                select(med) %>% unlist()
        }
        
        return(x)
}

jug() %>% post("/predict-hue", decorate(predict_hue)) %>%
        simple_error_handler_json() %>%
        serve_it()
