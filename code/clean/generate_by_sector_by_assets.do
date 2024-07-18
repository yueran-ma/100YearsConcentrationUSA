/************ Function ************/

*This file cleans raw tabulations by assets and produces cleaned tabulations "output/soi/brackets/sector_brackets_assets_R5.dta", "output/soi/brackets/subsector_brackets_assets_R5.dta.", "output/soi/brackets/subsector_gran_brackets_assets_R5.dta."

* In addition it prepares main sector totals with NAICS to SIC harmoinization at the 2 digit NAICS level "output/soi/by_2digitsector_totals.dta" used in FigureIA18.do

/************ Source ************/

*Digitized data 1931-1964, 1972, 1981-1984, 1991-1999: 								"input/soi/sector_raw_assets_R5.dta"
*Corporation source book file prepared by subprograms 
*	Electronic Corporation source book files 1965 to 1971, 1973-1980, 1985-1990: 	prepare_by_sector_by_assets_national_archive.do
*	Electronic Corporation Source Book Excels 2000 to 2003: 						prepare_by_sector_by_assets_2000_2003.do
*	Electronic Corporation Source Book Excels 2004 to 2013: 						prepare_by_sector_by_assets_2004_2013.do

/************ Notes ************/

*We use the sum over bins to construct *_total, except when there are bracket deletions, in which case we use the stated total 

/************ Steps ************/

*Import and combine data from the different sources 
*Assign main sectors and subsectors 
*Aggregate to main sectors/subsectors 
*Clean bracket deletions
*Clean brackets where the average is out of bounds

clear all

*================= Prepare sector files ========

*Prepare sector list for merge, SIC
import excel "$DATA/soi/sector_file.xlsx", sheet("SIC_main") clear
rename 	A sector
rename 	B sector_level
gen 	sector_main_ID = C 
gen 	sector_ID = D
gen 	indcode = "SIC"
rename 	E sector_final
rename 	G division_code
rename 	H major_group
rename 	I minor_industry
drop 	if _n == 1
drop 	C D F
replace sector = lower(sector)
replace sector = trim(sector)
save "$OUTPUT/temp/sector_list_SIC.dta", replace

collapse (lastnm) sector_ID sector_level sector_main_ID indcode, by(sector_final)
tempfile dataSIC
save 	"`dataSIC'"
save 	"$OUTPUT/temp/sector_list_SIC_unique.dta", replace


*Prepare sector list for merge, NAICS
import excel "$DATA/soi/sector_file.xlsx", sheet("NAICS_Industry code titles_2012") firstrow clear
destring Sector Major, replace force

gen 	sector_ID = Sector
replace sector_ID = Major if sector_ID == .
destring Minorcode, gen(Minor) force
replace sector_ID = Minor if sector_ID == .
carryforward Sector, gen(sector_main_ID)

keep 	if sector_ID != .
rename 	Sector_List sector_final
keep 	sector_final sector_ID sector_main_ID
gen 	sector_level = "Level 1" if sector_ID == 1
replace sector_level = "Level 2" if sector_ID > 9 & sector_ID < 100
replace sector_level = "Level 3" if sector_ID > 99 & sector_ID < 1000
replace sector_level = "Level 4" if sector_ID > 100000 & sector_ID < 1000000

tostring sector_ID sector_main_ID, replace
gen 	ID = sector_ID 

replace sector_ID = "31-33" 		if sector_ID == "31"
replace sector_main_ID = "31-33" 	if sector_main_ID == "31"
replace sector_ID = "48-49" 			if sector_ID == "48"
replace sector_main_ID = "48-49" 	if sector_main_ID == "48"

replace sector_ID = "41-45" 			if sector_ID == "41"
replace sector_main_ID = "41-45" 	if sector_main_ID == "41"

gen 	indcode = "NAICS"
gen 	sector = sector_final

drop if sector_ID == "541" | sector_ID == "551" // Subsector name == sector name
drop if sector_ID == "323100" // Minor Industry == Major Industry

replace sector = lower(sector)
replace sector = trim(sector)

save 	"$OUTPUT/temp/sector_list_NAICS_3digit.dta", replace


* Additional (earlier) NAICS codes
import excel "$DATA/soi/sector_file.xlsx", sheet("NAICS_additional") firstrow clear
rename 	Code ID
rename 	Code_final sector_ID
rename 	Name sector
rename 	Name_final sector_final

gen 	indcode = "NAICS"
tostring ID sector_ID sector_main_ID, replace

replace sector = lower(sector)
replace sector = trim(sector)

append using "$OUTPUT/temp/sector_list_NAICS_3digit.dta"
sleep 	2000
save 	"$OUTPUT/temp/sector_list_NAICS_3digit.dta", replace


collapse (lastnm) sector_ID sector_level sector_main_ID indcode ID, by(sector_final)
tempfile dataNAICS
save 	"`dataNAICS'"
save 	"$OUTPUT/temp/sector_list_NAICS_3digit_unique.dta", replace

use "$OUTPUT/temp/sector_list_NAICS_3digit.dta", replace
collapse (lastnm) sector_ID sector_level sector_main_ID indcode sector_final , by(ID)
tempfile dataNAICS
save 	"`dataNAICS'"
save 	"$OUTPUT/temp/sector_list_NAICS_3digit_uniqueID.dta", replace


*================= Prepare 1977-1980 and 1985-1990 source books (alternative format) ========

do "prepare_by_sector_by_assets_national_archive.do"

*================= Prepare 2000-2003 source books ========

do "prepare_by_sector_by_assets_2000_2003.do"

*================= Prepare 2004_2013 source books ========

do "prepare_by_sector_by_assets_2004_2013.do"



*===============================================================================
* Merge the four source types
*===============================================================================

use "$DATA/soi/digitized/sector_raw_assets_R5.dta", clear 

gen source = "digitized"

append using "$OUTPUT/temp/source_book_NA.dta"
append using "$OUTPUT/temp/by_sector_and_assets_2000_2003.dta"
append using "$OUTPUT/temp/by_sector_and_assets_2004_2013.dta"

save 	"$OUTPUT/temp/by_sector_and_assets.dta", replace







*===============================================================
*======== Prepare the combined data for the analysis
*===============================================================

use "$OUTPUT/temp/by_sector_and_assets.dta", clear


*************** Sector preparation *******************

