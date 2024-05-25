clear all

***** Program settings *****

set matsize 11000
set more off, permanently
set type double

***** Rscript settings *****

* Find your Rscript path: file.path(R.home("bin"), "Rscript"). 

if ("`c(username)'" == "yueranma") |  ("`c(username)'" == "Yueran Ma") {
	global		Rdirscript		"C:/PROGRA~1/R/R-43~1.1/bin/x64/Rscript"
}
else {
	global		Rdirscript		"C:/Users/Zimmermann-K/AppData/Local/Programs/R/R-4.3.1/bin/x64/Rscript"
}
* global Rdirscript "C:\Program Files\R\R-4.3.1\bin\x64\Rscript.exe" 


***** Paths *****

* Paths relative to code/clean and code/main folder
global DATA 	"../../input"
global OUTPUT 	"../../output"
global FIGURE 	"../../figures"
global TABLE 	"../../tables"

global RWORKDIR "`c(pwd)'/.." // get main directory and pass it to R


***** Utility File *****

do 						utility_stata.do
shell "$Rdirscript" 	utility_R.R
shell pip install -r 	utility_python.txt

***** Data Preparation and Interpolation *****

cd ./clean/

/* Clean raw SOI data */
do				generate_aggregate.do
do 				generate_by_sector_by_assets.do 
do 				generate_by_sector_by_receipts.do 
do 				generate_by_sector_by_ninc.do 
do 				generate_by_assets_part.do
do 				generate_by_sector_by_receipts_noncorp.do 
do				generate_by_sector_by_assets_2012_cross_section.do

/* Estimate top shares */
do 				compute_concentration_bds.do
do 				compute_concentration_agg.do
do 				compute_concentration_sector.do
do 				compute_concentration_sector_lognormal.do
do 				compute_concentration_manufacturing.do
do 				compute_concentration_robustness.do
do 				compute_concentration_subsector.do

/* Combine Stata datasets into a joint excel spreadsheet */
do 				generate_excel.do

/* External datasets */
do 				BEA_profit.do
do				clean_census_9712.do
python script	fof.py
python script 	international.py


***** Figures and Tables *****

* If you are in code/clean folder, you need to back to upper folder and then go to main folder.
cd ./main/


// Paper Figures
do Figure1.do
do Figure2.do
do Figure3.do
do Figure4.do
do Figure5.do
do Figure6.do
do Figure7.do
do Figure8.do
do Figure9.do


// Paper Tables
do Table2.do
do Table3.do


// Appendix Figures
do FigureIA1.do
do FigureIA2.do
do FigureIA3.do
do FigureIA4.do
do FigureIA5.do
do FigureIA6.do
do FigureIA7.do
do FigureIA8.do
do FigureIA9.do
do FigureIA10.do
do FigureIA11.do
do FigureIA12.do
do FigureIA13.do
do FigureIA14.do
do FigureIA15.do
do FigureIA16.do
do FigureIA17.do
do FigureIA18.do
do FigureIA19.do


