/************ Function ************/

*This file prepares the digital files from the National Archives.

/************ Source ************/

*Downloaded from: https://catalog.archives.gov/search-within/646618?levelOfDescription=fileUnit&limit=20&sort=naId%3Aasc, saved in "input/soi/national_archive"
*1965-1970, 1976: EBCDIC -> ASCII (download + converted)
*1971, 1973, 1974, 1975: ASCII (directly download, delimited '|')
*1977, 1978, 1979, 1980, 1985-1990: ASCII(directly download)

/************ Notes ************/ 

*Bracket combinations show up in 1972 print issue for the first time 
*Deletions show up for the first time in 1974 (ind_ variables)
*In some years the national archive files have miniscule differences with the print publications
*From 1965 to 1974 the national archive files have only minor industries, and aggregates have to be added up 


clear all

set matsize 11000
set more off, permanently

global DATA 	"../../input"
global OUTPUT 	"../../output"



********************************************
*======== Prepare sector assignment 
********************************************
 
import excel "$DATA/soi/sector_file.xlsx", sheet("SIC_national_archive") cellrange(B3:Q325) firstrow clear
keep if keep == 1
tempfile 		SIC_vintages
save 			"`SIC_vintages'"


// File: unique combinations of minor_industry_1973_1997 major_group_1973_1997 division_code_1973_1997 and sector final
use 			`SIC_vintages', replace
keep if 		minor_industry_1973_1997 != ""
keep 			minor_industry_1973_1997 minor_industry_1973_1997_alt major_group_1973_1997 division_code_1973_1997 sector_final
duplicates drop minor_industry_1973_1997 minor_industry_1973_1997_alt major_group_1973_1997 division_code_1973_1997 sector_final, force
tempfile 		SIC_vintages_1973_1997_unique
save 			"`SIC_vintages_1973_1997_unique'"

// File: only minor industries (to calculate total)
keep if 		minor_industry_1973_1997_alt != "0000"
tempfile 		sector1973_1997
save 			"`sector1973_1997'"


// File: unique combinations of minor_industry_1968_1972 major_group_1968_1972 division_code_1968_1972 and sector final
use 			`SIC_vintages', replace
keep if 		minor_industry_1968_1972 != ""
keep 			minor_industry_1968_1972 major_group_1968_1972 division_code_1968_1972 sector_final
duplicates drop minor_industry_1968_1972 major_group_1968_1972 division_code_1968_1972 sector_final, force
tempfile 		SIC_vintages_1968_1972_unique
save 			"`SIC_vintages_1968_1972_unique'"


// File: only minor industries (to calculate total)
keep if 		minor_industry_1968_1972 != "0000"
tempfile 		sector1968_1972
save 			"`sector1968_1972'"


// File: unique combinations of minor_industry_1963_1967 major_group_1963_1967 division_code_1963_1967 and sector final
use 			`SIC_vintages', replace
keep if 		minor_industry_1963_1967 != ""
keep 			minor_industry_1963_1967 major_group_1963_1967 division_code_1963_1967 sector_final
duplicates drop minor_industry_1963_1967 major_group_1963_1967 division_code_1963_1967 sector_final, force
tempfile 		SIC_vintages_1963_1967_unique
save 			"`SIC_vintages_1963_1967_unique'"


// File: only minor industries (to calculate total)
keep if 		minor_industry_1963_1967 != "0000"
tempfile 		sector1963_1967
save 			"`sector1963_1967'"


********************************************
*======== Convert EBCDIC files 
********************************************
 
python script prepare_national_archive_convert_EBCDIC.py


********************************************
*======== Batch 1: 1965-1967
********************************************

clear
gen 			year = ""
tempfile 		source_book_NA
save 			"`source_book_NA'"


/* 1965 data */

import delimited "$OUTPUT/soi/national_archive_converted/RG058.CORP.Y65_ASCII.txt", delimiter("", collapse) clear stringcols(_all)

replace v1 = subinstr(v1, "{", "0",.) 
replace v1 = subinstr(v1, "A", "1",.) 
replace v1 = subinstr(v1, "B", "2",.) 
replace v1 = subinstr(v1, "C", "3",.) 
replace v1 = subinstr(v1, "D", "4",.)
replace v1 = subinstr(v1, "E", "5",.) 
replace v1 = subinstr(v1, "F", "6",.) 
replace v1 = subinstr(v1, "G", "7",.) 
replace v1 = subinstr(v1, "H", "8",.) 
replace v1 = subinstr(v1, "I", "9",.) 

gen year = "1965"
gen minor_industry_1963_1967 = substr(v1, 1, 4)
gen asset_size 		= substr(v1, 5, 2)
gen file_type 		= substr(v1, 7, 1)
gen number 			= substr(v1,21,10)
gen assets 			= substr(v1,65,10)

gen cassets_1 		= substr(v1,164,10)
gen cassets_2 		= substr(v1,186,10)
gen cassets_3 		= substr(v1,208,10)
gen intangibles 	= substr(v1,219,10)
gen negcassets_1 	= substr(v1,175,10)
gen negcassets_2 	= substr(v1,197,10)
gen negintangibles 	= substr(v1,230,10)

gen treceipts 		= substr(v1,395,10)
gen breceipts 		= substr(v1,406,10)
gen inc 			= substr(v1,758,10)
gen def 			= substr(v1,769,10)
drop v1

// Add up variables with subcategories
local vars cassets negcassets  
foreach v of local vars {
	destring `v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring `v', replace
	drop `v'_*
}

gen 	thres_low = ""
replace thres_low = "0" 		if asset_size == "00"
replace thres_low = "1" 		if asset_size == "01"
replace thres_low = "50000" 	if asset_size == "02"
replace thres_low = "100000" 	if asset_size == "03"
replace thres_low = "250000" 	if asset_size == "04"
replace thres_low = "500000" 	if asset_size == "05"
replace thres_low = "1000000" 	if asset_size == "06"
replace thres_low = "5000000" 	if asset_size == "07"
replace thres_low = "10000000" 	if asset_size == "08"
replace thres_low = "25000000" 	if asset_size == "09"
replace thres_low = "50000000" 	if asset_size == "10"
replace thres_low = "100000000" if asset_size == "11"
replace thres_low = "250000000" if asset_size == "12"


// Round number of returns
destring 		number, replace
replace  		number = number / 100
replace  		number = round(number)

local varlist 	number assets treceipts breceipts cassets negcassets intangibles negintangibles inc def 

// Add up with and without income
foreach v of local varlist {
	destring 											`v', replace
	bysort year minor_industry thres_low: egen double 	temp = sum(`v')
	replace 											`v' = temp
	drop 												temp
}
duplicates drop 										year minor_industry thres_low, force

* Calculate net income
gen double 		ninc = inc - def

drop 			file_type asset_size 
append 			using `source_book_NA'
save 			`source_book_NA', replace



/* 1966 data */

import delimited "$OUTPUT/soi/national_archive_converted/RG058.CORP.Y66_ASCII.txt", delimiter("", collapse) clear stringcols(_all)

replace v1 = subinstr(v1, "{", "0",.) 
replace v1 = subinstr(v1, "A", "1",.) 
replace v1 = subinstr(v1, "B", "2",.) 
replace v1 = subinstr(v1, "C", "3",.) 
replace v1 = subinstr(v1, "D", "4",.)
replace v1 = subinstr(v1, "E", "5",.) 
replace v1 = subinstr(v1, "F", "6",.) 
replace v1 = subinstr(v1, "G", "7",.) 
replace v1 = subinstr(v1, "H", "8",.) 
replace v1 = subinstr(v1, "I", "9",.) 

gen year 							= "1966"
gen minor_industry_1963_1967 		= substr(v1, 1, 4)
drop if minor_industry_1963_1967 	== "6055" // This is life insurance total; life insurance "subcategories" are also given

gen asset_size 		= substr(v1, 11, 3)
gen file_type 		= substr(v1, 14, 1)
gen number 			= substr(v1,21,10)
gen assets 			= substr(v1,65,10)
gen ind_assets 		= substr(v1,75,1)

gen cassets_1 		= substr(v1,197,10)
gen cassets_2 		= substr(v1,219,10)
gen cassets_3 		= substr(v1,241,10)
gen intangibles 	= substr(v1,252,10)
gen negcassets_1 	= substr(v1,208,10)
gen negcassets_2 	= substr(v1,230,10)
gen negintangibles 	= substr(v1,263,10)

gen treceipts 		= substr(v1,428,10)
gen breceipts 		= substr(v1,439,10)
gen inc 			= substr(v1,791,10)
gen def 			= substr(v1,802,10)
drop v1

// Add up variables with subcategories
local vars cassets negcassets  
foreach v of local vars {
	destring 		`v'_*, replace
	egen double 	`v' = rowtotal(`v'_*)
	tostring 		`v', replace
	drop 			`v'_*
}

gen 	thres_low = ""
replace thres_low = "0" 			if asset_size == "000"
replace thres_low = "1" 			if asset_size == "010" | asset_size == "011"
replace thres_low = "50000" 		if asset_size == "020"
replace thres_low = "100000" 		if asset_size == "030"
replace thres_low = "250000" 		if asset_size == "040"
replace thres_low = "500000" 		if asset_size == "050"
replace thres_low = "1000000" 		if asset_size == "060"
replace thres_low = "5000000" 		if asset_size == "070"
replace thres_low = "10000000" 		if asset_size == "080"
replace thres_low = "15000000" 		if asset_size == "081"
replace thres_low = "20000000" 		if asset_size == "082"
replace thres_low = "25000000" 		if asset_size == "090"
replace thres_low = "50000000" 		if asset_size == "100"
replace thres_low = "100000000" 	if asset_size == "110"
replace thres_low = "250000000" 	if asset_size == "120"
replace thres_low = "1000000000" 	if asset_size == "121"


// Round number of returns
destring 		number, replace
replace 		number = number / 100
replace 		number = round(number)

// Round up cases where assets are >0, but rounded down in the Source Book
destring 		assets, replace
replace 		assets = ceil(0.001*number + 0.001) if ind_assets == "1" & assets == 0
drop 			ind_assets


local varlist	number assets treceipts breceipts cassets negcassets intangibles negintangibles inc def 

