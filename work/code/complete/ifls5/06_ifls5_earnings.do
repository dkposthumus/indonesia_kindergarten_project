/*
capture log close
log using 06_ifls5_earnings, replace text
*/

/*
  program:    	06_ifls5_earnings.do
  task:			To clean and create a dataset ready for merging relating to 
				earnings, using IFLS5.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 01August2023
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
* Create earnings 
*******************************************************************************************
cd "$raw/ifls5_hh"
	use b3a_tk2, clear
/*
	We want to create an annual earnings variable. This can be slightly 
	difficult, considering that many people have multiple jobs. 
	
	First, let's create a variable capturing the annual earnings for 
	respondents' primary job.

	To create this variable, earning_annual_primary, we will use:
		- tk25a2 "Approximately what was your salary/wage during the last year? 
		Job1"			
*/
gen earnings_1st 			= tk25a2
	replace earnings_1st 		= .m if earnings_1st == .	
	label var earnings_1st "salary/wage during the last year, primary job"
/*
	Next, let's create a variable capturing the annual earnings for 
	respondents' secondary job.

	To create this variable, earning_annual_primary, we will use:
	- tk25b2 "Approximately what was your salary/wage during the last year? 
	Job2"
*/
gen earnings_2nd				= tk25b2
	replace earnings_2nd 		= .m if earnings_2nd == .
	label var earnings_2nd "salary/wage during the last year, second job"
/*
	Next, let's create total earnings, merely the sum of the two previous 
	annual earnings variables.		
*/
egen earnings				= rowtotal(earnings_1st earnings_2nd)
	label var earnings "salary/wage during the last year, total"
/*
	Last, let's take the natural log of each of these variables.			
*/
foreach v in earnings_1st earnings_2nd earnings {	
	gen ln_`v' = ln(`v')
		local label1 `"`:var label `v''"'
		label var ln_`v' "natural log of `label1'"
}
*******************************************************************************************
* Finish up 
*******************************************************************************************
local tag 06_ifls5_earnings.do
foreach v in earnings_1st earnings_2nd earnings {
	notes `v' : `tag'
	foreach m in ln_`v' {
		notes `m' : `tag'
	}
}
keep hhid14_9 pidlink pid14 earnings_1st earnings_2nd earnings ln_earnings_1st ln_earnings_2nd ln_earnings 

label data "ifls5 earnings"
compress

cd "$clean/ifls5_hh"
save ifls5_earnings, replace

/*
log close
exit
*/









