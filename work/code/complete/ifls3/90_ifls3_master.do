/*
capture log close
log using  90_ifls3_master, replace text
*/

/*
  program:    	90_ifls3_master.do
  task:			Master do-file for all ifls3 code.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 02Aug2023
*/

version 17
clear all
set linesize 80
macro drop _all

***************************************************************************************
* Set Global Macros              ***************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~/thesis_independent_study/work/code/complete"
***************************************************************************************
* Run all do-files ***************************************************************************************
cd "$code/ifls3"
	do 01_ifls3_sample.do
cd "$code/ifls3"
	do 02_ifls3_ek_scores.do
cd "$code/ifls3"
	do 03_ifls3_cf_schls.do
cd "$code/ifls3"
	do 04_ifls3_household_char.do 
cd "$code/ifls3" 
	do 05_ifls3_cf_shocks.do
***************************************************************************************
* Merge data files ***************************************************************************************
cd "$clean/ifls3_hh"
	use ifls3_sample, clear
* We're beginning with our cleaned sample dataset -- this the broadest our sample can get so after every merge we're going to keep only if present in the master, even if it's not present in the using data:
merge 1:1 hhid00 pid00 using ifls3_ek_scores
	keep if _merge == 1 | _merge == 3
			drop _merge
		cd "$clean/ifls3_cf"
merge m:1 commid00 using ifls3_cf_schools
	keep if _merge == 1 | _merge == 3
			drop _merge
merge m:1 commid00 using ifls3_cf_shocks 
	keep if _merge == 1 | _merge == 3 
			drop _merge
		cd "$clean/ifls3_hh"
merge m:1 hhid00 using ifls3_household_char 
	keep if _merge == 1 | _merge == 3
			drop _merge
		cd "$clean/ifls3_hh"
***************************************************************************************
* Update labels for identifiers variables ***************************************************************************************
* I want to re-label these identifier variables to eliminate capitalized letters, maintaining consistent style for variable labels
label var hhid00 			"household id (2000)"
label var commid00 			"community id (2000)" 
label var pid00 			"person id (2000)"
label var pidlink			"person id (all years)"
***************************************************************************************
* Finishing Up ***************************************************************************************
cd "$clean/ifls3_hh"

label data "ifls3 master"
compress 

save ifls3_master, replace
/*
log close
exit
*/









