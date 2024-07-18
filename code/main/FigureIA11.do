/************ Function ************/

*This file makes Figure IA11 of the paper using BEA data on the foreign affiliates of U.S. multinational firms 

/************ Source ************/

*BEA data: "$OUTPUT/other/combined_international_tables.csv" compiled by code/clean/international.py
*SOI data: total assets from "output/soi/brackets/sector_brackets_assets_R5.dta" compiled by code/clean/by_sector_by_assets_generate_dataset.do and top share estimates "output/soi/topshares/sector_concent_R5.dta" compiled by code/clean/compute_concentration_sector.do

/************ Steps ************/

*Assign BEA data to main sectors using industry_level, which codes hierarchies in BEA data 
*Then merge with SOI data and construct modified top shares including assets of foreign affiliate

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

/* BEA Data on Foreign Affiliates of US Multinationals */

import delimited "$OUTPUT/other/combined_international_tables.csv", clear 

ren industry_level level
ren industry_name industry

gen sector_main = ""

*** Assign main sectors ***

replace industry = trim(industry)

replace sector_main = "All" if level == 0

// Pre-1999
replace sector_main = "Agriculture" 	if industry == "Other industries_Agriculture, forestry, and fishing" 					& level == 2 & year <= 1998
replace sector_main = "Construction" 	if industry == "Other industries_Construction" 						 					& level == 2 & year <= 1998
replace sector_main = "Finance" 		if industry == "Banking" 											 					& level == 1 & year <= 1998
replace sector_main = "Finance" 		if strpos(industry, "Finance") 															& level == 1 & year <= 1998

replace sector_main = "Manufacturing" 	if industry == "Manufacturing" 															& level == 1 & year <= 1998
replace sector_main = "Manufacturing" 	if industry == "Petroleum_Petroleum and coal products" 									& level == 2 & year <= 1998
replace sector_main = "Mining" 			if industry == "Other industries_Mining" 												& level == 2 & year <= 1998
replace sector_main = "Mining" 			if industry == "Petroleum_Oil and gas extraction" 										& level == 2 & year <= 1998

replace sector_main = "Services" 		if industry == "Services" 																& level == 1 & year <= 1998
replace sector_main = "Trade" 			if industry == "Other industries_Retail trade" 											& level == 2 & year <= 1998
replace sector_main = "Trade" 			if industry == "Wholesale trade" 														& level == 1 & year <= 1998
replace sector_main = "Trade" 			if industry == "Petroleum_Petroleum wholesale trade" 									& level == 2 & year <= 1998

replace sector_main = "Utilities" 		if industry == "Other industries_Transportation, communication, and public utilities" 	& level == 2 & year <= 1998 & year <= 1988
replace sector_main = "Utilities" 		if industry == "Other industries_Transportation" 										& level == 2 & year <= 1998 & year >= 1989
replace sector_main = "Utilities"		if industry == "Other industries_Communication and public utilities"					& level == 2 & year <= 1998 & year >= 1989
replace sector_main = "Utilities" 		if industry == "Petroleum_Other" 														& level == 2 & year <= 1998

// Post-1999
replace sector_main = "Agriculture" 	if industry == "Other industries_Agriculture, forestry, fishing, and hunting" 			& level == 2 & year >= 1999
replace sector_main = "Construction" 	if industry == "Other industries_Construction" 						 					& level == 2 & year >= 1999

replace sector_main = "Finance" 		if strpos(industry, "Finance") 															& level == 1 & year >= 1999
replace sector_main = "Finance"			if industry == "Other industries_Management of nonbank companies and enterprises"		& level == 2 & year >= 1999
replace sector_main = "Finance" 		if industry == "Other industries_Real estate" 											& level == 3 & year >= 1999
replace sector_main = "Finance" 		if industry == "Other industries_Rental and leasing (except real estate)" 				& level == 3 & year >= 1999

replace sector_main = "Manufacturing" 	if industry == "Manufacturing" 															& level == 1 & year >= 1999
replace sector_main = "Manufacturing" 	if industry == "Information_Publishing industries" 										& level == 2 & year >= 1999
replace sector_main = "Mining" 			if industry == "Mining" 																& level == 1 & year >= 1999

replace sector_main = "Services" 		if strpos(industry, "Professional") 													& level == 1 & year >= 1999
replace sector_main = "Services" 		if industry == "Information_Motion picture and sound recording industries" 				& level == 2 & year >= 1999
replace sector_main = "Services" 		if industry == "Information_Information services and data processing services" 			& level == 2 & year >= 1999 & 	year <= 2003
replace sector_main = "Services" 		if industry == "Information_Internet, data processing, and other information services" 	& level == 2 & year >= 1999 & inrange(year, 2004, 2008)
replace sector_main = "Services" 		if industry == "Information_Data processing, hosting, and related services" 			& level == 2 & year >= 1999 & 	year >= 2009
replace sector_main = "Services" 		if industry == "Information_Other information services" 								& level == 2 & year >= 1999 &	year >= 2009
replace sector_main = "Services"		if industry == "Other industries_Health care and social assistance"						& level == 2 & year >= 1999
replace sector_main = "Services"		if industry == "Other industries_Miscellaneous services"								& level == 2 & year >= 1999
replace sector_main = "Services" 		if industry == "Other industries_Administrative and support services" 					& level == 3 & year >= 1999
replace sector_main = "Services" 		if industry == "Other industries_Accommodation" 										& level == 3 & year >= 1999

