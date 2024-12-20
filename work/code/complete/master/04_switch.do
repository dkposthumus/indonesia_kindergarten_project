/*
capture log close
log using 04_switch, replace text
*/

/*
  program:    	04_switch
  task:			To summarize and characterize variation within household/between siblings 
				of the same mother to diagnose/contextualize fixed-effects findings.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
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
* Create variables for fixed-effects analysis ***************************************************************************************
cd $clean
	use master, clear
	tempfile base 
			save `base'
		keep if sample == 1
* Our fixed-effects estimation use only the portion of the sample that consists of 'switching' households, or those households that have variation in our explanatory variable, kindergarten attendance. Let's begin by constructing a dummy variable capturing which households are 'switchers'.
gen switch = . 
	label var switch "does hh have variation among children in kinder attendance"
* Our strategy is to capture the standard deviation of kinder_ever.
bysort mom_pidlink: egen sd_kinder = sd(kinder_ever) if kinder_ever != .
	label var sd_kinder "sd of kinder_ever within mother unit"
/*
	Now let's use this variable to code our switch variable. This is going to take a 
	little leg-work, w/the following requirements:
		- switching households must have num_children > 1 (> 1 children)
		- switching households must have a standard deviation in kinder_ever != 0, since 
		a standard deviation of 0 will indicate a lack of variation in kinder_ever.
*/
replace switch = 1 if num_children > 1 & sd_kinder != 0 & sd_kinder != .
	replace switch = 0 if sd_kinder == 0 & sample == 1 | sd_kinder == . & sample == 1
		replace switch = .m if sample != 1
* Now we have to take the standard deviation of years of education by mom_pidlink as well:
bysort mom_pidlink: egen sd_educ14 = sd(educ14) if educ14 != .
	label var sd_educ14 "sd of years of education within mother unit"
* Finally, let's take the standard deviation of the completion dummy variables:
foreach v in elem_completion junior_completion senior_completion {
	bysort mom_pidlink: egen sd_`v' = sd(`v')
		label var sd_`v' "sd of `v'"
}
* Let's also create means of a series of individual-level variables (for the purposes of our summary statistics table, which we're going to construct later):
foreach v in educ14 kinder_ever general_health_97 tot_num_vis_97 {
	bysort `v': egen mean_`v' = mean(`v')
}	
		keep pidlink switch sd_* mean_*
	merge 1:m pidlink using `base', nogen
***************************************************************************************
* Finishing Up 
***************************************************************************************
	local tag 04_switch.do
foreach v in switch sd_kinder sd_educ14 sd_elem_completion sd_junior_completion sd_senior_completion mean_kinder_ever mean_general_health_97 mean_tot_num_vis_97 {
	notes `v': `tag'
}
	compress
cd "$clean"
save master, replace

/*
log close
exit
*/
