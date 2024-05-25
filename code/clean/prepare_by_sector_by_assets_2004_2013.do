/************ Function ************/

*This file cleans 2004 to 2013 Corporation Source Book data

/************ Source ************/

*"input/soi/source_book/`i'sbfltfile/20`i'sb1.csv" downloaded from https://www.irs.gov/statistics/soi-tax-stats-corporation-source-book-publication-1053

clear all

set matsize 11000
set more off, permanently

global DATA 	"../../input"
global OUTPUT 	"../../output"


*========== 2004-2013 (csv files from IRS website) ===============

clear
gen year = .
gen sector_final = ""
tempfile by_sector_and_assets_2004_2013
save "`by_sector_and_assets_2004_2013'"

local list 13 12 11 10 09 08 07 06 05 04 

foreach i of local list {

	import delimited "$DATA/soi/source_book/`i'sbfltfile/20`i'sb1.csv", clear 
	// Keep all 1, 2 and 3 digit NAICS
	keep if indy_cd<1000 | (indy_cd >= 211110 & indy_cd <=213110) ///
		 | (indy_cd >= 551111 & indy_cd <=551112) 				  ///
		 | (indy_cd >= 532100 & indy_cd <=532400) 				  ///
		 | (indy_cd >= 221100 & indy_cd <=221500) 				  ///
		 | (indy_cd >= 481000 & indy_cd <=483000)

	tostring indy_cd, gen(ID)
	cap drop if indy_cd == 900 // Other
	cap drop if indy_cd == 541 // Subsector name == sector name
	cap drop if indy_cd == 551 // Subsector name == sector name

	merge m:1 ID using "$OUTPUT/temp/sector_list_NAICS_3digit_uniqueID.dta", assert(2 3) gen(m3) keepusing(sector_final sector_level sector_ID sector_main_ID indcode)
	keep if m3 ==3  
	drop m3

	// Keep variables we need 
	keep 	year sector_final sector_level sector_ID sector_main_ID indcode	///
			ac wt_ct* tot_assts* comp_tot_rcpts grs_rcpts net_incm dprcbl_assts dptbl_assts land accum_dpr accum_dpltn intngbl_assts accum_amort
 
	ren 											wt_ct 				number
	ren 											tot_assts 			assets
	ren 											comp_tot_rcpts 		treceipts
	ren 											grs_rcpts 			breceipts
	ren 											net_incm 			ninc
	ren												intngbl_assts 		intangibles 
	ren 											accum_amort			negintangibles 

	egen double 									cassets = rowtotal(dprcbl_assts dptbl_assts land)
	egen double										negcassets = rowtotal(accum_dpr accum_dpltn)
	drop 											dprcbl_assts dptbl_assts land accum_dpr accum_dpltn

	// Combine indicator variables of bracket deletion
	ren 											wt_ct_ind 			ind_number
	ren 											tot_assts_ind 		ind_assets
	
	foreach v of varlist ind_assets ind_number {
		bysort year sector_ID ac: egen 				temp = max(`v')
		replace 									`v' = temp
		drop 										temp
	}

	// Define bracket deletion variable
	egen 											temp1 = rowmax(ind_number ind_assets)
	bysort year sector_ID ac: egen 					temp = max(temp1)
	gen 											bracket_deletion = "no" 				if temp != 3
	replace 										bracket_deletion = "yes" 				if temp == 3
	bysort year sector_ID: egen 					temp_total = max(temp)
	gen 											bracket_deletion_total = "no" 			if temp_total != 3
	replace 										bracket_deletion_total = "yes" 			if temp_total == 3
	drop 											temp temp1 temp_total ind_number ind_assets
	
	// Aggregate by sector 
	local vlist										number assets treceipts breceipts ninc cassets negcassets intangibles negintangibles 
	foreach v of local vlist {
		cap bysort year sector_ID ac: egen double	temp = sum(`v') 						if bracket_deletion == "no"
		cap bysort year sector_ID ac: replace 		temp = . 								if bracket_deletion == "yes"
		cap drop 									`v'
		cap gen double 								`v' = temp
		cap drop 									temp
	}
	duplicates drop 								year sector_ID ac, force

	// 2004-2013 tables all have the same brackets
	gen 	thres_low = ""
	replace thres_low = "Total"   		if ac == 1
	replace thres_low = "0" 	  		if ac == 2
	replace thres_low = "1" 	  		if ac == 3
	replace thres_low = "500000" 	  	if ac == 4
	replace thres_low = "1000000" 	  	if ac == 5
	replace thres_low = "5000000" 	  	if ac == 6
	replace thres_low = "10000000"   	if ac == 7
	replace thres_low = "25000000"   	if ac == 8
	replace thres_low = "50000000"   	if ac == 9
	replace thres_low = "100000000"  	if ac == 10
	replace thres_low = "250000000"  	if ac == 11
	replace thres_low = "500000000"  	if ac == 12
	replace thres_low = "2500000000" 	if ac == 13

	gen 	thres_high = ""
	replace thres_high = ""   	   		if ac == 1
	replace thres_high = "1" 	   		if ac == 2
	replace thres_high = "500000" 	   	if ac == 3
	replace thres_high = "1000000"    	if ac == 4
	replace thres_high = "5000000"    	if ac == 5
	replace thres_high = "10000000"   	if ac == 6
	replace thres_high = "25000000"   	if ac == 7
	replace thres_high = "50000000"   	if ac == 8
	replace thres_high = "100000000"  	if ac == 9
	replace thres_high = "250000000"  	if ac == 10
	replace thres_high = "500000000"  	if ac == 11
	replace thres_high = "2500000000" 	if ac == 12
	replace thres_high = "more" 		if ac == 13
	
	drop 	ac
	rename 	sector_level sec_level 
	rename 	sector_ID sec_ID 
	rename 	sector_main_ID sec_main_ID 
	rename 	indcode scode 

	append using `by_sector_and_assets_2004_2013'
	save `by_sector_and_assets_2004_2013', replace
}


ren 		sector_final sector 

gen 		source = "sb2004_2013"

save "$OUTPUT/temp/by_sector_and_assets_2004_2013.dta", replace
