* capture log close
* log using _do_file_name_, replace text

//  program:    04_htrack_ptrack_cleaning.do
//  task:		moving the htrack dataset to the clean directory
//  project:	IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
//  author:     Daniel_Posthumus \ 04/06/2023

version 10
clear all
set linesize 80
macro drop _all

* EXTRACT DATA AND SAVE IN NEW FOLDER, the "clean" data folder

local rawdat_dir "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Datasets/hh14_all_dta"
local newdat_dir "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Data_Clean/hh_14_data"

foreach file in htrack ptrack {
	cd "`rawdat_dir'"
	use `file', clear
	cd "`newdat_dir'"
	compress
	save ifls5_`file', replace
}

duplicates tag pidlink, gen(dupes_tag)
bysort pidlink: gen n = _n
drop if dupes_tag == 1 & n == 2
save ifls5_ptrack, replace

local rawdat_dir "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Datasets/hh07_all_dta"
local newdat_dir "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Data_Clean/hh_7_data"

foreach file in htrack ptrack {
	cd "`rawdat_dir'"
	use `file', clear
	cd "`newdat_dir'"
	compress
	save ifls4_`file', replace
}

* duplicates tag pidlink, gen(dupes_tag)


* log close
* exit
