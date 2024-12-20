/*
capture log close
log using 01_merge, replace text
*/

/*
  program:    	01_merge.do
  task:			Master merge do-file for all code, creating UNRESTRICTED sample.
  
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
	global output "~/thesis_independent_study/work/writing/rough_draft/data_methods"
****************************************************************************************
* Run all do-files ****************************************************************************************
cd "$code/ifls1"
cd "$code/ifls2"
	do 90_ifls2_master
cd "$code/ifls3"
	do 90_ifls3_master
cd "$code/ifls4"
	do 90_ifls4_master
cd "$code/ifls5"
	do 90_ifls5_master
***************************************************************************************
* Merge data files and generate attrition variables ***************************************************************************************
* We want to bring in the household data from IFLS2.
	* Our sample restriction for IFLS 2 data is simple: it consists of everyone who appears on a household survey, since our primary focus is on the household\parental characteristics.
cd "$clean/ifls2_hh"
	use ifls2_master, clear
* Let's bring in the data from IFLS3:
cd "$clean/ifls3_hh"
	merge 1:1 pidlink using ifls3_master
		gen ifls3_attrition = 1 if _merge == 1 
			replace ifls3_attrition = 0 if _merge == 3 
				drop _merge 
				label var ifls3_attrition "was lost to attrition from ifls2 to ifls3"
cd "$clean/ifls4_hh"
	merge 1:1 pidlink using ifls4_master
		gen ifls4_attrition = 1 if _merge == 1 & ifls3_attrition == 0 
			replace ifls4_attrition = 0 if _merge == 3 & ifls3_attrition == 0
				drop _merge 
				label var ifls4_attrition "was lost to attrition from ifls3 to ifls4"
cd "$clean/ifls5_hh"
	merge 1:1 pidlink using ifls5_master
		gen ifls5_attrition = 1 if _merge == 1 & ifls4_attrition == 0 
			replace ifls5_attrition = 0 if _merge == 3 & ifls4_attrition == 0 
				drop _merge 
				label var ifls5_attrition "was lost to attrition from ifls4 to ifls5"
* Now a variable capturing whether an observation was EVER lost to attrition:
gen ev_attrition = 1 if ifls3_attrition == 1 | ifls4_attrition == 1 | ifls5_attrition == 1
	replace ev_attrition = 0 if ifls3_attrition == 0 & ifls4_attrition == 0 & ifls5_attrition == 0
	label var ev_attrition "was ever lost to attrition across any wave?"
***************************************************************************************
* Finishing Up 
***************************************************************************************
	local tag 01_merge.do
foreach v in ifls3_attrition ifls4_attrition ifls5_attrition ev_attrition {
	notes `v': `tag'
}
	compress
cd "$clean"
save master, replace

/*
log close
exit
*/









