/*
capture log close
log using 02_sample_analysis, replace text
*/

/*
  program:    	02_sample_analysis.do
  task:			To create the outputs to be used in my sample analysis.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 14Sept2023
*/

version 17
clear all
set linesize 80
macro drop _all

**********************************************************************************Set Global Macros              **********************************************************************************

global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"

global code "~thesis_independent_study/work/code/to_do"

global word "$clean/desc_stat/word_format"
global latex "$clean/desc_stat/latex_format"
global graphs "$clean/desc_stat/graphs"

global output "~/thesis_independent_study/work/writing/rough_draft/output"

****************************************************************************************Rate of Attrition Tables ****************************************************************************************
cd $clean
use master, clear

tab wave

* We want to create a table comparing the household characteristics of the respondents that fell to attrition.

local household fridge television electricity ln_agg_expend_r_pc above_med educ_hh
local educ educ14 kinder_ever exit_age labor_force ln_earnings

collect clear

collect: table ifls5, stat(mean `household') stat(sd `household') stat(count `household')
	foreach v in colname result ifls5 {
		collect label drop `v'
	}
	collect layout (colname) (result#ifls5[0 1])
	collect style cell result[mean sd], nformat(%9.2f)
	collect preview
	collect export "$output/attrition_ifls2.tex", tableonly replace

* Next, let's create a table comparing the educational outcomes of the respondents that fell to attrition (going the other way)
	
	collect clear

collect: table ifls2, stat(mean `educ') stat(sd `educ') stat(count `educ')
	foreach v in colname result ifls2 {
		collect label drop `v'
	}
	collect layout (colname) (result#ifls2[0 1])
	collect style cell result[mean sd], nformat(%9.2f)
	collect preview
	collect export "$output/attrition_ifls5.tex", tableonly replace
	
* Let's run quick ttests on the education variable:
	ttest educ_hh, by(ifls5)
	ttest above_med, by(ifls5)
	
	ttest educ14, by(ifls2)
	ttest kinder_ever, by(ifls2)
	
e
	
****************************************************************************************Table1 - Summary statistics table for our core variables ****************************************************************************************
local varlist educ14 kinder_ever kinder_age exit_age educ_hh television ln_agg_expend_r_pc male urban_97 

collect clear
collect: table sample1, stat(mean `varlist') stat(sd `varlist') stat(count `varlist')

foreach v in colname sample1 {
	collect label drop `v'
}
collect label levels sample1 0 "Not in sample" 1 "In sample" .m "Total"

	collect layout (colname) (result#sample1[1 .m])
	collect style cell cell_type[item column-header], halign(center)
	collect style column, extraspace(3)
	collect title "Summary Statistics Sample Comparison"
	collect preview
	collect style tex, begintable
collect export "$output/sample_summary.tex", replace tableonly
	****************************************************************************************Table2 - Summary statistics table for our core variables, by kindergarten attendance           ****************************************************************************************

cd $clean
use master, clear

local varlist educ14 kinder_ever kinder_age exit_age educ_hh television ln_agg_expend_r_pc male urban_97

collect clear 
collect: table kinder_ever, stat(mean `varlist') stat(sd `varlist') stat(count `varlist')

foreach v in colname kinder_ever {
	collect label drop `v'
}

collect label levels kinder_ever 0 "No kindergarten" 1 "Kindergarten"

collect layout (colname) (kinder_ever[1 0]#result[mean sd count])
collect style cell cell_type[item column-header], halign(center)
collect style column, extraspace(3)
collect title "Summary Statistics by Kindergarten Attendance"
collect preview
collect style tex, begintable
collect preview

collect export "$output/sample_summary(2).tex", replace tableonly

**********************************************************************************Table3 - Basic correlation table     **********************************************************************************

collect clear
collect: pwcorr `varlist'
collect layout (rowname) (colname[educ14 kinder_ever kinder_age exit_age]#result[C])

foreach v in colname rowname result {
	collect label drop `v'
}

collect style cell cell_type[item column-header], halign(center)
collect style column, extraspace(3)
collect title "Pair-Wise Correlations"
collect preview
collect style tex, begintable
collect preview

collect export "$output/correlations.tex", replace tableonly

**********************************************************************************Graphs - Basic Descriptive Graphs          **********************************************************************************

cd $output

local 	educ14 					Years of Education
local 	educ_hh 				Household Head Education
local	ln_agg_expend_r_pc		Household Expenditure
local	television				Household Television (Dummy)

foreach k in educ14 {
	
	binscatter kinder_ever `k', title("Kindergarten Attendance" "and ``k''") reportreg xtitle(Kindergarten Attendance) ytitle(``k'')
	graph export kinder_ever_educ14.png, as(png) replace
	
	foreach v in educ_hh ln_agg_expend_r_pc television {
	
		binscatter `v' `k', by(kinder_ever) title("``k''" "and ``v''") legend(label(1 "No Kinder") label(2 "Kinder")) ytitle(``v'') xtitle(``k'') reportreg
		graph export `v'_`k'.png, as(png) replace
	
	}
}	

**********************************************************************************Graphs over time - stayon, pass, and ln_ek scores over time         **********************************************************************************

