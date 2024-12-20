/*
capture log close
log using  02_podes90, replace text
*/

/*
  program:    	02_podes90.do
  task:			To import and clean data related to PODES 1990.
  
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
* Import and merge 1990 data ***************************************************************************************
cd "$raw/podes"
* Our data is in the excel format so we have to import from excel:
import delimited using podes90_b5.csv, varnames(1)
* first let's drop the unnecessary identifiers:
drop b1r7c1 b1r8c1 b1r9c1 filler_datc67 filler_idc3 rec_typec1
* let's simplify the village identifiers by renaming them:
rename (b1r1c2 b1r2c2 b1r4c3 b1r5c3 b1r6c1) (prop kab kec desa drh)
* we then have to destring all of these variables
foreach v in desa drh kab kec prop {
	destring `v', replace
}
	* We have to save this as a tempfile to merge with the remaining PODES data:
	tempfile podes90_b5
		save `podes90_b5'
import delimited using podes90_b7.csv, varnames(1) clear
drop b1r7c1 b1r8c1 b1r9c1 filler_idc3 rec_typec1
* to merge i have to rename the village identifier variables
	rename (b1r1c2 b1r2c2 b1r4c3 b1r5c3 b1r6c1) (prop kab kec desa drh)
	* now let's merge 
		merge 1:1 desa drh kab kec prop using `podes90_b5', nogen
***************************************************************************************
* Clean data  (var names/labels) ***************************************************************************************
* now let's label our variables of interest, adding 90 to them to differentiate from 2000 data:
label var b7r1ak2n20 "number of state-owned kindergarten buildings (1990)"
label var b7r1ak3n20 "number of private kindergarten buildings (1990)"
label var b7r1ak4n20 "number of state-owned kindergartens (1990)"
label var b7r1ak5n20 "number of private kindergartens (1990)"
label var b5ar3n60 "number of residents (1990)"
label var b5ar4n40 "number of people aged 7-15 (1990)" 
label var b5ar5n40 "number of people aged 7-15 attending school (1990)" 
label var b5ar6n60 "number of households (1990)" 
	drop b7r1ak2n20 b7r1ak3n20
* now let's rename our variables:
rename (b7r1ak4n20 b7r1ak5n20 b5ar3n60 b5ar4n40 b5ar5n40 b5ar6n60) (num_pubkinder90 num_privkinder90 num_pop90 num_young90 num_young_schl90 num_hh90)
* let's drop the young people variables, they're unnecessary
drop num_young90 num_young_schl90
* now I need to create several variables:
gen total_kinder90 = num_pubkinder90 + num_privkinder90 
	label var total_kinder90 "total number of kindergartens (1990)"
***************************************************************************************
* Finish Up 
***************************************************************************************
	local tag 02_podes90_kinder.do
foreach v in total_kinder90 num_privkinder90 num_pubkinder90 num_pop90 num_hh90 {
	notes `v': `tag'
}
label data "podes 1990"
compress
	cd "$clean/podes"
	save podes90, replace
/*
log close
exit
*/









