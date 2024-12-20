/*
capture log close
log using 02b_in_schl_probit, replace text
*/

/*
  program:    	02b_in_schl_probit
  task:			To conduct probit regression analysis with in-school dummy variable as my 
				outcome variable.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 13Jan2024
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
*******************************************************************************************Run basic probit specifications *******************************************************************************************
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
local indiv_control i.cohort male birth_order general_health_97 tot_num_vis_97
local comm_control elem_per_person junior_per_person senior_per_person
* Let's begin with running a univariate regression for the stay-on rates for every year. We're just going to stick with years 1-15, as that captures primary/junior/senior/university. (we don't need to include the final year of university).
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 { 
	collect has_hh_controls="NO" has_comm_controls = "NO" has_indiv_controls="NO" has_mom_fe="NO", tag(year[`n']): qui probit in_schl`n' 1.kinder_ever [pw=attwght], vce(cluster kec_97)
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
		gen univariate`n' = e(b)[1,1]
			collect remap result = univariate
}
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 { 
	* Then let's run a regression with our full set of household controls
	collect has_hh_controls="YES" has_comm_controls = "YES" has_indiv_controls="NO" has_mom_fe="NO", tag(year[`n']): qui probit in_schl`n' urban_97##kinder_ever `hh_control' `comm_control' [pw=attwght], vce(cluster kec_97)
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
		gen hh_control`n' = e(b)[1,4]
			collect remap result = hh_control
}
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 { 
	* Now let's run a regression with our full set of household and individual controls
collect has_hh_controls="YES" has_comm_controls = "YES" has_indiv_controls="YES" has_mom_fe="NO", tag(year[`n']): qui probit in_schl`n' urban_97##kinder_ever `hh_control' `indiv_control' `comm_control' [pw=attwght], vce(cluster kec_97)
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
		gen hh_indiv_control`n' = e(b)[1,4]
			collect remap result = hh_indiv_control
}
collect layout (year) (colname[1.kinder_ever]#univariate[_r_b] colname[1.kinder_ever]#hh_control[_r_b] colname[1.kinder_ever]#hh_indiv_control[_r_b])
			* Let's set locals to make labeling easier. 
				local univariate "No Ctrls" 
				local hh_control "HH/Comm Ctrls"
				local hh_indiv_control "HH/Comm/Indiv Ctrls"
				local mom_fe "Mother FE, No Ctrls"
				local indiv_fe "Mother FE, Indiv Ctrls"
		foreach k in univariate hh_control hh_indiv_control mom_fe indiv_fe {
			collect label levels `k' _r_b "``k''", modify
			collect style cell `k'[_r_b], nformat(%7.3f)
		}
		collect style header colname[1.kinder_ever], level(hide)
			collect style header colname, level(hide)
				collect title "In-School Probit Analysis"
collect preview 
		collect export "$output/in_schl_probit.tex", tableonly replace
* Before proceeding, let's do a quick check of the number of observations to make sure they're constant: 
	collect layout (year) (univariate[N] hh_control[N] hh_indiv_control[N])
		* They are all equivalent!
*******************************************************************************************Create graph of probit coefficients *******************************************************************************************
* Now let's try and graph these regression coefficients. Let's reshape each individually and then merge. 
	* Let's just keep the first observation for reshaping purposes.
		gen num_obs = _n 
			keep if num_obs == 1
				drop num_obs
* Let's reshape with a straightforward loop:
foreach n in univariate hh_control hh_indiv_control {
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
	* merge 1:1 year using `mom_fe',  nogen
	* merge 1:1 year using `indiv_fe', nogen
* Our data for year 15 is too wonky, so we're going to remove it from our graph.
	drop if year == 15
line univariate hh_control hh_indiv_control year, title("Kindergarten Effects on In-School Status," "By Grade (Probit model)") legend(label(1 "No Controls, No FE") label(2 "HH/Comm Controls, No FE") label(3 "HH/Comm/Indiv Controls, No FE") label(4 "No Controls, Mom FE") label(5 "Indiv Controls, Mom FE")) xtitle("Grade in School") ytitle("Probit Coefficient") nodraw
	* graph export "$output/in_schl_probit_line.png", replace
*******************************************************************************************Create single table with full specification (w/o interaction) *******************************************************************************************
cd $clean
	use master, clear
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
foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 { 
	* Now let's run a regression with our full set of household and individual controls
qui probit in_schl`n' i.kinder_ever i.urban_97 `hh_control' `indiv_control' `comm_control' [pw=attwght], vce(cluster kec_97)
	/*
	collect stars _r_p 0.01 "***" 0.05 "** " 0.1 "* " 1 " ", attach(_r_b) shownote
	gen kinder_b`n' = e(b)[1,1]
	gen urban_b`n' = e(b)[1,2]
	gen educ_mom_b`n' = e(b)[1,6]
	gen tot_num_b`n' = e(b)[1,16]
	*/
	collect, tag(year[`n']): qui margins, dydx(*)
		gen kinder_b`n' = r(b)[1,2]
		gen urban_b`n' = r(b)[1,4]
		gen educ_mom_b`n' = r(b)[1,10]
		gen tot_num_b`n' = r(b)[1,21]
}
collect layout (year[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]#result[_r_b _r_se]) (colname[1.kinder_ever 1.urban_97 educ_mom tot_num_vis_97])
	collect label drop colname
collect label levels colname educ14 "Years of education" 1.kinder_ever "Kinder" exit_age "Exit age from school" labor_force "Labor force participation" ln_earnings "Earnings (ln)" fridge "HH has a fridge" television "HH has a television" electricity "HH has electricity" educ_mom "Mother's Education" ln_agg_expend_r_pc "HH expenditure per capita (ln)" educ_hh "HH Head Education" tot_num_vis_97 "Outpatient Care Visits (1997)" general_health_97 "General Health Status (1997)" 1.urban_97 "Urban", replace
	collect style cell result[_r_b], nformat(%7.2f) halign(center)
	collect style cell result[_r_se], nformat(%7.2f) halign(center) sformat("(%s)")
	collect style header result[_r_b _r_se], level(hide)
	collect style column, delimiter(" x ") extraspace(1)
	collect style cell border_block, border(right, pattern(nil))
	collect preview
		collect export "$output/in_schl_probit_no_interaction.tex", replace tableonly
*******************************************************************************************Create graph of fully-specified regression coefficients (w/o interaction) *******************************************************************************************
* Now let's try and graph these regression coefficients. Let's reshape each individually and then merge. 
	* Let's just keep the first observation for reshaping purposes.
		gen num_obs = _n 
			keep if num_obs == 1
				drop num_obs
* Let's reshape with a straightforward loop:
foreach n in kinder_b urban_b educ_mom_b tot_num_b {
preserve 
	tempfile `n'
	keep pid97 `n'*
	reshape long `n', i(pid97) j(year)
		drop pid97
		save ``n''
restore
}
use `kinder_b', clear
	merge 1:1 year using `urban_b', nogen
	merge 1:1 year using `educ_mom_b', nogen
	merge 1:1 year using `tot_num_b', nogen
line kinder_b urban_b educ_mom_b year, xtitle("Grade in School") ytitle("Probit Coefficient") title("Variables' Effect on In-School Status," "By Grade (Probit Specification)") legend(label(1 "Kinder") label(2 "Urban (1997)") label(3 "Mom's Education (1997)") label(4 "Healthcare Visits (1997)"))
	graph export "$output/in_schl_probit_no_interaction_line.png", replace
