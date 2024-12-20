/*
capture log close
log using  01_ifls2_sample, replace text
*/

/*
  program:    	01_ifls2_sample.do
  task:			To clean sample from ifls2.
  
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
* Clean and prepare sample from IFLS2 ***************************************************************************************
cd "$raw/ifls2_hh"
use bk_ar1, clear
* Let's make sure there's no missing identifiers:
list if pidlink == "" | pid97 == . | hhid97 == ""
* We immediately run into a problem: pidlink is NOT a unique identifier in the data, as some people are listed in multiple households; let's first confirm that the combination of household id and person id (within household) are indeed unique identifiers.
isid pid97 hhid97
duplicates report pidlink 
duplicates tag pidlink, generate(pidlink_dupe)
* We can immediately drop some of these duplicate cases, by dropping those duplicates that are missing for the variable describing their relation to the head of the household.
tab ar02 if pidlink_dupe == 1, m 
drop if ar02 == . & pidlink_dupe == 1
	drop pidlink_dupe
duplicates report pidlink
duplicates tag pidlink, generate(pidlink_dupe)
* We are left with one duplicate; I will just drop this single observation.
drop if pidlink_dupe == 1
drop pidlink_dupe
* Let's check
isid pidlink
isid pid97 hhid97
***************************************************************************************
* Create hh_head_child and adopt dummy variables         ***************************************************************************************
* I want to now define the dummy variable for whether a child is the child [biological OR adopted] of the head of the household head; i'm using the ar02b variable ("relation to HH head").
gen hh_head_child = 1					if ar02b == 03 | ar02b == 04
	replace hh_head_child = 0				if hh_head_child == .
	replace hh_head_child = .m				if ar02b == .
label var hh_head_child					"are you the child of the head of your household"
	label def binary 1 "yes" 0 "no" .m "missing", replace
		label val hh_head_child binary
* Next, I want to create a dummy variable specific to adopted children of the household head (these children are coded as the child of the household head, this variable merely adds more detail).
gen adopt = 1							if ar02b == 04 & hh_head_child == 1
	replace adopt = 0						if adopt == . & hh_head_child == 1
	replace adopt = .m						if ar02b == . | adopt == .
label var adopt							"are you the adopted child of the head of your household"
		label val adopt binary
***************************************************************************************
* Create two-parent dummy variable           ***************************************************************************************
/*
Here I will define a two parent household as one containing both the birth father and a birth mother of the child. To code this variable, I will focus on the cases where the birth parents are NOT still in the household:
	- The birth father is either "OutHH" or "Died" (ar10 == 51 | ar10 == 52)
	- The birth mother is either "OutHH" or "Died" (ar11 == 51 | ar11 == 52)
I am also assuming that if either of these variables are MISSING, then the respective biological parents is NOT in the household.
*/
* I code separate biological mother and biological father variables and then the joint two-parent variable.
	gen mother_hh = 0 if ar11 == 51 | ar11 == 52 | ar11 == .
		replace mother_hh = 1 if mother_hh == .
			label var mother_hh "is biological mother in household?"
	gen father_hh = 0 if ar10 == 51 | ar10 == 52 | ar10 == .
		replace father_hh = 1 if father_hh == .
			label var father_hh "is biological father in household?"
* Now let's code the joint variable.
gen two_parent = 1 if mother_hh == 1 & father_hh == 1
	replace two_parent = 0 if mother_hh == 0 | father_hh == 0
	label var two_parent "are both biological parents in household?"
label val mother_hh father_hh two_parent binary
***************************************************************************************
* Create urban_97 variable       ***************************************************************************************
* To create the urban and geography-identifer variables, we need to merge on the bk_sc dataset. Consider that not all people on a household roster will also appear in the new dataset; therefore, we will drop all observations except for those that can be matched to observations in the master dataset--which is the household roster in IFLS2.
merge m:1 hhid97 using bk_sc
	keep if _merge == 1 | _merge == 3
	drop _merge
* I take the urban variable from the sc05 variable ("(1) Urban area (2) Rural (From BPS)")
gen urban_97 				= 1 if sc05 == 1
	replace urban_97 			= 0 if sc05 == 2
	replace urban_97			= .m if sc05 == .
	label var urban_97 "do you live in an urban area (1997)"
		label val urban_97 binary
* Our province/kabupaten/kecamatan variables are taken from their respective original IFLS variables. Of note is that the labels for the province codes are already coded and need no editing.
rename (sc01 sc02 sc03) (prov_97 kab_97 kec_97)
label var prov_97 "province code (1997)"
label var kab_97 "kabupaten code (1997)"
label var kec_97 "kecamatan code (1997)"
***************************************************************************************
* Merge to obtain commid97 (community identifier) variable ***************************************************************************************
tempfile ifls2_sample
		save `ifls2_sample'
	use htrack, clear
		keep hhid97 commid97 
merge 1:m hhid97 using `ifls2_sample'
	drop if _merge == 1 
		drop _merge 
***************************************************************************************
* Finish Up 
***************************************************************************************
* I want to tag all variables created in this do-file with the name of it to make tracking easier
local tag 01_ifls2_sample.do
foreach v in hh_head_child adopt father_hh mother_hh two_parent urban_97 prov_97 kab_97 kec_97 {
	notes `v': `tag'
}
	compress
* I want to keep only the necessary variables here
keep hhid97 pid97 pidlink hh_head_child adopt father_hh mother_hh two_parent urban_97 prov_97 kab_97 kec_97 commid97
* now let's label this dataset:
label data "ifls2 basic sample"
* let's make the person and household id variables strings for the sake of consistency
	tostring pidlink hhid97, replace
* now let's save the data set
cd "$clean/ifls2_hh"
	save ifls2_sample, replace
	
/*
log close
exit
*/