sort 	sector year thres_low

gen 	sector_main = ""
replace sector_main = "All" 			if sector == "All Industries" & scode == "SIC" 	 & sec_ID == "all"	
replace sector_main = "All" 			if sector == "All Industries" & scode == "NAICS" & sec_ID == "1"	

* SIC: 01-09 (Agriculture, Forestry, Fishing). NAICS: 11 (Agriculture, Forestry, Fishing and Hunting). 
replace sector_main = "Agriculture" 	if scode ==	"SIC" 	& sec_ID == "01-09"
replace sector_main = "Agriculture" 	if scode ==	"NAICS" & sec_ID == "11" 

* SIC: 15-17. NAICS: 23. 
replace sector_main = "Construction" 	if scode ==	"SIC" 	 & sec_ID == "15-17" 
replace sector_main = "Construction" 	if scode ==	"NAICS"  & sec_ID == "23"

* SIC: 60-67 (Finance, Insurance, and Real Estate); NAICS: 52 (Finance and Insurance), 531 (Real Estate), 533 (Patents), 55 (Management of Companies (Holding Companies)), 50 Finance + Real estate together (1998, 1999)
replace sector_main = "Finance" 		if scode ==	"SIC" 	& sec_ID ==	"60-67"
replace sector_main = "Finance" 		if scode ==	"NAICS" & sec_ID ==	"52" 
replace sector_main = "Finance" 		if scode ==	"NAICS" & sec_ID ==	"531" 
replace sector_main = "Finance" 		if scode ==	"NAICS" & sec_ID ==	"533"  
replace sector_main = "Finance" 		if scode ==	"NAICS" & sec_ID ==	"55" 
drop 									if scode ==	"NAICS" & sec_ID ==	"50"

* SIC: 20-39 (Total Manufacturing). NAICS: 31-33 (Total Manufacturing), 511 (Publishing)
replace sector_main = "Manufacturing" 	if scode ==	"SIC" 	& sec_ID ==	"20-39" 
replace sector_main = "Manufacturing" 	if scode ==	"NAICS" & sec_ID ==	"31-33" 
replace sector_main = "Manufacturing" 	if scode ==	"NAICS" & sec_ID == "511" 

* SIC: 10-14. NAICS: 21. 
replace sector_main = "Mining" 			if scode ==	"SIC" 	& sec_ID ==	"10-14"
replace sector_main = "Mining" 			if scode ==	"NAICS" & sec_ID ==	"21"

* SIC: 70-89; * NAICS: 512, 514, 516, 518, 519 (Info subsectors), 532 (Car leasing), 54 (Professional, Scientific, and Technical Services), 561 (Administrative and Support Services), 61 (Educational Services), 62 (Health Care and Social Assistance), 71 (Arts, Entertainment, and Recreation), 721 (Accommodation), 81 (Other Services)
replace sector_main = "Services" 		if scode ==	"SIC" 	& sec_ID == "70-89" 
replace sector_main = "Services" 		if scode == "NAICS" & (sec_ID == "512" | sec_ID == "514" | sec_ID == "516" | sec_ID == "518" | sec_ID == "519") 
replace sector_main = "Services" 		if scode == "NAICS" & sec_ID == "532"
replace sector_main = "Services" 		if scode == "NAICS" & sec_ID == "54"
replace sector_main = "Services" 		if scode == "NAICS" & sec_ID == "561"
replace sector_main = "Services" 		if scode == "NAICS" & sec_ID == "61" 
replace sector_main = "Services" 		if scode == "NAICS" & sec_ID == "62" 
replace sector_main = "Services" 		if scode == "NAICS" & sec_ID == "71"
replace sector_main = "Services" 		if scode == "NAICS" & sec_ID == "721" 
replace sector_main = "Services" 		if scode == "NAICS" & sec_ID == "81"


* SIC: 40-49 (SIC) Transportation and Public Utilities; NAICS: 22 (Utilities), 48-49 (Transportation and Warehousing), 513, 515, 517 (Telec.), 562 (Waste Management)
replace sector_main = "Utilities" 		if scode == "SIC" 	& sec_ID == "40-49" 
replace sector_main = "Utilities" 		if scode == "NAICS" & sec_ID == "22" 
replace sector_main = "Utilities" 		if scode == "NAICS" & sec_ID == "48-49" 
replace sector_main = "Utilities" 		if scode == "NAICS" & (sec_ID == "513" | sec_ID == "515" | sec_ID == "517")
replace sector_main = "Utilities" 		if scode == "NAICS" & sec_ID == "562"

* SIC: 50-59 (Trade); NAICS: 42-45 (Wholesale and Retail Trade), 722 (Food Services and Drinking Places)
replace sector_main = "Trade" 			if scode == "SIC" 	& sec_ID == "50-59"
replace sector_main = "Trade" 			if scode == "NAICS" & (sec_ID == "42-45" | sec_ID == "41-45")
replace sector_main = "Trade" 			if scode == "NAICS" & sec_ID == "722"

* SIC other and NAICS other
replace sector_main = "Other" 			if sector == "Nature of Business Not Allocable"
replace sector_main = "Other" 			if sector == "Not Allocable"
drop 									if scode == "NAICS" & sec_ID == "70" // Already captured by other sectors (61, 62)


* Main sector, 2 digit
gen 	sector_main2digit = "" 
replace sector_main2digit = sector_main 	if year < 1998
replace sector_main2digit = sector_main 	if sector_main == "All" | sector_main == "Agriculture" | sector_main == "Construction" | sector_main == "Mining" | sector_main == "Other"   
replace sector_main2digit = "Finance" 		if scode == "NAICS" & sec_ID == "52" 
replace sector_main2digit = "Finance" 		if scode == "NAICS" & sec_ID == "53" 
replace sector_main2digit = "Finance" 		if scode == "NAICS" & sec_ID == "55" 
replace sector_main2digit = "Manufacturing" if scode == "NAICS" & sec_ID == "31-33" 
replace sector_main2digit = "Services" 		if scode == "NAICS" & sec_ID == "54" 
replace sector_main2digit = "Services" 		if scode == "NAICS" & sec_ID == "56" 
replace sector_main2digit = "Services" 		if scode == "NAICS" & sec_ID == "61" 
replace sector_main2digit = "Services" 		if scode == "NAICS" & sec_ID == "62" 
replace sector_main2digit = "Services" 		if scode == "NAICS" & sec_ID == "71" 
replace sector_main2digit = "Services" 		if scode == "NAICS" & sec_ID == "72"
replace sector_main2digit = "Services" 		if scode == "NAICS" & sec_ID == "81" 
replace sector_main2digit = "Utilities" 	if scode == "NAICS" & sec_ID == "22" 
replace sector_main2digit = "Utilities" 	if scode == "NAICS" & sec_ID == "48-49" 
replace sector_main2digit = "Utilities" 	if scode == "NAICS" & sec_ID == "51" 
replace sector_main2digit = "Trade" 		if scode == "NAICS" & (sec_ID == "42-45" | sec_ID == "41-45") 



