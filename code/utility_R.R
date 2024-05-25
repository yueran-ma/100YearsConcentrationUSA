
check.packages <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg)) 
    install.packages(new.pkg, dependencies = TRUE, repos = "http://cran.us.r-project.org")
  sapply(pkg, require, character.only = TRUE)
}
packages<-c("data.table","plyr","tidyverse","janitor","haven","readxl",
            "stringr","stringdist","kableExtra","fedmatch","nleqslv","zoo")
check.packages(packages)

# Install gpinter in case it is missing
install.packages("devtools", repos = "http://cran.us.r-project.org")
devtools::install_github("thomasblanchet/gpinter")

# Windows users might also need to install Rtools
# https://cran.r-project.org/bin/windows/Rtools/rtools43/rtools.html