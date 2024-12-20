/*
capture log close
log using 01_iv_educ, replace text
*/

/*
  program:    	04_etregress
  task:			To run Treatment-Effects IV models.
  
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
***************************************************************************************Set Up ***************************************************************************************
cd $clean
use master, clear
* Let's define locals for our variables of interest:
local control urban_97 two_parent educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 i.prov_97 i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male elem_per_10000_00 junior_per_10000_07 senior_per_10000_14
local instrument kec_popkinder00 kec_popkinder90
* Let's only keep observations in our sample:
	keep if sample == 1
***************************************************************************************Full set of Outcome Variables ***************************************************************************************
foreach v in elem_completion junior_completion senior_completion {
	collect clear
	collect, tag(model[`v']): qui ivregress gmm `v' (kinder_ever = `instrument') `control', wmatrix(robust)
	collect, tag(model[`v'_te]): qui etregress `v' `control', treat(kinder_ever = `instrument' `control')
	collect label levels colname `control', replace
	collect label levels colname 1.kinder_ever "kinder", replace
	collect layout (colname[kinder_ever]#result[_r_b _r_se]) (model)
	collect layout (colname#result[_r_b _r_se]) (model[`v'])
}

foreach v in in_schl1 in_schl2 in_schl3 in_schl4 in_schl5 in_schl6 in_schl7 in_schl8 in_schl9 in_schl10 in_schl11 in_schl12 in_schl13 in_schl14 stayon6 stayon9 stayon12 {
	collect clear
	collect, tag(model[`v']): qui ivregress gmm `v' (kinder_ever = `instrument') `control', wmatrix(robust)
	collect, tag(model[`v'_te]): qui etregress `v' `control', treat(kinder_ever = `instrument' `control')
	collect label levels colname `control', replace
	collect label levels colname 1.kinder_ever "kinder", replace
	collect layout (colname[kinder_ever]#result[_r_b _r_se]) (model)
	collect layout (colname#result[_r_b _r_se]) (model[`v'])
}

	
/*
log close
exit
*/





	


