/************ Function ************/

*This file makes Figure 5 of the paper on top shares in subsectors 

/************ Source ************/

*"output/soi/topshares/subsector_concent_R5.dta" compiled by code/clean/compute_concentration_subsector.do

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

use "$OUTPUT/soi/topshares/subsector_concent_R5.dta", clear

encode subsector_BEA, gen(sector_ID)

tsfill, full

decode sector_ID, gen(temp)
replace subsector_BEA = temp if missing(subsector_BEA)
drop temp

labmask sector_ID, values(subsector_BEA)

drop if subsector_BEA == "Agriculture" | subsector_BEA == "Construction" | subsector_BEA == "Manufacturing: Plastics"

gen tsh_assets_ipol_1in10 = tsh_assets_ipol_1pct / tsh_assets_ipol_10pct

local size medium
local size2 large
local size3 vlarge
levelsof subsector_BEA, local(s_list)
local ytlist ""Share"   " "   " "   " "   "Share"     " "   " "   " "    "Share"   " "   " "   " "    "Share"    " "   " "   " "   "Share"    " "   " "   " " "Share"     " "   " "   " "    "Share"     " "   " "   " "   "Share" "

local snum : word count `s_list'

local allnames ""
local allnames_wide ""

local ylabels "0.2 0.4 0.6 0.8 1.0"

local ncols 4
local imargin_gap 10

local margin_first 1.25 
local margin_other 1.25

forvalues i = 1/`snum' {
    local s : word `i' of `s_list'
    local is_first_in_row = mod(`i' - 1, `ncols') == 0

    if `is_first_in_row' {
        local ylabel_options "ylabel(`ylabels', format(%3.1f) grid labsize(`size') labcolor(black) angle(horizontal))"
        local ytitle_options "ytitle("Share", size(large) margin(r=-1 l=-1))"
        local plotregion_options "plotregion(margin(l=1.25 r=`margin_first'))"
		local xsize 10
    }
    else {
		local ylabel_options "ylabel(`ylabels', format(%3.1f) grid labsize(`size') labcolor(white) angle(horizontal) notick)"
        local ytitle_options "ytitle("", size(large) margin(r=-1 l=-1))"
        local plotregion_options "plotregion(margin(l=1.25 r=`margin_other'))"
		local xsize 10
    }

    twoway 	(line tsh_assets_ipol_1pct year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) if tsh_assets_ipol_1pct != . & subsector_BEA == "`s'", ///
			`ytitle_options' xtitle("") title("`s'", margin(r=-5 l=-7) size(`size2')) ///
			`ylabel_options' xlabel(1930(20)2020, grid labsize(`size')) xsize(`xsize') ///
			legend(off) ///
			name(con_`i', replace)  `plotregion_options' graphregion(margin(l=-2 r=2)) nodraw 
    local allnames `allnames' con_`i'
}

graph combine  `allnames', iscale(*1) ycommon cols(`ncols') imargin(1 1 1 1) scheme(s1color) graphregion(margin(small)) name(all_graph, replace) 
graph display all_graph, xsize(2.3) ysize(3)
graph export "$FIGURE/Figure5.pdf", replace 
graph export "$FIGURE/Figure5.eps", replace 
