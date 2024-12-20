/*
capture log close
log using 02_iv_homosk, replace text
*/

/*
  program:    	02_iv_homosk
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
local hh_control urban_97 two_parent educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 i.prov_97
local indiv_control i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male
local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14
local instrument kec_popkinder00 kec_popkinder90
* Let's only keep observations in our sample:
	keep if sample == 1
* let's set up a loop with each of the outcome variables:
foreach v in educ14 elem_completion junior_completion senior_completion in_schl1 in_schl2 in_schl3 in_schl4 in_schl5 in_schl6 in_schl7 in_schl8 in_schl9 in_schl10 in_schl11 in_schl12 in_schl13 in_schl14 stayon6 stayon9 stayon12 {
	preserve 
		qui reg `v' kinder_ever `instrument' `hh_control' `indiv_control' `comm_control'
			predict uhat, residual 
			predict yhat, xb 
				ds `v'
				estat hettest
				pwcorr uhat kinder_ever 
				scatter uhat kinder_ever, nodraw saving(`v'.gph, replace) title("`v'") yline(0) msize(small)
				hist uhat, nodraw saving(h`v'.gph, replace) title("`v'") normal
	restore 
}
* now cognitive test scores: 
		foreach v in 00 07 14 {
	preserve
	keep if ln_total_ek00 != . & ln_total_ek07 != . & ln_total_ek14 != . 
		qui reg ln_total_ek`v' kinder_ever `instrument' `hh_control' `indiv_control' `comm_control'
			predict uhat, residual 
			predict yhat, xb 
				ds ln_total_ek`v'
				estat hettest
				pwcorr uhat kinder_ever
				scatter uhat kinder_ever, nodraw saving(ln`v'.gph, replace) title("ln_total_ek`v'") yline(0) msize(small)
				hist uhat, nodraw saving(hln`v'.gph, replace) title("`v'") normal

	restore 
		}

graph combine educ14.gph elem_completion.gph junior_completion.gph senior_completion.gph in_schl1.gph in_schl2.gph in_schl3.gph in_schl4.gph in_schl5.gph in_schl6.gph in_schl7.gph in_schl8.gph in_schl9.gph in_schl10.gph in_schl11.gph in_schl12.gph in_schl13.gph in_schl14.gph stayon6.gph stayon9.gph stayon12.gph ln00.gph ln07.gph ln14.gph

graph combine heduc14.gph helem_completion.gph hjunior_completion.gph hsenior_completion.gph hin_schl1.gph hin_schl2.gph hin_schl3.gph hin_schl4.gph hin_schl5.gph hin_schl6.gph hin_schl7.gph hin_schl8.gph hin_schl9.gph hin_schl10.gph hin_schl11.gph hin_schl12.gph hin_schl13.gph hin_schl14.gph hstayon6.gph hstayon9.gph hstayon12.gph hln00.gph hln07.gph hln14.gph

/*
log close
exit
*/





	


