/*
capture log close
log using 05_hh_var, replace text
*/

/*
  program:    	05_hh_var
  task:			To summarize and characterize variation within household/between siblings 
				of the same mother to diagnose/contextualize fixed-effects findings.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 16Jan2024
*/

version 17
clear all
set linesize 80
macro drop _all

***************************************************************************************
* Set Global Macros              ***************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~thesis_independent_study/work/code/complete"
		global output "~/thesis_independent_study/work/writing/rough_draft/analysis"
***************************************************************************************
* Generate sum_table ***************************************************************************************
cd $clean
	use master, clear
gen sum_table = 0 
	label var sum_table "variable used to analyze fixed-effects sample"
	replace sum_table = 1 if switch == 1 
	replace sum_table = 2 if tot_kinder == 0
	replace sum_table = 3 if sd_kinder == 0 & tot_kinder != 0
	replace sum_table = 4 if num_children == 1
tab sum_table, m 
***************************************************************************************
* Graphs   
***************************************************************************************
* All of these graphs are going to be on the level of the MOTHER, so we're going to collapse on mom_pidlink first (taking the means since the variables we're employing are constant throughout mom_pidlink anyways):
local varlist sd_kinder sd_educ14 switch educ14 kinder_ever general_health_97 tot_num_vis_97 educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 two_parent sd_elem_completion sd_junior_completion sd_senior_completion sum_table mean_educ14
collapse (mean) `varlist' num_children, by(prov_97 mom_pidlink)
* Let's begin with a basic histogram of num_children (essentially, household size) for those INCLUDED in the switching sample:
tw (hist num_children if switch == 1, width(1) percent fcolor(green) lcolor(black)) (hist num_children, width(1) percent fcolor(white) lcolor(black)), legend(labe(1 "Switching Sample") label(2 "Total Sample") size(small)) xtitle("Number of Children of Mother")
	graph export "$output/hist_switching.png", replace
* Now let's do our scatterplot comparing standard deviation to standard deviation:
tw (scatter sd_educ14 sd_kinder [w=num_children] if switch==0, msymbol(oh) mcolor(blue)) (scatter sd_educ14 sd_kinder [w=num_children] if switch==1, msymbol(oh) mcolor(red)), legend(label(1 "Non-Switching Family") label(2 "Switching Family") size(small)) ytitle("Standard Deviation of Years of Education") xtitle("Standard Deviation of Kindergarten Attendance") graphregion(color(white)) title("Non-Switching vs. Switching Families") saving(switch_sd, replace)
preserve 
	collapse (mean) `varlist' (sum) num_children, by(prov_97)
	scatter sd_educ14 sd_kinder [w=num_children], msymbol(oh) xtitle("Standard Deviation of Kindergarten Attendance") ytitle("Standard Deviation of Years of Education") title("Provinces (1997)") saving(prov_sd, replace) graphregion(color(white))
restore
graph combine switch_sd.gph prov_sd.gph, graphregion(color(white))
	graph export "$output/scatter_switching.png", replace
* next, let's make a scatterplot comparing standard deviation to mean:
tw (scatter mean_educ14 educ_mom [w=num_children] if switch==0, msymbol(oh) mcolor(blue)) (scatter mean_educ14 educ_mom [w=num_children] if switch==1, msymbol(oh) mcolor(red)), legend(label(1 "Non-Switching Family") label(2 "Switching Family") size(small)) ytitle("Standard Deviation of Years of Education") xtitle("Mean of Mom's Years of Education")
	graph export "$output/scatter_switching_means.png", replace
****************************************************************************************
* Summary Statistics Table ***************************************************************************************
* We're just going to summarize our variables of interest by sum_table
local varlist educ14 kinder_ever num_children general_health_97 tot_num_vis_97 educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 two_parent
		collect clear
foreach v in `varlist' {
	collect, tag(var[`v']): qui sum `v' if sum_table == 1
		collect remap result = switch
	collect, tag(var[`v']): qui sum `v' if sum_table == 2
		collect remap result = no_kinder
	collect, tag(var[`v']): qui sum `v' if sum_table == 3
		collect remap result = all_kinder
	collect, tag(var[`v']): qui sum `v' if sum_table == 4
		collect remap result = one_child
}
collect layout (var) (switch[mean sd] no_kinder[mean sd] all_kinder[mean sd] one_child[mean sd])
collect layout (var) (switch[mean] no_kinder[mean] all_kinder[mean] one_child[mean])
	collect label levels switch mean "Switching Sample" sd ""
	collect label levels no_kinder mean "No Kindergarten" sd ""
	collect label levels all_kinder mean "All Kinder" sd ""
	collect label levels one_child mean "One-Child Sample" sd ""
	foreach k in switch no_kinder all_kinder one_child {
		collect style cell `k'[mean], nformat(%7.2f) halign(center)
		collect style cell `k'[sd], nformat(%7.2f) sformat("(%s)") halign(center)
		collect style header `k'[sd], level(hide)
	}
	collect label levels var educ14 "Years of education" kinder_ever "Attended kindergarten" exit_age "Exit age from school" labor_force "Labor force participation" ln_earnings "Earnings (ln)" fridge "HH has a fridge" television "HH has a television" electricity "HH has electricity" educ_mom "Mom's years of education" ln_agg_expend_r_pc_97 "HH expenditure per capita (1997)" ln_agg_expend_r_pc_00 "HH expenditure per capita (2000)" ln_agg_expend_r_pc_07 "HH expenditure per capita (2007)" educ_hh "HH Head Education" tot_num_vis_97 "Visits to outpatient care (1997)" general_health_97 "General health status (1997)" two_parent "Two-parent HH" num_children "Number of children", replace
collect preview
collect style tex, nobegintable
	collect export "$output/switching_statistics.tex", replace tableonly
***************************************************************************************
* Quick Logit Examination ***************************************************************************************
collect clear
cd $clean
use master, clear
	keep if sample == 1
local hh_control two_parent educ_hh educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 urban_97 urban_00 urban_07 num_children
local indiv_control i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male
local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14 i.prov_97
local instrument kec_popkinder00 kec_popkinder90 

	logit switch kinder_ever `hh_control' `indiv_control' `comm_control' `instrument'
	margins, dydx(*)
		test educ_hh educ_mom urban_97 urban_00 urban_07 kec_popkinder90 kec_popkinder00

/*
log close
exit
*/
