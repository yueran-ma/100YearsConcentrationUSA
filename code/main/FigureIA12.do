/************ Function ************/

*This file makes Figure IA12 of the paper on aggregate relative top shares 

/************ Source ************/

*"output/other/bds_concent.dta" compiled by code/clean/compute_concentration_bds.do

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

use  "$OUTPUT/other/bds_concent.dta", replace

rename * *bds
rename yearbds year

twoway 	(line top_share_1pctbds year) ///
		(line top_share_0_1pctbds year, lpattern(dash) lcolor(midblue)) if year<= 2018, ///
		ytitle("Employment Share") xtitle("") ///
		ylabel(0.3(0.05)0.6, format(%03.2f)) ///
		legend(label(1 "Top 1%") label(2 "Top 0.1%"))
graph export "$FIGURE/FigureIA12.pdf", replace

