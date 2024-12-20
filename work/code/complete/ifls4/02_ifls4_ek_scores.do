/*
capture log close
log using 02_ifls4_ek_scores, replace text
*/

/*
  program:    	02_ifls4_ek_scores.do
  task:			To clean and create a dataset ready for merging relating to 
				ek scores for students, using IFLS4.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 31July2023
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
* Generate a total ek score for IFLS4 (2007) ***************************************************************************************
cd "$raw/ifls4_hh"
use bek_ek1, clear
	tempfile bek_ek1_07
	keep if age==14
save `bek_ek1_07'

use bek_ek2, clear
	drop if age < 15
append using `bek_ek1_07'

ds ek*x
foreach v in `r(varlist)' {
	recode `v' 3 = 0 9 = .m 6 = .n
}
ds ek*x
egen total_ek07 = rowmean(`r(varlist)')
	label var total_ek07 "proportion of answers answered correctly by respondent, ifsl4"
gen ln_total_ek07 = ln(total_ek07)
	label var ln_total_ek07 "natural log proportion of answers answered correctly by respondent, ifsl4"
***************************************************************************************
* Finish up 
***************************************************************************************
local tag 01_ek_scores.do
foreach v in total_ek07 {
	notes `v' : `tag'
	foreach k in ln_`v' {
		notes `k' : `tag'
	}
}

keep hhid07 pid07 pidlink total_ek07 ln_total_ek07
	label data "ifls4 cognitive test scores"
compress
cd "$clean/ifls4_hh"
save ifls4_ek_scores, replace

/*
log close
exit
*/