// Add up with and without income
foreach v of local varlist {
	destring 											`v', replace
	bysort year minor_industry thres_low: egen double 	temp = sum(`v')
	replace 											`v' = temp
	drop 												temp
}
duplicates drop 										year minor_industry thres_low, force


// Calculate net income
gen double 		ninc = inc - def

drop 			file_type asset_size
append 			using `source_book_NA'
save 			`source_book_NA', replace




/* 1967 data */

import delimited "$OUTPUT/soi/national_archive_converted/RG058.CORP.Y67_ASCII.txt", delimiter("", collapse) clear stringcols(_all)

replace v1 	= subinstr(v1, "{", "0",.) 
replace v1 	= subinstr(v1, "A", "1",.) 
replace v1 	= subinstr(v1, "B", "2",.) 
replace v1 	= subinstr(v1, "C", "3",.) 
replace v1 	= subinstr(v1, "D", "4",.)
replace v1 	= subinstr(v1, "E", "5",.) 
replace v1 	= subinstr(v1, "F", "6",.) 
replace v1 	= subinstr(v1, "G", "7",.) 
replace v1 	= subinstr(v1, "H", "8",.) 
replace v1 	= subinstr(v1, "I", "9",.) 

gen year 						= "1967"
gen minor_industry_1963_1967	= substr(v1, 1, 4)

gen asset_size 			= substr(v1, 11, 3)
gen file_type 			= substr(v1, 14, 1)
gen number 				= substr(v1,21,10)
gen assets 				= substr(v1,65,10)
gen ind_assets 			= substr(v1,75,1)

gen cassets_1 			= substr(v1,186,10)
gen cassets_2 			= substr(v1,208,10)
gen cassets_3 			= substr(v1,230,10)
gen intangibles 		= substr(v1,241,10)
gen negcassets_1 		= substr(v1,197,10)
gen negcassets_2 		= substr(v1,219,10)
gen negintangibles 		= substr(v1,252,10)

gen treceipts 			= substr(v1,406,10)
gen breceipts 			= substr(v1,417,10)
gen inc 				= substr(v1,769,10)
gen def 				= substr(v1,780,10)
drop v1

// Add up variables with subcategories
local vars cassets negcassets  
foreach v of local vars {
	destring 			`v'_*, replace
	egen double 		`v' = rowtotal(`v'_*)
	tostring 			`v', replace
	drop 				`v'_*
}


gen 	thres_low = ""
replace thres_low = "0" 			if asset_size == "000"
replace thres_low = "1" 			if asset_size == "010"
replace thres_low = "10000" 		if asset_size == "011"
replace thres_low = "25000" 		if asset_size == "012"
replace thres_low = "50000" 		if asset_size == "020"
replace thres_low = "100000" 		if asset_size == "030"
replace thres_low = "250000" 		if asset_size == "040"
replace thres_low = "500000" 		if asset_size == "050"
replace thres_low = "1000000" 		if asset_size == "060"
replace thres_low = "2500000" 		if asset_size == "061"
replace thres_low = "5000000" 		if asset_size == "070"
replace thres_low = "10000000" 		if asset_size == "080"
replace thres_low = "25000000" 		if asset_size == "090"
replace thres_low = "35000000" 		if asset_size == "091"
replace thres_low = "50000000"		if asset_size == "100"
replace thres_low = "100000000" 	if asset_size == "110"
replace thres_low = "250000000" 	if asset_size == "120"
replace thres_low = "1000000000" 	if asset_size == "121"


// Round number of returns
destring 		number, replace
replace 		number = number / 1000
replace 		number = round(number)


// Round up cases where assets are >0, but rounded down in the Source Book
destring 		assets, replace
replace 		assets = ceil(0.001*number +0.001) if ind_assets =="1" & assets ==0
drop 			ind_assets


local varlist 	number assets treceipts breceipts cassets negcassets intangibles negintangibles inc def 

// Add up with and without income	
foreach v of local varlist {
	destring 											`v', replace
	bysort year minor_industry thres_low: egen double 	temp = sum(`v')
	replace 											`v' = temp
	drop 												temp
}
duplicates drop year minor_industry thres_low, force

// Calculate net income (variable seems wrong)
gen double 		ninc = inc - def

drop 			file_type asset_size
append 			using `source_book_NA'
save 			`source_book_NA', replace



**************************************************
************** Standardize 1965-1967 *************
**************************************************

local varlist 	number assets treceipts breceipts cassets negcassets intangibles negintangibles ninc

// Create file with major group and minor industry for each division
use 			`SIC_vintages', replace
drop if 		division_code_1963_1967 ==""
collapse (first) major_group_1963_1967 minor_industry_1963_1967, by(division_code_1963_1967)
tempfile 		division
save 			"`division'"

// Create file with minor industry and division for each major group
use 			`SIC_vintages', replace
drop if 		major_group_1963_1967 ==""
collapse (first) minor_industry_1963_1967 division_code_1963_1967, by(major_group_1963_1967)
tempfile 		group
save 			"`group'"



// Load data
use 			`source_book_NA', replace

// Calculate bracket sum for all variables.
preserve
collapse (sum) `varlist', by(minor_industry year)
gen 			thres_low ="Total"
tempfile 		source_book_NA_total
save 			"`source_book_NA_total'"
restore
append using 	`source_book_NA_total'


// Add information on division and major group for each minor industry
merge m:1 minor_industry_1963_1967 using `sector1963_1967', assert(2 3) gen(m1) keep(3) keepusing(major_group_1963_1967 division_code_1963_1967)
drop m1

// File only includes minor industries. Major group, divison and aggregate calculated by adding up minor industries.

// Sum minor industries to obtain aggregate
preserve
collapse (sum) `varlist', by(thres_low year)
gen 			division_code_1963_1967 	= "00"
gen 			major_group_1963_1967 		= "00"
gen 			minor_industry_1963_1967 	= "0000"
tempfile 		source_book_NA_all
save 			"`source_book_NA_all'", replace
restore

// Sum minor industries to obtain industrial divisions
// Only need to be computed when division != minor_industry
preserve
bysort division_code_1963_1967 thres_low year: gen 	temp = _n
bysort division_code_1963_1967 year: egen 			n = max(temp)
keep 		if n >1  
collapse (sum) `varlist', by(division_code_1963_1967 thres_low year)
merge m:1 division_code_1963_1967 using `division', keep(3) nogen
tempfile 	source_book_NA_div
save 		"`source_book_NA_div'", replace
restore

preserve
keep 		if division_code_1963_1967 == "61" | division_code_1963_1967 == "62" | division_code_1963_1967 == "63"
collapse (last) minor_industry_1963_1967 major_group_1963_1967 division_code_1963_1967 (sum) `varlist', by(thres_low year)
replace 	division_code_1963_1967 	= "60"
replace 	major_group_1963_1967 		= "00"
replace 	minor_industry_1963_1967 	= "0000"
tempfile 	source_book_NA_divtrade
save 		"`source_book_NA_divtrade'"
restore

// Sum minor industries to obtain major groups
// Total only needs to be computed when major group != minor_industry
preserve
bysort major_group_1963_1967 thres_low year: gen 	temp = _n
bysort major_group_1963_1967 year: egen 			n = max(temp)
keep 		if n >1 
drop 		if major_group_1963_1967 == "06" | major_group_1963_1967 == "01" | major_group_1963_1967 == "45" | major_group_1963_1967 == "60" // Drop Construction and Agriculture, both an industry and a major group
collapse  (sum) `varlist', by(major_group_1963_1967 thres_low year)
merge m:1 	major_group_1963_1967 using `group', keep(3) nogen
tempfile 	source_book_NA_group
save 		"`source_book_NA_group'", replace
restore

append using `source_book_NA_div'
append using `source_book_NA_divtrade'
append using `source_book_NA_group'
append using `source_book_NA_all'

merge m:1  	minor_industry_1963_1967 major_group_1963_1967 division_code_1963_1967 using `SIC_vintages_1963_1967_unique', nogen keep(3) keepusing(sector_final)

destring 	`varlist', replace 

tempfile 	source_book_NA_batch1
save 		"`source_book_NA_batch1'"









********************************************
**#======== Batch 2: 1968-1971
********************************************

clear
gen year =""
save `source_book_NA', replace


/* 1968 data */

import delimited "$OUTPUT/soi/national_archive_converted/RG058.CORP.Y68_ASCII.txt", delimiter("", collapse) clear stringcols(_all)

replace v1 = subinstr(v1, "{", "0",.) 
replace v1 = subinstr(v1, "A", "1",.) 
replace v1 = subinstr(v1, "B", "2",.) 
replace v1 = subinstr(v1, "C", "3",.) 
replace v1 = subinstr(v1, "D", "4",.)
replace v1 = subinstr(v1, "E", "5",.) 
replace v1 = subinstr(v1, "F", "6",.) 
replace v1 = subinstr(v1, "G", "7",.) 
replace v1 = subinstr(v1, "H", "8",.) 
replace v1 = subinstr(v1, "I", "9",.) 

gen year 						= "1968"
gen minor_industry_1968_1972 	= substr(v1, 1, 4)
gen asset_size 					= substr(v1, 11, 3)
gen file_type 					= substr(v1, 14, 1)
gen number 						= substr(v1,21,10)
gen assets 						= substr(v1,65,10)

gen cassets_1 					= substr(v1,186,10)
gen cassets_2 					= substr(v1,208,10)
gen cassets_3 					= substr(v1,230,10)
gen intangibles 				= substr(v1,241,10)
gen negcassets_1 				= substr(v1,197,10)
gen negcassets_2 				= substr(v1,219,10)
gen negintangibles 				= substr(v1,252,10)

gen treceipts 					= substr(v1,406,10)
gen breceipts 					= substr(v1,417,10)
gen inc 						= substr(v1,769,10)
gen def 						= substr(v1,780,10)
drop v1

// Add up variables with subcategories
local vars cassets negcassets  
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace
	drop 		`v'_*
}


gen 	thres_low = ""
replace thres_low = "0" 			if asset_size == "000"
replace thres_low = "1" 			if asset_size == "010"
replace thres_low = "10000" 		if asset_size == "011"
replace thres_low = "25000" 		if asset_size == "012"
replace thres_low = "50000" 		if asset_size == "020"
replace thres_low = "100000" 		if asset_size == "030"
replace thres_low = "250000" 		if asset_size == "040"
replace thres_low = "500000" 		if asset_size == "050"
replace thres_low = "1000000" 		if asset_size == "060"
replace thres_low = "2500000" 		if asset_size == "061"
replace thres_low = "5000000" 		if asset_size == "070"
replace thres_low = "10000000" 		if asset_size == "080"
replace thres_low = "25000000" 		if asset_size == "090"
replace thres_low = "35000000" 		if asset_size == "091"
replace thres_low = "50000000" 		if asset_size == "100"
replace thres_low = "100000000" 	if asset_size == "110"
replace thres_low = "250000000" 	if asset_size == "120"
replace thres_low = "1000000000" 	if asset_size == "121"


// Round number of returns
destring 		number, replace
replace 		number = number / 100
replace 		number = round(number, 1)

