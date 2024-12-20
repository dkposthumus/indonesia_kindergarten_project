clear
cap log close
cap program drop _all
set more 1
set mem 500m
set matsize 150

*cd "C:\Users\Ranjan\Documents\Sync Folder\Stata Files\IFLS07\HH\b3a\log" ;
*log using IFLS07_b3a_sw.log, replace;

* EXTRACT DATA AND SAVE IN NEW FOLDER

* local rawdat_dir = "/Users/danielposthumus/Documents/Documents - Daniel's MacBook Air - 1/IFLS5/raw/hh14_all_dta"
* local newdat_dir = "/Users/danielposthumus/Documents/Documents - Daniel's MacBook Air - 1/IFLS5/cleaned/hh_data"

cd "/Users/danielposthumus/Documents/untitled" 
use b1_cov, clear

foreach file in b2_bh b2_cov b2_hi b2_hr1 b2_hr2 b2_kr b2_nd1 b2_nd2 b2_nt1 b2_nt2 b2_time b2_ut1 b2_ut2 b2_ut3 b2_ut4 {
	cd "/Users/danielposthumus/Documents/IFLS5/raw/hh14_all_dta"
	use `file', clear
	cd "/Users/danielposthumus/Documents/IFLS5/cleaned/hh_data"
	save ifls5_`file', replace
}

cd "`newdat_dir'"
