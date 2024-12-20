/*
capture log close
log using 05_ifls5_labor_force_participation, replace text
*/

/*
  program:    	05_ifls5_labor_force_participation.do
  task:			To clean and create a dataset ready for merging relating to 
				labor force outcomes for students, using IFLS5.
  
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
* Create labor force variable *******************************************************************************************
cd "$raw/ifls5_hh"
	use b3a_tk1, clear
/*
	First, we want to create a variable about whether an individual is in the 
	labor market or not. There are two possibilities to be in the labor 
	market: to have a job or to be looking for a job. 
	We will use the following variables to code our labor_force variables:
	- tk01a "During the past week did you do any of these activities?"
		- a. Work for pay
		- d. Job Searching
	- tk01 "Primary activity during past week"
	- tk02 "Did you work for pay at least 1 hr lst/wk"
	- tk03 "Do you have a job but didn't work lst/wk"
	- tk04 "Did you work in family-owned bus lst/wk"
		- note: tk02, tk03, and tk04 were only answered by those who did not 
		select 1 as response to tk01
	- tk16d "In the past one month, have you been looking for a job?"
		- labor_force = 1 ("yes")
			- tk01a = 1 ("1:Yes")
			- tk01d = 1 ("1:Yes")
			- tk01 = 1 ("1:Working/trying to get work/helping to earn an 
			income")
			- tk01 = 2 ("2:Job Searching")
			- tk03 = 1 ("1:Yes")
			- tk04 = 1 ("1:Yes")
		- labor_force = 0 ("no")
			- everything else
*/
label var tk01a "During the past week, did you work for pay?"
label var tk01b "During the past week, did you attend school?"
label var tk01c "During the past week, did you do housekeeping?"
label var tk01d "During the past week, did you search for a job?"

gen labor_force 			= 1 if tk01a == 1 | tk01d == 1
	replace labor_force 		= 1 if tk01 == 1 | tk01 == 2
	replace labor_force 		= 1 if tk02 == 1
	replace labor_force 		= 1 if tk03 == 1 
	replace labor_force 		= 1 if tk04 == 1 
	replace labor_force 		= 1 if tk16d == 1
	replace labor_force			= 0 if labor_force == .
	replace labor_force 		= .m if tk01 == .

label var labor_force "are you currently in the labor force?"
	label def binary 0 "no" 1 "yes", replace
	numlabel binary, mask(#_) add force
	label val labor_force binary
*******************************************************************************************
* Create unemployment_6 variable *******************************************************************************************
/*
	Now that we have our labor force participation variable, we can create a 
	variable capturing whether the respondent is currently unemployed, 
	according to the U-6 definition of unemployment.
	
	This is a tricky variable to create, there are a few possibilities for how 
	a person could be unemployed. Note that this only concerns those who are 
	currently in the labor force.
	- Currently looking for a job, and unable to get one
	- Currently under-employed
	- Currently not looking for a job because discouraged
	
	In order to code for these scenarios we will use the following variables:
	- labor_force "are you currently in the labor force"
	- tk01a "During the past week did you do any of these activities?"
		- a. Work for pay
		- d. Job Searching
	- tk16d  "In the past one month, have you been looking for a job?"
	- tk16h "What is the main reason not looking for a job?"
	
	In order to create this variable we have to make some assumptions:
	- Anyone who spent any time in the last week searching for a job is either 
	under-employed or completely unemployed
	
	We will code the variable using the following rules:
	- unemployed_6 = 1 ("yes")
		- tk01d = 1 ("1:Yes")
		- a worker is discouraged from searching for a job (this is the tricky 
		variable to code)
			- tk16d = 3 ("3:No") & tk16h = 01 ("1:Feel impossible to find a 
			job")
	- unemployed_6 = 0
		- all other cases, for workers that ARE in the labor force
	- unemployed_6 = .m 
		- labor_force = 0
	
*/
gen unemployed_6 				= 1 if tk01d == 1 & labor_force == 1
	replace unemployed_6			= 1 if tk16d == 1
	replace unemployed_6 			= 1 if tk16d == 3 & tk16h == 1
	replace unemployed_6			= 0 if unemployed_6 == . & labor_force == 1
	replace unemployed_6			= .m if labor_force == 0 
label var unemployed_6 "are you currently unemployed (U-6)?"
	label val unemployed_6 binary
*******************************************************************************************
* Create unemployment_3 variable *******************************************************************************************
/*
	Now that we have our labor force participation variable, we can create a 
	variable capturing whether the respondent is currently unemployed, 
	according to the U-3 definition of unemployment.
	
	This is much easier to code, as it only includes those actively searching 
	for a job; thus, we will only include those in the labor force and whose 
	primary activity in the last week was searching for a job. 
	
	In order to code for these scenarios we will use the following variables:
	- labor_force "are you currently in the labor force"
	- tk01 "Primary activitiy during past week"
	
	We will code the variable using the following rules:
	- unemployed_3 = 1 ("yes")
		- tk01 = 2 ("2:Job Searching")
	- unemployed_3 = 0
		- all other cases, for workers that ARE in the labor force
	- unemployed_3 = .m 
		- labor_force = 0
*/
gen unemployed_3				= 1 if tk01 == 2 & labor_force == 1
	replace unemployed_3			= 1 if tk16d == 1 & tk01 != 1 & labor_force == 1
	replace unemployed_3			= 0 if unemployed_3 == . & labor_force == 1
	replace unemployed_3 			= .m if labor_force == 0
label var unemployed_3 "are you currently unemployed (U-3)?"
	label val unemployed_3 binary
*******************************************************************************************
* Finish up 
*******************************************************************************************
local tag 04_labor_force_participation.do
foreach v in labor_force unemployed_3 unemployed_6 {
	notes `v' : `tag'
}
keep hhid14_9 pidlink pid14 labor_force unemployed_6 unemployed_3
label data "ifls5 labor force participation"
	compress

cd "$clean/ifls5_hh"
save ifls5_labor_force, replace

/*
log close
exit
*/









