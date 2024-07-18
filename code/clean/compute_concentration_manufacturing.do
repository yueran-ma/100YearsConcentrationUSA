/************ Function ************/

*This file uses generalized Pareto interpolation to estimate manufacturing top 100 share for the early years 

/************ Source ************/

*"output/soi/brackets/sector_brackets_assets_R5.dta" compiled by code/clean/generate_by_sector_by_assets.do
*"output/soi/brackets/sector_brackets_ninc_R5.dta" compiled by code/clean/generate_by_sector_by_ninc.do


clear all



*====================================================================
*========= Main sector concentration by assets ======================
*==================================================================== 


// Create file
clear all
gen 		year 		= .
gen 		sector_main = ""
tempfile 	manufacturing_concent_assets	
save 		"`manufacturing_concent_assets'"



// Run interpolation
forvalues i = 1931 / 1980 {
	local years `years' "`i'"
}
local sectors Manufacturing

foreach y of local years {
	foreach s of local sectors {
		
		use "$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", clear
		
		keep if 		year 			== `y'
		keep if 		sector_main 	== "`s'"
		drop if 		number 			== .

		// Percentiles
		sort 			year sector_main thres_low
		gen double 		pctile 			= number / number_total 
		gen double		p 				= 0 in 1
		replace 		p 				= pctile[_n-1] + p[_n-1] 	if _n > 1
		
		// Additional thresholds
		gen double 		p_top100 		= 1 - (100 / number_total)
		replace 		p_top100 		= 0 						if number_total <= 100
		
		// Create variables for gpinter
		gen double 		average 		= assets_total / number_total 				// Average overall
		gen double 		bracketavg 		= assets / number 							// Average in each bracket	
		replace 		bracketavg 		= 0 						if bracketavg == . & assets == . & thres_low == 0  // R reads zero as -0.00
		replace 		bracketavg 		= 0.0001 					if bracketavg == 0 // R reads zero as -0.00

		rename 			thres_low 		threshold
		sort 			threshold
		
		keep 			year sector_main p bracketavg average threshold number_total number p_top100 

		// Save the tabulation as a Stata file and run Gpinter
		// Using "saveold" allows R to read the file from very recent STATA versions
		saveold "$OUTPUT/temp/tabulation-input.dta", version(11) replace 
		
		// Run Gpinter
		* shell "$Rdir" CMD BATCH "gpinter_code.R"
		shell "$Rdirscript" "gpinter_code.R" "$RWORKDIR"
		
		// Keep vars that are constant 
		keep 			year sector_main number_total p_top100
		keep if 		_n 				== 1

		// Import distribution and keep key statistics
		cross using "$OUTPUT/temp/tabulation-output.dta"

		drop bracket_share top_average bottom_average bracket_average threshold bottom_share invpareto
		
		gen 			pct 			= 1 						if _n <= 127
		replace 		pct				= 2 						if _n > 127 & _n <= 128 & number_total > 100 & number_total != .

		gen 			varname 		= ""
		replace 		varname 		= "_100firms" 				if p == p_top100 & pct == 2
		drop 			p pct p_*
		
		keep if 		varname 		!= ""
		
		// Reshape to create time series structure
		reshape wide 	top_share, i(year) j(varname) string
		
		// Merge years
		merge 1:1 sector_main year using "`manufacturing_concent_assets'", nogen
		sort sector_main year
		save "`manufacturing_concent_assets'", replace

	}
}

