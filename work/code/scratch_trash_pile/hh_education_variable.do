clear
cap log close
cap program drop _all
set more 1
set mem 500m
set matsize 150

* Household Survey, Creating Years of Education Variable
* Daniel Posthumus
* Last Edited: February 25, 2023

cd "/Users/danielposthumus/Documents/IFLS5/Data/cleaned/hh_data"

* We are seeking to create our years_of_education variable from variables included in the b3a_dl1 datafile.

use ifls5_b3a_dl1, clear
* merge with household-identifying dataset, ifls5_b3a_cov
merge 1:1 hhid14_9 pid14 using ifls5_b3a_cov
* We want to remove those households missing their hhid from the general dataset, so we only keep those households that are matching according to both our criteria (hhid14_9 as well as pid14).
keep if _merge == 3

* First, we're going to deal with dl04, "Have you ever attended/are you attending school?" Right now, if dl04=3, that is a "no" and if dl04=1, that is a "yes". 
recode dl04 (3 = 0) (1 = 2), gen(evschl)
tab dl04
* What to do with missing observations? (dl04 = 8).
tab evschl
* Recall that dl07a tells us if the respondent is currently attending school, we can build this into our evschl variable.
replace evschl = 1 if dl07a == 1
lab var evschl "Have you ever went to school/are you currently going to school?"
lab def evschl 0 "Never have went to school" 1 "Currently going to school" 2 "Have went to school" 8 "Missing"
* It's unclear to me what this next command does exactly...why do we list the variable twice? 
lab val evschl evschl

* Now let's turn our attentino to variables dl06 ("What is the highest education level attended?").
tab dl06



* We're going to use the highest education level attended as a starting point;
* According to this source, https://sites.miis.edu/educationinindonesia/51-2/#:~:text=Education%20is%20compulsory%20for%20the,upon%20completion%20at%20nearly%20100%25., the respective years of each level of schooling are the following:
* kindergarten - 3 years 
* primary - 6 years
* junior secondary general/vocational - 3 years
* senior general/vocational - 3 years 
* We assume that a student has attended all compulsory years below their level of highest attainment (note kindergarten is NOT compulsory). For example, a student whose highest education level attained is senior general is considered to have completed AT LEAST 8 years of schooling (the sum of the lengths of primary and junior secondary schools).
* Added to this minimum is their response to dl07, "What is the highest grade completed at that school?"
* Additionally, if a student answered yes to dl05b ("Did you attend a kindergarten?"), then 3 years are added to their years_of_education variable.

* Thus first we want to create a new variable that transforms dl06 into our 'minimum' years of education (note that for those whose highest level of educational attainment was kindergarten we coded them at 0, since we're adding the kindergarten years later).
gen min_years_of_education = 0 if dl06==02
replace min_years_of_education = 6 if dl06==03 | dl06==04
replace min_years_of_education = 9 if dl06==05 | dl06==06 | dl06==74
replace min_years_of_education = 0 if dl06==90
summarize min_years_of_education, detail

* We next want to create a variable used to stand-in for kindergarten
gen years_kindergarten = 3 if dl05b==1
replace years_kindergarten = 0 if dl05b==3
summarize years_kindergarten, detail

* Next we'll create our last determinant of years_of_education, years_highest_grade, derived from dl07. This variable is a bit tricky; all categories except for 'graduated' are quite simple. If a student attended one year of primary school, it's coded as 01 and we can leave it be. If a student attended one year of junior high, it's coded as 01 and treated the same. However, a student having graduated junior high denotes a different amount of years of education than a student having graduated primary school.
* First we can start by generating the variable to be equial to the value of dl07 for all values except 07, which denotes graduation.
gen years_highest_grade = dl07 if dl07 == 00 | dl07==01 | dl07==02 | dl07==03 | dl07==04 | dl07==05 | dl07==06
* Here we just have to manually code for the different levels of education attainment:
replace years_highest_grade = 6 if dl06==02 & dl07==07
replace years_highest_grade = 3 if dl07==07 & dl06==03 | dl06==04 | dl06==05 | dl06==06 | dl06==74

* Finally we can generate years_of_education by summing our previously-generated variables:
gen years_of_education = min_years_of_education + years_kindergarten + years_highest_grade
summarize years_of_education, detail

save ifls5_b3a_dl1, clear
