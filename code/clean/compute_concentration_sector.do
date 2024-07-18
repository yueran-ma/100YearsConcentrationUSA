/************ Function ************/

*This file uses generalized Pareto interpolation to estimate top shares for main sectors  

/************ Source ************/

*"output/soi/brackets/sector_brackets_assets_R5.dta" compiled by code/clean/generate_by_sector_by_assets.do
*"output/soi/brackets/sector_brackets_receipts_R5.dta" compiled by code/clean/generate_by_sector_by_receipts.do
*"output/soi/brackets/sector_brackets_ninc_R5.dta" compiled by code/clean/generate_by_sector_by_ninc.do
*"output/soi/brackets/sector_type_brackets_receipts_R5.dta" compiled by code/clean/generate_by_sector_by_receipts_noncorp.do
*"output/soi/brackets/agg_type_brackets_assets_R5.dta compiled by code/clean/generate_by_assets_part.do
*"input/soi/digitized/noncorp_totals_R5.dta"
*"input/jst/JSTdatasetR6.dta" downloaded from https://www.macrohistory.net/database/



clear all


*====================================================================
*===== Main sector concentration by receipts and business type ======
*==================================================================== 

// Prepare population data
use "$DATA/JST/JSTdatasetR6.dta", clear
keep if iso == "USA"

gen double	temp 				= pop 			if year == 1980
egen double	pop_1980 			= mean(temp)
drop 		temp

gen double 	number_top500pop 	= 500 * pop / pop_1980
gen double 	number_top5000pop 	= 5000 * pop / pop_1980
sort 		year
keep 		year number_top500pop number_top5000pop

tempfile 	popadj_1980
save 		"`popadj_1980'", replace


// Create file
clear all
gen 		year 		= .
gen 		type 		= ""
gen 		sector_main = ""

tempfile 	sector_type_concent_receipts	
save 		"`sector_type_concent_receipts'"



// Run interpolation
local years 1959 1960 1961 1962 1965 1966 1968 1969 1970 1971 1972 1973 1974 1975 1976 1977 1978 1979 1980 1998 1999 2000 2001 2002 2003

