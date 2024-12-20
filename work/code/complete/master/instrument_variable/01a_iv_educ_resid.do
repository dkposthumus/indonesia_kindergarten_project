/*
capture log close
log using 01a_iv_educ_resid, replace text
*/

/*
  program:    	01a_iv_educ_resid
  task:			To run residual analysis for IV estimation of years of education.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 22Mar2024
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
***************************************************************************************Pull residual correlations for three primary model specifications ***************************************************************************************
cd $clean
use master, clear
* Let's define locals for our variables of interest:
local hh_control urban_97 two_parent educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 i.prov_97
local indiv_control i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male
local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14
* Let's only keep observations in our sample:
	keep if sample == 1
collect clear
* first our hh/indiv regression:
reg educ14 kinder_ever `hh_control' `indiv_control', vce(robust)
	predict educ_1
		gen residual_1 = educ14 - educ_1
* then w/community controls:
reg educ14 kinder_ever `hh_control' `indiv_control' `comm_control', vce(robust)
	predict educ_2
		gen residual_2 = educ14 - educ_2
* now w/mother fixed-effects
xtset mom_pidlink 
	xtreg educ14 kinder_ever `indiv_control', vce(robust) fe
		predict educ_3
			gen residual_3 = educ14 - educ_3
* now let's find the correlations:
foreach k in 1 2 3 {
	pwcorr kinder_ever kec_popkinder00 kec_popkinder90 residual_`k'
}
graph matrix kinder_ever kec_popkinder00 kec_popkinder90 residual_1 residual_2 residual_3

* now let's check if my instrumentals are actually endogenous:
foreach n in kec_popkinder00 kec_popkinder90 {
	reg educ14 kinder_ever `n' `hh_control' `indiv_control', vce(robust)
	reg educ14 kinder_ever `n' `hh_control' `indiv_control' `comm_control', vce(robust)
	xtreg educ14 kinder_ever `n' `indiv_control', vce(robust) fe
}




	


