/*
capture log close
log using  01_podes00, replace text
*/

/*
  program:    	01_podes00.do
  task:			To import and clean data related to PODES 2000.
  
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
* Import and merge 2000 data ***************************************************************************************
cd "$raw/podes"
* Our data is in the excel format so we have to import from excel:
import excel using podes00_b5.xlsx, firstrow
* let's simplify the village identifiers by renaming them:
rename (DESA DRH KAB KEC PROP) (desa drh kab kec prop)
* we then have to destring all of these variables
foreach v in desa drh kab kec prop {
	destring `v', replace
}
	* We have to save this as a tempfile to merge with the remaining PODES data:
	tempfile podes00_b5
		save `podes00_b5'
import delimited using podes00_b4.csv, varnames(1) clear
* to merge i have to rename the village identifier variables
	rename (desac3 drhc1 kabc2 kecc3 propc2) (desa drh kab kec prop)
	* now let's merge 
		merge 1:1 desa drh kab kec prop using `podes00_b5', nogen
***************************************************************************************
* Clean data  (var names/labels) ***************************************************************************************
* now let's label our variables of interest, adding 00 to them to differentiate from 1990 data:
label var b4ar1c1 "frequency of population registration (2000)"
label var b4ar2an70 "number of population (2000)"
label var b4ar2bn60 "number of households (2000)"
label var B5R1A2 "number of state-owned kindergartens (2000)"
label var B5R1A3 "number of private kindergartens (2000)"
label var B5R1A4 "if no kindergarten, distance to nearest school"
* now let's rename our variables:
rename (b4ar1c1 b4ar2an70 b4ar2bn60 B5R1A2 B5R1A3 B5R1A4) (pop_regist00 num_pop00 num_hh00 num_pubkinder00 num_privkinder00 kinder_dist)

* now I need to create several variables:
gen total_kinder00 = num_pubkinder00 + num_privkinder00 
	label var total_kinder00 "total number of kindergartens (2000)"
* let's drop the registration and distance variables, they're unnecessary
drop pop_regist00 kinder_dist
/*
kinder_hh00 = (total_kinder00/num_hh00) * 1000
	label var kinder_hh00 "total number of kindergartens per 1,000 households (2000)"
kinder_pop00 = (total_kinder00/num_pop00) * 10000
	label var kinder_pop00 "total number of kindergartens per 10,000 residents (2000)"
privkinder_pop00 = (num_privkinder00/num_pop00) * 10000
	label var privkinder_pop00 "private kindergartens per 10,000 residents (2000)"
pubkinder_pop00 = (num_pubkinder00/num_pop00) * 10000
	label var pubkinder_pop00 "public kindergartens per 10,000 residents (2000)" 
*/
***************************************************************************************
* Finish Up 
***************************************************************************************
	local tag 01_podes00.do
foreach v in total_kinder00 num_pop00 num_hh00 num_pubkinder00 num_privkinder00 {
	notes `v': `tag'
}
label data "podes 2000 data"
	compress
	cd "$clean/podes"
	save podes00, replace
/*
log close
exit
*/









