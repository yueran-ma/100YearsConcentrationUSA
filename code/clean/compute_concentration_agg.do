/************ Function ************/

*This file uses generalized Pareto interpolation to estimate aggregate top shares 

/************ Source ************/

*"output/soi/brackets/agg_brackets_assets_R5.dta", *"output/soi/brackets/agg_brackets_receipts_R5.dta", *"output/soi/brackets/agg_brackets_ninc_R5.dta", and  *"output/soi/brackets/agg_brackets_capital_R5.dta" compiled by code/clean/generate_aggregate.do

clear all



// Create files
clear
gen year 		= .
gen grouped_by 	= ""

tempfile	by_assets
save 		"`by_assets'"

tempfile 	by_receipts
save 		"`by_receipts'"

tempfile 	by_net_income
save 		"`by_net_income'"

tempfile 	by_capital
save 		"`by_capital'"	
	
	
	
*====================================================================
*================= Concentration by assets ==========================
*====================================================================
		
	
// Run interpolation: assets
local years
forvalues i = 1931 / 2018 {
	local years `years' `i'
}

foreach y of local years {	
	
	use "$OUTPUT/soi/brackets/agg_brackets_assets_R5.dta", clear
	
	gen 		grouped_by 			= "Total assets"
	sort 		year thres_low
	
	keep if 	y 					== `y'
	
	// Percentiles	
	gen double 	pctile 				= number / number_total 
	gen double	p 					= 0 in 1
	replace 	p 					= pctile[_n-1] + p[_n-1] 					if _n > 1

	// Create variables for gpinter
	gen double	average 			= assets_total / number_total 				// Average overall
	gen double	bracketavg 			= assets / number 							// Average in each bracket	
	replace 	bracketavg 			= 0 										if bracketavg == . & assets == . & thres_low == 0  // R reads zero as -0.00
	replace 	bracketavg 			= 0.0001 									if bracketavg == 0 // R reads zero as -0.00
	
	rename 		thres_low 			threshold
	sort 		threshold
	
	keep 		year p bracketavg average threshold grouped_by assets_total number_total
	
	// Save the tabulation as a Stata file and run Gpinter
	// Using "saveold" allows R to read the file from very recent STATA versions
	saveold 	"$OUTPUT/temp/tabulation-input.dta", version(11) replace 
	
	// Run Gpinter
	shell 		"$Rdirscript" "gpinter_code.R" "$RWORKDIR"
	
	// Keep vars that are constant 
	keep 		year grouped_by assets_total number_total 
	keep if 	_n 					== 1

	// Import distribution and keep key statistics
	cross using "$OUTPUT/temp/tabulation-output.dta"

	drop 		bracket_share top_average bottom_average bracket_average bottom_share gini

	gen 		pct					= 1 										if _n <= 127
		
	gen 		varname 			= ""
	replace 	varname 			= "_50pct" 									if p == 0.5 & pct == 1
	replace 	varname 			= "_10pct" 									if p == 0.9 & pct == 1
	replace 	varname 			= "_1pct" 									if p == 0.99 & pct == 1
	replace 	varname 			= "_0_1pct" 								if p == 0.999 & pct == 1
	drop 		p pct number_total	
	keep if 	varname 			!= ""

	// Reshape to create time series structure
	reshape wide top_share invpareto threshold, i(year) j(varname) string

	// Merge years
	merge 1:1 year using "`by_assets'", nogen
	save 		"`by_assets'", replace	
}

sort 			year
save 			"`by_assets'", replace	




*==============================================================================
*================= Concentration by business receipts =========================
*==============================================================================


// Run interpolation: By receipts
local years
forvalues i = 1959 / 1966 {
	local years `years' `i'
}
forvalues i = 1968 / 2018 {
	local years `years' `i'
}

