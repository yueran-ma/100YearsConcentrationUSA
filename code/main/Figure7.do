/************ Function ************/

*This file makes Figure 7 of the paper on top N receipt shares 

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


************************************************
**                Panel A                     **
************************************************

use "$OUTPUT/soi/topshares/sector_type_concent_R5.dta", clear
keep if tables == "Combined"

merge 1:1 sector_main year using "$OUTPUT/soi/topshares/sector_concent_R5.dta", nogen
sort sector_main year

// All
twoway 	(line tsh_receipts_ipol_0_1pct year, lpattern(solid) lwidth(medthick) color(eltblue)) ///
		(scatter top_share_0_1pct top_share_5000firms year, msymbol(T D) msize(medsmall medsmall) color(eltblue navy)) ///
		if sector_main == "All" & year >= 1959 & year <= 2013, ///
		ytitle("Share") xtitle("") title("All (N=5,000)") ///
		ylabel(0.4(0.1)0.8, format(%03.1f)) xlabel(1960(10)2010) ///
		legend(label(1 "Top 0.1% Corps in Corp") label(2 "Top 0.1% Businesses in All") label(3 "Top N Businesses in All") order(3 2 1) cols(3) symxsize(*0.6)) ///
		name(all, replace) 

// Manufacturing
twoway 	(line tsh_receipts_ipol_0_1pct year, lpattern(solid) lwidth(medthick) color(eltblue)) ///
		(scatter top_share_0_1pct top_share_500firms year, msymbol(T D) msize(medsmall medsmall) color(eltblue navy)) ///
		if sector_main == "Manufacturing" & year>= 1959 & year <= 2013, ///
		ytitle(" ")  xtitle("") title("Manufacturing (N=500)") ///
		ylabel(0.4(0.1)0.8, format(%03.1f)) xlabel(1960(10)2010) ///
		legend(label(1 "Top 0.1% Corps in Corp") label(2 "Top 0.1% Businesses in All") label(3 "Top N Businesses in All") order(3 2 1) cols(3) symxsize(*0.6)) ///
		name(manufacturing, replace) 

// Services
twoway 	(line tsh_receipts_ipol_0_1pct year, lpattern(solid) lwidth(medthick) color(eltblue)) ///
		(scatter  top_share_0_1pct top_share_5000firms year, msymbol(T D) msize(medsmall medsmall) color(eltblue navy)) ///
		if sector_main == "Services" & year >= 1959 & year <= 2013, ///
		ytitle("Share") xtitle("") title("Services (N=5,000)") ///
		ylabel(0.2(0.1)0.7, format(%03.1f)) xlabel(1960(10)2010) ///
		legend(label(1 "Top 0.1% Corps in Corp") label(2 "Top 0.1% Businesses in All") label(3 "Top N Businesses in All") order(3 2 1) cols(3) symxsize(*0.6)) ///
		name(services, replace) 

// Trade
twoway 	(line tsh_receipts_ipol_0_1pct year, lpattern(solid) lwidth(medthick) color(eltblue)) ///
		(scatter  top_share_0_1pct top_share_5000firms year, msymbol(T D) msize(medsmall medsmall) color(eltblue navy)) ///
		if sector_main == "Trade" & year >= 1959 & year <= 2013, ///
		ytitle(" ") xtitle("") title("Trade (N=5,000)")  ///
		ylabel(0.2(0.1)0.7, format(%03.1f)) xlabel(1960(10)2010) ///
		legend(label(1 "Top 0.1% Corps in Corp") label(2 "Top 0.1% Businesses in All") label(3 "Top N Businesses in All") order(3 2 1) cols(3) symxsize(*0.6)) ///
		name(trade, replace)

grc1leg all manufacturing services trade
graph export "$FIGURE/Figure7_PanelA.pdf", replace  
graph export "$FIGURE/Figure7_PanelA.eps", replace  


************************************************
**                Panel B                     **
************************************************

merge 1:1 sector_main year using "$OUTPUT/soi/topshares/sector_concent_topN_R5.dta", nogen 

// All
twoway 	(line tsh_receipts_ipol_5000firms tsh_Areceipts_ipol_5000firms year,  ///
		lpattern(shortdash dash) lwidth( medium medthick) color(navy navy)) ///
		(scatter top_share_5000firms year, msymbol(D) msize(medsmall) color( navy)) if sector_main == "All" & year >= 1959 & year <= 2013, ///
		ytitle("Share") xtitle("") title("All (N=5,000)") ///
		ylabel(0.4(0.1)0.8, format(%03.1f)) xlabel(1960(10)2010) ///
		legend(label(1 "Top N Corps in Corp") label(2 "Top N Corps in All") label(3 "Top N Businesses in All") order(3 2 1) cols(3) symxsize(*0.6)) ///
		name(all, replace) 

// Manufacturing
twoway 	(line tsh_receipts_ipol_500firms tsh_Areceipts_ipol_500firms year, ///
		lpattern(shortdash dash) lwidth(medium medthick) color(navy navy)) ///
		(scatter top_share_500firms year, msymbol(D) msize(medsmall) color( navy)) if sector_main == "Manufacturing" & year >= 1959 & year <= 2013, ///
		ytitle(" ") xtitle("") title("Manufacturing (N=500)") ///
		ylabel(0.4(0.1)0.8, format(%03.1f)) xlabel(1960(10)2010) ///
		legend(label(1 "Top N Corps in Corp") label(2 "Top N Corps in All") label(3 "Top N Businesses in All") order(3 2 1) cols(3) symxsize(*0.6)) ///
		name(manufacturing, replace)

// Services
twoway 	(line tsh_receipts_ipol_5000firms tsh_Areceipts_ipol_5000firms year, ///
		lpattern(shortdash dash) lwidth(medium medthick) color(navy navy)) ///
		(scatter top_share_5000firms year, msymbol(D) msize(medsmall) color( navy)) if sector_main == "Services" & year >= 1959 & year <= 2013, ///
		ytitle("Share") xtitle("") title("Services (N=5,000)") ///
		ylabel(0.2(0.1)0.7, format(%03.1f)) xlabel(1960(10)2010) ///
		legend(label(1 "Top N Corps in Corp") label(2 "Top N Corps in All") label(3 "Top N Businesses in All") order(3 2 1) cols(3) symxsize(*0.6)) ///
		name(services, replace) 

// Trade
twoway 	(line tsh_receipts_ipol_5000firms tsh_Areceipts_ipol_5000firms year, ///
		lpattern(shortdash dash) lwidth(medium medthick) color(navy navy)) ///
		(scatter top_share_5000firms year, msymbol(D) msize(medsmall) color( navy)) if sector_main == "Trade" & year >= 1959 & year <= 2013, ///
		ytitle(" ") xtitle("") title("Trade (N=5,000)") ///
		ylabel(0.2(0.1)0.7, format(%03.1f)) xlabel(1960(10)2010) ///
		legend(label(1 "Top N Corps in Corp") label(2 "Top N Corps in All") label(3 "Top N Businesses in All") order(3 2 1) cols(3) symxsize(*0.6)) ///
		name(trade, replace)
	
grc1leg all manufacturing services trade
graph export "$FIGURE/Figure7_PanelB.pdf", replace 
graph export "$FIGURE/Figure7_PanelB.eps", replace 