local varlist 	number assets treceipts breceipts cassets negcassets intangibles negintangibles inc def 

// Add up with and without income
foreach v of local varlist {
	destring 											`v', replace
	bysort year minor_industry thres_low: egen double 	temp = sum(`v')
	replace 											`v' = temp
	drop 												temp
}

duplicates drop 										year minor_industry thres_low, force

// Calculate net income
gen double 		ninc = inc - def

drop 			file_type asset_size
append 			using `source_book_NA'
save 			`source_book_NA', replace




/* 1969 data */

import delimited "$OUTPUT/soi/national_archive_converted/RG058.CORP.Y69_ASCII.txt", delimiter("", collapse) clear stringcols(_all)

replace v1 = subinstr(v1, "{", "0",.) 
replace v1 = subinstr(v1, "A", "1",.) 
replace v1 = subinstr(v1, "B", "2",.) 
replace v1 = subinstr(v1, "C", "3",.) 
replace v1 = subinstr(v1, "D", "4",.)
replace v1 = subinstr(v1, "E", "5",.) 
replace v1 = subinstr(v1, "F", "6",.) 
replace v1 = subinstr(v1, "G", "7",.) 
replace v1 = subinstr(v1, "H", "8",.) 
replace v1 = subinstr(v1, "I", "9",.) 

gen year = "1969"
gen minor_industry_1968_1972 	= substr(v1, 1, 4)
gen asset_size 					= substr(v1, 11, 3)
gen file_type 					= substr(v1, 14, 1)

gen number 						= substr(v1,21,10)
gen assets 						= substr(v1,65,10)

gen cassets_1 					= substr(v1,186,10)
gen cassets_2 					= substr(v1,208,10)
gen cassets_3 					= substr(v1,230,10)
gen intangibles 				= substr(v1,241,10)
gen negcassets_1 				= substr(v1,197,10)
gen negcassets_2 				= substr(v1,219,10)
gen negintangibles 				= substr(v1,252,10)

gen treceipts 					= substr(v1,406,10)
gen breceipts 					= substr(v1,417,10)
gen inc 						= substr(v1,769,10)
gen def 						= substr(v1,780,10)

drop v1

// Add up variables with subcategories
local vars cassets negcassets  
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace
	drop 		`v'_*
}

gen 	thres_low = ""
replace thres_low = "0" 			if asset_size == "000"
replace thres_low = "1" 			if asset_size == "010"
replace thres_low = "10000" 		if asset_size == "011"
replace thres_low = "25000" 		if asset_size == "012"
replace thres_low = "50000" 		if asset_size == "020"
replace thres_low = "100000" 		if asset_size == "030"
replace thres_low = "250000" 		if asset_size == "040"
replace thres_low = "500000" 		if asset_size == "050"
replace thres_low = "1000000" 		if asset_size == "060"
replace thres_low = "2500000" 		if asset_size == "061"
replace thres_low = "5000000" 		if asset_size == "070"
replace thres_low = "10000000" 		if asset_size == "080"
replace thres_low = "25000000" 		if asset_size == "090"
replace thres_low = "35000000" 		if asset_size == "091"
replace thres_low = "50000000" 		if asset_size == "100"
replace thres_low = "100000000" 	if asset_size == "110"
replace thres_low = "250000000" 	if asset_size == "120"
replace thres_low = "1000000000" 	if asset_size == "121"


// Round number of returns
destring 		number, replace
replace 		number = number / 100
replace 		number = round(number,1)

local varlist 	number assets treceipts breceipts cassets negcassets intangibles negintangibles inc def 

