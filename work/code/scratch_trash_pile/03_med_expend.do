/*
capture log close
log using 03_med_expend, replace text
*/

/*
  program:    	03_med_expend.do
  task:			To generate variables relating to median household expenditure.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 30Nov2023
*/

version 17
clear all
set linesize 80
macro drop _all

*******************************************************************************************Set Global Macros              *******************************************************************************************

global raw "/Users/danielposthumus/thesis_independent_study/work/data_raw"
global clean "/Users/danielposthumus/thesis_independent_study/work/data_clean"

global code "/Users/danielposthumus/thesis_independent_study/work/code/to_do"

*******************************************************************************************Generate our median household expenditure variable, by cohort (1997) *******************************************************************************************
cd "$code/master"
do 02_sample.do

cd "$clean"
use master, clear

* We want to first create a variable that represents the median natural log of household per capita expenditure, by birth cohort and province.
bysort prov_97 _cohort: 	egen med_agg_expend = median(ln_agg_expend_r_pc)
gen above_med 				= 1 if ln_agg_expend_r_pc >= med_agg_expend
replace above_med 			= 0 if ln_agg_expend_r_pc < med_agg_expend
replace above_med 			= .m if above_med == .

label var med_agg_expend "median household expenditure, by cohort and province (1997)"
label var above_med	"is your household expenditure above the median for your cohort and province? (1997)"

label def above_med 0 "below median household expenditure" 1 "above median household expenditure"
label val above_med above_med

*******************************************************************************************Finishing Up *******************************************************************************************

local tag 03_med_expend.do
foreach v in med_agg_expend above_med {
	notes `v': `tag'
}
compress

cd "$clean"
save master, replace

/*
log close
exit
*/
