/************ Function ************/

*This file cleans 2000 to 2003 Corporation Source Book data

/************ Source ************/

*"input/soi/source_book/sb_`yr" downloaded from https://www.irs.gov/statistics/soi-tax-stats-corporation-source-book-publication-1053


clear all

gen sector_final = ""
tempfile data
save "`data'"

/* Import Excels */

clear
local year_list 2000 2001 2002 2003

foreach yr of local year_list {

	// Save a list of all the sheets
	import excel "$DATA/soi/source_book/sb_`yr'.xlsx", describe	
	local tables 	
	local N = r(N_worksheet) 
	forvalues i = 1 / `N' {
		local tables `tables' `r(worksheet_`i')'
	}

	// Loop through the sheets
	foreach tab of local tables{
		import excel "$DATA/soi/source_book/sb_`yr'.xlsx", sheet("`tab'") clear
	
		display "`yr'"
		display "`tab'"

		gen 			sector 			= A 				if _n == 3
		gen 			sector_ID 		= A 				if _n == 8
		carryforward 	sector sector_ID, replace
		drop 												if D == ""
		replace 		sector = "" 						if _n <= 3
		replace 		sector_ID = "" 						if _n <= 3

		replace 		A = "ITEM" 							in 1
		replace 		B = "Total" 						in 1
		replace 		B = "" 								in 3
		replace	 		C = "0" 							in 1
		replace 		C = "1" 							in 3
		replace 		sector = "sector" 					in 1
		replace 		sector_ID = "sector_ID" 			in 1

		drop 												if _n == 2
		replace 		A = subinstr(A, word(A, 1), "", 1) 	if real(word(A, 1)) < .
		replace 		A = subinstr(A, ".", "", .) 
		replace 		A = trim(A)

	foreach var of varlist * {
		rename 			`var' `= "v_" + `var'[1] + "_" + `var'[2]'
	}

	
	foreach v of varlist * {		
		gen 			ind_`v' = "***" 					if `v' == "***"
		replace 		`v' = subinstr(`v', "$", "", .) 	if _n <= 3
		replace 		`v' = subinstr(`v', ",", "", .)
		replace			`v' = subinstr(`v', "-", "", .)
		replace 		`v' = subinstr(`v', "[1]", "", .)
		replace 		`v' = subinstr(`v', "*", "", .)	
	}
	

	drop 													if _n == 1 | _n == 2
	
	// Code bracket deletions 
	foreach v of varlist ind_* {	
		replace 		`v' = "0" 							if `v' == ""
		replace 		`v' = "1" 							if `v' == "***"
	}
	drop 				ind_v_ITEM_ ind_v_Total_ ind_v_sector_ ind_v_sector_ID_
	
	
	rename 				v_sector_ 		sector
	rename 				v_sector_ID_ 	sector_ID
	rename 				v_ITEM_ 		item

	replace 			sector_ID = "SECTOR CODE 1" 		if sector_ID == "ALL INDUSTRIES"
	split 				sector_ID
	rename 				sector_ID sector_code
	rename 				sector_ID3 ID

	gen 				sector_final = ID 
	
	// Identify the variables of interest
	gen 				item_final = "assets" 				if item == "Total assets"
	replace 			item_final = "breceipts" 			if item == "Business receipts"
	replace 			item_final = "treceipts" 			if item == "Total receipts"
	replace 			item_final = "cassets" 				if item == "Depletable assets"
	replace 			item_final = "cassets" 				if item == "Depreciable assets"
	replace 			item_final = "cassets" 				if item == "Land"
	replace 			item_final = "intangibles" 			if item == "Intangible assets (Amortizable)"
	replace 			item_final = "negcassets" 			if strpos(item, "ccumulated dep")
	replace 			item_final = "negintangibles" 		if strpos(item, "ccumulated amor")
	replace 			item_final = "ninc" 				if item == "Net income (less deficit)"
	replace 			item_final = "ninc" 				if item == "Net income (less deficit) total"
	replace 			item_final = "number" 				if item == "Number of returns"
	
	keep 													if item_final != ""
	drop 				item
	rename 				item_final item	
	
	destring 			v_*, replace
	
	// Sum items that are assigned to one item category in the harmonization
	foreach v of varlist v_* {
		bysort sector_final item: egen double	temp = total(`v')
		replace							 		`v' = temp if temp != 0
		drop 									temp
	}
	duplicates drop 							sector_final item, force
	
	
	* First reshape
	gen 				sector_item = sector_final + "_" + item 
	destring 			v_*, replace
	keep 				sector_item v_* ind_*
	reshape 			long v_ ind_v_, i(sector_item) j(thres, string)	
	
	split 				sector_item, parse("_")
	rename 				sector_item1 sector_final
	rename 				sector_item2 item
	drop 				sector_item 


	* Second reshape
	gen 				sector_thres = sector_final + "-" + thres 
	drop 				sector_final thres 
	reshape wide 		v_ ind_v_, i(sector_thres) j(item, string)	
	split 				sector_thres, parse("-")
	rename 				sector_thres1 sector_final
	rename 				sector_thres2 thres
	drop 				sector_thres

	* Create separate threshold variables
	split 				thres, parse("_")
	rename 				thres1 thres_low
	rename 				thres2 thres_high
	drop 				thres


	destring	 		v_*, replace	
	renvars 			v_*, predrop(2)
	gen 				year = `yr'
	
	append using 		`data' 
	save 				"`data'", replace
	}
}


