/************ Function ************/

*This file combines cleaned tabulations into KMZ_brackets_R5.xlsx and top share estimates into KMZ_topshares_R5.xlsx


clear all


*==============================================
* Prepare KMZ_brackets_R5.xlsx
*==============================================

// Table notes
insobs 14
gen notes = ""
gen n = _n
replace notes = "Cleaned size bracket tabulations" 															if n == 1
replace notes = "==========================================================================" 				if n == 2
replace notes = "" 																							if n == 3
replace notes = "agg_brackets_receipts: aggregate size tabulations by receipts" 							if n == 4
replace notes = "agg_brackets_assets: aggregate size tabulations by assets" 								if n == 5
replace notes = "agg_brackets_ninc: aggregate size tabulations by net income" 								if n == 6
replace notes = "agg_brackets_capital: aggregate size tabulations by capital" 								if n == 7
replace notes = "sector_brackets_assets: main sector size tabulations by assets" 							if n == 8
replace notes = "sector_brackets_receipts: main sector size tabulations by receipts" 						if n == 9
replace notes = "sector_brackets_ninc: main sector size tabulations by net income" 							if n == 10
replace notes = "sector_type_brackets_receipts: main sector size tabulations by receipts and legal form" 	if n == 11
replace notes = "agg_type_brackets_assets: aggregate size tabulations by assets and legal form" 			if n == 12
replace notes = "subsector_brackets_assets: subsector size tabulations by assets" 							if n == 13
replace notes = "subsector_gran_brackets_assets: granular subsector size tabulations by assets" 			if n == 14

export excel notes using "$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("Notes") replace 

		
***********************
* Aggregate tabulations

* Receipts
use 						"$OUTPUT/soi/brackets/agg_brackets_receipts_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("agg_brackets_receipts") firstrow(varlab) keepcellfmt
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("agg_brackets_receipts") firstrow(var) cell(A2) keepcellfmt sheetmodify


* Assets
use 						"$OUTPUT/soi/brackets/agg_brackets_assets_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("agg_brackets_assets") firstrow(varlab) keepcellfmt sheetmodify 
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("agg_brackets_assets") firstrow(var) cell(A2) keepcellfmt sheetmodify


* Net income
use 						"$OUTPUT/soi/brackets/agg_brackets_ninc_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("agg_brackets_ninc") firstrow(varlab) keepcellfmt sheetmodify 
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("agg_brackets_ninc") firstrow(var) cell(A2) keepcellfmt sheetmodify


* Capital
use 						"$OUTPUT/soi/brackets/agg_brackets_capital_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("agg_brackets_capital") firstrow(varlab) keepcellfmt sheetmodify 
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("agg_brackets_capital") firstrow(var) cell(A2) keepcellfmt sheetmodify
		
		
		
*************************
* Main sector tabulations 

* By assets
use 						"$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("sector_brackets_assets") firstrow(varlab) keepcellfmt sheetmodify 
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("sector_brackets_assets") firstrow(var) cell(A2) keepcellfmt sheetmodify


* By receipts		
use 						"$OUTPUT/soi/brackets/sector_brackets_receipts_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("sector_brackets_receipts") firstrow(varlab) keepcellfmt sheetmodify 
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("sector_brackets_receipts") firstrow(var) cell(A2) keepcellfmt sheetmodify


* By net income		
use 						"$OUTPUT/soi/brackets/sector_brackets_ninc_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("sector_brackets_ninc") firstrow(varlab) keepcellfmt sheetmodify 
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("sector_brackets_ninc") firstrow(var) cell(A2) keepcellfmt sheetmodify




***************************************************
* Main sector, by type of organizations tabulations
use 						"$OUTPUT/soi/brackets/sector_type_brackets_receipts_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("sector_type_brackets_receipts") firstrow(varlab) keepcellfmt sheetmodify 
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("sector_type_brackets_receipts") firstrow(var) cell(A2) keepcellfmt sheetmodify



*************************************************
* Aggregate, by type of organizations tabulations
use 						"$OUTPUT/soi/brackets/agg_type_brackets_assets_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("agg_type_brackets_assets") firstrow(varlab) keepcellfmt sheetmodify 
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("agg_type_brackets_assets") firstrow(var) cell(A2) keepcellfmt sheetmodify


