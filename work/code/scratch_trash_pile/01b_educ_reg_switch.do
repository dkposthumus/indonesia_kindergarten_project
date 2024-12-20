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
local hh_control two_parent educ_hh educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07  

local indiv_control i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97

	collect clear
keep if switch == 1
* Let's begin with running a univariate regression 
collect has_hh_controls="NO" has_indiv_controls="NO" has_mom_fe="NO", tag(model[(1)]): reg educ14 1.kinder_ever, vce(cluster mom_pidlink)
* Then let's run a regression with our full set of household controls
collect has_hh_controls="YES" has_indiv_controls="NO" has_mom_fe="NO", tag(model[(2)]): reg educ14 urban_97##kinder_ever `hh_control', vce(cluster mom_pidlink)
* Then let's run a regression with our full set of individual controls (w/no household controls)
collect has_hh_controls="NO" has_indiv_controls="YES" has_mom_fe="NO", tag(model[(3)]): reg educ14 urban_97##kinder_ever `indiv_control', vce(cluster mom_pidlink)
* Now let's run a regression with our full set of household and individual controls
collect has_hh_controls="YES" has_indiv_controls="YES" has_mom_fe="NO", tag(model[(4)]): reg educ14 urban_97##kinder_ever `hh_control' `indiv_control', vce(cluster mom_pidlink)
* Now let's run mother fixed effects. 
	* Note that for both of these specifications we're limiting our sample to mothers with more than one child, in order t ogenerate real variation within families.
xtset mom_pidlink
* We have a key problem, immediately: our weights are no longer consistent throughout our panel variable. (?????? --> what to do?)
		* First let's run a basic univariate regression.
	collect has_hh_controls="NO" has_indiv_controls="NO" has_mom_fe="YES", tag(model[(5)]): xtreg educ14 1.kinder_ever, fe vce(robust)
		* Now, let's add in our individual controls.
	collect has_hh_controls="NO" has_indiv_controls="YES" has_mom_fe="YES", tag(model[(6)]): xtreg educ14 1.kinder_ever `indiv_control', fe vce(robust)
* Now let's put all these results in a table together.
	collect label drop colname 
collect layout (colname[1.kinder_ever 1.urban_97 1.urban_97#1.kinder_ever]#result[_r_b _r_se] result[has_hh_controls has_indiv_controls has_mom_fe r2_a N]) (model[(1) (2) (4) (6)])
	collect label levels model (4) "(3)" (6) "(4)", modify
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
	collect style cell result[_r_b _r_se r2_a], nformat(%7.2f)
	collect style cell result[_r_se], sformat("(%s)")
	collect style cell border_block, border(right, pattern(nil))
	collect label levels result has_hh_controls "Household Controls" has_mom_fe "Mother Fixed-Effects" has_indiv_controls "Individual Controls" has_comm_controls "Community Controls"
	collect label levels colname 1.kinder_ever "Kinder" 1.urban_97 "Urban" 1.urban_97#1.kinder_ever "Urban x Kinder", replace
	collect style header result[_r_b _r_se], level(hide)
	collect style tex, nobegintable
	collect preview
		collect export "$output/regression_results_switch.tex", tableonly replace
