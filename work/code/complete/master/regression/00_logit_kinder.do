/*
capture log close
log using 01_educ_reg_comm, replace text
*/

/*
  program:    	00_kinder_logit.do 
  task:			To use logit to analyze selection into kindergarten attendance.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 18Mar2024
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
*collect _switch="NO" has_mom_fe="NO", tag(model[(1)]): logit kinder_ever `hh_control'
* Then let's run a regression with our full set
qui logit kinder_ever `hh_control' `indiv_control' `comm_control', vce(robust)
	collect _switch="NO" has_mom_fe="NO", tag(model[(1)]): margins, dydx(*)
* now let's run the full set w/only the switching sample:
	qui logit kinder_ever `hh_control' `indiv_control' `comm_control' if switch==1, vce(robust)
	collect _switch="YES" has_mom_fe="NO", tag(model[(2)]): margins, dydx(*)
	* Now let's run mother fixed effects. 
	* Note that for both of these specifications we're limiting our sample to mothers with more than one child, in order t ogenerate real variation within families.
xtset mom_pidlink
		* let's run a basic univariate regression.
	qui xtlogit kinder_ever `indiv_control' if switch==1, fe
	collect _switch="YES" has_mom_fe="YES", tag(model[(3)]): margins, dydx(*)
* Now let's put all these results in a table together.
	collect label drop colname 
collect layout (colname[urban_97 two_parent educ_hh educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07_07 4.cohort birth_order kinder_spillover tot_num_vis_07 1.general_health 2.general_health_97 3.general_health_97 4.general_health_97 tot_num_vis_97 male kec_popkinder90 kec_popkinder00]#result[_r_b _r_se] result[_switch has_mom_fe r2_a N]) (model[(1) (2) (3)])
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
	collect style cell result[_r_b _r_se r2_a], nformat(%7.2f)
	collect style cell result[_switch has_mom_fe r2_a N], halign(center)
	collect style cell result[_r_se], sformat("(%s)")
	collect style cell border_block, border(right, pattern(nil))
	collect label levels colname two_parent "Two-parent HH" educ_mom "Mom's years of education" ln_agg_expend_r_pc_97 "HH per-capita expenditure (1997)" ln_agg_expend_r_pc_00 "HH per-capita expenditure (2000)" ln_agg_expend_r_pc_07_07 "HH per-capita expenditure (2007)" elem_per_10000_00 "Elementaries per 10,000 (2000)" junior_per_10000_07 "Junior highs per 10,000 (2007)" senior_per_10000_14 "Senior highs per 10,000 (2014)" cohort "Birth cohort" birth_order "Birth order to mother" kinder_spillover "Older sibling attended kinder" tot_num_vis_97 "Healthcare visits" general_health_97 "General health status (1997)" kinder_ever "Kindergarten" educ14 "Years of education (2014)" elem_completion "Completed elementary" junior_completion "Completed junior high" senior_completion "Completed senior high" male "Male" kec_popkinder90 "Kindergartens/10,000 in kec. (1990)" kec_popkinder00 "Kindergartens/10,000 in kec. (2000)" 4.general_health_97 "Very healthy" 4.cohort "Oldest birth cohort" urban_97 "Urban" 2.general_health_97 "Poorly healthly" 3.general_health_97 "Fairly healthy" educ_hh "HH head's years of education", replace
	collect label levels result has_mom_fe "Has mother fixed-effects" _switch "Restricted to FE sample"
	collect style header result[_r_b _r_se], level(hide)
	collect style tex, nobegintable
	collect preview
		collect export "$output/kinder_logit.tex", tableonly replace