foreach y of local years {
	
	use "$OUTPUT/soi/brackets/agg_brackets_receipts_R5.dta", clear	
	
	gen 		grouped_by 			= "Business receipts"
	sort 		year thres_low
	
	keep if 	y 					== `y'
	
	// Percentiles
	gen double 	pctile 				= number / number_total 
	gen double	p 					= 0 in 1
	replace 	p 					= pctile[_n-1] + p[_n-1] 					if _n > 1
	
	// Create variables for gpinter
	gen double	average 			= breceipts_total / number_total 			// Average overall
	gen double	bracketavg 			= breceipts / number 						// Average in each bracket
	replace 	bracketavg 			= 0 										if bracketavg == . & breceipts == . & thres_low == 0  // R reads zero as -0.00
	replace 	bracketavg 			= 0.0001 									if bracketavg == 0 // R reads zero as -0.00

	rename 		thres_low 			threshold
	sort 		threshold
	
	keep 		year p bracketavg average threshold grouped_by breceipts_total number_total
	sort 		threshold
	
	// Save the tabulation as a Stata file and run Gpinter
	// Using "saveold" allows R to read the file from very recent STATA versions
	saveold 	"$OUTPUT/temp/tabulation-input.dta", version(11) replace 
		
	// Run Gpinter
	shell 		"$Rdirscript" "gpinter_code.R" "$RWORKDIR"
	
	// Keep vars that are constant 
	keep 		year grouped_by breceipts_total number_total 
	keep if 	_n 					== 1

	// Import distribution and keep key statistics
	cross using "$OUTPUT/temp/tabulation-output.dta"

	drop 		bracket_share top_average bottom_average bracket_average bottom_share gini
	
	gen 		pct					= 1 										if _n <= 127
	
	gen 		varname 			= ""
	replace 	varname 			= "_50pct" 									if p == 0.5 & pct == 1
	replace 	varname 			= "_10pct" 									if p == 0.9 & pct == 1
	replace 	varname 			= "_1pct"									if p == 0.99 & pct == 1
	replace 	varname 			= "_0_1pct" 								if p == 0.999 & pct == 1
	drop 		p pct	
	keep if 	varname 			!= ""
	
	// Reshape to create time series structure
	reshape wide top_share invpareto threshold, i(year) j(varname) string

	// Merge years
	merge 1:1 year using "`by_receipts'", nogen
	save 		"`by_receipts'", replace
	
}

sort 			year
save 			"`by_receipts'", replace



*========================================================================
*================= Concentration by net income ==========================
*========================================================================


// Run interpolation: Net income
clear all
local years
forvalues i = 1918 / 1965 {
	local years `years' `i'
}
local years `years' 1967 1973 1974

foreach y of local years {
	
	use "$OUTPUT/soi/brackets/agg_brackets_ninc_R5.dta", clear
	
	gen 		grouped_by 			= "Net income"
	sort 		year thres_low

	keep if 	y ==`y'
	
	// Percentiles
	gen double 	pctile 				= number / number_total 
	gen double	p 					= 0 in 1
	replace 	p 					= pctile[_n-1] + p[_n-1] 					if _n > 1
		
	// Create variables for gpinter
	gen double	average 			= ninc_total / number_total 				// Average overall
	gen double	bracketavg 			= ninc / number 							// Average in each bracket
	replace 	bracketavg 			= 0 										if bracketavg == . & ninc == . & thres_low == 0  // R reads zero as -0.00
	replace 	bracketavg 			= 0.0001 									if bracketavg == 0 // R reads zero as -0.00

	rename 		thres_low 			threshold
	sort 		threshold

	keep 		year p bracketavg average threshold grouped_by ninc_total number_total 
	sort 		threshold
	
	// Save the tabulation as a Stata file and run Gpinter
	// Using "saveold" allows R to read the file from very recent STATA versions
	saveold 	"$OUTPUT/temp/tabulation-input.dta", version(11) replace 
	
	// Run Gpinter
	shell 		"$Rdirscript" "gpinter_code.R" "$RWORKDIR"
	
	// Keep vars that are constant 
	keep 		year grouped_by ninc_total number_total 
	keep if 	_n 					== 1

	// Import distribution and keep key statistics
	cross using "$OUTPUT/temp/tabulation-output.dta"

	drop 		bracket_share top_average bottom_average bracket_average bottom_share gini
	
	gen 		pct 				= 1 										if _n <= 127
	
	gen 		varname 			= ""
	replace 	varname 			= "_50pct" 									if p == 0.5 & pct == 1
	replace 	varname 			= "_10pct" 									if p == 0.9 & pct == 1
	replace 	varname 			= "_1pct" 									if p == 0.99 & pct == 1
	replace 	varname 			= "_0_1pct" 								if p == 0.999 & pct == 1
	drop 		p pct 
	keep if 	varname 			!= ""

	// Reshape to create time series structure
	reshape wide top_share invpareto threshold, i(year) j(varname) string

	// Merge years
	merge 1:1 year using "`by_net_income'", nogen
	save 		"`by_net_income'", replace
}

sort 			year
save 			"`by_net_income'", replace




*==============================================================================
*================= Concentration by capital stock =============================
*==============================================================================

// Run interpolation: By capital stock
local years 1921 1922

