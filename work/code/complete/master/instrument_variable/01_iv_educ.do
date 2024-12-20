/*
capture log close
log using 01_iv_educ, replace text
*/

/*
  program:    	01_iv_educ
  task:			To run IV estimations for years of education
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 23Feb2024
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
***************************************************************************************Run basic IV regression/estimations and build main table of results ***************************************************************************************
cd $clean
use master, clear
* Let's define locals for our variables of interest:
local hh_control urban_97 two_parent educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 i.prov_97
local indiv_control i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male
local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14
local instrument kec_popkinder00 kec_popkinder90
* Let's only keep observations in our sample:
	keep if sample == 1
collect clear
* I am going to start with a univariate regression, using only kindergarten attendance as the endogenous, or troublesome regressors. Since this is a just-identified case, I will use 2sls (second-stage least squares):
collect has_hh_controls="NO" has_comm_controls="NO" has_indiv_controls="NO", tag(model[1]): ivregress gmm educ14 (kinder_ever = `instrument'), first wmatrix(robust)
* Let's now test for the endogeneity of our regressor, for which we'll use the Hausman test
estat endogenous
* Let's add the household and community-level controls:
collect has_hh_controls="YES" has_comm_controls="NO" has_indiv_controls="NO", tag(model[2]): ivregress gmm educ14 `hh_control' (kinder_ever =  kec_popkinder00 kec_popkinder90), first wmatrix(robust)
* Let's add the household and community-level controls:
collect has_hh_controls="YES" has_comm_controls="NO" has_indiv_controls="YES", tag(model[3]): ivregress gmm educ14 `hh_control' `indiv_control' (kinder_ever =  `instrument'), first wmatrix(robust)
* Now let's add the individual controls:
collect has_hh_controls="YES" has_comm_controls="YES" has_indiv_controls="YES", tag(model[4]): ivregress gmm educ14 `hh_control' `indiv_control' `comm_control' (kinder_ever = `instrument'), first wmatrix(robust)
* Now let's build the table of our results:
collect layout (colname[kinder_ever urban_97 urban_00 urban_07 two_parent educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07_07 4.cohort birth_order kinder_spillover tot_num_vis_97 4.general_health_97 male]#result[_r_b _r_se] result[has_hh_controls has_indiv_controls has_comm_controls N r2_a]) (model[1 2 3 4])
	collect label levels colname two_parent "Two-parent HH" educ_mom "Mom's years of education" ln_agg_expend_r_pc_97 "HH per-capita expenditure (1997)" ln_agg_expend_r_pc_00 "HH per-capita expenditure (2000)" ln_agg_expend_r_pc_07_07 "HH per-capita expenditure (2007)" elem_per_10000_00 "Elementaries per 10,000 (2000)" junior_per_10000_07 "Junior highs per 10,000 (2007)" senior_per_10000_14 "Senior highs per 10,000 (2014)" cohort "Birth cohort" birth_order "Birth order to mother" kinder_spillover "Older sibling attended kinder" tot_num_vis_97 "Healthcare visits" general_health_97 "General health status (1997)" kinder_ever "Kindergarten" educ14 "Years of education (2014)" elem_completion "Completed elementary" junior_completion "Completed junior high" senior_completion "Completed senior high" male "Male" kec_popkinder90 "Kindergartens/10,000 in kec. (1990)" kec_popkinder00 "Kindergartens/10,000 in kec. (2000)" 4.general_health_97 "Very healthy" 4.cohort "Oldest birth cohort" urban_97 "Urban", replace
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b)
	collect style cell result[_r_b _r_se r2_a], nformat(%7.2f)
	collect style cell result[_r_se], sformat("(%s)")
	collect style cell border_block, border(right, pattern(nil))
	collect label levels result has_hh_controls "Household Controls" has_mom_fe "Mother Fixed-Effects" has_indiv_controls "Individual Controls" has_comm_controls "Community Controls"
	collect label levels model 1 "(1)" 2 "(2)" 3 "(3)" 4 "(4)", replace
	collect style header result[_r_b _r_se], level(hide)
	collect style cell result has_hh_controls has_indiv_controls has_comm_controls N r2_a, halign(center)
	collect style tex, nobegintable
	collect preview
		collect export "$output/iv_results_main.tex", tableonly replace
***************************************************************************************Run first-stage regressions and build table ***************************************************************************************
collect clear
foreach k in 90 00 {
* Now let's run the first stage regression, which is merely all of my control variables (as listed above) as regressors and kinder_ever as my dependent variable:
collect has_hh_controls="NO" has_comm_controls="NO" has_indiv_controls="NO", tag(model[`k'_1]): qui regress kinder_ever kec_popkinder`k', vce(robust)
* Let's add the household and community-level controls:
collect has_hh_controls="YES" has_comm_controls="NO" has_indiv_controls="NO", tag(model[`k'_2]): qui regress kinder_ever kec_popkinder`k' `hh_control', vce(robust)
collect has_hh_controls="YES" has_comm_controls="NO" has_indiv_controls="YES", tag(model[`k'_3]): qui regress kinder_ever kec_popkinder`k' `hh_control' `indiv_control', vce(robust)
* Now let's add the individual controls:
collect has_hh_controls="YES" has_comm_controls="YES" has_indiv_controls="YES", tag(model[`k'_4]): qui regress kinder_ever kec_popkinder`k' `hh_control' `comm_control' `indiv_control', vce(robust)
		test kec_popkinder`k'
	collect label levels model `k'_1 "(1)" `k'_2 "(2)" `k'_3 "(3)" `k'_4 "(4)"
} 
* Now let's build the table of our results:
collect layout (colname[kec_popkinder90 kec_popkinder00]#result[_r_b _r_se] result[has_hh_controls has_indiv_controls has_comm_controls r2_a F N]) (model[90_1 00_1 90_2 00_2 90_3 00_3 90_4 00_4])
	collect label levels colname kec_popkinder00 "Kindergartens/10,000 people (2000)" kec_popkinder90 "Kindergartens/10,000 people (1990)"
	collect label levels result has_hh_controls "Household Controls" has_mom_fe "Mother Fixed-Effects" has_indiv_controls "Individual Controls" has_comm_controls "Community Controls"
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b)
	collect style cell result[_r_b _r_se r2_a F], nformat(%7.2f)
	collect style cell result[_r_se], sformat("(%s)")
	collect style cell border_block, border(right, pattern(nil))
	collect style header result[_r_b _r_se], level(hide)
	collect style tex, nobegintable
	collect style cell result has_hh_controls has_indiv_controls has_comm_controls r2_a F N, halign(center)
collect preview
	collect export "$output/iv_first_stage.tex", tableonly replace
***************************************************************************************Test instrument exogeneity ***************************************************************************************
ivregress gmm educ14 (kinder_ever = `instrument') `hh_control' `indiv_control' `comm_control', wmatrix(robust)
estat overid
/*
log close
exit
*/





	