replace sector_main = "Trade" 			if industry == "Other industries_Retail trade" 											& level == 2 & year >= 1999 &	year <= 2008
replace sector_main = "Trade" 			if industry == "Retail trade" 															& level == 1 & year >= 1999 &	year >= 2009
replace sector_main = "Trade" 			if industry == "Wholesale trade" 														& level == 1 & year >= 1999
replace sector_main = "Trade" 			if industry == "Other industries_Food services and drinking places" 					& level == 3 & year >= 1999	

replace sector_main = "Utilities" 		if industry == "Other industries_Transportation and warehousing" 						& level == 2 & year >= 1999
replace sector_main = "Utilities" 		if strpos(industry, "Information_Broadcasting")					 						& level == 2 & year >= 1999
replace sector_main = "Utilities" 		if industry == "Other industries_Waste management and remediation services" 			& level == 3 & year >= 1999

keep if sector_main != ""

keep sector_main year nbraffiliates totalassets sales byparentindustry_nbrusparents byparentindustry_totalassets_par byparentindustry_nbraffiliates byparentindustry_totalassets_aff

foreach item of varlist nbraffiliates - byparentindustry_totalassets_aff {
	replace `item' = "" if strpos(`item', "(D)")								
	replace `item' = subinstr(`item', ",", "", .)
	destring `item', replace
}

*** Sum foreign affiliate assets by main sector ***

preserve

keep if sector_main != "All" 

collapse (sum) nbraffiliates totalassets sales byparentindustry_nbrusparents byparentindustry_totalassets_par byparentindustry_nbraffiliates byparentindustry_totalassets_aff, by(sector_main year)

tempfile foreign
save "`foreign'"

restore

*** Total foreign affiliate assets ***

keep if sector_main == "All"

collapse (sum) nbraffiliates totalassets sales byparentindustry_nbrusparents byparentindustry_totalassets_par byparentindustry_nbraffiliates byparentindustry_totalassets_aff, by(sector_main year)

tempfile foreignall
save "`foreignall'"


/* SOI Data */

use "$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", clear

collapse (mean) assets_total, by(sector_main year)

tempfile total
save "`total'"

use "$OUTPUT/soi/topshares/sector_concent_R5.dta", clear

merge 1:1 sector_main year using "`total'", keep(1 3)
tab _merge
drop _merge

// Total assets of top 1% corps
gen double assets_top1 = tsh_assets_ipol_1pct * assets_total								

*** Merge in foreign affiliate assets ***

merge m:1 sector_main year using "`foreign'", keep(1 3)
tab _merge
drop _merge

merge m:1 sector_main year using "`foreignall'", keep(1 3 4 5) update
tab _merge
drop _merge

*** Adjust to include foreign affiliate assets ***

// Attribute all foreign affliates to top 1% corps
gen double tsh_assets_ipol_1pct_alt1 = (assets_top1 + byparentindustry_totalassets_aff * 10^6) / (assets_total + byparentindustry_totalassets_aff * 10^6)

// Attribute foreign affliates to top 1% corps according to share of domestic
gen double tsh_assets_ipol_1pct_alt2 = (assets_top1 + tsh_assets_ipol_1pct * byparentindustry_totalassets_aff * 10^6) / (assets_total + byparentindustry_totalassets_aff * 10^6)

label var tsh_assets_ipol_1pct "Top 1% Asset Share (Original)"
label var tsh_assets_ipol_1pct_alt1 "Top 1% Asset Share (All International Assets Belong to Top)"
label var tsh_assets_ipol_1pct_alt2 "Top 1% Asset Share (All International Assets Allocated Proportionally)"

local size medlarge
local size2 large
local s_list All Agriculture Construction Finance Manufacturing Mining Services Trade Utilities
local ytlist ""Share" " " " " "Share" " " " " "Share" " ""
local snum : word count `s_list'

local allnames ""

forvalues i = 1 / `snum' {
	local s : word `i' of `s_list'
	local yt : word `i' of `ytlist'
	
	twoway  (line tsh_assets_ipol_1pct year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
			(line tsh_assets_ipol_1pct_alt1 year, cmissing(no) lcolor(red) lpattern(dash) lwidth(medthick)) ///
			(line tsh_assets_ipol_1pct_alt2 year, cmissing(no) lcolor(purple) lpattern(dash_dot) lwidth(medthick)) if sector_main == "`s'" & year >= 1930, ///
			ytitle(`yt', size(`size')) xtitle("") title(`s', size(`size2')) ///
			ylabel(, format(%03.1f) grid labsize(`size') angle(0)) xlabel(1930(20)2010, grid labsize(`size')) ///
			legend(symxsize(*0.7) region(lwidth(none)) cols(1))	///
			name(con_`s', replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw	
			local allnames `allnames' con_`s'	
}

grc1leg `allnames', iscale(*0.95) ycommon cols(3) scheme(s1color) graphregion(margin(tiny)) name(all_graph, replace) 
resize all_graph, ysize(4.5) xsize(5.5)
graph export "$FIGURE/FigureIA11.pdf", replace 