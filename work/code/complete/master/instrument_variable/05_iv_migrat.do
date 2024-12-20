/*
capture log close
log using 05_iv_switch, replace text
*/

/*
  program:    	05_iv_migrat
  task:			To run OLS models for only the switching sample.
  
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
local control urban_97 two_parent educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 i.prov_97 i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male elem_per_10000_00 junior_per_10000_07 senior_per_10000_14 
local instrument kec_popkinder00 kec_popkinder90

	keep if sample == 1
***************************************************************************************Create two sets of migration variables: ***************************************************************************************
foreach v in 97 07 14 { 
	replace prov_`v' = prov_`v' * 100000
	replace kab_`v' = kab_`v' * 1000
	gen id_`v' = prov_`v' + kab_`v' + kec_`v'
}
gen schl_migrate = 1 if id_07 != id_97 
	replace schl_migrate = 0 if id_07 == id_97 
gen adult_migrate = 1 if id_14 != id_97 & schl_migrate == 0
	replace adult_migrate = 0 if adult_migrate == . 

sum schl_migrate 
sum adult_migrate
	
* let's set up a loop with each of the outcome variables:
foreach v in educ14 elem_completion junior_completion senior_completion in_schl1 in_schl2 in_schl3 in_schl4 in_schl5 in_schl6 in_schl7 in_schl8 in_schl9 in_schl10 in_schl11 in_schl12 in_schl13 in_schl14 stayon6 stayon9 stayon12 {
		 collect clear 
		 collect, tag(model[`v']): qui ivregress gmm `v' (kinder_ever = `instrument') `control' , wmatrix(robust)
		 collect, tag(model[`v'_schl]): qui ivregress gmm `v' (kinder_ever = `instrument') `control' if schl_migrate == 1, wmatrix(robust)
		 collect, tag(model[`v'_adult]): qui ivregress gmm `v' (kinder_ever = `instrument') `control' if adult_migrate == 1, wmatrix(robust)
		 collect label levels colname `control', replace
		collect layout (colname[kinder_ever]#result[_r_b _r_se] result[N]) (model)
}
* now cognitive test scores: 
		keep if ln_total_ek00 != . & ln_total_ek07 != . & ln_total_ek14 != . 
		foreach v in 00 07 14 {
		 collect clear 
		 collect, tag(model[`v']): qui ivregress gmm ln_total_ek`v' `control' (kinder_ever = `instrument'), wmatrix(robust)
		 collect, tag(model[`v'_schl]): qui ivregress gmm ln_total_ek`v' `control' (kinder_ever = `instrument') if schl_migrate == 1, wmatrix(robust)
		 collect, tag(model[`v'_adult]): qui ivregress gmm ln_total_ek`v' `control' (kinder_ever = `instrument') if adult_migrate == 1, wmatrix(robust)
		collect label levels colname `control', replace
		collect layout (colname[kinder_ever]#result[_r_b _r_se] result[N]) (model)
}

/*
log close
exit
*/





	


