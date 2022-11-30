## ----setup, include=FALSE----------------------------------------------------------------------------------------------------------------------------------------
knitr::opts_chunk$set(echo = TRUE)


## ---- echo=T, message=F------------------------------------------------------------------------------------------------------------------------------------------

### Read in the tidyverse
library(tidyverse)

### Load in the haven package
library(haven)

### Read in the pupiliq data
pupil <- read_dta("pupiliq.dta")


## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
#point estimate calculation based off of estimator 
pt_1 <- (sum((pupil$stdmdiff)/(pupil$se)^2)) / (sum(1/(pupil$se)^2))
pt_1

#standard error calculated from variance 
se <- sqrt((1)/(sum((1)/(pupil$se)^2)))
se

#Construction of 95% confidence interval
ci_95 <- c(pt_1 - qnorm(.975)*se, pt_1 + qnorm(.975)*se)
ci_95

#p-value 
ci_95_p_value <- 2*(1 - pnorm(abs(pt_1/se)))
ci_95_p_value


## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
print(pupil[17,]$stdmdiff)
print(c(pupil[17,]$stdmdiff - abs(qnorm(.025))*pupil[17,]$se, 
  pupil[17,]$stdmdiff + abs(qnorm(.025))*pupil[17,]$se))


## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
### Calculate the variance of tau_hat
var_tau_hat <- function(sigma_i){
  return(1/sum(1/sigma_i^2))
}

### Find the standard error
pupil[17,]$se/sqrt(var_tau_hat(pupil$se))


## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
#Point estimate for alternate estimator 
pt_2 <- (sum(pupil$stdmdiff)) / 19
print(pt_2)

#standard error calculation
se_2 <- sqrt(((sum(pupil$se))^2 / 19))
print(se_2)

#confidence interval calculation
ci_95_2 <- c(pt_2 - qnorm(.975)*se_2, pt_2 + qnorm(.975)*se_2)
print(ci_95_2)

#p-value calculation
ci_95_2_p_value <- 2*(1 - pnorm(abs(pt_2/se_2)))
ci_95_2_p_value


## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
### Calculate the variance of tau_prime_hat
var_tau_prime_hat <- function(sigma_i){
  return(sum(sigma_i^2)/(length(sigma_i)^2))
}

sqrt(var_tau_prime_hat(pupil$se))/sqrt(var_tau_hat(pupil$se))


## ---- echo=T, message=F------------------------------------------------------------------------------------------------------------------------------------------

### Read in the star data
star <- read_csv("STAR.csv")



## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
library(dplyr)
library(tidyverse)

#recode 'race' and 'classtype'
star <- star %>% mutate(Race=recode(race,
               "1" = "white", 
               "2" = "Black",
               "3" = "Asian",
               "4" = "Hispanic",
               "5" = "Native American",
               "6" = "Other"),
               ClassType=recode(classtype,
                                "1" = "small",
                                "2" = "regular",
                                "3" = "regular with aide"
                                )
               )

#Create a subset with only white and Black students 
star_subset <- star %>% filter(Race == "white" | Race == "Black")

#Group and summarize the # of students assigned to each classtype 
star_subset %>% group_by(ClassType) %>% summarize(Assigned.Students = n(), .groups = 'keep')


## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
star_subset_score <- star_subset %>% filter(!is.na(g4math), !is.na(g4reading))


## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
#Average treatment effect on math score 
math_small_class_effect <- mean(star_subset_score$g4math[star_subset_score$ClassType == "small"])
math_regular_class_effect <- mean(star_subset_score$g4math[star_subset_score$ClassType == "regular"])
math_class_effect <- math_small_class_effect - math_regular_class_effect
print(math_class_effect)

#Average treatment effect on reading score 
reading_small_class_effect <- mean(star_subset_score$g4reading[star_subset_score$ClassType == "small"])
reading_regular_class_effect <- mean(star_subset_score$g4reading[star_subset_score$ClassType == "regular"])
reading_class_effect <- reading_small_class_effect - reading_regular_class_effect
print(reading_class_effect)


