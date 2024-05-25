/************ Function ************/

*This file prepares data from the 2012 SOI cross-section and produces cleaned tabulations "output/soi/brackets/minor_industry_2012_brackets_assets_R5.dta"

/************ Source ************/

*"input/soi/source_book/12sbfltfile/122012sb1.csv" downloaded from https://www.irs.gov/statistics/soi-tax-stats-corporation-source-book-publication-1053

/************ Notes ************/

*We use the sum over bins to construct *_total, except when there are bracket deletions, in which case we use the stated total 

/************ Steps ************/

*Import data from csv
*Clean bracket deletions
*Clean brackets where the average is out of bounds

clear all



*===============================================================
*======== Import Source Book data
*===============================================================

clear
gen year = .
gen sector_ID = ""
tempfile data
save "`data'"

local list 12 
foreach i of local list {

	import delimited "$DATA/soi/source_book/`i'sbfltfile/20`i'sb1.csv", clear 

	tostring 	indy_cd, gen(ID)
	rename 		ID sector_ID

	local masterlist year sector_ID ac wt_ct tot_assts wt_ct_ind tot_assts_ind comp_tot_rcpts grs_rcpts
	
	local keeplist
	foreach i of local masterlist  {
		capture confirm variable `i'
			if !_rc {
				local keeplist "`keeplist' `i'"
			}
	}
	keep `keeplist'

	// Combine indicator variables of bracket deletion
	rename 								wt_ct_ind ind_number
	rename 								tot_assts_ind ind_assets
	foreach v of varlist ind_assets ind_number {
		bysort year sector_ID ac: egen 	temp = max(`v')
		replace 						`v' = temp
		drop 							temp
	}

	// Define bracket deletion variable
	egen 								temp1 = rowmax(ind_number ind_assets)
	bysort year sector_ID ac: egen 		temp = max(temp1) // Same identifier for all sectors assigned to one final sector
	gen 								bracket_deletion = "no" 				if temp != 3
	replace 							bracket_deletion = "yes" 				if temp == 3
	bysort year sector_ID: egen 		temp_total = max(temp)
	gen 								bracket_deletion_total = "no" 			if temp_total != 3
	replace 							bracket_deletion_total = "yes" 			if temp_total == 3
	drop 								temp temp1 temp_total ind_number ind_assets
		
	// Aggregate by sector 
	local vlist	wt_ct tot_assts 
	foreach v of local vlist {
		cap bysort year sector_ID ac: egen double	temp = sum(`v') 			if bracket_deletion == "no"
		cap bysort year sector_ID ac: replace 		temp = . 					if bracket_deletion == "yes"
		cap drop 									`v'
		cap gen double 								`v' = temp
		cap drop 									temp
	}
	duplicates drop 								year sector_ID ac, force


	rename wt_ct 			number
	rename tot_assts 		assets
	rename comp_tot_rcpts 	treceipts
	rename grs_rcpts 		breceipts


	// 2004-2013 Tables all have the same brackets
	gen 	thres_low = ""
	replace thres_low = "Total"   		if ac ==1
	replace thres_low = "0" 	  		if ac ==2
	replace thres_low = "1" 	  		if ac ==3
	replace thres_low = "500000" 		if ac ==4
	replace thres_low = "1000000" 	  	if ac ==5
	replace thres_low = "5000000" 	  	if ac ==6
	replace thres_low = "10000000"   	if ac ==7
	replace thres_low = "25000000"   	if ac ==8
	replace thres_low = "50000000"   	if ac ==9
	replace thres_low = "100000000"  	if ac ==10
	replace thres_low = "250000000"  	if ac ==11
	replace thres_low = "500000000"  	if ac ==12
	replace thres_low = "2500000000" 	if ac ==13

	gen 	thres_high = ""
	replace thres_high = ""   	   		if ac ==1
	replace thres_high = "1" 	   		if ac ==2
	replace thres_high = "500000" 	   	if ac ==3
	replace thres_high = "1000000"    	if ac ==4
	replace thres_high = "5000000"    	if ac ==5
	replace thres_high = "10000000"   	if ac ==6
	replace thres_high = "25000000"   	if ac ==7
	replace thres_high = "50000000"   	if ac ==8
	replace thres_high = "100000000"  	if ac ==9
	replace thres_high = "250000000"  	if ac ==10
	replace thres_high = "500000000"  	if ac ==11
	replace thres_high = "2500000000" 	if ac ==12
	replace thres_high = "more" 		if ac ==13
	drop 	ac

	append using `data'
	save "`data'", replace
}


*===============================================================
*======== Prepare the combined data for the analysis
*===============================================================

order year sector_ID thres_low
sort year sector_ID thres_low


/* Item preparation */

// Create variables for the totals
local vars number assets breceipts treceipts

* Generate separate variables for the totals
foreach var of local vars {
	replace 											`var' = `var' * 1000 			if "`var'" != "number" & year == 2012
	
	* Stated totals
	gen double 											temp = `var' 					if thres_low == "Total"
	bysort sector_ID year: egen double 					`var'_total_stated = min(temp)
	drop temp
	
	* Computed totals (add up stated totals)
	bysort sector_ID year thres_low: egen double 		`var'_total = total(`var'_total_stated) 
	replace 											`var'_total = . 				if `var'_total == 0
	
	* Computed totals (add up brackets)
	bysort sector_ID year: egen double 					`var'_total_alt = total(`var')  if thres_low != "Total"
	replace 											`var'_total_alt = . 			if `var'_total_alt == 0

	* Replace with adding up brackets (when no bracket deletions)
	replace												`var'_total = `var'_total_alt 	if bracket_deletion_total != "yes"  
}
cap drop 												*_stated

