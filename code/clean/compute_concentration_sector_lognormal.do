/************ Function ************/

*This file makes estimates top shares by interpolating lognormal curves

/************ Source ************/

*"output/soi/brackets/sector_brackets_assets_R5.dta" compiled by code/clean/generate_by_sector_by_assets.do


clear all


// Run Lognormal Interpolation
shell 	"$Rdirscript" "lognormal_code.R" "$RWORKDIR"
	
use "$OUTPUT/temp/sector_assets_lognormal.dta",clear


do "outliers_lognormal.do"

keep  sector_main year tsh_assets_ln_1pct
order sector_main year tsh_assets_ln_1pct

label var sector_main			"Main sector"
label var year 					"Year"
label var tsh_assets_ln_1pct 	"Top 1% asset share (lognormal interpolation)"
	
save "$OUTPUT/soi/topshares/sector_concent_lognorm_R5.dta",replace
capture erase "$OUTPUT/temp/sector_assets_lognormal.dta"
