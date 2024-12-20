/*
capture log close
log using 01_merge, replace text
*/

/*
  program:    	01_merge.do
  task:			Master merge do-file for all code.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 02Aug2023
*/

version 17
clear all
set linesize 80
macro drop _all


****************************************************************************************Set Global Macros              ****************************************************************************************

global raw "/Users/danielposthumus/thesis_independent_study/work/data_raw"
global clean "/Users/danielposthumus/thesis_independent_study/work/data_clean"

global code "/Users/danielposthumus/thesis_independent_study/work/code/to_do"

****************************************************************************************Run all do-files ****************************************************************************************

cd "$code/ifls1"

cd "$code/ifls2"
do 90_ifls2_master
cd "$code/ifls3"
do 90_ifls3_master
cd "$code/ifls4"
do 90_ifls4_master
cd "$code/ifls5"
do 90_ifls5_master

****************************************************************************************Merge data files ****************************************************************************************

cd "$clean/ifls5_hh"
use ifls5_master, clear

/*
cd "$clean/ifls4_hh"
merge 1:1 pidlink using ifls4_master
keep if _merge == 3
drop _merge 

cd "$clean/ifls3_hh"
merge 1:1 pidlink using ifls3_master
keep if _merge == 3
drop _merge 
*/
cd "$clean/ifls2_hh"
merge 1:1 pidlink using ifls2_master

** Next, we want to recode _merge so that we can use it to describe attrition:
rename _merge wave
	label def wave 1 "Only in IFLS5" 2 "Only in IFLS2" 3 "In sample"
	label val wave wave

****************************************************************************************Generate our cohort variable(s) ****************************************************************************************

local min 18
local max 32

local cohort1 				`max'-2,`max'
	local cohort1_label		"30 to 32"
local cohort2 				`max'-5,`max'-3
	local cohort2_label 	"27 to 29"
local cohort3				`min'+6,`max'-6
	local cohort3_label 	"24 to 26"
local cohort4 				`min'+3,`min'+5
	local cohort4_label 	"21 to 23"
local cohort5				`min',`min'+2
	local cohort5_label 	"18 to 20"

foreach _n in 1 2 3 4 5 {
	
	gen cohort`_n'				= 1 if inrange(age_14,`cohort`_n'')
		replace cohort`_n'		= 0 if cohort`_n' == .
		label var cohort`_n' 	"are you in the age cohort `_n', ages cohort`_n'_label? (2014)"
	
}

gen _cohort 				= 1 if cohort1 == 1

foreach _n in 2 3 4 5 {
	
	replace _cohort 		= `_n' if cohort`_n' == 1
	
}

label var _cohort "what age cohort are you in?"
label def _cohort 1 "ages `cohort1_label'" 2 "ages `cohort2_label'" 3 "ages `cohort3_label'" 4 "ages `cohort4_label'" 5 "ages `cohort5_label'"
label val _cohort _cohort

****************************************************************************************Generate our median household expenditure variable, by cohort (1997) ****************************************************************************************

bysort prov_97 _cohort: egen med_agg_expend = median(ln_agg_expend_r_pc)
gen above_med 				= 1 if ln_agg_expend_r_pc >= med_agg_expend
replace above_med 			= 0 if ln_agg_expend_r_pc < med_agg_expend
replace above_med 			= .m if above_med == .

label var med_agg_expend "median household expenditure, by cohort and province (1997)"
label var above_med	"is your household expenditure above the median for your cohort and province? (1997)"

label def above_med 0 "below median household expenditure" 1 "above median household expenditure"
label val above_med above_med

****************************************************************************************Generate our sample variables ****************************************************************************************

* Sample 1: everyone between max and min ages in both IFLS2 and IFLS5
gen sample1 = 1				if inrange(age_14,`min',`max') & wave == 3
replace sample1 = 0			if sample1 == .
label var sample1 "dummy variable, indicating if member of sample1"

* Sample 2: respondent is a member of a two-parent household and all children are children of the head of the household.
gen sample2 = 1 			if two_parent == 1 & hh_head_child == 1 & sample1 == 1
label var sample2 "dummy variable, indicating if member of sample2"
replace sample2 = 0 		if sample2 == .

****************************************************************************************Finishing Up ****************************************************************************************

local tag 01_merge.do
foreach v in _cohort cohort1 cohort2 cohort3 cohort4 cohort5 med_agg_expend above_med sample1 sample2 wave {
	
	notes `v': `tag'
	
}
compress

cd "$clean"
save master, replace

/*
log close
exit
*/









