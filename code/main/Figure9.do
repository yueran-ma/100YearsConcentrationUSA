/************ Function ************/

*This file makes Figure 9 of the paper using census CRx data 

/************ Source ************/

*Pre-1997 Census data: "input/census/concentration92-47.xls" downloaded from https://www.census.gov/data/tables/1992/econ/census/concentraion-ratio-data.html
*Post-1997 Census data: "output/other/census9712.dta" compiled by code/clean/clean_census_9712.do 
*2012 SOI data: "output/soi/brackets/minor_industry_2012_brackets_assets_R5.dta" compiled by code/clean/generate_by_sector_by_assets_2012_cross_section.do

/************ Notes ************/

*Pre-1997 data only available from manufacturing census for 4-digit sics
*Post-1997 data available at different levels of naics 

/************ Steps ************/

*Panel A: compute value-weighted and equal-weighted CR20
*Panel B: for 2012, compare census CR20 with top 20 shares imputed from SOI data for granual industries from 2012 SOI Source Book 
*		  for these granualar industries, SOI only has size brackets by assets, so we have to compute the receipts of top 20 by assets in total receipts
*		  bridge is "$DATA/soi/SOI_code.xlsx" (contains explaination for its construction)

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

***********************************************
**                  Panel A                  **
***********************************************

/* Census Manufacturing Data: Pre-1997 */

import excel "$DATA/census/concentration92-47.xls", cellrange(A4:V3602) firstrow clear

// Name the variables 
ren ValueofShipments1000 	Value
ren F 						Valuef
ren largestcompanies 		CR4 
ren I	 					CR4f
ren J 						CR8
ren K 						CR8f 
ren L 						CR20 
ren M 						CR20f 
ren N 						CR50 
ren O 						CR50f

destring _all, replace
gen year = YR + 1900

drop if Numberof ==	0  
drop if year == 1966															// a lot of data missing for this year
drop RSE

foreach item of varlist CR4 CR8 CR20 CR50 {
	replace `item' = 100 		if `item'f == "X"								// these flags are used for maxing out at 100 (fewer than x firms)
	replace `item' = `item'/100
	replace `item' = . 			if `item' == 0
}

// Equal weighted average 
foreach item of varlist CR4 CR8 CR20 CR50 {
	bysort year: egen double	`item'mean = mean(`item')
}

drop CR*f 																		// remove flags

collapse (mean) CR* [aw=Value], by(year)

/* Census Manufacturing Data: Post-1997 */

preserve
use "$OUTPUT/other/census9712.dta", clear 

// Keep naics6 to be consistent with sic4 in pre-1997 data
keep if strlen(naics) == 6

// Keep manufacturing 
keep if substr(naics, 1, 1) == "3"   

foreach item of varlist CR4 CR8 CR20 CR50 {
	replace `item' = `item' / 100
}

foreach item of varlist CR4 CR8 CR20 CR50 {
	bysort year: egen double	`item'mean = mean(`item')
}

drop CR*f

collapse (mean) CR* [aw = value], by(year)

tempfile censusmore
save "`censusmore'"
restore

// Combine pre-1997 and post-1997 data 
append using "`censusmore'"

foreach t in 4 8 20 50 {
	label var CR`t' "CR`t' (value weighted)"
	label var CR`t'mean "CR`t' (equal weighted)"
}
label var year "Year"

twoway 	(connect CR20 year) (connect CR20mean year, lpattern(longdash) mcolor(midblue) lcolor(midblue)), ///
		ytitle("Average Top 20 Sales Share") ylabel(, format(%03.2f)) legend(label(1 "Value-Weighted") label(2 "Equal-Weighted"))
graph export "$FIGURE/Figure9_PanelA.pdf", replace
graph export "$FIGURE/Figure9_PanelA.eps", replace


***********************************************
**                  Panel B                  **
***********************************************

/* Census Concentration Data */

use "$OUTPUT/other/census9712.dta", clear 

ren value rev_all
drop CR*f

tempfile census
save "`census'"

/* SOI Concentration Data */

use "$OUTPUT/soi/brackets/minor_industry_2012_brackets_assets_R5.dta", clear

gen 								digit = strlen(sector_ID)
destring 							sector_ID, replace

gsort 								year sector_ID -thres_low	
by year sector_ID: gen 				rank_hi = _n

*** Top 20 firms *** 

// Cumulative number of firms in each bracket
gen double							nb 				= number 						if rank_hi == 1
sort 								sector_ID year rank
by sector_ID year: 					replace nb 		= nb[_n-1] + number 			if nb == .
 
