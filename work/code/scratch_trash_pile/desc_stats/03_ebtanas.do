/*
capture log close
log using 03_ebtanas, replace text
*/

/*
  program:    	03_ebtanas.do
  task:			To clean and create a dataset ready for merging relating to 
				standardized test scores for students.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 20July2023
*/

version 17
clear all
set linesize 80
macro drop _all


********************************************************************************Set Global Macros              ********************************************************************************

global raw "/Users/danielposthumus/thesis_independent_study/work/data_raw"
global ifls2_hh "$raw/ifls2_hh"
global ifls3_hh "$raw/ifls3_hh"
global ifls4_hh "$raw/ifls4_hh"
global ifls5_hh "$raw/ifls5_hh"
global desc_stats "/Users/danielposthumus/thesis_independent_study/work/desc_stats"

global desc_stats_code "/Users/danielposthumus/thesis_independent_study/work/code/to_do/desc_stats"

********************************************************************************Pull EBTANAS scores ********************************************************************************

cd $ifls5_hh

use b3a_dl3, clear
tempfile ebtanas

/*

	We're going to create the variable level; this is going to be the 
	mechanism by which we reshape the data in order to be able to use pid97 
	and hhid97 as a unique identifier.
	
	We are going to base level off of dl3type: "Level of schooling"
	
	There are four possible values for level:
	- _elem
		- dl3type = 1 ("1:Elementary")
	- _junior
		- dl3type = 2 ("2:Junior high")
	- _senior
		- dl3type = 3 ("3:Senior high")
	- _d1
		- dl3type = 4 ("4:D1")
	
*/

tostring dl3type, gen("level")
replace level = "_elem" if dl3type == 1
replace level = "_junior" if dl3type == 2
replace level = "_senior" if dl3type == 3
replace level = "_d1" if dl3type == 4
drop if dl3type == .
drop dl3type

	* Creating a local for every variable label
local allvar "dl16b dl16c1 dl16dcx dl16ex dl16i dl16cx dl16c2 dl16dc dl16e dl16cmth dl16dbx dl16ddx dl16g dl16a dl16cyr dl16db dl16dd dl16ix"
foreach v in `allvar' {

	di `"`:var label `v''"'
	local label_`v' `"`:var label `v''"'
	
}

	* Reshape wide
reshape wide dl16*, i(pidlink hhid14 version module) j(level) string


	* Apply the variable labels taken from earlier
local _elem "in elementary school"
local _junior "in junior high"
local _senior "in senior high"
local _d1 "in d1"
	
foreach v in `allvar' {
	
	foreach l in _elem _junior _senior _d1 {
		
		label var `v'`l' "`label_`v'' ``l''"
		label values `v'`l' `v'
		
	}
	
}

label define yesno 0 "no" 1 "yes"

********************************************************************************Rename and clean variables ********************************************************************************

foreach l in _elem _junior _senior _d1 {
	
	rename dl16a`l' test_type`l'
	rename dl16db`l' ebtanas_indo`l'
	rename dl16dc`l' ebtanas_engl`l'
	rename dl16dd`l' ebtanas_math`l'
	rename dl16e`l' test_total`l'
	rename dl16g`l' hrs_day`l'
	rename dl16i`l' class_size`l'
	
	gen ebtanas`l' = 1 if test_type`l' == 1
	replace ebtanas`l' = 0 if test_type`l' != 1
	label var ebtanas`l' "Did you take the EBTANAS exam ``l''"
	label values ebtanas`l' yesno
	
	gen uan_un`l' = 1 if test_type`l' == 2
	replace uan_un`l' = 0 if test_type`l'!= 2
	label var uan_un`l' "Did you take the UAN/UN exam? ``l''"
	label values uan_un`l' yesno
	
	foreach t in uan_un ebtanas {
		
		gen total_`t'`l' = test_total`l' if `t'`l' == 1
		replace total_`t'`l' = . if `t'`l' == 0
		label var total_`t'`l' "Total score for `t' exam ``l''"
	
	}

	drop test_total`l'
	
}

********************************************************************************Finishing Up ********************************************************************************

local tag 03_ebtanas.do
foreach l in _elem _junior _senior _d1 {
	
	foreach v in ebtanas`l' uan_un`l' ebtanas_indo`l' ebtanas_engl`l' ebtanas_math`l' total_ebtanas`l' total_uan_un`l' hrs_day`l' class_size`l' {
		
		notes `v': `tag'
		
	}
	
}
compress

cd $desc_stats
save ifls5_ebtanas, replace

/*
log close
exit
*/









