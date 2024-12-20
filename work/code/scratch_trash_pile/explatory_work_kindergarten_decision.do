* capture log close
* log using explatory_work_kindergarten_decision, replace text

//  program:    exploratory_work_kindergarten_decision.do
//  task:		to explore the descriptive statistics of key variables for my tentative research topic - early childhood education, or kindergarten and playgroup participation. OUTDATED
//  project:	IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
//  author \ last modified:     Daniel_Posthumus \ 07/14/2023

version 10
clear all
set linesize 80
macro drop _all

* install necessary programs
ssc install binscatter

* set macros
global data_raw "/Users/danielposthumus/thesis_independent_study/work/data_raw"
global ifls5_hh_raw "$data_raw/ifls5_hh"
global ifls2_hh_raw "$data_raw/ifls2_hh"
global ifls3_hh_raw "$data_raw/ifls3_hh"
global ifls3_cf_raw "$data_raw/ifls3_cf"

cd $ifls5_hh_raw

use b5_dla1, clear

*In particular we're interested in six variables: 
vl create ece_var = (dla04a dla04b dla04c dla04d dla04e dla04f)
ds $ece_var, detail
codebook $ece_var, detail


* Now we want to take a quick glance at the age group we're interested in. Let's take a quick look at the ifls3 data.
cd $ifls3_hh_raw
use b5_dla3, clear

* the variable dla3type denotes the column types in b5:
* 1 = CURRENT SCHOOL YEAR
* 2 = LAST YEAR AT SCHOOL PREVIOUSLY ATTENDED (FOR THOSE CURRENTLY IN SCHOOL, WITH A SCHOOL CHANGE IN LAST 5 YEARS)
* 3 = LAST YEAR IN SCHOOL (FOR THOSE NOT CURRENTLY IN SCHOOL)
* for now, let's restrict our results to dla3type in order to achieve unique identification and thus merging: 
preserve
keep if dla3type==1
tab dla36
restore
keep if dla3type==2
tab dla36

tempfile educ_rough
save "`educ_rough'"

* we're interested in dla08, the question concerning itself with what grade the survey respondent is currently in. we're interested in the age of respondent, which is located in a different module, so let's import that module.
use b5_cov, clear
ds, detail

* Now that we have age, we'll merge this with the other module so we can get the age breakdown of students currently in kindergarten
merge 1:1 pidlink using "`educ_rough'"
keep if _merge == 3
drop _merge

/*
preserve
* we'll restrict the sample to respondents who are in kindergarten, which is represented by the value of 90.
keep if dla08 == 90

* We can see that the minimum age is 2 and the largest age is 6; however, the first percentile is 3% so it is unreasonable to include 10 years old (?). Therefore, we will estimate 'kindergarten' age at 3-6. The average age is 4.61. 
restore
*/
egen kindergarten_age = anymatch(age), values(3 4 5 6)
keep if kindergarten_age

e

* Now we have the rough beginning of a dataset including only kindergarten-age children. We want to generate a binary kindergarten variable, indicating whether a student is currently in kindergarten
gen kindergarten = 1 if dla08==90
replace kindergarten = 0 if dla08!=90

gen elementary = 1 if dla08==02
replace elementary = 0 if dla08!=02

/*
local tag 01_hh_education_variables_ifls5.do
foreach v in educ educ_level evschl {
	notes `v': `tag'
}
compress
save , replace
*/

* log close
* exit