// Add up with and without income
foreach v of local varlist {
	destring 									`v', replace
	bysort year minor_industry thres_low: egen 	double temp = sum(`v')
	replace 									`v' = temp
	drop 										temp
}
duplicates drop 								year minor_industry thres_low, force

// Calculate net income
gen double 		ninc = inc - def

drop 			file_type asset_size
append 			using `source_book_NA'
save 			`source_book_NA', replace




/* 1970 data */

import delimited "$OUTPUT/soi/national_archive_converted/RG058.CORP.Y70_ASCII.txt", delimiter("", collapse) clear stringcols(_all)

replace v1 = subinstr(v1, "{", "0",.) 
replace v1 = subinstr(v1, "A", "1",.) 
replace v1 = subinstr(v1, "B", "2",.) 
replace v1 = subinstr(v1, "C", "3",.) 
replace v1 = subinstr(v1, "D", "4",.)
replace v1 = subinstr(v1, "E", "5",.) 
replace v1 = subinstr(v1, "F", "6",.) 
replace v1 = subinstr(v1, "G", "7",.) 
replace v1 = subinstr(v1, "H", "8",.) 
replace v1 = subinstr(v1, "I", "9",.) 

gen year = "1970"
gen minor_industry_1968_1972 	= substr(v1, 1, 4)
gen asset_size 					= substr(v1, 11, 3)
gen file_type 					= substr(v1, 14, 1)

gen number 						= substr(v1,20,11)
gen assets 						= substr(v1,65,10)

gen cassets_1 					= substr(v1,186,10)
gen cassets_2 					= substr(v1,208,10)
gen cassets_3 					= substr(v1,230,10)
gen intangibles 				= substr(v1,241,10)
gen negcassets_1 				= substr(v1,197,10)
gen negcassets_2 				= substr(v1,219,10)
gen negintangibles 				= substr(v1,252,10)

gen treceipts 					= substr(v1,406,10)
gen breceipts 					= substr(v1,417,10)
gen ninc 						= substr(v1,758,10)

drop v1

local vars ninc  

foreach v of local vars {
	replace `v' = "-" + `v'  if	!inrange(real(substr(`v', -1, 1)), 0, 9)
	replace `v' = subinstr(`v', "}", "0",.) 
	replace `v' = subinstr(`v', "J", "1",.) 
	replace `v' = subinstr(`v', "K", "2",.) 
	replace `v' = subinstr(`v', "L", "3",.) 
	replace `v' = subinstr(`v', "M", "4",.)
	replace `v' = subinstr(`v', "N", "5",.) 
	replace `v' = subinstr(`v', "O", "6",.) 
	replace `v' = subinstr(`v', "P", "7",.) 
	replace `v' = subinstr(`v', "Q", "8",.) 
	replace `v' = subinstr(`v', "R", "9",.) 
}

// Add up variables with subcategories
local vars cassets negcassets  
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace
	drop 		`v'_*
}


gen thres_low = ""
replace thres_low = "0" 			if asset_size == "000"
replace thres_low = "1" 			if asset_size == "010"
replace thres_low = "10000" 		if asset_size == "011"
replace thres_low = "25000" 		if asset_size == "012"
replace thres_low = "50000" 		if asset_size == "020"
replace thres_low = "100000" 		if asset_size == "030"
replace thres_low = "250000"		if asset_size == "040"
replace thres_low = "500000" 		if asset_size == "050"
replace thres_low = "1000000" 		if asset_size == "060"
replace thres_low = "2500000" 		if asset_size == "061"
replace thres_low = "5000000" 		if asset_size == "070"
replace thres_low = "10000000" 		if asset_size == "080"
replace thres_low = "25000000" 		if asset_size == "090"
replace thres_low = "35000000" 		if asset_size == "091"
replace thres_low = "50000000" 		if asset_size == "100"
replace thres_low = "100000000" 	if asset_size == "110"
replace thres_low = "250000000" 	if asset_size == "120"
replace thres_low = "1000000000" 	if asset_size == "121"


// Round number of returns
destring 		number, replace
replace 		number = number / 100
replace 		number = round(number,1)

local varlist	number assets treceipts breceipts cassets negcassets intangibles negintangibles ninc

// Add up with and without income	
foreach v of local varlist {
	destring 									`v', replace
	bysort year minor_industry thres_low: egen 	double temp = sum(`v')
	replace							 			`v' = temp
	drop 										temp
}
duplicates drop 								year minor_industry thres_low, force

drop 			file_type asset_size
append 			using `source_book_NA'
save 			`source_book_NA', replace






**************************************************
************** Standardize 1968-1972 *************
**************************************************

local varlist 	number assets treceipts breceipts cassets negcassets intangibles negintangibles ninc 

// Create file with major group and minor industry for each division
use 			`SIC_vintages', replace
drop 			if division_code_1968_1972 ==""
collapse (first) major_group_1968_1972 minor_industry_1968_1972 ,by(division_code_1968_1972)
tempfile 		division
save 			"`division'", replace

// Create file with minor industry and division for each major group
use 			`SIC_vintages', replace
drop 			if major_group_1968_1972 ==""
collapse (first) minor_industry_1968_1972 division_code_1968_1972 ,by(major_group_1968_1972)
tempfile 		group
save 			"`group'"


// Load data
use 			`source_book_NA', replace


// Calculate bracket sum for all variables
preserve
collapse (sum) `varlist', by(minor_industry year)
gen 			thres_low ="Total"
tempfile 		source_book_NA_total
save 			"`source_book_NA_total'"
restore
append using 	`source_book_NA_total'

// Add information on division and major group for each minor industry
merge m:1 minor_industry_1968_1972 using `sector1968_1972', assert(2 3) gen(m1) keep(3) keepusing(major_group_1968_1972 division_code_1968_1972)
drop m1


// File only includes minor industries. Major group, divison and aggregate calculated by adding up minor industries.

// Sum minor industries to obtain aggregate 
preserve
collapse (sum) `varlist', by(thres_low year)
gen 			division_code_1968_1972 	= "00"
gen 			major_group_1968_1972 		= "00"
gen 			minor_industry_1968_1972 	= "0000"
tempfile 		source_book_NA_all
save 			"`source_book_NA_all'", replace
restore


// Sum minor industries to obtain major groups.
// Total only needs to be computed when division != minor_industry
preserve
bysort division_code_1968_1972 thres_low year: gen 	temp = _n
bysort division_code_1968_1972 year: egen 			n = max(temp)
keep 		if n >1  
collapse (sum) `varlist', by(division_code_1968_1972 thres_low year)
merge m:1 division_code_1968_1972 using `division', keep(3) nogen
tempfile 	source_book_NA_div
save 		"`source_book_NA_div'", replace
restore

preserve
keep 		if division_code_1968_1972 == "61" | division_code_1968_1972 == "62" | division_code_1968_1972 == "63"
collapse (last) minor_industry_1968_1972 major_group_1968_1972 division_code_1968_1972 (sum) `varlist', by(thres_low year)
replace 	division_code_1968_1972 	= "60"
replace 	major_group_1968_1972 		= "00"
replace 	minor_industry_1968_1972 	= "0000"
tempfile 	source_book_NA_divtrade
save 		"`source_book_NA_divtrade'", replace
restore

// Sum minor industries to obtain major groups.
// Total only needs to be computed when major group != minor_industry
preserve
bysort major_group_1968_1972 thres_low year: gen 	temp = _n
bysort major_group_1968_1972 year: egen 			n = max(temp)
keep 		if n >1 
drop 		if major_group_1968_1972 == "06" | major_group_1968_1972 == "01" | major_group_1968_1972 == "42" | major_group_1968_1972 == "56" // Drop Construction and Agriculture, both an industry and a major group

collapse  (sum) `varlist', by(major_group_1968_1972 thres_low year)
merge m:1 major_group_1968_1972 using `group', keep(3) nogen
tempfile 	source_book_NA_group
save 		"`source_book_NA_group'", replace
restore

append using `source_book_NA_div'
append using `source_book_NA_divtrade'
append using `source_book_NA_group'
append using `source_book_NA_all'

tempfile source_book_NA_batch2
save "`source_book_NA_batch2'", replace



/* 1971 data */

import delimited "$DATA/soi/national_archive/RG058.CORP.Y71.txt", delimiter("|") clear stringcols(_all)

gen year = "1971"
gen division_code_1968_1972 	= industrydivisioncode  
gen major_group_1968_1972 		= majorgroupcode 
gen minor_industry_1968_1972 	= minorindustry
gen asset_size 					= totalassetsize
gen file_type 					= netincomedeficit

replace minor_industry_1968_1972 ="6055" if minor_industry_1968_1972 =="6051" // Note from the document for 1972


gen number 			= numberofreturnstotal
gen assets 			= totalassets2

gen cassets_1 		= depreciableassets
gen cassets_2 		= depletableassets
gen cassets_3 		= land
gen intangibles 	= intangibleassets
gen negcassets_1 	= accumulateddepreciation
gen negcassets_2 	= accumulateddepletion
gen negintangibles 	= accumulatedamortization

gen treceipts 		= totalreceipts
gen breceipts 		= businessreceipts
gen ninc 			= netincomelessdeficit

// Add up variables with subcategories
local vars cassets negcassets 
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace
	drop 		`v'_*
}


gen 	thres_low = ""
replace thres_low = "0" 			if asset_size == "010"
replace thres_low = "1" 			if asset_size == "020"
replace thres_low = "100000" 		if asset_size == "030"
replace thres_low = "250000" 		if asset_size == "040"
replace thres_low = "500000" 		if asset_size == "050"
replace thres_low = "1000000" 		if asset_size == "060"
replace thres_low = "5000000" 		if asset_size == "070"
replace thres_low = "10000000" 		if asset_size == "080"
replace thres_low = "25000000" 		if asset_size == "090"
replace thres_low = "50000000"		if asset_size == "100"
replace thres_low = "100000000" 	if asset_size == "110"
replace thres_low = "250000000" 	if asset_size == "120"

// Round number of returns
destring 		number, replace
replace 		number = number / 100
replace 		number = round(number,1)

// 1971 separates with and without net income. Need to be added up
local varlist 	number assets treceipts breceipts cassets negcassets intangibles negintangibles ninc

// Add up with and without income	
foreach v of local varlist {
	destring 																	`v', replace
	bysort year division_code major_group minor_industry thres_low: egen double	temp = sum(`v')
	replace 																	`v' = temp
	drop 																		temp
}
duplicates drop 																year minor_industry major_group division_code thres_low, force 

keep 																			year division_code major_group minor_industry thres_low `varlist'

// Files do not include a total. Needs to be calculated
local varlist 	number assets treceipts breceipts cassets negcassets intangibles negintangibles ninc 

destring 		`varlist', replace

// Calculate bracket sum for all variables
preserve
collapse (sum) `varlist', by(minor_industry division_code major_group  year)
gen 			thres_low ="Total"
tempfile 		source_book_NA_total
save 			"`source_book_NA_total'", replace
restore
append using 	`source_book_NA_total'


append using 	`source_book_NA_batch2'
save 			`source_book_NA_batch2', replace

merge m:1 minor_industry_1968_1972 major_group_1968_1972 division_code_1968_1972 using `SIC_vintages_1968_1972_unique', gen(m1) keep(3) keepusing(sector_final)

destring 		`varlist', replace 
save 			`source_book_NA_batch2', replace







********************************************
**#  Batch 3: 1973-1997
********************************************

local varlist number assets treceipts breceipts cassets negcassets intangibles negintangibles ninc 

clear
gen		year = ""
save 	`source_book_NA', replace


// Create file with minor industry and division for each major group
use 	`SIC_vintages', replace
drop 	if major_group_1973_1997 == ""
collapse (first) division_code_1973_1997 ,by(major_group_1973_1997)
tempfile group
save 	"`group'"

// Create file with major group and division for each minor industry
use 	`SIC_vintages', replace
drop 	if minor_industry_1973_1997 == ""
collapse (first) major_group_1973_1997 division_code_1973_1997 ,by(minor_industry_1973_1997)
tempfile industry
save 	"`industry'"




/* 1973 data */

import delimited "$DATA/soi/national_archive/RG058.CORP.Y73.txt", delimiter("|") clear stringcols(_all)


gen year 			= "1973"
gen division_code 	= industrydivisioncode  
gen major_group 	= majorgroupcode
gen minor_industry 	= minorindustry
gen asset_size 		= totalassetsize
gen file_type 		= netincomedeficit
gen number 			= numberofreturnstotal
gen assets 			= totalassets2

gen cassets_1 		= depreciableassets 
gen cassets_2 		= depletableassets
gen cassets_3 		= land
gen intangibles 	= intangibleassets
gen negcassets_1 	= accumulateddepreciation
gen negcassets_2 	= accumulateddepletion
gen negintangibles 	= accumulatedamortization

gen treceipts 		= totalreceipts
gen breceipts 		= businessreceipts
gen ninc 			= netincomelessdeficit

// Add up variables with subcategories
local vars cassets negcassets 
foreach v of local vars {
	destring 		`v'_*, replace
	egen double 	`v' = rowtotal(`v'_*)
	tostring 		`v', replace
	drop 			`v'_*
}


// Keep "All Returns", Drop "Returns with net income"
keep if file_type == "1"
drop file_type

gen 	thres_low = ""
replace thres_low = "Total" 		if asset_size == "000"
replace thres_low = "0" 			if asset_size == "001"
replace thres_low = "1" 			if asset_size == "020"
replace thres_low = "100000" 		if asset_size == "030"
replace thres_low = "250000" 		if asset_size == "040"
replace thres_low = "500000" 		if asset_size == "050"
replace thres_low = "1000000" 		if asset_size == "060"
replace thres_low = "5000000" 		if asset_size == "070"
replace thres_low = "10000000" 		if asset_size == "080"
replace thres_low = "25000000" 		if asset_size == "090"
replace thres_low = "50000000" 		if asset_size == "100"
replace thres_low = "100000000" 	if asset_size == "110"
replace thres_low = "250000000" 	if asset_size == "120"

keep year division_code major_group minor_industry thres_low `varlist'
append using 	`source_book_NA'
save 			`source_book_NA', replace




/* 1974 data */

import delimited "$DATA/soi/national_archive/RG058.CORP.Y74.txt", delimiter("|") clear stringcols(_all)

gen year 			= "1974"
gen division_code 	= industrydivisioncode  
gen major_group 	= majorgroupcode 
gen minor_industry 	= minorindustry
gen asset_size 		= totalassetsize
gen file_type 		= netincomedeficit
gen number 			= numberofreturnstotal
gen assets		 	= totalassets2
gen ind_number 		= numberofreturnstotalfrequencycod 
gen ind_assets 		= totalassets2frequencycode
replace ind_number = "5" if ind_number =="3"
replace ind_assets = "5" if ind_assets =="3"

gen cassets_1 		= depreciableassets 
gen cassets_2 		= depletableassets
gen cassets_3 		= land
gen intangibles 	= intangibleassets
gen negcassets_1 	= accumulateddepreciation
gen negcassets_2 	= accumulateddepletion
gen negintangibles 	= accumulatedamortization

gen treceipts 		= totalreceipts
gen breceipts 		= businessreceipts
gen ninc 			= netincomelessdeficit

// Add up variables with subcategories
local vars cassets negcassets 
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace
	drop 		`v'_*
}

// Keep "All Returns", Drop "Returns with net income"
keep if file_type =="1"
drop file_type

gen 	thres_low = ""
replace thres_low = "Total" 		if asset_size == "000"
replace thres_low = "0" 			if asset_size == "001"
replace thres_low = "1" 			if asset_size == "020"
replace thres_low = "100000" 		if asset_size == "030"
replace thres_low = "250000" 		if asset_size == "040"
replace thres_low = "500000" 		if asset_size == "050"
replace thres_low = "1000000" 		if asset_size == "060"
replace thres_low = "5000000" 		if asset_size == "070"
replace thres_low = "10000000" 		if asset_size == "080"
replace thres_low = "25000000" 		if asset_size == "090"
replace thres_low = "50000000" 		if asset_size == "100"
replace thres_low = "100000000" 	if asset_size == "110"
replace thres_low = "250000000" 	if asset_size == "120"

keep 			year division_code major_group minor_industry thres_low `varlist'
append using 	`source_book_NA'
drop 			division_code major_group // These are empty in 1973 and 1974
rename 			minor_industry minor_industry_1973_1997_alt

save 			`source_book_NA', replace


// Create file with major group and minor industry for each division
use 	`SIC_vintages', replace
drop 	if division_code_1973_1997 ==""
collapse (first) minor_industry_1973_1997 major_group_1973_1997, by(division_code_1973_1997)
tempfile division
save 	"`division'"

// Create file with minor industry and division for each major group
use 	`SIC_vintages', replace
drop 	if major_group_1973_1997 ==""
collapse (first) minor_industry_1973_1997 division_code_1973_1997, by(major_group_1973_1997)
tempfile group
save 	"`group'"



use `source_book_NA', replace

destring `varlist', replace

// Add information on division and major group for each minor industry
merge m:1  minor_industry_1973_1997_alt using `sector1973_1997', assert(2 3) gen(m1) keep(3) keepusing(minor_industry_1973_1997 major_group_1973_1997 division_code_1973_1997)
drop m1 minor_industry_1973_1997_alt

// File only includes minor industries. Major group, divison and aggregate calculated by adding up minor industries.

// Sum minor industries to obtain aggregate.
preserve
collapse (sum) `varlist', by(thres_low year)
gen 		division_code_1973_1997 	= "00"
gen 		major_group_1973_1997 		= "00"
gen 		minor_industry_1973_1997 	= "0000"
tempfile 	source_book_NA_all
save 		"`source_book_NA_all'", replace
restore