*==== Construct combined subsectors SIC / NAICS

gen subsector = ""

*===== Drop agriculture subsectors =======

* Production
drop if scode == "SIC" 	 & sec_ID == "01-07" 
drop if scode == "NAICS" & sec_ID == "111" 

* Forestry, Fishing and Hunting
drop if scode == "SIC"   & sec_ID == "08-09" 
drop if scode == "NAICS" & sec_ID == "113" 	  
drop if scode == "NAICS" & sec_ID == "114" 	 

* Fishing and Hunting
drop if scode == "SIC"	 & sec_ID == "09" 		 
drop if scode == "NAICS" & sec_ID == "114"   

*===== Mining subsectors =======

* Metal
replace subsector = "Mining: Metal" 		if scode == "SIC" 	& sec_ID == "10"
replace subsector = "Mining: Metal" 		if scode == "NAICS" & sec_ID == "212200"

* Coal
replace subsector = "Mining: Coal" 			if scode == "SIC" 	& sec_ID == "12"
replace subsector = "Mining: Coal" 			if scode == "NAICS" & sec_ID == "212110" 

* Oil and Gas
replace subsector = "Mining: Oil and Gas" 	if scode == "SIC"	& sec_ID == "13"  
replace subsector = "Mining: Oil and Gas" 	if scode == "NAICS" & sec_ID == "211110"   
replace subsector = "Mining: Oil and Gas" 	if scode == "NAICS" & sec_ID == "213110"  // Support activities are largely oil and gas related 

* Non-Metallic
replace subsector = "Mining: Non Metallic" 	if scode == "SIC" 	& sec_ID == "14"
replace subsector = "Mining: Non Metallic" 	if scode == "SIC"	& sec_ID == "10-14_other"  // "Not allocable" is inegrated into other non-metallic mining
replace subsector = "Mining: Non Metallic" 	if scode == "NAICS" & sec_ID == "212315"

*===== Construction subsectors =======

* Buildings
replace subsector = "Construction: Buildings" 			if scode == "SIC" 	& sec_ID == "15"
replace subsector = "Construction: Buildings" 			if scode == "NAICS" & sec_ID == "236"

* Heavy Construction
replace subsector = "Construction: Heavy Construction" 	if scode == "SIC"	& sec_ID == "16"
replace subsector = "Construction: Heavy Construction" 	if scode == "NAICS"	& sec_ID == "237"

* Special Trade
replace subsector = "Construction: Special Trade" 		if scode == "SIC"	& sec_ID == "17"
replace subsector = "Construction: Special Trade" 		if scode == "NAICS"	& sec_ID == "238"


*===== Manufacturing subsectors =======

* Food & Tobacco
replace subsector = "Manufacturing: Food" 				if scode == "SIC"	&  sec_ID == "20"
replace subsector = "Manufacturing: Food" 				if scode == "SIC"	&  sec_ID == "21"
replace subsector = "Manufacturing: Food" 				if scode == "NAICS"	& (sec_ID == "311" | sec_ID == "312") 

* Textile Mills
replace subsector = "Manufacturing: Textile Mills" 		if scode == "SIC"  	& sec_ID == "22"
replace subsector = "Manufacturing: Textile Mills" 		if scode == "NAICS" & sec_ID == "313"   

* Apparel
replace subsector = "Manufacturing: Apparel" 			if scode == "SIC"	& sec_ID == "23"
replace subsector = "Manufacturing: Apparel" 			if scode == "NAICS" & sec_ID == "315"

* Wood
replace subsector = "Manufacturing: Wood" 				if scode == "SIC" 	& sec_ID == "24"
replace subsector = "Manufacturing: Wood" 				if scode == "NAICS" & sec_ID == "321"

* Furniture
replace subsector = "Manufacturing: Furniture" 			if scode == "SIC" 	& sec_ID == "25"
replace subsector = "Manufacturing: Furniture" 			if scode == "NAICS" & sec_ID == "337"

* Paper
replace subsector = "Manufacturing: Paper" 				if scode == "SIC" 	& sec_ID == "26"
replace subsector = "Manufacturing: Paper" 				if scode == "NAICS" & sec_ID == "322"

* Printing
replace subsector = "Manufacturing: Printing" 			if scode == "SIC" 	& sec_ID == "27"
replace subsector = "Manufacturing: Printing" 			if scode == "NAICS" & sec_ID == "323"
replace subsector =  "Manufacturing: Printing" 			if scode == "NAICS" & sec_ID == "511"   

* Chemicals
replace subsector = "Manufacturing: Chemicals" 			if scode == "SIC" 	& sec_ID == "28"
replace subsector = "Manufacturing: Chemicals" 			if scode == "NAICS" & sec_ID == "325"

* Petroleum
replace subsector = "Manufacturing: Petroleum" 			if scode == "SIC" 	& sec_ID == "29"
replace subsector = "Manufacturing: Petroleum" 			if scode == "NAICS" & sec_ID == "324"

* Rubber
replace subsector = "Manufacturing: Rubber" 			if scode == "SIC" 	& sec_ID == "30_old"

* Plastics
replace subsector = "Manufacturing: Plastics" 			if scode == "SIC" 	& sec_ID == "30"
replace subsector = "Manufacturing: Plastics" 			if scode == "NAICS" & sec_ID == "326" 

* Leather
replace subsector = "Manufacturing: Leather"  			if scode == "SIC" 	& sec_ID == "31"
replace subsector = "Manufacturing: Leather"  			if scode == "NAICS" & sec_ID == "316"

