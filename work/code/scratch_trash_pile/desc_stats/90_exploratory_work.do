/*
capture log close
log using 90_exploratory_work, replace text
*/

/*
  program:    	90_exploratory_work.do
  task:			To serve as a master do-file, executing the requisite do-files in the descriptive statistics folder in the proper order. Merges individual datasets created by these do-files in one masterdataset, used in "91_desc_stats.do" to create a series of graphs and descriptive statistics tables. 
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 20July2023
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

********************************************************************************Run all our do-files             ********************************************************************************

cd "$desc_stats_code"
do 01_kinder_variables
cd "$desc_stats_code"
do 02_educ_variables
cd "$desc_stats_code"
/*
do 03_ebtanas
cd "$desc_stats_code"
*/
do 04_household_char
cd "$desc_stats_code"
do 05_parental_char
cd "$desc_stats_code"
do 06_ek_scores
cd "$desc_stats_code"
do 07_labor_force_participation
cd "$desc_stats_code"
do 08_earnings

********************************************************************************Merge our datasets             ********************************************************************************

cd "$desc_stats"
use ifls5_educ_variables, clear
* merge 1:1 hhid14_9 pid14 using ifls5_ebtanas, nogen
merge 1:1 hhid14_9 pid14 using ifls5_labor_force, nogen
merge 1:1 hhid14_9 pid14 using ifls5_earnings
cd "$ifls5_hh"
merge 1:1 hhid14_9 pid14 using b3a_cov, nogen

tempfile merge
save `merge'

use ptrack, clear
tempfile ptrack_temp
drop if hhid14_9 == ""
drop if pid14 == .
duplicates drop pid14 hhid14_9, force
save `ptrack_temp'

use `merge', clear
merge 1:1 hhid14_9 pid14 using `ptrack_temp', nogen
drop _merge

cd "$desc_stats"
merge m:1 hhid97 using ifls2_household_char, force
keep if _merge == 3
drop _merge

merge m:1 hhid97 using ifls2_parental_char, force
keep if _merge == 3
drop _merge

merge 1:1 hhid00 pidlink using ek_scores, nogen

********************************************************************************Create our cohort of interest, of kindergaten age in 1996 ********************************************************************************

* We can trace these respondents back to 1996; thus we're interested in the cohort that were of 'kindergarten age' in 1996. We can take a quick look at our kindergarten_age variable.
sum kinder_age, detail

* Capturing the central 90% of the distribution of kindergarten ages, we have the interval [4,6]. Thus, we want to narrow our sample down to those who were between 3 and 7 in 1996. This survey was asked in 2014, 18 years after 1996; thus, those who were between 3 and 7 in 1996 would have been between 21 and 25 in 2014. We will drop everyone except those with ages contained in [21, 25].
* keep if inrange(age_14,21,25)

********************************************************************************Clean sex variable ********************************************************************************

recode sex 3 = 0
label def sex 0 "female" 1 "male", replace
label val sex sex

* Create dummy for male: 

gen male = 1 if sex == 1
replace male = 0 if sex != 1

********************************************************************************Pull rural/urban variable ********************************************************************************

cd "$ifls2_hh"
merge m:1 hhid97 using bk_sc, force nogen

gen urban = 1 if sc05 == 1
replace urban = 0 if sc05 != 1

********************************************************************************Breakdown of kindergarten enrollment rates by province, expenditure percentile, birth cohort, and urban/rural split ********************************************************************************

cd $desc_stats
use ifls5_exploratory_work, clear

local min 17
local max 32

keep if inrange(age,`min',`max')

gen cohort = 4 if inrange(age,`min',`min'+3)
replace cohort = 3 if inrange(age,`min'+4,`min'+7)
replace cohort = 2 if inrange(age,`max'-7,`max'-4)
replace cohort = 1 if inrange(age,`max'-3,`max')

rename sc01 prov
sort cohort prov
by cohort prov: egen med_expend = median(ln_agg_expend_r_pc)

gen above_ave = 1 if ln_agg_expend_r_pc > med_expend
replace above_ave = 0 if ln_agg_expend_r_pc <= med_expend

table (prov above_ave) (cohort), statistic(mean kinder_ever)

bysort hhid14_9: gen num = _N
tab num

bysort hhid14_9: egen total_kinder = total(kinder_ever)


********************************************************************************Save this dataset; this will be used for exploratory work ********************************************************************************

compress

cd $desc_stats
save ifls5_exploratory_work, replace

/*
log close
exit
*/









