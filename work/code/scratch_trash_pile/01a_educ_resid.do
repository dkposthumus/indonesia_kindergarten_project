/*
capture log close
log using 01_attrition, replace text
*/

/*
  program:    	01_ols_analysis
  task:			To execute and analyze OLS residuals.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 01Jan2024
*/

version 17
clear all
set linesize 80
macro drop _all

*******************************************************************************************Set Global Macros              *******************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~thesis_independent_study/work/code/to_do"
		global output "~/thesis_independent_study/work/writing/rough_draft/analysis"	
*******************************************************************************************Install appropiate programs             *******************************************************************************************
ssc install binscatter
*******************************************************************************************Run and analyze univariate regression estimation *******************************************************************************************
cd $clean
	use master, clear
		collect clear
tempfile master
* Let's first create our local macros for the control variables, w/our 3 categories
local hh_control two_parent ln_agg_expend_r_pc electricity educ_mom num_children
local indiv_control i.cohort male birth_order general_health_97 tot_num_vis_97
local comm_control elem_per_person junior_per_person senior_per_person
* Let's begin with running a univariate regression 
	keep if sample == 1
qui reg educ14 kinder_ever [pw=attwght], vce(cluster kec_97)
	* Now let's create a predicted level of education variable:
		predict yhat_univar, xb
			gen univar_resid = educ14 - yhat_univar
binscatter kinder_ever univar_resid, name(univar) nodraw
	collect: pwcorr kinder_ever univar_resid
*******************************************************************************************Run and analyze hh_control regression estimation *******************************************************************************************
qui reg educ14 kinder_ever##urban_97 `hh_control' `comm_control' [pw=attwght], vce(cluster kec_97)
	* Now let's create a predicted level of education variable:
		predict yhat_hh_ctrl, xb
			gen hh_ctrl_resid = educ14 - yhat_hh_ctrl
binscatter kinder_ever hh_ctrl_resid, name(hh_ctrl) nodraw
	collect: pwcorr kinder_ever hh_ctrl_resid
*******************************************************************************************Run and analyze hh_control and indiv_control regression estimation *******************************************************************************************
qui reg educ14 kinder_ever##urban_97 `hh_control' `comm_control' `indiv_control' [pw=attwght], vce(cluster kec_97)
	* Now let's create a predicted level of education variable:
		predict yhat_indiv_ctrl, xb
			gen hh_indiv_ctrl_resid = educ14 - yhat_indiv_ctrl
binscatter kinder_ever hh_indiv_ctrl_resid, name(hh_indiv_ctrl) nodraw
	collect: pwcorr kinder_ever hh_indiv_ctrl_resid
*******************************************************************************************Run and analyze mother fixed effects regression estimation *******************************************************************************************
	xtset mom_pidlink
qui xtreg educ14 kinder_ever, fe vce(cluster kec_97)
	* Now let's create a predicted level of education variable:
		predict yhat_fe, xb
			gen fe_resid = educ14 - yhat_fe
binscatter kinder_ever fe_resid, name(fe) nodraw
	collect: pwcorr kinder_ever fe_resid
*******************************************************************************************Run and analyze mother fixed effects w/indiv controls regression estimation *******************************************************************************************
qui xtreg educ14 kinder_ever `indiv_control', fe vce(cluster kec_97)
	* Now let's create a predicted level of education variable:
		predict yhat_indiv_fe, xb
			gen fe_indiv_resid = educ14 - yhat_indiv_fe
binscatter kinder_ever fe_indiv_resid, name(fe_indiv) nodraw
	collect: pwcorr kinder_ever fe_indiv_resid
save `master'
*******************************************************************************************Make correlation table *******************************************************************************************
collect layout (colname[univar_resid hh_ctrl_resid hh_indiv_ctrl_resid fe_resid fe_indiv_resid]#result[C]) (rowname[kinder_ever])
	collect label levels colname univar_resid "Univariate" hh_ctrl_resid "HH/Community Ctrls" hh_indiv_ctrl "HH/Community/Indiv Ctrls" fe_resid "Mom FE" fe_indiv_resid "Mom FE w/Indiv Ctrls"
	collect style header result[C], level(hide)
	collect title "Residual Correlations w/Explanatory Variable, by Model Specification"
	collect style cell result[C], nformat(%6.3f)
collect preview
	collect export "$output/resid_corr_table.tex", replace tableonly
*******************************************************************************************Create a "total" binscatter graph *******************************************************************************************
* To create this scatterplot, we're going to have to do a quick reshape.
keep pidlink kinder_ever univar_resid hh_ctrl_resid hh_indiv_ctrl_resid fe_resid fe_indiv_resid
rename (univar_resid hh_ctrl_resid hh_indiv_ctrl_resid fe_resid fe_indiv_resid) (resid1 resid2 resid3 resid4 resid5)
reshape long resid, i(pidlink) j(resid_type)
binscatter kinder_ever resid, by(resid_type) legend(label(1 "Univariate") label(2 "HH Ctrls") label(3 "HH/Individual Ctrls") label(4 "Mom FE") label(5 "Mom FE w/Indiv Ctrls")) xtitle("Residual Value") ytitle("Attended Kindergarten") title("Correlation Between Residuals and Explanatory Power," "By Specification")
	graph export "$output/resid_binscatter.png", replace
*******************************************************************************************Summarize predictions *******************************************************************************************
use `master', clear
sum educ14 yhat*
* Now let's create a quick table for this:
collect clear
	collect, tag(var[y]): sum educ14
	collect has_hh_ctrls="NO" has_comm_ctrls="NO" has_indiv_ctrls="NO" has_mom_fe="NO", tag(var[univar]): sum yhat_univar
	collect has_hh_ctrls="YES" has_comm_ctrls="YES" has_indiv_ctrls="NO" has_mom_fe="NO", tag(var[hh_ctrl]): sum yhat_hh_ctrl
	collect has_hh_ctrls="YES" has_comm_ctrls="YES" has_indiv_ctrls="YES" has_mom_fe="NO", tag(var[indiv_ctrl]): sum yhat_indiv_ctrl
	collect has_hh_ctrls="NO" has_comm_ctrls="NO" has_indiv_ctrls="NO" has_mom_fe="YES", tag(var[fe]): sum yhat_fe
	collect has_hh_ctrls="NO" has_comm_ctrls="NO" has_indiv_ctrls="YES" has_mom_fe="YES", tag(var[indiv_fe]): sum yhat_indiv_fe
collect layout (var) (result[mean sd has_mom_fe has_hh_ctrls has_comm_ctrls has_indiv_ctrls])
collect style cell result, halign(center) nformat(%7.2f)
collect label levels var y "Education (Actual)" univar "Education (Prediction)" hh_ctrl "Education (Prediction)" indiv_ctrl "Education (Prediction)" fe "Education (Prediction)" indiv_fe "Education (Prediction)"
	collect label levels result has_hh_ctrls "HH Ctrls" has_mom_fe "Mom FE" has_indiv_ctrls "Indiv. Ctrls" has_comm_ctrls "Comm. Ctrls"
collect preview












