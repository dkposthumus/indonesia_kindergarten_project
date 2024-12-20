/*
capture log close
log using 04_ifls2_child_health, replace text
*/

/*
  program:    	04_ifls2_child_health.do
  task:			To create a set of child health variables, using the IFLS2 household 	
				survey data.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 04Jan2024
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
* Pull basic child data             ***************************************************************************************
* I'm going to begin by just pulling the 'cov' data for children interviewed--this originates from b5 for the ifls2 household survey.
cd "$raw/ifls2_hh"
use b5_cov, clear
		tempfile b5_cov
			rename age age_97
	keep hhid97 pid97 cp2 cp3 age_97
		rename (cp2 cp3) (resp_accuracy_97 resp_interest_97)
* Now that we have our cover sheet we are going to merely merge all further datasets onto here. 
	* Note that we are NOT keepign pidlink; this is only to streamline our dataflow, since the 'base' of the sample is taken from the household rosters, and that data already includes pidlink for each individual. pid97 and hhid97 suffice for now.

* Before proceeding, we need to check whether hhid97 and pid97 are unique.
isid hhid97 pid97 	
	* They are! Let's proceed.
		save `b5_cov'
***************************************************************************************
* General health status            ***************************************************************************************
* We're going to begin with coding and creating our basic health variables.
use b5_maa0, clear
* Our first variable is going to be general health status, taken from maa0a.
* We also want to take maa0b, which gives us "days missed of primary activity last 4 weeks" due to school -- for children whose primary activity is going to school, this variable is a stand-in for days of school missed due to illness. 
	rename (maa0a maa0b) (general_health_97 schl_miss_sick_97)
		label var general_health_97 "general health status (1997)" 
		label var schl_miss_sick_97 "days of school missed in last 4 weeks (1997)" 
* Now we want to recode the missing observations of these variables with a little greater detail.
	replace general_health_97 = .d if general_health_97 == 8
		label def health 1 "very unhealthy" 2 "poor health" 3 "fairly healthy" 4 "very healthy" 
				numlabel health, mask(#:) add force
			label val general_health_97 health
	replace schl_miss_sick = .d if maa0bx == 8
keep hhid97 pid97 general_health schl_miss_sick
* Now let's check to see if hhid97 and pid97 are unique identifiers of the data.
isid hhid97 pid97 
	* They are! We can go ahead and do a 1:1 merge with our previous data then. 
		merge 1:1 hhid97 pid97 using `b5_cov'
	* We want all observations that match from the using and that don't match from the master. If an observation is in the using but not the master, it's not valid and we can freely drop it.
			drop if _merge == 1
					* No observations deleted.
				drop _merge 
tempfile general_health
	save `general_health'		
***************************************************************************************
* Self Treatment Variables            ***************************************************************************************
* Next I want to create a set of variables relating to self-treatment. 
use b5_psa, clear
* We have a problem with this dataset we quickly notice: hhid97 and pid97 are not unique because of the 'psatype' variable, meaning that we have to reshape.
	* Before reshaping, let's cut down on unnecessary variables and recode the missing obsevations for psa02.
			replace psa02 = .m if psa02x == 9 
			replace psa02 = .d if psa02x == 8
				drop version psa02x pidlink
* Let's create a set of locals we're going to use later in a loop to label our vars.
					local A		"modern medicine"
					local B		"traditional medicine" 
					local C		"topical medicine"
					local D		"other"
					local E		"vitamin"
					local F		"refresher"
					local G		"provider"
* Now we're going to reshape, keeping hhid97/pid97 as our identifying pair of vars.
reshape wide psa01 psa02, i(hhid97 pid97) j(psatype) string
* Let's label all these variables using our local macros defined above.
foreach k in A B C D E F G {
	label var psa01`k' "did child use ``k'' last 4 wks (1997)"
	label var psa02`k' "cost of ``k'' treatment"
		replace psa01`k' = 0 if psa01`k' == 3 | psa01`k' == 9
		replace psa02`k' = 0 if psa01`k' == . | psa02`k' == .d
}
foreach k in E F G {
	replace psa01`k' = 0 if psa01`k' == 4
}
ds, detail
* We're not terribly interested in the TYPE of treatment used by children, so we're going to sum up all these variables to create a total self_treatment variable.
* First we're going to create a basic self-treatment dummy ; since all of our non-cost dummies are just that (and don't tell us HOW often kids were treated), we are going to settle for a dummy.
		ds psa01* 
	egen self_treat_97 = rowmax(`r(varlist)')
		label var self_treat_97 "has child been treated with any medicine last 4 wks? (1997)"
			label def binary 0 "no" 1 "yes"
			numlabel binary, mask(#:) add force
				label val self_treat_97 binary		
* Next, we're going to create a total cost variable that is the sum of all individual cost variables.
		ds psa02*
	egen self_treat_cost_97 = rowtotal(`r(varlist)')
			sum self_treat_cost_97 
				label var self_treat_cost_97 "total cost of self-treatment in last 4 wks (1997)"
keep hhid97 pid97 self_treat_97 self_treat_cost_97
gen ln_slf_trt_cost_97 = ln(self_treat_cost_97)
		hist ln_slf_trt_cost_97, nodraw
	label var ln_slf_trt_cost_97 "ln of total cost of self-treatment in last 4 wks (1997)"
* Let's check if hhid97 and pid97 are unique.
isid hhid97 pid97
	* They are! Let's merge 1:1 with previous data.
	merge 1:1 hhid97 pid97 using `general_health'
					drop if _merge == 1
						drop _merge 
* Now let's save our tempfile.
tempfile self_treat
	save `self_treat'
***************************************************************************************
* Hospital Visit Variables          ***************************************************************************************
* First, we need to figure out the children that did not go to ANY type of patient care facilies, using the b5_rja0 dataset:
use b5_rja0, clear

keep hhid97 pid97 rja_num 
	rename rja_num tot_num_vis_97 
		replace tot_num_vis_97 = 0 if tot_num_vis_97 == .
			label var tot_num_vis_97 "total number of visits to outpatient care (1997)"
/*
* In this dataset we are going to create a series of variables dealing with hospital visits.
use b5_rja1, clear
	* The data here follows a similar structure to the previous dataset that we worked with. For now, let's just create a num_visits variable. 
	rename (rja01 rja02) (ev_visit_97 num_visit_97)

	* Let's prep our locals to label the variables upon reshaping. 
	local A "public hospital"
	local B "public health center"
	local E "private hospital"
	local F "private clinic"
	local G "private doctor"
	local H "nurse/mwife/other"
	local I "traditional practitioner"
	local J "other"
* Now let's reshape our variable, after dropping all but our necessary variables.
drop pidlink version 
reshape wide ev_visit_97 num_visit_97, i(hhid97 pid97) j(rja1type) string
foreach k in A B E F G H I J {
	label var ev_visit_97`k' "ever visited ``k'' (1997)"
	label var num_visit_97`k' "number of visits to ``k'' in last 4wks (1997)"
		*replace num_visit_97`k' = 0 if ev_visit_97`k' == 3
}
* Now we want to generate a total number of visits variable -- for this, we are going to sum all the categories across categories. We're excluding the category of midwife, as that seems less relevant to the health of the child.
ds ev_visit* pid97 hhid97 num_visit_97H, not
	egen tot_num_vis_97 = rowtotal(`r(varlist)')
		label var tot_num_vis_97 "total # of visits to med providers, last 4 wks (1997)"
keep hhid97 pid97 tot_num_vis_97 
*/
	* Let's check if hhid97 pid97 are unique identifiers of observations.
	isid hhid97 pid97 
		* They are! So we can merge 1:1 w/previous data. 
			merge 1:1 hhid97 pid97 using `self_treat'
				drop if _merge == 1 
					drop _merge 
tempfile hos_visit
	save `hos_visit'
