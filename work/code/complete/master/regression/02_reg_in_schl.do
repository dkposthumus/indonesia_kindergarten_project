/*
capture log close
log using 02_in_schl_reg, replace text
*/

/*
  program:    	02_in_schl_reg
  task:			To conduct regression analysis with in-school dummy variable as my 
				outcome variable.
  
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
	global code "~thesis_independent_study/work/code/to_do"
	global output "~/thesis_independent_study/work/writing/rough_draft/analysis"
**************************************************************************************Run basic regression specifications **************************************************************************************
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
local hh_control urban_97 two_parent educ_hh educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 num_children
local indiv_control i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male
local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14  i.prov_97
local instrument kec_popkinder00 kec_popkinder90
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 { 
	* Now let's run a regression with our full set of household, individual, and community controls:
collect has_hh_controls="YES" has_indiv_controls="YES" has_mom_fe="NO", tag(year[`n']): qui reg in_schl`n' urban_97##kinder_ever `hh_control' `indiv_control' `instrument', vce(robust)
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
		gen full_control`n' = e(b)[1,4]
		gen full_control_se`n' = _se[1.kinder_ever]
			collect remap result = full_control
}
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 { 
* Now let's run mother fixed effects. 
	* Note that for both of these specifications we're limiting our sample to mothers with more than one child, in order to generate real variation within families.
xtset mom_pidlink
		* First let's run a basic univariate regression.
	collect has_hh_controls="NO" has_indiv_controls="NO" has_mom_fe="YES", tag(year[`n']): qui xtreg in_schl`n' 1.kinder_ever `indiv_control' if switch == 1, fe vce(robust)
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
		gen mom_fe`n' = e(b)[1,1]
		gen mom_fe_se`n' = _se[1.kinder_ever]
			collect remap result = mom_fe 
}

collect layout (year#mom_fe[_r_b _r_se]) (colname[1.kinder_ever 4.general_health_97 male birth_order kinder_spillover])
	collect style cell mom_fe[_r_b _r_se], nformat(%7.2f)
	collect style cell mom_fe[_r_se], sformat("(%s)")
	collect style header mom_fe, level(hide)
	collect label levels colname 1.kinder_ever "Kinder" 4.general_health_97 "Very healthy" male "Male" birth_order "Birth order" kinder_spillover "Kinder spillover", replace
	collect style tex, nobegintable
		collect preview 
			collect export "$output/in_schl_fe.tex", tableonly replace
* now let's construct the same table, but for the fully-specified OLS model:
collect layout (year#full_control[_r_b _r_se]) (colname[1.kinder_ever 4.general_health_97 male birth_order kinder_spillover])
	collect style cell full_control[_r_b _r_se], nformat(%7.2f)
	collect style cell full_control[_r_se], sformat("(%s)")
	collect style header full_control, level(hide)
	collect label levels colname 1.kinder_ever "Kinder" 4.general_health_97 "Very healthy" male "Male" birth_order "Birth order" kinder_spillover "Kinder spillover", replace
	collect style tex, nobegintable
		collect preview 
			collect export "$output/in_schl_ols.tex", tableonly replace
* now let's add two sets of coefficients: fully specified LOGIT and fixed-effects LOGIT margins
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 { 
	qui xtlogit in_schl`n' 1.kinder_ever `indiv_control', fe
		qui margins, dydx(*)
			gen logit_fe`n' = r(b)[1,1]
	qui logit in_schl`n' 1.kinder_ever `indiv_control' `hh_control' `comm_control' `instrument'
		qui margins, dydx(*)
			gen logit_full`n' = r(b)[1,1]
}
* now let's run our ivregress specification
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 { 
	ivregress gmm in_schl`n' `hh_control' `indiv_control' `comm_control' (kinder_ever = `instrument'), wmatrix(robust)
	gen iv_full`n' = e(b)[1,1]
	gen iv_full_se`n' = _se[kinder_ever]
}

	* Let's just keep the first observation for reshaping purposes.
		gen num_obs = _n 
			keep if num_obs == 1
				drop num_obs	
* Let's reshape with a straightforward loop:
foreach n in full_control mom_fe logit_fe logit_full iv_full {
preserve 
	tempfile `n'
	keep pid97 `n'*
	reshape long `n' `n'_se, i(pid97) j(year)
		gen `n'_low = `n'-(1.96*`n'_se)
		gen `n'_high = `n'+(1.96*`n'_se)
		drop pid97
		save ``n''
restore
}
use `full_control', clear
	merge 1:1 year using `mom_fe',  nogen
	merge 1:1 year using `logit_fe',  nogen
	merge 1:1 year using `logit_full',  nogen
	merge 1:1 year using `iv_full', nogen
* Our data for year 15 is too wonky, so we're going to remove it from our graph.
	drop if year == 15
tw (line full_control year, lcolor(blue)) (rcap full_control_low full_control_high year, lcolor(blue)) (line mom_fe year, lcolor(red)) (rcap mom_fe_low mom_fe_high year, lcolor(red)) (line iv_full year, lcolor(green)) (rcap iv_full_low iv_full_high year, lcolor(green)), ytitle("Marginal Effects") xtitle("Grade in School") legend(order(1 3 5) label(1 "OLS, Full Control") label(3 "Mother Fixed-Effects") label(5 "IV Estimation") size(*0.75) rows(3)) graphregion(color(white)) bgcolor(white) saving("$output/in_schl_reg", replace)
		graph export "$output/in_schl_reg_bas.png", replace
		cd $output 
		graph combine in_schl.gph in_schl_reg.gph, graphregion(color(white))
	graph export "$output/in_schl_reg_line.png", replace
