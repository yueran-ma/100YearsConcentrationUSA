/************ Function ************/

*This file cleans raw tabulations by receipts and produces cleaned tabulations "output/soi/brackets/agg_brackets_assets_R5.dta", "output/soi/brackets/agg_brackets_receipts_R5.dta", "output/soi/brackets/agg_brackets_ninc_R5.dta", "output/soi/brackets/agg_brackets_capital_R5.dta"

/************ Source ************/

*"input/soi/digitized/agg_raw_assets_R5.dta", "input/soi/digitized/agg_raw_receipts_R5.dta", "input/soi/digitized/agg_raw_ninc_R5.dta", "input/soi/digitized/agg_raw_capital_R5.dta"

clear all

/* Organize the raw data */

foreach item in assets receipts ninc capital {
    
	if "`item'" == "assets" {
	    local size assets
		local sizelab "Assets, all"
	}
	
	else if "`item'" == "receipts" {
	    local size breceipts 
		local sizelab "Receipts, all"
	}
	
	else if "`item'" == "ninc" { 
	    local size ninc
		local sizelab "Net income, all (with positive net income)"
	}
	
	else if "`item'" == "capital" { 
	    local size capital 
		local sizelab "Capital, all"
	}
    
	use "$DATA/soi/digitized/agg_raw_`item'_R5.dta", clear
	
	drop if thres_low == "Total"
	destring thres_low, replace
	
	drop thres_high 
	
	bysort year: egen double number_total = sum(number)
	bysort year: egen double `size'_total = sum(`size')
	
	label var number_total "Number, all"
	label var `size'_total "`sizelab'"
	
	sort year thres_low
	order year thres_low number number_total `size' `size'_total
	
	save "$OUTPUT/soi/brackets/agg_brackets_`item'_R5.dta", replace
}


/* By capital tabulation adjustment */

use "$OUTPUT/soi/brackets/agg_brackets_capital_R5.dta", clear 

/* Some brackets are not "within" bounds */

* Identify probematic brackets
sort 				year thres_low
gen double			av = capital / number

* Case average is above the threshold (more common)
by year: gen 		d_temp = 1 				if av[_n] > thres_low[_n+1] & av != . & av[_n+1] != .  & av[_n+1] != 0
by year: gen 		d_temp2 = 1 			if av[_n-1] > thres_low[_n] & av[_n-1] != . & av[_n] != .  & av[_n] != 0

* Case average is below the threshold (less common)
by year: gen 		d_temp3 = 1 			if av[_n] < thres_low[_n] & av != . & av[_n] != .  & av[_n] != 0
by year: gen 		d_temp4 = 1 			if av[_n+1] < thres_low[_n+1] & av[_n+1] != . & av[_n+1] != .  & av[_n+1] != 0

gen 				d_comb = 1 				if d_temp == 1 | d_temp2 == 1 | d_temp3 == 1 | d_temp4 == 1
// There can be several cases of this. 
by year: gen 		newid = 1 				if d_comb[_n] == 1 & d_comb[_n-1] == .
by year: replace 	newid = sum(newid)
replace 			d_comb = newid 			if d_comb == 1

* Sum bracket with next highest bracket
local vars number capital
foreach var of local vars {	
	bysort year d_comb: egen double 	`var'_temp = total(`var'), missing
	replace							 	`var' = `var'_temp 						if d_comb != .
	drop 								`var'_temp
}
bysort year d_comb: egen double 		thres_low_temp = min(thres_low), missing
replace									thres_low = thres_low_temp 				if d_comb != .
drop 																			if year[_n] == year[_n-1] & d_comb[_n] == d_comb[_n-1] & d_comb != .
drop 									d_comb d_temp d_temp2 d_temp3 d_temp4 av thres_low_temp newid

sort year thres_low

save "$OUTPUT/soi/brackets/agg_brackets_capital_R5.dta", replace

