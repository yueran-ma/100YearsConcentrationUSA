/************ Function ************/

*This file cleans raw tabulations by receipts and produces cleaned tabulations output/soi/brackets/sector_brackets_ninc_R5.dta

/************ Source ************/

*"input/soi/digitized/sector_raw_ninc_R5.dta"

/************ Notes ************/

*We use the sum over bins to construct *_total (no bracket deletions here)

/************ Steps ************/

*Assign main sectors  
*Aggregate to main sectors 
 

clear all


use "$DATA/soi/digitized/sector_raw_ninc_R5.dta", clear
 
/* Harmonize main sectors */

sort 	sector year thres_low

gen 	sector_main = ""
replace sector_main = "All" 			if sector == "All Industries"
replace sector_main = "Agriculture" 	if sector == "Agriculture, Forestry, Fishing"
replace sector_main = "Construction" 	if sector == "Construction"
replace sector_main = "Finance" 		if sector == "Finance, Insurance, and Real Estate"
replace sector_main = "Manufacturing" 	if sector == "Manufacturing"
replace sector_main = "Mining" 			if sector == "Mining"
replace sector_main = "Services" 		if sector == "Services"
replace sector_main = "Utilities" 		if sector == "Transportation and Public Utilities"
replace sector_main = "Trade" 			if sector == "Trade"

order 	sector_main year thres_low
sort 	sector_main year thres_low


/* Item preparation */

// Create variables for the totals
local vars number ninc

* Generate separate variables for the totals
foreach var of local vars {
  
	* Stated totals
	gen double 										temp = `var' 					if thres_low == "Total"
	bysort sector year: egen double 				`var'_total_stated = min(temp)
	drop 											temp
		
	* Computed totals (add up stated totals)
	bysort sector year thres_low: egen double 		`var'_total = total(`var'_total_stated) 
	replace 										`var'_total = . 				if `var'_total == 0
	
	* Computed totals (add up brackets)
	bysort sector year: egen double 				`var'_total_alt = total(`var')  if thres_low != "Total"
	replace 										`var'_total_alt = . 			if `var'_total_alt == 0
	
	* Replace with adding up brackets (no bracket deletion in by net income data)
	replace											`var'_total = `var'_total_alt   // only 1967 data doesn't add up  	 
	
}

drop if 											thres_low == "Total"
destring 											thres_low, replace
drop 												*_stated *_alt

sort 												year sector thres_low

// No bracket deletions in early years with by net income tabulations 
cap gen 	bracket_deletion = "no"  
cap gen 	bracket_deletion_total = "no"  

// Drop empty brackets
drop if 											number == 0

keep sector_main year thres_low number number_total ninc ninc_total bracket_deletion bracket_deletion_total			
order sector_main year thres_low number number_total ninc ninc_total bracket_deletion bracket_deletion_total			


label var 	sector_main 			"Main sector"
label var	year					"Year"
label var	thres_low				"Bin threshold low"
label var 	number 					"Number" 
label var 	number_total 			"Number, all (with positive net income)" 
label var 	ninc 					"Net income"
label var 	ninc_total 				"Net income, all (with positive net income)"
label var 	bracket_deletion 		"Combined bracket"
label var 	bracket_deletion_total 	"Sector-year with combined bracket"


sort 		sector_main year thres_low

save 		"$OUTPUT/soi/brackets/sector_brackets_ninc_R5.dta", replace

 

 
 