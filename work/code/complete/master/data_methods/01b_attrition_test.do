/*
capture log close
log using 01b_attrition_test, replace text
*/

/*
  program:    	01b_attrition_test
  task:			To test attrition randomness.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 11Jan2024
*/

version 17
clear all
set linesize 80
macro drop _all

**************************************************************************************Set Global Macros              **************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~/thesis_independent_study/work/code/to_do"
	global output "~/thesis_independent_study/work/writing/rough_draft/methods"
**************************************************************************************Attrition Probits **************************************************************************************
cd $clean
	use master, clear
		keep if ev_attrition != .
* Let's begin with a basic test of attrition probits (Fitzgerald et al, 1998)
* For this analysis we need two sets of varaibles: baseline values of all variables believed to affect the outcome variable of interest and variables characterizing interview process. We define these using locals below:
local hh_control educ_mom educ_hh ln_agg_expend_r_pc_97 urban_97 num_children
local indiv_control i.cohort tot_num_vis_97 male
local comm_control kec_popkinder00 kec_popkinder90
local interview_quality resp_interest_97 resp_accuracy_97
* For each regression specification we're going to generate a quick e(sample) variable and re-run to get the exactly correct number of observations:
logit ev_attrition `interview_quality' `hh_control' `indiv_control' `comm_control'
	gen logit_sample = e(sample)
keep if logit_sample == 1
* Then we merely run a series of probits with our attrition dummy as the dependent variable:
collect clear
* Probit w/only interview quality:
collect has_hh_controls="NO" has_indiv_controls="NO" has_community_controls="NO", tag(model[1]): logit ev_attrition `interview_quality', vce(cluster kec_97)
* Probit w/only interview quality and hh_controls:
collect has_hh_controls="YES" has_indiv_controls="NO" has_community_controls="NO", tag(model[2]): logit ev_attrition `interview_quality' `hh_control', vce(cluster kec_97)
* Probit w/only interview quality and indiv_controls:
collect has_hh_controls="NO" has_indiv_controls="YES" has_community_controls="NO", tag(model[3]): logit ev_attrition `interview_quality' `indiv_control', vce(robust)
* Probit w/only interview quality and community controls:
collect has_hh_controls="NO" has_indiv_controls="NO" has_community_controls="YES", tag(model[4]): logit ev_attrition `interview_quality' `comm_control', vce(robust)
* Probit w/full controls:
collect has_hh_controls="YES" has_indiv_controls="YES" has_community_controls="YES", tag(model[5]): logit ev_attrition `hh_control' `indiv_control' `interview_quality' `comm_control', vce(robust)
	
* Then let's build a table:
collect layout (colname[resp_interest_97 two_parent electricity urban_97 tot_num_vis_97]#result[_r_b _r_se] result[has_hh_controls has_indiv_controls has_community_controls N r2_p]) (model)
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
	collect style cell result[_r_b _r_se], nformat(%7.2f)
	collect style cell result[_r_se], sformat("(%s)")
	collect style cell border_block, border(right, pattern(nil))
	collect style row stack, spacer delimiter(" x ")
	collect label levels result has_hh_controls "Full Household Controls" has_mom_fe "Mother Fixed-Effects" has_indiv_controls "Full Individual Controls" has_community_controls "Full Community Controls"
	collect style header result[_r_b _r_se], level(hide)
	collect label levels colname educ14 "Years of education" kinder_ever "Attended kindergarten" exit_age "Exit age from school" labor_force "Labor force participation" ln_earnings "Earnings (ln)" fridge "HH has a fridge" television "HH has a television" electricity "HH has electricity" educ_mom "Mother's Years of Education" ln_agg_expend_r_pc "HH expenditure per capita (ln)" educ_hh "HH Head Education" tot_num_vis_97 "Visits to Outpatient Care (1997)" general_health_97 "General Health Status (1997)" resp_interest_97 "Respondent's Interest in Interview (1997)" resp_accuracy_97 "Respondent's Accuracy in Interview (1997)" two_parent "Two Parent household" num_children "Number of Mother's Children" urban_97 "Urban (1997)", replace
collect preview
	collect export "$output/attrition_logit.tex", replace tableonly
	* Clearly, these are significant, although not large in magnitude, predictors of attrition.
****************************************************************************************Pooling Test ****************************************************************************************
* Now let's create interaction term variables for all of our variables of interest:
foreach v in two_parent urban_97 cohort general_health_97 male prov_97 resp_interest_97 resp_accuracy_97 {
	xi i.ev_attrition*i.`v', prefix(I)
}
* now for continuous: 
foreach v in educ_hh educ_mom ln_agg_expend_r_pc_97 num_children birth_order tot_num_vis_97 kec_popkinder00 kec_popkinder90 {
	xi i.ev_attrition*`v', prefix(I)
}
* Then we'll estimate a clustered regression. Since educational outcomes are not available in 1997 and thus all observations that have a non-missing value for our educational outcome will be attrited, we are just going to use mother's education -- the most significant covariate in our fully-specified analysis, and a variable that exists for BOTH attrited and non-attrited observations.
reg `hh_control' `interview_quality' `indiv_control' `comm_control' Iev*, vce(robust)
* Then we are giong to test whether the attrition dummy and the interactions are jointly equal to 0:
ds Iev* 
testparm ev_attrition `r(varlist)'
* Clearly, by neither of our tests, is attrition random (here the P-value is 0 once again)
****************************************************************************************Calculate Inverse Probability Weights ****************************************************************************************
cd $clean
	use master, clear
		keep if ev_attrition != .
* To find the inverse probability weights, we begin by taking the predicted probabilities from the unrestricted attrition probit:
logit ev_attrition `interview_quality' `hh_control' `indiv_control' `comm_control', vce(robust)
		* Make sure the sample size is consistent:
			di e(N)
	predict pxav 
* Next we find the predicted probabilities in out restricted probit -- which excludes the auxiliary variables (or the interview quality variables):
logit ev_attrition `hh_control' `indiv_control' `comm_control', vce(robust)
		* Make sure the sample size is consistent:
			di e(N)
	predict pxres
* The inverse probability weight is merely the ratio between these two predicted values:
	gen attwght=pxres/pxav 
		label var attwght "inverse probability weight"
	* Let's graph a quick histogram of these weight:
		sum attwght
	hist attwght if sample == 1, percent xtitle("Inverse Probability Weight") title("Inverse Probability Weight Distribution") xline(`r(mean)', extend)
		graph export "$output/attwght_hist.png", replace
****************************************************************************************Compare results when using probability weights and when not ****************************************************************************************
local hh_control two_parent educ_hh educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 urban_97 urban_00 urban_07 num_children
local indiv_control i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male
local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14 i.prov_97
local instrument kec_popkinder00 kec_popkinder90 
collect clear
collect has_wght="YES" type="OLS", tag(model[(1)]): reg educ14 kinder_ever `hh_control' `indiv_control' `comm_control' `instrument' [pweight = attwght], vce(robust) 
collect has_wght="NO" type="OLS", tag(model[(2)]): reg educ14 kinder_ever `hh_control' `indiv_control' `comm_control' `instrument', vce(robust) 
collect has_wght="YES" type="IV", tag(model[(3)]): ivregress gmm educ14 `hh_control' `indiv_control' `comm_control' (kinder_ever = `instrument') [pweight = attwght], vce(robust) 
collect has_wght="NO" type="IV", tag(model[(4)]): ivregress gmm educ14 `hh_control' `indiv_control' `comm_control' (kinder_ever = `instrument'), vce(robust)

collect layout (colname#result[_r_b _r_se] result[F r2_a N has_wght type]) (model)
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
	collect style cell result[_r_b _r_se r2_a], nformat(%7.2f)
	collect style cell result[_r_se], sformat("(%s)")
	collect style cell border_block, border(right, pattern(nil))
	collect label levels colname kinder_ever "Kinder" urban_97 "Urban (1997)" urban_00 "Urban (2000)" urban_07 "Urban (2007)" two_parent "Two-parent HH" educ_hh "HH head's education" educ_mom "Mother's education" ln_agg_expend_r_pc_97 "HH per-capita expenditure (1997)" ln_agg_expend_r_pc_00 "HH per-capita expenditure (2000)" ln_agg_expend_r_pc_07_07 "HH per-capita expenditure (2007)" 4.cohort "Oldest birth cohort" birth_order "Birth order" kinder_spillover "Spillover dummy" 2.general_health_97 "Poor health (1997)" 3.general_health_97 "Fairly healthy (1997)" 4.general_health_97 "Very healthy (1997)" tot_num_vis_97 "Total visits to healthcare (1997)" male "Male" kec_popkinder90 "Kindergartens/10,000 in kec. (1990)" kec_popkinder00 "Kindergartens/10,000 in kec. (2000)", replace
	collect label levels result has_mom_fe "Has mother fixed-effects" _switch "Restricted to FE sample"
	collect style header result[_r_b _r_se], level(hide)
	collect style tex, nobegintable
	collect preview

/*
log close
exit





