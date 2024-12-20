/*
capture log close
log using 04_ifls5_ek_scores, replace text
*/

/*
  program:    	04_ifls5_ek_scores.do
  task:			To clean and create a dataset ready for merging relating to 
				ek scores for students, using IFLS5.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 31July2023
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
* Generate a total ek score for IFLS5 (2014) *******************************************************************************************
cd "$raw/ifls5_hh"
use ek_ek2, clear
	drop if age < 15
foreach v in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 {
	recode ek`v'_ans 0 = . if ek`v'x == .
}
ds ek*_ans

egen total_ek14 = rowmean(`r(varlist)')
	label var total_ek14 "proportion of answers answered correctly by respondent, ifsl5"
gen ln_total_ek14 = ln(total_ek14)
	label var ln_total_ek14 "natural log proportion of answers answered correctly by respondent, ifsl5"
*******************************************************************************************
* Finish up 
*******************************************************************************************
local tag 04_ifls5_ek_scores.do
foreach v in total_ek14 {
	notes `v' : `tag'
	foreach k in ln_`v' {
		notes `k' : `tag'
	}
}
		keep hhid14_9 pid14 pidlink total_ek14 ln_total_ek14
label data "ifls5 cognitive test scores"
	compress
cd "$clean/ifls5_hh"
save ek_scores14, replace

/*
log close
exit
*/









