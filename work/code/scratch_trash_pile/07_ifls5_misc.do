/*
capture log close
log using 02_ifls5_educ_variables, replace text
*/

/*
  program:    	90_ifls5_master.do
  task:			Master do-file for all ifls5 code.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 02Aug2023
*/

version 17
clear all
set linesize 80
macro drop _all


*****************************************************************************************Set Global Macros              *****************************************************************************************

global raw "/Users/danielposthumus/thesis_independent_study/work/data_raw"
global clean "/Users/danielposthumus/thesis_independent_study/work/data_clean"

global code "/Users/danielposthumus/thesis_independent_study/work/code/to_do"

*****************************************************************************************Create age and male variables *****************************************************************************************

cd "$raw/ifls5_hh"
use b3a_cov, clear

tempfile merge1
rename age age_14
gen age_07 = age_14 - 7
gen age_00 = age_07 - 7
gen age_97 = age_00 - 3
rename marstat marstat_14

label var age_14 "age (2014)"
label var age_07 "age (2007)"
label var age_00 "age (2000)"
label var age_97 "age (1997)"
label var marstat_14 "marriage status (2014)"

save `merge1'

use htrack, clear
tempfile merge2
drop if hhid14_9 == ""
save `merge2'
use `merge1'
merge m:1 hhid14_9 using `merge2'
keep if _merge == 3
drop _merge

gen male 				= 1 if sex == 1
replace male 			= 0 if sex == 3
replace male 			= .m if sex == .
label var male "male (dummy variable)"

save `base'

use ptrack, clear
drop if hhid14_9 == ""
drop if pidlink == ""
drop if pid14 == .
duplicates drop hhid14_9 pid14 pidlink, force
merge 1:1 hhid14_9 pid14 pidlink using `base'

keep pidlink hhid97 pid97 hhid00 pid00 hhid07 pid07 hhid14_9 pid14 age_00 age_07 age_14 marstat_14 male

*****************************************************************************************Finishing Up *****************************************************************************************

local tag 06_ifls5_misc.do
foreach v in male marstat_14 age_00 age_07 age_14 age_14 {
	
	notes `v': `tag'
	
}
compress

cd "$clean/ifls5_hh"
save ifls5_cov, replace

/*
log close
exit
*/









