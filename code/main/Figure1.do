/************ Function ************/

*This file makes Figure 1 of the paper on aggregate top shares 

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

twoway 	(connected tsh_ninc_ipol_1pct year, color(midgreen)) ///
		(connected tsh_receipts_ipol_1pct year, color(red) msymbol(D)) ///
		(connected tsh_assets_ipol_1pct year, color(navy) msymbol(T)) ///
		(connected tsh_capital_ipol_1pct year, mfcolor(none) mlcolor(navy) lcolor(navy) lpattern(dash) msymbol(X) msize(medlarge)) if year < 2020, ///
		title("Top 1%") ytitle("Share", size(medlarge)) xtitle("", size(medlarge)) ///
		ylabel(, format(%9.1fc) labsize(medlarge)) xlabel(, labsize(medlarge)) ///
		legend(label(1 "Net Income") label(2 "Receipts") label(3 "Assets") label(4 "Equity") order(3 2 1 4) cols(4) size(medlarge)) ///
		name(dist_1pct, replace) graphregion(margin(medium)) nodraw  

twoway 	(connected tsh_ninc_ipol_0_1pct year, color(midgreen)) ///
		(connected tsh_receipts_ipol_0_1pct year, color(red) msymbol(D)) ///
		(connected tsh_assets_ipol_0_1pct year, color(navy) msymbol(T)) ///
		(connected tsh_capital_ipol_0_1pct year, mfcolor(none) mlcolor(navy) lcolor(navy) lpattern(dash) msymbol(X) msize(medlarge)) if year < 2020, ///
		title("Top 0.1%") ytitle(" ", size(medlarge)) xtitle("", size(medlarge)) ///
		ylabel(, format(%9.1fc) labsize(medlarge)) xlabel(, labsize(medlarge)) ///
		legend(label(1 "Net Income") label(2 "Receipts") label(3 "Assets") label(4 "Equity") order(3 2 1 4) cols(4) size(medlarge)) ///
		name(dist_0_1pct, replace) graphregion(margin(medium)) nodraw 

grc1leg dist_1pct dist_0_1pct, iscale(*1.3) ycommon graphregion(margin(none)) name(g, replace)
graph display g, xsize(15) ysize(7) 
graph export "$FIGURE/Figure1.pdf", replace
graph export "$FIGURE/Figure1.eps", replace
