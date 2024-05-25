/************ Function ************/

*This file performs robustness checks for aggregate top asset share estimates with and without returns with missing balance sheets 

/************ Source ************/

*"output/soi/brackets/sector_brackets_assets_R5.dta" compiled by code/clean/generate_by_sector_by_assets.do  
*"input/soi/digitized/corp_totals_pre1959_R5.dta"

clear all


*===================================================================================
*= Concentration by assets with adjusted totals due to missing balance sheets ======
*===================================================================================

use "$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", clear

keep if year < 1959

collapse number_total treceipts_total, by(year sector_main)

// This file has the totals for all corporations (with and without balance sheets)
merge 1:1 sector_main year using "$DATA/soi/digitized/corp_totals_pre1959_R5.dta", gen(m1) keepusing(all*) keep(1 3)

gen double	ratio_number 	= allnumber / number_total
gen double 	ratio_treceipts = alltreceipts / treceipts_total
keep 		sector_main year ratio*
	
tempfile 	by_sector_adjustment_factors
save 		"`by_sector_adjustment_factors'"	
	


// Create files
clear
gen 		year 		= .
gen 		sector_main = ""
tempfile 	agg_concent_missing_bs
save 		"`agg_concent_missing_bs'"	



// Run interpolation
forvalues i = 1931/1958 {
	local years `years' "`i'"
}

local sectors All
foreach y of local years {
	foreach s of local sectors {
		
		use "$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", clear
		
		sort sector_main year thres_low
		keep if 		year 				== `y'
		keep if 		sector_main 		== "`s'"
		drop if 		number 				== .

		// Adjustment for missing balance sheets
		merge m:1 sector_main year using "`by_sector_adjustment_factors'", keep(3) keepusing(ratio*)
		
		gen double		number_missing 		= (number_total * (ratio_number - 1))
		gen double 		assets_missing 		= assets_total * (ratio_treceipts - 1)
		gen double 		av_assets_missing 	= assets_missing / number_missing
		
		replace 		number 				= number + number_missing 				if thres_low <= av_assets_missing & thres_low[_n+1] > av_assets_missing
		replace 		assets 				= assets + assets_missing 				if thres_low <= av_assets_missing & thres_low[_n+1] > av_assets_missing		
		replace 		number_total 		= number_total + number_missing 
		replace 		assets_total 		= assets_total + assets_missing 
		
		// Percentiles
		gen double 		pctile 				= number / number_total 
		gen double		p 					= 0 in 1
		replace 		p 					= pctile[_n-1] + p[_n-1] 				if _n > 1
		
		// Create variables for gpinter
		gen double 		average 			= assets_total / number_total 			// Average overall
		gen double 		bracketavg 			= assets / number 						// Average in each bracket	
		replace 		bracketavg 			= 0 									if bracketavg == . & assets == . & thres_low == 0  // R reads zero as -0.00
		replace 		bracketavg 			= 0.0001 								if bracketavg == 0 // R reads zero as -0.00

		gen double 		threshold 			= thres_low
		sort 			threshold

		keep 			year sector_main p bracketavg average threshold assets_total number_total treceipts_total breceipts_total

		// Save the tabulation as a Stata file and run Gpinter
		// Using "saveold" allows R to read the file from very recent STATA versions
		saveold "$OUTPUT/temp/tabulation-input.dta", version(11) replace 
		
		// Run Gpinter
		shell "$Rdirscript" "gpinter_code.R" "$RWORKDIR"
		
		// Keep vars that are constant 
		keep 			year sector_main assets_total number_total treceipts_total breceipts_total
		keep if 		_n 					== 1

		// Import distribution and keep key statistics
		cross using "$OUTPUT/temp/tabulation-output.dta"
		
		drop 			bracket_share top_average bottom_average bracket_average threshold bottom_share invpareto
		
		gen 			pct					= 1 									if _n <= 127

		gen 			varname 			= ""
		replace 		varname 			= "_50pct" 								if p == 0.5 & pct == 1
		replace 		varname 			= "_10pct" 								if p == 0.9 & pct == 1
		replace 		varname 			= "_1pct" 								if p == 0.99 & pct == 1
		replace 		varname 			= "_0_1pct" 							if p == 0.999 & pct == 1
		drop 			p pct
		keep if 		varname 			!= ""
		
		// Reshape to create time series structure
		reshape wide top_share, i(year) j(varname) string

		// Merge years
		merge 1:1 sector_main year  using "`agg_concent_missing_bs'", nogen
		sort 			sector_main year
		save 			"`agg_concent_missing_bs'", replace
	}
}

// Identify failed interpolations and set values to missing (too few brackets)
sort year sector_main
gen 					issues 				= 1 									if top_share_1pct[_n] == top_share_1pct[_n-1]
foreach var of varlist top_* {
	replace 			`var' 				= . 									if issues ==1
}

rename 					top_share_1pct 		tsh_assets_ipoladj_1pct
	
// Interpolate outliers and deal with consolidation in the 1930s
do "outliers_sector.do"
	
/* Finalize */

keep 					sector_main year tsh_assets_ipoladj_1pct
order 					sector_main year tsh_assets_ipoladj_1pct

label var sector_main 				"Main sector"
label var year 						"Year"
label var tsh_assets_ipoladj_1pct 	"Top 1% asset share, with missing balance sheet adjustment"

save "$OUTPUT/soi/topshares/agg_concent_adj_R5.dta", replace
capture erase "$OUTPUT/temp/tabulation-input.dta"
capture erase "$OUTPUT/temp/tabulation-output.dta"


