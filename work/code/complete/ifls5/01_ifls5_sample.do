/*
capture log close
log using 01_ifls5_sample, replace text
*/

/*
  program:    	01_ifls5_sample.do
  task:			To construct the sample 'base' for the IFLS5 data.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 24Oct2023
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
* Create sample of all individuals interviewed in the IFLS5 wave ***************************************************************************************
cd "$raw/ifls5_hh"
* Our sample restriction for IFLS5 are all individuals 15 that were interviewed; note that we only concern ourselves with individuals 15 and over who were interviewed, since we are merging onto IFLS2 (1997) and individuals under 15 in 2014 were not alive and thus certailny not on household rosters in 1997. 
	use b3a_cov, clear
		* We're going to create a tempfile
	tempfile sample_base
	* We only want to take away the hhid14_9, pid14 and pidlink of the data.
		* However, what to do with proxies?
	
	* First, let's check whether pid14 and hhid14_9 are unique identifiers.
	duplicates report pid14 hhid14_9
		isid pid14 hhid14_9
	* Clearly, they ARE unique identifiers and this makes our job very straightfoward.
	* Now let's look at the proxy status of these books.
	tab proxy
		* 7.75% of the completed books are proxy. For now, we're going to leave these in the survey. We also want to check if these identifying variables are missing anywhere:
		foreach v in hhid14_9 pidlink {
			list if `v' == ""
		}
		list if pid14 == .
		* Clearly there are no missing observations for these identifiers.
***************************************************************************************
* Create basic sample variables ***************************************************************************************
	
* While we're here, let's create some of the basic summary variables for individuals in our sample.
	* Let's begin with our age variable:
rename age age_14
	label var age_14 "age (2014)"
	* Now let's create our marital status variable:
rename marstat marstat_14
	label var marstat_14 "marital status in 2014"
	* Now we want to create a dummy variable for male using the sex variable
gen male 				= 1 if sex == 1
replace male 			= 0 if sex == 3
replace male 			= .m if sex == .
	label var male "male (dummy variable)"
		label define male_lab 1 "male" 0 "female" .m "missing", replace
		label val male male_lab
save `sample_base'

* Now we want to merge on the previous household ids in order to merge onto the IFLS2 data, whose unit of analysis is the household.
use htrack, clear
	* We want to drop all observations in htrack with a missing observation for the 2014 HHID; without this, we simply can't merge previous household data from waves where individuals were NOT interviewed individually. 
drop if hhid14_9 == ""
			* Note that we have dropped 3,480 observations. 
			duplicates report hhid14_9 
			* hhid14_9 IS a unique identifier, allowing us to merge 1:m.
			tab pid14, m
				* However, there's something puzzling going on: pid14 is ENTIRELY MISSING from htrack. So, let's just drop this variable.
				drop pid14 
			* The same thing is occurring with pidlink 
			tab pidlink, m
			drop pidlink
* Before merging, we want to snatch three variables, 
	* Finally, we're going to merge on hhid14_9 with our sample base dataset.
merge 1:m hhid14_9 using `sample_base'
	keep if _merge == 3 
		drop _merge 
	* We're only interested in perfectly matching observations; tracked households aren't part of our sample without data on individual interviews in 2014, and individual interviews in 2014 aren't part of our sample without panel data on household.
		* Now we want to keep the variables of interest.
keep pid14 hhid14_9 pidlink male marstat_14 age_14 proxy hhid00 hhid93 hhid97 hhid07 commid14
duplicates report hhid14_9 pid14 
duplicates report pidlink
	* There's no observations for our key identifiers -- we are ready to merge!
***************************************************************************************
* Finishing Up ***************************************************************************************
local tag 01_ifls5_sample.do
foreach v in male marstat_14 age_14 {
	notes `v': `tag'
}
label data "ifls5 basic sample"
	compress
cd "$clean/ifls5_hh"
save ifls5_sample, replace

/*
log close
exit
*/









