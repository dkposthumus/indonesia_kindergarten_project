/*
capture log close
log using 03b_ifls5_educ_variables, replace text
*/

/*
  program:    	03b_ifls5_educ_variables.do
  task:			To create a set of education variables for the use of our 
				descriptive statistics exploratory work: years of education, 
				highest of level of education attended, and if they have ever 
				attended school.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 20July2023
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
* Run first educational variables do-file             *******************************************************************************************
cd "$code/ifls5"
	do 02_ifls5_kinder_variables.do
cd "$code/ifls5"
	do 03a_ifls5_educ_variables.do
*******************************************************************************************
* Reshape  data *******************************************************************************************
cd "$raw/ifls5_hh"
use b3a_dl4, clear

tempfile ifls5_educ
tempfile base
label val dl4type
tostring dl4type, replace

replace dl4type = "_elem" 		if dl4type == "1"
replace dl4type = "_junior" 	if dl4type == "2"
replace dl4type = "_senior" 	if dl4type == "3"
replace dl4type = "_d1" 		if dl4type == "4"

local elem 			"elementary"
local junior 		"junior high"
local senior 		"senior high"
local d1 			"college (d1)"

keep hhid14_9 pid14 dl4type dl11c dl11d dl11f dl13 dl14a1 dl14b2 dl14c3 dl14d4 dl14e5 dl14f6  

reshape wide dl11c dl11f dl13 dl14a1 dl14b2 dl14c3 dl14d4 dl14e5 dl14f6 dl11d, i(hhid14_9 pid14) j(dl4type) string
save `base'
*******************************************************************************************
* Merge b3a_cov onto dataset *******************************************************************************************
use b3a_cov, clear
	keep hhid14_9 pid14 dob_yr
	merge 1:1 hhid14_9 pid14 using `base'
keep if _merge == 3
	drop _merge
cd "$clean/ifls5_hh"
merge 1:1 hhid14_9 pid14 using ifls5_educ_variables, nogen
*******************************************************************************************
* Create exit_year and then exit_age variables *******************************************************************************************
foreach v in elem junior senior d1 {
	label var dl11f_`v' 		"exit year for ``v''"
	recode dl11f_`v' 			9998 = .d
	recode dl11f_`v' 			9999 = .m
	replace dl11f_`v'			= .m if dl11f_`v' == .
	rename dl11f_`v'			exit_year_`v'
	gen exit_age_`v'			= exit_year_`v' - dob_yr
	replace exit_age_`v'		= .m if exit_age_`v' == . | exit_age_`v' < 0
	label var exit_age_`v'		"exit age for ``v''"
	drop exit_year_`v'
}

gen exit_age = 			exit_age_elem 		if educ_level14 == 1 | educ_level14 == 0
replace exit_age = 		exit_age_junior		if educ_level14 == 2
replace exit_age =		exit_age_senior		if educ_level14 == 3
replace exit_age = 		exit_age_d1			if educ_level14 == 4

replace exit_age = .m if educ_level == .m | educ_level == 10 | educ_level == 14 | educ_level == 17 | educ_level == .d | exit_age == .

label var exit_age "exit age at highest level of education attended"

*******************************************************************************************
* Create grade retention dummy variables for each grade *******************************************************************************************
* drop unnecessary variables
foreach v in dl14a1_d1 dl14b2_d1 dl14c3_d1 dl14d4_d1 dl14e5_d1 dl14f6_d1 dl14d4_junior dl14e5_junior dl14f6_junior dl14d4_senior dl14e5_senior dl14f6_senior dl13_d1 {
	tab `v'
	drop `v'
}

label define binary 1 "yes" 0 "no", replace
local a1_	"1st"
local b2_	"2nd"
local c3_	"3rd"
local d4_ 	"4th"
local e5_ 	"5th"
local f6_ 	"6th"
foreach v in elem junior senior {
	label var dl13_`v' 				"did you ever fail a grade in ``v''"
	recode dl13_`v' 3 = 0
	replace dl13_`v' = .m 			if dl13_`v' == .
	replace dl13_`v' = .d 			if dl13_`v' == 8
	replace dl13_`v' = .m			if dl13_`v' == 9
	
	label val dl13_`v' binary
	rename dl13_`v' evfail_`v'
	
	foreach n in a1_ b2_ c3_ {
		label var dl14`n'`v'		"how many times did you fail ``n'' grade in ``v''"
		replace dl14`n'`v' = 0 		if dl14`n'`v' ==.
	
		gen pass`n'`v' = 0 			if dl14`n'`v' != 0 & dl14`n'`v' != .m & 										dl14`n'`v' != .n
			replace pass`n'`v' = 1		if dl14`n'`v' == 0
			replace pass`n'`v' = .m		if dl14`n'`v' == .m
			replace pass`n'`v' = .n		if dl14`n'`v' == .n
			label var pass`n'`v' 		"did you pass ``n'' grade in ``v''"
		drop dl14`n'`v' 
	}
}
foreach n in d4_ e5_ f6_ {
	label var dl14`n'elem			"how many times did you fail ``n'' grade in `elem'"
		replace dl14`n'elem = 0 		if dl14`n'elem ==.
	gen pass`n'elem = 0 			if dl14`n'elem != 0 & dl14`n'elem != .m & 										dl14`n'elem != .n
	replace pass`n'elem = 1			if dl14`n'`v' == 0
	replace pass`n'elem = .m		if dl14`n'elem == .m
	replace pass`n'elem = .n		if dl14`n'elem == .n
	label var pass`n'elem 			"did you pass ``n'' grade in `elem'"
		drop dl14`n'elem
}
rename (passa1_elem passb2_elem passc3_elem passd4_elem passe5_elem passf6_elem passa1_junior passb2_junior passc3_junior passa1_senior passb2_senior passc3_senior) (pass1 pass2 pass3 pass4 pass5 pass6 pass7 pass8 pass9 pass10 pass11 pass12)

foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 {
	label var pass`n' "did you pass grade `n' on your first attempt"
		replace pass`n' = .n if educ14 < `n'
}
*******************************************************************************************
* Create stay-on dummy variable, for every year of schooling *******************************************************************************************
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22  {
	gen stayon`n' = 1				if educ14 > `n'
		replace stayon`n' = 0			if educ14 == `n'
		replace stayon`n' = .n			if educ14 < `n'
		replace stayon`n'	= .m		if educ14 == .
		label var stayon`n'			"did the student stay-on in the education system after completing grade `n'"
}
*******************************************************************************************
* Create in school dummy variable, for every year of schooling *******************************************************************************************
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22  {
	gen in_schl`n' = 1				if educ14 >= `n'
	replace in_schl`n' = 0			if educ14 < `n'
	replace in_schl`n'	= .m		if educ14 == .
	label var in_schl`n'			"was the student still in school in grade `n'"
}
*******************************************************************************************
* Finishing Up *******************************************************************************************
local tag 03b_ifls5_educ_variables.do
foreach l in elem junior senior {
	foreach v in exit_age_`l' exit_age evfail_`l' {
		notes `v': `tag'
	}
}
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12  {
	notes pass`n': `tag'
}
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22  {
	notes stayon`n': `tag'
	notes in_schl`n': `tag'
}
label data "ifls5 educational variables"
compress

save ifls5_educ_variables, replace

/*
log close
exit
*/









