/*
capture log close
log using 03_ifls2_parental_educ.do, replace text
*/

/*
  program:    	03_ifls2_parental_educ.do
  task:			To create a set of parental educational variables from IFLS2 data.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 24July2023
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
* Pull data for head of household/parents             ***************************************************************************************
/*
	In this section we create the valuable hh, "are you the head of the 
	household?"
	We create the variable using ar02b.
	
	households can assume the following values:
		- 0: "0_no"
			- ar02b != 1 ("01. Head")
		- 1: "1_yes"
			- ar02b = 1 ("01. Head")
*/
cd "$raw/ifls2_hh"
	use bk_ar1, clear
tempfile hh_status
* let's define a binary value label
	label def binary 0 "no" 1 "yes", replace
	numlabel binary, mask(#_) add force
gen hh = 1 if ar02b == 1
	replace hh = 0 if ar02b != 1
	label var hh "are you the head of your household?"
		label val hh binary
* Next, we also want to find the pid97 of the birth mother of each child, which is already captured in the ar11 variable.
rename ar11 mom_pid97
	save `hh_status', replace
***************************************************************************************
* Create evschl variable         ***************************************************************************************
use `hh_status', clear
/*
	First, we'll create the variable evschl, "have you never went to 
	school/are you currently going to school?" 
	We'll use two existing variables to create this variable: 
	- ar16, "HH member highest level of edu"
	- ar18c, "Still in school?"

	evschl can assume the following values:
		- 0 "never have went to school"
			- ar16 = 1 ("01. None")
		- 1 "currently going to school"
			 - ar18c = 1 ("1. Yes")
		- 2 "have went to school"
			- ar16 != 1 ("01. None") & 18c != 1 ("1. Yes")
		- .m "missing"
			- ar16 = . & ar18c = .
*/
gen evschl = 1 if ar18c == 1
	replace evschl = 0 if ar16 == 1
	replace evschl = 2 if ar16 != 1 & ar18c != 1
	replace evschl = .m if ar16 == . & ar18c == . 

	lab var evschl "have you ever went to school/are you currently going to school?"
	lab def evschl 0 "never have went to school" 1 "currently going to school" 2 "have went to school" .m "missing", replace
	numlabel binary, mask(#_) add force
	label val evschl evschl
***************************************************************************************
* Create educ_level variable      ***************************************************************************************
/*
	Next, we're going to create the variable educ_level "highest level of 
	education attended"
	We'll use two existing variables to create this variable: 
	- evschl, 'have you ever went to school/are you currently going to school?'
	- ar17, "Highest grade completed"
	- ar16, "HH member highest level of educ"
	
	educ_level can assume the following values:
		- 0 "no schooling/not finished primary school"
			- evschl = 0 ("0_no")
			- ar16 = 90 ("90:Kindergarten")
			- ar16 = 2 ("02. Elem") & ar17 != 7 ("7:Graduated")
		- 1 "primary school/equivalent"
			- ar16 = 2 ("2:Elementary school") & ar17 = 7 ("7:Graduated")
			- ar16 = 3 ("03. Gen JrHi") & ar17 != 7 ("7:Graduated")
			- ar16 = 4 ("03. Voc JrHi") & ar17 != 7 ("7:Graduated")
			- ar16 = 12 ("12. Adlt Ed B") & ar17 != 7 ("7:Graduated")
		- 2 "junior high school/equivalent"
			- ar16 = 3 ("03. Gen JrHi") & ar17 = 7 ("7:Graduated")
			- ar16 = 4 ("03. Voc JrHi") & ar17 = 7 ("7:Graduated")
			- ar16 = 12 ("12. Adlt Ed B") & ar17 = 7 ("7:Graduated")
			- ar16 = 5 ("05. Gen SrHi") & ar17 != 7 ("7:Graduated")
			- ar16 = 6 ("06. Voc SrHi") & ar17 != 7 ("7:Graduated")
		- 3 "senior high school/equivalent"
			- ar16 = 5 ("05. Gen SrHi") & ar17 = 7 ("7:Graduated")
			- ar16 = 6 ("06. Voc SrHi") & ar17 = 7 ("7:Graduated")
			- ar16 = 7 ("07. Dipl(1/2)") & ar17 != 7 ("7:Graduated")
			- ar16 = 8 ("08. Dipl(3)") & ar17 != 7 ("7:Graduated")
			- ar16 = 9 ("09. Univ") & ar17 != 7 ("7:Graduated")
		- 4 "higher education"
			- ar16 = 7 ("07. Dipl(1/2)") & ar17 = 7 ("7:Graduated")
			- ar16 = 8 ("08. Dipl(3)") & ar17 = 7 ("7:Graduated")
			- ar16 = 9 ("09. Univ") & ar17 = 7 ("7:Graduated")
		- 10 "other"
			- ar16 = 10 ("10. Other")
		- 14 "pesantren (islamic school)"
			- ar16 = 14 ("14. Islam Scl")
		- .d "don't know"
			- ar16 = 98 ("98:DK")
		- .m "missing"
			- ar16 = . ("99:MISSING")
			- educ_level = . (after all other rules have been coded)
*/
	* educ_level = 0
gen educ_level = 0 if 	  evschl == 0 | ar16 == 90 | ar16 == 02 & ar17 != 07
	* educ_level = 1
replace educ_level = 1 if ar16 == 02 & ar17 == 07 | inlist(ar16, 03, 04, 12) & 							[inrange(ar17,00,06) | ar17 == 96]
	* educ_level = 2
replace educ_level = 2 if inlist(ar16, 03, 04, 12) & ar17==07 |                          inlist(ar16,05,06) & [inrange(ar17,00,06) | ar17 ==                          96]
	* educ_level = 3
replace educ_level = 3 if inlist(ar16,05,06) & ar17==07 |                          inlist(ar16,07,08,09) & [inrange(ar17,00,06) | ar17                          == 96]
	* educ_level = 4
replace educ_level = 4 if inlist(ar16,07,08,09) & ar17==07
	* misc. cases
replace educ_level = 14 if ar16 == 14
replace educ_level = 10 if ar16 == 10
replace educ_level = .d if ar16 == 98
replace educ_level = .m if ar16 == .
replace educ_level = .m if educ_level == .

label var educ_level "highest level of education attended"
lab def educ_level 0 "no schooling/not finished primary school" 1 "primary school/equivalent" 2 "junior high school/equivalent" 3 "senior high school/equivalent" 4 "higher education" 10 "other" 14 "pesantren (islamic school)" .d "don't know" .m "missing"
label val educ_level educ_level
***************************************************************************************
* Create years of educ variable      ***************************************************************************************
/*
	Finally, we're going to be creating our educ variable, "years of education".
	We'll be using two existing variables to create educ:
	- evschl, "have you ever went to school/are you currently going to school?"
	- ar16, "HH member highest level of educ"
	- ar17, "Highest grade completed"
	
	To create the educ variable, the number of years required to complete each 
	stage of education must be clear. 
	Thus, here are the years required to complete each stage of education, 
	according to the values of ar16:
		- "02. Elem"
			- 6 years
		- "03. Gen JrHi", "04. Voc JrHi", "12. Adlt Ed B"
			- 3 years
		- "5:Gen SrHi", "6:Voc SrHi"
			- 3 years
	From here, a student advancing beyond high school is faced with two 
	choices: They can attend either "07. Dipl(1/2)"/"08. Dipl(3)" or 
	University: 
	these are two distinct tracks.
		- "07. Dipl(1/2)" as well as "08. Dipl(3)". Thus, these variables are 
		essentially treated as the same.
			- 2 years
	
	The University track poses a particular problem: IFLS2, unlike subsequent 
	waves, doesn't differentiate between the three levels of university: 
	undergrad (4 years), master's (2 years), and doctor (4 years). Thus, we 
	have to make an assumption to code educ based on IFLS's data: we assume 
	that any student that has graduated from university merely completed 
	undergrad, or accrued four years of education. Students currently in 
	university with ar17>4 will obviously have that coded as the number of 
	years they've spent in university.
	Thus:
		- "09. Univ"
			- 4 years
			
	The following is another assumption made:
	- A student at one point in the 'flow' of education is assumed to have 
	completed all years of education prior in the track. 
		For example, a student in the second year of high school is assumed to 
		have completed the first year of high school, all three years of 
		junior high, and all six years of kindergarten.
*/
	* educ = 0
gen educ = 0 if             evschl == 0 | (ar16==02 & inlist(ar17, 0, 98, 99))                            | ar16 == 90
	* students in elementary school
replace educ = ar17 if      (ar16 == 02 & inrange(ar17, 1, 5))
	* students in junior high
replace educ = 6 if         (ar16 == 02 & inlist(ar17, 6, 7))                                 		 | (inlist(ar16, 3, 4, 12) 										& inlist(ar17, 0, 98, 99))
	* students in senior high
replace educ = 6 + ar17 if  (inlist(ar16, 3, 4, 12) & inrange(ar17, 1, 2))
replace educ = 9 if			(inlist(ar16, 3, 4, 12) & inrange(ar17, 3, 7)) 							  | (inlist(ar16, 5, 6, 15, 74) & inlist(ar17, 0, 98,                            99))
replace educ = 9 + ar17 if	(inlist(ar16, 5, 6) & inrange(ar17, 1, 2))
replace educ = 12 if		(inlist(ar16, 5, 6) & inrange(ar17, 3, 7)) 							  | (inlist(ar16, 07,08,09) & inlist(ar17, 0, 98, 99))
	* students in college ("07. Dipl(1/2)" or "08. Dipl(3)")
replace educ = 13 if		(inlist(ar16, 07, 08) & ar17 == 1)
replace educ = 14 if 		(inlist(ar16, 07, 08) & inrange(ar17, 2, 7))
	* students in university
replace educ = 12 + ar17 if ar16 == 9 & inrange(ar17, 1, 6)
replace educ = 16 if        ar16 == 9 & ar17==7
	* misc.
replace educ = .m if 		educ == .
	label var educ "years of education"
	label def years .d "don't know" .m "missing", replace
	label val educ years
save `hh_status', replace
***************************************************************************************
* Generating a mother educ and pidlink variable
***************************************************************************************
drop mom_pid97
rename (evschl educ_level educ pid97 pidlink) (evschl_mom educ_level_mom educ_mom mom_pid97 mom_pidlink) 

keep hhid97 evschl_mom educ_level_mom educ_mom mom_pid97 mom_pidlink
		duplicates report hhid97 mom_pid97
	merge 1:m hhid97 mom_pid97 using `hh_status'
		drop if _merge == 1
			drop _merge
keep pidlink pid97 hhid97 hhid97 evschl_mom educ_level_mom educ_mom mom_pid97 mom_pidlink
***************************************************************************************
* Finish Up [mother_char dataset]
***************************************************************************************
local tag 03_ifls2_parental_educ.do
foreach v in evschl_mom educ_level_mom educ_mom mom_pid97 mom_pidlink {
	notes `v': `tag'
}
	compress
	label data "ifls2 mother educational characteristics"
		cd "$clean/ifls2_hh"
			save ifls2_mother_educ, replace
***************************************************************************************
* Generating a head of household educ variable
***************************************************************************************
use `hh_status', clear
	keep if hh == 1
rename (evschl educ_level educ) (evschl_hh educ_level_hh educ_hh)
	label var evschl_hh "has household head gone to school/goes to school now?"
	label var educ_level_hh "highest education lvl of household head"
	label var educ_hh "yrs of education of household head"
***************************************************************************************
* Finish Up 
***************************************************************************************
foreach v in evschl_hh educ_level_hh educ_hh {
	notes `v': `tag'
}
	compress
	label data "ifls2 household head educational characteristics"
keep hhid97 evschl_hh educ_level_hh educ_hh
	cd "$clean/ifls2_hh"
	save ifls2_hh_head_educ, replace

/*
log close
exit
*/