// Sum minor industries to obtain industrial divisions
// Total only needs to be computed when division != minor_industry
preserve
bysort division_code thres_low year: gen	temp = _n
bysort division_code year: egen 			n = max(temp)
keep 		if n >1  
collapse (sum) `varlist', by(division_code thres_low year)
merge m:1 division_code using `division', keep(3) nogen
tempfile 	source_book_NA_div
save 		"`source_book_NA_div'", replace
restore

preserve
keep 		if division_code == "61" | division_code == "62" | division_code == "63"
collapse (last) minor_industry major_group division_code (sum) `varlist', by(thres_low year)
replace 	division_code 	= "60"
replace 	major_group 	= "00"
replace 	minor_industry 	= "0000"
tempfile 	source_book_NA_divtrade
save 		"`source_book_NA_divtrade'", replace
restore


// Sum minor industries to obtain major group
// Total only needs to be computed when major group != minor_industry
preserve
bysort major_group thres_low year: gen 	temp = _n
bysort major_group year: egen 			n = max(temp)
keep 		if n >1 
drop 		if major_group == "01" // Drop Agriculture, both an industry and a major group
drop 		if  major_group == "00" // Drop Other, both an industry and a major group
collapse  (sum) `varlist', by(major_group thres_low year)
merge m:1 major_group using `group', keep(3) nogen
tempfile 	source_book_NA_group
save 		"`source_book_NA_group'", replace 
restore

append using `source_book_NA_div'
append using `source_book_NA_divtrade'
append using `source_book_NA_group'
append using `source_book_NA_all'


tostring 	*, replace
rename 		minor_industry_1973_1997 	minor_industry
rename 		division_code_1973_1997 	division_code
rename 		major_group_1973_1997 		major_group
save 		`source_book_NA', replace




/* 1975 data */

import delimited "$DATA/soi/national_archive/RG058.CORP.Y75.txt", delimiter("|") clear stringcols(_all)


gen year 			= "1975"
gen division_code 	= indrydivision  
gen major_group 	= majorgroup
gen minor_industry 	= minorindustry
gen asset_size 		= sizetotalassets
gen file_type 		= incdft
gen number 			= numberofreturns
gen assets 			= totalassets
gen ind_number 		= numberofreturnsfrequencycode 
gen ind_assets 		= totalassetsfrequencycode
replace ind_number 	= "5" if ind_number =="3"
replace ind_assets 	= "5" if ind_assets =="3"

gen cassets_1 		= depreciableassets
gen cassets_2 		= depletableassets
gen cassets_3 		= land
gen intangibles 	= intangibleassets
gen negcassets_1 	= accumulateddepreciation
gen negcassets_2 	= accumulateddepletion
gen negintangibles 	= accumulatedamortization

gen treceipts 		= totalreceipts 
gen breceipts 		= businessreceipts
gen ninc 			= netincomelessdeficit

// Add up variables with subcategories
local vars cassets negcassets 
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace
	drop 		`v'_*
}

// Keep "All Returns", Drop "Returns with net income"
keep if file_type == "1"
drop file_type

gen 	thres_low 	  = ""
replace thres_low = "Total" 		if asset_size == "00"
replace thres_low = "0" 			if asset_size == "01"
replace thres_low = "1" 			if asset_size == "02"
replace thres_low = "100000" 		if asset_size == "03"
replace thres_low = "250000" 		if asset_size == "04"
replace thres_low = "500000" 		if asset_size == "05"
replace thres_low = "1000000" 		if asset_size == "06"
replace thres_low = "5000000" 		if asset_size == "07"
replace thres_low = "10000000" 		if asset_size == "08"
replace thres_low = "25000000" 		if asset_size == "09"
replace thres_low = "50000000" 		if asset_size == "10"
replace thres_low = "100000000" 	if asset_size == "11"
replace thres_low = "250000000" 	if asset_size == "12"

keep 	year division_code major_group minor_industry thres_low `varlist'
append using `source_book_NA'
save 	`source_book_NA', replace




/* 1976 data */

import delimited "$OUTPUT/soi/national_archive_converted/RG058.CORP.Y76_ASCII.txt", delimiter("", collapse) clear stringcols(_all)

replace v1 	= subinstr(v1, "{", "0",.) 
replace v1 	= subinstr(v1, "A", "1",.) 
replace v1 	= subinstr(v1, "B", "2",.) 
replace v1 	= subinstr(v1, "C", "3",.) 
replace v1 	= subinstr(v1, "D", "4",.)
replace v1 	= subinstr(v1, "E", "5",.) 
replace v1 	= subinstr(v1, "F", "6",.) 
replace v1 	= subinstr(v1, "G", "7",.) 
replace v1 	= subinstr(v1, "H", "8",.) 
replace v1 	= subinstr(v1, "I", "9",.) 

gen year 						= "1976"
gen minor_industry_1973_1997 	= substr(v1, 1, 4)
gen major_group_1973_1997 		= substr(v1, 5, 2)
gen division_code_1973_1997 	= substr(v1, 7, 2)
gen asset_size 					= substr(v1, 11, 2)
gen file_type 					= substr(v1, 14, 1)
replace minor_industry_1973_1997 = "6355" if minor_industry_1973_1997 =="6351"
keep if file_type 				== "1" // 1: All returns

// Add information on division to each major group
preserve
keep 		if major_group_1973_1997 != "00"
merge m:1 major_group_1973_1997 using `group', nogen keep(3 5) replace update keepusing(division_code_1973_1997)
tempfile 	source_book_NA_group
save 		"`source_book_NA_group'", replace
restore

// Add information on major group and division to each minor industry
preserve
keep 		if minor_industry_1973_1997 !="0000"
merge m:1 minor_industry_1973_1997 using `industry', nogen keep(3 5) replace update keepusing(major_group_1973_1997 division_code_1973_1997)
tempfile 	source_book_NA_industry
save 		"`source_book_NA_industry'", replace
restore

keep if major_group_1973_1997 =="00" & minor_industry_1973_1997 =="0000"
append using `source_book_NA_group'
append using `source_book_NA_industry'

gen number 			= substr(v1,21,11)
gen assets 			= substr(v1,33,11)
gen ind_number 		= substr(v1,32,1)
gen ind_assets 		= substr(v1,44,1)
replace ind_number 	= "5" if ind_number =="3"
replace ind_assets 	= "5" if ind_assets =="3"

gen cassets_1 		= substr(v1,165,11)
gen cassets_2 		= substr(v1,189,11)
gen cassets_3 		= substr(v1,213,11)
gen intangibles 	= substr(v1,225,11)
gen negcassets_1 	= substr(v1,177,11)
gen negcassets_2 	= substr(v1,201,11)
gen negintangibles 	= substr(v1,237,11)

gen treceipts 		= substr(v1,405,11)
gen breceipts 		= substr(v1,417,11)
gen ninc 			= substr(v1,789,11)

drop v1

local vars ninc 
foreach v of local vars {
	replace `v' = "-" + `v'  if	!inrange(real(substr(`v', -1, 1)), 0, 9)
	replace `v' = subinstr(`v', "}", "0",.) 
	replace `v' = subinstr(`v', "J", "1",.) 
	replace `v' = subinstr(`v', "K", "2",.) 
	replace `v' = subinstr(`v', "L", "3",.) 
	replace `v' = subinstr(`v', "M", "4",.)
	replace `v' = subinstr(`v', "N", "5",.) 
	replace `v' = subinstr(`v', "O", "6",.) 
	replace `v' = subinstr(`v', "P", "7",.) 
	replace `v' = subinstr(`v', "Q", "8",.) 
	replace `v' = subinstr(`v', "R", "9",.) 
}

// Add up variables with subcategories
local vars cassets negcassets 
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace
	drop 		`v'_*
}


gen 	thres_low = ""
replace thres_low = "Total" 		if asset_size == "00"
replace thres_low = "0" 			if asset_size == "01"
replace thres_low = "1" 			if asset_size == "02"
replace thres_low = "100000" 		if asset_size == "03"
replace thres_low = "250000" 		if asset_size == "04"
replace thres_low = "500000" 		if asset_size == "05"
replace thres_low = "1000000" 		if asset_size == "06"
replace thres_low = "5000000" 		if asset_size == "07"
replace thres_low = "10000000" 		if asset_size == "08"
replace thres_low = "25000000" 		if asset_size == "09"
replace thres_low = "50000000" 		if asset_size == "10"
replace thres_low = "100000000" 	if asset_size == "11"
replace thres_low = "250000000" 	if asset_size == "12"

local varlist number assets treceipts breceipts cassets negcassets intangibles negintangibles ninc

// Add with and without income	
foreach v of local varlist {
	destring 																	`v', replace
	bysort year minor_industry major_group division_code thres_low: egen double temp = sum(`v')
	replace 																	`v' = temp
	drop 																		temp
}

rename major_group_1973_1997 		major_group
rename division_code_1973_1997 		division_code
rename minor_industry_1973_1997 	minor_industry

duplicates drop 																year minor_industry major_group division_code thres_low, force
drop file_type asset_size

tostring *, replace force
order thres_low
sort minor_industry major_group division_code thres_low
append using `source_book_NA'
save `source_book_NA', replace




/* 1977 data */

import delimited "$DATA/soi/national_archive/RG058.CORP.Y77.txt",  delimiter(" ", collapse) clear stringcols(_all)

foreach v of varlist v1-v151 {
	replace `v' = "-" + `v'  if	!inrange(real(substr(`v', -3, 1)), 0, 9)
	replace `v' = subinstr(`v', "}", "0",.) 
	replace `v' = subinstr(`v', "J", "1",.) 
	replace `v' = subinstr(`v', "K", "2",.) 
	replace `v' = subinstr(`v', "L", "3",.)
	replace `v' = subinstr(`v', "M", "4",.)
	replace `v' = subinstr(`v', "N", "5",.)
	replace `v' = subinstr(`v', "O", "6",.)
	replace `v' = subinstr(`v', "P", "7",.)
	replace `v' = subinstr(`v', "Q", "8",.)
	replace `v' = subinstr(`v', "R", "9",.)
}

gen year 			= "19" + substr(v1, 1,2)
gen file_type 		= substr(v1, 3, 1)
gen division_code 	= substr(v2, 1, 2)
gen major_group 	= substr(v2, 3, 2)
gen minor_industry 	= substr(v2, 5, 4)
gen asset_size 		= substr(v2, 9, 2)
gen number 			= substr(v3,1,strlen(v3)-2)
gen assets 			= substr(v4,1,strlen(v4)-2)
gen ind_number 		= substr(v3,-1,1)
gen ind_assets 		= substr(v4,-1,1)

