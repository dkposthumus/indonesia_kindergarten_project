/*
capture log close
log using 01_educ_reg_comm, replace text
*/

/*
  program:    	01_educ_reg_comm
  task:			To execute and analyze OLS results for the community characteristics 
				variable-included sample.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 29Feb2024
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
***************************************************************************************Run basic regression specifications ***************************************************************************************
cd $clean
use master, clear
local hh_control two_parent educ_hh educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 urban_97 urban_00 urban_07 num_children
local indiv_control i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male
local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14 kec_popkinder00 kec_popkinder90 i.prov_97

	collect clear
keep if sample == 1
* Let's begin with running a univariate regression 
collect has_hh_controls="NO" has_indiv_controls="NO" has_comm_controls="NO" has_mom_fe="NO", tag(model[(1)]): reg educ14 kinder_ever, vce(cluster mom_pidlink)
* Then let's run a regression with our full set of household controls
collect has_hh_controls="YES" has_indiv_controls="NO" has_comm_controls="NO" has_mom_fe="NO", tag(model[(2)]): reg educ14 kinder_ever `hh_control', vce(robust)
* Then let's run a regression with our full set of individual controls (w/no household controls)
collect has_hh_controls="NO" has_indiv_controls="YES" has_mom_fe="NO", tag(model[(3)]): reg educ14 kinder_ever `indiv_control', vce(robust)
* Now let's run a regression with our full set of household and individual controls
collect has_hh_controls="YES" has_indiv_controls="YES" has_comm_controls="YES" has_mom_fe="NO", tag(model[(4)]): reg educ14 kinder_ever `hh_control' `indiv_control' `comm_control', vce(cluster mom_pidlink)
* Now let's run mother fixed effects. 
	* Note that for both of these specifications we're limiting our sample to mothers with more than one child, in order t ogenerate real variation within families.
xtset mom_pidlink
		* First let's run a basic univariate regression.
	collect has_hh_controls="NO" has_indiv_controls="NO" has_mom_fe="YES", tag(model[(5)]): xtreg educ14 kinder_ever if switch == 1, fe vce(robust)
		* Now, let's add in our individual controls.
	collect has_hh_controls="NO" has_indiv_controls="YES" has_mom_fe="YES", tag(model[(6)]): xtreg educ14 kinder_ever `indiv_control' if switch == 1, fe vce(robust)
* Now let's put all these results in a table together.
	collect label drop colname 
collect layout (colname[kinder_ever]#result[_r_b _r_se] result[has_hh_controls has_indiv_controls has_mom_fe r2_a N]) (model[(1) (2) (4) (6)])
	collect label levels model (4) "(3)" (6) "(4)", modify
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
	collect style cell result[_r_b _r_se r2_a], nformat(%7.2f)
	collect style cell result[_r_se], sformat("(%s)")
	collect style cell border_block, border(right, pattern(nil))
	collect label levels result has_hh_controls "Household Controls" has_mom_fe "Mother Fixed-Effects" has_indiv_controls "Individual Controls" has_comm_controls "Community Controls"
	collect label levels colname kinder_ever "Kinder", replace
	collect label levels colname kinder_ever "Kinder", replace
	collect style header result[_r_b _r_se], level(hide)
	collect style tex, nobegintable
	collect preview
		collect export "$output/regression_results_main.tex", tableonly replace
* now let's create a table with all coefficents
collect layout (colname[kinder_ever urban_97 urban_00 urban_07 two_parent educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07_07 kec_popkinder90 kec_popkinder00 4.cohort birth_order kinder_spillover tot_num_vis_97 4.general_health_97 male]#result[_r_b _r_se] result[has_mom_fe r2_a N]) (model[(1) (2) (4) (6)])
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
	collect style cell result[_r_b _r_se r2_a], nformat(%7.2f) halign(center)
	collect style cell result[N has_mom_fe], halign(center)
	collect style cell result[_r_se], sformat("(%s)")
	collect style cell border_block, border(right, pattern(nil))
	collect label levels colname two_parent "Two-parent HH" educ_mom "Mom's years of education" ln_agg_expend_r_pc_97 "HH per-capita expenditure (1997)" ln_agg_expend_r_pc_00 "HH per-capita expenditure (2000)" ln_agg_expend_r_pc_07_07 "HH per-capita expenditure (2007)" elem_per_10000_00 "Elementaries per 10,000 (2000)" junior_per_10000_07 "Junior highs per 10,000 (2007)" senior_per_10000_14 "Senior highs per 10,000 (2014)" cohort "Birth cohort" birth_order "Birth order to mother" kinder_spillover "Older sibling attended kinder" tot_num_vis_97 "Healthcare visits" general_health_97 "General health status (1997)" kinder_ever "Kindergarten" educ14 "Years of education (2014)" elem_completion "Completed elementary" junior_completion "Completed junior high" senior_completion "Completed senior high" male "Male" kec_popkinder90 "Kindergartens/10,000 in kec. (1990)" kec_popkinder00 "Kindergartens/10,000 in kec. (2000)" 4.general_health_97 "Very healthy" 4.cohort "Oldest birth cohort" urban_97 "Urban (1997)" urban_00 "Urban (2000)" urban_07 "Urban (2007)", replace
	collect label levels result has_mom_fe "Has mother fixed-effects" _switch "Restricted to FE sample"
	collect style header result[_r_b _r_se], level(hide)
	collect style tex, nobegintable
	collect preview
		collect export "$output/regression_results_full.tex", tableonly replace
***************************************************************************************Post-Estimation ***************************************************************************************
* run full OLS specification for post-estimation analysis:
qui reg educ14 kinder_ever `hh_control' `comm_control' `indiv_control'
	predict uhat, residual 
	predict yhat, xb 
	* first, test kinder_ever: 
	test kinder_ever
	* next, a basic residual diagnosis plot 
	rvfplot, msize(tiny) scale(1.2)
	estat hettest, iid 
	* my errors are absurdly heteroskedastic 
	estat ovtest
	linktest
reg educ14 kinder_ever `hh_control' `comm_control' `indiv_control' if switch == 1, vce(robust)



