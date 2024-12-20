/*
capture log close
log using 02_sample_tables, replace text
*/

/*
  program:    	02_sample_tables.do
  task:			To create a variety of tables demonstrating variable variation.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 14Aug2023
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

**********************************************************************************Table1 - Summary statistics table for our core variables, by sample restrictions            **********************************************************************************

cd $clean
use master, clear

/*
eststo: estpost tabstat educ14 kinder_ever kinder_age ln_total_ek00 ln_total_ek07 ln_total_ek14 exit_age evfail_elem evfail_junior evfail_senior evschl_hh television ln_agg_expend_r_pc male urban_97, by(sample2) stat(N mean sd) col(stat)
esttab using "$word/sample_summary.rtf", cells("count mean sd") replace
esttab using "$latex/sample_summary.tex", cells("count mean sd") replace
*/

collect clear 
collect create sample_sum_table

foreach v in educ14 kinder_ever kinder_age ln_total_ek00 ln_total_ek07 ln_total_ek14 exit_age evfail_elem evfail_junior evfail_senior evschl_hh television ln_agg_expend_r_pc male urban_97 {
	
	collect: sum `v' if sample1 == 1
	collect: sum `v' if sample2 == 1 
	local `v' "`v'"
	local `v'_ ":    `v' (restricted sample)"
	
}

collect label levels cmdset 1 "`educ14'" 2 "`educ14_'" 3 "`kinder_ever'" 4 "`kinder_ever_'" 5 "`kinder_age'" 6 "`kinder_age_'" 7 "`ln_total_ek00'" 8 "`ln_total_ek00_'" 9 "`ln_total_ek07'" 10 "`ln_total_ek07_'" 11 "`ln_total_ek14'" 12 "`ln_total_ek14_'" 13 "`exit_age'" 14 "`exit_age_'" 15 "`evfail_elem'" 16 "`evfail_elem_'" 17 "`evfail_junior'" 18 "`evfail_junior_'" 19 "`evfail_senior'" 20 "`evfail_senior_'" 21 "`evschl_hh'" 22 "`evschl_hh_'" 23 "`television'" 24 "`television_'" 25 "`ln_agg_expend_r_pc'" 26 "`ln_agg_expend_r_pc_'" 27 "`male'" 28 "`male_'" 29 "`urban_97'" 30 "`urban_97_'", replace

collect label levels result mean "" N "" sd "", replace

collect layout (cmdset) (result[mean N sd])
collect style cell cell_type[item column-header], halign(center)
collect style column, extraspace(3)
collect style row stack, spacer nobinder

collect preview

collect export "$word/sample_summary.docx", name(sample_sum_table) replace
collect export "$latex/sample_summary.tex", name(sample_sum_table) replace

**********************************************************************************Tables over time - stayon, pass, and ln_ek scores over time         **********************************************************************************

cd $clean
use master, clear

collect clear
collect create stayon_sum_table

foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 {
	
	collect: sum stayon`n' if sample1 == 1
	collect: sum stayon`n' if sample2 == 1 
	
	local stayon`n' ":    stayon`n' (restricted sample)"
	
}

local v1 stayon
collect label levels cmdset 1 "`v1'1" 2 "``v1'1'" 3 "`v1'2" 4 "``v1'2'" 5 "`v1'3" 6 "``v1'3'" 7 "`v1'4" 8 "``v1'4'" 9 "`v1'5" 10 "``v1'5'" 11 "`v1'6" 12 "``v1'6'" 13 "`v1'7" 14 "``v1'7'" 15 "`v1'8" 16 "``v1'8'" 17 "`v1'9" 18 "``v1'9'" 19 "`v1'10" 20 "``v1'10'" 21 "`v1'11" 22 "``v1'11'" 23 "`v1'12" 24 "``v1'12'" 25 "`v1'3" 26 "``v1'13'" 27 "`v1'14" 28 "``v1'14'" 29 "`v1'15" 30 "``v1'15'" 31 "`v1'16" 32 "``v1'16'" 33 "`v1'17" 34 "``v1'17'" 35 "`v1'18" 36 "``v1'18'" 37 "`v1'19" 38 "``v1'19'" 39 "`v1'20" 40 "``v1'20'" 41 "`v1'21" 42 "``v1'21'" 43 "`v1'22" 44 "``v1'22'" 


collect label list cmdset

collect layout (cmdset) (result[mean sd])
collect style cell cell_type[item column-header], halign(center)
collect style column, extraspace(3)
collect style row stack, spacer nobinder

collect preview

collect export "$word/stayon_summary.docx", name(stayon_sum_table) replace
collect export "$word/stayon_summary.docx", name(stayon_sum_table) replace

preserve

