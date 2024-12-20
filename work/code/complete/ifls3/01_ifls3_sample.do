/*
capture log close
log using  01_ifls3_sample, replace text
*/

/*
  program:    	01_ifls3_sample.do
  task:			To clean sample from ifls3.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 02Aug2023
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
* Clean and prepare sample from IFLS3 ***************************************************************************************
cd "$raw/ifls3_hh"
	use bk_ar1, clear
* Let's make sure there's no missing identifiers:
list if pidlink == "" | pid00 == . | hhid00 == ""
* We immediately run into a problem: pidlink is NOT a unique identifier in the data, as some people are listed in multiple households; let's first confirm that the combination of household id and person id (within household) are indeed unique identifiers.
isid pid00 hhid00
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
	isid pid00 hhid00
****************************************************************************************
* Create urban_00 variable       ****************************************************************************************
* To create the urban and geography-identifer variables, we need to merge on the bk_sc dataset. Consider that not all people on a household roster will also appear in the new dataset; therefore, we will drop all observations except for those that can be matched to observations in the master dataset--which is the household roster in IFLS2.
merge m:1 hhid00 using bk_sc
	keep if _merge == 1 | _merge == 3
	drop _merge
* I take the urban variable from the sc05 variable ("(1) Urban area (2) Rural (From BPS)")
gen urban_00 				= 1 if sc05 == 1
	replace urban_00 			= 0 if sc05 == 2
	replace urban_00			= .m if sc05 == .
	label var urban_00 "do you live in an urban area (2000)"
		label val urban_00 binary
* Our province/kabupaten/kecamatan variables are taken from their respective original IFLS variables. Of note is that the labels for the province codes are already coded and need no editing.
rename (sc01 sc02 sc03) (prov_00 kab_00 kec_00)
label var prov_00 "province code (2000)"
label var kab_00 "kabupaten code (2000)"
label var kec_00 "kecamatan code (2000)"
****************************************************************************************
* Merge to obtain commid00 variable ****************************************************************************************
tempfile ifls3_sample
		save `ifls3_sample'
	use htrack, clear
		keep hhid00 commid00 
* Bizarrely, there are a bunch of observations with missing household ids -- let's drop, they're useless to us.
		drop if hhid00 == ""
merge 1:m hhid00 using `ifls3_sample'
	drop if _merge == 1 
		drop _merge 
***************************************************************************************
* Finish Up 
***************************************************************************************
	local tag 01_ifls3_sample.do
foreach v in urban_00 prov_00 kab_00 kec_00 {
	notes `v': `tag'
}
* let's keep only the necessary variables
keep hhid00 pid00 pidlink urban_00 prov_00 kab_00 kec_00 commid00
	* for consistency's sake, let's make the person and household identifiers strings
	tostring pidlink hhid00, replace
* now let's label the data
label data "ifls3 basic sample"

compress
	cd "$clean/ifls3_hh"
	save ifls3_sample, replace
/*
log close
exit
*/









