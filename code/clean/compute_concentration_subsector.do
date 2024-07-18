/************ Function ************/

*This file uses generalized Pareto interpolation to estimate top shares for subsectors and granular subsectors 

/************ Source ************/

*"output/soi/brackets/subsector_brackets_assets_R5.dta" compiled by code/clean/generate_by_sector_by_assets.do
*"output/soi/brackets/subsector_gran_brackets_assets_R5.dta" compiled by code/clean/generate_by_sector_by_assets.do


clear all



*====================================================================
*============== BEA subsector concentration by assets ===============
*==================================================================== 

// Create files
clear all
gen 		year 			= .
gen 		subsector_BEA 	= ""
tempfile 	subsector_BEA_concent	
save 		"`subsector_BEA_concent'"	


forvalues i = 1931 / 2013 {
	local years `years' "`i'"
}

// Run interpolation
foreach y of local years {
    
	use "$OUTPUT/soi/brackets/subsector_brackets_assets_R5.dta", clear
	keep if 			year 			== `y'
	sort 				subsector_BEA year
	levelsof 			subsector_BEA, local(sectors)

	foreach s of local sectors {
	    
		use "$OUTPUT/soi/brackets/subsector_brackets_assets_R5.dta", clear
		sort 			year subsector_BEA thres_low

		keep if 		year 			== `y'
		keep if 		subsector_BEA 	== "`s'"
		drop if 		number 			== . | number == 0

		// Percentiles
		gen double 		pctile 			= number / number_total 
		gen double		p 				= 0 in 1
		replace 		p 				= pctile[_n-1] + p[_n-1] 				if _n > 1
		
		// Create variables for gpinter
		gen double 		average 		= assets_total / number_total 			// Average overall
		gen double 		bracketavg 		= assets / number 						// Average in each bracket	
		replace 		bracketavg 		= 0 									if bracketavg == . & assets == . & thres_low == 0  // R reads zero as -0.00
		replace 		bracketavg 		= 0.0001 								if bracketavg == 0 // R reads zero as -0.00

		rename 			thres_low 		threshold
		sort 			threshold

		keep 			year subsector_BEA p bracketavg average threshold assets_total number_total number

		// Save the tabulation as a Stata file and run Gpinter
		// Using "saveold" allows R to read the file from very recent STATA versions
		saveold "$OUTPUT/temp/tabulation-input.dta", version(11) replace 
		
		// Run Gpinter
		shell "$Rdirscript" "gpinter_code.R" "$RWORKDIR"
		
		// Keep vars that are constant 
		keep 			year subsector_BEA assets_total number_total
		keep if 		_n 				== 1

		// Import distribution and keep key statistics
		cross using "$OUTPUT/temp/tabulation-output.dta"

		drop 			bracket_share top_average bottom_average bracket_average bottom_share invpareto threshold
		
		gen 			pct				= 1 									if _n <= 127

		gen 			varname 		= ""
		replace 		varname 		= "_50pct" 								if p == 0.5 & pct == 1
		replace 		varname 		= "_10pct" 								if p == 0.9 & pct == 1
		replace 		varname 		= "_1pct" 								if p == 0.99 & pct == 1
		replace 		varname 		= "_0_1pct" 							if p == 0.999 & pct == 1
		* drop 			p pct p_*
		drop 			p pct
		keep if 		varname 	    != ""
		
		// Reshape to create time series structure
		reshape wide 	top_share, i(year) j(varname) string
		
		// Merge years
		merge 1:1 subsector_BEA year using "`subsector_BEA_concent'", nogen
		sort 			subsector_BEA year
		save 			"`subsector_BEA_concent'", replace
	}
}


// Merge annual dta files into one
use "`subsector_BEA_concent'", clear


