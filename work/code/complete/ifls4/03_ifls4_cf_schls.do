/*
capture log close
log using 03_ifls4_cf_schls, replace text
*/

/*
  program:    	03_ifls4_cf_schls.do
  task:			To create a set of variables capturing the prevalence of schools in 
				communities in 2007, during the time of the ifls4 survey.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
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
cd "$raw/ifls4_cf"
	use bk1_i, clear
		tempfile basic_schools
	* Immediately we know that we're going to have to reshape; before doing so, let's properly label the itype variable and create a set of locals:
	local A "elementary school"
		local AA elem
	local B "junior high school"
		local BB junior
	local C "senior high school"
		local CC senior
* Now we want to change the values for the 'x' variables, to be more intuitive:
foreach v in i13 {
	replace `v' = .m if `v'x == 9
	replace `v' = .d if `v'x == 8
		* Now we can drop them:
		drop `v'x
}
* Finally we can reshape:
reshape wide i13, i(commid07) j(itype) string
* Let's rename variables using the loop and locals we defined previously:
foreach v in A B C {
	label var i13`v' "# of ``v'' used by population (2007)"
		rename i13`v' num_``v'`v''_07
}
	save `basic_schools'
***************************************************************************************
* Pull population size            ***************************************************************************************
* But this isn't all that detailed; we don't know how many people live in the village, the size of these schools, etc. So let's bring in the population size for these villages to create a persons-per-school variable.
	use bk2, clear
keep commid07 s31a s31b s31c 
* First, there are some random duplicate observations w/all variables missing; let's drop those.
drop if s31a == . & s31b == . & s31c == .
	 * Let's rename our variables quickly using a loop w/locals:
		local a total
		local b male
		local c female
	foreach v in a b c {
		rename s31`v' ``v''_pop_07
			label var ``v''_pop_07 "``v'' population (2007)"
	}
* Now do a quick check if commid97 is a unique identifier:
isid commid07
* It is! so we can merge 1:1 using our `basic_schools' data:
merge 1:1 commid07 using `basic_schools'
	keep if _merge == 3
		drop _merge 
* Now we want to generate our persons-per-school variable for each level:
	local elem "Elementary School"
	local junior "Junior High School"
	local senior "Senior High School"
foreach v in elem junior senior {
	* First, let's create our basic per-person variable.
	gen `v'_per_person_07 = (num_`v'_07 / total_pop_07)
		label var `v'_per_person_07 "``v'' per-person in village"
		* That isn't very helpful. So let's create a per-10,000 person varible:
			gen `v'_per_10000_07 = `v'_per_person_07*10000
				label var `v'_per_10000_07 "``v'' per 10,000 people in village"
	* Then let's put all of these on scatterplots:
	scatter `v'_per_10000_07 total_pop_07, name(`v'_sct) title("``v'' Per 10,000 People") ytitle("") xtitle("Total Population of Village") nodraw
		qui sum `v'_per_person
	* Now let's put all of these on histograms:
	hist `v'_per_10000_07, title("``v'' Per 10,000 People" "In Village") xline(`r(mean)') name(`v'_hist) percent nodraw
}
* Let's first combine our scatterplots.
graph combine elem_sct junior_sct senior_sct, title("Schools Per 10,000 People and Total Population of Village")
* Then let's combine our histograms.
graph combine elem_hist junior_hist senior_hist, title("Schools Per 10,000 People")
***************************************************************************************
* Finish Up 
***************************************************************************************
	local tag 03_ifls4_cf_schls.do
foreach v in total_pop_07 male_pop_07 female_pop_07 {
	notes `v': `tag'
}
foreach v in elem junior senior {
		* Let's just drop the per-person variables so they don't clutter our data.
			drop `v'_per_person_07
	notes num_`v'_07 : `tag'
	notes `v'_per_10000_07 : `tag'
}
label data "ifls4 presence of schools in community"
compress
	cd "$clean/ifls4_cf"
	save ifls4_cf_schools, replace
/*
log close
exit
*/









