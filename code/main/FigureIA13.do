/************ Function ************/

*This file makes Figure IA13 of the paper on profitability in main sectors 

/************ Source ************/

*"output/soi/brackets/sector_brackets_assets_R5.dta" compiled by code/clean/by_sector_by_assets_generate_dataset.do

/************ Steps ************/

*Add up top bins to get profits and receipts by asset size class

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
by sector_main year: gen 				rank_hi 	= _n

// Cumulative fraction of firms up to each bucket 
gen double								frac 		= number/number_total 					if rank_hi == 1
sort 									sector_main year rank
by sector_main year: replace 			frac 		= frac[_n-1] + number / number_total 	if frac == .

// Buckets above and below 1% 
gen 									pass 		= 0 									if frac <= 0.01
replace 								pass 		= 1 									if frac > 0.01
by sector_main year: gen 				boundary 	= 1 									if frac <= 0.01 & frac[_n+1] > 0.01

bysort sector_main year: egen double	tmp 		= sum(number) 							if pass == 0

// Estimate top 1% total 
sort 									sector_main year rank
gen double								remainder 	= (number_total*0.01 - tmp) / number[_n+1] if boundary == 1
foreach item in treceipts ninc {
	by sector_main year: egen double	`item'_top1 = sum(`item') 							if pass == 0
	replace 							`item'_top1 = `item'_top1 + remainder*`item'[_n+1] 	if boundary == 1
	replace 							`item'_top1 = . 									if boundary != 1
}

cap drop 								bracket_deletion_total

collapse (mean) *_top1 *_total, by(sector_main year)

// Profitability for top 1% by assets and the rest 
gen double								profit_top1 = ninc_top1 / treceipts_top1 
gen double								profit_other = (ninc_total - ninc_top1) / (treceipts_total - treceipts_top1)

label var profit_top1 "Net Income/Receipts (Top 1%)"
label var profit_other "Net Income/Receipts (Other)"

// Plot
local size medlarge
local size2 large

twoway 	(line profit_top1 year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
		(line profit_other year, cmissing(no) lcolor(eltblue*1.2) lpattern(dash) lwidth(medthick)) ///
		if sector_main == "All" & year <= 2013 & year >= 1931, ///
		ytitle("Ratio", size(`size')) xtitle("") title("All", size(`size2')) ///
		ylabel(-0.1 "-0.1" 0 "0" 0.1 "0.1" 0.2 "0.2", grid labsize(`size')) xlabel(1930(20)2010, grid labsize(`size')) ///
		legend(symxsize(*0.7) region(lwidth(none)))	///
		name(con_All, replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw
local allnames `allnames' con_All
		
twoway 	(line profit_top1 year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
		(line profit_other year, cmissing(no) lcolor(eltblue*1.2) lpattern(dash) lwidth(medthick)) ///
		if sector_main == "Agriculture" & year <= 2013 & year >= 1931, ///
		ytitle(" ", size(`size')) xtitle("") title("Agriculture", size(`size2')) ///
		ylabel(-0.4 "-0.4" -0.2 "-0.2" 0 "0" 0.2 "0.2", grid labsize(`size')) xlabel(1930(20)2010, grid labsize(`size')) ///
		legend(symxsize(*0.7) region(lwidth(none)))	///
		name(con_Agriculture, replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw
local allnames `allnames' con_Agriculture

twoway 	(line profit_top1 year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
		(line profit_other year, cmissing(no) lcolor(eltblue*1.2) lpattern(dash) lwidth(medthick)) ///
		if sector_main == "Construction" & year <= 2013 & year >= 1931, ///
		ytitle(" ", size(`size')) xtitle("") title("Construction", size(`size2')) ///
		ylabel(-0.1 "-0.1" 0 "0" 0.1 "0.1", grid labsize(`size')) xlabel(1930(20)2010, grid labsize(`size')) ///
		legend(symxsize(*0.7) region(lwidth(none)))	///
		name(con_Construction, replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw	 
local allnames `allnames' con_Construction

twoway 	(line profit_top1 year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
		(line profit_other year, cmissing(no) lcolor(eltblue*1.2) lpattern(dash) lwidth(medthick)) ///
		if sector_main == "Finance" & year <= 2013 & year >= 1931, ///
		ytitle("Ratio", size(`size')) xtitle("") title("Finance", size(`size2')) ///
		ylabel(-0.4 "-0.4" -0.2 "-0.2" 0 "0" 0.2 "0.2" 0.4 "0.4", grid labsize(`size')) xlabel(1930(20)2010, grid labsize(`size')) ///
		legend(symxsize(*0.7) region(lwidth(none)))	///
		name(con_Finance, replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw	
local allnames `allnames' con_Finance

twoway 	(line profit_top1 year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
		(line profit_other year, cmissing(no) lcolor(eltblue*1.2) lpattern(dash) lwidth(medthick)) ///
		if sector_main == "Manufacturing" & year <= 2013 & year >= 1931, ///
		ytitle(" ", size(`size')) xtitle("") title("Manufacturing", size(`size2')) ///
		ylabel(-0.1 "-0.1" 0 "0" 0.1 "0.1" 0.2 "0.2", grid labsize(`size')) xlabel(1930(20)2010, grid labsize(`size')) ///
		legend(symxsize(*0.7) region(lwidth(none)))	/// 
		name(con_Manufacturing, replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw
local allnames `allnames' con_Manufacturing

twoway 	(line profit_top1 year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
		(line profit_other year, cmissing(no) lcolor(eltblue*1.2) lpattern(dash) lwidth(medthick)) ///
		if sector_main == "Mining" & year <= 2013 & year >= 1931, ///
		ytitle(" ", size(`size')) xtitle("") title("Mining", size(`size2')) ///
		ylabel(-0.2 "-0.2" 0 "0" 0.2 "0.2" 0.4 "0.4", grid labsize(`size')) xlabel(1930(20)2010, grid labsize(`size')) ///
		legend(symxsize(*0.7) region(lwidth(none)))	///
		name(con_Mining, replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw
local allnames `allnames' con_Mining

twoway 	(line profit_top1 year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
		(line profit_other year, cmissing(no) lcolor(eltblue*1.2) lpattern(dash) lwidth(medthick)) ///
		if sector_main == "Services" & year <= 2013 & year >= 1931, ///
		ytitle("Ratio", size(`size')) xtitle("") title("Services", size(`size2')) ///
		ylabel(-0.2 "-0.2" -0.1 "-0.1" 0 "0" 0.1 "0.1" 0.2 "0.2", grid labsize(`size')) xlabel(1930(20)2010, grid labsize(`size')) ///
		legend(symxsize(*0.7) region(lwidth(none)))	///
		name(con_Services, replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw
local allnames `allnames' con_Services

twoway 	(line profit_top1 year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
		(line profit_other year, cmissing(no) lcolor(eltblue*1.2) lpattern(dash) lwidth(medthick)) ///
		if sector_main == "Trade" & year <= 2013 & year >= 1931, ///
		ytitle(" ", size(`size')) xtitle("") title("Trade", size(`size2')) ///
		ylabel(-0.1 "-0.1" 0 "0" 0.1 "0.1", grid labsize(`size')) xlabel(1930(20)2010, grid labsize(`size')) ///
		legend(symxsize(*0.7) region(lwidth(none)))	///
		name(con_Trade, replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw
local allnames `allnames' con_Trade


twoway 	(line profit_top1 year, cmissing(no) lcolor(navy) mcolor(navy) lwidth(medthick)) ///
		(line profit_other year, cmissing(no) lcolor(eltblue*1.2) lpattern(dash) lwidth(medthick)) ///
		if sector_main == "Utilities" & year <= 2013 & year >= 1931, ///
		ytitle(" ", size(`size')) xtitle("") title("Utilities", size(`size2')) ///
		ylabel(-0.1 "-0.1" 0 "0" 0.1 "0.1" 0.2 "0.2" 0.3 "0.3", grid labsize(`size')) xlabel(1930(20)2010, grid labsize(`size')) ///
		legend(symxsize(*0.7) region(lwidth(none)))	///
		name(con_Utilities, replace) plotregion(margin(l=1.25 r=1.25)) graphregion(margin(medium)) nodraw
local allnames `allnames' con_Utilities

grc1leg `allnames', iscale(*0.95) cols(3) scheme(s1color) graphregion(margin(tiny)) name(all_graph, replace)
resize all_graph, ysize(4.5) xsize(5.5)
graph export "$FIGURE/FigureIA13.pdf", replace  