foreach y of local years {
	
	use "$OUTPUT/soi/brackets/sector_type_brackets_receipts_R5.dta", clear
	keep if 				year 				== `y'
	sort 					sector_main year thres_low
	
	levelsof 				type, 				local(types)
	levelsof 				sector_main, 		local(sectors)

	
	foreach s of local sectors {
	
		use "$OUTPUT/soi/brackets/sector_type_brackets_receipts_R5.dta", clear
		merge m:1 year using "`popadj_1980'", nogen
		
		keep if 					sector_main	 		== "`s'"
		bysort type year: gen 		d 			 		= 1 							if _n == 1
		keep if 					d 					== 1 
		sort year
		by year: egen double		temp 				= sum(number_total)
		
		keep 						temp year sector_main *pop  
		rename 						temp 				number_total_all
		
		gen 						tables 				= "Combined"
		gen 						type 				= "combined"

		// Additional thresholds
		gen double 					p_top500 			= round(1 - (500 / number_total_all), 0.0000000001)
		replace 					p_top500 			= 1 							if number_total_all < 500
		gen double 					p_top5000 			= 1 - (5000 / number_total_all)
		replace 					p_top5000 			= 1 							if number_total_all < 5000
		gen double 					p_top500pop 		= round(1 - (number_top500pop / number_total_all), 0.0000000001)
		replace 					p_top500pop 		= 1 							if number_total_all < number_top500pop
		gen double 					p_top5000pop 		= 1 - (number_top5000pop / number_total_all)
		replace 					p_top5000pop 		= 1 							if number_total_all < number_top5000pop

		// Top X% in total matched to correspond to the 1980 percentile of top 5000 in total
		// Agriculture: use nonfarm sole prop only when calculating 1980 percentile
		sort sector_main
		replace 					number_total_all 	= 514835 						if sector_main == "Agriculture" & year == 1980
		gen double					temp_p_top5000 		= 1 - (5000 / number_total_all) if year == 1980
		by sector_main: egen double p_top5000in1980 	= mean(temp_p_top5000)
		replace 					p_top5000in1980 	= 0 							if number_total_all <= 5000
		drop 						temp_p_top5000	
		
		keep if 					year 				== `y'	

		// Save the tabulation as a Stata file and run Gpinter
		// Using "saveold" allows R to read the file from very recent STATA versions
		saveold 					"$OUTPUT/temp/tabulation-input_combined.dta", version(11) replace 


		foreach t of local types {
			use "$OUTPUT/soi/brackets/sector_type_brackets_receipts_R5.dta", clear
			merge m:1 year using "`popadj_1980'", nogen
			sort 					year sector_main thres_low

			keep if 				year 				== `y'
			keep if 				sector_main 		== "`s'"
			keep if 				type 				== "`t'"
			drop if 				number 				== .

			// Percentiles
			sort 					year sector_main thres_low
			gen double 				pctile 				= number / number_total 
			gen double				p 					= 0 in 1
			replace 				p 					= pctile[_n-1] + p[_n-1] 		if _n > 1
			
			// Additional thresholds
			gen double 				p_top500 			= round(1 - (500 / number_total), 0.0000000001)
			replace 				p_top500 			= 1 							if number_total < 500
			gen double 				p_top5000 			= 1 - (5000 / number_total)
			replace 				p_top5000 			= 1 							if number_total < 5000
			gen double 				p_top500pop 		= round(1 - (number_top500pop / number_total), 0.0000000001)
			replace 				p_top500pop 		= 1 							if number_total < number_top500pop
			gen double 				p_top5000pop 		= 1 - (number_top5000pop / number_total)
			replace 				p_top5000pop 		= 1 							if number_total < number_top5000pop

			// Create variables for gpinter
			gen double 				average 			= size_total / number_total 	// Average overall
			gen double 				bracketavg 			= size / number 				// Average in each bracket
			replace 				bracketavg 			= 0 							if bracketavg == . & size == . & thres_low == 0  // R reads zero as -0.00
			replace 				bracketavg 			= 0.0001 						if bracketavg == 0 // R reads zero as -0.00

			rename 					thres_low 			threshold
			sort 					threshold

			keep 					year type sector_main tables p bracketavg average threshold number_total p_top500 p_top5000 p_top500pop p_top5000pop
			
			// Save the tabulation as a Stata file and run Gpinter
			// Using "saveold" allows R to read the file from very recent STATA versions
			saveold 				"$OUTPUT/temp/tabulation-input_`t'.dta", version(11) replace 
		}

		// Run Gpinter
		shell 						"$Rdirscript" "gpinter_code_bygroup.R" "$RWORKDIR"

		local types2 ""combined" `types'"
		foreach t of local types2 {
			use "$OUTPUT/temp/tabulation-input_`t'.dta", clear
		 
			// Drop vars that are not needed
			cap drop 				p bracketavg average threshold
			keep if 				_n 				== 1
			
			// Import distribution and keep key statistics
			cross using "$OUTPUT/temp/tabulation-output_`t'.dta"
			
			drop 					bracket_share top_average bottom_average bracket_average threshold bottom_share invpareto
			
			gen 					pct				= 1 								if _n <= 112
			replace 				pct				= 2 								if _n > 112 & _n <= 114 & number_total > 5000 & number_total != .
			replace					pct				= 2 								if _n > 112 & _n <= 113 & number_total > 500 & number_total != .
			replace 				pct				= 3 								if _n > 114 & _n <= 116 & number_total > 5000 & number_total != .
			replace 				pct				= 3 								if _n > 114 & _n <= 115 & number_total > 500 & number_total != .
			

			gen 					varname		 	= ""
			replace 				varname 		= "_50pct" 							if float(p) == float(0.5) & pct == 1
			replace 				varname 		= "_10pct" 							if float(p) == float(0.9) & pct == 1
			replace 				varname 		= "_1pct" 							if float(p) == float(0.99) & pct == 1
			replace 				varname 		= "_0_1pct" 						if float(p) == float(0.999) & pct == 1
			replace 				varname 		= "_500firms" 						if float(p) == float(p_top500) & pct == 2
			replace 				varname 		= "_5000firms" 						if float(p) == float(p_top5000) & pct == 2
			replace 				varname 		= "_500firmspop" 					if float(p) == float(p_top500pop) & pct == 3
			replace 				varname 		= "_5000firmspop" 					if float(p) == float(p_top5000pop) & pct == 3
			cap replace 			varname 		= "_500in1980" 						if float(p) == float(p_top500in1980) & pct == .
			cap replace 			varname 		= "_5000in1980" 					if float(p) == float(p_top5000in1980) & pct == .
			
			drop 					p pct p_* number_total
			keep if 				varname 		!= ""
			
			// Reshape to create time series structure
			reshape wide 			top_share, 		i(year) j(varname) string
			
			// Merge years
			merge 1:1 sector_main type year using "`sector_type_concent_receipts'", nogen
			sort 					type year
			sleep 400
			
			save "`sector_type_concent_receipts'", replace
			
		}
	}
}


// Identify failed interpolations and set values to missing (too few brackets)
gen 					n 					= 1 								if tables == "Combined"
replace 				n 					= 2 								if tables == "Corporations"
replace 				n 					= 3 								if tables == "Partnerships"
replace 				n 					= 4 								if tables == "Sole Proprietorships"

