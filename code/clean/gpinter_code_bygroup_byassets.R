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
data_corp <- read_dta(paste0(inpath,"tabulation-input_corp.dta"))
data_part <- read_dta(paste0(inpath,"tabulation-input_part.dta"))
data_combined <- read_dta(paste0(inpath,"tabulation-input_combined.dta"))

p_top500_corp <- data_corp$p_top500[1]
p_top500_part <- data_part$p_top500[1]
p_top500_combined <- round(1- 500 / (data_corp$number_total[1] +data_part$number_total[1]), digits=10)

p_top5000_corp <- data_corp$p_top5000[1]
p_top5000_part <- data_part$p_top5000[1]           
p_top5000_combined <- round(1- 5000 / (data_corp$number_total[1] +data_part$number_total[1]), digits=10)


distribution_corp <- tabulation_fit(
  p = data_corp$p,
  thr = data_corp$threshold,
  bracketavg = data_corp$bracketavg,
  average = data_corp$average[1]
)

distribution_part <- tabulation_fit(
  p = data_part$p,
  thr = data_part$threshold,
  bracketavg = data_part$bracketavg,
  average = data_part$average[1]
)


distribution_combined <- merge_dist(
  dist = list(distribution_corp, distribution_part),
  popsize = c(data_corp$number_total[1],data_part$number_total[1])
)

percentiles_output_corp <- c(
  seq(0, 0.99, 0.01), 
  seq(0.991, 0.999, 0.001),
  seq(0.99925, 0.99975, 0.00025),
  p_top500_corp, p_top5000_corp
)

percentiles_output_part <- c(
  seq(0, 0.99, 0.01), 
  seq(0.991, 0.999, 0.001),
  seq(0.99925, 0.99975, 0.00025),
  p_top500_part, p_top5000_part
)

percentiles_output_combined <- c(
    seq(0, 0.99, 0.01), 
    seq(0.991, 0.999, 0.001),
    seq(0.99925, 0.99975, 0.00025),
    p_top500_combined, p_top5000_combined
  )


tabulation_corp <- generate_tabulation(distribution_corp, percentiles_output_corp)
tabulation_part <- generate_tabulation(distribution_part, percentiles_output_part)
tabulation_combined <- generate_tabulation(distribution_combined, percentiles_output_combined)


tabulation_corp <- data.frame(
  p               = tabulation_corp$fractile,
  threshold       = tabulation_corp$threshold,
  top_share       = tabulation_corp$top_share,
  bottom_share    = tabulation_corp$bottom_share,
  bracket_share   = tabulation_corp$bracket_share,
  top_average     = tabulation_corp$top_average,
  bottom_average  = tabulation_corp$bottom_average,
  bracket_average = tabulation_corp$bracket_average,
  invpareto       = tabulation_corp$invpareto
)


tabulation_part <- data.frame(
  p               = tabulation_part$fractile,
  threshold       = tabulation_part$threshold,
  top_share       = tabulation_part$top_share,
  bottom_share    = tabulation_part$bottom_share,
  bracket_share   = tabulation_part$bracket_share,
  top_average     = tabulation_part$top_average,
  bottom_average  = tabulation_part$bottom_average,
  bracket_average = tabulation_part$bracket_average,
  invpareto       = tabulation_part$invpareto
)

tabulation_combined <- data.frame(
  p               = tabulation_combined$fractile,
  threshold       = tabulation_combined$threshold,
  top_share       = tabulation_combined$top_share,
  bottom_share    = tabulation_combined$bottom_share,
  bracket_share   = tabulation_combined$bracket_share,
  top_average     = tabulation_combined$top_average,
  bottom_average  = tabulation_combined$bottom_average,
  bracket_average = tabulation_combined$bracket_average,
  invpareto       = tabulation_combined$invpareto
)

write_dta(tabulation_corp, paste0(inpath,"tabulation-output_corp.dta"))
write_dta(tabulation_part, paste0(inpath,"tabulation-output_part.dta"))
write_dta(tabulation_combined, paste0(inpath,"tabulation-output_combined.dta"))
