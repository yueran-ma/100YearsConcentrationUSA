/************ Function ************/

*This file makes Figure IA2 of the paper on relative top shares in main sectors 

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

// generate relative top share
gen double	tsh_assets_ipol_1in10 = tsh_assets_ipol_1pct / tsh_assets_ipol_10pct

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
			(line tsh_assets_ipol_1in10 year, cmissing(no) lcolor(eltblue*1.2) lpattern(longdash) lwidth(medthick)) if sector_main == "`s'" , ///
			ytitle(`yt', size(`size')) xtitle("") title(`s', size(`size2')) ///
			ylabel(, format(%03.1f) grid labsize(`size') angle(0)) xlabel(1920(30)2010, grid labsize(`size')) ///
			legend(off)	///
			name(con_`s', replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw	
			local allnames `allnames' con_`s'
}

// create a blank graph for the legend
twoway 	(line tsh_assets_ipol_1pct year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
		(line tsh_assets_ipol_1in10 year, cmissing(no) lcolor(eltblue*1.2) lpattern(longdash) lwidth(medthick)) if sector_main == "Agriculture" & year == 2017, ///
		ytitle("") xtitle("") ///
		ylabel("") xlabel("") yscale(off) xscale(off) ///
		legend(label(1 "Asset Share of" "Top 1% in All") label(2 "Asset Share of" "Top 1% in Top 10%") /// 
		col(1) pos(11) ring(0) order(1 2) region(lwidth(none)) margin(vsmall) size(*1.4)) ///
		name(blank_label, replace) plotregion(lpattern(blank)) graphregion(lpattern(blank)) scheme(s1color) nodraw

graph combine `allnames' blank_label, iscale(*0.95) ycommon cols(3) scheme(s1color) graphregion(margin(tiny)) name(all_graph, replace) 
graph export "$FIGURE/FigureIA2.pdf", replace  

 