sort 					n year sector_main
gen 					issues 				= 1 								if top_share_1pct[_n] == top_share_1pct[_n-1]
foreach var of varlist top_* {
	replace 			`var' 				= . 								if issues == 1
}

sort sector_main tables year
keep sector_main tables year top_share_0_1pct top_share_1pct top_share_500firms top_share_5000firms top_share_500firmspop top_share_5000firmspop top_share_5000in1980
order sector_main tables year top_share_0_1pct top_share_1pct top_share_500firms top_share_5000firms top_share_500firmspop top_share_5000firmspop top_share_5000in1980

label var sector_main 						"Main sector"
label var year 								"Year"

label var top_share_1pct 					"Top 1% receipt share" 
label var top_share_0_1pct 					"Top 0.1% receipt share" 
label var top_share_500firms 				"Top 500 receipt share" 
label var top_share_5000firms 				"Top 5000 receipt share"  

label var top_share_500firmspop 			"Top 500 receipt share, pop growth adj" 
label var top_share_5000firmspop 			"Top 5000 receipt share, pop growth adj" 
label var top_share_5000in1980 				"Top X% receipt share (X% based on share of 5000 in all in 1980)" 

save "$OUTPUT/soi/topshares/sector_type_concent_R5.dta", replace	
	

	

*===================================================================================
*= Main sector concentration by assets and business type (corps and partnerships) ==
*===================================================================================


// Create file
clear all
gen 		year 		= .
gen 		type 		= ""
gen 		sector_main = ""

tempfile 	sector_type_concent_assets	
save 		"`sector_type_concent_assets'"


// Run interpolation
use "$OUTPUT/soi/brackets/agg_type_brackets_assets_R5.dta", clear
levelsof year, local(years) separate(" ")
	
foreach y of local years{
	use "$OUTPUT/soi/brackets/agg_type_brackets_assets_R5.dta", clear
	keep if 					year 				== `y'
	sort 						sector_main year thres_low
	levelsof 					type, 				local(types)
	levelsof 					sector_main,		local(sectors)

	foreach s of local sectors {
		use "$OUTPUT/soi/brackets/agg_type_brackets_assets_R5.dta", clear
		
		display "`y'"
		display "`s'"
		display "Assets by type"
		
		keep if 				sector_main 		== "`s'"
		bysort type year: gen 	d 					= 1 							if _n == 1
		keep if 				d 					== 1 
		sort 					year
		
		by year: egen double	temp 				= sum(number_total)
		by year: egen double	temp2   			= sum(assets_total)
		
		keep 					temp temp2 year sector_main
		rename 					temp 				number_total_all
		rename 					temp2 				assets_total_all
		
		gen 					tables 				= "Combined"
		gen 					type 				= "combined"
		
		// Additional thresholds
		gen double 				p_top500 			= round(1 - (500 / number_total_all), 0.0000000001)
		replace 				p_top500 			= 1 							if number_total_all < 500
		gen double 				p_top5000 			= 1 - (5000 / number_total_all)
		replace 				p_top5000 			= 1 							if number_total_all < 5000	

		keep if 				year 				== `y'	
		keep if					_n 					== 1
		
		rename 					number_total_all 	number_total
		rename 					assets_total_all 	assets_total
		
		
		// Save the tabulation as a Stata file and run Gpinter
		// Using "saveold" allows R to read the file from very recent STATA versions
		saveold 				"$OUTPUT/temp/tabulation-input_combined.dta", version(11) replace 
	
		foreach t of local types {
			use "$OUTPUT/soi/brackets/agg_type_brackets_assets_R5.dta", clear
			sort 				year sector_main type thres_low

			keep if 			year 				== `y'
			keep if 			sector_main 		== "`s'"
			keep if 			type 				== "`t'"
			drop if 			number 				== .

			// Percentiles
			sort 				year sector_main thres_low
			gen double 			pctile 				= number / number_total 
			gen double			p 					= 0 in 1
			replace 			p 					= pctile[_n-1] + p[_n-1] 		if _n > 1
			
			// Additional thresholds
			gen double 			p_top500 			= round(1 - (500 / number_total), 0.0000000001)
			replace 			p_top500 			= 1 							if number_total < 500
			gen double 			p_top5000 			= 1 - (5000 / number_total)
			replace 			p_top5000 			= 1 							if number_total < 5000

			// Create variables for gpinter
			gen double 			average 			= assets_total / number_total 	// Average overall
			gen double 			bracketavg 			= assets / number 				// Average in each bracket
			replace 			bracketavg 			= 0 							if bracketavg == . & assets == . & thres_low == 0  // R reads zero as -0.00
			replace 			bracketavg 			= 0.0001 if bracketavg == 0 	// R reads zero as -0.00

			rename 				thres_low 			threshold
			sort 				threshold

			keep 				year type sector_main tables p bracketavg average threshold number_total assets_total p_top500 p_top5000
			
			// Save the tabulation as a Stata file and run Gpinter
			// Using "saveold" allows R to read the file from very recent STATA versions
			saveold 			"$OUTPUT/temp/tabulation-input_`t'.dta", version(11) replace 
		}

		// Run Gpinter
		shell 					"$Rdirscript" "gpinter_code_bygroup_byassets.R" "$RWORKDIR"

		local types2 ""combined" `types'"
		foreach t of local types2 {
			use "$OUTPUT/temp/tabulation-input_`t'.dta", clear
		 
			// Keep vars that are constant 
			cap drop p bracketavg average threshold
			*keep year type tables sector_main number_total p_top500 p_top5000 
			keep if 			_n 					== 1
			
			// Import distribution and keep key statistics
			cross using "$OUTPUT/temp/tabulation-output_`t'.dta"
			
			drop 				bracket_share top_average bottom_average bracket_average threshold bottom_share 
			
			gen 				pct					= 1 							if _n <= 112
			replace 			pct					= 2 							if _n > 112 & _n <= 114 & number_total > 5000 & number_total != .
			replace 			pct					= 2 							if _n > 112 & _n <= 113 & number_total > 500 & number_total != .	

			gen 				varname 			= ""
			replace 			varname 			= "_50pct" 						if float(p) == float(0.5) & pct == 1
			replace 			varname 			= "_10pct" 						if float(p) == float(0.9) & pct == 1
			replace 			varname 			= "_1pct" 						if float(p) == float(0.99) & pct == 1
			replace 			varname 			= "_0_1pct" 					if float(p) == float(0.999) & pct == 1
			replace 			varname 			= "_500firms" 					if float(p) == float(p_top500) & pct == 2
			replace 			varname 			= "_5000firms" 					if float(p) == float(p_top5000) & pct == 2
			
			drop 				p pct p_*
			keep if 			varname 			!= ""
			
			// Reshape to create time series structure
			reshape wide 		top_share invpareto, i(year) j(varname) string
			
			// Merge years
			merge 1:1 sector_main type year using "`sector_type_concent_assets'", nogen
			sort 				type year	
			save 				"`sector_type_concent_assets'", replace
		}
	}
}


