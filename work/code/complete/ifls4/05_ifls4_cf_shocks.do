/*
capture log close
log using 05_ifls4_cf_schls, replace text
*/

/*
  program:    	05_ifls4_cf_shocks.do
  task:			To create a set of variables capturing community-level shocks in the 
				IFLS4 survey.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 20Feb2024
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
* Pull basic shocks data           ***************************************************************************************
cd "$raw/ifls4_cf"
	use bk1_f1, clear
* We can drop unhelpful variables:
drop module f03mthx f03yrx f03mth 
* now let's define the set of locals corresponding to the categories of f1type:
local A "flood" 
local B "earthquake" 
local C "landslide" 
local D "volcano eruption" 
local E "tsunami" 
local F "drought" 
local G "fire" 
local H "other"
		drop if f1type == "H"
rename (f01 f02 f03yr) (disaster num_disaster year_disaster)
* Now let's reshape wide:
reshape wide disaster num_disaster year_disaster, i(commid07) j(f1type) string
foreach l in A B C D E F G {
	replace disaster`l' = 0 if disaster`l' == 3
	replace num_disaster`l' = 0 if num_disaster`l' == . 
	replace year_disaster`l' = . if year_disaster`l' == 9998
		label var num_disaster`l' "number of ``l'' in last five years (2007)"
		label var year_disaster`l' "year of most severe ``l'' in last five years (2007)"
		label var disaster`l' "was there a ``l'' in last five years (2007)"
}
* Now let's create a variable summing the number of ALL types of disaster: 
duplicates report commid07 
ds num_disaster* 
egen num_disaster_total_07 = rowtotal(`r(varlist)')
	label var num_disaster_total_07 "total number of disasters in last 5 years (2007)"
***************************************************************************************
* Finish Up 
***************************************************************************************
	local tag 05_ifls4_cf_shocks.do
foreach n in A B C D E F G {
		foreach v in num_disaster year_disaster disaster {
			rename `v'`n' `v'`n'_07
			notes `v'`n'_07: `tag'
	}
}
			notes num_disaster_total_07: `tag'
	label data "ifls4 community shocks"
compress
	cd "$clean/ifls4_cf"
	save ifls4_cf_shocks, replace
/*
log close
exit
*/









