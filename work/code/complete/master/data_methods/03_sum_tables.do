/*
capture log close
log using 03_sum_tables, replace text
*/

/*
  program:    	03_sum_tables
  task:			To create tables of summary statistics of my sample.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 27Dec2023
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
***************************************************************************************Create basic summary statistics table          ***************************************************************************************
cd $clean
	use master, clear
keep if sample == 1
local hh_control two_parent educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07  
local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14
local indiv_control cohort birth_order kinder_spillover tot_num_vis_97 general_health_97
local outcomes kinder_ever educ14 elem_completion junior_completion senior_completion
collect clear
foreach v in `outcomes' `hh_control' `comm_control' `indiv_control' {
	bysort kinder_ever urban_97: collect, tag(sum[`v']): qui sum `v'
	bysort sample: collect, tag(sum[`v']): qui sum `v'
}
bysort sample: collect, tag(sum[sample]): sum sample
bysort kinder_ever urban_97: collect, tag(sum[sample]): sum sample
collect layout (sum[`outcomes' `hh_control' `comm_control' `indiv_control']#result[mean sd] sum[sample]#result[N]) (sample[1] urban_97[1]#kinder_ever[1] urban_97[1]#kinder_ever[0] urban_97[0]#kinder_ever[1] urban_97[0]#kinder_ever[0])
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
	collect label levels sum two_parent "Two-parent HH" educ_mom "Mom's years of education" ln_agg_expend_r_pc_97 "HH per-capita expenditure (1997)" ln_agg_expend_r_pc_00 "HH per-capita expenditure (2000)" ln_agg_expend_r_pc_07 "HH per-capita expenditure (2007)" elem_per_10000_00 "Elementaries per 10,000 (2000)" junior_per_10000_07 "Junior highs per 10,000 (2007)" senior_per_10000_14 "Senior highs per 10,000 (2014)" cohort "Birth cohort" birth_order "Birth order to mother" kinder_spillover "Older sibling attended kinder" tot_num_vis_97 "Healthcare visits" general_health_97 "General health status (1997)" kinder_ever "Kindergarten" educ14 "Years of education (2014)" elem_completion "Completed elementary" junior_completion "Completed junior high" senior_completion "Completed senior high", replace
	collect style tex, nobegintable
	collect style column, dups(center)
collect preview
	collect export "$output/summary_table.tex", replace tableonly