// Identify failed interpolations and set values to missing (too few brackets)
gen 				n 					= 1 									if tables == "Combined"
replace				n 					= 2 									if tables == "Corporations"
replace 			n 					= 3 									if tables == "Partnerships"

sort 				n sector_main year
gen 				issues 				= 1 									if top_share_1pct[_n] == top_share_1pct[_n-1]
foreach var of varlist top_* {
	replace 		`var' 				= . 									if issues == 1
}
drop 				issues

sort 				n year sector_main
save 				"`sector_type_concent_assets'", replace


use "$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", clear
keep if sector_main == "All"
collapse (lastnm) assets_total, by(year)
tempfile 			temp
save 				"`temp'"


use "`sector_type_concent_assets'", clear

// Calculate total assets of top 5000 (corps and partnerships)
gen double		assets_comb_5000firms			= top_share_5000firms * assets_total

keep if 		tables 							== "Combined"
keep 			assets_comb_5000firms sector_main year
merge 1:1 year using "`temp'", nogen 

gen double 			tsh_assets_ipol_5000firmscomb 	= assets_comb_5000firms / assets_total
keep if 		tsh_assets_ipol_5000firmscomb	!= .
keep 			sector_main year tsh_assets_ipol_5000firmscomb 

save 			"`sector_type_concent_assets'", replace





*====================================================================
*========= Main sector concentration by assets ======================
*==================================================================== 

// Create file
clear all
gen 			year = .
gen 			sector_main = ""
tempfile 		sector_concent_assets	
save 			"`sector_concent_assets'"



// Run interpolation
local years
forvalues i = 1931 / 2013 {
	local years `years' "`i'"
}
local sectors All Agriculture Construction Finance Manufacturing Mining Services Trade Utilities 


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
		replace 		p 				= pctile[_n-1] + p[_n-1] 					if _n > 1
		
		// Additional thresholds
		gen double 		p_top500 		= 1 - (500 / number_total)
		replace 		p_top500 		= 0 										if number_total <= 500
		gen double 		p_top5000 		= 1 - (5000 / number_total)
		replace 		p_top5000 		= 0 										if number_total <= 5000
		
		// Create variables for gpinter
		gen double 		average 		= assets_total / number_total 				// Average overall
		gen double 		bracketavg 		= assets / number 							// Average in each bracket	
		replace 		bracketavg 		= 0 										if bracketavg == . & assets == . & thres_low == 0  // R reads zero as -0.00
		replace 		bracketavg 		= 0.0001 if bracketavg == 0 				// R reads zero as -0.00

		rename 			thres_low threshold
		sort 			threshold
		
		keep 			year sector_main p bracketavg average threshold assets_total number_total treceipts_total breceipts_total number p_top500 p_top5000

		// Save the tabulation as a Stata file and run Gpinter
		// Using "saveold" allows R to read the file from very recent STATA versions
		saveold 		"$OUTPUT/temp/tabulation-input.dta", version(11) replace 
		
		// Run Gpinter
		shell 			"$Rdirscript" "gpinter_code.R" "$RWORKDIR"
		
		// Keep vars that are constant 
		keep 			year sector_main assets_total number_total treceipts_total breceipts_total p_top500 p_top5000
		keep if 		_n 				== 1

		// Import distribution and keep key statistics
		cross using "$OUTPUT/temp/tabulation-output.dta"

		drop 			bracket_share top_average bottom_average bracket_average threshold bottom_share invpareto
		
		gen 			pct				= 1 										if _n <= 127
		replace 		pct 			= 2 										if _n > 127 & _n <= 129 & number_total > 5000 & number_total != .
		replace 		pct				= 2 										if _n > 127 & _n <= 128 & number_total > 500 & number_total != .

		gen 			varname 		= ""
		replace 		varname 		= "_50pct" 									if p == 0.5 & pct == 1
		replace 		varname 		= "_10pct" 									if p == 0.9 & pct == 1
		replace 		varname 		= "_1pct" 									if p == 0.99 & pct == 1
		replace 		varname 		= "_0_1pct" 								if p == 0.999 & pct == 1
		replace 		varname 		= "_500firms" 								if p == p_top500 & pct == 2
		replace 		varname 		= "_5000firms" 								if p == p_top5000 & pct == 2
		drop 			p pct p_*
		keep if 		varname 		!= ""
		
		// Reshape to create time series structure
		reshape wide	top_share, i(year) j(varname) string
		
		// Merge years
		merge 1:1 sector_main year  using "`sector_concent_assets'", nogen
		sort 			sector_main year
		save 			"`sector_concent_assets'", replace

	}
}

