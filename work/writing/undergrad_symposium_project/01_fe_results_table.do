/*
capture log close
log using 01_fe_results_table, replace text
*/

/*
  program:    	01_fe_results_table
  task:			To build a compact table of fixed-effects results for honors symposium.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 07Mar2024
*/

version 17
clear all
set linesize 80
macro drop _all

***************************************************************************************Set Global Macros              ***************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~thesis_independent_study/work/code/to_do"
	global output "~/thesis_independent_study/work/writing/undergrad_symposium_project"
***************************************************************************************Run basic regression specifications ***************************************************************************************
cd $clean
use master, clear
local hh_control urban_97 two_parent educ_hh educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07  

local indiv_control i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male

local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14

	collect clear
keep if sample == 1
* Now let's run a regression with our full set of household and individual controls
collect has_hh_controls="YES" has_indiv_controls="YES" has_mom_fe="NO", tag(model[educ14]): reg educ14 kinder_ever `hh_control' `indiv_control', vce(cluster mom_pidlink)
* Now let's run mother fixed effects. 
	* Note that for both of these specifications we're limiting our sample to mothers with more than one child, in order t ogenerate real variation within families.
xtset mom_pidlink
		* Now, let's add in our individual controls.
	collect has_hh_controls="NO" has_indiv_controls="YES" has_mom_fe="YES", tag(model[educ14_fe]): xtreg educ14 kinder_ever `indiv_control', fe vce(robust)
	* Now let's run a regression for the completion variables:
collect has_hh_controls="NO" has_indiv_controls="YES" has_mom_fe="YES", tag(model[elem_completion]): xtreg elem_completion kinder_ever `indiv_control', fe vce(robust)
	* Second, junior_completion:
collect has_hh_controls="NO" has_indiv_controls="YES" has_mom_fe="YES", tag(model[junior_completion]): xtreg junior_completion kinder_ever `indiv_control', fe vce(robust)
	* Third, senior_completion:
collect has_hh_controls="NO" has_indiv_controls="YES" has_mom_fe="YES", tag(model[senior_completion]): xtreg senior_completion kinder_ever `indiv_control', fe vce(robust)
	
* Now let's put all these results in a table together.
	collect label drop colname 
collect layout (colname[kinder_ever]#result[_r_b _r_se] result[has_hh_controls has_indiv_controls has_mom_fe r2_a N]) (model[educ14 educ14_fe elem_completion junior_completion senior_completion])
	collect label levels model (4) "(3)" (6) "(4)", modify
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b)
	collect style cell result[_r_b _r_se], nformat(%7.2f) halign(right)
	collect style cell result[r2_a], nformat(%7.2f)
	collect style cell result[_r_se], sformat("(%s)")
	collect style cell border_block, border(right, pattern(nil))
	collect label levels result has_hh_controls "Household Controls" has_mom_fe "Mother Fixed-Effects" has_indiv_controls "Individual Controls" has_comm_controls "Community Controls"
	collect label levels model educ14 "educ yrs" educ14_fe "educ yrs" elem_completion "elem completion" junior_completion "junior completion" senior_completion "senior completion"
	collect label levels colname kinder_ever "Kinder", replace
	collect style header result[_r_b _r_se], level(hide)
	collect style tex, nobegintable
	collect preview
		collect export "$output/fe_results.tex", tableonly replace
