* capture log close
* log using hh_education_variable, replace text

//  program:    01_hh_education_variable.do
//  task:		creating an education variable with the ifls5 data
//  project:	IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
//  author:     Daniel_Posthumus \ 04/12/2023

version 10
clear all
set linesize 80
macro drop _all

local data_clean "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Data_Clean/hh_14_data"

cd "`data_clean'"

* We are seeking to create our years_of_education variable from variables 	included in the b3a_dl1 datafile.
use ifls5_b3a_dl1, clear

* merge with household-identifying dataset, ifls5_b3a_cov
merge 1:1 hhid14_9 pid14 using ifls5_b3a_cov
* We want to remove those households missing their hhid from the general dataset, 		so we only keep those households that are matching according to both our criteria (hhid14_9 as well as pid14).
keep if _merge == 3
drop _merge
*******************************************************************************Generating a the variable evschl, "Have you ever attended/are you 			attending school?"
*******************************************************************************

* We want to start w/ dl04=3, that is a "no" and if dl04=1, that is a "yes". 
recode dl04 (3 = 0) (1 = 2), gen(evschl)
tab dl04
* What to do with missing observations? (dl04 = 8).
tab evschl
* Recall that dl07a tells us if the respondent is currently attending school, 			we can build this into our evschl variable.
replace evschl = 1 if dl07a == 1
lab var evschl "Have you ever went to school/are you currently going to school?"
lab def evschl 0 "Never have went to school" 1 "Currently going to school" ///
	2 "Have went to school" 8 "Missing"