use 					`data', clear

destring 				ind_v_assets, gen(ind_assets)
destring 				ind_v_number, gen(ind_number)
drop 					ind_v_*

/* Bracket deletions */

// Combine indicator variable
foreach v of varlist ind_assets ind_number {
	bysort year sector_final thres_low: 	egen temp = max(`v')
	replace 								`v' = temp
	drop 									temp
}

egen 										temp = rowmax(ind_number ind_assets)
gen 										bracket_deletion = "no" 			if temp != 1
replace 									bracket_deletion = "yes" 			if temp == 1
bysort 	year sector_final: egen 			temp_total = max(temp)
gen 										bracket_deletion_total = "no" 		if temp_total != 1
replace 									bracket_deletion_total = "yes" 		if temp_total == 1
drop 										temp temp_total ind_number ind_assets


/* Sector Info */

rename 										sector_final ID
merge m:1 ID using "$OUTPUT/temp/sector_list_NAICS_3digit_uniqueID.dta", assert(2 3) gen(m3) keepusing(sector_final sector_level sector_ID sector_main_ID indcode)
keep if m3 == 3 
drop m3

rename 										sector_level sec_level 
rename 										sector_ID sec_ID 
rename 										sector_main_ID 	sec_main_ID 
rename 										indcode scode 


/* Finalize */

// Adjustment for "returns with zero assets"
local varlist assets cassets negcassets intangibles negintangibles 

foreach v of local varlist {
	replace `v' = 0 															if `v' == . & thres_low == "0" & bracket_deletion != "yes"  
}

// Correct thresholds
gen 	low = ""
replace low = "0" 			if thres_low == "0"
replace low = "1" 			if thres_low == "1"
replace low = "100000" 		if thres_low == "100"
replace low = "250000" 		if thres_low == "250"
replace low = "500000" 		if thres_low == "500"
replace low = "1000000" 	if thres_low == "1000"
replace low = "5000000" 	if thres_low == "5000"
replace low = "10000000" 	if thres_low == "10000"
replace low = "25000000" 	if thres_low == "25000"
replace low = "50000000" 	if thres_low == "50000"
replace low = "100000000" 	if thres_low == "100000"
replace low = "250000000" 	if thres_low == "250000"
replace low = "500000000" 	if thres_low == "500000"
replace low = "2500000000" 	if thres_low == "2500000"
replace low = "Total" 		if thres_low == "Total"


gen 	high = ""
replace high = "1" 			if thres_high == "1"
replace high = "100000" 	if thres_high == "100"
replace high = "250000" 	if thres_high == "250"
replace high = "500000" 	if thres_high == "500"
replace high = "1000000" 	if thres_high == "1000"
replace high = "5000000" 	if thres_high == "5000"
replace high = "25000000" 	if thres_high == "25000"
replace high = "50000000" 	if thres_high == "50000"
replace high = "10000000" 	if thres_high == "10000"
replace high = "100000000" 	if thres_high == "100000"
replace high = "250000000" 	if thres_high == "250000"
replace high = "500000000" 	if thres_high == "500000"
replace high = "2500000000" if thres_high == "2500000"
replace high = "more" 		if thres_high == "more"
replace high = "Total" 		if thres_high == "Total"

replace thres_high 	= high
replace thres_low 	= low
drop 	high low
ren 	sector_final sector

gen 	source = "sb2000_2003"

save "$OUTPUT/temp/by_sector_and_assets_2000_2003.dta", replace
