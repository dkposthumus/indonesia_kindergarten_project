/*
capture log close
log using 05_earnings, replace text
*/

/*
  program:    	08_earnings.do
  task:			To clean and create a dataset ready for merging relating to 
				earnings, using IFLS5.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 01August2023
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

********************************************************************************Create earnings ********************************************************************************

cd $ifls5_hh
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

	Finally, let's create total earnings, merely the sum of the two previous 
	annual earnings variables.
			
*/

egen earnings				= rowtotal(earnings_1st earnings_2nd)

label var earnings "salary/wage during the last year, total"



********************************************************************************Finish up ********************************************************************************

local tag 08_earnings.do
	
foreach v in earnings_1st earnings_2nd earnings {
		
	notes `v' : `tag'
	
}
compress

keep hhid14_9 hhid14 pidlink pid14 earnings_1st earnings_2nd earnings

cd $desc_stats
save ifls5_earnings, replace

/*
log close
exit
*/