// Identify failed interpolations and set values to missing (too few brackets)
sort 			year sector_main 
gen 			issues 				= 1 					if top_share_100firms[_n] == top_share_100firms[_n-1]
foreach var of varlist top_* {
	replace 	`var' 				= . 					if issues == 1
}
drop 			issues
save 			"`manufacturing_concent_assets'", replace






*====================================================================
*======== Main sector concentration by net income ===================
*====================================================================


// Create file
clear all
gen 			year = .
gen 			sector_main = ""
tempfile 		manufacturing_concent_ninc	
save 			"`manufacturing_concent_ninc'"


// Run interpolation
use "$OUTPUT/soi/brackets/sector_brackets_ninc_R5.dta", clear
keep if sector_main == "Manufacturing"
levelsof year, local(years) separate(" ")

local sectors Manufacturing

foreach y of local years {	
	foreach s of local sectors {
		use "$OUTPUT/soi/brackets/sector_brackets_ninc_R5.dta", clear
	
		keep if 		year 		== `y'
		keep if 		sector_main == "`s'"
		drop if 		number 		== .

		// Percentiles
		sort 			year sector_main thres_low
		gen double 		pctile 		= number / number_total 
		gen double		p 			= 0 in 1
		replace 		p 			= pctile[_n-1] + p[_n-1] 	if _n > 1
		
		// Additional thresholds
		gen double 		p_top100 	= 1 - (100 / number_total)
		replace 		p_top100 	= 0 						if number_total <= 100
		
		// Create variables for gpinter	
		gen double 		average 	= ninc_total / number_total 						// Average overall
		gen double 		bracketavg 	= ninc / number 									// Average in each bracket
		replace 		bracketavg 	= 0 						if bracketavg == . & ninc == . & thres_low == 0  	// R reads zero as -0.00
		replace 		bracketavg 	= 0.0001 					if bracketavg == 0 		// R reads zero as -0.00
		
		rename 			thres_low 	threshold
		sort 			threshold
		
		keep 			year sector_main p bracketavg average threshold number_total p_top100
		
		// Save the tabulation as a Stata file and run Gpinter
		// Using "saveold" allows R to read the file from very recent STATA versions	
		saveold "$OUTPUT/temp/tabulation-input.dta", version(11) replace 

		// Run Gpinter
		shell "$Rdirscript" "gpinter_code.R" "$RWORKDIR"
		
		// Keep vars that are constant 
		keep 			year sector_main number_total p_top100
		keep if 		_n 			== 1

		// Import distribution and keep key statistics
		cross using "$OUTPUT/temp/tabulation-output.dta"

		drop bracket_share top_average bottom_average bracket_average threshold bottom_share invpareto
		
		gen 			pct 		= 1 						if _n <= 127
		replace 		pct			= 2 						if _n > 127 & _n <= 128 & number_total > 100 & number_total != . 
		
		gen 			varname 	= ""
		replace 		varname 	= "_100firms" 				if p == p_top100 & pct == 2
		drop 			p pct p_* number_total
		
		keep if 		varname 	!= ""
		
		// Reshape to create time series structure
		reshape wide top_share, i(year) j(varname) string

		// Merge years
		merge 1:1 sector_main year  using "`manufacturing_concent_ninc'", nogen
		sort sector_main year
		save "`manufacturing_concent_ninc'", replace

	}
}

// Identify failed interpolations and set values to missing (too few brackets)
sort 			year sector_main
gen 			issues 		= 1	 						if top_share_100firms[_n] == top_share_100firms[_n-1]
foreach var of varlist top_* {
	replace 	`var' 		= . 						if issues == 1
}
drop 			issues
save 			"`manufacturing_concent_ninc'", replace



*====================================================================
*================== Merge main sector files =========================
*==================================================================== 

// Load by asset data to get totals 
use "`manufacturing_concent_assets'", clear

rename 		top_share_100firms tsh_assets_ipol_100firms
keep 		sector_main year tsh*

merge 1:1 sector_main year using "`manufacturing_concent_ninc'", nogen keepusing(top_share_*)

rename 		top_share_100firms tsh_ninc_ipol_100firms
keep 		sector_main year tsh*


*===== Interpolate outliers and deal with consolidation in the 1930s
do "outliers_sector.do"


keep 		sector_main year tsh_*
order 		sector_main year tsh_assets_ipol_100firms tsh_ninc_ipol_100firms

label var sector_main 				"Main sector"
label var year						"Year"
label var tsh_assets_ipol_100firms 	"Top 100 corp asset share" 
label var tsh_ninc_ipol_100firms 	"Top 100 corp net income share" 

save "$OUTPUT/soi/topshares/manufacturing_concent_R5.dta", replace
capture erase "$OUTPUT/temp/tabulation-input.dta"
capture erase "$OUTPUT/temp/tabulation-output.dta"


