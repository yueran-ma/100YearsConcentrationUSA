/************ Function ************/

*This file makes Figure 2 of the paper on aggregate relative top shares 

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

// Generate relative top shares
gen double	tsh_ninc_1pct_in10 		= tsh_ninc_ipol_1pct / tsh_ninc_ipol_10pct
gen double	tsh_ninc_01pct_in1 		= tsh_ninc_ipol_0_1pct / tsh_ninc_ipol_1pct

gen double	tsh_assets_1pct_in10 	= tsh_assets_ipol_1pct / tsh_assets_ipol_10pct
gen double	tsh_assets_01pct_in1 	= tsh_assets_ipol_0_1pct / tsh_assets_ipol_1pct

gen double	tsh_receipts_1pct_in10 	= tsh_receipts_ipol_1pct / tsh_receipts_ipol_10pct
gen double	tsh_receipts_01pct_in1 	= tsh_receipts_ipol_0_1pct / tsh_receipts_ipol_1pct

gen double	tsh_capital_1pct_in10 	= tsh_capital_ipol_1pct / tsh_capital_ipol_10pct
gen double	tsh_capital_01pct_in1 	= tsh_capital_ipol_0_1pct / tsh_capital_ipol_1pct

// Plot
twoway 	(connected tsh_ninc_1pct_in10 year, color(midgreen)) ///
		(connected tsh_receipts_1pct_in10 year, color(red) msymbol(D)) ///
		(connected tsh_assets_1pct_in10 year, color(navy) msymbol(T)) ///
		(connected tsh_capital_1pct_in10 year, mfcolor(none) mlcolor(navy) lcolor(navy) lpattern(dash) msymbol(X) msize(medlarge)) if year < 2020, ///
		title("Top 1% in Top 10%") ytitle("Share", size(medlarge)) xtitle("", size(medlarge)) ///
		ylabel(0.2 (0.2) 1, format(%03.1f) labsize(medlarge)) xlabel(, labsize(medlarge)) ///
		legend(label(1 "Net Income") label(2 "Receipts") label(3 "Assets") label(4 "Equity") order(3 2 1 4) cols(4) size(medlarge)) ///
		name(dist_1pctin10, replace) graphregion(margin(medium)) nodraw

twoway 	(connected tsh_ninc_01pct_in1 year, color(midgreen)) ///
		(connected tsh_receipts_01pct_in1 year, color(red) msymbol(D)) ///
		(connected tsh_assets_01pct_in1 year, color(navy) msymbol(T)) ///
		(connected tsh_capital_01pct_in1 year, mfcolor(none) mlcolor(navy) lcolor(navy) lpattern(dash) msymbol(X) msize(medlarge)) if year < 2020, ///
		title("Top 0.1% in Top 1%") ytitle(" ", size(medlarge)) xtitle("", size(medlarge)) ///
		ylabel(0.2 (0.2) 1, format(%03.1f) labsize(medlarge)) xlabel(, labsize(medlarge)) ///
		legend(label(1 "Net Income") label(2 "Receipts") label(3 "Assets") label(4 "Equity") order(3 2 1 4) cols(4) size(medlarge)) ///
		name(dist_1pctin1, replace) graphregion(margin(medium)) nodraw	
	
grc1leg dist_1pctin10 dist_1pctin1, iscale(*1.3) ycommon graphregion(margin(none)) name(g, replace)
graph display g , xsize(15) ysize(7) 
graph export "$FIGURE/Figure2.pdf", replace
graph export "$FIGURE/Figure2.eps", replace