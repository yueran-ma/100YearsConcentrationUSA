/******************Function******************/

*This file cleans raw tabulations by receipts for partnerships and proprietorships and produces cleaned tabulations output/soi/brackets/sector_type_brackets_receipts_R5.dta

/******************Source******************/

*"input/soi/digitized/sector_noncorp_raw_receipts_R5.dta"
*"output/soi/brackets/sector_brackets_receipts_R5.dta" compiled by code/clean/generate_by_sector_by_receipts.do

/************ Notes ************/

*We use the sum over bins to construct *_total, except when there are bracket deletions, in which case we use the stated total 

/************ Steps ************/

*Assign main sectors and subsectors 
*Aggregate to main sectors/subsectors 
*Clean bracket deletions
*Clean brackets where the average is out of bounds
*Combine with corporation by receipt tabulations 

clear all



use "$DATA/soi/digitized/sector_noncorp_raw_receipts_R5.dta", clear

sort sector year thres_low

/* Harmonize main sectors */

replace 	sector = trim(sector)
gen 		sector_main = ""
replace 	sector_main =  "All" 			if sector == "All Industries" 

* SIC: 01-09. NAICS: 11.
replace 	sector_main = "Agriculture" 	if sector == "Agriculture, Forestry, Fishing"   
replace 	sector_main = "Agriculture" 	if sector == "Agriculture, Forestry, Fishing and Hunting"

* SIC: 15-17. NAICS: 23. 
replace 	sector_main = "Construction" 	if sector == "Construction" 

* SIC: 60-67; NAICS: 52, 53, 55.
replace 	sector_main = "Finance" 		if sector == "Finance, Insurance, and Real Estate"
replace 	sector_main = "Finance" 		if sector == "Finance and Insurance" 
replace 	sector_main = "Finance"			if sector == "Real Estate and Rental and Leasing" 
replace 	sector_main = "Finance" 		if sector == "Management of Companies (Holding Companies)"

* SIC: 20-39. NAICS: 31-33.
replace 	sector_main = "Manufacturing" 	if sector == "Manufacturing"

* SIC: 10-14. NAICS: 21.  
replace 	sector_main = "Mining" 			if sector == "Mining" 

* SIC: 70-89; * NAICS:  54, 56, 61, 62, 71, 72 81. 
replace 	sector_main = "Services" 		if sector == "Services"
replace 	sector_main = "Services" 		if sector == "Professional, Scientific, and Technical Services" 
replace 	sector_main = "Services" 		if sector == "Administrative and Support and Waste Management and Remediation Services"
replace 	sector_main = "Services" 		if sector == "Educational Services"
replace 	sector_main = "Services" 		if sector == "Health Care and Social Assistance" 
replace 	sector_main = "Services" 		if sector == "Arts, Entertainment, and Recreation" 
replace 	sector_main = "Services" 		if sector == "Accommodation and Food Services"
replace 	sector_main = "Services" 		if sector == "Other Services"

* SIC: 40-49; NAICS: 22, 48-49, 51.
replace 	sector_main = "Utilities" 		if sector == "Utilities"
replace 	sector_main = "Utilities" 		if sector == "Transportation and Warehousing" 
replace 	sector_main = "Utilities" 		if sector == "Transportation and Public Utilities"
replace 	sector_main = "Utilities" 		if sector == "Information" 

* SIC: 50-59; NAICS: 42-45
replace 	sector_main = "Trade" 			if sector == "Trade"
replace 	sector_main = "Trade" 			if sector == "Wholesale and Retail Trade"

order 		year sector_main


/* Item preparation */

// Create variables for the totals
local vars number breceipts 

