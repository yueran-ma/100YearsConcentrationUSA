# GPINTER Code

# ***************** 0. Setups *****************
rm(list = ls())

library(haven)
library(gpinter)

#commandArgs picks up the variables you pass from the command line
args <- commandArgs(trailingOnly = F)

# Set the wd by passing current directory
setwd(args[6]) # args 6 is the path variable passed to the program.
program_wd=getwd()
print(program_wd)

inpath <-paste0(program_wd,"/output/temp/")

# Load data
data <- read_dta(paste0(inpath,"tabulation-input.dta"))

if ("p_top100" %in% names(data)) {
  p_top100 <- data$p_top100[1]
}
if ("p_top500" %in% names(data)) {
  p_top500 <- data$p_top500[1]
}
if ("p_top5000" %in% names(data)) {
  p_top5000 <- data$p_top5000[1]
}
if ("p_top5000in1980all" %in% names(data)) {
  p_top5000in1980all <- data$p_top5000in1980all[1]
}




distribution <- tabulation_fit(
  p = data$p,
  thr = data$threshold,
  bracketavg = data$bracketavg,
  average = data$average[1]
)

if ("p_top500" %in% names(data)) {
  if(data$number_total[1] > 5000){
    percentiles_output <- c(
      seq(0, 0.99, 0.01), 
      seq(0.991, 0.999, 0.001), 
      seq(0.9991, 0.9999, 0.0001), 
      seq(0.99991, 0.99999, 0.00001),
      p_top500, p_top5000
    )
  } else if (data$number_total[1] > 500){
    percentiles_output <- c(
      seq(0, 0.99, 0.01), 
      seq(0.991, 0.999, 0.001), 
      seq(0.9991, 0.9999, 0.0001), 
      seq(0.99991, 0.99999, 0.00001),
      p_top500
    )
  }
  } else {
    percentiles_output <- c(
      seq(0, 0.99, 0.01), 
      seq(0.991, 0.999, 0.001), 
      seq(0.9991, 0.9999, 0.0001), 
      seq(0.99991, 0.99999, 0.00001)
    )
  }


if ("p_top5000in1980all" %in% names(data)) {
  percentiles_output <- c(
    seq(0, 0.99, 0.01), 
    seq(0.991, 0.999, 0.001), 
    seq(0.9991, 0.9999, 0.0001), 
    seq(0.99991, 0.99999, 0.00001),
    p_top500, p_top5000, p_top5000in1980all
  )
}




if ("p_top100" %in% names(data)) {
    percentiles_output <- c(
      seq(0, 0.99, 0.01), 
      seq(0.991, 0.999, 0.001), 
      seq(0.9991, 0.9999, 0.0001), 
      seq(0.99991, 0.99999, 0.00001),
      p_top100
    )
}


tabulation <- generate_tabulation(distribution, percentiles_output)

gini <- gini(distribution)

tabulation <- data.frame(
  p               = tabulation$fractile,
  threshold       = tabulation$threshold,
  top_share       = tabulation$top_share,
  bottom_share    = tabulation$bottom_share,
  bracket_share   = tabulation$bracket_share,
  top_average     = tabulation$top_average,
  bottom_average  = tabulation$bottom_average,
  bracket_average = tabulation$bracket_average,
  invpareto       = tabulation$invpareto,
  gini       = gini
)

write_dta(tabulation, paste0(inpath,"tabulation-output.dta"))


