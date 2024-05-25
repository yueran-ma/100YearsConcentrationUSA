/************ Function ************/

*This file makes Figure IA14 of the paper on profitability in SOI vs BEA data

/************ Source ************/

*SOI data: "output/soi/brackets/sector_brackets_assets_R5.dta" compiled by code/clean/by_sector_by_assets_generate_dataset.do
*BEA data: "output/other/BEAProfit_out.dta" compiled by code/clean/BEA_profit.do

/************ Steps ************/

*Add up top bins to get profits and receipts by asset size class

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

// Start with SOI data
use "$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", clear

keep if sector_main == "All"

collapse (last) ninc_total treceipts_total, by(year)

// Merge BEA data
merge 1:1 year using "$OUTPUT/other/BEAProfit_out.dta", keep(1 3)
tab _merge
drop _merge

// Profits over receipts
gen double profitability_bea 	= 10^9 * NINC_bea / treceipts_total
gen double profitability 		= ninc_total / treceipts_total

label var profitability "Net Income (SOI)/Receipts (SOI)"
label var profitability_bea "Net Income (BEA)/Receipts (SOI)"

twoway	(line profitability year) ///
		(line profitability_bea year, lp(dash) lcolor(midblue) ) if  profitability != ., ///
		ytitle("") xtitle("") xlabel(1930(20)2010) ylabel(-0.05 "-0.05" 0 "0" 0.05 "0.05" 0.1 "0.1" 0.15 "0.15", format(%03.2f)) legend(colgap(*1.5))
graph export "$FIGURE/FigureIA14.pdf", replace 
 