* Stone, Clay, and Glass Products
replace subsector = "Manufacturing: Stone" 				if scode == "SIC" 	& sec_ID == "32"
replace subsector = "Manufacturing: Stone" 				if scode == "NAICS" & sec_ID == "327" 

* Primary metals 
replace subsector = "Manufacturing: Primary Metals" 	if scode == "SIC" 	& sec_ID == "33"  
replace subsector = "Manufacturing: Primary Metals" 	if scode == "NAICS" & sec_ID == "331"

* Fabricated Metals
replace subsector = "Manufacturing: Fabricated Metals" 	if scode == "SIC" 	& sec_ID == "34"   
replace subsector = "Manufacturing: Fabricated Metals" 	if scode == "NAICS" & sec_ID == "332"  


* Electrical Machinery
replace subsector = "Manufacturing: Electrical" 		if scode == "SIC" 	& sec_ID == "36"  
replace subsector = "Manufacturing: Electrical" 		if scode == "NAICS" & (sec_ID == "335" | sec_ID == "334")  

* Transportation (Motor and other)
replace subsector = "Manufacturing: Transportation" 	if scode == "SIC" 	& sec_ID == "37"   
replace subsector = "Manufacturing: Transportation" 	if scode == "NAICS" & sec_ID == "336"   

* Machinery (Machines and Instruments; Instruments could also be assigned to other) 
replace subsector = "Manufacturing: Machinery" 			if scode == "SIC" 	& (sec_ID == "35" | sec_ID == "38")  
replace subsector = "Manufacturing: Machinery" 			if scode == "NAICS" & sec_ID == "333"   

* All metal products (1933-1937, before first SIC codes)
replace subsector = "Manufacturing: All Metals" 		if scode == "SIC" 	& sec_ID == "33-38"   
replace subsector = "Manufacturing: All Metals" 		if scode == "SIC" 	& sec_ID == "37" & year < 1938 // Motor vehicles get separated out in 1936; start series in 1938 (when Metal subsectors are separately included) to maximize consistency

* Other
replace subsector = "Manufacturing: Other" 				if scode == "SIC" 	& sec_ID == "39"   
replace subsector = "Manufacturing: Other" 				if scode == "NAICS" & sec_ID == "339"   


*===== Trade subsectors =======

* Wholesale
replace subsector = "Trade: Wholesale" 						if scode == "SIC" 	& sec_ID == "50-51"   
replace subsector = "Trade: Wholesale" 						if scode == "NAICS" & sec_ID == "42" 	 

* Retail: Building Materials
replace subsector = "Trade: Retail: Building Materials" 	if scode == "SIC" 	& sec_ID == "52"  
replace subsector = "Trade: Retail: Building Materials" 	if scode == "NAICS" & sec_ID == "444"  
replace subsector = "Trade: Retail: Building Materials" 	if scode == "NAICS" & sec_ID == "443"  

* Retail: General Merchandise
replace subsector = "Trade: Retail: General Merchandise" 	if scode == "SIC" 	& sec_ID == "53"   
replace subsector = "Trade: Retail: General Merchandise" 	if scode == "NAICS" & sec_ID == "452"  

* Retail: Food
replace subsector = "Trade: Retail: Food" 					if scode == "SIC" 	& sec_ID == "54"   
replace subsector = "Trade: Retail: Food" 					if scode == "NAICS" & sec_ID == "445"   

* Retail: Autmotive
replace subsector = "Trade: Retail: Automotive" 			if scode == "SIC" 	& sec_ID == "55"  
replace subsector = "Trade: Retail: Automotive" 			if scode == "NAICS" & (sec_ID == "441" | sec_ID == "447")   

* Retail: Apparel
replace subsector = "Trade: Retail: Apparel" 				if scode == "SIC" 	& sec_ID == "56"  
replace subsector = "Trade: Retail: Apparel" 				if scode == "NAICS" & sec_ID == "448"  

* Retail: Furniture
replace subsector = "Trade: Retail: Furniture" 				if scode == "SIC" 	& sec_ID == "57"  
replace subsector = "Trade: Retail: Furniture" 				if scode == "NAICS" & sec_ID == "442"   

* Retail: Eating and Drinking Places
replace subsector = "Trade: Retail: Restaurants" 			if scode == "SIC" 	& sec_ID == "58"  
replace subsector = "Trade: Retail: Restaurants" 			if scode == "NAICS" & sec_ID == "722"  

* Miscellaneous Retail (and Wholesale)
replace subsector = "Trade: Retail: Miscellaneous" 			if scode == "SIC" 	& sec_ID == "59"  
replace subsector = "Trade: Retail: Miscellaneous" 			if scode == "SIC" 	& sec_ID == "50-59_other"  
replace subsector = "Trade: Retail: Miscellaneous" 			if scode == "NAICS" & (sec_ID == "451" | sec_ID == "453" | sec_ID == "454" | sec_ID == "446")  
replace subsector = "Trade: Retail: Miscellaneous" 			if scode == "NAICS" & sec_ID == "46" 



*===== Transport and Utilities subsectors =======

* Transportation
replace subsector = "Utilities: Transportation" 		if scode == "SIC" 		& sec_ID == "40-47"   
replace subsector = "Utilities: Transportation" 		if scode == "NAICS" 	& sec_ID == "48-49"   

* Communication
replace subsector = "Utilities: Communications" 		if scode == "SIC" 		& sec_ID == "48" 		
replace subsector = "Utilities: Communications" 		if scode == "NAICS" 	& (sec_ID == "513" | sec_ID == "515" | sec_ID == "517")  	 

* Electric, Gas and Water
replace subsector = "Utilities: Electricity and Gas" 	if scode == "SIC" 		& sec_ID == "49" 					 
replace subsector = "Utilities: Electricity and Gas" 	if scode == "NAICS" 	& (sec_ID == "22" | sec_ID == "562")  	 

*===== Finance subsectors =======

* Banking and credit
replace subsector = "Finance: Banking" 					if scode == "SIC" 		& (sec_ID == "60" | sec_ID == "61")		 
replace subsector = "Finance: Banking" 					if scode == "NAICS" 	& (sec_ID == "521" | sec_ID == "522")   
replace subsector = "Finance: Banking" 					if scode == "NAICS" 	& sec_ID == "551111" 	 
drop if sec_ID == "520"  // 520 is the sum of 521 and 522. Also, in 2000 and 2001 522 includes depository and non-depository