// Buckets above and below 20 firms 
gen 								pass_nb 		= 0 							if nb <= 20
replace 							pass_nb 		= 1 							if nb > 20

by sector_ID year: gen 				boundary_nb 	= 1 							if nb <= 20 & nb[_n+1] > 20
bysort sector_ID year: egen double	tmp_nb 			= sum(number) 					if pass_nb == 0

// Estimate top 20 total
sort 								sector_ID year rank
gen double							remainder_nb 	= (20 - tmp_nb) / number[_n+1] 	if boundary_nb == 1
replace 							remainder_nb 	= 1 							if remainder_nb > 1 & remainder_nb != .

foreach item in assets breceipts treceipts {
	by sector_ID year: egen double	`item'_top20 	= sum(`item') 					if pass_nb == 0
	replace				 			`item'_top20 	= `item'_top20 + remainder_nb *`item'[_n+1] if boundary_nb == 1
	replace 						`item'_top20 	= . 							if boundary_nb != 1
} 

cap drop 							bracket_deletion_total

collapse (mean) *_top* *_total digit, by(sector_ID year)

// Top 20 share 
foreach item in assets breceipts treceipts {
	gen double						`item'_top20_shr = `item'_top20 / `item'_total
}

keep sector_ID *top* digit

tempfile soiaddup
save "`soiaddup'"

/* Bridge between SOI and Census */

import excel "$DATA/soi/sector_file.xlsx", sheet("NAICS_Industry code titles_2012") firstrow clear

// SOI industry IDs
gen 							sector_ID = Minor 								if real(Minor) != .
replace 						sector_ID = Major         						if real(Major) != . & sector_ID == ""
destring 						sector_ID, replace
replace 						sector_ID = Sector 								if sector_ID == .
order 							sector_ID

missings dropvars, force
missings dropobs, force

// Get the NAICS codes mapped to each SOI industry ID
ren 							NAICS* naics*

reshape long naics, i(sector_ID) j(count)

drop if naics == .
drop count

// Number of naics codes mapped to SOI code
bysort sector_ID: gen 			N = _N													
tostring naics, replace

// Merge in SOI top shares
merge m:1 sector_ID using "`soiaddup'", keep(1 3)
tab _merge
drop _merge

// Merge in census top shares
cap drop 						year
gen 							year = 2012
merge m:1 naics year using "`census'", keep(1 3)
tab _merge
drop _merge

foreach t in 4 8 20 50 {
	replace CR`t' =  CR`t' / 100
}

*** Compare Census concentration and SOI concentration ***

tostring sector_ID, gen(sector_ID_str)
gen 							Manufacturing = substr(sector_ID_str, 1, 1) == "3"

// SOI data use size by business receipts in non-finance sectors and total receipts in finance (because non-business receipts are large)
foreach t in 20 {
	gen double 					receipts_top`t'_shr = breceipts_top`t'_shr
	replace 					receipts_top`t'_shr = treceipts_top`t'_shr 		if substr(sector_ID_str, 1, 2) == "52" | substr(sector_ID_str, 1, 2) == "53" | substr(sector_ID_str, 1, 2) == "55"
}

foreach t in 4 8 20 50 {
	label var CR`t' "Top `t' Sales Share (Census)"
}

pwcorr receipts_top20_shr CR20 													if N == 1 & digit == 6
gen 							dif = receipts_top20_shr - CR20
sum dif 																		if N == 1 & digit == 6, detail

twoway	(scatter receipts_top20_shr CR20 if Manufacturing == 1) ///
		(scatter receipts_top20_shr CR20 if Manufacturing == 0, msymbol(Oh) mcolor(midblue)) ///
		(line CR20 CR20, lcolor(gray)) if N == 1 & digit == 6, ///
		ytitle("Top 20 Sales Share (SOI)") ///
		ylabel(0 "0" 0.2 "0.2" 0.4 "0.4" 0.6 "0.6" 0.8 "0.8" 1 "1.0") xlabel(0 "0" 0.2 "0.2" 0.4 "0.4" 0.6 "0.6" 0.8 "0.8" 1 "1.0") ///
		legend(label(1 "Manufacturing") label(2 "Non-Manufacturing") label(3 "45-Degree Line") cols(3))  
graph export "$FIGURE/Figure9_PanelB.pdf", replace
graph export "$FIGURE/Figure9_PanelB.eps", replace