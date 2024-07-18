/************ Function ************/

*This file makes Figure IA9 of the paper on top 100 asset shares in manufacturing 

/************ Source ************/

*FTC: "$DATA/top_lists/FTC.xlsx"
*Collins-Preston: "$DATA/top_lists/Collins_Preston.xlsx"
*Chandler: "$DATA/top_lists/Chandler.xlsx"
*SOI: "output/soi/topshares/manufacturing_concent_R5.dta" compiled by "code/clean/compute_concentration_manufacturing.do"
*Total corporate capital stock for early years: "$DATA/soi/digitized/early_totals_R5.dta"
**Value added of manufacturing corporations and noncorporations: "input/histstat/Dd903-904.xls" for the early years and "$input/census/manufacturing_corp_value_added.xlsx" for 1997 onwards 

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

/* Merge in Top Firm Lists */

// FTC list, top 100
import excel "$DATA/top_lists/FTC.xlsx", sheet("Sheet1") clear

rename 						A year
gen 						ftc100_sh = B
drop 																			if _n <= 3
destring, replace
keep 						year ftc*

tempfile 					ftc
save 						"`ftc'"

// Collins-Preston, top 100
import excel "$DATA/top_lists/Collins_Preston.xlsx", sheet("Sheet1") clear

keep 						B D F H J L
drop 																			if _n == 3 	// drop assets and rank header
destring, replace

