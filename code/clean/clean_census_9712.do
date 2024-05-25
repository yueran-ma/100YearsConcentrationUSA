/************ Function ************/

*This file cleans Census CRx data for 1997 to 2012

/************ Source ************/

*Source files from Census FTP server: https://www2.census.gov/programs-surveys/economic-census/data/. Saved in input/census folder. 

/************ Notes ************/

*Different years have different variable naming conventions. 
*Manufacturing industries and non-manufacturing industries also have different variable naming conventions and structure.
	*Manufacturing industries only have totals for all firms, not for topx; other industries have totals for both all firms and topx.
	*1997 manufacturing: one row per industry; all other files: one row per industry and CRx.
*So we process nonmanufacturing and manufacturing industries separately. 

/************ Steps ************/

*Pool nonmanufacturing data across years, then reshape to one row per industry for each year. 
*Pool manufacturing data from 2002 to 2012, then reshape to one row per industry for each year.
*Go to manufacturing data for 1997, which is one row per industry and CRx, and merge in the previous parts. 

clear all


**************************************************
*******      Import non-manufacturing      *******
**************************************************

*** Read in raw data ***

foreach yy in 97 02 07 12 {
	
foreach ind in 22 42 44 48 51 52 53 54 56 61 62 71 72 81 {
	
	if `yy' == 97 {
		
		import delimited "$DATA/census/97/e97`ind's6/E97`ind'S6.dat", clear
		
	}
	
	else if `yy' == 02 | `yy' == 07 | `yy' == 12 {
		
		if `yy' == 12 {
			import delimited "$DATA/census/`yy'/EC`yy'`ind'SSSZ6.dat", clear
			cap ren *_ttl *_meaning													// this naming convention only applies in 2012
		}
		
		else {
			import delimited "$DATA/census/`yy'/EC`yy'`ind'SSSZ6/EC`yy'`ind'SSSZ6.dat", clear
		}

		cap ren val_* val*														// this naming convention applies in 2007 and 2012
		
		// realign variable names to 1997 variable names
		ren *_f *f																// flag name 
		ren rcptot* ecvalue*													// sale/shipment 
		ren naics20`yy'* naics*													// naics
		drop foot*																// footnote

		// optax in these years is taxind in 1997 
		cap ren optax* taxind*
		// but for sector 42, optax in these years is optype in 1997, which denotes the type of operators
		if `ind' == 42 {
			ren taxind* optype*
		}
		
	}	
	
	keep sector - valpctf
	drop estab estabf
	
	foreach item of varlist *f naics {											// some industries have non-numerical values; others don't
		tostring `item', replace 
	}
	
	tempfile `yy'ec`ind'
	save "``yy'ec`ind''"
}
}

*** Append togeter ***

clear 

foreach yy in 97 02 07 12 {
foreach ind in 22 42 44 48 51 52 53 54 56 61 62 71 72 81 {
	append using "``yy'ec`ind''"
}
}

*** Clean data ***

// mark top share type
bysort year: tab concenfi
replace concenfi = 0 				if concenfi < 800 							// aggregate
replace concenfi = concenfi - 800 	if concenfi >= 800							// CRx
drop concenfi_meaning

// drop non-major operators in 42
tab sector if optype!=.
drop if optype != 0 & sector == 42
drop optype*

// use taxable firms if available, otherwise all firms/nontaxable firms: 1997 only has taxable vs nontaxable, other years have taxable, nontaxable, all
// if an industry does not have taxable firms, then all and nontaxable are the same
bysort year: tab taxind 														
gen 	tax = 0 if taxind == "N" | taxind == "Y"									// nontaxable
replace tax = 1 if taxind == "A"												// all 
replace tax = 2 if taxind == "T"												// taxable

bysort year naics: egen taxmax = max(tax)
drop if taxind != "" & tax != taxmax
drop tax* 

reshape wide ecvalue ecvaluef valpct valpctf, i(naics year) j(concenfi)

drop valpct0 valpctf0															// aggregate is always 100%

// rename to the convention of 1997 manufacturing data 
ren valpct* vstop*
ren vstopf* vstop*f
ren ecvaluef* ecvalue*f
drop ecvalue4* ecvalue8* ecvalue20* ecvalue50*
ren ecvalue0* ecvalue*

tempfile nm9712
save "`nm9712'"

********************************************************************
*******      Import manufacturing (has different format)     *******
********************************************************************

foreach yy in 02 07 12 {
	
foreach ind in 31 {

	else if `yy' == 02 | `yy' == 07 | `yy' == 12 {
		
		if `yy' == 12 {
			import delimited "$DATA/census/`yy'/EC`yy'`ind'SR2.dat", clear 
			cap ren *_ttl *_meaning													// this naming convention only applies in 2012
		}
		
		else {
			import delimited "$DATA/census/`yy'/EC`yy'`ind'SR12/EC`yy'`ind'SR12.dat", clear
		}

		ren ccorcppct* valpct*
	
		// realign variable names to 1997 variable names
		ren *_f *f																// flag name
		ren rcptot* ecvalue*													// sales/shipment
		ren naics20`yy'* naics*													// naics
		drop foot*																// footnote
		
	}
	
	keep sector - valpctf
	drop company*
	
	foreach item of varlist *f naics {
		tostring `item', replace 
	}
	
	tempfile `yy'ec`ind'
	save "``yy'ec`ind''"
}
}


*** Append togeter ***

clear 

foreach yy in 02 07 12 {
foreach ind in 31 {
	append using "``yy'ec`ind''"
}
}

*** Clean data ***

//mark top share type
bysort year: tab concenfi
replace concenfi = 0 				if concenfi < 800 							// aggregate
replace concenfi = 4 				if concenfi == 856							// CR4
replace concenfi = 8 				if concenfi == 857							// CR8
replace concenfi = 20 				if concenfi == 858							// CR20
replace concenfi = 50 				if concenfi == 859							// CR50
drop concenfi_meaning

reshape wide ecvalue ecvaluef valpct valpctf, i(naics year) j(concenfi)

drop valpct0 valpctf0															// aggregate is always 100%

ren valpct* vstop*
ren vstopf* vstop*f
ren ecvaluef* ecvalue*f
drop ecvalue4* ecvalue8* ecvalue20* ecvalue50*
ren ecvalue0* ecvalue*

tempfile m0212
save "`m0212'"

************************************************ 
*******      Put everything together     *******
************************************************ 

import delimited "$DATA/census/97/e9731r2/E9731R2.dat", clear 

keep sector - vstop50f
drop company*

foreach item of varlist *f naics {
	tostring `item', replace 
}

append using "`m0212'"

append using "`nm9712'"

ren vstop* CR*

// label variables 
foreach k in 4 8 20 50 {
	label var CR`k' "CR`k'"
	label var CR`k'f "CR`k' flag"
}

ren ecvalue value
label var value "Value"
ren ecvaluef valuef
label var valuef "Value flag"

// data suppresion: see more info here https://www.census.gov/programs-surveys/economic-census/year/2022/technical-documentation/data-dictionary.html 
replace value = . if valuef == "D"												// disclosure supression 
foreach item in CR4 CR8 CR20 CR50 {
	replace `item' = . 		if `item'f == "D"									// disclosure supression 
	replace `item' = 100 	if `item'f == "X"									// max out at 100% 
	replace `item' = 100 	if `item'f == "N"									// max out at 100% 
}

save "$OUTPUT/other/census9712.dta", replace
