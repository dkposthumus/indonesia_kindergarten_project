/*
capture log close
log using 02_ifls3_ek_scores, replace text
*/

/*
  program:    	02_ifls3_ek_scores.do
  task:			To clean and create a dataset ready for merging relating to 
				ek scores for students,s using IFLS3.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 31July2023
*/

version 17
clear all
set linesize 80
macro drop _all

*****************************************************************************************
* Set Global Macros              *****************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~/thesis_independent_study/work/code/complete"
*****************************************************************************************
* Generate a total ek score for IFLS3 (2000) *****************************************************************************************
cd "$raw/ifls3_hh"
	use bek, clear
merge 1:1 pid00 hhid00 pidlink using ptrack
keep if _merge == 3
drop _merge
tempfile ek_test00
/*
	Right now, we have the results for the 20 questions on the cognitive test, 
	where 1 is coded as correct, 3 is coded as incorrect, and 9 as missing. 
	Since we have 20 variables for the results of 20 questions, we will recode 
	these 20 variables to be binary (1 = correct and 0 = incorrect) and take 
	the rowmean to derive overall scores (the variable being the proportion of 
	answers correctly answered by the respondent). This will give us an 
	overall score for every respondent. 
*/
ds ek*x
foreach v in `r(varlist)' {
	recode `v' 3 = 0 9 = .m 6 = .n
}
ds ek*x
egen total_ek00 = rowmean(`r(varlist)')
	label var total_ek00 "proportion of answers answered correctly by respondent, ifsl3"
gen ln_total_ek00 = ln(total_ek00)
	label var ln_total_ek00 "natural log proportion of answers answered correctly by respondent, ifsl3"
*****************************************************************************************
* Finish up 
*****************************************************************************************
local tag 02_ifls3_ek_scores.do
foreach v in total_ek00 {
	notes `v' : `tag'
	foreach k in ln_`v' {
		notes `k' : `tag'
	}
}
* let's keep only the necessary variables
keep hhid00 pid00 pidlink total_ek00 ln_total_ek00

label data "ifls3 cognitive test scores"

compress
cd "$clean/ifls3_hh"
save ifls3_ek_scores, replace

/*
log close
exit
*/









