/************ Function ************/

*This file compiles corporate profit before tax from NIPA data


/************ Source ************/

*"$DATA/bea/BEAbyInd_profits.xls" downloaded from https://apps.bea.gov/iTable/?reqid=19&step=2&isuri=1&categories=survey (Table 16)
 
clear all


/* Pre tax profits with IVA and CCAdj */

// 1929-1948 
import excel "$DATA/bea/BEAbyInd_profits.xlsx", sheet("29_47") cellrange(C9:U9) clear  

local t = 1929
foreach v of varlist C - U {
	rename `v' NINC`t'
	local t = `t' + 1
}

gen Line = _n

reshape long NINC, i(Line) j(year)

drop Line

tempfile NINCpart1
save "`NINCpart1'"

// 1948-87
import excel "$DATA/bea/BEAbyInd_profits.xlsx", sheet("48_87") cellrange(C9:AP9) clear  

local t = 1948
foreach v of varlist C - AP {
	rename `v' NINC`t'
	local t = `t' + 1
}

gen Line = _n

reshape long NINC, i(Line) j(year)

drop Line

drop if year >= 1987

tempfile NINCpart2
save "`NINCpart2'"

// 1987-2000
import excel "$DATA/bea/BEAbyInd_profits.xlsx", sheet("87_00") cellrange(C9:P9) clear  

local t = 1987
foreach v of varlist C - P {
	rename `v' NINC`t'
	local t = `t' + 1
}

gen Line = _n

reshape long NINC, i(Line) j(year)

drop Line

drop if year >= 1998

tempfile NINCpart3
save "`NINCpart3'"

// 1998-2023
import excel "$DATA/bea/BEAbyInd_profits.xlsx", sheet("98_23") cellrange(C9:AB9) clear  

local t = 1998
foreach v of varlist C - AB {
	rename `v' NINC`t'
	local t = `t' + 1
}

gen Line = _n

reshape long NINC, i(Line) j(year)

drop Line

tempfile NINCpart4
save "`NINCpart4'"

//Combine
clear
forvalues k = 1 / 4 {
	append using "`NINCpart`k''"
}

order 	year

ren 	NINC NINC_bea

label var year	   "Year"
label var NINC_bea "Profit before Tax (BEA)"

save "$OUTPUT/other/BEAProfit_out.dta", replace

