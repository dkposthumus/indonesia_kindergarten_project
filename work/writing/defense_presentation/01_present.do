/*
capture log close
log using 01_present, replace text
*/

/*
  program:    	01_present
  task:			To create tables for the defense presentation
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 28Apr2024
*/

version 17
clear all
set linesize 80
macro drop _all

*************************************************************************************Set Global Macros and Pull Master Dataset             *************************************************************************************
global clean "~/thesis_independent_study/work/data_clean"
global output "~/thesis_independent_study/work/writing/defense_presentation"
cd $clean 
	use master, clear
*************************************************************************************Abbreviated Summary Stats Table - Outcomes *************************************************************************************
collect clear 
	keep if sample == 1
foreach v in kinder_ever educ14 elem_completion junior_completion senior_completion ln_total_ek00 ln_total_ek07 ln_total_ek14 {
	bysort kinder_ever urban_97: collect, tag(sum[`v']): qui sum `v'
	bysort sample: collect, tag(sum[`v']): qui sum `v'
}
bysort sample: collect, tag(sum[sample]): sum sample
bysort kinder_ever urban_97: collect, tag(sum[sample]): sum sample
collect layout (sum[kinder_ever educ14 elem_completion junior_completion senior_completion ln_total_ek00 ln_total_ek07 ln_total_ek14]#result[mean sd] sum[sample]#result[N]) (sample[1] urban_97[1]#kinder_ever[1] urban_97[1]#kinder_ever[0] urban_97[0]#kinder_ever[1] urban_97[0]#kinder_ever[0])
	collect style header result[mean sd], level(hide)
	collect style header sum[sample], level(hide)
	collect style cell result[mean sd], nformat(%7.2f) halign(center) valign(center)
	collect style cell result[N], halign(center)
	collect style cell result[sd], sformat("(%s)")
	collect label levels sample 1 "Full Sample", replace
	collect label levels result N "Number of Observations", replace
	collect label levels switch 0 "Not Switching HH" 1 "Switching HH", replace
	collect label levels kinder_ever 0 "No Kinder" 1 "Kinder", replace
	collect label levels urban_97 1 "Urban" 0 "Rural", replace
	collect style cell switch kinder_ever, halign(center)
	collect style cell urban_97 kinder_ever, halign(center)
	collect label levels sum kinder_ever "Kindergarten attendance" educ14 "Years of education" elem_completion "Completed elementary" junior_completion "Completed junior high" senior_completion "Completed senior high" ln_total_ek00 "Cognitive score, ln (2000)" ln_total_ek07 "Cognitive score, ln (2007)" ln_total_ek14 "Cognitive score, ln (2014)", replace
	collect style column, dups(center)
	collect style tex, nobegintable
collect preview
	collect export "$output/sum_table_outcome.tex", replace tableonly
*************************************************************************************Abbreviated Summary Stats Table - Covariates *************************************************************************************
collect clear 
foreach v in educ_mom educ_hh ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 num_children {
	bysort kinder_ever urban_97: collect, tag(sum[`v']): qui sum `v'
	bysort sample: collect, tag(sum[`v']): qui sum `v'
}
bysort sample: collect, tag(sum[sample]): sum sample
bysort kinder_ever urban_97: collect, tag(sum[sample]): sum sample
collect layout (sum[educ_mom educ_hh ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 num_children]#result[mean sd] sum[sample]#result[N]) (sample[1] urban_97[1]#kinder_ever[1] urban_97[1]#kinder_ever[0] urban_97[0]#kinder_ever[1] urban_97[0]#kinder_ever[0])
	collect style header result[mean sd], level(hide)
	collect style header sum[sample], level(hide)
	collect style cell result[mean sd], nformat(%7.2f) halign(center) valign(center)
	collect style cell result[N], halign(center)
	collect style cell result[sd], sformat("(%s)")
	collect label levels sample 1 "Full Sample", replace
	collect label levels result N "Number of Observations", replace
	collect label levels switch 0 "Not Switching HH" 1 "Switching HH", replace
	collect label levels kinder_ever 0 "No Kinder" 1 "Kinder", replace
	collect label levels urban_97 1 "Urban" 0 "Rural", replace
	collect style cell switch kinder_ever, halign(center)
	collect style cell urban_97 kinder_ever, halign(center)
	collect label levels sum educ_mom "Mom's yrs of education" ln_agg_expend_r_pc_97 "HH per-capita expenditure (1997)" ln_agg_expend_r_pc_00 "HH per-capita expenditure (2000)" ln_agg_expend_r_pc_07 "HH per-capita expenditure (2007)" educ_hh "HH head's yrs of education" num_children "Number of children in HH", replace
	collect style tex, nobegintable
	collect style column, dups(center)
collect preview
	collect export "$output/sum_table_covar.tex", replace tableonly
*************************************************************************************Years of Education Estimation Table *************************************************************************************
local hh_control two_parent educ_hh educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 urban_97 urban_00 urban_07 num_children
local indiv_control i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male
local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14 i.prov_97
local instrument kec_popkinder00 kec_popkinder90
	collect clear
collect type="OLS", tag(model[(1)]): reg educ14 kinder_ever `hh_control' `indiv_control' `comm_control' `instrument', vce(robust)
xtset mom_pidlink
	collect type="FE", tag(model[(2)]): xtreg educ14 kinder_ever `indiv_control' if switch == 1, fe vce(robust)
	collect type="IV", tag(model[(3)]): ivregress gmm educ14 `comm_control' `hh_control' `indiv_control' (kinder_ever = `instrument'), wmatrix(robust)
* Now let's put all these results in a table together.
	collect label drop colname 
collect layout (colname[kinder_ever educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07_07]#result[_r_b _r_se] result[type r2_a N]) (model[(1) (2) (3)])
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b)
	collect style cell result[_r_b _r_se r2_a], nformat(%7.2f)
	collect style cell result[_r_se], sformat("(%s)")
	collect style cell border_block, border(right, pattern(nil))
	collect label levels result type "Model", modify
	collect label levels colname kinder_ever "Kindergarten" educ_mom "Mom's yrs of education" ln_agg_expend_r_pc_97 "HH per-capita expenditure (1997)" ln_agg_expend_r_pc_00 "HH per-capita expenditure (2000)" ln_agg_expend_r_pc_07_07 "HH per-capita expenditure (2007)", replace
	collect style header result[_r_b _r_se], level(hide)
	collect style cell result type r2_a N, halign(center)
	collect style tex, nobegintable
collect preview
	collect export "$output/educ_table.tex", replace tableonly
*************************************************************************************School Completion Estimation Table *************************************************************************************
	collect clear 
foreach v in elem junior senior {
	collect type="OLS", tag(model[`v']): qui reg `v'_completion kinder_ever `hh_control' `indiv_control' `comm_control' `instrument', vce(robust)
xtset mom_pidlink
	collect type="IV", tag(model[`v'_iv]): qui ivregress gmm `v'_completion `comm_control' `hh_control' `indiv_control' (kinder_ever = `instrument'), wmatrix(robust)
}
	collect label drop colname 
collect layout (colname[kinder_ever educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07_07]#result[_r_b _r_se] result[type r2_a N]) (model[elem elem_iv junior junior_iv senior senior_iv])
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b)
	collect style cell result[_r_b _r_se r2_a], nformat(%7.2f)
	collect style cell result[_r_se], sformat("(%s)")
	collect style cell border_block, border(right, pattern(nil))
	collect label levels result type "Model", modify
	collect label levels model elem "Elementary" junior "Junior High" senior "Senior High"
	collect label levels colname kinder_ever "Kindergarten" educ_mom "Mom's yrs of education" ln_agg_expend_r_pc_97 "HH per-capita expenditure (1997)" ln_agg_expend_r_pc_00 "HH per-capita expenditure (2000)" ln_agg_expend_r_pc_07_07 "HH per-capita expenditure (2007)", replace
	collect style header result[_r_b _r_se], level(hide)
	collect style header model[elem_iv junior_iv senior_iv], level(hide)
	collect style cell result model r2_a N, halign(center)
	collect style tex, nobegintable
collect preview
	collect export "$output/complete_table.tex", replace tableonly
*************************************************************************************Stay-On Estimation Table *************************************************************************************
	collect clear 
foreach v in 6 9 12 {
	collect type="OLS", tag(model[_`v']): qui reg stayon`v' kinder_ever `hh_control' `indiv_control' `comm_control' `instrument', vce(robust)
xtset mom_pidlink
	collect type="IV", tag(model[_`v'_iv]): qui ivregress gmm stayon`v' `comm_control' `hh_control' `indiv_control' (kinder_ever = `instrument'), wmatrix(robust)
}
	collect label drop colname 
collect layout (colname[kinder_ever educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07_07]#result[_r_b _r_se] result[type r2_a N]) (model[_6 _6_iv _9 _9_iv _12 _12_iv])
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b)
	collect style cell result[_r_b _r_se r2_a], nformat(%7.2f)
	collect style cell result[_r_se], sformat("(%s)")
	collect style cell border_block, border(right, pattern(nil))
	collect label levels result type "Model", modify
	collect label levels model _6 "6th Grade" _9 "9th Grade" _12 "12th Grade", replace
	collect label levels colname kinder_ever "Kindergarten" educ_mom "Mom's yrs of education" ln_agg_expend_r_pc_97 "HH per-capita expenditure (1997)" ln_agg_expend_r_pc_00 "HH per-capita expenditure (2000)" ln_agg_expend_r_pc_07_07 "HH per-capita expenditure (2007)", replace
	collect style header result[_r_b _r_se], level(hide)
	collect style header model[_6_iv _9_iv _12_iv], level(hide)
	collect style cell result model r2_a N, halign(center)
	collect style tex, nobegintable
collect preview
	collect export "$output/stayon_table.tex", replace tableonly
*************************************************************************************Cognitive Tests Estimation Table *************************************************************************************
	collect clear 
preserve 
	keep if ln_total_ek00 != . & ln_total_ek07 != . & ln_total_ek14 != .
foreach v in 00 07 14 {
	collect type="OLS", tag(model[_`v']): qui reg ln_total_ek`v' kinder_ever `hh_control' `indiv_control' `comm_control' `instrument', vce(robust)
xtset mom_pidlink
	collect type="IV", tag(model[_`v'_iv]): qui ivregress gmm ln_total_ek`v' `comm_control' `hh_control' `indiv_control' (kinder_ever = `instrument'), wmatrix(robust)
}
	collect label drop colname 
collect layout (colname[kinder_ever educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07_07]#result[_r_b _r_se] result[type r2_a N]) (model[_00 _00_iv _07 _07_iv _14 _14_iv])
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b)
	collect style cell result[_r_b _r_se r2_a], nformat(%7.2f)
	collect style cell result[_r_se], sformat("(%s)")
	collect style cell border_block, border(right, pattern(nil))
	collect label levels result type "Model", modify
	collect label levels model _00 "2000" _07 "2007" _14 "2014", replace
	collect label levels colname kinder_ever "Kindergarten" educ_mom "Mom's yrs of education" ln_agg_expend_r_pc_97 "HH per-capita expenditure (1997)" ln_agg_expend_r_pc_00 "HH per-capita expenditure (2000)" ln_agg_expend_r_pc_07_07 "HH per-capita expenditure (2007)", replace
	collect style header result[_r_b _r_se], level(hide)
	collect style header model[_00_iv _07_iv _14_iv], level(hide)
	collect style cell result model r2_a N, halign(center)
	collect style tex, nobegintable
collect preview
	collect export "$output/ek_table.tex", replace tableonly
