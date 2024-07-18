/************ Function ************/

*This file makes Figure IA16 of the paper on robustness to returns without balance sheets

/************ Source ************/

*"output/soi/topshares/agg_concent_adj_R5.dta" compiled by "code/clean/compute_concentration_robustness.do" 
*"output/soi/topshares/sector_concent_R5.dta" compiled by code/clean/compute_concentration_sector.do 
*"output/soi/topshares/sector_brackets_assets_R5.dta" compiled by code/clean/by_sector_by_assets_generate_dataset.do
*"input/soi/digitized/corp_totals_pre1959_R5.dta"

clear all


******************************************************
* set graph style
set scheme s2color
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox
grstyle set symbol
******************************************************

// Tabulation data 
use "$OUTPUT/soi/brackets/sector_brackets_assets_R5.dta", clear

drop *deletion*

collapse (mean) *_total, by(sector_main year)

keep if year < 1959
keep if sector_main == "All"

// Baseline top share estimate 
merge 1:1 sector_main year using "$OUTPUT/soi/topshares/sector_concent_R5.dta", keep(1 3) nogen 

// Total numbers 
merge 1:1 sector_main year using "$DATA/soi/digitized/corp_totals_pre1959_R5.dta", keep(1 3) keepusing(all*) nogen

tempfile tmp
save "`tmp'"

// With imputed assets
use "$OUTPUT/soi/topshares/agg_concent_adj_R5.dta", replace
	
merge 1:1 year using "`tmp'", nogen

gen double r_number  	= number_total / allnumber
gen double r_treceipts  = treceipts_total / alltreceipts
label var r_number 		"Share of Returns with Balance Sheets by Number"
label var r_treceipts 	"Share of Returns with Balance Sheets by Receipts"

// Appendix Figure: Returns With Balance Sheets
twoway	(connected r_number year, color(navy)) ///
		(connected r_treceipts year, color(eltblue) lpattern(dash)) if sector_main == "All" & year < 1959 & year >= 1930, ///
		ytitle("Share") xtitle("") title("Returns with Balance Sheets") ylabel(, format(%03.2f)) ///
		legend(cols(1)) ///
		name(receipts, replace) 

// Top 1% Asset Shares with Imputed Assets
twoway 	(connected tsh_assets_ipol_1pct year, color(navy)) ///
		(connected tsh_assets_ipoladj_1pct year, lpattern(dash) color(eltblue)) if sector_main == "All" & year < 1959 & year >= 1930, ///
		xtitle("") title("Top 1% Asset Shares with Imputed Assets") ylabel(, format(%03.2f)) xlabel(1930(10)1960) ///
		legend(label(1 "Baseline") label(2 "Adjusted") order(1 2) cols(1)) ///
		name(top1, replace) 
		
graph combine receipts top1, iscale(*1.3) ysize(7) xsize(15) graphregion(margin(small))  
graph export "$FIGURE/FigureIA16.pdf", replace

