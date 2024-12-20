/*
capture log close
log using 90_desc_regtables, replace text
*/

/*
  program:    	90_desc_regtables.do
  task:			to create a series of preliminary OLS regression tables
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 11Sept2023
*/

version 17
clear all
set linesize 80
macro drop _all

*********************************************************************************Set Global Macros              *********************************************************************************

global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"

global code "~/thesis_independent_study/work/code/to_do"

********************************************************************************Run merge do-file ********************************************************************************

cd "$code/master"
do 01_merge.do

global word "$clean/desc_stat/word_format"
global latex "$clean/desc_stat/latex_format"

*********************************************************************************Creating OLS regression tables ********************************************************************************

cd $clean
use master, clear

* Let's create our all-in-one regression table representing preliminary findings for the Honors Thesis proposal:

destring hhid14_9, gen(hhid14_9_num)
destring hhid97, gen(hhid97_num)

eststo clear

eststo: reg educ14 kinder_ever 
eststo: reg educ14 kinder_ever educ_hh ln_agg_expend_r_pc television urban_97 male cohort1 cohort2 cohort3 cohort4 cohort5
xtset hhid14_9_num
eststo: xtreg educ14 kinder_ever male cohort1 cohort2 cohort3 cohort4 cohort5

esttab using "$word/proposal_regression.rtf", se ar2 title("Preliminary regression findings") replace
esttab using "$latex/proposa_regression.tex", se ar2 title("Preliminary regression findings") replace


eststo clear

eststo: reg educ14 kinder_ever
eststo: reg educ14 educ_hh ln_agg_expend_r_pc television
eststo: reg educ14 educ_hh ln_agg_expend_r_pc television urban
eststo: reg educ14 kinder_ever educ_hh ln_agg_expend_r_pc television urban_97 male

esttab using "$word/exploratory_regression_educ.rtf", se ar2 title("Influences on educational attainment") replace
esttab using "$latex/exploratory_regression_educ.tex", se ar2 title("Influences on educational attainment") replace


eststo clear

eststo: regress ln_total_ek00 kinder_ever
eststo: regress ln_total_ek00 kinder_ever educ_hh ln_agg_expend_r_pc television
eststo: regress ln_total_ek00 kinder_ever educ_hh ln_agg_expend_r_pc television urban_97
eststo: regress ln_total_ek00 educ_hh ln_agg_expend_r_pc television
eststo: regress ln_total_ek00 educ_hh ln_agg_expend_r_pc television urban
esttab using "$word/exploratory_regression_total_score00.rtf", se ar2 title("Cognitive Score Regressions, 2000") replace
esttab using "$latex/exploratory_regression_total_score00.tex", se ar2 title("Cognitive Score Regressions, 2000") replace

eststo clear

eststo: regress kinder_ever urban_97
eststo: regress kinder_ever educ_hh ln_agg_expend_r_pc television urban_97
esttab using "$word/exploratory_regression_kinder.rtf", se ar2 title("Influences on kindergarten attendance") replace
esttab using "$latex/exploratory_regression_kinder.tex", se ar2 title("Influences on kindergarten attendance") replace

********************************************************************************Creating fixed household effects regression tables ********************************************************************************

destring hhid14_9, gen(hhid14_9_num)
destring hhid97, gen(hhid97_num)

/*
preserve
bysort hhid14_9_num: gen hhsize = _N
keep if hhsize > 1
*/ 

eststo clear

xtset hhid14_9_num
eststo: xtreg educ14 kinder_ever male cohort*, fe vce(robust)
esttab using "$word/exploratory_regression_fixed_home.rtf", se ar2 title("Household fixed effects, influences on educational attainment, basic") replace
esttab using "$latex/exploratory_regression_fixed_home.rtf", se ar2 title("Household fixed effects, influences on educational attainment, basic")  replace

eststo clear

xtset hhid14_9_num
eststo: xtreg ln_total_ek00 kinder_ever male age_14, fe vce(robust)
eststo: xtreg ln_total_ek07 kinder_ever male age_14, fe vce(robust)
eststo: xtreg ln_total_ek14 kinder_ever male age_14, fe vce(robust)
esttab using "$word/exploratory_regression_fadeout.rtf", se ar2 title("Household fixed effects, cognitive scores over time") replace
esttab using "$latex/exploratory_regression_fadeout.rtf", se ar2 title("Household fixed effects, cognitive scores over time") replace

restore

/*
log close
exit
*/









