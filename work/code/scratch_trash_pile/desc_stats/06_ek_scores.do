/*
capture log close
log using 06_ek_scores, replace text
*/

/*
  program:    	06_ek_scores.do
  task:			To clean and create a dataset ready for merging relating to 
				ek scores for students, using earlier IFLS waves.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 31July2023
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

********************************************************************************Generate a total ek score for IFLS3 (2000) ********************************************************************************

cd $ifls3_hh

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

egen std_total_ek00 = std(total_ek00)
label var std_total_ek00 "standardized test performance, ifsl3"
label var total_ek00 "proportion of answers answered correctly by respondent, ifsl3"

save `ek_test00'

********************************************************************************Generate a total ek score for IFLS4 (2007) ********************************************************************************

cd $ifls4_hh
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

egen std_total_ek07 = std(total_ek07)
label var std_total_ek07 "standardized of test performance, ifsl4"
label var total_ek07 "proportion of answers answered correctly by respondent, ifsl4"

tempfile ek_test07
save `ek_test07'

********************************************************************************Generate a total ek score for IFLS5 (2014) ********************************************************************************

cd $ifls5_hh
use ek_ek2, clear
drop if age < 15

foreach v in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 {
	
	recode ek`v'_ans 0 = . if ek`v'x == .
	
}
ds ek*_ans

egen total_ek14 = rowmean(`r(varlist)')

egen std_total_ek14 = std(total_ek14)
label var std_total_ek14 "standardized of test performance, ifsl5"
label var total_ek14 "proportion of answers answered correctly by respondent, ifsl5"

********************************************************************************Merge ********************************************************************************

merge 1:1 pidlink using `ek_test07'
keep if _merge == 3
drop _merge

merge 1:1 pidlink using `ek_test00'
keep if _merge == 3
drop _merge

********************************************************************************Generate the natural log of each of these variables ********************************************************************************

foreach v in total_ek00 total_ek07 total_ek14 {
	
	gen ln_`v' = ln(`v')
	
}
label var ln_total_ek00 "natural log proportion of answers answered correctly by respondent, ifsl3"
label var ln_total_ek07 "natural log proportion of answers answered correctly by respondent, ifsl4"
label var ln_total_ek14 "natural log proportion of answers answered correctly by respondent, ifsl5"


********************************************************************************Finish up ********************************************************************************

local tag 06_ek_scores.do
	
foreach v in total_ek00 total_ek07 total_ek14 {
		
	notes `v' : `tag'
	
	foreach k in ln_`v'	std_`v' {
		
		notes `k' : `tag'
	
	}
	
}
compress

keep hhid14_9 pid14 hhid00 pidlink total_ek14 std_total_ek14 ln_total_ek14 total_ek07 std_total_ek07 ln_total_ek07 total_ek00 std_total_ek00 ln_total_ek00

cd $desc_stats
save ek_scores, replace

/*
log close
exit
*/









