/*
capture log close
log using 06_reg_stayon, replace text
*/

/*
  program:    	06_reg_stayon.do
  task:			To conduct regression analysis examining stay-on rates for 3 key 
				years.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 31Mar2024
*/

version 17
clear all
set linesize 80
macro drop _all

***************************************************************************************Set Global Macros              ***************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~thesis_independent_study/work/code/to_do"
	global output "~/thesis_independent_study/work/writing/rough_draft/analysis"
***************************************************************************************Check outcome variables -- stayon dummies for grade 6, 9, 12 ***************************************************************************************
cd $clean
use master, clear
* Let's begin with restricting our sample:
keep if sample == 1
* We already have our completion dummies coded:
sum stayon6 stayon9 stayon12
***************************************************************************************Execute completion regressions ***************************************************************************************
local hh_control urban_97 urban_00 urban_07 two_parent educ_hh educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07  
local indiv_control birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male
local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14 i.prov_97
local instrument kec_popkinder00 kec_popkinder90 
xtset mom_pidlink
foreach y in 6 9 12 {
	
	collect model_type="FE" has_fe="YES", tag(model[stayon`y'_fe]): xtreg stayon`y' kinder_ever `indiv_control' if stayon`y' != . & switch == 1, fe vce(robust)
	
	collect model_type="OLS" has_fe="NO", tag(model[stayon`y']): reg stayon`y' kinder_ever `indiv_control' `comm_control' `instrument' `hh_control' if stayon`y' != ., vce(robust)
	
	collect model_type="IV", tag(model[stayon`y'_iv]): ivregress gmm stayon`y'  `hh_control' `indiv_control' `comm_control' (kinder_ever = `instrument') if stayon`y' != ., wmatrix(robust)
	
}

collect layout (colname[kinder_ever educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07_07 elem_per_10000_00 junior_per_10000_07 senior_per_10000_14]#result[_r_b _r_se] result[model_type r2_a N]) (model[stayon6 stayon6_fe stayon6_iv stayon9 stayon9_fe stayon9_iv stayon12 stayon12_fe stayon12_iv])
	collect style header result[_r_b _r_se], level(hide)
	collect style cell result[r2_a _r_b], nformat(%7.2f)  halign(center)
	collect style cell result[_r_se], nformat(%7.2f) sformat("(%s)") halign(center)
	collect style cell result[N], halign(center)
	collect label levels model stayon6 "6th Grade" stayon9 "9th Grade" stayon12 "12th Grade", replace
	collect style header model[stayon6_fe stayon6_iv stayon9_fe stayon9_iv stayon12_fe stayon12_iv], level(hide)
	collect label levels colname two_parent "Two-parent HH" educ_mom "Mom's years of education" ln_agg_expend_r_pc_97 "HH per-capita expenditure (1997)" ln_agg_expend_r_pc_00 "HH per-capita expenditure (2000)" ln_agg_expend_r_pc_07_07 "HH per-capita expenditure (2007)" elem_per_10000_00 "Elementaries per 10,000 (2000)" junior_per_10000_07 "Junior highs per 10,000 (2007)" senior_per_10000_14 "Senior highs per 10,000 (2014)" cohort "Birth cohort" birth_order "Birth order to mother" kinder_spillover "Older sibling attended kinder" tot_num_vis_97 "Healthcare visits" general_health_97 "General health status (1997)" kinder_ever "Kindergarten" educ14 "Years of education (2014)" elem_completion "Completed elementary" junior_completion "Completed junior high" senior_completion "Completed senior high" male "Male" kec_popkinder90 "Kindergartens/10,000 in kec. (1990)" kec_popkinder00 "Kindergartens/10,000 in kec. (2000)" 4.general_health_97 "Very healthy" 4.cohort "Oldest birth cohort" urban_97 "Urban", replace
	collect label levels result has_fe "Has Mom FE" model_type "Model", modify
	collect style cell result[has_fe model_type], halign(center)
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
	collect style tex, nobegintable
collect preview
	collect export "$output/full_stayon.tex", tableonly replace



