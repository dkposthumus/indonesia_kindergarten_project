/*
capture log close
log using 90_ifls5_master, replace text
*/

/*
  program:    	90_ifls5_master.do
  task:			Master do-file for all ifls5 code.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
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
****************************************************************************************
* Run all do-files ****************************************************************************************
cd "$code/ifls5"
	do 01_ifls5_sample
cd "$code/ifls5"
	do 02_ifls5_kinder_variables
cd "$code/ifls5"
	do 03a_ifls5_educ_variables
cd "$code/ifls5"
	do 03b_ifls5_educ_variables
cd "$code/ifls5"
	do 04_ifls5_ek_scores
cd "$code/ifls5"
	do 05_ifls5_labor_force_participation
cd "$code/ifls5"
	do 06_ifls5_earnings
cd "$code/ifls5"
	do 07_ifls5_geo
cd "$code/ifls5"
	do 08_ifls5_cf_schls
cd "$code/ifls5"
	do 09_ifls5_household_char
cd "$code/ifls5" 
	do 10_ifls5_cf_shocks
****************************************************************************************
* Merge data files ****************************************************************************************
cd "$clean/ifls5_hh"
	* We're going to begin with our sample dataset; we want to keep all observations in this `base' dataset, no matter whether they're missing observations in the datasets that we're merging onto our sample.
use ifls5_sample, clear
merge 1:1 hhid14_9 pid14 using ek_scores14
	* For each merging, we are only keeping observatons present in our sample data; thus, those observations that upon merging have _merge == 1 | _merge == 3
	keep if _merge == 1 | _merge == 3
	drop _merge
merge 1:1 hhid14_9 pid14 using ifls5_labor_force
	keep if _merge == 1 | _merge == 3
	drop _merge
merge 1:1 hhid14_9 pid14 using ifls5_earnings
	keep if _merge == 1 | _merge == 3
	drop _merge
merge 1:1 hhid14_9 pid14 using ifls5_educ_variables
	keep if _merge == 1 | _merge == 3
	drop _merge
merge m:1 hhid14_9 using ifls5_geo
	keep if _merge == 1 | _merge == 3 
	drop _merge
		cd "$clean/ifls5_cf" 
merge m:1 commid14 using ifls5_cf_schools
	keep if _merge == 1 | _merge == 3
	drop _merge
merge m:1 commid14 using ifls5_cf_shocks 
	keep if _merge == 1 | _merge == 3
	drop _merge
		cd "$clean/ifls5_hh"
merge m:1 hhid14_9 using ifls5_household_char
	keep if _merge == 1 | _merge == 3
	drop _merge
* Now let's check the duplicative properties of our identifiers:
duplicates report pidlink 
	* pidlink is a unique identifier! Our IFLS5 Sample is thus complete.
*****************************************************************************************
* Finishing Up *****************************************************************************************
label data "ifls5 master"
	compress
cd "$clean/ifls5_hh"
save ifls5_master, replace

/*
log close
exit
*/









