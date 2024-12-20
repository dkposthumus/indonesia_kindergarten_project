/*
capture log close
log using 03_schl_complete, replace text
*/

/*
  program:    	03_schl_complete
  task:			To conduct regression analysis with school completion dummy outcomes.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 26Mar2024
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
***************************************************************************************Clean sample/cognitive test score ***************************************************************************************
cd $clean
use master, clear
* Let's begin with restricting our sample:
keep if sample == 1
* We already have our completion dummies coded:
codebook ln_total_ek00 ln_total_ek07 ln_total_ek14, detail
* now let's generate these variables, standardized by age so that i don't need to include age fixed-effects:
foreach v in 00 07 14 {
	bysort age_14: egen ek`v'_std = std(ln_total_ek`v')
}
	* We have very few/no missing observations for in-sample observations.
* however, let's keep only observations that have ONLY non-missing for all 3 waves of the cognitive test:
drop if ln_total_ek00 == . | ln_total_ek07 == . | ln_total_ek14 == .
codebook ln_total_ek00 ln_total_ek07 ln_total_ek14, detail
***************************************************************************************Execute completion regressions ***************************************************************************************
local hh_control urban_97 urban_00 urban_07 two_parent educ_hh educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07  
local indiv_control birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male
local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14 i.prov_97
local instrument kec_popkinder00 kec_popkinder90 
xtset mom_pidlink
foreach y in 00 07 14 {
	
	collect model_type="FE" has_fe="YES", tag(model[ek`y'_fe]): xtreg ek`y'_std kinder_ever `indiv_control' if switch == 1, fe vce(robust)
	
	collect model_type="OLS" has_fe="NO", tag(model[ek`y']): reg ek`y'_std kinder_ever `indiv_control' `comm_control' `instrument' `hh_control', vce(robust)
	
	collect model_type="IV", tag(model[ek`y'_iv]): ivregress gmm ek`y'_std  `hh_control' `indiv_control' `comm_control' (kinder_ever = `instrument'), wmatrix(robust)
	
}

collect layout (colname[kinder_ever educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07_07 elem_per_10000_00 junior_per_10000_07 senior_per_10000_14]#result[_r_b _r_se] result[model_type r2_a N]) (model[ek00 ek00_fe ek00_iv ek07 ek07_fe ek07_iv ek14 ek14_fe ek14_iv])
	collect style header result[_r_b _r_se], level(hide)
	collect style cell result[r2_a _r_b], nformat(%7.2f)  halign(center)
	collect style cell result[_r_se], nformat(%7.2f) sformat("(%s)") halign(center)
	collect style cell result[N], halign(center)
	collect label levels model ek00 "2000" ek07 "2007" ek14 "2014", replace
	collect style header model[ek00_fe ek07_fe ek14_fe ek00_iv ek07_iv ek14_iv], level(hide)
	collect label levels colname two_parent "Two-parent HH" educ_mom "Mom's years of education" ln_agg_expend_r_pc_97 "HH per-capita expenditure (1997)" ln_agg_expend_r_pc_00 "HH per-capita expenditure (2000)" ln_agg_expend_r_pc_07_07 "HH per-capita expenditure (2007)" elem_per_10000_00 "Elementaries per 10,000 (2000)" junior_per_10000_07 "Junior highs per 10,000 (2007)" senior_per_10000_14 "Senior highs per 10,000 (2014)" cohort "Birth cohort" birth_order "Birth order to mother" kinder_spillover "Older sibling attended kinder" tot_num_vis_97 "Healthcare visits" general_health_97 "General health status (1997)" kinder_ever "Kindergarten" educ14 "Years of education (2014)" elem_completion "Completed elementary" junior_completion "Completed junior high" senior_completion "Completed senior high" male "Male" kec_popkinder90 "Kindergartens/10,000 in kec. (1990)" kec_popkinder00 "Kindergartens/10,000 in kec. (2000)" 4.general_health_97 "Very healthy" 4.cohort "Oldest birth cohort" urban_97 "Urban", replace
	collect label levels result has_fe "Has Mom FE" model_type "Model", modify
	collect style cell result[has_fe model_type], halign(center)
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
	collect style tex, nobegintable
collect preview
	collect export "$output/full_ek.tex", tableonly replace

***************************************************************************************Look at other measures of test performance ***************************************************************************************
* first, let's generate change in performance for the test scores:
gen ek07_chg = ((total_ek07 - total_ek00) / total_ek00) * 100
gen ek14_chg = ((total_ek14 - total_ek07) / total_ek07) * 100
foreach k in 07 14 {
	egen ek`k'_chg_std = std(ek`k'_chg)
	sum ek`k'_chg 
	sum ek`k'_chg_std
		ivregress gmm ek`k'_chg `hh_control' `indiv_control' `comm_control' (kinder_ever = `instrument'), wmatrix(robust)
		ivregress gmm ek`k'_chg_std `hh_control' `indiv_control' `comm_control' (kinder_ever = `instrument'), wmatrix(robust)
}