keep stayon* sample2 pidlink
reshape long stayon, i(pidlink sample2) j(year)
gen stayon_total = stayon
reshape wide stayon, i(pidlink year) j(sample2)
drop stayon0
graph bar (mean) stayon_total stayon1, over(year) legend(label(1 "Unrestricted sample") label(2 "Restricted sample")) title("Stay on rates, by year") yscale(r(0 1))
graph export "$graphs/stayon_sample.png", replace

restore

collect clear
collect create pass_sum_table

foreach n in 1 2 3 4 5 6 7 8 9 10 11 12 {
	
	collect: sum pass`n' if sample1 == 1
	collect: sum pass`n' if sample2 == 1 
	
	local pass`n' ":    pass`n' (restricted sample)"
	
}

local v1 pass
collect label levels cmdset 1 "`v1'1" 2 "``v1'1'" 3 "`v1'2" 4 "``v1'2'" 5 "`v1'3" 6 "``v1'3'" 7 "`v1'4" 8 "``v1'4'" 9 "`v1'5" 10 "``v1'5'" 11 "`v1'6" 12 "``v1'6'" 13 "`v1'7" 14 "``v1'7'" 15 "`v1'8" 16 "``v1'8'" 17 "`v1'9" 18 "``v1'9'" 19 "`v1'10" 20 "``v1'10'" 21 "`v1'11" 22 "``v1'11'" 23 "`v1'12" 24 "``v1'12'" 

collect label list cmdset

collect layout (cmdset) (result[mean sd])
collect style cell cell_type[item column-header], halign(center)
collect style column, extraspace(3)
collect style row stack, spacer nobinder

collect preview

collect export "$word/pass_summary.docx", name(pass_sum_table) replace
collect export "$word/pass_summary.docx", name(pass_sum_table) replace

preserve

keep pass* sample2 pidlink
reshape long pass, i(pidlink sample2) j(year)
gen pass_total = pass
reshape wide pass, i(pidlink year pass_total) j(sample2)
drop pass0
graph bar (mean) pass_total pass1, over(year) legend(label(1 "Unrestricted sample") label(2 "Restricted sample")) title("Pass rates, by year") yscale(r(0 1))
graph export "$graphs/pass_sample.png", replace

restore

collect clear 
collect create ek_sum_table

foreach n in 00 07 14 {
	
	collect: sum ln_total_ek`n' if sample1 == 1
	collect: sum ln_total_ek`n' if sample2 == 1
	
	local ln_total_ek`n' ":    ln_total_ek`n' (restricted sample)"
	
}

local v1 ln_total_ek
collect label levels cmdset 1 "`v1'00" 2 "``v1'00'" 3 "`v1'07" 4 "``v1'07'" 5 "`v1'14" 6 "``v1'14'"

collect label list cmdset

collect layout (cmdset) (result[mean sd])
collect style cell cell_type[item column-header], halign(center)
collect style column, extraspace(3)
collect style row stack, spacer nobinder

collect preview

preserve

keep ln_total_ek* sample2 pidlink
rename (ln_total_ek00 ln_total_ek07 ln_total_ek14) (ln_total_ek2000 ln_total_ek2007 ln_total_ek2014)
reshape long ln_total_ek, i(pidlink sample2) j(year)

gen ln_total_ek_total = ln_total_ek
reshape wide ln_total_ek, i(pidlink year ln_total_ek_total) j(sample2)
drop ln_total_ek0
graph bar ln_total_ek_total ln_total_ek1, over(year) legend(label(1 "Unrestricted sample") label(2 "Restricted sample")) title("Average ln(EK) scores")
graph export "$graphs/ek_sample.png", replace

restore


**********************************************************************************Distributions of sample over urban, cohort, province, and sex       **********************************************************************************

cd $clean
use master, clear

collect clear
collect: bysort _cohort sample2: quietly sum male
collect label levels sample2 0 "not in restricted sample" 1 "in restricted sample", modify
collect label levels result mean "% male", modify
collect layout (_cohort#sample2) (result[mean])
collect export "$word/sex_cohort_sample.docx", replace
collect export "$latex/sex_cohort_sample.tex", replace

collect clear 
collect: bysort prov_97 sample2: quietly sum urban_97
collect label levels sample2 0 "not in restricted sample" 1 "in restricted sample", modify
collect label levels result mean "% urban", modify
collect layout (prov_97#sample2) (result[mean])
collect export "$word/prov_urban_sample.docx", replace
collect export "$latex/prov_urban_sample.tex", replace

collect clear
collect: bysort prov_97 sample2: quietly sum above_med
collect label levels sample2 0 "not in restricted sample" 1 "in restricted sample", modify
collect label levels result mean "% above median expend", modify
collect layout (prov_97#sample2) (result[mean])
collect export "$word/prov_expend_sample.docx", replace
collect export "$latex/prov_expend_sample.tex", replace