// Identify failed interpolations and set values to missing (too few brackets)
sort 				year sector_main 
gen 				issues 			= 1 										if top_share_1pct[_n] == top_share_1pct[_n-1]
foreach var of varlist top_* {
	replace 		`var' 			= .	 										if issues == 1
}
drop 				issues
save 				"`sector_concent_assets'", replace





*====================================================================
*========= Main sector concentration by receipts ====================
*==================================================================== 


// Create file
clear all
gen 			year = .
gen 			sector_main = ""
tempfile 		sector_concent_receipts	
save 			"`sector_concent_receipts'"


// Run interpolation
use "$OUTPUT/soi/brackets/sector_brackets_receipts_R5.dta", clear
levelsof year, local(years) separate(" ")
	
foreach y of local years{
	
	use "$OUTPUT/soi/brackets/sector_brackets_receipts_R5.dta", clear
	keep if year == `y'
	levelsof sector_main, local(sectors)

	foreach s of local sectors {
		
		use "$OUTPUT/soi/brackets/sector_brackets_receipts_R5.dta", clear
		merge m:1 sector_main year using "$DATA/soi/digitized/noncorp_totals_R5.dta", keep(1 3) gen(merge1) keepusing(number_*)

		keep if 					sector_main 		== "`s'"
		drop if 					number 				== .
		sort 						year sector_main thres_low

		// Additional thresholds
		gen double 					p_top500 			= 1 - (500 / number_total)
		replace 					p_top500 			= 1 							if number_total < 500
		gen double 					p_top5000 			= 1 - (5000 / number_total)
		replace 					p_top5000 			= 1 							if number_total < 5000
		
		// Top X% in corp matched to correspond to the 1980 percentile of top 5000 in all
		sort 						sector_main
		gen double					temp_p_top5000 		= 1 - (5000 / number_total_all) if year == 1980
		by sector_main: egen double	p_top5000in1980all 	= mean(temp_p_top5000)
		replace 					p_top5000in1980all 	= 0 							if number_total <= 5000
		drop 						temp_p_top5000
		
		keep if 					year 				== `y'

		// Percentiles
		sort 						year sector_main thres_low
		gen double 					pctile 				= number / number_total 
		gen double					p 					= 0 in 1
		replace 					p 					= pctile[_n-1] + p[_n-1] 		if _n > 1
		
		// Create variables for gpinter
		gen double 					average 			= size_total / number_total 	// Average overall
		gen double 					bracketavg 			= size / number 				// Average in each bracket
		replace 					bracketavg 			= 0 							if bracketavg == . & size == . & thres_low == 0  // R reads zero as -0.00
		replace 					bracketavg 			= 0.0001 						if bracketavg == 0 // R reads zero as -0.00

		rename 						thres_low 			threshold
		sort 						threshold

		keep 						year sector_main p bracketavg average threshold number_total p_top500 p_top5000 p_top5000in1980all
		
		// Save the tabulation as a Stata file and run Gpinter
		// Using "saveold" allows R to read the file from very recent STATA versions
		saveold "$OUTPUT/temp/tabulation-input.dta", version(11) replace 

		// Run Gpinter
		shell "$Rdirscript" "gpinter_code.R" "$RWORKDIR"
		
		// Keep vars that are constant 
		keep 						year sector_main p_top500 p_top5000 p_top5000in1980all number_total
		keep if 					_n == 1

		// Import distribution and keep key statistics
		cross using "$OUTPUT/temp/tabulation-output.dta"

		drop 						bracket_share top_average bottom_average bracket_average threshold bottom_share invpareto
		
		
		gen 						pct					= 1 							if _n <= 127
		replace 					pct					= 2 							if _n > 127 & _n <= 129 & number_total > 5000 & number_total != .
		replace 					pct					= 2 							if _n > 127 & _n <= 128 & number_total > 500 & number_total != .
		
		gen 						varname 			= ""
		replace 					varname 			= "_50pct" 						if p == 0.5 & pct == 1
		replace 					varname 			= "_10pct" 						if p == 0.9 & pct == 1
		replace 					varname 			= "_1pct" 						if p == 0.99 & pct == 1
		replace 					varname 			= "_0_1pct" 					if p == 0.999 & pct == 1
		replace 					varname 			= "_500firms" 					if p == p_top500 & pct == 2
		replace 					varname 			= "_5000firms" 					if p == p_top5000 & pct == 2
		replace 					varname 			= "_5000in1980all" 				if p == p_top5000in1980all & pct == .
		drop 						p pct p_* number_total
		keep if 					varname 			!= ""
		
		// Reshape to create time series structure
		reshape wide 				top_share, i(year) j(varname) string

		// Merge years
		merge 1:1 sector_main year using "`sector_concent_receipts'", nogen
		sort 						sector_main year
		save 						"`sector_concent_receipts'", replace

	}
}