numlabel evschl, mask(#_) add force
lab val evschl evschl

*******************************************************************************Generating a the variable educ_level
*******************************************************************************

* The possible values are: 
* "No schooling/not finished primary school", "Primary school/equivalent", 			"Junior high school/equivalent", "Senior high school/equivalent", 					"Higher education", "Other", "Pesantren", and "School for disabled". 				We're going to work with our existing variables to create these categories.
tab dl06 dl07
* We start w/the most obvious: education level = 0 if respondent has never 		attended school.
gen educ_level = 0 if evschl == 0
tab educ_level

* The other scenarios are for if a respondent has only gone to kindergarten or had not graduated from primary school yet. 
* Note we apply educ_level to three types of non-graduated students: students who haven't graduated from "elementary school" (dl06 = 2), "Islamic elementary school" (dl06 = 72), and "adult education a" (dl06 = 11).
replace educ_level = 0 if dl06 == 90
replace educ_level = 0 if dl06 == 2 & dl07 < 7 | dl07 >= 98
replace educ_level = 0 if dl06 == 72 & dl07 < 7 | dl07 >= 98
replace educ_level = 0 if dl06 == 1 & dl07 < 7 | dl07 >= 98
* Now we have taken care of the cases falling into educ_level = 0.

* Next, we want to create educ_level=1, or "primary school/equivalent". 
* These are the following possibilites: 
* graduating from elementary school/adult education a/Islamic elementary
* having incompleted junior high/adult education b/Islamic junior high 
 
replace educ_level = 1 if (inlist(dl06, 2, 11, 72) & dl07 == 7 | 							inlist(dl06, 3, 4, 12, 73) & (dl07 < 7 | dl07 >= 98))

/* Next, we want to create educ_level=2, or "Junior high school/equivalent"
These are the following possibilities:
- graduating from junior high school/adult education b/Islamic junior high
- having incompleted senior high/adult education c/Islamic senior high s*/
replace educ_level = 2 if (inlist(dl06, 3, 4, 12, 73) & dl07==7 | 							inlist(dl06, 5, 6, 15, 74) & (dl07 < 7 | dl07 >= 98))

* Next, we want to create educ_level=3, or "Senior high school/equivalent"
* These are the following possibilities:
* graduating from senior high/adult education c/Islamic senior high
* having incompleted...open university, college, and university S1
replace educ_level = 3 if (inlist(dl06, 5, 6, 15, 74) & dl07==7 | 							inlist(dl06, 13, 60, 61) & (dl07 < 7 | dl07 >= 98))

* Next, we want to create educ_level=4, or "Higher education"
* These are the following possibilities:
* having graduated from open university, college, university S1, university S2, or university S3
* Having incompleted university s2 or university s3
replace educ_level = 4 if (inlist(dl06, 13, 60, 61, 62, 63) & dl07== 7 						| inlist(dl06, 62, 63) & (dl07 < 7 | dl07 >= 98))
* Our next categories are a bit tricky and more specific. 
* First, let's code educ_level=17 as "School for Disabled"
replace educ_level = 17 if dl06 == 17
* Let's also code educ_level = 10 as "Other"
replace educ_level = 10 if dl06 == 95
* Let's code "pesantren [Islamic school]" as educ_level = 14
replace educ_level = 14 if dl06 == 14
* We can't forget our missing values.
replace educ_level = .d if dl06 == 98
replace educ_level = .m if dl06 == 99
replace educ_level = .m if educ_level == .
* Now let's label the values and check the variable to make sure it has values for every observation:
lab def educ_level 0 "No schooling/not finished primary school" 1 "Primary school/equivalent" 2 "Junior high school/equivalent" 3 "Senior high school/equivalent" 	4 "Higher education" 10 "Other" 14 "Pesantren" 17 "School for disabled"
numlabel educ_level, mask(#_) add force
lab val educ_level educ_level
tab educ_level, m // confirmed: 34,464 observations
tab dl06, m // confirmed: 34,464 observations

*******************************************************************************Generating a the variable educ, or years of education 
*******************************************************************************

* First, for educ = 0, there are a few possibilities:
* Never attended school
* Highest level of school attended was kindergarten
* Didn't complete first grade, don't know, or missing at primary school level
gen educ = 0 if evschl == 0 | (inlist(dl06, 2, 72, 11) & inlist(dl07, 0, 98, 99)) 			| dl06 == 90
tab educ, m
* Next, for educ = dl07:
* student is currently in primary school, and only primary school
replace educ = dl07 if (inlist(dl06, 2, 11, 72) & inrange(dl07, 1, 5))
* Next, for educ = 6:
* student has graduated primary school (and primary school is their highest level of schooling--not that primary school has 6 years, since dl07 = 6 and dl07 = 7 are de-facto the same for primary school), student has not started junior high/missing/don't know re: junior high
replace educ = 6 if (inlist(dl06, 2, 11, 72) & inlist(dl07, 6, 7)) | 						(inlist(dl06, 3, 4, 12, 73) & inlist(dl07, 0, 98, 99))
* rest of the generation of the variable educ follows this pattern:
replace educ = 6 + dl07 if	(inlist(dl06, 3, 4, 12, 73) & inrange(dl07, 1, 2))
replace educ = 9 if			(inlist(dl06, 3, 4, 12, 73) & inrange(dl07, 3, 7)) 				| (inlist(dl06, 5, 6, 15, 74) & inlist(dl07, 0, 98, 99))
replace educ = 9 + dl07 if	(inlist(dl06, 5, 6, 15, 74) & inrange(dl07, 1, 2))
replace educ = 12 if		(inlist(dl06, 5, 6, 15, 74) & inrange(dl07, 3, 7)) 				| (inlist(dl06, 60, 61, 13) & inlist(dl07, 0, 98, 99))
replace educ = 13 if		(inlist(dl06, 60) & dl07 == 1)
replace educ = 14 if 		(inlist(dl06, 60) & inrange(dl07, 2, 7))
replace educ = 12 + dl07 if (inlist(dl06, 61, 13) & inrange(dl07, 1, 3))
replace educ = 16 if 		(inlist(dl06, 61, 13) & inrange(dl07, 4, 7)) | 					(inlist(dl06, 62) & inlist(dl07, 0, 98, 99))
replace educ = 17 if 		(inlist(dl06, 62) & dl07 == 1)
replace educ = 18 if 		(inlist(dl06, 62) & inrange(dl07, 2, 7)) | 						(inlist(dl06, 63) & inlist(dl07, 0, 98, 99))
replace educ = 18 + dl07 if	(inlist(dl06, 63) & inrange(dl07, 1, 3))
replace educ = 22 if		(inlist(dl06, 63) & inrange(dl07, 4, 7))
replace educ = .d if 		dl06 == 98
replace educ = .m if		inlist(educ_level, 7, 10, 14, 17) | dl06 == 99
replace educ = .m if 		educ == .
label var educ "Years of education"


local tag 01_hh_education_variables_ifls5.do
foreach v in educ educ_level evschl {
	notes `v': `tag'
}
compress
save ifls5_b3a_dl1_educ, replace

* log close
* exit