foreach y of local years {
	
	use "$OUTPUT/soi/brackets/agg_brackets_capital_R5.dta", clear
	
	gen 		grouped_by 			= "Capital"
	sort 		year thres_low
	
	keep if 	y 					== `y'
	
	// Percentiles
	gen double 	pctile 				= number / number_total 
	gen double	p 					= 0 in 1
	replace 	p 					= pctile[_n-1] + p[_n-1] 					if _n > 1
	
	// Create variables for gpinter
	gen double	average 			= capital_total / number_total 				// Average overall
	gen double	bracketavg 			= capital / number 							// Average in each bracket
	replace 	bracketavg 			= 0 										if bracketavg == . & capital == . & thres_low == 0  // R reads zero as -0.00
	replace 	bracketavg 			= 0.0001 									if bracketavg == 0 // R reads zero as -0.00

	rename 		thres_low 			threshold
	sort 		threshold
	
	keep 		year p bracketavg average threshold grouped_by capital_total number_total 
	sort 		threshold
	
	// Save the tabulation as a Stata file and run Gpinter
	// Using "saveold" allows R to read the file from very recent STATA versions
	saveold 	"$OUTPUT/temp/tabulation-input.dta", version(11) replace 
		
	// Run Gpinter
	shell 		"$Rdirscript" "gpinter_code.R" "$RWORKDIR"
	
	// Keep vars that are constant 
	keep 		year grouped_by capital_total number_total 
	keep if 	_n 					== 1

	// Import distribution and keep key statistics
	cross using "$OUTPUT/temp/tabulation-output.dta"

	drop 		bracket_share top_average bottom_average bracket_average bottom_share gini
	
	gen 		pct					= 1 										if _n <= 127
	
	gen 		varname 			= ""
	replace 	varname 			= "_50pct" 									if p == 0.5 & pct == 1
	replace 	varname 			= "_10pct" 									if p == 0.9 & pct == 1
	replace 	varname 			= "_1pct" 									if p == 0.99 & pct == 1
	replace 	varname 			= "_0_1pct" 								if p == 0.999 & pct == 1
	drop 		p pct	
	keep if 	varname 			!= ""
	
	// Reshape to create time series structure
	reshape wide top_share invpareto threshold, i(year) j(varname) string

	// Merge years
	merge 1:1 year using "`by_capital'", nogen
	save 		"`by_capital'", replace
	
}

sort 			year
save 			"`by_capital'", replace


*==============================================================================
*================= Combine concentration estimates ============================
*==============================================================================

use "`by_net_income'", clear

merge 1:1 year grouped_by using "`by_receipts'", nogen
merge 1:1 year grouped_by using "`by_assets'", nogen
merge 1:1 year grouped_by using "`by_capital'", nogen
sort year

encode grouped_by, gen(ID)
tsset ID year

// Consolidation adjustment for 1934 to 1941 (consolidated returns not allowed between 1934 and 1941)
foreach v of varlist top_share* {
	local vars "`vars' `v'"

	// If have data before and after: take the level difference between 1933 and 1942 that is not accounted for by the year-to-year changes and divide it equally between all years 
	gen double			change 			= d.`v'
	by ID: egen double	tmp 			= sum(change) 							if year >= 1935 & year <= 1941
	by ID: egen double 	change_33_42	= mean(tmp)
	drop 				change tmp

	gen double			temp33 			= `v' 									if year == 1933
	by ID: egen double	lev33 			= mean(temp33)
	gen double 			temp42 			= `v' 									if year == 1942
	by ID: egen double	lev42 			= mean(temp42)
	drop 				temp33 temp42 

	gen double			scale 			= (lev42 - lev33) - change_33_42
	gen double			`v'_adj 		= `v' 									if year < 1934 | year > 1941
	replace 			`v'_adj 		= `v'_adj[_n-1] + scale/9 				if year == 1934 
	replace 			`v'_adj 		= `v'_adj[_n-1] + scale/9 + d.`v' 		if year >= 1935 & year < 1942 
	drop 				scale change_33_42 lev42 lev33
}

gen double				top_share_1pctwoadj = top_share_1pct

