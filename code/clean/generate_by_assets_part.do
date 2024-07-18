/************ Function ************/

*This file cleans raw tabulations by asset size for partnerships and produces cleaned tabulations "output/soi/brackets/agg_type_brackets_assets_R5.dta"

/************ Source ************/

* "input/soi/digitized/partnerships_by_assets_raw_R5.dta" and "output/soi/brackets/sector_brackets_assets_R5.dta" compiled by code/clean/generate_by_sector_by_assets.do

/************ Notes ************/

*We use the sum over bins to construct *_total (no bracket deletions here)


clear all



*===============================================================
*======== Prepare the combined data for the analysis
*===============================================================

use "$DATA/soi/digitized/part_raw_assets_R5.dta", clear


sort year thres_low
order year


/* Item preparation */

// Create variables for the totals
local vars number assets 

* Generate separate variables for the totals
foreach var of local vars { 

	* Stated totals
	gen double 									temp = `var' 					if thres_low == "Total"
	bysort year: egen double 					`var'_total_stated = min(temp)
	drop 										temp
	
	* Computed totals (add up stated totals)
	bysort year thres_low: egen double 			`var'_total = total(`var'_total_stated) 
	replace 									`var'_total = . 				if `var'_total == 0
	
	* Computed totals (add up brackets)
	bysort year: egen double 					`var'_total_alt = total(`var')  if thres_low != "Total"
	replace 									`var'_total_alt = . 			if `var'_total_alt == 0
	
	* Replace with adding up brackets (no bracket deletions here)
	replace										`var'_total = `var'_total_alt 	 
	
}

drop if 										thres_low == "Total"
cap drop 										*_stated *_alt


// "Sum" negative assets and zero assets
gen 														ind_zero = 1 		if thres_low == "less"
replace 													ind_zero = 1 		if thres_low == "0"
replace 													assets = 0 			if thres_low == "less" // Firms in liquidation; not key for numerator

replace 													thres_low = "0" 		if thres_low == "less"
replace 													thres_high = "1" 	if thres_high == "0"

// Compute their totals
local vars number assets
foreach var of local vars {	
	bysort year tables thres_low: egen double				`var'_temp = total(`var')
	replace 												`var' = `var'_temp 	if `var'_temp != 0 
	drop 													`var'_temp
}
duplicates drop 											year tables thres_low, force

local vars number assets
foreach var of local vars {	
	bysort year tables: egen double 						`var'_total_temp = total(`var')
	replace 												`var'_total = `var'_total_temp if `var'_total_temp != 0
	drop 													`var'_total_temp 
}

sort 														year table thres_low
destring 													thres_low, replace

// Drop empty brackets
drop 																			if number == 0

sort 														year tables thres_low
order 														year tables thres_low

keep 														year tables thres_low number number_total assets assets_total
 

/* Combine with corporations by asset tabulations */

preserve

use "$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", clear

keep if		sector_main == "All"
gen 		tables = "Corporations"

keep 		year tables thres_low number number_total assets assets_total bracket_deletion bracket_deletion_total 

// Keep the years with partnerships by asset tabulations 
keep if (year >= 1965 & year <= 1982) | year >= 2002
drop if year == 1979

tempfile 	corp
save 		"`corp'"

restore

append using "`corp'"

/* Finalize */

gen			sector_main = "All"
gen 		type = ""
replace 	type = "corp" 					if tables == "Corporations"
replace 	type = "part" 					if tables == "Partnerships"

replace 	bracket_deletion = "no" 		if bracket_deletion == ""
replace 	bracket_deletion_total = "no" 	if bracket_deletion_total == ""

keep 		sector_main type tables year thres_low number number_total assets assets_total bracket_deletion bracket_deletion_total	
order 		sector_main type tables year thres_low number number_total assets assets_total bracket_deletion bracket_deletion_total 

label var	sector_main						"Main sector"
label var 	year 							"Year"
label var 	type 							"Entity type"
label var   tables							"Tabulation type"
label var	thres_low						"Bin threshold low" 
label var 	number 							"Number" 
label var 	number_total					"Number, all" 
label var 	assets 							"Assets"
label var 	assets_total 					"Assets, all"
label var 	bracket_deletion 				"Combined bracket"
label var 	bracket_deletion_total			"Year with combined bracket"

sort 		tables year thres_low

save 		"$OUTPUT/soi/brackets/agg_type_brackets_assets_R5.dta", replace
