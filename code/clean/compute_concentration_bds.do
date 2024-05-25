/************ Function ************/

*This file uses generalized Pareto interpolation to estimate top shares in BDS data by employment size bins

/************ Source ************/

*input/bds/bds2021_fz.csv downloaded from https://www.census.gov/data/datasets/time-series/econ/bds/bds-datasets.html

clear all


*============= Prepare BDS file ================================

import delimited "$DATA/bds/bds2021_fz.csv", clear

rename firms number

gen 	thres_low 	= 	.
replace thres_low 	= 	1 		if fsize == "a) 1 to 4"  
replace thres_low 	= 	5 		if fsize == "b) 5 to 9"  
replace thres_low 	= 	10 		if fsize == "c) 10 to 19"  
replace thres_low 	= 	20 		if fsize == "d) 20 to 99"  
replace thres_low 	= 	100 	if fsize == "e) 100 to 499"  
replace thres_low 	= 	500 	if fsize == "f) 500 to 999"  
replace thres_low 	= 	1000 	if fsize == "g) 1000 to 2499"  
replace thres_low 	= 	2500 	if fsize == "h) 2500 to 4999"  
replace thres_low 	= 	5000 	if fsize == "i) 5000 to 9999"  
replace thres_low 	= 	10000 	if fsize == "j) 10000+"  

gen 	thres_high  =	""
replace thres_high 	= 	"4"	 	if fsize == "a) 1 to 4"  
replace thres_high 	= 	"9" 	if fsize == "b) 5 to 9"  
replace thres_high 	= 	"19" 	if fsize == "c) 10 to 19"  
replace thres_high 	= 	"99" 	if fsize == "d) 20 to 99"
replace thres_high 	= 	"499" 	if fsize == "e) 100 to 499"
replace thres_high 	= 	"999" 	if fsize == "f) 500 to 999"  
replace thres_high 	= 	"2499" 	if fsize == "g) 1000 to 2499"  
replace thres_high 	= 	"4999" 	if fsize == "h) 2500 to 4999"  
replace thres_high 	= 	"9999" 	if fsize == "i) 5000 to 9999"  
replace thres_high 	= 	"more" 	if fsize == "j) 10000+"  

gen sector_main ="All"

// Create separate variables for totals
bysort year: egen double number_total = sum(number)
bysort year: egen double emp_total = sum(emp)

collapse (mean) number* emp* (last) thres_high, by(year thres_low)


*===== Some brackets are not "within" bounds =======

/* Identify probematic brackets */
sort 			year thres_low
gen double		av = emp / number

// Case average is above the threshold  
by year: gen 	d_temp		= 1 	if av[_n] 	> thres_low[_n+1] 	& av != . 		& av[_n+1] != .	& av[_n+1] != 0
by year: gen 	d_temp2 	= 1 	if av[_n-1] > thres_low[_n] 	& av[_n-1] != . & av[_n] != .  	& av[_n] != 0

// Case average is below the threshold  
by year: gen 	d_temp3 	= 1 	if av[_n] 	< thres_low[_n] 	& av != . 		& av[_n] != . 	& av[_n] != 0
by year: gen 	d_temp4 	= 1 	if av[_n+1] < thres_low[_n+1] 	& av[_n+1] != . & av[_n+1] != .  & av[_n+1] != 0
gen 			d_comb 		= 1 	if d_temp == 1 | d_temp2 == 1 | d_temp3 == 1 | d_temp4 == 1

// Sum bracket with next highest bracket
local vars number emp
foreach var of local vars {	
	bysort year: egen double 	`var'_temp = total(`var') 						if d_comb == 1, missing
	replace 					`var' = `var'_temp 								if d_comb == 1
	drop 						`var'_temp
}	
bysort year: egen double 		thres_low_temp = min(thres_low) 				if d_comb == 1, missing
drop 																			if year[_n] == year[_n-1] & d_comb[_n] == d_comb[_n-1] & d_comb == 1
drop 							d_comb d_temp d_temp2 d_temp3 d_temp4 av thres_low_temp

tempfile bds
save "`bds'"	
	




*============= Interpolate concentration ratios ================================

clear all

// Generate file for concentration estimates 
gen year =.
tempfile bds_concent
save "`bds_concent'"	
	

forvalues i = 1978/2018 {
	local years `years' "`i'"
}

foreach y of local years {

	use "`bds'", clear

	keep if year == `y'
	drop if number == .

	// Percentiles
	gen double		pctile 		= number / number_total 
	gen double		p 			= 0 in 1
	replace 		p 			= pctile[_n-1] + p[_n-1] 	if _n > 1
		
	// Create variables for gpinter
	gen double		average 	= emp_total / number_total 						// Average overall
	gen double		bracketavg  = emp / number 									// Average in each bracket
	replace 		bracketavg 	= 0 						if bracketavg == . 	& emp == . & thres_low == 0  // R reads zero as -0.00
	replace 		bracketavg 	= 0.0001 					if bracketavg == 0 	// R reads zero as -0.00

	rename 			thres_low threshold
	sort 			threshold

	keep 			year p bracketavg average threshold emp_total number_total  

	// Save the tabulation as a Stata file and run Gpinter
	// Using "saveold" allows R to read the file from very recent STATA versions
	saveold "$OUTPUT/temp/tabulation-input.dta", version(11) replace 

	// Run Gpinter
	shell "$Rdirscript" "gpinter_code.R" "$RWORKDIR"
	
	// Keep vars that are constant 
	keep year emp_total number_total
	keep if _n == 1


	// Import distribution and keep key statistics
	cross using "$OUTPUT/temp/tabulation-output.dta"

	drop bracket_share top_average bottom_average bracket_average threshold bottom_share gini invpareto

	gen 	pct				= 1 							if _n <= 127		
	
	gen 	varname 		= ""
	replace varname 		= "_50pct" 						if p == 0.5 		& pct == 1
	replace varname 		= "_10pct" 						if p == 0.9 		& pct == 1
	replace varname 		= "_1pct" 						if p == 0.99 		& pct == 1
	replace varname 		= "_0_1pct" 					if p == 0.999 		& pct == 1

	drop 	p pct  
	keep 													if varname != ""

	// Reshape to create time series structure
	reshape wide top_share, i(year) j(varname) string

	// Merge years
	merge 1:1 year using "`bds_concent'", nogen
	sort year
	save "`bds_concent'", replace
}

// Identify failed interpolations and set values to missing (too few brackets)
sort 		year 
gen 		issues = 1 										if top_share_1pct[_n] == top_share_1pct[_n-1]

foreach var of varlist top_* {
	replace `var' = . 										if issues == 1
}
drop 		issues

keep 		year top_share_1pct top_share_0_1pct 

label var 	year 				"Year"
label var 	top_share_1pct 		"Top 1% employment share"
label var 	top_share_0_1pct 	"Top 0.1% employment share"

order 		year top_share_0_1pct top_share_1pct

save  "$OUTPUT/other/bds_concent.dta", replace
capture erase "$OUTPUT/temp/tabulation-input.dta"
capture erase "$OUTPUT/temp/tabulation-output.dta"





