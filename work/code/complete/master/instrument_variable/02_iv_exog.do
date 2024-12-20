/*
capture log close
log using 01_iv_educ, replace text
*/

/*
  program:    	02_iv_exog
  task:			To test instruments' validity for various models.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 16Apr2024
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
***************************************************************************************Run over-idenifying tests: ***************************************************************************************
cd $clean
use master, clear
* Let's define locals for our variables of interest:
local hh_control urban_97 two_parent educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 i.prov_97
local indiv_control i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male
local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14
local instrument kec_popkinder00 kec_popkinder90
* Let's only keep observations in our sample:
	keep if sample == 1
* let's set up a loop with each of the outcome variables:
foreach v in elem_completion junior_completion senior_completion in_schl1 in_schl2 in_schl3 in_schl4 in_schl5 in_schl6 in_schl7 in_schl8 in_schl9 in_schl10 in_schl11 in_schl12 in_schl13 in_schl14 stayon6 stayon9 stayon12 {
	qui ivregress gmm `v' (kinder_ever = `instrument') `hh_control' `indiv_control' `comm_control', wmatrix(robust) 
		ds `v'
		estat overid 
		estat endogenous
}

* now cognitive test scores: 
preserve 
	keep if ln_total_ek00 != . & ln_total_ek07 != . & ln_total_ek14 != . 
		foreach v in 00 07 14 {
		qui ivregress gmm ln_total_ek`v' (kinder_ever = `instrument') `hh_control' `indiv_control' `comm_control', wmatrix(robust) 
		estat overid 
		estat endogenous
		}
restore 

	
/*
log close
exit
*/





	


