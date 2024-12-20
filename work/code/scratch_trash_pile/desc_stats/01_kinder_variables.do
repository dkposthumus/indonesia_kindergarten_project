
/*
capture log close
log using kinder_variables, replace text
*/

/*
  program:    	01_kindergarten_variable.do
  task:			To create my two key kindergarten variables: kinder_ever (have 
				you ever attended kindergarten) and kinder_age (at what age 
				did you attend kindergarten?).
  
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

********************************************************************************Create kinder_ever variable ********************************************************************************

cd $ifls5_hh

use b3a_dl1, clear

/*

	We will create our kinder_ever variable, "did you ever attend 
	kindergarten". 
	We'll use one existing variable to create kinder_ever:
	- dl05b: "Did you attend kindergarten"
	
	kinder_ever can assume the following value:
		- 1: yes
			- dl05b = 1 ("1:Yes")
		- 0: no
			- dl05b = 3 ("3:No")
		- .m : missing
			- dl05b = .
			- dl05b = 9 ("9:MISSING")
		- .d : don't know
			- dl05b = 8 ("8:Don't Know")

*/
 
tab dl05b, m

gen kinder_ever = 1 if dl05b == 1
replace kinder_ever = 0 if dl05b == 3
replace kinder_ever =.m if dl05b == 9 | dl05b == .
replace kinder_ever = .d if dl05b == 8

label define binary .m "missing" .d "don't know" 0 "no" 1 "yes", replace
numlabel binary, mask(#_) add force
label values kinder_ever binary
label var kinder_ever "did you ever attend kindergarten?"

********************************************************************************Create kinder_age variable ********************************************************************************

/*

	We will create our kinder_age variable: at what age did you attend 
	kindergarten?"
	We'll use one existing variable to create kinder_age: 
	- dl05c: "At what age did you atstend the kindergarten"
	- kinder_ever: "did you ever attend kindergarten?"
	
		- x: age attended at kindergarten
			- dl05c != . & dl05c != 98
		- .m : missing
			- dl05c = .
		- .d : don't know
			- dl05c = 98 ("98:Don't Know")
		- .n : not applicable
			- dl05c = . & kinder_ever = 0

*/

tab dl05c, m

gen kinder_age = dl05c
replace kinder_age = .m if dl05c == .
replace kinder_age = .d if dl05c == 98
replace kinder_age = .n if kinder_ever == 0

label define age .m "missing" .d "don't know" .n "not applicable", replace
numlabel age, mask(#_) add force
label values kinder_age age
label var kinder_age "at what age did you attend kindergarten?"

********************************************************************************Finishing Up ********************************************************************************

local tag kinder_variables.do
foreach v in kinder_ever kinder_age {
	notes `v': `tag'
}
compress

cd $desc_stats
save ifls5_kinder_variables, replace

/*
log close
exit
*/









