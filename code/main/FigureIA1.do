/************ Function ************/

*This file makes Figure A1 of the paper on top shares in main sectors using Pareto, lognormal, and adding up bins estimates  

/************ Source ************/

*"output/soi/topshares/sector_concent_R5.dta" compiled by code/clean/compute_concentration_sector.do, "output/soi/topshares/sector_concent_lognorm_R5.dta" compiled by code/clean/compute_concentration_sector_lognormal.do, and "output/soi/brackets/sector_brackets_assets_R5.dta" compiled by code/clean/by_sector_by_assets_generate_dataset.do

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

// Add up brackets for top share estimates

use "$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", clear

gsort 									year sector_main -thres_low	
by year sector_main: gen 				rank_hi 	= _n

// Cumulative fraction of firms up to each bucket 
gen double								frac 		= number / number_total 					if rank_hi == 1
sort 									sector_main year rank
by sector_main year: replace 			frac 		= frac[_n-1] + number / number_total 		if frac == .

// Buckets above and below 1% 
gen 									pass 		= 0 										if frac <= 0.01
replace 								pass 		= 1 										if frac > 0.01
by sector_main year: gen 				boundary 	= 1 										if frac <= 0.01 & frac[_n+1] > 0.01

bysort sector_main year: egen double	tmp 		= sum(number) 								if pass == 0

// Estimate top 1% total 
sort 									sector_main year rank
gen double								remainder 	= (number_total*0.01 - tmp) / number[_n+1] 	if boundary == 1
foreach item in assets {
	by sector_main year: egen double	`item'_top1 = sum(`item') 								if pass == 0
	replace 							`item'_top1 = `item'_top1 + remainder * `item'[_n+1] 	if boundary == 1
	replace 							`item'_top1 = . 										if boundary != 1
}

cap drop 								bracket_deletion_total

collapse (mean) *_top1  *_total, by(sector_main year)

gen double 								tsh_assets_add_1pct = assets_top1 / assets_total

do "../clean/outliers_sector.do"

// Add baseline top share estimates
merge 1:1 sector_main year using "$OUTPUT/soi/topshares/sector_concent_R5.dta", keep(1 3)
tab _merge
drop _merge

// Add lognormal top share estimates
merge 1:1 sector_main year using "$OUTPUT/soi/topshares/sector_concent_lognorm_R5.dta", keep(1 3)
tab _merge
drop _merge

// Make figure 
local size medlarge
local size2 large
local s_list All Agriculture Construction Finance Manufacturing Mining Services Trade Utilities
local ytlist ""Share" " " " " "Share" " " " " "Share" " ""
local snum : word count `s_list'

local allnames ""

forvalues i = 1/`snum'{
	local s : word `i' of `s_list'
	local yt : word `i' of `ytlist'	
		
	twoway 	(line tsh_assets_ipol_1pct year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
			(line tsh_assets_add_1pct year, cmissing(no) lcolor(eltblue*1.2) lpattern(shortdash) lwidth(medthick)) ///
			(line tsh_assets_ln_1pct year, cmissing(no) lcolor(purple) lpattern(longdash) lwidth(medthick)) if sector_main == "`s'" & year >= 1930, ///
			ytitle(`yt', size(`size')) xtitle("") title(`s', size(`size2')) ///
			ylabel(, format(%03.1f) grid labsize(`size') angle(0)) xlabel(1930(20)2010, grid labsize(`size')) ///
			legend(label(1 "Pareto") label(2 "Addup") label(3 "Lognormal") order(1 3 2) col(3) pos(11) ring(0) region(lwidth(none))) ///
			name(con_`s', replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw	
			local allnames `allnames' con_`s'
}
grc1leg `allnames', iscale(*0.95) ycommon cols(3) scheme(s1color) graphregion(margin(tiny)) name(all_graph, replace) 
graph export "$FIGURE/FigureIA1.pdf", replace 
