/*
capture log close
log using 03_pass_reg, replace text
*/

/*
  program:    	03_pass_reg
  task:			To conduct regression analysis with stay-on rates as my outcome variable.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 06Jan2024
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

*******************************************************************************************Run basic regression specifications *******************************************************************************************
cd $clean
use master, clear

	label def kinder_ever 0 "No kinder" 1 "Kinder"
	label def urban 0 "Rural" 1 "Urban"
		label val kinder_ever kinder_ever
		label val urban_97 urban
label var kinder_ever ""
* Let's begin by restricting our sample to no missing variables.
keep if sample == 1

collect clear
* Let's first create our local macros for the control variables, w/our 3 categories
local hh_control two_parent ln_agg_expend_r_pc electricity educ_mom num_children
local indiv_control i.cohort male birth_order general_health_97

* Let's begin with running a univariate regression for the stay-on rates for every year. We're just going to stick with years 1-15, as that captures primary/junior/senior/university. (we don't need to include the final year of university).
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 { 
	collect has_hh_controls="NO" has_indiv_controls="NO" has_mom_fe="NO", tag(year[`n']): qui reg pass`n' 1.kinder_ever 
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
		gen univariate`n' = e(b)[1,1]
			collect remap result = univariate
}
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 { 
	* Then let's run a regression with our full set of household controls
	collect has_hh_controls="YES" has_indiv_controls="NO" has_mom_fe="NO", tag(year[`n']): qui reg pass`n' urban_97##kinder_ever `hh_control'
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
		gen hh_control`n' = e(b)[1,4]
			collect remap result = hh_control
}
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 { 
	* Now let's run a regression with our full set of household and individual controls
collect has_hh_controls="YES" has_indiv_controls="YES" has_mom_fe="NO", tag(year[`n']): qui reg pass`n' urban_97##kinder_ever `hh_control' `indiv_control'
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
		gen hh_indiv_control`n' = e(b)[1,4]
			collect remap result = hh_indiv_control
}
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 { 
* Now let's run mother fixed effects. 
	* Note that for both of these specifications we're limiting our sample to mothers with more than one child, in order to generate real variation within families.
xtset mom_pidlink
		* First let's run a basic univariate regression.
	collect has_hh_controls="NO" has_indiv_controls="NO" has_mom_fe="YES", tag(year[`n']): qui xtreg pass`n' 1.kinder_ever, fe
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
		gen mom_fe`n' = e(b)[1,1]
			collect remap result = mom_fe 
}
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 { 
		* Now, let's add in our individual controls.
	collect has_hh_controls="NO" has_indiv_controls="YES" has_mom_fe="YES", tag(year[`n']): qui xtreg pass`n' 1.kinder_ever `indiv_control', fe
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
		gen indiv_fe`n' = e(b)[1,1]
			collect remap result = indiv_fe
}

collect layout (year) (colname[1.kinder_ever]#univariate[_r_b] colname[1.kinder_ever]#hh_control[_r_b] colname[1.kinder_ever]#hh_indiv_control[_r_b] colname[1.kinder_ever]#mom_fe[_r_b] colname[1.kinder_ever]#indiv_fe[_r_b])
			* Let's set locals to make labeling easier. 
				local univariate "No Ctrls" 
				local hh_control "HH Ctrls"
				local hh_indiv_control "HH and Indiv Ctrls"
				local mom_fe "Mother FE, No Ctrls"
				local indiv_fe "Mother FE, Indiv Ctrls"
				
		foreach k in univariate hh_control hh_indiv_control mom_fe indiv_fe {
			collect label levels `k' _r_b "``k''", modify
			collect style cell `k'[_r_b], nformat(%7.3f)
		}
		collect style header colname[1.kinder_ever], level(hide)
			collect style header colname, level(hide)
collect preview 
	collect title "Passing Regression Analysis"
		collect export "$output/pass_reg.tex", tableonly replace
	
* Now let's try and graph these regression coefficients. Let's reshape each individually and then merge. 
	* Let's just keep the first observation for reshaping purposes.
		gen num_obs = _n 
			keep if num_obs == 1
				drop num_obs
* Let's reshape with a straightforward loop:
foreach n in univariate hh_control hh_indiv_control mom_fe indiv_fe {
preserve 
	tempfile `n'
	keep pid97 `n'*
	reshape long `n', i(pid97) j(year)
		drop pid97
		save ``n''
restore
}
use `univariate', clear
	merge 1:1 year using `hh_control', nogen
	merge 1:1 year using `hh_indiv_control', nogen
	merge 1:1 year using `mom_fe',  nogen
	merge 1:1 year using `indiv_fe', nogen
* Our data for year 15 is too wonky, so we're going to remove it from our graph.
	drop if year == 15
line univariate hh_control hh_indiv_control mom_fe indiv_fe year, title("Kindergarten Effects on Passing Rates, By Year") legend(label(1 "No Controls, No FE") label(2 "HH Controls, No FE") label(3 "HH and Indiv Controls, No FE") label(4 "No Controls, Mom FE") label(5 "Indiv Controls, Mom FE")) xtitle("Grade in School")
	graph export "$output/pass_reg_line.png", replace





