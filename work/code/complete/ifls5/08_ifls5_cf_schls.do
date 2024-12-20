/*
capture log close
log using 08_ifls5_cf_schls, replace text
*/

/*
  program:    	08_ifls5_cf_schls.do
  task:			To create a set of variables capturing the prevalence of schools in 
				communities in 2014, during the time of the ifls5 survey.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 05Feb2024
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
* Pull basic schools data             ***************************************************************************************
cd "$raw/ifls5_cf"
	use pkk_i, clear
		tempfile basic_schools
	* Immediately we know that we're going to have to reshape; before doing so, let's properly label the itype variable and create a set of locals:
	local A "elementary school"
		local AA elem
	local B "junior high school"
		local BB junior
	local C "senior high school"
		local CC senior
	local A1 "pre elementary school"
		local A1A1 kinder
* Drop our unnecessary variable
drop ea 
* Now we want to change the values for the 'x' variables, to be more intuitive:
foreach v in i13 {
	replace `v' = .m if `v'x == 9
	replace `v' = .d if `v'x == 8
		* Now we can drop them:
		drop `v'x
}
* Finally we can reshape:
reshape wide i13, i(commid14) j(itype) string
* Let's rename variables using the loop and locals we defined previously:
foreach v in A B C A1 {
	label var i13`v' "# of ``v'' used by population (2014)"
		rename i13`v' num_``v'`v''_14
}
	save `basic_schools'
***************************************************************************************
* Pull population size            ***************************************************************************************
* But this isn't all that detailed; we don't know how many people live in the village, the size of these schools, etc. So let's bring in the population size for these villages to create a persons-per-school variable.
	use bk2, clear
keep commid14 s31
* First, there are some random duplicate observations w/all variables missing; let's drop those.
drop if s31 == .
		rename s31 total_pop_14
			label var total_pop_14 "total population (2014)"
* Now do a quick check if commid97 is a unique identifier:
isid commid14
* It is! so we can merge 1:1 using our `basic_schools' data:
merge 1:1 commid14 using `basic_schools'
	keep if _merge == 3
		drop _merge 
* Now we want to generate our persons-per-school variable for each level:
	local elem "Elementary School"
	local junior "Junior High School"
	local senior "Senior High School"
	local kinder "Pre Elementary School"
foreach v in elem junior senior kinder {
	* First, let's create our basic per-person variable.
	gen `v'_per_person_14 = (num_`v'_14 / total_pop_14)
		label var `v'_per_person_14 "``v'' per-person in village"
		* That isn't very helpful. So let's create a per-10,000 person varible:
			gen `v'_per_10000_14 = `v'_per_person_14*10000
				label var `v'_per_10000_14 "``v'' per 10,000 people in village"
	* Then let's put all of these on scatterplots:
	scatter `v'_per_10000_14 total_pop_14, name(`v'_sct) title("``v'' Per 10,000 People") ytitle("") xtitle("Total Population of Village") nodraw
		qui sum `v'_per_person
	* Now let's put all of these on histograms:
	hist `v'_per_10000_14, title("``v'' Per 10,000 People" "In Village") xline(`r(mean)') name(`v'_hist) percent nodraw
}
* Let's first combine our scatterplots.
graph combine elem_sct junior_sct senior_sct, title("Schools Per 10,000 People and Total Population of Village")
* Then let's combine our histograms.
graph combine elem_hist junior_hist senior_hist, title("Schools Per 10,000 People")
***************************************************************************************
* Finish Up 
***************************************************************************************
	local tag 08_ifls5_cf_schls.do
foreach v in total_pop_14 {
	notes `v': `tag'
}
foreach v in elem junior senior kinder { 
		* Let's just drop the per-person variables so they don't clutter our data.
			drop `v'_per_person_14
	notes num_`v'_14 : `tag'
	notes `v'_per_10000_14 : `tag'
}

label data "ifls5 presence of schools in communities"
compress
	cd "$clean/ifls5_cf"
	save ifls5_cf_schools, replace
/*
log close
exit
*/









