/************ Function ************/

*This file makes Table 2 of the paper  

/************ Source ************/

*Pre-1959 (by asset tabulations omitted corporations with missing balance sheets, so total numbers were separately collected):
*"input/soi/digitized/corp_totals_pre1959_R5.dta"

*Post-1959 (by asset tabulations included corporations with missing balance sheets, imputed by IRS, so we get total numbers from by asset tabulations):
*"output/soi/brackets/sector_brackets_assets_R5.dta" compiled by code/clean/generate_by_sector_by_assets.do

clear all


******************************************************
* set graph style
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

// Totals after 1959
use "$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", clear

keep 			sector_main year number_total
duplicates drop sector_main year number_total, force

ren 			number_total allnumber

keep			if year >= 1959

tempfile 		post59
save 			"`post59'"

// Totals before 1959
use "$DATA/soi/digitized/corp_totals_pre1959_R5.dta", clear

keep 			sector_main year allnumber 
append using 	"`post59'"

gen double allnumber000 = allnumber / 10^3

label var allnumber000 "Number of Corporations (000)"
label var year "Year"

keep if mod(year, 10) == 0

collapse (mean) allnumber000, by(sector_main year)

gen 			sector_ID = 1 if sector_main == "All"
replace 		sector_ID = 2 if sector_main == "Agriculture"
replace 		sector_ID = 3 if sector_main == "Construction"
replace 		sector_ID = 4 if sector_main == "Finance"
replace 		sector_ID = 5 if sector_main == "Manufacturing"
replace 		sector_ID = 6 if sector_main == "Mining"
replace 		sector_ID = 7 if sector_main == "Services"
replace 		sector_ID = 8 if sector_main == "Trade"
replace 		sector_ID = 9 if sector_main == "Utilities"

replace allnumber000 = round(allnumber000, 1)
reshape wide allnumber000, i(sector_ID) j(year)

// Reduce number of columns - AER table style guidelines
drop allnumber0001920 allnumber0001940 allnumber0001960 allnumber0001980 allnumber0002000

format allnumber00* %10.0fc
listtab sector_main allnumber000* using "$TABLE/Table2.tex", replace rstyle(tabular) 