gen cassets_1 		= substr(v15,1,strlen(v15)-2)
gen cassets_2 		= substr(v17,1,strlen(v17)-2)
gen cassets_3 		= substr(v19,1,strlen(v19)-2)
gen intangibles 	= substr(v20,1,strlen(v20)-2)
gen negcassets_1 	= substr(v16,1,strlen(v16)-2)
gen negcassets_2 	= substr(v18,1,strlen(v18)-2)
gen negintangibles 	= substr(v21,1,strlen(v21)-2)

gen treceipts 		= substr(v35,1,strlen(v35)-2)
gen breceipts 		= substr(v36,1,strlen(v36)-2)
gen ninc 			= substr(v67,1,strlen(v67)-2)

// Add up variables with subcategories
local vars cassets negcassets  
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace
	drop 		`v'_*
}


// Keep "All Returns", Drop "Returns with net income"
keep 	if file_type == "1"
drop 	file_type 

gen 	thres_low = ""
replace thres_low = "Total" 	if asset_size == "01"
replace thres_low = "0" 		if asset_size == "02"
replace thres_low = "1" 		if asset_size == "03"
replace thres_low = "100000" 	if asset_size == "04"
replace thres_low = "200000" 	if asset_size == "05"
replace thres_low = "500000" 	if asset_size == "06"
replace thres_low = "1000000" 	if asset_size == "07"
replace thres_low = "5000000" 	if asset_size == "08"
replace thres_low = "10000000" 	if asset_size == "09"
replace thres_low = "25000000" 	if asset_size == "10"
replace thres_low = "50000000" 	if asset_size == "11"
replace thres_low = "100000000" if asset_size == "12"
replace thres_low = "250000000" if asset_size == "13"

drop 	v1 - v151
append using `source_book_NA'
save 	`source_book_NA', replace



/* 1978 data */

import delimited "$DATA/soi/national_archive/RG058.CORP.Y78.txt",  clear stringcols(_all)

gen year 			= "19" + substr(v1, 1,2)
gen file_type 		= substr(v1, 3, 1)
gen zero_filled 	= substr(v1, 4, 1)
gen division_code 	= substr(v1, 5, 2)
gen major_group 	= substr(v1, 7, 2)
gen minor_industry 	= substr(v1, 9, 4)
gen asset_size 		= substr(v1, 13, 2)
gen number 			= substr(v1,21,13)
gen assets 			= substr(v1,47,13)
gen ind_number 		= substr(v1,34,1)
gen ind_assets 		= substr(v1,60,1)

gen cassets_1 		= substr(v1,333,13)
gen cassets_2 		= substr(v1,385,13)
gen cassets_3 		= substr(v1,437,13)
gen intangibles 	= substr(v1,463,13)
gen negcassets_1 	= substr(v1,359,13)
gen negcassets_2 	= substr(v1,411,13)
gen negintangibles 	= substr(v1,489,13)

gen treceipts 		= substr(v1,853,13)
gen breceipts 		= substr(v1,879,13)
gen ninc 			= substr(v1,1685,13)


local vars ninc  
foreach v of local vars {
	replace `v' = "-" + `v'  if	!inrange(real(substr(`v', -1, 1)), 0, 9)
	replace `v' = subinstr(`v', "}", "0",.) 
	replace `v' = subinstr(`v', "J", "1",.) 
	replace `v' = subinstr(`v', "K", "2",.) 
	replace `v' = subinstr(`v', "L", "3",.) 
	replace `v' = subinstr(`v', "M", "4",.)
	replace `v' = subinstr(`v', "N", "5",.) 
	replace `v' = subinstr(`v', "O", "6",.) 
	replace `v' = subinstr(`v', "P", "7",.) 
	replace `v' = subinstr(`v', "Q", "8",.) 
	replace `v' = subinstr(`v', "R", "9",.) 
}

// Add up variables with subcategories
local vars cassets negcassets  
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace force
	drop	 	`v'_*
}


// Keep "All Returns", Drop "Returns with net income"
keep 	if file_type == "1"
drop 	file_type zero_filled

gen 	thres_low = ""
replace thres_low = "Total" 	if asset_size == "01"
replace thres_low = "0" 		if asset_size == "02"
replace thres_low = "1" 		if asset_size == "03"
replace thres_low = "100000" 	if asset_size == "04"
replace thres_low = "250000" 	if asset_size == "05"
replace thres_low = "500000" 	if asset_size == "06"
replace thres_low = "1000000" 	if asset_size == "07"
replace thres_low = "5000000" 	if asset_size == "08"
replace thres_low = "10000000" 	if asset_size == "09"
replace thres_low = "25000000" 	if asset_size == "10"
replace thres_low = "50000000" 	if asset_size == "11"
replace thres_low = "100000000" if asset_size == "12"
replace thres_low = "250000000" if asset_size == "13"

drop 	v1
append using `source_book_NA'
save 	`source_book_NA', replace



/* 1979 data */

import delimited "$DATA/soi/national_archive/RG058.CORP.Y79.txt",  clear stringcols(_all)

gen year 			= "19" + substr(v1, 1,2)
gen file_type 		= substr(v1, 3, 1)
gen zero_filled 	= substr(v1, 4, 1)
gen division_code 	= substr(v1, 5, 2)
gen major_group 	= substr(v1, 7, 2)
gen minor_industry 	= substr(v1, 9, 4)
gen asset_size 		= substr(v1, 13, 2)
gen number 			= substr(v1,21,13)
gen assets 			= substr(v1,50,13)
gen ind_number 		= substr(v1,34,1)
gen ind_assets 		= substr(v1,63,1)

gen cassets_1 		= substr(v1,369,13)
gen cassets_2 		= substr(v1,427,13)
gen cassets_3 		= substr(v1,485,13)
gen intangibles 	= substr(v1,514,13)
gen negcassets_1 	= substr(v1,398,13)
gen negcassets_2 	= substr(v1,456,13)
gen negintangibles 	= substr(v1,543,13)

gen treceipts 		= substr(v1,949,13)
gen breceipts 		= substr(v1,978,13)
gen ninc 			= substr(v1,1877,13)

local vars ninc  
foreach v of local vars {
	replace `v' = "-" + `v'  if	!inrange(real(substr(`v', -1, 1)), 0, 9)
	replace `v' = subinstr(`v', "}", "0",.) 
	replace `v' = subinstr(`v', "J", "1",.) 
	replace `v' = subinstr(`v', "K", "2",.) 
	replace `v' = subinstr(`v', "L", "3",.) 
	replace `v' = subinstr(`v', "M", "4",.)
	replace `v' = subinstr(`v', "N", "5",.) 
	replace `v' = subinstr(`v', "O", "6",.) 
	replace `v' = subinstr(`v', "P", "7",.) 
	replace `v' = subinstr(`v', "Q", "8",.) 
	replace `v' = subinstr(`v', "R", "9",.) 
}


// Add up variables with subcategories
local vars cassets negcassets  
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace force
	drop 		`v'_*
}


// Keep "All Returns", Drop "Returns with net income"
keep 	if file_type == "1"
drop 	file_type zero_filled

gen 	thres_low = ""
replace thres_low = "Total" 	if asset_size == "01"
replace thres_low = "0" 		if asset_size == "02"
replace thres_low = "1" 		if asset_size == "03"
replace thres_low = "100000" 	if asset_size == "04"
replace thres_low = "250000" 	if asset_size == "05"
replace thres_low = "500000" 	if asset_size == "06"
replace thres_low = "1000000" 	if asset_size == "07"
replace thres_low = "5000000" 	if asset_size == "08"
replace thres_low = "10000000" 	if asset_size == "09"
replace thres_low = "25000000" 	if asset_size == "10"
replace thres_low = "50000000" 	if asset_size == "11"
replace thres_low = "100000000" if asset_size == "12"
replace thres_low = "250000000" if asset_size == "13"

drop 	v1
append using `source_book_NA'
save 	`source_book_NA', replace




/* 1980 data */

import delimited "$DATA/soi/national_archive/RG058.CORP.Y80.txt",  clear stringcols(_all)

gen year 			= "19" + substr(v1, 1,2)
gen file_type 		= substr(v1, 3, 1)
gen zero_filled 	= substr(v1, 4, 1)
gen division_code 	= substr(v1, 5, 2)
gen major_group 	= substr(v1, 7, 2)
gen minor_industry 	= substr(v1, 9, 4)
gen asset_size 		= substr(v1, 13, 2)
gen number 			= substr(v1,21,13)
gen assets 			= substr(v1,108,13)
gen ind_number 		= substr(v1,34,1)
gen ind_assets 		= substr(v1,121,1)

gen cassets_1 		= substr(v1,427,13)
gen cassets_2 		= substr(v1,485,13)
gen cassets_3 		= substr(v1,543,13)
gen intangibles 	= substr(v1,572,13)
gen negcassets_1 	= substr(v1,456,13)
gen negcassets_2 	= substr(v1,514,13)
gen negintangibles 	= substr(v1,601,13)

gen treceipts 		= substr(v1,1007,13)
gen breceipts 		= substr(v1,1036,13)
gen ninc 			= substr(v1,1935,13)

local vars ninc  
foreach v of local vars {
	replace `v' = "-" + `v'  if	!inrange(real(substr(`v', -1, 1)), 0, 9)
	replace `v' = subinstr(`v', "}", "0",.) 
	replace `v' = subinstr(`v', "J", "1",.) 
	replace `v' = subinstr(`v', "K", "2",.) 
	replace `v' = subinstr(`v', "L", "3",.) 
	replace `v' = subinstr(`v', "M", "4",.)
	replace `v' = subinstr(`v', "N", "5",.) 
	replace `v' = subinstr(`v', "O", "6",.) 
	replace `v' = subinstr(`v', "P", "7",.) 
	replace `v' = subinstr(`v', "Q", "8",.) 
	replace `v' = subinstr(`v', "R", "9",.) 
}


// Add up variables with subcategories
local vars cassets negcassets 
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace force
	drop 		`v'_*
}


// Keep "All Returns", Drop "Returns with net income"
keep 	if file_type == "1"
drop 	file_type zero_filled

gen 	thres_low = ""
replace thres_low = "Total" 	if asset_size == "01"
replace thres_low = "0" 		if asset_size == "02"
replace thres_low = "1" 		if asset_size == "03"
replace thres_low = "100000" 	if asset_size == "04"
replace thres_low = "250000" 	if asset_size == "05"
replace thres_low = "500000" 	if asset_size == "06"
replace thres_low = "1000000" 	if asset_size == "07"
replace thres_low = "5000000" 	if asset_size == "08"
replace thres_low = "10000000" 	if asset_size == "09"
replace thres_low = "25000000" 	if asset_size == "10"
replace thres_low = "50000000" 	if asset_size == "11"
replace thres_low = "100000000" if asset_size == "12"
replace thres_low = "250000000" if asset_size == "13"

drop 	v1
append using `source_book_NA'
save 	`source_book_NA', replace




/* 1985 data */

import delimited "$DATA/soi/national_archive/RG058.CORSCB.ST85.txt",  clear stringcols(_all)

gen year 			= "19" + substr(v1, 1,2)
gen file_type 		= substr(v1, 3, 1)
gen zero_filled 	= substr(v1, 4, 1)
gen division_code 	= substr(v1, 5, 2)
gen major_group 	= substr(v1, 7, 2)
gen minor_industry 	= substr(v1, 9, 4)
gen asset_size 		= substr(v1, 13, 2)
gen number 			= substr(v1,15,19)
gen assets 			= substr(v1,151,28)
gen ind_number 		= substr(v1,34,1)
gen ind_assets 		= substr(v1,179,1)

gen cassets_1 		= substr(v1,441,28)
gen cassets_2 		= substr(v1,499,28)
gen cassets_3 		= substr(v1,557,28)
gen intangibles 	= substr(v1,586,28)
gen negcassets_1 	= substr(v1,470,28)
gen negcassets_2 	= substr(v1,528,28)
gen negintangibles 	= substr(v1,615,28)

gen treceipts 		= substr(v1,1021,28)
gen breceipts 		= substr(v1,1050,28)
gen ninc 			= substr(v1,1949,28)


local vars ninc  
foreach v of local vars {
	replace `v' = "-" + `v'  if	!inrange(real(substr(`v', -1, 1)), 0, 9)
	replace `v' = subinstr(`v', "}", "0",.) 
	replace `v' = subinstr(`v', "J", "1",.) 
	replace `v' = subinstr(`v', "K", "2",.) 
	replace `v' = subinstr(`v', "L", "3",.) 
	replace `v' = subinstr(`v', "M", "4",.)
	replace `v' = subinstr(`v', "N", "5",.) 
	replace `v' = subinstr(`v', "O", "6",.) 
	replace `v' = subinstr(`v', "P", "7",.) 
	replace `v' = subinstr(`v', "Q", "8",.) 
	replace `v' = subinstr(`v', "R", "9",.) 
}

// Add up variables with subcategories
local vars cassets negcassets  
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace force
	drop 		`v'_*
}


// Keep "All Returns", Drop "Returns with net income"
keep 	if file_type == "1"
drop 	file_type zero_filled

gen 	thres_low = ""
replace thres_low = "Total" 	if asset_size == "01"
replace thres_low = "0" 		if asset_size == "02"
replace thres_low = "1" 		if asset_size == "03"
replace thres_low = "100000" 	if asset_size == "04"
replace thres_low = "250000" 	if asset_size == "05"
replace thres_low = "500000" 	if asset_size == "06"
replace thres_low = "1000000" 	if asset_size == "07"
replace thres_low = "5000000" 	if asset_size == "08"
replace thres_low = "10000000" 	if asset_size == "09"
replace thres_low = "25000000" 	if asset_size == "10"
replace thres_low = "50000000" 	if asset_size == "11"
replace thres_low = "100000000" if asset_size == "12"
replace thres_low = "250000000" if asset_size == "13"

drop 	v1
append using `source_book_NA'
save 	`source_book_NA', replace



/* 1986 data */

import delimited "$DATA/soi/national_archive/RG058.CORSCB.ST86.txt",  clear stringcols(_all)

// Note: A letter is used for the last entry of a number. The following letters seem have one for one match with numbers. */

replace v1	= subinstr(v1, "{", "0",.) 
replace v1 	= subinstr(v1, "A", "1",.) 
replace v1 	= subinstr(v1, "B", "2",.) 
replace v1 	= subinstr(v1, "C", "3",.) 
replace v1 	= subinstr(v1, "D", "4",.)
replace v1 	= subinstr(v1, "E", "5",.) 
replace v1 	= subinstr(v1, "F", "6",.) 
replace v1 	= subinstr(v1, "G", "7",.) 
replace v1 	= subinstr(v1, "H", "8",.) 
replace v1 	= subinstr(v1, "I", "9",.) 

gen year 			= "19" + substr(v1, 1,2)
gen file_type 		= substr(v1, 3, 1)
gen zero_filled 	= substr(v1, 4, 1)
gen division_code 	= substr(v1, 5, 2)
gen major_group 	= substr(v1, 7, 2)
gen minor_industry 	= substr(v1, 9, 4)
gen asset_size 		= substr(v1, 13, 2)
gen number 			= substr(v1,15,19)
gen assets 			= substr(v1,151,28)
gen ind_number 		= substr(v1,34,1)
gen ind_assets 		= substr(v1,179,1)

gen cassets_1 		= substr(v1,441,28)
gen cassets_2 		= substr(v1,499,28)
gen cassets_3 		= substr(v1,557,28)
gen intangibles 	= substr(v1,586,28)
gen negcassets_1 	= substr(v1,470,28)
gen negcassets_2 	= substr(v1,528,28)
gen negintangibles 	= substr(v1,615,28)

gen treceipts 		= substr(v1,1050,28)
gen breceipts 		= substr(v1,1079,28)
gen ninc 			= substr(v1,1978,28)

local vars ninc  
foreach v of local vars {
	replace `v' = "-" + `v'  if	!inrange(real(substr(`v', -1, 1)), 0, 9)
	replace `v' = subinstr(`v', "}", "0",.) 
	replace `v' = subinstr(`v', "J", "1",.) 
	replace `v' = subinstr(`v', "K", "2",.) 
	replace `v' = subinstr(`v', "L", "3",.) 
	replace `v' = subinstr(`v', "M", "4",.)
	replace `v' = subinstr(`v', "N", "5",.) 
	replace `v' = subinstr(`v', "O", "6",.) 
	replace `v' = subinstr(`v', "P", "7",.) 
	replace `v' = subinstr(`v', "Q", "8",.) 
	replace `v' = subinstr(`v', "R", "9",.) 
}

// Add up variables with subcategories
local vars cassets negcassets 
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace force
	drop	 	`v'_*
}


// Keep "All Returns", Drop "Returns with net income"
keep 	if file_type == "1"
drop 	file_type zero_filled

gen 	thres_low = ""
replace thres_low = "Total" 		if asset_size == "01"
replace thres_low = "0" 			if asset_size == "02"
replace thres_low = "1" 			if asset_size == "03"
replace thres_low = "100000" 		if asset_size == "04"
replace thres_low = "250000" 		if asset_size == "05"
replace thres_low = "500000" 		if asset_size == "06"
replace thres_low = "1000000" 		if asset_size == "07"
replace thres_low = "5000000" 		if asset_size == "08"
replace thres_low = "10000000" 		if asset_size == "09"
replace thres_low = "25000000" 		if asset_size == "10"
replace thres_low = "50000000" 		if asset_size == "11"
replace thres_low = "100000000" 	if asset_size == "12"
replace thres_low = "250000000" 	if asset_size == "13"

drop 	v1
append using `source_book_NA'
save 	`source_book_NA', replace



/* 1987 data */

import delimited "$DATA/soi/national_archive/RG058.CORSCB.ST87.txt",  clear stringcols(_all)

rename 		v1 v
gen 		v1 = substr(v, 1, 14)
forvalues i=2/89 {
	local 	start = (`i'-1) * 15 
	gen 	v`i' = substr(v, `start', 15)
}
drop 		v

gen year 			= "19" + substr(v1, 1,2)
gen file_type 		= substr(v1, 3, 1)
gen zero_filled 	= substr(v1, 4, 1)
gen division_code 	= substr(v1, 5, 2)
gen major_group 	= substr(v1, 7, 2)
gen minor_industry 	= substr(v1, 9, 4)
gen asset_size 		= substr(v1, 13, 2)
gen number 			= substr(v2,1,strlen(v2)-1)
gen assets 			= substr(v3,1,strlen(v3)-1)
gen ind_number 		= substr(v2,-1,1)
gen ind_assets 		= substr(v3,-1,1)

gen cassets_1 		= substr(v13,1,strlen(v13)-1)
gen cassets_2 		= substr(v15,1,strlen(v15)-1)
gen cassets_3 		= substr(v17,1,strlen(v17)-1)
gen intangibles 	= substr(v18,1,strlen(v18)-1)
gen negcassets_1 	= substr(v14,1,strlen(v14)-1)
gen negcassets_2 	= substr(v16,1,strlen(v16)-1)
gen negintangibles 	= substr(v19,1,strlen(v19)-1)

gen treceipts 		= substr(v34,1,strlen(v34)-1)
gen breceipts 		= substr(v35,1,strlen(v35)-1)
gen ninc 			= substr(v65,1,strlen(v65)-1)

// Add up variables with subcategories
local vars cassets negcassets 
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace
	drop 		`v'_*
}


// Keep "All Returns", Drop "Returns with net income"
keep if file_type =="1"
drop 	file_type zero_filled

gen 	thres_low = ""
replace thres_low = "Total" 		if asset_size == "01"
replace thres_low = "0" 			if asset_size == "02"
replace thres_low = "1" 			if asset_size == "03"
replace thres_low = "100000" 		if asset_size == "04"
replace thres_low = "250000" 		if asset_size == "05"
replace thres_low = "500000" 		if asset_size == "06"
replace thres_low = "1000000" 		if asset_size == "07"
replace thres_low = "5000000" 		if asset_size == "08"
replace thres_low = "10000000" 		if asset_size == "09"
replace thres_low = "25000000" 		if asset_size == "10"
replace thres_low = "50000000" 		if asset_size == "11"
replace thres_low = "100000000" 	if asset_size == "12"
replace thres_low = "250000000" 	if asset_size == "13"

drop 	v1 - v89
append using `source_book_NA'
save 	`source_book_NA', replace



/* 1988 data */

import delimited "$DATA/soi/national_archive/RG058.CORP.Y88.txt",  clear stringcols(_all)

rename 		v1 v
gen 		v1 = substr(v, 1, 14)
forvalues i = 2/87 {
	local 	start = (`i'-1) * 15 
	gen		 v`i' = substr(v, `start', 15)
}
drop 		v

gen year 			= "19" + substr(v1, 1,2)
gen file_type 		= substr(v1, 3, 1)
gen zero_filled 	= substr(v1, 4, 1)
gen division_code 	= substr(v1, 5, 2)
gen major_group 	= substr(v1, 7, 2)
gen minor_industry 	= substr(v1, 9, 4)
gen asset_size 		= substr(v1, 13, 2)
gen number 			= substr(v2,1,strlen(v2)-1)
gen assets 			= substr(v3,1,strlen(v3)-1)
gen ind_number 		= substr(v2,-1,1)
gen ind_assets 		= substr(v3,-1,1)

gen cassets_1 		= substr(v13,1,strlen(v13)-1)
gen cassets_2 		= substr(v15,1,strlen(v15)-1)
gen cassets_3 		= substr(v17,1,strlen(v17)-1)
gen intangibles 	= substr(v18,1,strlen(v18)-1)
gen negcassets_1 	= substr(v14,1,strlen(v14)-1)
gen negcassets_2 	= substr(v16,1,strlen(v16)-1)
gen negintangibles 	= substr(v19,1,strlen(v19)-1)

gen treceipts 		= substr(v34,1,strlen(v34)-1)
gen breceipts 		= substr(v35,1,strlen(v35)-1)
gen ninc 			= substr(v65,1,strlen(v65)-1)

// Add up variables with subcategories
local vars cassets negcassets 
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace
	drop 		`v'_*
}


// Keep "All Returns", Drop "Returns with net income"
keep if file_type == "1"
drop 	file_type zero_filled

gen 	thres_low = ""
replace thres_low = "Total" 	if asset_size == "01"
replace thres_low = "0" 		if asset_size == "02"
replace thres_low = "1" 		if asset_size == "03"
replace thres_low = "100000" 	if asset_size == "04"
replace thres_low = "250000" 	if asset_size == "05"
replace thres_low = "500000" 	if asset_size == "06"
replace thres_low = "1000000" 	if asset_size == "07"
replace thres_low = "5000000" 	if asset_size == "08"
replace thres_low = "10000000" 	if asset_size == "09"
replace thres_low = "25000000" 	if asset_size == "10"
replace thres_low = "50000000" 	if asset_size == "11"
replace thres_low = "100000000" if asset_size == "12"
replace thres_low = "250000000" if asset_size == "13"

drop 	v1 - v87
append using `source_book_NA'
save 	`source_book_NA', replace



/* 1989 data */

import delimited "$DATA/soi/national_archive/RG058.CORP.Y89.txt",  clear stringcols(_all)

rename v1 v
gen v1 = substr(v, 1, 14)
forvalues i = 2/90 {
	local 	start = (`i'-1) * 15 
	gen 	v`i' = substr(v, `start', 15)
}
drop v

gen year 			= "19" + substr(v1, 1,2)
gen file_type 		= substr(v1, 3, 1)
gen zero_filled 	= substr(v1, 4, 1)
gen division_code 	= substr(v1, 5, 2)
gen major_group 	= substr(v1, 7, 2)
gen minor_industry 	= substr(v1, 9, 4)
gen asset_size 		= substr(v1, 13, 2)

gen number 			= substr(v2,1,strlen(v2)-1)
gen assets 			= substr(v3,1,strlen(v3)-1)
gen ind_number 		= substr(v2,-1,1)
gen ind_assets 		= substr(v3,-1,1)

gen cassets_1 		= substr(v14,1,strlen(v14)-1)
gen cassets_2 		= substr(v16,1,strlen(v16)-1)
gen cassets_3 		= substr(v18,1,strlen(v18)-1)
gen intangibles 	= substr(v19,1,strlen(v19)-1)
gen negcassets_1 	= substr(v15,1,strlen(v15)-1)
gen negcassets_2 	= substr(v17,1,strlen(v17)-1)
gen negintangibles 	= substr(v20,1,strlen(v20)-1)

gen treceipts 		= substr(v35,1,strlen(v35)-1)
gen breceipts 		= substr(v36,1,strlen(v36)-1)
gen ninc 			= substr(v66,1,strlen(v66)-1)

// Add up variables with subcategories
local vars cassets negcassets 
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace force
	drop 		`v'_*
}


// Keep "All Returns", Drop "Returns with net income"
keep if file_type == "1"
drop file_type zero_filled

gen 	thres_low = ""
replace thres_low = "Total" 		if asset_size == "01"
replace thres_low = "0" 			if asset_size == "02"
replace thres_low = "1" 			if asset_size == "03"
replace thres_low = "100000" 		if asset_size == "04"
replace thres_low = "250000" 		if asset_size == "05"
replace thres_low = "500000" 		if asset_size == "06"
replace thres_low = "1000000" 		if asset_size == "07"
replace thres_low = "5000000" 		if asset_size == "08"
replace thres_low = "10000000" 		if asset_size == "09"
replace thres_low = "25000000" 		if asset_size == "10"
replace thres_low = "50000000" 		if asset_size == "11"
replace thres_low = "100000000" 	if asset_size == "12"
replace thres_low = "250000000" 	if asset_size == "13"

drop 	v1 - v90
append using `source_book_NA'
save 	`source_book_NA', replace



/* 1990 data */

import delimited "$DATA/soi/national_archive/RG058.CORP.Y90.txt",  clear stringcols(_all)

rename 		v1 v
gen 		v1 = substr(v, 1, 14)
forvalues i = 2/90 {
	local 	start = (`i'-1) * 15 
	gen 	v`i' = substr(v, `start', 15)
}
drop 		v

gen year 			= "19" + substr(v1, 1,2)
gen file_type 		= substr(v1, 3, 1)
gen zero_filled 	= substr(v1, 4, 1)
gen division_code 	= substr(v1, 5, 2)
gen major_group 	= substr(v1, 7, 2)
gen minor_industry 	= substr(v1, 9, 4)
gen asset_size 		= substr(v1, 13, 2)
gen number 			= substr(v2,1,strlen(v3)-1)
gen assets 			= substr(v3,1,strlen(v3)-1)
gen ind_number 		= substr(v2,-1,1)
gen ind_assets 		= substr(v3,-1,1)

gen cassets_1 		= substr(v14,1,strlen(v14)-1)
gen cassets_2 		= substr(v16,1,strlen(v16)-1)
gen cassets_3 		= substr(v18,1,strlen(v18)-1)
gen intangibles 	= substr(v19,1,strlen(v19)-1)
gen negcassets_1 	= substr(v15,1,strlen(v15)-1)
gen negcassets_2 	= substr(v17,1,strlen(v17)-1)
gen negintangibles 	= substr(v20,1,strlen(v20)-1)

gen treceipts 		= substr(v36,1,strlen(v36)-1)
gen breceipts 		= substr(v37,1,strlen(v37)-1)
gen ninc 			= substr(v67,1,strlen(v67)-1)

// Add up variables with subcategories
local vars cassets negcassets 
foreach v of local vars {
	destring 	`v'_*, replace
	egen double `v' = rowtotal(`v'_*)
	tostring 	`v', replace
	drop 		`v'_*
}

