* capture log close
* log using _do_file_name_, replace text

//  program:    03_hh_bk3_cleaning.do
//  task:		moving the hh bk3 datasets to the clean directory
//  project:	IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
//  author:     Daniel_Posthumus \ 03/15/2023

version 10
clear all
set linesize 80
macro drop _all

* EXTRACT DATA AND SAVE IN NEW FOLDER, the "clean" data folder

local rawdat_dir "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Datasets/hh14_all_dta"
local newdat_dir "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Data_Clean/hh_14_data"

foreach file in b3a_br1 b3a_cov b3a_dl1 b3a_dl2 b3a_dl3 b3a_dl4 b3a_dl5 b3a_hi b3a_hr0 b3a_hr1 b3a_hr2 b3a_kw1 b3a_kw3 b3a_mg1 b3a_mg2 b3a_pk1 b3a_pk2 b3a_pk3 b3a_pna1 b3a_pna2 b3a_re1 b3a_re2 b3a_si b3a_sw b3a_time b3a_tk1 b3a_tk2 b3a_tk2 b3a_tk3 b3a_tk4 b3a_tr b3b_ak1 b3b_ak2 b3b_ba0 b3b_ba1 b3b_ba4 b3b_ba6 b3b_cd1 b3b_cd2 b3b_cd3 b3b_co1 b3b_cob b3b_cov b3b_eh b3b_ep1 b3b_ep2 b3b_fm1 b3b_fm2 b3b_kk1 b3b_kk2 b3b_kk3 b3b_kk4 b3b_km b3b_kp b3b_ma1 b3b_ma2 b3b_pm1 b3b_pm2 b3b_ps b3b_psn b3b_rj0 b3b_rj1 b3b_rj2 b3b_rj3 b3b_rn1 b3b_rn2 b3b_sa b3b_tdr b3b_tf b3b_time {
	cd "`rawdat_dir'"
	use `file', clear
	cd "`newdat_dir'"
	save ifls5_`file', replace
}

local rawdat_dir "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Datasets/hh07_all_dta"
local newdat_dir "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Data_Clean/hh_7_data"

foreach file in b3a_dl1 b3a_cov {
	cd "`rawdat_dir'"
	use `file', clear
	cd "`newdat_dir'"
	save ifls4_`file', replace
}
//* 
*foreach file in b3a_br1 b3a_cov b3a_dl1 b3a_dl2 b3a_dl3 b3a_dl4 b3a_dl5 b3a_hi b3a_hr0 b3a_hr1 b3a_hr2 b3a_kw1 b3a_kw3 b3a_mg1 b3a_mg2 b3a_pk1 b3a_pk2 b3a_pk3 b3a_pna1 b3a_pna2 b3a_re1 b3a_re2 b3a_si b3a_sw b3a_time b3a_tk1 b3a_tk2 b3a_tk2 b3a_tk3 b3a_tk4 b3a_tr b3b_ak1 b3b_ak2 b3b_ba0 b3b_ba1 b3b_ba4 b3b_ba6 b3b_cd1 b3b_cd2 b3b_cd3 b3b_co1 b3b_cob b3b_cov b3b_eh b3b_ep1 b3b_ep2 b3b_fm1 b3b_fm2 b3b_kk1 b3b_kk2 b3b_kk3 b3b_kk4 b3b_km b3b_kp b3b_ma1 b3b_ma2 b3b_pm1 b3b_pm2 b3b_ps b3b_psn b3b_rj0 b3b_rj1 b3b_rj2 b3b_rj3 b3b_rn1 b3b_rn2 b3b_sa b3b_tdr b3b_tf b3b_time {
	*cd "`rawdat_dir'"
	*use `file', clear
	*cd "`newdat_dir'"
	*save ifls4_`file', replace
* } 
//* 


* log close
exit