***********************
* Subsector tabulations
use 						"$OUTPUT/soi/brackets/subsector_brackets_assets_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("subsector_brackets_assets") firstrow(varlab) keepcellfmt sheetmodify 
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("subsector_brackets_assets") firstrow(var) cell(A2) keepcellfmt sheetmodify
		

********************************
* Granular subsector tabulations 
use 						"$OUTPUT/soi/brackets/subsector_gran_brackets_assets_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("subsector_gran_brackets_assets") firstrow(varlab) keepcellfmt sheetmodify 
export excel _all using 	"$OUTPUT/soi/brackets/KMZ_brackets_R5.xlsx", sheet("subsector_gran_brackets_assets") firstrow(var) cell(A2) keepcellfmt sheetmodify
	



*==============================================
* Prepare KMZ_topshares_R5.xlsx
*==============================================

clear all

// Table notes
insobs 11
gen notes = ""
gen n = _n
replace notes = "Cleaned estimated top shares" 																if n == 1
replace notes = "==========================================================================" 				if n == 2
replace notes = "" 																							if n == 3
replace notes = "agg: aggregate top share estimates"							 							if n == 4
replace notes = "agg_adj: aggregate top share estimates including returns with missing balance sheets " 	if n == 5
replace notes = "sector: main sector top share estimates" 													if n == 6
replace notes = "sector_topN: main sector top N share estimates" 											if n == 7
replace notes = "sector_type: main sector top share estimates by legal form" 								if n == 8
replace notes = "subsector: subsector top share estimates" 													if n == 9
replace notes = "subsector_gran: granular subsector top share estimates" 									if n == 10
replace notes = "manufacturing: manufacturing top 100 share estimates for early decades" 					if n == 11

export excel notes using "$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("Notes") replace 


***********************************
* Aggregate concentration estimates
use 						"$OUTPUT/soi/topshares/agg_concent_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("agg") firstrow(varlab) keepcellfmt
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("agg") firstrow(var) cell(A2) keepcellfmt sheetmodify

	
	
***************************************************************
* Aggregate concentration estimates with missing balance sheets
use 						"$OUTPUT/soi/topshares/agg_concent_adj_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("agg_adj") firstrow(varlab) keepcellfmt sheetmodify 	
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("agg_adj") firstrow(var) cell(A2) keepcellfmt sheetmodify



*************************************
* Main sector concentration estimates
use 						"$OUTPUT/soi/topshares/sector_concent_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("sector") firstrow(varlab) keepcellfmt sheetmodify 
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("sector") firstrow(var) cell(A2) keepcellfmt sheetmodify


	
*********************************************************
* Main sector concentration estimates, top N and noncorps
use 						"$OUTPUT/soi/topshares/sector_concent_topN_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("sector_topN") firstrow(varlab) keepcellfmt sheetmodify 	
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("sector_topN") firstrow(var) cell(A2) keepcellfmt sheetmodify
	
	
	
*********************************************************
* Main sector concentration estimates by type of business
use 						"$OUTPUT/soi/topshares/sector_type_concent_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("sector_type") firstrow(varlab) keepcellfmt sheetmodify 	
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("sector_type") firstrow(var) cell(A2) keepcellfmt sheetmodify



***********************************
* Subsector concentration estimates
use 						"$OUTPUT/soi/topshares/subsector_concent_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("subsector") firstrow(varlab) keepcellfmt sheetmodify 	
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("subsector") firstrow(var) cell(A2) keepcellfmt sheetmodify


			
*****************************************************************
* Granular subsector concentration estimates for Trade and Mining		
use 						"$OUTPUT/soi/topshares/subsector_gran_concent_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("subsector_gran") firstrow(varlab) keepcellfmt sheetmodify 	
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("subsector_gran") firstrow(var) cell(A2) keepcellfmt sheetmodify
			
			

***********************************************
* Manufacturing top 100 concentration estimates
use 						"$OUTPUT/soi/topshares/manufacturing_concent_R5.dta", clear
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("manufacturing") firstrow(varlab) keepcellfmt sheetmodify 	
export excel _all using 	"$OUTPUT/soi/topshares/KMZ_topshares_R5.xlsx", sheet("manufacturing") firstrow(var) cell(A2) keepcellfmt sheetmodify
		

			
