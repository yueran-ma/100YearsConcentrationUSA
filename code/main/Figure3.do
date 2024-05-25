/************ Function ************/

*This file makes Figure 3 of the paper on top shares in main sectors 

/************ Source ************/

*"output/soi/topshares/sector_concent_R5.dta" compiled by code/clean/compute_concentration_sector.do

clear all



******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

use "$OUTPUT/soi/topshares/sector_concent_R5.dta", clear

local size medlarge
local size2 large
local s_list Agriculture Construction Finance Manufacturing Mining Services Trade Utilities
local ytlist ""Share" " " " " "Share" " " " " "Share" " ""
local snum : word count `s_list'

local allnames ""

forvalues i = 1/`snum'{
	local s : word `i' of `s_list'
	local yt : word `i' of `ytlist'
	
	twoway 	(line tsh_assets_ipol_1pct year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
			(line tsh_receipts_ipol_1pct year, cmissing(no) lcolor(red) mcolor(red) lpattern(longdash) lwidth(medthick)) ///
			(line tsh_ninc_ipol_1pct year, cmissing(no) lcolor(midgreen) lpattern(shortdash) lwidth(thick)) if sector_main == "`s'", ///
			title(`s', size(`size2')) ytitle(`yt', size(`size')) xtitle("") ///
			ylabel(, format(%03.1f) grid labsize(`size') angle(0)) xlabel(1920(30)2010, grid labsize(`size')) ///
			plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) ///
			name(con_`s', replace) legend(off) nodraw	
			local allnames `allnames' con_`s'
}

// create a blank graph for the legend
twoway 	(line tsh_assets_ipol_1pct year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
		(line tsh_receipts_ipol_1pct year, cmissing(no) lcolor(red) lpattern(longdash) lwidth(medthick)) ///
		(line tsh_ninc_ipol_1pct year, cmissing(no) lcolor(midgreen) lpattern(shortdash) lwidth(thick)) if sector_main == "Agriculture" & year == 2017, ///
		ylabel("") xlabel("") ytitle("") xtitle("") xscale(off) yscale(off) ///
		legend(label(1 "Assets") label(2 "Receipts") label(3 "Net Income") order(1 2 3) col(1) pos(11) ring(0) region(lwidth(none)) margin(vsmall) size(*1.4)) ///
		name(blank_label, replace)  plotregion(lpattern(blank)) graphregion(lpattern(blank)) scheme(s1color) nodraw

graph combine `allnames' blank_label, iscale(*0.95) ycommon scheme(s1color) cols(3) graphregion(margin(tiny)) name(all_graph, replace) 
graph export "$FIGURE/Figure3.pdf", replace  
graph export "$FIGURE/Figure3.eps", replace 
