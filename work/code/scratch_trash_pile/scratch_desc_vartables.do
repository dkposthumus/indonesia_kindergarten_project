/*
capture log close
log using 90_desc_vartabels, replace text
*/

/*
  program:    	90_desc_vartables.do
  task:			To create a variety of tables demonstrating variable variation.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 04Aug2023
*/

version 17
clear all
set linesize 80
macro drop _all

********************************************************************************Set Global Macros              ********************************************************************************

global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"

global code "/Users/danielposthumus/thesis_independent_study/work/code/to_do"

global word "$clean/desc_stat/word_format"
global latex "$clean/desc_stat/latex_format"

********************************************************************************Table1 - Summary statistics table for our core variables            ********************************************************************************

cd $clean
use master, clear

table (var), statistic(mean educ kinder_ever ln_earnings ln_total_ek00 ln_total_ek07 ln_total_ek14 unemployed_3 labor_force male urban) statistic(sd educ kinder_ever ln_earnings ln_total_ek00 ln_total_ek07 ln_total_ek14 unemployed_3 labor_force male urban) statistic(count educ kinder_ever ln_earnings ln_total_ek00 ln_total_ek07 ln_total_ek14 unemployed_3 labor_force male urban) 

collect dims

collect layout (var) (result)
collect label levels var educ "" kinder_ever "" labor_force "" ln_earnings "" ln_total_ek00 "" ln_total_ek07 "" ln_total_ek14 "" unemployed_3 "" urban_97 "", modify

collect export "$word/summary_table.docx", name(Table) replace
collect export "$latex/summary_table.tex", name(Table) replace

********************************************************************************Table2 - Creating tables demonstrating kindergarten attendance variation across wealth/province/birth cohort          ********************************************************************************

cd $clean
use master, clear

collect clear

collect create table2
collect: bysort _cohort prov_97 above_med: quietly sum kinder_ever
collect label levels above_med 1 "1" 0 "0", modify
collect style autolevels result N mean sd skewness kurtosis

collect layout (prov_97#_cohort) (result), name(table2)
collect export "$word/kinder_prov_cohort.docx", replace name(table2)
collect export "$latex/kinder_prov_cohort.tex", replace name(table2)

collect layout (prov_97#_cohort) (above_med) (result[mean]), name(table2)
collect export "$word/kinder_prov_cohort_wealth.docx", replace name(table2)
collect export "$latex/kinder_prov_cohort_wealth.tex", replace name(table2)

********************************************************************************Table3 - Creating tables demonstrating years of education variation across wealth/province/birth cohort          ********************************************************************************

cd $clean
use master, clear

collect clear

collect create table3
collect: bysort _cohort prov_97 above_med: quietly sum educ
collect label levels above_med 1 "1" 0 "0", modify
collect style autolevels result N mean sd skewness kurtosis

collect layout (prov_97#_cohort) (result), name(table3)
cd $word
collect export educ_prov_cohort.docx, replace name(table3)
cd $latex
collect export educ_prov_cohort.tex, replace name(table3)

collect layout (prov_97#_cohort) (above_med) (result[mean]), name(table3)
cd $word
collect export educ_prov_cohort_wealth.docx, replace name(table3)
cd $latex
collect export educ_prov_cohort_wealth.tex, replace name(table3)











