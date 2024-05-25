/************ Function ************/

*This file makes Figure 4 of the paper on top shares in main sectors 

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

************************************************
**             Panel A: By Assets             **
************************************************

gen double	bottom_share_50pct 	= 1 - tsh_assets_ipol_50pct	
gen double	diff_50pct_10pct 	= tsh_assets_ipol_50pct - tsh_assets_ipol_10pct
gen double	diff_10pct_1pct 	= tsh_assets_ipol_10pct - tsh_assets_ipol_1pct
gen double	diff_1pct_0_1pct 	= tsh_assets_ipol_1pct - tsh_assets_ipol_0_1pct
	
gen double	temp 				= bottom_share_50pct + diff_50pct_10pct
gen double	temp2 				= bottom_share_50pct + diff_50pct_10pct + diff_10pct_1pct
gen double	temp3 				= bottom_share_50pct + diff_50pct_10pct + diff_10pct_1pct + diff_1pct_0_1pct
gen double	temp4 				= bottom_share_50pct + diff_50pct_10pct + diff_10pct_1pct + diff_1pct_0_1pct + tsh_assets_ipol_0_1pct

label var bottom_share_50pct 	"Bottom 50%"
label var temp 					"Top 10%-Top 50%"
label var temp2 				"Top 1%-Top 10%"
label var temp3 				"Top 0.1%-Top 1%"
label var temp4 				"Top 0.1%"
	
local size medlarge
local size2 large
local s_list All Agriculture Construction Finance Manufacturing Mining Services Trade Utilities
local ytlist ""Share" " " " " "Share" " " " " "Share" " ""
local snum : word count `s_list'

local allnames ""

forvalues i = 1/`snum'{
	local s : word `i' of `s_list'
	local yt : word `i' of `ytlist'
	
	twoway 	(area temp4 temp3 temp2 temp bottom_share_50pct year, lwidth(none none none none none) fintensity(100 85 50 50 30)) ///
			if sector_main == "`s'" & year >= 1930 & year <= 2013, ///
			ylabel(0 "0" 0.2 "0.2" 0.4 "0.4" 0.6 "0.6" 0.8 "0.8" 1 "1.0", grid labsize(`size') angle(0)) xlabel(1930(20)2010, grid labsize(`size')) ///
			ytitle(`yt', size(`size')) xtitle("") title(`s', size(`size2')) ///
			legend(cols(3) symxsize(*0.7) region(lwidth(none))) ///
			name(con_`s', replace) plotregion(margin(l=1.25 r=1.25 t=1.25 b=1.25)) graphregion(margin(t=1.5 b=1.5)) nodraw	
			local allnames `allnames' con_`s'
}
grc1leg `allnames', iscale(*0.95) ycommon cols(3) scheme(s1color) graphregion(margin(tiny)) name(all_graph, replace) 	   
resize all_graph, ysize(4) xsize(5.5)
graph export "$FIGURE/Figure4_PanelA.pdf", replace 
graph export "$FIGURE/Figure4_PanelA.eps", replace 
 
		
		
************************************************
**            Panel B: By Receipts            **
************************************************
		
cap drop bottom_share_50pct diff_50pct_10pct diff_10pct_1pct diff_1pct_0_1pct
drop temp*

gen double	bottom_share_50pct 	= 1 - tsh_receipts_ipol_50pct	
gen double	diff_50pct_10pct 	= tsh_receipts_ipol_50pct - tsh_receipts_ipol_10pct
gen double	diff_10pct_1pct 	= tsh_receipts_ipol_10pct - tsh_receipts_ipol_1pct
gen double	diff_1pct_0_1pct 	= tsh_receipts_ipol_1pct - tsh_receipts_ipol_0_1pct
	
gen double	temp 				= bottom_share_50pct + diff_50pct_10pct
gen double	temp2 				= bottom_share_50pct + diff_50pct_10pct + diff_10pct_1pct
gen double	temp3 				= bottom_share_50pct + diff_50pct_10pct + diff_10pct_1pct + diff_1pct_0_1pct
gen double	temp4 				= bottom_share_50pct + diff_50pct_10pct + diff_10pct_1pct + diff_1pct_0_1pct + tsh_receipts_ipol_0_1pct

label var bottom_share_50pct 	"Bottom 50%"
label var temp 					"Top 10%-Top 50%"
label var temp2 				"Top 1%-Top 10%"
label var temp3 				"Top 0.1%-Top 1%"
label var temp4 				"Top 0.1%"

local size medlarge
local size2 large
local s_list All Agriculture Construction Finance Manufacturing Mining Services Trade Utilities
local ytlist ""Share" " " " " "Share" " " " " "Share" " ""
local snum : word count `s_list'

local allnames ""

forvalues i = 1/`snum'{
	local s : word `i' of `s_list'
	local yt : word `i' of `ytlist'
	
	twoway 	(area temp4 temp3 temp2 temp bottom_share_50pct year, lwidth(none none none none none) fintensity(100 85 50 50 30)) ///
			if sector_main == "`s'" & year >= 1959 & year <= 2013, ///
			ytitle(`yt', size(`size')) xtitle("") title(`s', size(`size2')) ///
			ylabel(0 "0" 0.2 "0.2" 0.4 "0.4" 0.6 "0.6" 0.8 "0.8" 1 "1.0", grid labsize(`size') angle(0)) xlabel(1960(20)2010, grid labsize(`size'))  ///
			legend(cols(3) symxsize(*0.7) region(lwidth(none)))	///
			name(con_`s', replace) plotregion(margin(l=1.25 r=1.25 t=1.25 b=1.25)) graphregion(margin(t=1.5 b=1.5)) nodraw	
			local allnames `allnames' con_`s'
}
grc1leg `allnames', iscale(*0.95) ycommon cols(3) scheme(s1color) graphregion(margin(tiny)) name(all_graph, replace) 	   
resize all_graph, ysize(4) xsize(5.5)
graph export "$FIGURE/Figure4_PanelB.pdf", replace  
graph export "$FIGURE/Figure4_PanelB.eps", replace  
 	