* Security and Commodity Brokers, Exchanges, and Services combined with Banking
replace subsector = "Finance: Banking" 					if scode == "SIC" 		& sec_ID == "62"  		 
replace subsector = "Finance: Banking"  				if scode == "NAICS" 	& sec_ID == "523" 		 

* Insurance
replace subsector = "Finance: Insurance" 				if scode == "SIC" 		& (sec_ID == "63" | sec_ID == "64")
replace subsector = "Finance: Insurance" 				if scode == "NAICS" 	& sec_ID == "524" 

* Real Estate
replace subsector = "Finance: Real Estate" 				if scode == "SIC" 		& sec_ID == "65"   
replace subsector = "Finance: Real Estate" 				if scode == "NAICS" 	& (sec_ID == "531" | sec_ID == "533")
  
* Holding companies and other (misc)
replace subsector = "Finance: Holding Companies" 		if scode == "SIC" 		& sec_ID == "67"  
replace subsector = "Finance: Holding Companies" 		if scode == "SIC" 		& sec_ID == "60-67_other" 

replace subsector = "Finance: Holding Companies" 		if scode == "NAICS" 	& sec_ID == "551112"  
replace subsector = "Finance: Holding Companies" 		if scode == "NAICS" 	& sec_ID == "525" 	 



*===== Services subsectors =======

* Hotels
replace subsector = "Services: Hotels" 					if scode == "SIC" 	& sec_ID == "70" 		 
replace subsector = "Services: Hotels" 					if scode == "NAICS" & sec_ID == "721" 	 

* Entertainment
replace subsector = "Services: Entertainment" 			if scode == "SIC" 	& (sec_ID == "78" | sec_ID == "79")
replace subsector = "Services: Entertainment" 			if scode == "NAICS" & sec_ID == "71" 	 
replace subsector = "Services: Entertainment" 			if scode == "NAICS" & sec_ID == "512" 	 


* Personal Services
replace subsector = "Services: Personal" 				if scode == "SIC" 	& sec_ID == "72" 	 
replace subsector = "Services: Personal" 				if scode == "NAICS" & sec_ID == "812" 	 

* Personal and Hotels
replace subsector = "Services: Personal and Hotels" 	if scode == "SIC" 	& sec_ID == "72" & year < 1940


* SIC 73; NAICS: 54, 514, 516, 518, 519
replace subsector = "Services: Business" 				if scode == "SIC" 	& sec_ID == "73" 	 
replace subsector = "Services: Business" 				if scode == "NAICS" & sec_ID == "54" 		 
replace subsector = "Services: Business" 				if scode == "NAICS" & (sec_ID == "514" | sec_ID == "516" | sec_ID == "518" | sec_ID == "519") 

* Repair and Maintenance
replace subsector = "Services: Repair" 					if scode == "SIC"	& (sec_ID == "75" | sec_ID == "76")
replace subsector = "Services: Repair" 					if scode == "NAICS" & sec_ID == "811" 
replace subsector = "Services: Repair"  				if scode == "NAICS" & sec_ID == "532100" 	 

* Other
replace subsector = "Services: Miscellaneous" 			if scode == "SIC" 	& sec_ID == "89" 	 
replace subsector = "Services: Miscellaneous" 			if scode == "NAICS" & sec_ID == "813" 		 
replace subsector = "Services: Miscellaneous" 			if scode == "NAICS" & (sec_ID == "61" | sec_ID == "62")

* Miscellaneous or Business
replace subsector = "Services: Miscellaneous" 			if scode == "NAICS" & sec_ID == "561" 		  
replace subsector = "Services: Miscellaneous" 			if scode == "NAICS" & (sec_ID == "532215" | sec_ID == "532400")  



*======== Combine subsectors further to map into BEA sectors ==============
gen 	subsector_BEA = subsector
replace subsector_BEA = "Agriculture" 		if sector_main == "Agriculture"	
replace subsector_BEA = "Construction" 		if sector_main == "Construction" 
replace subsector_BEA = "" 					if subsector == "Construction: Buildings" ///
											| subsector == "Construction: Heavy Construction" ///
											| subsector == "Construction: Special Trade" 
replace subsector_BEA = "Services: Other" 	if subsector == "Services: Repair" ///
											| subsector == "Services: Miscellaneous"
replace subsector_BEA = "Mining: Other" 	if subsector == "Mining: Metal" ///
											| subsector == "Mining: Coal"  ///
											| subsector == "Mining: Non Metallic"
replace subsector_BEA = "Trade: Retail" 	if subsector == "Trade: Retail: Apparel" ///
											| subsector == "Trade: Retail: Automotive"  ///
											| subsector == "Trade: Retail: Building Materials" ///
											| subsector == "Trade: Retail: Food" ///
											| subsector == "Trade: Retail: Furniture" ///
											| subsector == "Trade: Retail: General Merchandise" ///
											| subsector == "Trade: Retail: Miscellaneous"
replace subsector_BEA = "Manufacturing: Apparel" if  subsector == "Manufacturing: Textile Mills" ///
											| subsector == "Manufacturing: Apparel" ///
											| subsector == "Manufacturing: Leather"
replace subsector_BEA = "Manufacturing: Chemicals" if subsector == "Manufacturing: Chemicals" ///
											| subsector == "Manufacturing: Petroleum"
replace subsector_BEA = "Manufacturing: Metals" if subsector == "Manufacturing: Fabricated Metals" ///
											| subsector == "Manufacturing: Primary Metals" 	
replace subsector_BEA = "Manufacturing: Wood" if subsector == "Manufacturing: Wood" ///
											| subsector == "Manufacturing: Furniture"

											
order year sector_main subsector thres_low
sort year sector_main subsector thres_low


*======== Net capital assets
gen double		temp1 = -negcassets
gen double		temp3 = -negintangibles
egen double 	temp2 = rowtotal(cassets intangibles temp1 temp3)
replace 		cassets = temp2
replace 		cassets = . 													if cassets == 0 & year < 1931
drop 			temp1 temp2 temp3 intangibles negcassets negintangibles


*************** Item preparation *******************
 
local vars number assets treceipts breceipts ninc cassets  

