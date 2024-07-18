/************ Function ************/

*This file makes Figure 6 of the paper on top shares in main sectors including noncorporations

/************ Source ************/

*"output/soi/topshares/sector_type_concent_R5.dta" (tabulations with noncorporations) and "output/soi/topshares/sector_concent_R5.dta" (baseline) compiled by code/clean/compute_concentration_sector.do

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

// Compare data to corp baseline
merge m:1 sector_main year using "$OUTPUT/soi/topshares/sector_concent_R5.dta", keep(1 2 3) nogen

// Inconsistency in the integrated business data for Finance (confirmed by SOI staff)
replace top_share_1pct = . if tables== "Combined" & sector_main == "Finance" & year > 1990

// Can't separate farm sole proprietorships in the tabulation from other sole proprietorships in Agriculture before 1981, drop estimate
replace top_share_1pct = . if sector_main == "Agriculture" & year <= 1981

sort sector_main year

// Plot
local size medlarge
local size2 large
local s_list All Agriculture Construction Finance Manufacturing Mining Services Trade Utilities
local ytlist ""Share" " " " " "Share" " " " " "Share" " ""
local snum : word count `s_list'
label var tsh_receipts_ipol_1pct ""

local allnames ""

forvalues i = 1 / `snum' {
	local s : word `i' of `s_list'
	local yt : word `i' of `ytlist'
	
	display "`c'"
	twoway 	(connected tsh_receipts_ipol_1pct year, cmissing(no) color(navy) lwidth(medthick) msize(vsmall) msymbol(C)) ///
			(scatter top_share_1pct year if tables == "Combined", mcolor(purple) msize(vsmall)) if sector_main == "`s'" & tsh_receipts_ipol_1pct != . , ///
			ytitle(`yt', size(`size')) xtitle("") title(`s', size(`size2')) ///
			ylabel(, format(%03.1f) grid labsize(`size') angle(0)) xlabel(1960(20)2000, grid labsize(`size')) ///
			legend(label(1 "Corporations") label(2 "All Businesses") order (1 3 2) cols(3) symxsize(*0.6) region(lwidth(none)))	///
			name(con_`s', replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw	
			local allnames `allnames' con_`s'
}

grc1leg `allnames', iscale(*0.95) ycommon cols(3) scheme(s1color) graphregion(margin(tiny)) name(all_graph, replace) 
resize all_graph, ysize(4.5) xsize(5.5)	   
graph export "$FIGURE/Figure6.pdf", replace 
graph export "$FIGURE/Figure6.eps", replace