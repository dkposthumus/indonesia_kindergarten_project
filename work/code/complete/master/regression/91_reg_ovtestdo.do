/*
capture log close
log using 91_reg_ovtest, replace text
*/

/*
  program:    	91_reg_ovtest
  task:			To test IV models' homoskedasticity.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 17Apr2024
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
local control urban_97 two_parent educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 i.prov_97 i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male elem_per_10000_00 junior_per_10000_07 senior_per_10000_14 kec_popkinder00 kec_popkinder90

xi i.kinder_ever*i.two_parent i.kinder_ever*i.urban_97 i.kinder_ever*i.cohort i.kinder_ever*i.general_health_97 i.kinder_ever*i.male i.kinder_ever*i.prov_97 i.kinder_ever*educ_hh i.kinder_ever*educ_mom i.kinder_ever*ln_agg_expend_r_pc_97 i.kinder_ever*ln_agg_expend_r_pc_00 i.kinder_ever*ln_agg_expend_r_pc_07 i.kinder_ever*num_children i.kinder_ever*tot_num_vis_97 i.kinder_ever*elem_per_10000_00 i.kinder_ever*junior_per_10000_07 i.kinder_ever*senior_per_10000_14 i.kinder_ever*kec_popkinder00 i.kinder_ever*kec_popkinder90, prefix(I)
ds I*
	local c_control `r(varlist)'
* Let's only keep observations in our sample:
	keep if sample == 1
* let's set up a loop with each of the outcome variables:
foreach v in educ14 elem_completion junior_completion senior_completion in_schl1 in_schl2 in_schl3 in_schl4 in_schl5 in_schl6 in_schl7 in_schl8 in_schl9 in_schl10 in_schl11 in_schl12 in_schl13 in_schl14 stayon6 stayon9 stayon12 {
		 qui reg `v' kinder_ever `control' `c_control', vce(robust)
			ds `v'
				testparm `c_control'
			
}
* now cognitive test scores: 
		keep if ln_total_ek00 != . & ln_total_ek07 != . & ln_total_ek14 != . 
		foreach v in 00 07 14 {
		qui reg ln_total_ek`v' kinder_ever `control' `c_control', vce(robust)
			ds ln_total_ek`v'
				testparm `c_control'
		}


/*
log close
exit
*/





	