// Replace unadjusted with adjusted data
foreach v of local vars {
	replace `v' = `v'_adj
	drop `v'_adj
}

// Add labels
label var top_share_0_1pct 			"Top 0.1%"
label var top_share_1pct 			"Top 1%"
label var top_share_10pct 			"Top 10%"
label var top_share_1pctwoadj 		"Top 1% without consolidation adjustment"

tempfile agg_prepared
save "`agg_prepared'"	


/* Finalize */

use "`agg_prepared'", clear

keep if grouped_by == "Total assets"

rename top_share_50pct 				tsh_assets_ipol_50pct
rename top_share_10pct 				tsh_assets_ipol_10pct
rename top_share_1pct 				tsh_assets_ipol_1pct
rename top_share_0_1pct 			tsh_assets_ipol_0_1pct
rename top_share_1pctwoadj 			tsh_assets_ipol_1pctwoadj

keep year tsh_assets_*

tempfile agg_concent
save "`agg_concent'"	


use "`agg_prepared'", clear
keep if grouped_by == "Business receipts"

rename top_share_50pct 				tsh_receipts_ipol_50pct
rename top_share_10pct 				tsh_receipts_ipol_10pct
rename top_share_1pct 				tsh_receipts_ipol_1pct
rename top_share_0_1pct 			tsh_receipts_ipol_0_1pct

keep year tsh_receipts_*

merge 1:1 year using "`agg_concent'", nogen

tempfile agg_concent
save "`agg_concent'"	

use "`agg_prepared'", clear
keep if grouped_by == "Net income"

rename top_share_50pct 				tsh_ninc_ipol_50pct
rename top_share_10pct 				tsh_ninc_ipol_10pct
rename top_share_1pct 				tsh_ninc_ipol_1pct
rename top_share_0_1pct 			tsh_ninc_ipol_0_1pct

keep year tsh_ninc_*

merge 1:1 year using "`agg_concent'", nogen

tempfile agg_concent
save "`agg_concent'"	


use "`agg_prepared'", clear
keep if grouped_by == "Capital"

rename top_share_50pct 				tsh_capital_ipol_50pct
rename top_share_10pct 				tsh_capital_ipol_10pct
rename top_share_1pct 				tsh_capital_ipol_1pct
rename top_share_0_1pct 			tsh_capital_ipol_0_1pct

keep year tsh_capital_*

merge 1:1 year using "`agg_concent'", nogen


sort 	year
keep 	year tsh_assets_ipol_50pct tsh_assets_ipol_10pct tsh_assets_ipol_1pct tsh_assets_ipol_0_1pct tsh_assets_ipol_1pctwoadj ///
		tsh_receipts_ipol_50pct tsh_receipts_ipol_10pct tsh_receipts_ipol_1pct tsh_receipts_ipol_0_1pct ///
		tsh_ninc_ipol_50pct tsh_ninc_ipol_10pct tsh_ninc_ipol_1pct tsh_ninc_ipol_0_1pct ///
		tsh_capital_ipol_50pct tsh_capital_ipol_10pct tsh_capital_ipol_1pct tsh_capital_ipol_0_1pct 

order 	year tsh_assets_ipol_50pct tsh_assets_ipol_10pct tsh_assets_ipol_1pct tsh_assets_ipol_0_1pct tsh_assets_ipol_1pctwoadj ///
		tsh_receipts_ipol_50pct tsh_receipts_ipol_10pct tsh_receipts_ipol_1pct tsh_receipts_ipol_0_1pct ///
		tsh_ninc_ipol_50pct tsh_ninc_ipol_10pct tsh_ninc_ipol_1pct tsh_ninc_ipol_0_1pct ///
		tsh_capital_ipol_50pct tsh_capital_ipol_10pct tsh_capital_ipol_1pct tsh_capital_ipol_0_1pct  

label var year						"Year"
label var tsh_assets_ipol_50pct 	"Top 50% asset share" 
label var tsh_assets_ipol_10pct 	"Top 10% asset share" 
label var tsh_assets_ipol_1pct 		"Top 1% asset share" 
label var tsh_assets_ipol_0_1pct 	"Top 0.1% asset share" 
label var tsh_assets_ipol_1pctwoadj "Top 1% asset share, without consolidation adjustment"

label var tsh_receipts_ipol_50pct 	"Top 50% receipt share" 
label var tsh_receipts_ipol_10pct 	"Top 10% receipt share"  
label var tsh_receipts_ipol_1pct 	"Top 1% receipt share" 
label var tsh_receipts_ipol_0_1pct 	"Top 0.1% receipt share" 

label var tsh_ninc_ipol_50pct 		"Top 50% net income share" 
label var tsh_ninc_ipol_10pct 		"Top 10% net income share" 
label var tsh_ninc_ipol_1pct 		"Top 1% net income share" 
label var tsh_ninc_ipol_0_1pct 		"Top 0.1% net income share" 

label var tsh_capital_ipol_50pct 	"Top 50% capital share" 
label var tsh_capital_ipol_10pct 	"Top 10% capital share" 
label var tsh_capital_ipol_1pct 	"Top 1% capital share" 
label var tsh_capital_ipol_0_1pct 	"Top 0.1% capital share" 

tsset year

order 	year tsh_assets_ipol_0_1pct tsh_assets_ipol_1pct tsh_assets_ipol_1pctwoadj tsh_assets_ipol_10pct tsh_assets_ipol_50pct ///
		tsh_receipts_ipol_0_1pct tsh_receipts_ipol_1pct tsh_receipts_ipol_10pct tsh_receipts_ipol_50pct ///
		tsh_ninc_ipol_0_1pct tsh_ninc_ipol_1pct tsh_ninc_ipol_10pct tsh_ninc_ipol_50pct ///
		tsh_capital_ipol_0_1pct tsh_capital_ipol_1pct tsh_capital_ipol_10pct tsh_capital_ipol_50pct

save "$OUTPUT/soi/topshares/agg_concent_R5.dta", replace
capture erase "$OUTPUT/temp/tabulation-input.dta"
capture erase "$OUTPUT/temp/tabulation-output.dta"






