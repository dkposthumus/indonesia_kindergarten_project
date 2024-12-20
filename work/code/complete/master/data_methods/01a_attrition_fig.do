/*
capture log close
log using 01a_attrition_fig, replace text
*/

/*
  program:    	01a_attrition_fig
  task:			To create figures and tables analyzing the attrition of my sample.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 25Feb2024
*/

version 17
clear all
set linesize 80
macro drop _all

***************************************************************************************Set Global Macros              ***************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~thesis_independent_study/work/code/to_do"
	global output "~/thesis_independent_study/work/writing/rough_draft/data"
***************************************************************************************Attrition Table ***************************************************************************************
cd "$clean"
	use master, clear
	keep if sample1 == 1
* With the table, we're trying to capture two things:
	* The mean observation of the pre-treatment household variables
	* The total number of observations lost to attrition
* I first need to create a dummy variable capturing observations lost to missing observations
gen attrition_missing = 1 if sample == 0 & ev_attrition == 0 
	replace attrition_missing = 0 if sample == 1 & ev_attrition == 0
		label var attrition_missing "was observation lost to attrition due to missing observations"
collect clear
	* Let's define a local with all of the pre-treatment variables we're interested in:
	local pre_treatment urban_97 two_parent educ_mom ln_agg_expend_r_pc_97 birth_order tot_num_vis_97 general_health_97 
	local attrit_var ifls3_attrition ifls4_attrition ifls5_attrition attrition_missing sample
	foreach v in `pre_treatment' {
		foreach k in `attrit_var' {
			bysort `k': collect, tag(att[`v']): qui sum `v'
		}
	}
	foreach k in `attrit_var' {
		bysort `k': collect, tag(att[attrit_var]): qui sum `k'
	}
	
collect layout (att[`pre_treatment']#result[mean sd] att[attrit_var]#result[N]) (sample[1] attrition_missing[1] ifls3_attrition[1] ifls4_attrition[1] ifls5_attrition[1])
* Now let's clean the table
* First let's properly label our column headers:
collect label levels sample 1 "In Sample"
collect label levels ev_attrition 0 "Never Attrited"
collect label levels ifls5_attrition 1 "IFLS4 to IFLS5"
collect label levels ifls3_attrition 1 "IFLS2 to IFLS3" 
collect label levels ifls4_attrition 1 "IFLS3 to IFLS4"
collect label levels attrition_missing 1 "Missing Obs."
collect label levels att urban_97 "Urban" two_parent "Two-Parent Household" educ_mom "Mom's Years of Education" ln_agg_expend_r_pc_97 "Household Expenditure" birth_order "Birth Order" tot_num_vis_97 "Healthcare Visits" general_health_97 "General Health Status"
* Now let's properly format our summary statistics and hide their labels (as well as the label for attrit_var)
collect style cell result[mean sd], nformat(%7.2f) halign(center)
collect style cell result[N], halign(center)
collect style cell result[sd], sformat("(%s)")
collect style header result[mean sd] att[attrit_var], level(hide)
collect style tex, nobegintable
collect preview
	collect export "$output/attrition_table.tex", tableonly replace 





