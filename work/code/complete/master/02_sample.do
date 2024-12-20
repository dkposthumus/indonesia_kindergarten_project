/*
capture log close
log using 02_sample, replace text
*/

/*
  program:    	02_sample.do
  task:			To generate sample variables and fine-tune sample specifications. I 
				also will to generate data specific to fixed-effects 
				diagnosis/analysis.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 30Nov2023
*/

version 17
clear all
set linesize 80
macro drop _all

**************************************************************************************
* Set Global Macros              
**************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~/thesis_independent_study/work/code/complete"
	global output "~/thesis_independent_study/work/writing/rough_draft/data_methods"
**************************************************************************************
* Age cohort variables 
**************************************************************************************
cd "$code/master"
	do 01_merge.do
cd "$clean"
	use master, clear
* Let's set our minimum and maximum ages using locals:
local min 3
local max 10
/*
	I'm going to construct a basic age cohort variable, containing four categories (in 1997 ages):
		4 --> 3-4
		3 --> 5-6
		2 --> 7-8
		1 --> 9-10
*/
gen cohort = 0 
	replace cohort = 4 if inrange(age_97,`min',`min'+1)
	replace cohort = 3 if inrange(age_97,`min'+2,`min'+3)
	replace cohort = 2 if inrange(age_97,`max'-3,`max'-2)
	replace cohort = 1 if inrange(age_97, `max'-1,`max')
		replace cohort = .m if cohort == .
			label var cohort "age cohort"
**************************************************************************************
* Generate birth order variable **************************************************************************************
* We want to generate our birth order, which we'll do very simply by sorting by mother and age; the higher the age, the older the individual, and then the closer to being 1st born they'll be. 
	destring mom_pidlink, replace
bysort mom_pidlink age_14: gen birth_order = _n 
	replace birth_order = . if mom_pidlink == .
		label var birth_order "order of birth for household"
* We also want an idea of the number of siblings each individual had.
bysort mom_pidlink: gen num_children = _N
	replace num_children = . if mom_pidlink == .
		label var num_children "number of children of mother"
**************************************************************************************
* Spillover Variables **************************************************************************************
* I want to create a dummy variable capturing whether there is any spillover, i.e., whether an older sibling of an individual attended kindergarten.
bysort mom_pidlink birth_order: gen kinder_spillover = 1 if kinder_ever[_n-1] == 1
	bysort mom_pidlink birth_order: replace kinder_spillover = 1 if kinder_spillover[_n-1] == 1 
	bysort mom_pidlink birth_order: replace kinder_spillover = 0 if kinder_spillover == .
			label var kinder_spillover "did an older sibling attend kindergarten"
/*
	Let's also create two variables representing:
		1) The total number of kids in a family who attended kindergarten
		2) The fraction of kids in a family who attended kindergarten
*/
bysort mom_pidlink: egen tot_kinder = total(kinder_ever) 
	label var tot_kinder "number of kids in family who attended kindergarten"
bysort mom_pidlink: gen share_kinder = tot_kinder/num_children
	label var share_kinder "share of kids in family who attended kindergarten"
**************************************************************************************
* Clean community variables **************************************************************************************
* for those w/missing village-level data, I want to replace that for the average within each kecamatan: 
foreach v in elem junior senior {
	foreach y in 97 00 07 14 {
		bysort prov_`y' urban_`y': egen avg_`v'_per_10000_`y' = mean(`v'_per_10000_`y')
		* now let's replace observations w/missing with these variables:
		replace `v'_per_10000_`y' = avg_`v'_per_10000_`y' if `v'_per_10000_`y' ==.
	}
}
**************************************************************************************
* Sample dummy variables **************************************************************************************
* Sample 1: everyone between max and min ages without ever being attrited
gen sample1 = 1				if inrange(age_97,`min',`max')
	replace sample1 = 0			if sample1 == .
label var sample1 "dummy variable, indicating if in age range of sample"
* Let's first create our local macros for the control variables, w/our 3 categories
local hh_control two_parent educ_hh educ_mom ln_agg_expend_r_pc_97 ln_agg_expend_r_pc_00 ln_agg_expend_r_pc_07 urban_97 urban_00 urban_07 num_children
local indiv_control i.cohort birth_order kinder_spillover tot_num_vis_97 i.general_health_97 male
local comm_control elem_per_10000_00 junior_per_10000_07 senior_per_10000_14 i.prov_97
* Our sample variable is simple to code: anything that has sample1 == 1 AND is included in the e(sample) regression specification will be a part of my true sample:
reg educ14 `hh_control' `indiv_control' `comm_control' if sample1 == 1
gen sample = e(sample)
	label var sample "sample dummy"
**************************************************************************************
* Urban/Province variable **************************************************************************************
gen prov_urban_97 = prov_97 * 10
	replace prov_urban_97 = prov_urban_97 + urban_97
		label var prov_urban_97 "province/urban identifier (1997)"
**************************************************************************************
* Finishing Up **************************************************************************************
	local tag 02_sample.do
foreach v in sample1 sample num_children birth_order cohort prov_urban_97 {
	notes `v': `tag'
}
	compress
cd "$clean"
save master, replace

/*
log close
exit
*/
