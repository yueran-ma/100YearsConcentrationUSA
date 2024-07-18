/************ Function ************/

*This file makes Figure IA18 of the paper on share of consolidated returns

/************ Source ************/

*"$DATA/soi/digitized/sector_consolidation_R5.dta"
*"$OUTPUT/soi/by_2digitsector_totals.dta" compiled by code/clean/generate_by_sector_by_assets.do

clear all



******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

use "$DATA/soi/digitized/sector_consolidation_R5.dta", clear

// Merge in sector totals at the coarser SIC/NAICS main division level (to match the consolidation statistics)
merge 1:1 sector_main year using "$OUTPUT/soi/by_2digitsector_totals.dta", nogen keep(1 3)

gen double 				sh_assets = conassets / assets_total2digit 				 
gen double 				sh_number = connumber / number_total2digit 				 

// Get rid of outlier and interpolate 1976
replace 				sh_assets = . 											if sector_main == "Agriculture" & year == 1954
foreach v of varlist sh_* {
	bysort sector_main: ipolate `v' year, gen(temp_`v')
	replace 			`v' = temp_`v' 											if year == 1976
	drop 				temp_`v'
}

sort 					sector_main year

local size medlarge
local size2 large
local s_list All Agriculture Construction Finance Manufacturing Mining Services Trade Utilities
local ytlist ""Share" " " " " "Share" " " " " "Share" " ""
local ytlist2 "" "" ""Share"" "" ""Share"" "" ""Share"" 

local yclist """"color(none)""color(none)""""color(none)""color(none)""""color(none)""color(none)""
local yclist2 ""color(none)""color(none)""""color(none)""color(none)""""color(none)""color(none)""""

local snum : word count `s_list'

local allnames ""

forvalues i = 1 / `snum' {
	local s : word `i' of `s_list'
	local yt : word `i' of `ytlist'
	local yt2 : word `i' of `ytlist2'
	local yc : word `i' of `yclist'		
	local yc2 : word `i' of `yclist2'		

	twoway 	(scatter sh_number year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick) msize(vsmall)) ///
			(scatter sh_assets year, yaxis(2) cmissing(no) color(eltblue) lpattern(longdash) lwidth(medthick) msize(vsmall)) ///
			if sector_main == "`s'" & year >= 1930  & year <= 2013, ///
			ytitle(`yt', axis(1) size(`size') `yc') ytitle(`yt2', axis(2) size(`size') `yc2') ytitle(`yt', size(`size')) xtitle("") title(`s', size(`size2')) ///
			ylabel(0 "0" 0.02 "0.02" 0.04 "0.04" 0.06 "0.06", grid labsize(`size')) ylabel(0 "0" 0.5 "0.5" 1 "1.0", axis(2) labsize(`size')) ///
			xlabel(1930(20)2010, grid labsize(`size')) ///
			legend(label(1 "Share of Consolidated Returns by Number (left axis)") label(2 "Share of Consolidated Returns by Assets (right axis)") ///
			col(1) region(lwidth(none))) ///
			name(con_`s', replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(l=0 r=-5)) nodraw 
			local allnames `allnames' con_`s'
}
grc1leg `allnames', iscale(*0.95) ycommon cols(3) scheme(s1color) graphregion(margin(tiny)) name(all_graph, replace) 
resize all_graph, ysize(4.5) xsize(5.5)
graph export "$FIGURE/FigureIA18.pdf", replace