* Generate separate variables for the totals
foreach var of local vars {	

	* Stated totals
	gen double 												temp = `var' 					if thres_low == "Total"
	bysort sector year tables: egen double 					`var'_total_stated = min(temp)
	drop temp
	
	* Computed totals (add up stated totals)
	bysort sector year tables thres_low: egen double 		`var'_total = total(`var'_total_stated) 
	replace 												`var'_total = . 				if `var'_total == 0
	
	* Computed totals (add up brackets)
	bysort sector year tables: egen double 					`var'_total_alt = total(`var')  if thres_low != "Total"
	replace 												`var'_total_alt = . 			if `var'_total_alt == 0
	
	* Replace with adding up brackets (when no bracket deletions)
	replace													`var'_total = `var'_total_alt 	if bracket_deletion_total != "yes" // seems adding up not an issue in these files
}

drop if 													thres_low == "Total"
destring 													thres_low, replace
cap drop 													*_stated *_alt

/* Aggregate to main sectors */

// "Sum" bracket deletions at main sector level
encode bracket_deletion_total, gen(ind_bracket_deletion_total)
encode bracket_deletion, gen(ind_bracket_deletion)
bysort sector_main year tables thres_low: egen 				temp = max(ind_bracket_deletion)
bysort sector_main year tables thres_low: egen 				temp_total = max(ind_bracket_deletion_total)
replace 													bracket_deletion_total = "yes" 	if temp_total == 2
replace 													bracket_deletion = "yes" 		if temp ==2
drop 														temp temp_total ind_bracket_deletion ind_bracket_deletion_total

// Main sector totals
local vars number breceipts
foreach var of local vars {	
    
	* Sum over sectors to have data for main sectors
	bysort sector_main year tables thres_low: egen double 	`var'_total_temp = total(`var'_total)
	replace 												`var'_total = `var'_total_temp 	if `var'_total_temp !=0
	drop 													`var'_total_temp 
	
	bysort sector_main year tables thres_low: egen double 	`var'_temp = total(`var')
	replace 												`var' = `var'_temp 				if `var'_temp !=0 
	replace 												`var' = . 						if bracket_deletion =="yes"
	drop 													`var'_temp
	
	
}

duplicates drop 											sector_main year tables thres_low, force


/* Deal with deleted brackets */

// Construct interval variable between the deleted brackets
sort 														sector_main year tables thres_low
gen 														temp_low_to_high = 1 			if bracket_deletion == "yes"
by sector_main year tables: carryforward 					temp_low_to_high, replace
gsort 														sector_main year tables -thres_low
gen 														temp_high_to_low = 1 			if bracket_deletion == "yes"
by sector_main year tables: carryforward 					temp_high_to_low, replace
gen 														interval = 1 					if temp_low_to_high == 1 & temp_high_to_low == 1
drop 														temp_low_to_high temp_high_to_low

// We combine intervals into one bracket and back out their values as the difference between the total and the sum of the other brackets
sort 														sector_main year tables thres_low
drop if sector_main[_n] == sector_main[_n-1] & year[_n] == year[_n-1] & tables[_n] == tables[_n-1] & interval[_n] == interval[_n-1] & interval == 1

// Sum over brackets outside of the interval
local vars number breceipts
foreach var of local vars {	
	bysort sector_main year tables: egen double 			`var'_temp = total(`var') 		if bracket_deletion_total == "yes" & interval == . 
	bysort sector_main year tables: egen double 			`var'_temp2 = mean(`var'_temp)
	replace 												`var' = `var'_total - `var'_temp2 if interval == 1 & `var'_temp2 != .
	replace 												`var' = `var'_total 			if interval == 1 & `var'_temp2 == .
	drop 													`var'_temp `var'_temp2
}	
drop 														interval 
 	
sort 														sector_main year tables thres_low

local vars breceipts number
foreach var of local vars {
	by sector_main year tables: egen double 				`var'_total_alt = total(`var') 
	replace 												`var'_total_alt = . 			if `var'_total_alt == 0
}


cap drop 													check
gen 														check_breceipts = breceipts_total / breceipts_total_alt // Check if the bracket adjustment worked
gen 														check_number = number_total / number_total_alt // Check if the bracket adjustment worked
cap drop 													check* *_alt

// Drop empty brackets
drop 																			if number == 0


