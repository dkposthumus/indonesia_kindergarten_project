/*
capture log close
log using 91_desc_stats, replace text
*/

/*
  program:    	91_desc_stats.do
  task:			to create a series of graphs and descriptive statistics tables related to key variables of interest, only using the master dataset ifls5_exploratory_work.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 26July2023
*/

version 17
clear all
set linesize 80
macro drop _all


********************************************************************************Set Global Macros              ********************************************************************************

global raw "/Users/danielposthumus/thesis_independent_study/work/data_raw"
global ifls2_hh "$raw/ifls2_hh"
global ifls3_hh "$raw/ifls3_hh"
global ifls4_hh "$raw/ifls4_hh"
global ifls5_hh "$raw/ifls5_hh"
global desc_stats "/Users/danielposthumus/thesis_independent_study/work/desc_stats"

global desc_stats_code "/Users/danielposthumus/thesis_independent_study/work/code/to_do/desc_stats"
global desc_stats_graph "/Users/danielposthumus/thesis_independent_study/work/desc_stats/graphs"

********************************************************************************We can create our first descriptive statistics tables and graphs ********************************************************************************

cd "$desc_stats"
use ifls5_exploratory_work, clear

cd "$desc_stats_graph"

foreach m in kinder_ever educ educ_hh television {
	
	sum `m', detail
	graph bar (percent),  over(`m', label(angle(45))) title(`"`:var label `m''"')
	graph export `m'.png, as(png) replace
	
}

/*
foreach l in total_ebtanas_elem total_uan_un_elem {
	
	hist `l', percent title(`"`:var label `l''"')
	graph export `l'.png, as(png) replace
	
}
*/

foreach k in educ {
	
	foreach v in kinder_ever educ_hh ln_agg_expend_r television {
	
		binscatter `v' `k', title(`"`:var label `v''"' "vs." `"`:var label     `k''"')
		graph export `v'_`k'.png, as(png) replace
	
	}
		
}

* Create regression tables
cd "$desc_stats"
use ifls5_exploratory_work, clear

eststo clear
eststo: quietly regress educ kinder_ever
eststo: quietly regress educ kinder_ever educ_hh
eststo: quietly regress educ kinder_ever educ_hh ln_agg_expend_r_pc
eststo: quietly regress educ kinder_ever educ_hh ln_agg_expend_r_pc television
eststo: quietly regress educ kinder_ever educ_hh ln_agg_expend_r_pc television urban male
eststo: quietly regress educ educ_hh ln_agg_expend_r_pc television urban
eststo: quietly regress educ educ_hh ln_agg_expend_r_pc television

esttab using "$desc_stats_graph/exploratory_regression_educ.rtf", se ar2 varwidth (7) modelwidth(4) replace

eststo clear
eststo: quietly regress total_ek00 kinder_ever
eststo: quietly regress total_ek00 kinder_ever educ_hh
eststo: quietly regress total_ek00 kinder_ever educ_hh ln_agg_expend_r_pc
eststo: quietly regress total_ek00 kinder_ever educ_hh ln_agg_expend_r_pc television
eststo: quietly regress total_ek00 kinder_ever educ_hh ln_agg_expend_r_pc television urban
eststo: quietly regress total_ek00 educ_hh ln_agg_expend_r_pc television urban
eststo: quietly regress total_ek00 educ_hh ln_agg_expend_r_pc television
esttab using "$desc_stats_graph/exploratory_regression_total_score00.rtf", se ar2 varwidth (7) modelwidth(4) replace

eststo clear
eststo: quietly regress kinder_ever educ_hh ln_agg_expend_r_pc television urban
eststo: quietly regress kinder_ever educ_hh
eststo: quietly regress kinder_ever ln_agg_expend_r_pc 
eststo: quietly regress kinder_ever television
eststo: quietly regress kinder_ever urban
esttab using "$desc_stats_graph/exploratory_regression_kinder.rtf", se ar2 varwidth(7) modelwidth(7) replace


* Fixed Effects Regression

destring hhid14_9, gen(hhid14_9_num)

local min 17
local max 32

keep if inrange(age,`min',`max')

gen cohort = 4 if inrange(age,`min',`min'+3)
replace cohort = 3 if inrange(age,`min'+4,`min'+7)
replace cohort = 2 if inrange(age,`max'-7,`max'-4)
replace cohort = 1 if inrange(age,`max'-3,`max')

xtset hhid14_9_num
xtreg educ kinder_ever male age_14, fe vce(robust)
xtreg std_total_ek00 kinder_ever male cohort, fe vce(robust)
xtreg std_total_ek07 kinder_ever male cohort, fe vce(robust)
xtreg std_total_ek14 kinder_ever male cohort, fe vce(robust)

* cognitive skills over time
graph bar (mean) std_total_ek00 std_total_ek07 std_total_ek14, over(kinder_ever)



/*
log close
exit
*/









