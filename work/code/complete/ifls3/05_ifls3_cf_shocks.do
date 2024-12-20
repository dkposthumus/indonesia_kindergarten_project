/*
capture log close
log using 05_ifls3_cf_shocks, replace text
*/

/*
  program:    	05_ifls3_cf_shocks.do
  task:			To create a set of variables capturing community-level shocks in the 
				IFLS3 survey.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 19Feb2024
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
* Pull basic shocks data           ***************************************************************************************
cd "$raw/ifls3_cf"
	use bk1_e2, clear
* We can drop unhelpful variables: 
drop module e10b e11x e2type
* Note I'm dropping e10b, "impact of event on the population" -- I am already dropping all types of positive events. I am assuming that events categorized as natural disasters did NOT have a positive impact on the village's population.

* Our first step is to reshape wide; before doing so, we need to define the locals that we'll use to label the variables upon reshaping
local 1 "fire" 
local 2 "flood"
local 3 "earthquake"
local 5 "drought"
local 6 "famine"
local 7 "opening new firm" 
local 8 "opening new road"
local 9 "construction of new road" 
local 10 "construction of new health facilities" 
local 11 "construction of new school" 
local 12 "epidemic" 
local 13 "other" 
local 14 "crop failure" 
local 15 "construction of clean water facility" 
local 16 "typhoon"
local 17 "construction project" 
local 18 "construction of economic institution" 
local 19 "construction of telephone net" 
local 20 "disturbance or riot" 
local 21 "migration" 
local 22 "store relocation" 
* We're interested in SHOCKS, and clearly not all these observations are shocks. Therefore I'm going to drop the unnecessary observations of important events. Additionally, I'm dropping all observations with a missing type of important event, since those observations contain no information that I can use.
drop if e10evt == 7 | e10evt == 8 | e10evt == 9 | e10evt == 10 | e10evt == 11 | e10evt == 13 | e10evt == 15 | e10evt == 18 | e10evt == 19 | e10evt == 21 | e10evt == 22 | e10evt == 99
* I want to start with a panel dataset.
rename (e10a e10evt e11) (year shock_type pop_affected)
* First -- is this more complex sort of data cleaning even necessary?
duplicates report commid00 year
* Yes it is -- let's define our new variables of interest and code them.
gen num_shock = 1
* We have a problem, however: there are no observations for years with no shocks; however, we need variation in this variable if we're going to use it in analysis. Therefore, we have to create 'empty' years and fill in 0s. Before doing this, however, I want to make our data more precious: about 88% of the shocks of this data are between 1997 and 2000--or since the previous wave of the IFLS. Let's only keep those.
drop if year == 1994 | year == 1995 | year == 1996
* Let's collapse our variables of interest:
collapse (sum) num_shock pop_affected, by(commid00 year)
	label var num_shock "number of shocks in given community and year" 
	label var pop_affected "total pop. (%) affected by shocks in given comm. and year"
* Now let's fill in w/empty observations. This process will be complex, and will require the creation of a tempfile. Bear with me.
* Generate a list of unique communities
levelsof commid00, local(communities)
* Generate a list of years you're interested in
local years 1997 1998 1999 2000
	tempfile master
		save `master'
clear 
tempfile append_master
	set obs 0
	gen commid00 = ""
	gen year = .
save `append_master'
* Create and append individuall these datasets using the following loop:
foreach year in `years' {
    foreach community in `communities' {
       	clear
			tempfile temp
			set obs 1
				di `year'
					gen year = `year'
				di "`community'"
					gen commid00 = "`community'"
			save `temp', replace
		use `append_master', clear
			append using `temp'
				save `append_master', replace
    }
}
use `append_master'
	merge 1:1 commid00 year using `master'
		keep if _merge == 1 | _merge == 3
			drop _merge
sort commid00 year
foreach v in num_shock pop_affected {
	replace `v' = 0 if `v' == .
}
bysort commid00 year: gen dummy_shock = 1 if num_shock > 0
	replace dummy_shock = 0 if dummy_shock == .
	label var dummy_shock "did any shock occur in given year in given community"
* Now let's finally reshape wide:
reshape wide num_shock pop_affected dummy_shock, i(commid00) j(year)
***************************************************************************************
* Finish Up 
***************************************************************************************
	local tag 05_ifls3_cf_shocks.do
foreach n in 1997 1998 1999 2000 {
		foreach v in num_shock pop_affected dummy_shock {
			notes `v'`n': `tag'
	}
}

label data "ifls3 community shocks"
compress
	cd "$clean/ifls3_cf"
	save ifls3_cf_shocks, replace
/*
log close
exit
*/