* Generate separate variables for the totals
foreach var of local vars {
	* Align units
	replace `var' = `var' * 1000 if "`var'" != "number" & (year >= 2000 | 	///
					year == 1965 | year == 1966 | year == 1967 | ///
					year == 1968 | year == 1969 | year == 1970 | year == 1971 | ///
					year == 1973 | year == 1974 | year == 1975 | ///
					year == 1976 | year == 1977 | year == 1978 | year == 1979 | ///
					year == 1980 | year == 1985 | year == 1986 | year == 1987 | ///
					year == 1988 | year == 1989 | year == 1990)
	
	* Stated totals
	gen double 										temp = `var' 					if thres_low == "Total"
	bysort sector year: egen double					`var'_total_stated = min(temp)
	drop 											temp
	
	* Computed totals (add up stated totals)
	bysort sector year thres_low: egen double 		`var'_total = total(`var'_total_stated) 
	replace 										`var'_total = . 				if `var'_total == 0
	
	* Computed totals (add up brackets)
	bysort sector year: egen double 				`var'_total_alt = total(`var')  if thres_low != "Total"
	replace 										`var'_total_alt = . 			if `var'_total_alt == 0
	
	//gen double 									`var'_total_dif = `var'_total_stated - `var'_total_alt

	* Replace with adding up brackets (when no bracket deletions)
	replace											`var'_total = `var'_total_alt 	if bracket_deletion_total != "yes"   
}

drop 																			if thres_low == "Total"
destring 											thres_low, replace

cap drop 											*_stated *_alt

drop if sector_main == "" & subsector == "" & sector_main2digit == ""

// Do not use these variables outside main sectors 
foreach item in treceipts breceipts ninc cassets {
    replace 										`item' = . 					if sector_main == ""
    replace 										`item'_total = . 			if sector_main == ""
}	
 

save "$OUTPUT/temp/by_sector_and_assets.dta", replace


/* Main sector aggregates with coarser industry harmonization */

// Sum over 2 digit subsectors (to have totals for alternative harmonization)
foreach var in number assets {
	
	bysort sector_main2digit year thres_low: egen double	`var'_total2digit = total(`var'_total)
	
}

collapse (lastnm) *_total2digit, by(sector_main2digit year)

rename 		sector_main2digit sector_main
keep 		sector_main year number_total2digit assets_total2digit 
order 		sector_main year number_total2digit assets_total2digit 
drop if 	sector_main == "" | sector_main == "Other"

label var sector_main 				"Main Sector"
label var year 						"Year"
label var number_total2digit 		"Number, all (sectors classfified using two digit SIC/NAICS codes)" 
label var assets_total2digit 		"Assets, all (sectors classfified using two digit SIC/NAICS codes)" 

save 		"$OUTPUT/soi/by_2digitsector_totals.dta", replace



*===============================================================================
*=============== Prepare main sector file ======================================
*===============================================================================

use "$OUTPUT/temp/by_sector_and_assets.dta", clear

// Keep only the sectors that are needed to construct the "main sectors"
order year sector_main

/* Aggregate to main sectors */

// "Sum" bracket deletions at main sector level 
encode bracket_deletion_total, 	gen(ind_bracket_deletion_total)
encode bracket_deletion, 		gen(ind_bracket_deletion)
bysort sector_main year thres_low: egen 	temp = max(ind_bracket_deletion)
bysort sector_main year thres_low: egen 	temp_total = max(ind_bracket_deletion_total)
replace 									bracket_deletion_total 	= "yes" if temp_total == 2
replace 									bracket_deletion 		= "yes" if temp == 2
drop 										temp temp_total ind_bracket_deletion_total ind_bracket_deletion_total



// Main sector totals
local vars number assets treceipts breceipts ninc cassets

foreach var of local vars {	
	
	* Sum over sectors to have data for main sectors
	bysort sector_main year thres_low: egen double 			`var'_total_temp = total(`var'_total)
	replace 												`var'_total = `var'_total_temp 			if `var'_total_temp != 0
	drop 													`var'_total_temp 
	
	bysort sector_main year thres_low: egen double 			`var'_temp = total(`var')
	replace 												`var' = `var'_temp 						if `var'_temp != 0 
	replace 												`var' = . 								if bracket_deletion == "yes"
	drop 													`var'_temp
		
}

duplicates drop 											sector_main year thres_low, force
drop 														sector subsector


/* Deal with deleted brackets */

// Construct interval variable between the deleted brackets
sort 										sector_main year thres_low
gen 										temp_low_to_high = 1 				if bracket_deletion == "yes"
by sector_main year: carryforward 			temp_low_to_high, replace
gsort 										sector_main year -thres_low
gen 										temp_high_to_low = 1 				if bracket_deletion == "yes"
by sector_main year: carryforward 			temp_high_to_low, replace
gen 										interval = 1 						if temp_low_to_high == 1 & temp_high_to_low == 1
drop 										temp_low_to_high temp_high_to_low

// We combine intervals into one bracket and back out their values as the difference between the total and the sum of the other brackets
sort 										sector_main year thres_low
drop 										if sector_main[_n] == sector_main[_n-1] & year[_n] == year[_n-1] & interval[_n] == interval[_n-1] & interval == 1


local vars number assets treceipts breceipts ninc cassets 

* Sum over brackets outside of the interval
foreach var of local vars {	
	bysort sector_main year: egen double 	`var'_temp = total(`var') 			if bracket_deletion_total == "yes" & interval == .
	bysort sector_main year: egen double 	`var'_temp2 = mean(`var'_temp)
	replace 								`var' = `var'_total - `var'_temp2 	if interval == 1 & `var'_temp2 != .
	replace 								`var' = `var'_total 				if interval == 1 & `var'_temp2 == .
	drop 									`var'_temp `var'_temp2
}	
drop 										interval 
 	
sort 										sector_main year thres_low


// Drop empty brackets
drop 																			if number == 0 | number == .

/* Some brackets are not "within" bounds */
// This seems to be largely because larger brackets are not reported separately and their values are included in the lower brackets  
// A natural solution is therefore to combine brackets whenever there is an issue 

* Identify probematic brackets
sort 										sector_main year thres_low
gen double									av = assets / number

* Case average is above the threshold (more common)
by sector_main year: gen 					d_temp  = 1 						if av[_n] > thres_low[_n+1] & av != . 		& av[_n+1] != .  & av[_n+1] != 0
by sector_main year: gen 					d_temp2 = 1 						if av[_n-1] > thres_low[_n] & av[_n-1] != . & av[_n] != .  & av[_n] != 0

