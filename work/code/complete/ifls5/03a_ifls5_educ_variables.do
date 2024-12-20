/*
capture log close
log using 03a_ifls5_educ_variables, replace text
*/

/*
  program:    	03a_ifls5_educ_variables.do
  task:			To create a set of education variables for the use of our 
				descriptive statistics exploratory work: years of education, 
				highest of level of education attended, and if they have ever 
				attended school.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 20July2023
*/

version 17
clear all
set linesize 80
macro drop _all

*******************************************************************************************
* Set Global Macros              *******************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~/thesis_independent_study/work/code/complete"
*******************************************************************************************
* Create the evschl variable *******************************************************************************************
cd "$clean/ifls5_hh"
use ifls5_kinder_variables, clear
/*
	First, we'll create the variable evschl, "have you never went to 
	school/are you currently going to school?" 
	We'll use two existing variables to create this variable: 
	- dl04, "Have you ever attended/are you attending school?"
	- dl07a, "Are you currently attending school?"
	
	evschl can assume the following values:
		- 0 "never have went to school"
			- dl04 = 3 ("3:No")
		- 1 "currently going to school"
			 - dl07a = 1 ("1:Yes")
		- 2 "have went to school"
			- dl04 = 1 ("1:Yes") & dl07a != 1 ("1:Yes")
		- .m "missing"
			- dl04 = 8 ("8:MISSING")
			- dl04 = .
*/
tab dl04, m
gen evschl14 = 0 if dl04 == 3
replace evschl14 = 2 if dl04 == 1
replace evschl14 = 1 if dl07a == 1
replace evschl14 = .m if dl04 == . | dl04 == 8
tab dl04 evschl14, m 
lab var evschl14 "have you ever went to school/are you currently going to school?"
lab def evschl14 0 "never have went to school" 1 "currently going to school" 2 "have went to school" .m "missing"
numlabel evschl14, mask(#_) add force
lab val evschl14 evschl14

*******************************************************************************************
* Generating a the variable educ_level *******************************************************************************************
/*
	Next, we're going to create the variable educ_level "highest level of 
	education attended"
	We'll use two existing variables to create this variable: 
	- evschl, 'have you ever went to school/are you currently going to school?'
	- dl06, "Highest level of education attended"
	- dl07, "What is the highest grade completed at that school?"
	
	educ_level can assume the following values:
		- 0 "no schooling/not finished primary school"
			- evschl = 0 ("0_no")
			- dl06 = 90 ("90:Kindergarten")
			- dl06 = 2 ("2:Elementary school") & dl07 != 7 ("7:Graduated")
			- dl06 = 72 ("72:Islamic Elementary School (Madrasah)") & != 7 
			("7:Graduated")
		- 1 "primary school/equivalent"
			- dl06 = 2 ("2:Elementary school") & dl07 = 7 ("7:Graduated")
			- dl06 = 11 ("11:Adult education A") & dl07 = 7 ("7:Graduated")
			- dl06 = 72 ("Islamic Elementary School (Madrasah)") & dl07 = 7 
			("7:Graduated")
			- dl06 = 3 ("3:Junior high general") & dl07 != 7 ("7:Graduated")
			- dl06 = 4 ("4:Junior high vocational") & dl07 != 7 ("7:Graduated")
			- dl06 = 12 ("12:Adult education B") & dl07 != 7 ("7:Graduated")
			- dl06 = 73 ("Islamic Junior/High School (Madrasah)") & dl07 != 7 
			("7:Graduated")
		- 2 "junior high school/equivalent"
			- dl06 = 3 ("3:Junior high general") & dl07 = 7 ("7:Graduated")
			- dl06 = 4 ("4:Junior high vocational") & dl07 = 7 ("7:Graduated")
			- dl06 = 12 ("12:Adult education B") & dl07 = 7 ("7:Graduated")
			- dl06 = 73 ("Islamic Junior/High School (Madrasah)") & dl07 != 7 
			("7:Graduated")
			- dl06 = 5 ("5:Senior high general") & dl07 != 7 ("7:Graduated")
			- dl06 = 6 ("Senior high vocational") & dl07 != 7 ("7:Graduated")
			- dl06 = 15 ("Adult education C") & dl07 != 7 ("7:Graduated")
			- dl06 = 74 ("Islamic Senior/High School (Madrasah)") & dl07 != 7 
			("7:Graduated")
		- 3 "senior high school/equivalent"
			- dl06 = 5 ("5:Senior high general") & dl07 = 7 ("7:Graduated")
			- dl06 = 6 ("Senior high vocational") & dl07 = 7 ("7:Graduated")
			- dl06 = 15 ("Adult education C") & dl07 = 7 ("7:Graduated")
			- dl06 = 74 ("Islamic Senior/High School (Madrasah)") & dl07 = 7 
			- dl06 = 13 ("Open university") & dl07 != 7 ("7:Graduated")
			- dl06 = 60 ("College (D1,D2,D3)") & dl07 != 7 ("7:Graduated")
			- dl06 = 61 ("University S1") & dl07 != 7 ("7:Graduated")
		- 4 "higher education"
			- dl06 = 13 ("Open university") & dl07 = 7 ("7:Graduated")
			- dl06 = 60 ("College (D1,D2,D3)") & dl07 = 7 ("7:Graduated")
			- dl06 = 61 ("University S1") & dl07 = 7 ("7:Graduated")
			- dl06 = 62 ("University S2")
			- dl06 = 63 ("University S3")
		- 10 "other"
			- dl06 = 95 ("95:Other")
		- 14 "pesantren"
			- dl06 = 14 ("14:Islamic School (pesantren)")
		- 17 "school for disabled"
			- dl06 = 17 ("17:School for Disabled")
		- .d "don't know"
			- dl06 = 98 ("98:Don't know"
		- .m "missing"
			- dl06 = 99 ("99:MISSING")
			- educ_level = . (after all other rules have been coded)
*/

tab dl06, m
tab dl07, m
tab evschl14, m

	* educ_level = 0
gen educ_level14 = 0 if evschl == 0 | dl06 == 90 | dl06 == 2 & dl07 != 7 | dl06        == 72 & dl07 != 7
 
	* educ_level = 1
replace educ_level14 = 1 if inlist(dl06, 2, 11, 72) & dl07 == 7 | inlist(dl06, 	   3, 4, 12, 73) & dl07 != 7

	* educ_level = 2
replace educ_level14 = 2 if inlist(dl06, 3, 4, 12, 73) & dl07==7 | inlist(dl06, 		5, 6, 15, 74) & dl07!= 7

	* educ_level = 3
replace educ_level14 = 3 if inlist(dl06, 5, 6, 15, 74) & dl07==7 | inlist(dl06, 		13, 60, 61) & dl07 != 7

	* educ_level = 4
replace educ_level14 = 4 if inlist(dl06, 13, 60, 61) & dl07== 7 | inlist(dl06, 			62, 63)

	* misc.
replace educ_level14 = 17 if dl06 == 17
replace educ_level14 = 10 if dl06 == 95
replace educ_level14 = 14 if dl06 == 14
replace educ_level14 = .d if dl06 == 98
replace educ_level14 = .m if dl06 == 99
replace educ_level14 = .m if educ_level == .

label var educ_level14 "highest level of education attended"
lab def educ_level14 0 "no schooling/not finished primary school" 1 "primary school/equivalent" 2 "junior high school/equivalent" 3 "senior high school/equivalent" 	4 "higher education" 10 "other" 14 "pesantren" 17 "school for disabled" .d "don't know" .m "missing"

numlabel educ_level14, mask(#_) add force
lab val educ_level14 educ_level14

tab educ_level14, m

*******************************************************************************************
* Generating a the variable educ, or years of education *******************************************************************************************
/*
	Finally, we're going to be creating our educ variable, "years of education".
	We'll be using two existing variables to create educ:
	- evschl, "have you ever went to school/are you currently going to school?"
	- dl06, "Highest level of education attended"
	- dl07, "What is the highest grade completed at that school?"
	
	To create the educ variable, the number of years required to complete each 
	stage of education must be clear. 
	Thus, here are the years required to complete each stage of education, 
	according to the values of dl06:
		- "2:Elementary school", "11:Adult Education A", "72:Islamic 
		Elementary School (Madrasah)"
			- 6 years
		- "3:Junior high general", "4:Junior high vocational", "12:Adult 
		education B", "73:Islamic Junior/High School (Madrasah)"
			- 3 years
		- "5:Senior high general", "6:Senior high vocational", "15:Adult 
		education C", "74:Islamic Senior/High School (Madrasah)"
			- 3 years
	From here, a student advancing beyond high school is faced with two 
	choices: They can attend either "60:College (D1,D2,D3)" or University: 
	these are two distinct tracks.
		- "60:College (D1,D2,D3)"
			- 2 years
		- "61:University S1"
			- 4 years
		- "62:University S2"
			- 2 years
		- "63: University S3"
			- 4 years
	The following is assumed:
	- A student at one point in the 'flow' of education is assumed to have 
	completed all years of education prior in the track. 
		- This includes the three stages of college (a PhD student is assumed 
		to have taken four years to complete their undergraduate career and 
		two years to complete their master's degree).
		For example, a student in the second year of high school is assumed to 
		have completed the first year of high school, all three years of 
		junior high, and all six years of kindergarten.
*/

	* educ = 0
gen educ14 = 0 if evschl14 == 0 | (inlist(dl06, 2, 72, 11) & inlist(dl07, 0, 98, 99								)) | dl06 == 90

	* students in elementary school
replace educ14 = dl07 if (inlist(dl06, 2, 11, 72) & inrange(dl07, 1, 5))
replace educ14 = 6 if (inlist(dl06, 2, 11, 72) & inlist(dl07, 6, 7)) | 							(inlist(dl06, 3, 4, 12, 73) & inlist(dl07, 0, 98, 							  99))

	* students in junior high
replace educ14 = 6 + dl07 if	(inlist(dl06, 3, 4, 12, 73) & inrange(dl07, 1, 2))
replace educ14 = 9 if			(inlist(dl06, 3, 4, 12, 73) & inrange(dl07, 3, 7)) 							| (inlist(dl06, 5, 6, 15, 74) & inlist(dl07, 0, 98, 							99))

	* students in senior high
replace educ14 = 9 + dl07 if	(inlist(dl06, 5, 6, 15, 74) & inrange(dl07, 1, 2))
replace educ14 = 12 if		(inlist(dl06, 5, 6, 15, 74) & inrange(dl07, 3, 7)) 							| (inlist(dl06, 60, 61, 13) & inlist(dl07, 0, 98, 99))

	* students in college(D1,D2,D3)
replace educ14 = 13 if		(inlist(dl06, 60) & dl07 == 1)
replace educ14 = 14 if 		(inlist(dl06, 60) & inrange(dl07, 2, 7))

	* students in university (S1)
replace educ14 = 12 + dl07 if (inlist(dl06, 61, 13) & inrange(dl07, 1, 3))
replace educ14 = 16 if 		(inlist(dl06, 61, 13) & inrange(dl07, 4, 7)) | 							  (inlist(dl06, 62) & inlist(dl07, 0, 98, 99))

	* students in university (S2)
replace educ14 = 17 if 		(inlist(dl06, 62) & dl07 == 1)
replace educ14 = 18 if 		(inlist(dl06, 62) & inrange(dl07, 2, 7)) | 							  (inlist(dl06, 63) & inlist(dl07, 0, 98, 99))

	* students in university (S3)
replace educ14 = 18 + dl07 if	(inlist(dl06, 63) & inrange(dl07, 1, 3))
replace educ14 = 22 if		(inlist(dl06, 63) & inrange(dl07, 4, 7))

	* misc.
replace educ14 = .d if 		dl06 == 98
replace educ14 = .m if		inlist(educ_level14, 7, 10, 14, 17) | dl06 == 99
replace educ14 = .m if       educ14 == .

label def years .d "don't know" .m "missing", replace
label val educ14 years
label var educ14 "years of education"

*******************************************************************************************
* Create Education Dummy Variables *******************************************************************************************
* Now we want to create education dummy variables for the three key levels of education. We're simply going to use our years of education + our assumption that a student at one point in the 'flow' of the educational system has completed all previous grades/steps.
gen elem_completion = 0
	label var elem_completion "completed elementary (dummy)"
		replace elem_completion = 1 if educ14 >= 6
gen junior_completion = 0 
	label var junior_completion "completed junior high (dummy)"
		replace junior_completion = 1 if educ14 >= 9
gen senior_completion = 0 
	label var senior_completion "completed senior high (dummy)"
		replace senior_completion = 1 if educ14 >= 12
*******************************************************************************************
* Finishing Up *******************************************************************************************
local tag 03a_ifls5_educ_variables.do
foreach v in evschl14 educ_level14 educ14 elem_completion junior_completion senior_completion {
	notes `v': `tag'
}
keep hhid14_9 pidlink pid14 kinder_ever kinder_age evschl14 educ_level14 educ14 elem_completion junior_completion senior_completion

label data "ifls5 educational variables"
compress

save ifls5_educ_variables, replace

/*
log close
exit
*/









