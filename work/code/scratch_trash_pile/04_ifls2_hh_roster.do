/*
capture log close
log using 03_hh_roster, replace text
*/

/*
  program:    	03_hh_roster.do
  task:			To clean and create a dataset of household roster variables.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 10Aug2023
*/

version 17
clear all
set linesize 80
macro drop _all


****************************************************************************************Set Global Macros              ****************************************************************************************

global raw "/Users/danielposthumus/thesis_independent_study/work/data_raw"
global clean "/Users/danielposthumus/thesis_independent_study/work/data_clean"

global code "/Users/danielposthumus/thesis_independent_study/work/code/to_do"


****************************************************************************************Create hh_head_child and adopt variable            ****************************************************************************************

cd "$raw/ifls2_hh"
use bk_ar1, clear

gen hh_head_child = 1					if ar02b == 03 | ar02b == 04
replace hh_head_child = 0				if ar02b != 03 & ar02b != 04
replace hh_head_child = .m				if ar02b == .
label var hh_head_child					"are you the child of the head of your household"

gen adopt = 1							if ar02b == 04
replace adopt = 0						if ar02b != 04
replace adopt = .m						if ar02b == .
label var adopt							"are you the adopted child of the head of your household"


****************************************************************************************Create two-parent variable           ****************************************************************************************

* Here I will define a two parent household as one containing both a birth father and a birth mother.

gen two_parent = 1						if (ar10 != 51 | ar10 != 52 | ar10 != .) & (ar11 != 51 & ar11 != 52 & ar11 != .)
replace two_parent = 0					if two_parent == .

label var two_parent					"is your household a two parent household?"

****************************************************************************************Create urban_97 variable       ****************************************************************************************

merge m:1 hhid97 using bk_sc, nogen

gen urban_97 				= 1 if sc05 == 1
replace urban_97 			= 0 if sc05 == 2
replace urban_97			= .m if sc05 == .
label var urban_97 "do you live in an urban area (1997)"

rename (sc01 sc02 sc03) (prov_97 kab_97 kec_97)
label var prov_97 "province code (1997)"
label var kab_97 "kabupaten code (1997)"
label var kec_97 "kecamatan code (1997)"


****************************************************************************************Finish Up ****************************************************************************************

local tag 03_ifls2_hh_roster.do

foreach v in hh_head_child two_parent adopt urban_97 prov_97 kec_97 kab_97 {
		
	notes `v': `tag'
	
}
compress

keep hhid97 pid97 pidlink hh_head_child adopt two_parent urban_97 prov_97

cd "$clean/ifls2_hh"
save ifls2_sample_var, replace

/*
log close
exit
*/









