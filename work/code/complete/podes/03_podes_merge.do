/*
capture log close
log using  03_podes_merge, replace text
*/

/*
  program:    	03_podes_merge.do
  task:			To merge podes data
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 21Mar2024
*/

version 17
clear all
set linesize 80
macro drop _all

***************************************************************************************
* Set Global Macros              ***************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~/thesis_independent_study/work/code/complete"
***************************************************************************************
* Merge 1990 and 2000 data ***************************************************************************************
cd "$clean/podes"
use podes90, clear
	merge 1:1 desa drh kab kec prop using podes00
* now let's rename / properly label _merge 
rename _merge podes_merge  
	label var podes_merge "status of merging podes"
		label def podes_merge 1 "only in 1990" 2 "only in 2000" 3 "both in 1990 and 2000"
***************************************************************************************
* Private vs. Public Comparison ***************************************************************************************
foreach k in 90 00 {
	foreach v in priv pub {
		egen total`v'`k' = total(num_`v'kinder`k')
			sum total`v'`k'
		bysort prop: egen prov_total`v'`k' = total(num_`v'kinder`k')
	}
	egen total`k' = total(total_kinder`k')
			sum total`k'
	bysort prop: egen prov_total`k' = total(total_kinder`k')
}

di "percentage of kindergartens that were private (1990):" (39533/41587)*100
di "percentage of kindergartens that were public (1990):" (61136/63267)*100
	list if prov_totalpriv90 < prov_totalpub90 
	list if prov_totalpriv00 < prov_totalpub00
***************************************************************************************
* Finish Up 
***************************************************************************************
	local tag 03_podes_merge.do
foreach v in podes_merge {
	notes `v': `tag'
}
label data "podes master"
	compress
	cd "$clean/podes"
	save podes, replace
/*
log close
exit
*/









