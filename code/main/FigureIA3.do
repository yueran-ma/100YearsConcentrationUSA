/************ Function ************/

*This file makes Figure IA3 of the paper on top shares in main sectors 

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

***********************************************
**                  Panel A                  **
***********************************************

use "$OUTPUT/soi/topshares/sector_concent_R5.dta", replace

gen decade = floor((year - 1) / 10) * 10
keep if decade == 1930 | decade == 1970 | decade == 2010

collapse (mean) tsh_assets_ipol_1pct tsh_assets_ipol_0_1pct, by(sector_main decade)

sort sector_main decade

gen 					time 					= 1 							if decade == 1930
replace 				time 					= 2 							if decade == 1970
replace 				time 					= 3 							if decade == 2010

order time
encode sector_main, gen(sector_ID)
tsset sector_ID time

// Difference over time
gen double					dtop_share_1pct 		= d.tsh_assets_ipol_1pct
gen double					dtop_share_0_1pct		= d.tsh_assets_ipol_0_1pct

gen double					tsort 					= dtop_share_1pct 			if time == 3
by sector_ID: egen double	temp_sort 				= mean(dtop_share_1pct)
gen double 					dtop_share_1pct_1970 	= dtop_share_1pct 			if time == 2
gen double 					dtop_share_1pct_2013	= dtop_share_1pct 			if time == 3

graph dot 	dtop_share_1pct_1970 dtop_share_1pct_2013 if time != 1 & sector_main != "All" & sector_main != "Nonfinancial" & sector_main != "Other", ///
			over(sector_main, sort(dtop_share_1pct_2013 ) label(labsize(small))) linetype(line) lines(lcolor(gs12) lw(vthin)) ///
			ytitle("Change in Top 1% Asset Share") ///
			ylabel(0 "0" 0.1 "0.1" 0.2 "0.2" 0.3 "0.3", format(%03.1f)) ///
			legend(label(1 "1930s-1970s") label(2 "1970s-2010s")) marker(1, mcolor(navy)) marker(2, msymbol(diamond_hollow) mcolor(maroon))   
graph export "$FIGURE/FigureIA3_PanelA.pdf", replace 


***********************************************
**                  Panel B                  **
***********************************************

use "$OUTPUT/soi/topshares/subsector_concent_R5.dta", replace

gen decade = floor((year - 1) / 10) * 10
keep if decade == 1930 | decade == 1970 | decade == 2010

collapse (mean) tsh_assets_ipol_1pct tsh_assets_ipol_0_1pct, by(subsector_BEA decade)

sort subsector_BEA decade

gen 					time 					= 1 							if decade == 1930
replace 				time 					= 2 							if decade == 1970
replace 				time 					= 3 							if decade == 2010

drop if subsector_BEA == "Agriculture"
drop if subsector_BEA == "Construction"

// Only one data point
drop if subsector_BEA == "Manufacturing: Plastics"
drop if subsector_BEA == "Finance: Real Estate" 

order time
encode subsector_BEA, gen(subsector_ID)
tsset subsector_ID time

// Difference over time
gen double 						dtop_share_1pct 		= d.tsh_assets_ipol_1pct
gen double 						dtop_share_0_1pct 		= d.tsh_assets_ipol_0_1pct

gen double 						tsort 					= dtop_share_1pct 		if time == 2
by subsector_ID: egen double	temp_sort 				= mean(dtop_share_1pct)
gen double 						dtop_share_1pct_1970 	= dtop_share_1pct 		if time == 2
gen double 						dtop_share_1pct_2013 	= dtop_share_1pct 		if time == 3

graph dot 	dtop_share_1pct_1970 dtop_share_1pct_2013,  ///
			over(subsector_BEA, sort(dtop_share_1pct_2013 ) label(labsize(vsmall))) linetype(line) lines(lcolor(gs12) lw(vthin)) ///
			ytitle("Change in Top 1% Asset Share") ///
			ylabel(-0.1 "-0.1" 0 "0" 0.1 "0.1" 0.2 "0.2" 0.3 "0.3" 0.4 "0.4") ///
			legend(label(1 "1930s-1970s") label(2 "1970s-2010s")) marker(1, mcolor(navy)) marker(2, msymbol(diamond_hollow) mcolor(maroon)) 
graph export "$FIGURE/FigureIA3_PanelB.pdf", replace

