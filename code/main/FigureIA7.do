/************ Function ************/

*This file makes Figure IA7 of the paper on top N receipt shares 

/************ Source ************/

*"output/soi/topshares/sector_type_concent_R5.dta" (tabulations including noncorporations), "output/soi/topshares/sector_concent_R5.dta" (baseline), "output/soi/topshares/sector_concent_topN_R5.dta" (topN corps) compiled by code/clean/compute_concentration_sector.do

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

use "$OUTPUT/soi/topshares/sector_type_concent_R5.dta", clear
keep if tables == "Combined"

merge 1:1 sector_main year using "$OUTPUT/soi/topshares/sector_concent_R5.dta", nogen
sort sector_main year

// All
twoway 	(line tsh_receipts_ipol_0_1pct year, lpattern(solid) lwidth(medthick) color(eltblue)) ///
		(scatter top_share_0_1pct top_share_5000firmspop year, ///
		msymbol(T D) msize(medsmall medsmall) color(eltblue navy)) if sector_main == "All" & year >= 1959 & year <= 2013, ///
		ytitle("Share") title("All (N=5,000)") xtitle("") ///
		ylabel(0.4(0.1)0.8, format(%03.1f)) xlabel(1960(10)2010) ///
		legend(label(1 "Top 0.1% Corps in Corp") label(2 "Top 0.1% Businesses") label(3 "Top N Businesses in All, population growth ajusted") ///
		order(3 2 1) cols(1) symxsize(*0.6)) ///
		name(all, replace)

// Manufacturing
twoway 	(line tsh_receipts_ipol_0_1pct year, lpattern(solid) lwidth(medthick) color(eltblue)) ///
		(scatter top_share_0_1pct top_share_500firmspop year, ///
		msymbol(T D) msize(medsmall medsmall) color(eltblue navy)) if sector_main == "Manufacturing" & year >= 1959 & year <= 2013, ///
		ytitle(" ") xtitle("") title("Manufacturing (N=500)") ///
		ylabel(0.4(0.1)0.8, format(%03.1f)) xlabel(1960(10)2010) ///
		legend(off) ///
		name(manufacturing, replace) 

// Services
twoway 	(line tsh_receipts_ipol_0_1pct year, lpattern(solid) lwidth(medthick) color(eltblue)) ///
		(scatter top_share_0_1pct top_share_5000firmspop year, ///
		msymbol(T D) msize(medsmall medsmall) color(eltblue navy)) if sector_main == "Services" & year >= 1959 & year <= 2013, ///
		ytitle("Share") xtitle("") title("Services (N=5,000)") ///
		ylabel(0.2(0.1)0.7, format(%03.1f)) xlabel(1960(10)2010) ///
		legend(off) ///
		name(services, replace) 

// Trade
twoway 	(line tsh_receipts_ipol_0_1pct year, lpattern(solid) lwidth(medthick) color(eltblue)) ///
		(scatter top_share_0_1pct top_share_5000firmspop year, ///
		msymbol(T D) msize(medsmall medsmall) color(eltblue navy)) if sector_main == "Trade" & year >= 1959 & year <= 2013, ///
		ytitle(" ") xtitle("") title("Trade (N=5,000)") ///
		ylabel(0.2(0.1)0.7, format(%03.1f)) xlabel(1960(10)2010) ///
		legend(off) ///
		name(trade, replace)

grc1leg all manufacturing services trade
graph export "$FIGURE/FigureIA7.pdf", replace  