// Identify failed interpolations and set values to missing (too few brackets)
sort 						year sector_main 
gen 						issues 				= 1 							if top_share_1pct[_n] == top_share_1pct[_n-1]
foreach var of varlist top_* {
	replace 				`var' 				= . 							if issues == 1
}
drop 						issues
save 						"`sector_concent_receipts'", replace





*====================================================================
*======== Main sector concentration by net income ===================
*====================================================================


// Create file
clear all
gen 			year = .
gen 			sector_main = ""
tempfile 		sector_concent_ninc	
save 			"`sector_concent_ninc'"


// Run interpolation
use "$OUTPUT/soi/brackets/sector_brackets_ninc_R5.dta", clear
levelsof year, local(years) separate(" ")

foreach y of local years{	

	use "$OUTPUT/soi/brackets/sector_brackets_ninc_R5.dta", clear
	keep if 			year 			== `y'
	levelsof 			sector_main, 	local(sectors)

	foreach s of local sectors {
		
		use "$OUTPUT/soi/brackets/sector_brackets_ninc_R5.dta", clear
		sort 			year sector_main thres_low
		
		keep if 		year 			== `y'
		keep if 		sector_main 	== "`s'"
		drop if 		number 			== .

		// Percentiles
		gen double 		pctile 			= number / number_total 
		gen double		p 				= 0 in 1
		replace 		p 				= pctile[_n-1] + p[_n-1] 					if _n > 1
		
		// Additional thresholds
		gen double 		p_top500 		= 1 - (500 / number_total)
		replace 		p_top500 		= 0 										if number_total <= 500
		gen double 		p_top5000 		= 1 - (5000 / number_total)
		replace 		p_top5000 		= 0 										if number_total <= 5000
		
		// Create variables for gpinter	
		gen double 		average 		= ninc_total / number_total					// Average pverall
		gen double 		bracketavg 		= ninc / number 							// Average in each bracket
		replace 		bracketavg 		= 0 										if bracketavg == . & ninc == . & thres_low == 0  // R reads zero as -0.00
		replace 		bracketavg 		= 0.0001 									if bracketavg == 0 // R reads zero as -0.00
		
		rename 			thres_low 		threshold
		sort 			threshold
		
		keep 			year sector_main p bracketavg average threshold number_total p_top500 p_top5000
		
		// Save the tabulation as a Stata file and run Gpinter
		// Using "saveold" allows R to read the file from very recent STATA versions	
		saveold "$OUTPUT/temp/tabulation-input.dta", version(11) replace 

		// Run Gpinter
		shell "$Rdirscript" "gpinter_code.R" "$RWORKDIR"
		
		// Keep vars that are constant 
		keep 			year sector_main number_total p_top500 p_top5000
		keep if 		_n 				== 1

		// Import distribution and keep key statistics
		cross using "$OUTPUT/temp/tabulation-output.dta"

		drop 			bracket_share top_average bottom_average bracket_average threshold bottom_share invpareto
		
		gen 			pct				= 1 										if _n <= 127
		replace 		pct				= 2 										if _n > 127 & _n <= 129 & number_total > 5000 & number_total != .
		replace 		pct				= 2 										if _n > 127 & _n <= 128 & number_total > 500 & number_total != .
		
		gen 			varname 		= ""
		replace 		varname 		= "_50pct" 									if p == 0.5 & pct == 1
		replace 		varname 		= "_10pct" 									if p == 0.9 & pct == 1
		replace 		varname 		= "_1pct" 									if p == 0.99 & pct == 1
		replace 		varname 		= "_0_1pct" 								if p == 0.999 & pct == 1
		replace 		varname 		= "_500firms" 								if p == p_top500 & pct == 2
		replace 		varname 		= "_5000firms" 								if p == p_top5000 & pct == 2
		drop 			p pct p_* number_total
		keep if 		varname 		!= ""
		
		// Reshape to create time series structure
		reshape wide 	top_share, i(year) j(varname) string

		// Merge years
		merge 1:1 sector_main year using "`sector_concent_ninc'", nogen
		sort 			sector_main year
		save 			"`sector_concent_ninc'", replace

	}
}

