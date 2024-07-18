/************ Function ************/

*This file makes Figure 8 of the paper on top N asset shares 

/************ Source ************/

*"output/soi/topshares/sector_concent_R5.dta" (baseline) and "output/soi/topshares/sector_concent_topN_R5.dta" (topN corps) compiled by code/clean/compute_concentration_sector.do

clear all



******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

use "$OUTPUT/soi/topshares/sector_concent_topN_R5.dta", clear

merge 1:1 sector_main year using "$OUTPUT/soi/topshares/sector_concent_R5.dta", nogen keepusing(tsh_assets_ipol_0_1pct)

sort sector_main year

// All 
twoway 	(line tsh_assets_ipol_0_1pct tsh_Aassets_ipol_5000firms year, ///
		lpattern(solid dash) lwidth(medthick medthick) color(eltblue navy)) ///
		(scatter tsh_Aassets_ipol_5000firmscomb year, msymbol(D) msize(medsmall) color(navy)) if sector_main == "All" & year >= 1945 & year <= 2013, ///
		ytitle("Share") xtitle("") title("All (N=5,000)") ///
		ylabel(0.4(0.1)0.9, format(%03.1f)) xlabel(1950(10)2010) yscale(range(0.36 0.9)) ///
		legend(label(1 "Top 0.1% Corps in Corp") label(2 "Top N Corps in All") label(3 "Top N Corps and Partnerships in All") order(2 3 1) symxsize(*0.6)) ///
		name(all, replace)

// Manufacturing
twoway 	(line tsh_assets_ipol_0_1pct tsh_Aassets_ipol_500firms year, ///
		lpattern(solid dash) lwidth(medthick medthick) color(eltblue navy)) if sector_main == "Manufacturing" & year >= 1945 & year <= 2013, ///
		ytitle(" ") xtitle("") title("Manufacturing (N=500)") ///
		ylabel(0.4(0.1)0.9, format(%03.1f)) xlabel(1950(10)2010) yscale(range(0.36 0.9))  ///
		legend(off) ///
		name(manufacturing, replace) 

// Services
twoway	(line tsh_assets_ipol_0_1pct tsh_Aassets_ipol_5000firms year, ///
		lpattern(solid  dash) lwidth(medthick medthick) color(eltblue navy)) if sector_main == "Services" & year >= 1945 & year <= 2013, ///
		ytitle("Share") xtitle("") title("Services (N=5,000)") ///
		ylabel(, format(%03.1f)) xlabel(1950(10)2010) ///
		legend(off) /// 
		name(services, replace) 

// Trade
twoway 	(line tsh_assets_ipol_0_1pct tsh_Aassets_ipol_5000firms year, ///
		lpattern(solid  dash) lwidth(medthick medthick) color(eltblue navy)) if sector_main == "Trade" & year >= 1945 & year <= 2013, ///
		ytitle(" ") xtitle("") title("Trade (N=5,000)") ///
		ylabel(, format(%03.1f)) xlabel(1950(10)2010) ///
		legend(off) ///
		name(trade, replace) 

grc1leg all manufacturing services trade
graph export "$FIGURE/Figure8.pdf", replace 
graph export "$FIGURE/Figure8.eps", replace