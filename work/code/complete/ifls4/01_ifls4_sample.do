/*
capture log close
log using  01_ifls4_sample, replace text
*/

/*
  program:    	01_ifls4_sample.do
  task:			To clean sample from ifls4.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 13February2024
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
* Clean and prepare sample from IFLS4 ***************************************************************************************
cd "$raw/ifls4_hh"
use bk_ar1, clear

* Let's make sure there's no missing identifiers:
list if pidlink == "" | pid07 == . | hhid07 == ""

	* We immediately run into a problem: pidlink is NOT a unique identifier in the data, as some people are listed in multiple households; let's first confirm that the combination of household id and person id (within household) are indeed unique identifiers.
isid pid07 hhid07
duplicates report pidlink 
duplicates tag pidlink, generate(pidlink_dupe)

	* We can immediately drop some of these duplicate cases, by dropping those duplicates that are missing for the variable describing their relation to the head of the household.
tab ar02 if pidlink_dupe == 1, m 
drop if ar02b == . & pidlink_dupe == 1
	drop pidlink_dupe

duplicates report pidlink
duplicates tag pidlink, generate(pidlink_dupe)

* Okay, so we're going to have to drop pidlinks based on their closeness to the household head:
bysort pidlink: egen max_closeness = min(ar02b) 
drop if ar02b != max_closeness
* We still haven't eliminated all duplicates; some listed in the HH roster are no longer part of the household or are dead, so we can drop those that are pidlink duplicates:
duplicates tag pidlink, gen(dupe_pidlink) 
	drop if (ar01a == 0 | ar01a == 3) & dupe_pidlink == 1
* That got rid of most of the duplicates; let's quickly check the remaining ones.
drop dupe_pidlink
duplicates report pidlink
	* There's only 3 duplicates left; let's just drop them:
	duplicates drop pidlink, force
* Let's check
isid pidlink
isid pid07 hhid07
****************************************************************************************
* Create urban_00 variable       ****************************************************************************************
* To create the urban and geography-identifer variables, we need to merge on the bk_sc dataset. Consider that not all people on a household roster will also appear in the new dataset; therefore, we will drop all observations except for those that can be matched to observations in the master dataset--which is the household roster in IFLS2.
merge m:1 hhid07 using bk_sc
	keep if _merge == 1 | _merge == 3
	drop _merge
* I take the urban variable from the sc05 variable ("(1) Urban area (2) Rural (From BPS)")
gen urban_07 				= 1 if sc05 == 1
	replace urban_07 			= 0 if sc05 == 2
	replace urban_07			= .m if sc05 == .
	label var urban_07 "do you live in an urban area (2007)"
		label val urban_07 binary
* Our province/kabupaten/kecamatan variables are taken from their respective original IFLS variables. Of note is that the labels for the province codes are already coded and need no editing.
rename (sc010707 sc020707 sc030707) (prov_07 kab_07 kec_07)
label var prov_07 "province code (2007)"
label var kab_07 "kabupaten code (2007)"
label var kec_07 "kecamatan code (2007)"
****************************************************************************************
* Merge to obtain commid00 variable ****************************************************************************************
tempfile ifls4_sample
		save `ifls4_sample'
	use htrack, clear
		keep hhid07 commid07 
		* Bizarrely, there are a bunch of observations with missing household ids -- let's drop, they're useless to us.
		drop if hhid07 == ""
merge 1:m hhid07 using `ifls4_sample'
	drop if _merge == 1 
		drop _merge 
***************************************************************************************
* Finish Up 
***************************************************************************************
	local tag 01_ifls4_sample.do
foreach v in urban_07 prov_07 kab_07 kec_07 {
	notes `v': `tag'
}
	keep hhid07 pid07 pidlink urban_07 prov_07 kab_07 kec_07 commid07
	tostring pidlink hhid07, replace
label data "ifls4 basic sample"
	
compress
	cd "$clean/ifls4_hh"
	save ifls4_sample, replace
/*
log close
exit
*/









