/*
capture log close
log using 03_iv_create, replace text
*/

/*
  program:    	03_iv_create
  task:			To create my first independent variable (IV), kindergarten attendance 
				rates by kecamatan and age cohort.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 05Jan2024
*/

version 17
clear all
set linesize 80
macro drop _all

***************************************************************************************
* Set Global Macros              ***************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~thesis_independent_study/work/code/complete"
	global output "~/thesis_independent_study/work/writing/rough_draft/analysis"
***************************************************************************************
* PODES kindergarten data ***************************************************************************************
use "$clean/podes/podes", clear
	tempfile podes_kinder
* first, let's collapse on kecamatan:
foreach v in 90 00 {
	bysort prop kab kec: egen kec_total_kinder`v' = sum(total_kinder`v')
	bysort prop kab kec: egen kec_total_pop`v' = sum(num_pop`v')
	bysort prop kab kec: egen kec_total_hh`v' = sum(num_hh`v')
	foreach k in priv pub {
		bysort prop kab kec: egen kec_`k'kinder`v' = sum(num_`k'kinder`v')
	}
}
* now let's collapse with the mean of these variables (they're constant throughout)
ds kec_*
collapse (mean) `r(varlist)', by(prop kab kec)
* now let's generate our kinder-per-pop:
foreach v in 90 00 {
	gen kec_popkinder`v' = (kec_total_kinder`v' / kec_total_pop`v') * 10000
	gen kec_hhkinder`v' = (kec_total_kinder`v' / kec_total_hh`v') * 10000
	gen kec_privpopkinder`v' = (kec_privkinder`v' / kec_total_pop`v') * 10000
	gen kec_pubpopkinder`v' = (kec_pubkinder`v' / kec_total_pop`v') * 10000

}
* now let's generate the change variable, we'll do a basic percent change:
foreach v in pop hh {
	gen kec_`v'kinder_chg = ((kec_`v'kinder00 - kec_`v'kinder90) / kec_`v'kinder90) * 100
}
* now for merging we have to rename the geographical identifying variables: 
rename (kec kab prop) (kec_97 kab_97 prov_97)
	save `podes_kinder'
***************************************************************************************
* Merge data 
***************************************************************************************
use `podes_kinder'
	cd $clean
	merge 1:m kec_97 kab_97 prov_97 using master, nogen
* now let's replace missing observation with the mean from each province:
foreach v in kec_popkinder00 kec_popkinder90 {
	bysort prov_97: egen mean_`v' = mean(`v')
		replace `v' = mean_`v' if `v' == .
			drop mean_`v'
}
***************************************************************************************
* Finishing Up ***************************************************************************************
local tag 03_iv_create.do
foreach v in kec_popkinder00 kec_popkinder90 kec_hhkinder00 kec_hhkinder90 {
	notes `v': `tag'
}
	compress
cd "$clean"
save master, replace

/*
log close
exit
*/





	