// Keep "All Returns", Drop "Returns with net income"
keep if file_type == "1"
drop 	file_type zero_filled

gen 	thres_low = ""
replace thres_low = "Total" 		if asset_size == "01"
replace thres_low = "0" 			if asset_size == "02"
replace thres_low = "1" 			if asset_size == "03"
replace thres_low = "100000" 		if asset_size == "04"
replace thres_low = "250000" 		if asset_size == "05"
replace thres_low = "500000" 		if asset_size == "06"
replace thres_low = "1000000" 		if asset_size == "07"
replace thres_low = "5000000" 		if asset_size == "08"
replace thres_low = "10000000" 		if asset_size == "09"
replace thres_low = "25000000" 		if asset_size == "10"
replace thres_low = "50000000" 		if asset_size == "11"
replace thres_low = "100000000" 	if asset_size == "12"
replace thres_low = "250000000" 	if asset_size == "13"

drop 	v1 - v90
append using `source_book_NA'
save 	`source_book_NA', replace




********************************************
*======== Changes to all years 
********************************************

use `source_book_NA', clear

local varlist 	number assets treceipts breceipts cassets negcassets intangibles negintangibles ninc 

destring `varlist', replace 

gen 			minor_industry_1973_1997 	= minor_industry
gen 			major_group_1973_1997 		= major_group
gen 			division_code_1973_1997 	= division_code
merge m:1  minor_industry_1973_1997 major_group_1973_1997 division_code_1973_1997 using `SIC_vintages_1973_1997_unique',  gen(m2) keepusing(sector_final)
keep 			if m2 == 3
drop 			m2


append using `source_book_NA_batch1'
append using `source_book_NA_batch2'

local varlist 	number assets treceipts breceipts cassets negcassets intangibles negintangibles ninc 

destring 		year, replace

// Drop unnecessary variables
cap drop 		asset_size 
cap drop	 	m1


// Assign sectors from our harmonization
merge m:1 sector_final using "$OUTPUT/temp/sector_list_SIC_unique.dta",  keep(3) gen(m1) keepusing(sector_level sector_ID sector_main_ID indcode) assert(2 3)
drop 			m1
drop 			if sector_level == "Level Drop"

rename 			sector_level 	sec_level 
rename 			sector_ID 		sec_ID 
rename 			sector_main_ID 	sec_main_ID 
rename 			indcode 		scode 


// Manual adjustments
replace number = number * assets/100000 if minor_industry_1973_1997 == "0000" & major_group_1973_1997 == "10" & division_code_1973_1997 == "40" & thres_low =="25000000" & year == 1987


// Drop sector indentifiers
drop division_code major_group minor_industry

// Destring variables
destring, replace 

// Combine indicator variables for bracket deletion 
foreach v of varlist ind_assets ind_number {
	bysort year sector_final thres_low: egen		temp = max(`v')
	replace 										`v' = temp
	drop 											temp
}
egen 												temp = rowmax(ind_number ind_assets)

// Define bracket deletion variable
gen 												bracket_deletion = "no" 		if temp != 5
replace 											bracket_deletion = "yes" 		if temp == 5
bysort year sector_final: egen 						temp_total = max(temp)
gen 												bracket_deletion_total = "no" 	if temp_total != 5
replace 											bracket_deletion_total = "yes" 	if temp_total == 5
drop 												temp temp_total ind_number ind_assets

// Sum sectors belonging to one subsector
foreach v of local varlist {
	bysort year sector_final thres_low: egen double	temp = sum(`v') 				if bracket_deletion == "no"
	bysort year sector_final thres_low: replace 	temp = . 						if bracket_deletion == "yes"
	replace 										`v' = temp
	drop 											temp
}

duplicates drop 									year sector_final thres_low, force
drop 												*_1963_1967 *_1968_1972 

// Keep variables we need  
keep year sector thres_low sec_level sec_ID sec_main_ID scode number assets treceipts breceipts ninc cassets negcassets intangibles negintangibles bracket_deletion bracket_deletion_total

ren sector_final sector 

gen source = "national_archive"

save "$OUTPUT/temp/source_book_NA.dta", replace


