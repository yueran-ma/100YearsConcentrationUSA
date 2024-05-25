/************ Function ************/

*This file makes Figure IA4 of the paper on top shares within subsectors 

/************ Source ************/

*"output/soi/topshares/subsector_gran_concent_R5.dta" compiled by code/clean/compute_concentration_subsector.do

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

use "$OUTPUT/soi/topshares/subsector_gran_concent_R5.dta", clear

***********************************************
**                  Panel A                  **
***********************************************

twoway	(connected tsh_assets_ipol_1pct year if subsector == "Mining: Coal") ///
		(connected tsh_assets_ipol_1pct year if subsector == "Mining: Metal", msize(medium) msymbol(x) lpattern(dash)) ///
		(connected tsh_assets_ipol_1pct year if subsector == "Mining: Non Metallic", msize(medsmall) msymbol(T) lpattern(dash_dot)) ///
		(connected tsh_assets_ipol_1pct year if subsector == "Mining: Oil and Gas", msize(medsmall) msymbol(D) lpattern(longdash)), ///
		ylabel(0 "0" 0.2 "0.2" 0.4 "0.4" 0.6 "0.6" 0.8 "0.8" 1 "1.0") xlabel(1940(10)2010) xtitle("") /// 
		ytitle("Top 1% Asset Share") ///
		legend(label(1 "Coal") label(2 "Metal") label(3 "Nonmetallic") label(4 "Oil and Gas") order(1 2 3 4) symxsize(0.6*) region(lwidth(none)))  ///
		name(sub_mining, replace)
graph export "$FIGURE/FigureIA4_PanelA.pdf", replace



***********************************************
**                  Panel B                  **
***********************************************

twoway	(connected tsh_assets_ipol_1pct year if subsector == "Trade: Retail: Apparel", msize(medsmall)) ///
		(connected tsh_assets_ipol_1pct year if subsector == "Trade: Retail: Automotive",  msymbol(+) msize(medsmall)) ///
		(connected tsh_assets_ipol_1pct year if subsector == "Trade: Retail: Building Materials", msize(medsmall) msymbol(T)) ///
		(connected tsh_assets_ipol_1pct year if subsector == "Trade: Retail: Eating Places", msize(medsmall) msymbol(o)) ///
		(connected tsh_assets_ipol_1pct year if subsector == "Trade: Retail: Food", msize(medsmall) msymbol(x)) ///
		(connected tsh_assets_ipol_1pct year if subsector == "Trade: Retail: Furniture", msize(small) msymbol(D)) ///
		(connected tsh_assets_ipol_1pct year if subsector == "Trade: Retail: General Merchandise", msize(medsmall) msymbol(x)) ///
		(connected tsh_assets_ipol_1pct year if subsector == "Trade: Retail: Miscellaneous", msize(medsmall) msymbol(x)) ///
		(connected tsh_assets_ipol_1pct year if subsector == "Trade: Wholesale", msize(medsmall) msymbol(x)), ///
		ytitle("Top 1% Asset Share") xtitle("") ///
		ylabel(0 "0" 0.2 "0.2" 0.4 "0.4" 0.6 "0.6" 0.8 "0.8" 1 "1.0") xlabel(1940(10)2010) /// 
		legend(label(1 "Apparel") label(2 "Automotive") label(3 "Building Materials") label(4 "Restaurants") ///
		label(5 "Food Stores") label(6 "Furniture") label(7 "General Merchandise") label(8 "Miscellaneous") label(9 "Wholesale") ///
		order(3 1 2 4 5 6 7 8 9) cols(3) symxsize(0.6*) region(lwidth(none))) 
graph export "$FIGURE/FigureIA4_PanelB.pdf", replace

