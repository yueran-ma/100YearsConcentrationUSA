/************ Function ************/

*This file makes Figure IA17 of the paper on robustness to consolidation adjustments in 1930s

/************ Source ************/

*"output/soi/topshares/agg_concent_R5.dta" compiled by code/clean/compute_concentration_agg.do

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

use "$OUTPUT/soi/topshares/agg_concent_R5.dta", replace

tsset year

gen bar = 0.76 if year >= 1934 & year <= 1941

twoway 	(area bar year, lcolor(white) fintensity(60) color(gs12)) ///
		(connected tsh_assets_ipol_1pctwoadj year if year >= 1933 & year <= 1942, msymbol(C) lpattern(dash) color(eltblue)) ///
		(connected tsh_assets_ipol_1pct year,  color(navy) msymbol(T) lpattern(dash)) if year < 1950 & year >= 1931, ///
		ytitle("Top 1% Asset Share") xtitle("") ylabel(0.68(0.02)0.76, format(%03.2f) angle(0)) ///
		legend(label(1 "No Tax Consolidation") label(2 "Without Adjustment") label(3 "With Adjustment") ///
		order(3 2 1) cols(1) pos(5) ring(0) region(lwidth(none))) scheme(s1mono) ///
		plotregion(margin(tiny))  
graph export "$FIGURE/FigureIA17.pdf", replace