// Identify failed interpolations and set values to missing (too few brackets)
sort 				year sector_main 
gen 				issues 			= 1 										if top_share_1pct[_n] == top_share_1pct[_n-1]
foreach var of varlist top_* {
	replace 		`var' 			= . 										if issues == 1
}
drop 				issues
save 				"`sector_concent_ninc'", replace



*====================================================================
*================== Merge main sector files =========================
*==================================================================== 

* Load by asset data to get totals 
use "`sector_concent_assets'", clear

rename 	top_share_0_1pct 				tsh_assets_ipol_0_1pct
rename 	top_share_1pct 					tsh_assets_ipol_1pct
rename 	top_share_10pct 				tsh_assets_ipol_10pct
rename 	top_share_50pct 				tsh_assets_ipol_50pct
rename 	top_share_500firms 				tsh_assets_ipol_500firms
rename 	top_share_5000firms 			tsh_assets_ipol_5000firms

keep 	sector_main year tsh*

merge 1:1 sector_main year using "`sector_concent_receipts'", nogen keepusing(top_share_*)

rename 	top_share_0_1pct 				tsh_receipts_ipol_0_1pct
rename 	top_share_1pct 					tsh_receipts_ipol_1pct
rename 	top_share_10pct 				tsh_receipts_ipol_10pct
rename 	top_share_50pct 				tsh_receipts_ipol_50pct
rename 	top_share_500firms 				tsh_receipts_ipol_500firms
rename 	top_share_5000firms 			tsh_receipts_ipol_5000firms
rename 	top_share_5000in1980all 		tsh_receipts_ipol_5000in1980all

keep 	sector_main year tsh*

merge 1:1 sector_main year using "`sector_concent_ninc'", nogen keepusing(top_share_*)

rename top_share_0_1pct 				tsh_ninc_ipol_0_1pct
rename top_share_1pct 					tsh_ninc_ipol_1pct
rename top_share_10pct 					tsh_ninc_ipol_10pct
rename top_share_50pct 					tsh_ninc_ipol_50pct
keep   sector_main year tsh*


*===== Interpolate outliers and deal with consolidation in the 1930s
do "outliers_sector.do"

preserve
keep 	sector_main year tsh_assets_ipol_50pct tsh_assets_ipol_10pct tsh_assets_ipol_1pct tsh_assets_ipol_0_1pct ///
		tsh_receipts_ipol_50pct tsh_receipts_ipol_10pct tsh_receipts_ipol_1pct tsh_receipts_ipol_0_1pct ///
		tsh_ninc_ipol_50pct tsh_ninc_ipol_10pct tsh_ninc_ipol_1pct tsh_ninc_ipol_0_1pct 

order 	sector_main year tsh_assets_ipol_50pct tsh_assets_ipol_10pct tsh_assets_ipol_1pct tsh_assets_ipol_0_1pct ///
		tsh_receipts_ipol_50pct tsh_receipts_ipol_10pct tsh_receipts_ipol_1pct tsh_receipts_ipol_0_1pct ///
		tsh_ninc_ipol_50pct tsh_ninc_ipol_10pct tsh_ninc_ipol_1pct tsh_ninc_ipol_0_1pct 

label var sector_main 						"Main sector"
label var year 								"Year"

label var tsh_assets_ipol_50pct 			"Top 50% asset share" 
label var tsh_assets_ipol_10pct 			"Top 10% asset share" 
label var tsh_assets_ipol_1pct 				"Top 1% asset share" 
label var tsh_assets_ipol_0_1pct 			"Top 0.1% asset share" 

label var tsh_receipts_ipol_50pct 			"Top 50% receipt share" 
label var tsh_receipts_ipol_10pct 			"Top 10% receipt share"  
label var tsh_receipts_ipol_1pct 			"Top 1% receipt share" 
label var tsh_receipts_ipol_0_1pct 			"Top 0.1% receipt share" 

label var tsh_ninc_ipol_50pct 				"Top 50% net income share" 
label var tsh_ninc_ipol_10pct 				"Top 10% net income share" 
label var tsh_ninc_ipol_1pct 				"Top 1% net income share" 
label var tsh_ninc_ipol_0_1pct 				"Top 0.1% net income share" 

sort      sector_main year

order 	sector_main year tsh_assets_ipol_0_1pct tsh_assets_ipol_1pct tsh_assets_ipol_10pct tsh_assets_ipol_50pct ///
		tsh_receipts_ipol_0_1pct tsh_receipts_ipol_1pct tsh_receipts_ipol_10pct tsh_receipts_ipol_50pct ///
		tsh_ninc_ipol_0_1pct tsh_ninc_ipol_1pct tsh_ninc_ipol_10pct tsh_ninc_ipol_50pct

save 	"$OUTPUT/soi/topshares/sector_concent_R5.dta", replace
restore

keep 	sector_main year tsh_receipts_ipol_500firms tsh_receipts_ipol_5000firms tsh_receipts_ipol_5000in1980all tsh_assets_ipol_500firms tsh_assets_ipol_5000firms 

merge 1:1 sector_main year using "`sector_type_concent_assets'", nogen

// Adjust to include estimated corp + noncorp in denominator 
merge 1:1 sector_main year using "$DATA/soi/digitized/noncorp_totals_R5.dta", nogen keep(1 3) keepusing(corpsh)

gen tsh_Areceipts_ipol_500firms 			= tsh_receipts_ipol_500firms * corpsh
gen tsh_Areceipts_ipol_5000firms 			= tsh_receipts_ipol_5000firms * corpsh
gen tsh_Aassets_ipol_500firms 				= tsh_assets_ipol_500firms * corpsh
gen tsh_Aassets_ipol_5000firms 				= tsh_assets_ipol_5000firms * corpsh
gen tsh_Aassets_ipol_5000firmscomb 			= tsh_assets_ipol_5000firmscomb * corpsh

label var sector_main 						"Main sector"
label var year 								"Year"

label var tsh_receipts_ipol_500firms 		"Top 500 corp receipt share among corps" 
label var tsh_Areceipts_ipol_500firms 		"Top 500 corp receipt share among corp and noncorp" 
label var tsh_receipts_ipol_5000firms 		"Top 5000 corp receipt share among corps" 
label var tsh_receipts_ipol_5000in1980all	"Top X% corp receipt share (X% based on share of 5000 in all in 1980)"
label var tsh_Areceipts_ipol_5000firms 		"Top 5000 corp receipt share among corp and noncorp" 
label var tsh_assets_ipol_500firms 			"Top 500 corp asset share among corps" 
label var tsh_assets_ipol_5000firms 		"Top 5000 corp asset share among corps" 
label var tsh_Aassets_ipol_500firms 		"Top 500 corp asset share among corp and noncorp" 
label var tsh_Aassets_ipol_5000firms 		"Top 5000 corp asset share among corp and noncorp"
label var tsh_Aassets_ipol_5000firmscomb 	"Top 5000 corp and partnership asset share among corp and noncorp"

keep 	sector_main year tsh_receipts_ipol_500firms tsh_receipts_ipol_5000firms tsh_receipts_ipol_5000in1980all tsh_Areceipts_ipol_500firms tsh_Areceipts_ipol_5000firms ///
		tsh_assets_ipol_500firms tsh_assets_ipol_5000firms tsh_Aassets_ipol_500firms tsh_Aassets_ipol_5000firms tsh_Aassets_ipol_5000firmscomb

order 	sector_main year tsh_receipts_ipol_500firms tsh_receipts_ipol_5000firms tsh_receipts_ipol_5000in1980all tsh_Areceipts_ipol_500firms tsh_Areceipts_ipol_5000firms ///
		tsh_assets_ipol_500firms tsh_assets_ipol_5000firms tsh_Aassets_ipol_500firms tsh_Aassets_ipol_5000firms tsh_Aassets_ipol_5000firmscomb  

sort      sector_main year

drop if year < 1945
drop if year > 2013

save "$OUTPUT/soi/topshares/sector_concent_topN_R5.dta", replace
capture erase "$OUTPUT/temp/tabulation-input.dta"
capture erase "$OUTPUT/temp/tabulation-output.dta"
capture erase "$OUTPUT/temp/tabulation-input_combined.dta"
capture erase "$OUTPUT/temp/tabulation-output_combined.dta"
capture erase "$OUTPUT/temp/tabulation-input_corp.dta"
capture erase "$OUTPUT/temp/tabulation-output_corp.dta"
capture erase "$OUTPUT/temp/tabulation-input_part.dta"
capture erase "$OUTPUT/temp/tabulation-output_part.dta"
capture erase "$OUTPUT/temp/tabulation-input_prop.dta"
capture erase "$OUTPUT/temp/tabulation-output_prop.dta"