* Case average is below the threshold (less common)
by sector_main year: gen 					d_temp3 = 1 						if av[_n]  < thres_low[_n] 	 & av != . 		& av[_n] != .  	& av[_n] != 0
by sector_main year: gen	 				d_temp4 = 1 						if av[_n+1] < thres_low[_n+1] & av[_n+1] != . & av[_n+1] != .   & av[_n+1] != 0

gen 										d_comb = 1 							if d_temp == 1 | d_temp2 == 1 | d_temp3 == 1 | d_temp4 == 1
// There can be several cases of this 
by sector_main year: gen 					newid = 1 							if d_comb[_n] == 1 & d_comb[_n-1] == .
by sector_main year: replace 				newid = sum(newid)
replace 									d_comb = newid 						if d_comb == 1


local vars number assets treceipts breceipts ninc cassets 

// Sum bracket with next highest bracket
foreach var of local vars {	
	bysort sector_main year d_comb: egen double 	`var'_temp = total(`var'), missing
	replace 										`var' = `var'_temp 			if d_comb != .
	drop 											`var'_temp
}
bysort sector_main year d_comb: egen double 		thres_low_temp = min(thres_low), missing
replace 											thres_low = thres_low_temp 	if d_comb != .
drop																			if sector_main[_n] == sector_main[_n-1] & year[_n] == year[_n-1] & d_comb[_n] == d_comb[_n-1] & d_comb != .
drop 												d_comb d_temp d_temp2 d_temp3 d_temp4 av thres_low_temp

drop 		subsector

tempfile 	by_sector_and_assets_final
save 		"`by_sector_and_assets_final'", replace

/* Main sector output */

drop 		if sector_main == ""
drop 		if sector_main == "Other"

keep 		sector_main year thres_low number number_total assets assets_total treceipts treceipts_total breceipts breceipts_total ///
			cassets cassets_total ninc ninc_total bracket_deletion bracket_deletion_total			
		
order 		sector_main year thres_low number number_total assets assets_total treceipts treceipts_total breceipts breceipts_total ///
			cassets cassets_total ninc ninc_total bracket_deletion bracket_deletion_total			

sort 		sector_main year thres_low

label var year						"Year"
label var sector_main				"Main sector"
label var thres_low					"Bin threshold low"
label var number 					"Number" 
label var number_total 				"Number, all" 
label var assets 					"Assets"
label var assets_total 				"Assets, all"
label var cassets 					"Capital assets"
label var cassets_total 			"Capital assets, all"
label var ninc 						"Net income" 
label var ninc_total 				"Net income, all"
label var treceipts 				"Total receipts"
label var treceipts_total 			"Total receipts, all"
label var breceipts 				"Business receipts"
label var breceipts_total 			"Business receipts, all"
label var bracket_deletion 			"Combined bracket"
label var bracket_deletion_total 	"Sector-year with combined bracket"

save 		"$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", replace




*===============================================================================
*================ Prepare subsector files ======================================
*===============================================================================

local secs subsector subsector_BEA
foreach s of local secs {

	/* Load data */

	clear all
	use "$OUTPUT/temp/by_sector_and_assets.dta", replace
	replace subsector = `s'

	// Construct totals for the "main sectors" to check for completeness
	split 	subsector, parse(:)
	gen 	sector_top = sector_main
	replace sector_top = subsector1 if sector_top == ""
	drop 	subsector1 subsector2 subsector3


	local vars number assets treceipts breceipts ninc cassets 
	foreach v of local vars {
		gen 											temp = `v'_total 		if sector_top == sector_main
		bysort year sector_top thres_low: egen double `v'_total_sector_main = sum(temp)
		drop 											temp
	}

	drop 												sector_main


	// Keep only the sectors that are needed to construct the subsectors
	order year subsector
	keep if subsector != ""


	// "Sum" bracket deletions at the subsector level 
	encode bracket_deletion_total, gen(ind_bracket_deletion_total)
	encode bracket_deletion, gen(ind_bracket_deletion)
	bysort subsector year thres_low: egen 	temp = max(ind_bracket_deletion)
	bysort subsector year: egen 			temp_total = max(ind_bracket_deletion_total)
	replace 								bracket_deletion_total = "yes" 		if temp_total == 2
	replace 								bracket_deletion = "yes" 			if temp == 2
	drop 									temp temp_total ind_bracket_deletion_total ind_bracket_deletion_total


	// Subsector totals
	local vars number assets treceipts breceipts ninc cassets 

	foreach var of local vars {
		
		* Sum over sectors to have data for subsectors
		bysort subsector year thres_low: egen double 	`var'_total_temp = total(`var'_total), missing
		bysort subsector year: egen double 				`var'_total_temp2 = max(`var'_total_temp)
		replace 										`var'_total = `var'_total_temp2  
		drop 											`var'_total_temp* 
		
		bysort subsector year thres_low: egen double 	`var'_temp = total(`var'), missing
		replace 										`var' = `var'_temp  
		replace 										`var' = . 				if bracket_deletion == "yes"
		drop 											`var'_temp		
		
	}
	
	duplicates drop 									subsector year thres_low, force
	drop 												sector
	rename 												sector_top sector_main

	/* Deal with deleted brackets */

	// Construct interval variable between the deleted brackets
	gen 								temp_low_to_high = 1 					if bracket_deletion == "yes"
	by subsector year: carryforward 	temp_low_to_high , replace
	gsort 								subsector year -thres_low
	gen 								temp_high_to_low = 1 					if bracket_deletion == "yes"
	by subsector year: carryforward 	temp_high_to_low , replace
	gen 								interval = 1 							if temp_low_to_high == 1 & temp_high_to_low == 1
	drop 								temp_low_to_high temp_high_to_low

	// We combine intervals into one bracket and back out their values as the difference between the total and the sum of the other brackets

	sort 								subsector year thres_low
	drop 								if subsector[_n] == subsector[_n-1] & year[_n] == year[_n-1] & interval[_n] == interval[_n-1] & interval == 1

	local vars number assets treceipts breceipts ninc cassets 
	
	// Sum over brackets outside of the interval
	foreach var of local vars {	
		bysort subsector year: egen double 	`var'_temp = total(`var') 			if bracket_deletion_total == "yes" & interval == . , missing
		bysort subsector year: egen double 	`var'_temp2 = mean(`var'_temp)
		replace 							`var' = `var'_total - `var'_temp2 	if interval == 1 & `var'_temp2 != .
		replace 							`var' = `var'_total 				if interval == 1 & `var'_temp2 == .
		drop 								`var'_temp `var'_temp2
	}	
	drop 									interval 
		
	sort 									subsector year thres_low

	local vars assets number
	foreach var of local vars {
		by subsector year: egen double 		`var'_total_alt = total(`var') , missing
	}


	// Dummy variable to drop sectors with incomplete data (when brackets do not add up to the total)
	cap drop 								check
	gen 									check = assets_total / assets_total_alt 	   // Check if the bracket adjustment worked
	gen 									check_number = number_total / number_total_alt // Check if the bracket adjustment worked
	bysort year subsector: egen 			check_temp = max(check)
	gen 									sample = 1 							if check_temp < 1.1 & check_temp != .
	replace 								sample = 1 							if year == 1962 // many outliers / not enough brackets

	// Drop empty brackets
	drop 																		if number == 0 | number == .
	
	/* Some brackets are not "within" bounds */
	// This seems to be largely because larger brackets are not reported separately and their values are included in the lower brackets  
	// A natural solution is therefore to combine brackets whenever there is an issue 

	* Identify probematic brackets
	sort 									subsector year thres_low
	gen double								av = assets / number
	by subsector year: gen 					d_temp = 1  						if av[_n] > thres_low[_n+1] & av != . & av[_n+1] != . & av[_n+1] != 0
	by subsector year: gen 					d_temp2 = 1 						if av[_n-1] > thres_low[_n] & av[_n-1] != . & av[_n] != . & av[_n] != 0


	* Case average is below the threshold (less common)
	by subsector year: gen 					d_temp3 = 1 						if av[_n] < thres_low[_n] & av != . & av[_n] != . & av[_n] != 0
	by subsector year: gen 					d_temp4 = 1 						if av[_n+1] < thres_low[_n+1] & av[_n+1] != . & av[_n+1] != . & av[_n+1] != 0

	gen 									d_comb = 1 							if d_temp == 1 | d_temp2 == 1 | d_temp3 == 1 | d_temp4 == 1
	// There can be several cases of this  
	by subsector year: gen 					newid = 1 							if d_comb[_n] == 1 & d_comb[_n-1] == .
	by subsector year: replace 				newid = sum(newid)
	replace 								d_comb = newid 						if d_comb == 1


	local vars number assets treceipts breceipts ninc cassets  
		
	// Sum bracket with next highest bracket
	foreach var of local vars {	
		bysort subsector year d_comb: egen double 	`var'_temp = total(`var'), missing
		replace 									`var' = `var'_temp 			if d_comb != .
		drop 										`var'_temp
	}
	bysort subsector year d_comb: egen double 		thres_low_temp = min(thres_low), missing
	replace 										thres_low = thres_low_temp 	if d_comb != .
	drop 											if subsector[_n] == subsector[_n-1] & year[_n] == year[_n-1] & d_comb[_n] == d_comb[_n-1] & d_comb != .
	drop 											d_comb d_temp d_temp2 d_temp3 d_temp4 av thres_low_temp

	sort 											subsector year
	tempfile	by_`s'
	save 		"`by_`s''", replace

}