drop 																			if thres_low == "Total"
destring 												thres_low, replace


/* Deal with deleted brackets */

// "Sum" brackets with bracket deletions
encode bracket_deletion_total, gen(ind_bracket_deletion_total)
encode bracket_deletion, gen(ind_bracket_deletion)
bysort sector_ID year thres_low: egen 					temp = max(ind_bracket_deletion)
bysort sector_ID year thres_low: egen 					temp_total = max(ind_bracket_deletion_total)
replace 												bracket_deletion_total = "yes" 	if temp_total == 2
replace 												bracket_deletion = "yes" 		if temp == 2
drop 													temp temp_total ind_bracket_deletion_total ind_bracket_deletion_total


// Construct interval variable between the deleted brackets
sort 													sector_ID year thres_low
gen 													temp_low_to_high = 1 			if bracket_deletion == "yes"
by sector_ID year: carryforward 						temp_low_to_high, replace
gsort 													sector_ID year -thres_low
gen 													temp_high_to_low = 1 			if bracket_deletion == "yes"
by sector_ID year: carryforward 						temp_high_to_low, replace
gen 													interval = 1 					if temp_low_to_high == 1 & temp_high_to_low == 1
drop 													temp_low_to_high temp_high_to_low

// We combine intervals into one bracket and back out their values as the difference between the total and the sum of the other brackets
sort 													sector_ID year thres_low
drop if sector_ID[_n] == sector_ID[_n-1] & year[_n] == year[_n-1] & interval[_n] == interval[_n-1] & interval == 1

// Sum over brackets outside of the interval
local vars number assets treceipts breceipts
foreach var of local vars {	
	bysort sector_ID year: egen double 					`var'_temp = total(`var') 		if bracket_deletion_total == "yes" & interval == .
	bysort sector_ID year: egen double 					`var'_temp2 = mean(`var'_temp)
	replace 											`var' = `var'_total - `var'_temp2 if interval == 1 & `var'_temp2 != .
	replace 											`var' = `var'_total 			if interval == 1 & `var'_temp2 == .
	drop 												`var'_temp `var'_temp2
}	
drop 													interval 
 	
sort 													sector_ID year thres_low

// Drop empty brackets
drop 																			if number == 0

/* Some brackets are not "within" bounds */
// This seems to be largely because larger brackets are not reported separately and their values are included in the lower brackets. 
// A natural solution is therefore to combine brackets whenever there is an issue.

* Identify probematic brackets
sort 													sector_ID year thres_low
gen double												av = assets / number

* Case average is above the threshold (more common)
by sector_ID year: gen 									d_temp = 1 				if av[_n] > thres_low[_n+1] & av != . & av[_n+1] != .  & av[_n+1] != 0
by sector_ID year: gen 									d_temp2 = 1 			if av[_n-1] > thres_low[_n] & av[_n-1] != . & av[_n] != .  & av[_n] != 0

* Case average is below the threshold (less common)
by sector_ID year: gen 									d_temp3 = 1 			if av[_n] < thres_low[_n] & av != . & av[_n] != .  & av[_n] != 0
by sector_ID year: gen 									d_temp4 = 1 			if av[_n+1] < thres_low[_n+1] & av[_n+1] != . & av[_n+1] != .  & av[_n+1] != 0

gen 													d_comb = 1 				if d_temp == 1 | d_temp2 == 1 | d_temp3 == 1 | d_temp4 == 1

* Sum bracket with next highest bracket
local vars number assets breceipts treceipts
foreach var of local vars {	
	bysort sector_ID year: egen double 					`var'_temp = total(`var') 		if d_comb == 1, missing
	replace 											`var' = `var'_temp 				if d_comb == 1
	drop 												`var'_temp
}	
bysort sector_ID year: egen double 						thres_low_temp = min(thres_low) if d_comb == 1, missing
replace 												thres_low = thres_low_temp 	if d_comb != .
drop 													if sector_ID[_n] == sector_ID[_n-1] & year[_n] == year[_n-1] & d_comb[_n] == d_comb[_n-1] & d_comb == 1
drop 													d_comb d_temp d_temp2 d_temp3 d_temp4 av thres_low_temp
drop 													ind_bracket_deletion

keep sector_ID year thres_low number number_total assets assets_total treceipts treceipts_total breceipts breceipts_total bracket_deletion bracket_deletion_total
order sector_ID year thres_low number number_total assets assets_total treceipts treceipts_total breceipts breceipts_total bracket_deletion bracket_deletion_total

label var 	sector_ID 				"Sector code"
label var	year					"Year"
label var	thres_low				"Bin threshold low"
label var 	number 					"Number" 
label var 	number_total 			"Number, all" 
label var 	assets 					"Assets"
label var 	assets_total 			"Assets, all"
label var 	treceipts 				"Total receipts"
label var 	treceipts_total 		"Total receipts, all"
label var 	breceipts				"Business receipts"
label var 	breceipts_total 		"Business receipts, all"
label var 	bracket_deletion 		"Combined bracket"
label var 	bracket_deletion_total 	"Sector-year with combined bracket"

save 	"$OUTPUT/soi/brackets/minor_industry_2012_brackets_assets_R5.dta", replace

