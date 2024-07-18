/************ Function ************/

*This file makes Figure IA6 of the paper on corporations relative to noncorporations

/************ Source ************/

*Receipts of nonfinancial and manufacturing corporations and noncorporations: "input/soi/digitized/noncorp_totals_R5.dta"  
*Assets of nonfinancial corporations and noncorporations: "output/other/fof.dta" compiled by code/clean/fof.py
*Value added of manufacturing corporations and noncorporations: "input/histstat/Dd903-904.xls" for the early years and "$input/census/manufacturing_corp_value_added.xlsx" for 1997 onwards 

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

***********************************************
**                  Panel A                  **
***********************************************

// SOI data on receipts
use "$DATA/soi/digitized/noncorp_totals_R5.dta", clear

keep if sector_main == "Nonfinancial"

// Merge Flow of Funds data on assets  
merge 1:1 year using "$OUTPUT/other/fof.dta", nogen keep(1 3)

twoway 	(line corpsh year) (line corp_at_shr year if corpsh != ., lp(dash) lcolor(midblue)) if year >= 1945, ///
		ytitle("Share") xtitle("") ///
		ylabel(0.2(0.2)1, format(%03.1f)) xlabel(1950(20)2010) ///
		legend(label(1 "Corporate Receipt Share (SOI)") label(2 "Corporate Asset Share (FoF)") cols(2) size(9.5pt) ///
		symxsize(*0.7) colgap(*1.5) region(lwidth(none))) 
graph export "$FIGURE/FigureIA6_PanelA.pdf", replace 


***********************************************
**                  Panel B                  **
***********************************************

// Historical data before 1997
import excel "$DATA/histstat/Dd903-904.xls", sheet("Dd903-904") firstrow clear

rename 		ValueAdded_Dd904_Percent msh_va
rename 		Year year
destring, replace

tempfile 	temp	
save 		"`temp'"

// After 1997
import excel "$DATA/census/manufacturing_corp_value_added.xlsx", sheet("Sheet1") firstrow clear

gen double	msh_va = corporatevalueadded / allvalueadded * 100 
keep 		msh_* year
destring, replace

merge 1:1 year using "`temp'", nogen
tempfile 	temp	
save 		"`temp'"

// Plot with SOI data 	
use "$DATA/soi/digitized/noncorp_totals_R5.dta", clear

keep if sector_main == "Manufacturing"	
merge 1:1 year using "`temp'", nogen

replace		msh_va = msh_va / 100
sort 		year

twoway 	(connected corpsh year if year >= 1946 & sector_main == "Manufacturing", msize(medsmall))  ///
		(connected msh_va year, lp(dash) color(midblue) msize(medsmall)) if year >= 1899 & year <= 2013, ///
		ytitle("Share") xtitle("") ///
		ylabel(0.2 (0.2) 1, format(%03.1f)) xlabel(1900(20)2020) ///
		legend(label(1 "Corporate Receipt Share (SOI)") label(2 "Corporate Value Added Share (Census)") cols(2) size(9.5pt) ///
		symxsize(*0.7) colgap(*1.5) region(lwidth(none))) 
graph export "$FIGURE/FigureIA6_PanelB.pdf", replace  