foreach v of varlist B D F H J L {
	egen double				`v'_sum = sum(`v') 									if _n > 2 	// sum the top 100 list 
	replace 				`v'_sum = `v' 										if _n <= 2 	// carry over the years 
	drop 					`v'
}
keep 																			if _n <= 3 	// only keep one sum per year
drop 																			if _n == 1 	// empty row 

sxpose, clear force
rename 						_var1 year
rename 						_var2 cp_top100
destring, replace

tempfile cp	
save "`cp'"

// Chandler, top 100 in 1917
foreach year in 1917 1930 1948 {
	import excel "$DATA/top_lists/Chandler.xlsx", sheet("`year'") clear firstrow
	keep 																		if Assets != .
	destring 				Rank, replace
	keep 																		if Rank <= 100
	collapse (sum) Assets 

	gen 					year = `year'
	ren 					Assets chandler_top100

	tempfile 				chandler`year'
	save 					"`chandler`year''"
}


/* Merge in Denominator Info for Scaling */

// Total asset estimates based on SOI data for 1909-1925            
use "$DATA/soi/digitized/early_totals_R5.dta", clear

// Capital ratios for both Manufacturing and Industrials is 0.71 in 1926
gen double					assets_Industrials 	 = cap_Industrials / 0.71
gen double 					assets_Manufacturing = cap_Manufacturing / 0.71

keep 						year assets_Industrials assets_Manufacturing
tsset						year
tsfill 						
ipolate 					assets_Industrials year, gen(assets_Industrials_lipol)
ipolate 					assets_Manufacturing year, gen(assets_Manufacturing_lipol)

tempfile					soiearly	
save 						"`soiearly'"

// Manufacturing and industrial total 
use "$DATA/soi/digitized/corp_totals_pre1959_R5.dta", clear

*industrial: manufacturing + mining
bysort year: egen double	assets_total_Industrials = sum(assets_total) 		if sector_main == "Manufacturing" | sector_main == "Mining"
keep 																			if sector_main == "Manufacturing"
replace 					assets_total_Industrials = . 						if assets_total_Industrials == 0
keep year 					assets_total assets_total_Industrials

tempfile 					industrials
save 						"`industrials'"

// Histstat, corporate value added share
import excel "$DATA/histstat/Dd903-904.xls", sheet("Dd903-904") firstrow clear

rename 						ValueAdded_Dd904_Percent msh_va
rename 						Year year
destring, replace
keep 						msh_va year

tempfile 					censusearly	
save 						"`censusearly'"

// Census, corporate value added share
import excel "$DATA/census/manufacturing_corp_value_added.xlsx", sheet("Sheet1") firstrow clear

gen double 					msh_va = corporatevalueadded / allvalueadded * 100 
keep 						msh_* year
destring, replace
keep 						msh_va year

tempfile 					censuslate	
save 						"`censuslate'"

/* Output */

// Combine data
use "$OUTPUT/soi/topshares/manufacturing_concent_R5.dta", clear

keep 																			if sector_main == "Manufacturing"
drop 						sector_* 

// Top lists  
merge 1:1 year using "`ftc'", nogen
merge 1:1 year using "`cp'", nogen
foreach year in 1917 1930 1948 {
	merge 1:1 year using "`chandler`year''", nogen update
}	

// Denominator information 
merge 1:1 year using "`soiearly'", nogen
merge 1:1 year using "`censusearly'", nogen
merge 1:1 year using "`censuslate'", nogen update
merge 1:1 year using "`industrials'", nogen
 
sort 					year
tsset 					year

// Linearly interpolate manufacturing value added share
ipolate 				msh_va year, gen(msh_va_ipol)

// Rescale FTC data
replace 				ftc100_sh = ftc100_sh / 100	 

// SOI series: noncorp adjustment using the manufacturing value added share
gen double 				tsh_assets_ipol_100firms_adj = tsh_assets_ipol_100firms * msh_va_ipol / 100
gen double 				tsh_ninc_ipol_100firms_adj = tsh_ninc_ipol_100firms * msh_va_ipol / 100

// Chandler series: scale by total corp assets and adjust for noncorporates
*use baseline soi for denominator
gen double 				ratio_chandler_top100adj = chandler_top100 * 10000 * msh_va_ipol / assets_total  
*use early total for manufacturing 
replace 				ratio_chandler_top100adj = chandler_top100 * 10000 * msh_va_ipol / assets_Manufacturing_lipol  		if ratio_chandler_top100adj == .  
*before 1921 use early total for industrial and manufacturing share estimate (0.82 from capital stock)
replace 				ratio_chandler_top100adj = chandler_top100 * 10000 * msh_va_ipol / (assets_Industrials_lipol*0.82)  if ratio_chandler_top100adj == . 

// Collins-Preston series: scale by total corp assets and adjust for noncorporates
*use baseline soi for denominator
gen double 				ratio_cp_top100adj = cp_top100 * 10000 * msh_va_ipol / assets_total_Industrials  
*use early total for industrials
replace 				ratio_cp_top100adj = cp_top100 * 10000 * msh_va_ipol / assets_Industrials_lipol   					if ratio_cp_top100adj == .

// Plot
twoway 	(connected tsh_ninc_ipol_100firms_adj year, color(midgreen) msize(medsmall) cmissing(no)) ///
		(connected tsh_assets_ipol_100firms_adj year, msymbol(T) color(navy) msize(medsmall)) ///
		(connected ratio_chandler_top100adj year, color(orange) cmissing(yes)) /// 
		(connected ratio_cp_top100adj year, msymbol(D) color(red) cmissing(yes)) ///
		(connected ftc100_sh year, msymbol(x) msize(large) lwidth(medthick) color(purple) cmissing(yes)) if year > 1900 & year <= 1980, ///
		ytitle("Share") xtitle("") ///
		ylabel(0.2(0.1)0.6, format(%03.1f)) xlabel(1920(20)1980) ///
		legend(label(1 "Top 100 by Net Income, SOI") label(2 "Top 100 by Assets, SOI") label(3 "Top 100 by Assets, Chandler") ///
		label(4 "Top 100 by Assets, Collins-Preston") label(5 "Top 100 by Assets, FTC") order(2 5 4 3 1) cols(2)) ///
		graphregion(margin(medium)) name(main, replace)
graph export "$FIGURE/FigureIA9.pdf", replace 
