# functions
add_vars <- function(df, extra_var = "nos") {
        
        if (extra_var == "yes") {
                df1 <- df %>% select(log_time, y) %>% 
                        mutate(y = factor(y, levels = c("dim","mid","bright", "zero")))
        } else {
                df1 <- df %>% select(log_time)
        }
        df1 %>% mutate(log_time =  as.POSIXct(log_time, tz = "Europe/Amsterdam"),
                       date = as.Date(log_time,tz="Europe/Amsterdam"),
                       mins_passed = as.numeric(difftime(log_time, 
                                                         as.POSIXct(paste0(date,"00:00:00"), 
                                                                    tz = "Europe/Amsterdam"),
                                                         units="mins") %>% round()),
                       day_of_week = factor(weekdays(date),
                                            levels = c("Monday", "Tuesday", "Wednesday",
                                                       "Thursday", "Friday", "Saturday", 
                                                       "Sunday")),
                       month = lubridate::month(date),
                       week = lubridate::week(date),
                       weekend = factor(ifelse(day_of_week %in% c("Friday","Saturday","Sunday"), 
                                               "weekend", "weekday")),
                       hour = lubridate::hour(log_time),
                       time_of_day = factor(ifelse(hour > 5 & hour < 12, "morning",
                                                   ifelse(hour > 11 & hour < 18, "afternoon",
                                                          ifelse(hour > 17 & hour < 24, "evening",
                                                                 "night")))),
                       mins_cut = ifelse(time_of_day=="morning", mins_passed - 360,
                                         ifelse(time_of_day=="afternoon", mins_passed - 720,
                                                ifelse(time_of_day=="evening", mins_passed - 1080, mins_passed)))) %>% 
                select(-mins_passed, -hour) # logtime taken out
}