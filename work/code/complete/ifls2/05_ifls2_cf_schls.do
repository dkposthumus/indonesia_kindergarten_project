/*
capture log close
log using 05_ifls2_cf_schls, replace text
*/

/*
  program:    	05_ifls2_cf_schls.do
  task:			To create a set of variables capturing the prevalence of schools in 
				communities in 1997, during the time of the ifls2 survey.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 15Jan2024
*/

version 17
clear all
set linesize 80
macro drop _all

***************************************************************************************
* Set Global Macros              ***************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "/Users/danielposthumus/thesis_independent_study/work/data_clean"
	global code "/Users/danielposthumus/thesis_independent_study/work/code/complete"
***************************************************************************************
* Pull basic schools data             ***************************************************************************************
cd "$raw/ifls2_cf"
	use bk1_i, clear
		tempfile basic_schools
	* Immediately we know that we're going to have to reshape; before doing so, let's properly label the itype variable and create a set of locals:
	local A "elementary school"
		local AA elem
	local B "junior high school"
		local BB junior
	local C "senior high school"
		local CC senior
* Now let's drop our unnecessary variables:
drop module bktype 
* Now we want to change the values for the 'x' variables, to be more intuitive:
foreach v in i11 i12 i13 {
	replace `v' = .m if `v'x == 9
	replace `v' = .d if `v'x == 8
		* Now we can drop them:
		drop `v'x
}
* I also don't think i12 is paticularly important; this is information that i11 already tells us! So let's drop it.
drop i12 
* Finally we can reshape:
reshape wide i11 i13, i(commid97) j(itype) string
* Let's rename variables using the loop and locals we defined previously:
foreach v in A B C {
	label var i11`v' "year 1st ``v'' was established in village (1997)"
		rename i11`v' year_1st_``v'`v''_97
	label var i13`v' "# of ``v'' used by population (1997)"
		rename i13`v' num_``v'`v''_97
}
	save `basic_schools'
***************************************************************************************
* Pull population size            ***************************************************************************************
* But this isn't all that detailed; we don't know how many people live in the village, the size of these schools, etc. So let's bring in the population size for these villages to create a persons-per-school variable.
	use bk2, clear
keep commid97 s31a s31b s31c 
	 * Let's rename our variables quickly using a loop w/locals:
		local a total
		local b male
		local c female
	foreach v in a b c {
		rename s31`v' ``v''_pop_97
			label var ``v''_pop_97 "``v'' population (1997)"
	}
* Now do a quick check if commid97 is a unique identifier:
isid commid97
* It is! so we can merge 1:1 using our `basic_schools' data:
merge 1:1 commid97 using `basic_schools'
	keep if _merge == 3
		drop _merge 
* Now we want to generate our persons-per-school variable for each level:
	local elem "Elementary School"
	local junior "Junior High School"
	local senior "Senior High School"
foreach v in elem junior senior {
	* First, let's create our basic per-person variable.
	gen `v'_per_person_97 = (num_`v'_97 / total_pop_97)
		label var `v'_per_person "``v'' per-person in village"
		* That isn't very helpful. So let's create a per-10,000 person varible:
			gen `v'_per_10000_97 = `v'_per_person_97*10000
				label var `v'_per_10000_97 "``v'' per 10,000 people in village"
	* Then let's put all of these on scatterplots:
	scatter `v'_per_10000_97 total_pop_97, name(`v'_sct) title("``v'' Per 10,000 People") ytitle("") xtitle("Total Population of Village") nodraw
		qui sum `v'_per_person
	* Now let's put all of these on histograms:
	hist `v'_per_10000_97, title("``v'' Per 10,000 People" "In Village") xline(`r(mean)') name(`v'_hist) percent nodraw
}
* Let's first combine our scatterplots.
graph combine elem_sct junior_sct senior_sct, title("Schools Per 10,000 People and Total Population of Village")
* Then let's combine our histograms.
graph combine elem_hist junior_hist senior_hist, title("Schools Per 10,000 People")
***************************************************************************************
* Finish Up 
***************************************************************************************
	local tag 05_ifls2_cf_schls.do
foreach v in total_pop_97 male_pop_97 female_pop_97 {
	notes `v': `tag'
}
foreach v in elem junior senior {
	* Let's just drop the per-person variables so they don't clutter our data.
			drop `v'_per_person_97
	notes year_1st_`v'_97 : `tag'
	notes num_`v'_97 : `tag'
	notes `v'_per_10000_97 : `tag'
}
compress
	label data "ifls2 presence of schools in communities"
	cd "$clean/ifls2_cf"
save ifls2_cf_schools, replace
/*
log close
exit
*/









