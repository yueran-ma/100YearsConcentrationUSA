/************ Function ************/

*This file deals with outliers and changes in consolidation in the 1930s in the main sectors 

encode sector_main, gen(sector_ID)
tsset sector_ID year

*******************************
*======= Outliers =========
*******************************

*===== Step 1: Identify individual outliers ===========

gen 	outlier = .
replace outlier = 1 if sector_main == "Agriculture" & year == 1977				// too many bracket deletions in source book file
replace outlier = 1 if sector_main == "Agriculture" & year == 1978				// too many bracket deletions
replace outlier = 1 if sector_main == "Services" 	& year == 2011				// too many bracket deletions in services components


gen 	outlier_addingup = .
replace outlier_addingup = 1 if sector_main == "Agriculture"  & year == 1962
replace outlier_addingup = 1 if sector_main == "Agriculture"  & year == 1977	// too many bracket deletions in source book file
replace outlier_addingup = 1 if sector_main == "Agriculture"  & year == 1978	// too many bracket deletions
replace outlier_addingup = 1 if sector_main == "Construction" & year == 1978	// too many bracket deletions
replace outlier_addingup = 1 if sector_main == "Trade" 		  & year == 1962

*===== Step 2: Drop concentration estimates for these sector years =========

cap foreach l of varlist tsh_assets_ipol* {
    local vlist "`vlist' `l'"
}

// Drop outliers
foreach v of local vlist {
    replace 			`v' 	= .		if outlier == 1
}

cap foreach v of varlist tsh_assets_add* {
    cap replace 		`v' 	= . 	if outlier == 1
	cap replace 		`v' 	= . 	if outlier_addingup == 1
}


*===== Step 3: Interpolate concentration for outlier years ====

// For Interpolation: interpolate all gaps
foreach v of local vlist  {
	cap drop 			d
    rename 				`v' old`v'
    sort 				sector_ID year
    by sector_ID: 		ipolate old`v' year, gen(`v') 
}
cap drop old*

// For Adding up: interpolate only gaps due to outliers
cap foreach v of varlist tsh_assets_add* {
	cap drop 			d
    cap rename 			`v' old`v'
    cap sort 			sector_ID year
    cap by sector_ID: 	ipolate old`v' year, gen(`v') 
	cap replace 		old`v' 	= `v' 	if outlier_addingup == 1 | outlier == 1
	cap drop 			`v'
	cap rename 			old`v' `v'
}


*******************************
*==== Consolidation =========
*******************************

sort sector_ID year

// Consolidation adjustment for 1934 to 1941 (consolidated returns not allowed between 1934 and 1941)
foreach v of varlist tsh* {
	
	// If sectors have data before and after: take the level difference between 1933 and 1942 that is not accounted for by the year-to-year changes and divide it equally between all years 
	gen double 					change 			= d.`v'
	by sector_ID: egen double 	tmp 			= sum(change) 					if year >= 1935 & year <= 1941
	by sector_ID: egen double	change_33_42 	= mean(tmp)
	drop 						change tmp

	gen double					temp33 			= `v' 							if year == 1933
	by sector_ID: egen double	lev33 			= mean(temp33)
	gen double					temp42 			= `v' 							if year == 1942
	by sector_ID: egen double	lev42 			= mean(temp42)
	drop 						temp33 temp42 

	gen double					scale 			= (lev42 - lev33) - change_33_42
	gen double					`v'a 			= `v' 							if year < 1934 | year > 1941
	replace 					`v'a 			= `v'a[_n-1] + scale/9 			if year == 1934 
	replace 					`v'a 			= `v'a[_n-1] + scale/9 + d.`v' 	if year >= 1935 & year < 1942 
	drop 						scale change_33_42 lev42 lev33

	// If we only have data afterwards: assume that concentration did not change between 1941 and 1942 and rescale series before
	by sector_ID, sort: egen 	firsttime 		= min(cond(`v' != ., year, .))
	gen double					change 			= d.`v' 						if year == 1942
	by sector_ID: egen double	tmp_ch 			= mean(change)
	replace 					`v'a 			= `v' + tmp_ch 					if year <= 1941 & firsttime > 1933 & firsttime != . 
	drop 						firsttime change tmp_ch

	replace `v' = `v'a
	drop `v'a
}

drop outlier*

