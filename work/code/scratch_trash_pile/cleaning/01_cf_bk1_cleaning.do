* capture log close
* log using _do_file_name_, replace text

//  program:    01_cf_bk1_cleaning.do
//  task:		moving the cf bk1 datasets to the clean directory
//  project:	IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
//  author:     Daniel_Posthumus \ 03/15/2023

version 10
clear all
set linesize 80
macro drop _all
* EXTRACT DATA AND SAVE IN NEW FOLDER, the "clean" data folder

local rawdat_dir = "/Users/danielposthumus/IFLS5/Work/Datasets/cf14_all_dta" 
local newdat_dir = "/Users/danielposthumus/IFLS5/Work/Data_Clean/cf_data"

foreach file in bk1_a1 bk1_b bk1_c1 bk1_c2 bk1_c3 bk1_d1 bk1_d1a bk1_d2 bk1_d3 bk1_d4 bk1_e1 bk1_e2 bk1_f1 bk1_f2 bk1_g bk1_ir bk1_pap0 bk1_pap1 bk1_pmkd bk1_tr bk1 bk1a_cov bk1a_time bk1b_cov bk1b_time bk1c_cov bk1c_time {
	cd "`rawdat_dir'"
	use `file', clear
	cd "`newdat_dir'"
	save ifls5_`file', replace
}

* log close
exit