#Neyman large sample error on math scores
var_math_class_effect <- var(star_subset_score$g4math[star_subset_score$ClassType == "small"])/sum(star_subset_score$ClassType == "small") + var(star_subset_score$g4math[star_subset_score$ClassType == "regular"])/sum(star_subset_score$ClassType == "regular")

math_se_class_effect <- sqrt(var_math_class_effect)

print(math_se_class_effect)

#Neyman large sample error on reading scores
var_reading_class_effect <- var(star_subset_score$g4reading[star_subset_score$ClassType == "small"])/sum(star_subset_score$ClassType == "small") + var(star_subset_score$g4reading[star_subset_score$ClassType == "regular"])/sum(star_subset_score$ClassType == "regular")

reading_se_class_effect <- sqrt(var_reading_class_effect)

print(reading_se_class_effect)

# 95% confidence interval for math score(asymptotic)
ci_95_math_class_effect <- c(math_class_effect - qnorm(.975)*math_se_class_effect, math_class_effect + qnorm(.975)*math_se_class_effect)
print(ci_95_math_class_effect)

# 95% confidence interval for reading score(asymptotic)
ci_95_reading_class_effect <- c(reading_class_effect - qnorm(.975)*reading_se_class_effect, reading_class_effect + qnorm(.975)*reading_se_class_effect)
print(ci_95_reading_class_effect)

#p-value for math score
p_value_math_score <- 2*(1 - pnorm(abs(math_class_effect/math_se_class_effect)))
p_value_math_score

#p-value for reading score 
p_value_reading_score <- 2*(1 - pnorm(abs(reading_class_effect/reading_se_class_effect)))
p_value_reading_score


## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
star_subset_score <- star_subset_score %>% mutate (race = case_when (race == 1 ~ FALSE,
                                                race == 2 ~ TRUE))

star_subset_score %>% group_by(ClassType) %>% summarize(Total_Students = n(), Black_Students = sum(race), Proportion = mean(race), .groups = "keep")



## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
#new subset where students with missing values of 'hsgrad' are removed 
star_grad_subset <- star_subset %>% filter(hsgrad != "NA")

#New column variable created to recode  # of years spent in a small classroom 
star_grad_subset <- star_grad_subset %>% mutate(YearsSmall=recode(yearssmall,
               "0" = "0", 
               "1" = "0",
               "2" = "0",
               "3" = "1",
               "4" = "1"))

#estimate average treatment effect of having 3 or 4 years of small class sizes from kindergarten to third grade on the probability that a student graduates high school.
more_small_years_effect <- mean(star_grad_subset$hsgrad[star_grad_subset$YearsSmall == "1"])
less_small_years_effect <- mean(star_grad_subset$hsgrad[star_grad_subset$YearsSmall == "0"])
small_years_effect <- more_small_years_effect - less_small_years_effect
print(small_years_effect)

#standard error 
var_small_years_effect <- var(star_grad_subset$hsgrad[star_grad_subset$YearsSmall == "1"]) / sum(star_grad_subset$YearsSmall == "1") + var(star_grad_subset$hsgrad[star_grad_subset$YearsSmall == "0"])/sum(star_grad_subset$YearsSmall == "0")

years_small_se_effect <- sqrt(var_small_years_effect)

# 95% confidence interval on hsgrad probability
ci_95_small_years_effect <- c(small_years_effect - qnorm(.975)*years_small_se_effect, small_years_effect + qnorm(.975)*years_small_se_effect)
print(ci_95_small_years_effect)

#p-value calculation
p_value_small_years_effect <- 2*(1 - pnorm(abs(small_years_effect/years_small_se_effect)))
p_value_small_years_effect 



## ----------------------------------------------------------------------------------------------------------------------------------------------------------------
star_grad_subset <- star_grad_subset %>% mutate(race = case_when (race == 1 ~ FALSE,
                                                                  race == 2 ~ TRUE))

star_grad_subset %>% group_by(YearsSmall) %>% summarize(Total_Students = n(), Black_Students = sum(race), Proportion = mean(race), .groups = "keep")


