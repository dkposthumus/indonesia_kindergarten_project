/*
capture log close
log using  90_ifls4_master, replace text
*/

/*
  program:    	90_ifls4_master.do
  task:			Master do-file for all ifls4 code.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 02Aug2023
*/

version 17
clear all
set linesize 80
macro drop _all

****************************************************************************************
* Set Global Macros              ****************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~/thesis_independent_study/work/code/complete"
****************************************************************************************
* Run all do-files ****************************************************************************************
cd "$code/ifls4"
	do 01_ifls4_sample.do
cd "$code/ifls4"
	do 02_ifls4_ek_scores.do
cd "$code/ifls4"
	do 03_ifls4_cf_schls.do
cd "$code/ifls4"
	do 04_ifls4_household_char.do
cd "$code/ifls4" 
	do 05_ifls4_cf_shocks.do
****************************************************************************************
* Merge data files ****************************************************************************************
cd "$clean/ifls4_hh"
	use ifls4_sample, clear
merge 1:1 pid07 hhid07 using ifls4_ek_scores
	keep if _merge == 1 | _merge == 3
		drop _merge 
			cd "$clean/ifls4_cf"
merge m:1 commid07 using ifls4_cf_schools
	keep if _merge == 1 | _merge == 3
		drop _merge
merge m:1 commid07 using ifls4_cf_shocks 
	keep if _merge == 1 | _merge == 3 
		drop _merge
			cd "$clean/ifls4_hh"
merge m:1 hhid07 using ifls4_household_char
	keep if _merge == 1 | _merge == 3
		drop _merge
****************************************************************************************
* Finishing Up 
****************************************************************************************
label data "ifls4 master"
compress

cd "$clean/ifls4_hh"
save ifls4_master, replace
/*
log close
exit
*/









