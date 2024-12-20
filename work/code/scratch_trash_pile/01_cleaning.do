* capture log close
* log using _do_file_name_, replace text

//  program:    02_hh_bk1_cleaning.do
//  task:		moving the hh bk1 datasets to the clean directory
//  project:	Independent Study/Honors Thesis (Daniel Posthumus)
//  author:     Daniel_Posthumus \ 03/15/2023

version 17
clear all
set linesize 80
macro drop _all

********************************************************************************Set Global Macros              ********************************************************************************

global raw "/Users/danielposthumus/thesis_independent_study/work/data_raw"

global clean "/Users/danielposthumus/thesis_independent_study/work/data_clean"

********************************************************************************Move files to clean folder ********************************************************************************

/*

	We are concerned with the following datasets, and the do-files utilizing 
	them:
		- b3a_dl1
			- 02_kinder_variables.do
			- 

*/

foreach file in b3a_dl1  {
	
	cd "$raw/ifls5_hh"
	use `file', clear
	
	cd "$clean/ifls5_hh"
	compress
	save `file', replace
	
}

* log close
* exit