preserve
	drop if kinder_ever == . | kinder_ever == .d
	keep stayon* kinder_ever pidlink
	reshape long stayon, i(pidlink kinder_ever) j(year)
	gen stayon_total = stayon
	reshape wide stayon, i(pidlink year) j(kinder_ever)
	drop stayon0
	graph bar (mean) stayon_total stayon1, over(year) legend(label(1 "No kindergarten") label(2 "Kindergarten")) title("Stay on rates, by year") yscale(r(0 1))
	graph export "$output/stayon_sample.png", replace
restore


preserve
	drop if kinder_ever == . | kinder_ever == .d
	keep pass* kinder_ever pidlink
	reshape long pass, i(pidlink kinder_ever) j(year)
	gen pass_total = pass
	reshape wide pass, i(pidlink year pass_total) j(kinder_ever)
	drop pass0
	graph bar (mean) pass_total pass1, over(year) legend(label(1 "No kindergarten") label(2 "Kindergarten")) title("Pass rates, by year") yscale(r(0 1))
	graph export "$output/pass_sample.png", replace
restore


preserve
	drop if kinder_ever == . | kinder_ever == .d
	keep ln_total_ek* kinder_ever pidlink
	rename (ln_total_ek00 ln_total_ek07 ln_total_ek14) (ln_total_ek2000 ln_total_ek2007 ln_total_ek2014)
	reshape long ln_total_ek, i(pidlink kinder_ever) j(year)
	gen ln_total_ek_total = ln_total_ek
	reshape wide ln_total_ek, i(pidlink year ln_total_ek_total) j(kinder_ever)
	drop ln_total_ek0
	graph bar ln_total_ek_total ln_total_ek1, over(year) legend(label(1 "No kindergarten") label(2 "Kindergarten")) title("Average ln(EK) scores")
	graph export "$output/ek_sample.png", replace
restore

preserve
	drop if kinder_ever == . | kinder_ever == .d
	keep in_schl* kinder_ever pidlink
	reshape long in_schl, i(pidlink kinder_ever) j(year)
	gen in_schl_total = in_schl
	reshape wide in_schl, i(pidlink year in_schl_total) j(kinder_ever)
	drop in_schl0
	graph bar in_schl_total in_schl1, over(year) legend(label(1 "No kindergarten") label(2 "Kindergarten")) title("In School Dummy")
	graph export "$output/in_school.png", replace
restore

**********************************************************************************Distributions of sample over urban, cohort, province, and sex       **********************************************************************************

cd $clean
use master, clear

	preserve
	drop if prov_97 == .m | kinder_ever == . | kinder_ever == .d | urban_97 == . | urban_97 == .m | _cohort == .
collect clear
collect: bysort prov_97 urban_97 _cohort: quietly sum kinder_ever
collect label levels urban_97 0 "not urban" 1 "urban"
* collect label levels result mean "kindergarten attendance rates", modify
collect layout (prov_97#urban_97) (result[mean]#_cohort)
collect title "Kindergarten attendance rates, by province and urban status"
collect preview
collect export "$output/kinder_prov_urban.tex", replace tableonly
collect layout (prov_97#urban_97) (result[N]#_cohort)
collect label drop result
collect title "Number of observations for kindergarten attendance, by province and urban status"
collect preview
collect export "$output/kinder_prov_urban(1).tex", replace tableonly
	restore

collect clear
	preserve
	drop if prov_97 == .m
	drop if _cohort == .
	drop if kinder_ever == . | kinder_ever == .d
collect: bysort prov_97 _cohort above_med: quietly sum kinder_ever
* collect label levels result mean "kindergarten attendance rates", modify
collect layout (prov_97#above_med) (result[mean]#_cohort)
collect title "Kindergarten attendance rates, by age cohort"
collect preview
collect export "$output/kinder_cohort.tex", replace tableonly
collect layout (prov_97#above_med) (result[N]#_cohort)
collect title "Number of observations, by age cohort"
collect label drop result
collect preview
collect export "$output/kinder_cohort(1).tex", replace tableonly
	restore

collect clear
	preserve
	drop if _cohort == .
	drop if kinder_ever == . | kinder_ever == .d
	drop if male == . | male == .m
collect: bysort _cohort male: quietly sum kinder_ever
collect label levels kinder_ever 0 "no kindergarten" 1 "kindergarten", modify
collect label levels result mean "% male", modify
collect layout (male) (result[mean]#_cohort)
collect title "Percent male, by age cohort and kindergarten attendance"
collect preview

collect export "$output/sex_cohort.tex", replace tableonly
	restore

**********************************************************************************Creating OLS regression table **********************************************************************************

* In order to run our household fixed regression, we have to prepare for declaring our data as a panel; we're borrowing time series methods here. Our 'time variable', which is really our household identifier, can't be a string; thus, we will destring our household id variable.

destring hhid14_9, gen(hhid14_9_num)

* We are going to prepare our regression table, which will be crafted using the esttab series of commands. We are interested in three specifications: 1) a basic, non-household fixed effects univariate model, 2) a 'complete' non-household fixed effects model, and 3) a household fixed effects model. 
eststo clear

eststo: reg educ14 kinder_ever, vce(robust)
eststo: reg educ14 kinder_ever educ_hh ln_agg_expend_r_pc television urban_97 male cohort2 cohort3 cohort4 cohort5, vce(robust)
xtset hhid14_9_num
eststo: xtreg educ14 kinder_ever male cohort2 cohort3 cohort4 cohort5, vce(cluster kec_97)

esttab using "$output/proposal_regression.tex", se ar2 title("Preliminary regression findings, robust standard errors") replace






