/*
capture log close
log using 90_master_do, replace text
*/

/*
  program:    	90_master_do
  task:			To run every do-file as part of the project.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 11Apr2024
*/

version 17
clear all
set linesize 80
macro drop _all

**************************************************************************************
* Set Global Macros              **************************************************************************************
global code "~/thesis_independent_study/work/code/complete"
**************************************************************************************
* Run PODES Data-Cleaning Files **************************************************************************************
cd "~/thesis_independent_study/work/code/complete/podes"
	do 01_podes00.do
cd "~/thesis_independent_study/work/code/complete/podes"
	do 02_podes90.do 
cd "~/thesis_independent_study/work/code/complete/podes"
	do 03_podes_merge.do
**************************************************************************************
* Run IFLS Data-Cleaning Files **************************************************************************************
cd "~/thesis_independent_study/work/code/complete/master"
	do 02_sample.do 
cd "~/thesis_independent_study/work/code/complete/master"
	do 03_iv_create.do
cd "~/thesis_independent_study/work/code/complete/master"
	do 04_switch.do
cd "~/thesis_independent_study/work/code/complete/master"
	do 05_hh_var.do 
**************************************************************************************
* Data-Methods Files  **************************************************************************************
cd "~/thesis_independent_study/work/code/complete/master/data_methods"
	do 01a_attrition_fig.do
cd "~/thesis_independent_study/work/code/complete/master/data_methods"
	do 01b_attrition_test.do 
cd "~/thesis_independent_study/work/code/complete/master/data_methods"
	do 02_sum_graphs.do
cd "~/thesis_independent_study/work/code/complete/master/data_methods"
	do 03_sum_tables.do
**************************************************************************************
* IV Estimation Files **************************************************************************************
cd "~/thesis_independent_study/work/code/complete/master/instrument_variable"
	do 01_iv_educ.do 
cd "~/thesis_independent_study/work/code/complete/master/instrument_variable"
	do 01a_iv_educ_resid.do
cd "~/thesis_independent_study/work/code/complete/master/instrument_variable"
	do 02_iv_exog.do
cd "~/thesis_independent_study/work/code/complete/master/instrument_variable"
	do 03_iv_homosk.do 
cd "~/thesis_independent_study/work/code/complete/master/instrument_variable"
	do 04_etregress.do 
cd "~/thesis_independent_study/work/code/complete/master/instrument_variable"
	do 05_iv_migrat.do 
cd "~/thesis_independent_study/work/code/complete/master/instrument_variable"
	do 06_iv_switch.do 
cd "~/thesis_independent_study/work/code/complete/master/instrument_variable"
	do 07_iv_alt.do 
**************************************************************************************
* Regression Files **************************************************************************************
cd "~/thesis_independent_study/work/code/complete/master/regression"
	do 00_logit_kinder.do
cd "~/thesis_independent_study/work/code/complete/master/regression"
	do 01_reg_educ.do
cd "~/thesis_independent_study/work/code/complete/master/regression"
	do 02_reg_in_schl.do
cd "~/thesis_independent_study/work/code/complete/master/regression"
	do 03_reg_complete.do 
cd "~/thesis_independent_study/work/code/complete/master/regression"
	do 05_reg_ek.do 
cd "~/thesis_independent_study/work/code/complete/master/regression"
	do 06_reg_stayon.do 
cd "~/thesis_independent_study/work/code/complete/master/regression"
	do 90_reg_homosk 
cd "~/thesis_independent_study/work/code/complete/master/regression"
	do 91_reg_ovtestdo.do 
cd "~/thesis_independent_study/work/code/complete/master/regression"
	do 92_reg_switch.do 
cd "~/thesis_independent_study/work/code/complete/master/regression"
	do 93_reg_migrat.do

/*
log close
exit
*/