***************************************************************************************
* Hospitalization Data Variables          ***************************************************************************************
* We're going to conclude with hospitalization data. 
use b5_rna1, clear
* We're going to keep our hospitalization data the same way, by reshaping wide.
keep hhid97 pid97 rna1type rna01 rna_num 
* Let's prep our local macros for variable labeling. 
			local A "public hospital"
			local B "public health center"
			local C "private hospital"
			local D "private clinic"
			local E "other" 
	* Let's just code rna1type as 0 for those with missing observations of rna1type.
		drop if rna1type == ""
reshape wide rna01 rna_num, i(hhid97 pid97) j(rna1type) string
foreach k in A B C D E {
	label var rna01`k' "hospitalized at ``k'' in last 12mos? (1997)"
		rename rna01`k' ev_hosp`k'_97
	label var rna_num`k' "num of hospitalizations at ``k'' in last 12 mos (1997)"
		rename rna_num`k' num_hosp`k'_97
			replace num_hosp`k'_97 = 0 if ev_hosp`k'_97 == 3
}
* Now let's just code our total hospitalizations with egen. 
ds num_hosp* 
	egen tot_hosp_97 = rowtotal(`r(varlist)')
		label var tot_hosp_97 "total num of hospitalizations last 12mos (1997)"
keep hhid97 pid97 tot_hosp_97
* Now let's check if hhid97 and pid97 are unique identifiers of observations. 	
isid hhid97 pid97 
	* They are! We can merge 1:1 with previous data now.
	merge 1:1 hhid97 pid97 using `hos_visit'
		drop if _merge == 1
			drop _merge 
	* For missing observations of our total hospitalizations, we can assume that the num of hospital visits is actually 0 (because of our dropping of missing variables earlier.)
		replace tot_hosp_97 = 0 if tot_hosp_97 == .
***************************************************************************************
* Recode interview variables        ***************************************************************************************
label def scale_5 1 "very bad" 2 "not good" 3 "fair" 4 "good" 5 "excellent", replace
	numlabel scale_5, mask(#:) add force
* We want to recode this the OPPOSITE way, so that higher valued-observations are 'better'.
foreach v in resp_accuracy_97 resp_interest_97 {
		tab `v', m
			label val `v'
		recode `v' (1 = 5) (2 = 4) (3 = 3) (4 = 2) (5 = 1)
				label val `v' scale_5
		tab `v', m
}
***************************************************************************************
* Finish Up 
***************************************************************************************
	local tag 04_ifls2_child_health.do
foreach v in tot_hosp_97 tot_num_vis_97 self_treat_97 self_treat_cost_97 ln_slf_trt_cost_97 general_health_97 schl_miss_sick_97 resp_interest_97 resp_accuracy_97 age_97 {
	notes `v': `tag'
}
compress
	label data "ifls2 children health variables"
	cd "$clean/ifls2_hh"
	save ifls2_child_health, replace
/*
log close
exit
*/









