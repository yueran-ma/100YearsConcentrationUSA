/************ Function ************/

*This file makes Figure IA10 of the paper on comparison with Compustat data 

/************ Source ************/

*Compustat North America Fundamental Annual data: "$DATA/compustat/compustat_ann_latest.dta" downloaded from https://wrds-www.wharton.upenn.edu/pages/get-data/compustat-capital-iq-standard-poors/compustat/north-america-daily/fundamentals-annual/
*Consolidation Level = C, Industry Format = INDL, Data Format = STD, Population Source = D, Currency = USD, Company Status = Active (A) + Inactive (I), Variable Types = Data Items
*SOI total receipts and assets for denominator: "output/soi/brackets/sector_brackets_assets_R5.dta" compiled by code/clean/generate_by_sector_by_assets.do
*SOI estimated topN shares: "output/soi/topshares/sector_concent_topN_R5.dta" compiled by code/clean/compute_concentration_sector.do

/************ Steps ************/

*Sort Compustat by sales/assets and sum top 500 accordingly, then merge with SOI estimated top 500 shares

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

/* Compustat Data */

use "$DATA/compustat/compustat_ann_latest.dta", clear

// Keep only US companies
keep if fic == "USA"
	
// Drop federal agencies
drop if tic == "3FNMA" 															// Fannie Mae
drop if tic == "3FMCC" 															// Freddie Mac
	
// Get calendar dates
gen 	yrq 	= qofd(datadate)
gen 	ym 		= ym(fyear, fyr) 	if fyr >= 6
replace ym 		= ym(fyear+1, fyr) 	if fyr <= 5
gen 	yq 		= qofd(dofm(ym))
gen 	year 	= year(dofm(ym))

// Tag the top 500 in Compustat
foreach outcome in sale at  {
	gsort year -`outcome'
	by year: gen 	n = _n

	foreach item in 500 {
		gen 		top`item' 		= 0
		replace 	top`item' 		= 1 					if n <= `item'
		gen double	`outcome'`item' = `outcome' * top`item'
	}

	drop n top*
}
 
collapse (sum) *500*, by(year)

tempfile cpst
save "`cpst'"
 
/* SOI Data */

use "$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", clear

collapse (mean) assets_total breceipts_total, by(sector_main year)

keep if sector_main == "All"
drop sector_main

tempfile total
save "`total'"

use "$OUTPUT/soi/topshares/sector_concent_topN_R5.dta", clear

keep if sector_main == "All"

merge 1:1 year using "`total'", keep(1 3)
tab _merge
drop _merge

merge 1:1 year using "`cpst'", keep(1 3)
tab _merge
drop _merge

gen double at500shr 	= at500 * 10^6 / assets_total
gen double sale500shr 	= sale500 * 10^6 / breceipts_total

label var tsh_assets_ipol_500firms "SOI"
label var at500shr "Compustat"
label var tsh_receipts_ipol_500firms "SOI"
label var sale500shr "Compustat"
label var year "Year"

***********************************************
**                  Panel A                  **
***********************************************

twoway 	(line tsh_assets_ipol_500firms year) ///
		(line at500shr year, lpattern(longdash) lcolor(midblue)) if year >= 1960 & year <= 2013, ///
		ytitle("Top 500 Asset Share") ///
		ylabel(0 "0" 0.2 "0.2" 0.4 "0.4" 0.6 "0.6" 0.8 "0.8" 1 "1.0")  ///
		graphregion(margin(small))   	
graph export "$FIGURE/FigureIA10_PanelA.pdf", replace

***********************************************
**                  Panel B                  **
***********************************************

twoway 	(line tsh_receipts_ipol_500firms year) ///
		(line sale500shr year, lpattern(longdash) lcolor(midblue)) if year >= 1960 & year <= 2013, ///
		ytitle("Top 500 Receipt Share") ///
		ylabel(0 "0" 0.2 "0.2" 0.4 "0.4" 0.6 "0.6" 0.8 "0.8" 1 "1.0") ///
		graphregion(margin(small))   	
graph export "$FIGURE/FigureIA10_PanelB.pdf", replace


