/************ Function ************/

*This file makes Figure IA15 of the paper on fixed assets in main sectors 

/************ Source ************/

*"output/soi/brackets/sector_brackets_assets_R5.dta" compiled by code/clean/by_sector_by_assets_generate_dataset.do

/************ Steps ************/

*Add up top bins to get fixed assets and total assets by asset size class

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

use "$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", clear

** Top 1% Estimate **

gsort 									sector_main year -thres_low	
by sector_main year: gen 				rank_hi 		= _n

// Cumulative fraction of firms up to each bucket 
gen double								frac 			= number / number_total 					if rank_hi == 1
sort 									sector_main year rank
by sector_main year: replace 			frac 			= frac[_n-1] + number / number_total 		if frac == .

// Buckets above and below 1% 
gen 									pass 			= 0 										if frac <= 0.01
replace 								pass 			= 1 										if frac > 0.01
by sector_main year: gen 				boundary 		= 1 										if frac <= 0.01 & frac[_n+1] > 0.01

bysort sector_main year: egen double	tmp 			= sum(number) 								if pass == 0

// Estimate top 1% total 
sort 									sector_main year rank
gen double 								remainder 		= (number_total*0.01 - tmp) / number[_n+1] 	if boundary == 1
foreach item in assets cassets {
	by sector_main year: egen double	`item'_top1 	= sum(`item') 								if pass == 0
	replace 							`item'_top1 	= `item'_top1 + remainder*`item'[_n+1] 		if boundary == 1
	replace 							`item'_top1	 	= . 										if boundary != 1
}

cap drop 								bracket_deletion_total

collapse (mean) *_top1  *_total, by(sector_main year)

// Fixed asset over total assets for top 1% by assets and the rest
gen double								cassets_asset_top1 	= cassets_top1 / assets_top1
gen double 								cassets_asset_other = (cassets_total - cassets_top1) / (assets_total - assets_top1)

local size medlarge
local size2 large
local s_list All Agriculture Construction Finance Manufacturing Mining Services Trade Utilities
local ytlist ""Ratio" " " " " "Ratio" " " " " "Ratio" " ""
local snum : word count `s_list'

local allnames ""

forvalues i = 1/`snum'{
	local s : word `i' of `s_list'
	local yt : word `i' of `ytlist'
	
	twoway 	(line cassets_asset_top1 year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
			(line cassets_asset_other year, cmissing(no) lcolor(eltblue*1.2) lpattern(dash) lwidth(medthick)) ///
			if cassets_asset_top1 != . & sector_main == "`s'" & year >= 1930 & year != 1962, ///
			ytitle(`yt', size(`size')) xtitle("") title(`s', size(`size2')) ///
			ylabel(0 "0" 0.2 "0.2" 0.4 "0.4" 0.6 "0.6" 0.8 "0.8", grid labsize(`size') angle(0)) xlabel(1930(20)2010, grid labsize(`size')) ///
			legend(label(1 "Fixed Assets/Total Assets (Top 1%)") label(2 "Fixed Assets/Total Assets (Other)") symxsize(*0.7) region(lwidth(none))) ///
			name(con_`s', replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw	
			local allnames `allnames' con_`s'
}

grc1leg `allnames', iscale(*0.95) ycommon cols(3) scheme(s1color)  graphregion(margin(tiny)) name(all_graph, replace) 
graph export "$FIGURE/FigureIA15.pdf", replace   