// Identify failed interpolations and set values to missing (too few brackets)
sort 				year subsector_BEA
gen 				issues 			= 1 										if top_share_1pct[_n] == top_share_1pct[_n-1]
foreach var of varlist top_* {
	replace 		`var' 			= . 										if issues == 1
}

rename top_share_0_1pct 			tsh_assets_ipol_0_1pct
rename top_share_1pct 				tsh_assets_ipol_1pct
rename top_share_10pct 				tsh_assets_ipol_10pct
rename top_share_50pct 				tsh_assets_ipol_50pct

*===== Interpolate outliers and deal with consolidation in the 1930s
do "outliers_subsector.do"

keep subsector_BEA year tsh_assets_ipol_50pct tsh_assets_ipol_10pct tsh_assets_ipol_1pct tsh_assets_ipol_0_1pct 
order subsector_BEA year tsh_assets_ipol_50pct tsh_assets_ipol_10pct tsh_assets_ipol_1pct tsh_assets_ipol_0_1pct 


label var subsector_BEA				"Subsector"
label var year						"Year"
label var tsh_assets_ipol_50pct 	"Top 50% asset share" 
label var tsh_assets_ipol_10pct 	"Top 10% asset share" 
label var tsh_assets_ipol_1pct 		"Top 1% asset share" 
label var tsh_assets_ipol_0_1pct 	"Top 0.1% asset share" 

sort subsector_BEA year
order subsector_BEA year tsh_assets_ipol_0_1pct tsh_assets_ipol_1pct tsh_assets_ipol_10pct tsh_assets_ipol_50pct

save "$OUTPUT/soi/topshares/subsector_concent_R5.dta", replace
capture erase "$OUTPUT/temp/tabulation-input.dta"
capture erase "$OUTPUT/temp/tabulation-output.dta"







*====================================================================
*========= More granular subsector concentration by assets ==========
*====================================================================


// Create files
clear all
gen 		year 			= .
gen 		subsector 		= ""
tempfile 	subsector_concent	
save 		"`subsector_concent'"	

forvalues i = 1931 / 2013 {
	local years `years' "`i'"
}

// Run interpolation
foreach y of local years {
    
	use "$OUTPUT/soi/brackets/subsector_gran_brackets_assets_R5.dta", clear
	keep if 		year 			== `y'
	sort 			subsector year
	levelsof 		subsector, 		local(sectors)

	foreach s of local sectors {
	    
		use "$OUTPUT/soi/brackets/subsector_gran_brackets_assets_R5.dta", clear
		sort 			year subsector thres_low

		keep if 		year 			== `y'
		keep if 		subsector 		== "`s'"
		drop if 		number 			== . | number == 0

		// Percentiles
		gen double 		pctile 			= number / number_total 
		gen double		p 				= 0 in 1
		replace 		p 				= pctile[_n-1] + p[_n-1] 				if _n > 1
	
		// Create variables for gpinter
		gen double 		average 		= assets_total / number_total 			// Average overall
		gen double 		bracketavg 		= assets / number 						// Average in each bracket	
		replace 		bracketavg 		= 0 									if bracketavg == . & assets == . & thres_low == 0  // R reads zero as -0.00
		replace 		bracketavg 		= 0.0001 								if bracketavg == 0 // R reads zero as -0.00

		rename 			thres_low 		threshold
		sort 			threshold
		
		keep 			year subsector p bracketavg average threshold assets_total number_total number 

		// Save the tabulation as a Stata file and run Gpinter
		// Using "saveold" allows R to read the file from very recent STATA versions
		saveold "$OUTPUT/temp/tabulation-input.dta", version(11) replace 
		
		// Run Gpinter
		shell "$Rdirscript" "gpinter_code.R" "$RWORKDIR"

		// Keep vars that are constant 
		keep 			year subsector assets_total number_total 
		keep if 		_n 			== 1

		// Import distribution and keep key statistics
		cross using "$OUTPUT/temp/tabulation-output.dta"

		drop 			bracket_share top_average bottom_average bracket_average bottom_share invpareto threshold
		
		gen 			pct			= 1 										if _n <= 127

		gen 			varname 	= ""
		replace 		varname 	= "_50pct" 									if p == 0.5 & pct == 1
		replace 		varname 	= "_10pct" 									if p == 0.9 & pct == 1
		replace 		varname 	= "_1pct" 									if p == 0.99 & pct == 1
		replace 		varname 	= "_0_1pct" 								if p == 0.999 & pct == 1
		* drop 			p pct p_*
		drop 			p pct
		keep if 		varname 	!= ""
		
		// Reshape to create time series structure
		reshape wide 	top_share, i(year) j(varname) string
		
		// Merge years
		merge 1:1 subsector year using "`subsector_concent'"	, nogen
		sort subsector year
		save "`subsector_concent'"	, replace
	}
}

// Identify failed interpolations and set values to missing (too few brackets)
sort 				year subsector
gen 				issues 		= 1 											if top_share_1pct[_n] == top_share_1pct[_n-1]
foreach var of varlist top_* {
	replace 		`var' 		= . 											if issues == 1
}

rename 				top_share_1pct tsh_assets_ipol_1pct

*===== Interpolate outliers and deal with consolidation in the 1930s
do "outliers_subsector"

keep 				subsector year tsh_assets_ipol_1pct 
order 				subsector year tsh_assets_ipol_1pct 

label var 			subsector				"Subsector"
label var			year 					"Year"
label var 			tsh_assets_ipol_1pct 	"Top 1% asset share" 

sort subsector year
save "$OUTPUT/soi/topshares/subsector_gran_concent_R5.dta", replace
capture erase "$OUTPUT/temp/tabulation-input.dta"
capture erase "$OUTPUT/temp/tabulation-output.dta"