/* Subsectors output */

use `by_subsector_BEA.dta', replace

keep 	subsector_BEA year thres_low number number_total assets assets_total bracket_deletion bracket_deletion_total 		
order 	subsector_BEA year thres_low number number_total assets assets_total bracket_deletion bracket_deletion_total 		

// Drop temporary sectors***
drop 	 if subsector_BEA ==	"Manufacturing: All Metals"
drop 	 if subsector_BEA ==	"Services: Personal and Hotels"
cap drop if subsector_BEA ==	"Finance: Holding Companies and Other"
cap drop if subsector_BEA ==	"Finance: Holding Companies"
cap drop if subsector_BEA ==	"Manufacturing: Rubber"
// Real Estate Adjustment (drop recent years with REITs)***
drop 	 if subsector_BEA ==	"Finance: Real Estate" & year >= 2007 

sort 	subsector_BEA year thres_low

label var year						"Year"
label var subsector_BEA				"Subsector"
label var thres_low					"Bin threshold low"
label var number 					"Number" 
label var number_total 				"Number, all" 
label var assets 					"Assets"
label var assets_total 				"Assets, all"
label var bracket_deletion 			"Combined bracket"
label var bracket_deletion_total 	"Sector-year with combined bracket"

save 	"$OUTPUT/soi/brackets/subsector_brackets_assets_R5.dta", replace


/* Granular subsectors output */

use `by_subsector.dta', replace

keep 	subsector year thres_low number number_total assets assets_total bracket_deletion bracket_deletion_total 		
order 	subsector year thres_low number number_total assets assets_total bracket_deletion bracket_deletion_total

keep if strpos(subsector, "Mining") == 1 | strpos(subsector, "Trade") == 1 

sort 	subsector year thres_low

label var year						"Year"
label var subsector					"Subsector"
label var thres_low					"Bin threshold low"
label var number 					"Number" 
label var number_total 				"Number, all" 
label var assets 					"Assets"
label var assets_total 				"Assets, all"
label var bracket_deletion 			"Combined bracket"
label var bracket_deletion_total 	"Sector-year with combined bracket"

save 	"$OUTPUT/soi/brackets/subsector_gran_brackets_assets_R5.dta", replace

capture erase "$OUTPUT/temp/by_sector_and_assets_2000_2003.dta"
capture erase "$OUTPUT/temp/by_sector_and_assets_2004_2013.dta"
capture erase "$OUTPUT/temp/source_book_NA.dta"
capture erase "$OUTPUT/temp/by_sector_and_assets.dta"
capture erase "$OUTPUT/temp/item_list_SB.dta"
capture erase "$OUTPUT/temp/sector_list_SIC.dta"
capture erase "$OUTPUT/temp/sector_list_SIC_unique.dta"
capture erase "$OUTPUT/temp/sector_list_NAICS_3digit.dta"
capture erase "$OUTPUT/temp/sector_list_NAICS_3digit_unique.dta"
capture erase "$OUTPUT/temp/sector_list_NAICS_3digit_uniqueID.dta"