/* Some brackets are not "within" bounds */
// This seems to be largely because larger brackets are not reported separately and their values are included in the lower brackets. 
// A natural solution is therefore to combine brackets whenever there is an issue.

* Identify probematic brackets
sort 														sector_main year tables thres_low
gen double 													av = breceipts / number

* Case average is above the threshold (more common)
by sector_main year tables: gen 							d_temp = 1 			if av[_n] > thres_low[_n+1] & av != . & av[_n+1] != .  & av[_n+1] != 0
by sector_main year tables: gen 							d_temp2 = 1 		if av[_n-1] > thres_low[_n] & av[_n-1] != . & av[_n] != .  & av[_n] != 0

* Case average is below the threshold (less common)
by sector_main year tables: gen 							d_temp3 = 1 		if av[_n] < thres_low[_n] & av != . & av[_n] != .  & av[_n] != 0
by sector_main year tables: gen 							d_temp4 = 1 		if av[_n+1] < thres_low[_n+1] & av[_n+1] != . & av[_n+1] != .  & av[_n+1] != 0

gen 														d_comb = 1 if d_temp == 1 | d_temp2 == 1 | d_temp3 == 1 | d_temp4 == 1
// There can be several cases of this 
by sector_main year tables: gen 							newid = 1 if d_comb[_n] == 1 & d_comb[_n-1] == .
by sector_main year tables: replace 						newid = sum(newid)
replace 													d_comb = newid if d_comb == 1

// Sum bracket with next highest bracket
local vars number breceipts
foreach var of local vars {	
	bysort sector_main year tables d_comb: egen double 		`var'_temp = total(`var'), missing
	replace 												`var' = `var'_temp 	if d_comb != .
	drop 													`var'_temp
}	
bysort sector_main year tables d_comb: egen double 			thres_low_temp = min(thres_low), missing
replace 													thres_low = thres_low_temp 	if d_comb != .
drop if 	sector_main[_n] == sector_main[_n-1] & year[_n] == year[_n-1] & tables[_n] == tables[_n-1] & d_comb[_n] == d_comb[_n-1] & d_comb != .
drop 		d_comb d_temp d_temp2 av
drop 		d_temp3 d_temp4 thres_low_temp


keep 		tables sector_main year thres_low number number_total breceipts breceipts_total bracket_deletion bracket_deletion_total 
order 		tables sector_main year thres_low number number_total breceipts breceipts_total bracket_deletion bracket_deletion_total


/* Combine with corporations by receipt tabulations */

ren 		breceipts* size*

append using "$OUTPUT/soi/brackets/sector_brackets_receipts_R5.dta"

replace 	tables = "Corporations" if tables == ""

gen 		type = ""
replace 	type = "corp" 			if tables == "Corporations"
replace 	type = "part" 			if tables == "Partnerships"
replace 	type = "prop" 			if tables == "Sole Proprietorships"

/* Finalize */

// Keep only years for which we have data for all three sectors
drop if 	year < 1959 
drop if 	year == 1963 | year == 1964 | year == 1967
drop if 	year >= 1981 & year <= 1997
drop if 	year >= 2004

keep 		sector_main type tables year thres_low number number_total size size_total bracket_deletion bracket_deletion_total
order 		sector_main type tables year  thres_low number number_total size size_total bracket_deletion bracket_deletion_total

label var 	sector_main 			"Main sector"
label var	year					"Year"
label var	type					"Entity type"
label var	tables					"Tabulation type"
label var	thres_low				"Bin threshold low"
label var 	number 					"Number" 
label var 	number_total 			"Number, all" 
label var 	size 					"Receipts"
label var 	size_total 				"Receipts, all"
label var 	bracket_deletion 		"Combined bracket"
label var 	bracket_deletion_total 	"Sector-year with combined bracket"

sort 		sector_main tables year thres_low

save 		"$OUTPUT/soi/brackets/sector_type_brackets_receipts_R5.dta", replace


 