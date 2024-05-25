/************ Function ************/

*This file makes Figure IA5 of the paper on corporations relative to noncorporations

/************ Source ************/

*"input/soi/digitized/noncorp_totals_R5.dta"  

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

use "$DATA/soi/digitized/noncorp_totals_R5.dta", clear

gen double sh_corp = receipts_total_corp / (receipts_total_corp + receipts_total_prop_nonfarm + receipts_total_part) 

label var sh_corp "Share"

local size medlarge
local size2 large
local s_list All Agriculture Construction Finance Manufacturing Mining Services Trade Utilities
local yclist """"color(none)""color(none)""""color(none)""color(none)""""color(none)""color(none)""
local snum : word count `s_list'

local allnames ""

forvalues i = 1/`snum'{
	local s : word `i' of `s_list'
	local yc : word `i' of `yclist'
	
	twoway 	(scatter sh_corp year, cmissing(no) color(navy) lwidth(medthick) msize(vsmall) msymbol(D) ) if sector_main == "`s'", ///
			ytitle(, size(`size') `yc') xtitle("") title(`s', size(`size2')) ///
			ylabel(0 "0" 0.2 "0.2" 0.4 "0.4" 0.6 "0.6" 0.8 "0.8" 1 "1.0", grid labsize(`size') angle(0)) xlabel(1940(20)2020, grid labsize(`size')) ///
			legend(off)	///
			name(con_`s', replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw	
			local allnames `allnames' con_`s'	
}
graph combine `allnames', iscale(*0.95) ycommon	cols(3) scheme(s1color) graphregion(margin(tiny)) name(all_graph, replace) 
graph export "$FIGURE/FigureIA5.pdf", replace
