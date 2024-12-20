/*
capture log close
log using 02c_in_schl_logit, replace text
*/

/*
  program:    	02c_in_schl_logit.do
  task:			To conduct logit fixed-effects analysis with in-school dummy variable as 
				my outcome variable, varying samples and plotting coefficients.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 16Jan2024
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
*******************************************************************************************Create sum_table variable *******************************************************************************************
cd $clean
	use master, clear
*******************************************************************************************Run full specifications, varying sample *******************************************************************************************
* Now let's create a single table for our fully-specified regression with more information:
collect clear
* Let's clear value labels for the annoying kinder and urban variables:
	label def kinder_ever 0 "No kinder" 1 "Kinder", replace
	label def urban 0 "Rural" 1 "Urban", replace
		label val kinder_ever kinder_ever
		label val urban_97 urban
* Re-define locals 
	local hh_control i.two_parent ln_agg_expend_r_pc i.electricity educ_mom num_children
	local indiv_control i.cohort i.male birth_order general_health_97 tot_num_vis_97
xtset mom_pidlink	
foreach n in 1 2 3 4 5 6 7 8 9 10 11 { 
	* Now let's run a regression with our full set of household and individual controls
qui xtlogit in_schl`n' i.kinder_ever `indiv_control',  fe
	collect, tag(year[`n']): qui margins, dydx(*)
		gen kinder_total`n' = r(b)[1,2]
qui xtlogit in_schl`n' i.kinder_ever `indiv_control' if urban_97 == 1, fe
	collect, tag(year[`n']): qui margins, dydx(*)
		gen kinder_urban`n' = r(b)[1,2]
qui xtlogit in_schl`n' i.kinder_ever `indiv_control' if urban_97 == 0, fe
	collect, tag(year[`n']): qui margins, dydx(*)
		gen kinder_rural`n' = r(b)[1,2]
}
*******************************************************************************************Create graph of fully-specified regression coefficients (w/o interaction) *******************************************************************************************
* Now let's try and graph these regression coefficients. Let's reshape each individually and then merge. 
	* Let's just keep the first observation for reshaping purposes.
		gen num_obs = _n 
			keep if num_obs == 1
				drop num_obs
* Let's reshape with a straightforward loop:
foreach n in kinder_total kinder_urban kinder_rural {
preserve 
	tempfile `n'
	keep pid97 `n'*
	reshape long `n', i(pid97) j(year)
		drop pid97
		save ``n''
restore
}
use `kinder_total', clear
	merge 1:1 year using `kinder_urban', nogen
	merge 1:1 year using `kinder_rural', nogen
line kinder_total kinder_urban kinder_rural year, xtitle("Grade in School") legend(label(1 "Total Sample") label(2 "Urban Sample") label(3 "Rural Sample") size(small)) ytitle("Marginal Effects of Kindergarten Attendance")
	graph export "$output/me_in_schl_sample.png", replace
	
