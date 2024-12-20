/*
capture log close
log using  90_ifls2_master, replace text
*/

/*
  program:    	90_ifls2_master.do
  task:			Master do-file for all ifls3 code.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 02Aug2023
*/

version 17
clear all
set linesize 80
macro drop _all

*******************************************************************************************
* Set Global Macros              *******************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~/thesis_independent_study/work/code/complete"
*******************************************************************************************
* Run all do-files *******************************************************************************************
cd "$code/ifls2"
	do 01_ifls2_sample.do
cd "$code/ifls2"
	do 02_ifls2_household_char.do
cd "$code/ifls2"
	do 03_ifls2_parental_educ.do
cd "$code/ifls2"
	do 04_ifls2_child_health.do
*******************************************************************************************
* Merge data files *******************************************************************************************
cd "$clean/ifls2_hh"
	use ifls2_sample, clear
* Since all the observations of our IFLS2 sample are contained in the ifls2_sample dataset, we are going to keep only the observations that appear in that sample when merging our other datasets onto it.
	merge 1:1 hhid97 pid97 using ifls2_child_health
		keep if _merge == 3
			drop _merge 
merge m:1 hhid97 using ifls2_household_char
	keep if _merge == 1 | _merge == 3
		drop _merge
merge m:1 hhid97 using ifls2_hh_head_educ
	keep if _merge == 1 | _merge == 3
		drop _merge
merge 1:1 hhid97 pid97 using ifls2_mother_educ
	keep if _merge == 1 | _merge == 3
			drop _merge 
		cd "$clean/ifls2_cf"
merge m:1 commid97 using ifls2_cf_schools
	keep if _merge == 1 | _merge == 3
		drop _merge
***************************************************************************************
* Update labels for identifiers variables ***************************************************************************************
* I want to re-label these identifier variables to eliminate capitalized letters, maintaining consistent style for variable labels
label var hhid97 			"household id (1997)"
label var commid97 			"community id (1997)" 
label var pid97 			"person id (1997)"
label var pidlink			"person id (all years)"
*******************************************************************************************
* Finishing Up *******************************************************************************************
	compress
	label data "ifls2 master"
cd "$clean/ifls2_hh"
save ifls2_master, replace

/*
log close
exit
*/









