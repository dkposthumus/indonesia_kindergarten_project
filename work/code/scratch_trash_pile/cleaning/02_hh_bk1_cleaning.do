* capture log close
* log using _do_file_name_, replace text

//  program:    02_hh_bk1_cleaning.do
//  task:		moving the hh bk1 datasets to the clean directory
//  project:	Independent Study/Honors Thesis (Daniel Posthumus)
//  author:     Daniel_Posthumus \ 03/15/2023

version 10
clear all
set linesize 80
macro drop _all

* EXTRACT DATA AND SAVE IN NEW FOLDER, the "clean" data folder

local rawdat_dir "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Datasets/hh14_all_dta"
local newdat_dir "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Data_Clean/hh_14_data"

foreach file in b1_cov b1_ks0 b1_ks1 b1_ks2 b1_ks3 b1_ks4 b1_ksr1 b1_ksr2 b1_ksr3 b1_ksr4 b1_pp b1_time {
	cd "`rawdat_dir'"
	use `file', clear
	cd "`newdat_dir'"
	save ifls5_`file', replace
}

local rawdat_dir "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Datasets/hh07_all_dta"
local newdat_dir "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Data_Clean/hh_7_data"

foreach file in b1_cov b1_ks0 {
	cd "`rawdat_dir'"
	use `file', clear
	cd "`newdat_dir'"
	save ifls4_`file', replace
} 
* log close
exit
