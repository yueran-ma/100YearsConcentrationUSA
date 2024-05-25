/************ Function ************/

*This file makes Table 3 of the paper 

/************ Source ************/

*"output/soi/topshares/sector_concent_R5.dta" compiled by code/clean/compute_concentration_sector.do

clear all


******************************************************
* set graph style
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

use "$OUTPUT/soi/topshares/sector_concent_R5.dta", clear

gen decade = floor(year/10)

collapse (mean) tsh_assets_ipol_1pct, by(sector_main decade)

replace decade = decade*10
drop if decade == 1920 | decade == 1910

gen 	sector_ID = 1 if sector_main == "All"
replace sector_ID = 2 if sector_main == "Agriculture"
replace sector_ID = 3 if sector_main == "Construction"
replace sector_ID = 4 if sector_main == "Finance"
replace sector_ID = 5 if sector_main == "Manufacturing"
replace sector_ID = 6 if sector_main == "Mining"
replace sector_ID = 7 if sector_main == "Services"
replace sector_ID = 8 if sector_main == "Trade"
replace sector_ID = 9 if sector_main == "Utilities"

replace tsh_assets_ipol_1pct = round(tsh_assets_ipol_1pct, 0.01)
format tsh_assets_ipol_1pct %03.2f
reshape wide tsh_assets_ipol_1pct, i(sector_ID) j(decade)

// Reduce number of columns - AER table style guidelines
drop tsh_assets_ipol_1pct1940 tsh_assets_ipol_1pct1960 tsh_assets_ipol_1pct1980 tsh_assets_ipol_1pct2000

listtab sector_main tsh_assets_ipol_1pct* using "$TABLE/Table3.tex", replace rstyle(tabular)  
