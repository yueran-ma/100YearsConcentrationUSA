/************ Function ************/

*This file makes Figure IA of the paper on top 5000 receipt shares 

/************ Source ************/

*"output/soi/topshares/sector_type_concent_R5.dta" (tabulations including noncorporations), "output/soi/topshares/sector_concent_R5.dta" (baseline), "output/soi/topshares/sector_concent_topN_R5.dta" (topN corps) compiled by code/clean/compute_concentration_sector.do

/************ Note ************/

*5000in1980 suffix means we fix the x% in top x% to be 5000/total number of businesses in 1980

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
keep if tables == "Combined"

merge 1:1 sector_main year using "$OUTPUT/soi/topshares/sector_concent_topN_R5.dta", nogen keepusing(tsh_receipts_ipol_5000in1980all)
sort sector_main year

// Inconsistency in the integrated business data for Finance (confirmed by SOI staff)
replace top_share_5000in1980 = . if tables == "Combined" & sector_main == "Finance" & year > 1990
replace top_share_5000firms  = . if tables == "Combined" & sector_main == "Finance" & year > 1990


// Can't separate farm sole proprietorships in the tabulation from other sole proprietorships in Agriculture before 1981, drop estimate
replace top_share_5000in1980 = . if tables == "Combined" & sector_main == "Agriculture" & year <= 1980
replace top_share_5000firms  = . if tables == "Combined" & sector_main == "Agriculture" & year <= 1980

// Plot
local size medlarge
local size2 large
local s_list All Agriculture Construction Finance Manufacturing Mining Services Trade Utilities
local s_name ""All (X=0.04)" "Agriculture (X=0.1)" "Construction (X=0.35)" "Finance (X=0.23)" "Manufacturing (X=0.88)" "Mining (X=2.77)" "Services (X=0.1)" "Trade (X=0.14)" "Utilities (X=0.88)""
local ytlist ""Share" " " " " "Share" " " " " "Share" " ""

local ylabs ""0.3(0.1)0.7""0.3(0.1)0.7" "0.1(0.1)0.5" "0.6(0.1)1" "0.6(0.1)1" "0.6(0.1)1" "0.1(0.1)0.5" "0.3(0.1)0.7""0.6(0.1)1""

local snum : word count `s_list'

local allnames ""

forvalues i = 1 / `snum' {
	local s : word `i' of `s_list'
	local sn : word `i' of `s_name'
	local yt : word `i' of `ytlist'
	local yc : word `i' of `yclist'		
	local yl: word `i' of `ylabs'
	
	twoway	(line tsh_receipts_ipol_5000in1980 year, lpattern(solid shortdash dash) ///
			lwidth(medthick medium medthick) color(eltblue navy navy)) ///
			(scatter top_share_5000in1980 top_share_5000firms year, msymbol(T D) msize(small small) color(eltblue navy)) ///
			if sector_main == "`s'" & year >= 1959 & year <= 2013, ///
			ytitle("`yt'", size(`size')) xtitle("", size(`size')) title(`sn', size(`size2')) ///
			ylabel(`yl', format(%03.1f) labsize(`size')) xlabel(1960(20)2010, labsize(`size')) ///
			legend(label(1 "Top X% Corps in Corp") label(2 "Top X% Businesses in All") label(3 "Top 5,000 Businesses in All") ///
			order(3 2 1) cols(3) symxsize(*0.6)) ///
			name(con_`s', replace) plotregion(margin(small)) graphregion(margin(medium)) nodraw 
			local allnames `allnames' con_`s'
}

grc1leg `allnames', iscale(*0.95) cols(3) scheme(s1color) graphregion(margin(tiny)) name(all_graph, replace)
graph export "$FIGURE/FigureIA8.pdf", replace  
