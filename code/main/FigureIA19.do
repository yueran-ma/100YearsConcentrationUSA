/************ Function ************/

*This file makes Figure IA19 of the paper  

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

twoway 	(connected tsh_assets_ipol_1pct year if sector_main == "All") ///
		(connected tsh_assets_ipol_1pct year if sector_main == "Manufacturing", color(eltblue)) if year >= 1930, ///
		xline(1934, lpattern(dash_dot)) xline(1954, lcolor(gs10) lpattern(longdash)) xline(1964, lcolor(navy)) ///
		ytitle("Share") xtitle("") ylabel(, format(%03.1f)) xlabel(1930 (20) 2010) ///
		legend(order(1 2) label(1 "All") label(2 "Manufacturing")) ///
		graphregion(margin(small))
graph export "$FIGURE/FigureIA19.pdf", replace 
 
