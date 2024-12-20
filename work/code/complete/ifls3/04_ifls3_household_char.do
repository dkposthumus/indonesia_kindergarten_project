/*
capture log close
log using 04_ifls3_household_char, replace text
*/

/*
  program:    	04_ifls3_household_char.do
  task:			To clean and create a dataset of household characteristics, in 
				IFLS 3. 
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 13February2024
*/

version 17
clear all
set linesize 80
macro drop _all

****************************************************************************************
* Set Global Macros              ****************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global expenditure "$raw/consumption_aggregates"
	global code "/Users/danielposthumus/thesis_independent_study/work/code/complete"
/*
	We are interested in the following household characteristics: 
		- Asset index
			/ Unclear on how to create this variable
		- Expenditures per capita in household
		- Total assets per capita in household
			/ Unclear on how to create this variable
		- Owns television (indicator)
		- Owns refrigerator (indicator)
		- Owns stove (indicator)
			/ Unclear on how to create this variables
		- Uses electricity
		- Annual earnings in household
			/ Unclear on how to create this variable
*/
****************************************************************************************
* Nonfood consumption and expenditures, annual by category ****************************************************************************************
/*
	This section will create variables for the following:
		- Total annual nonfood nominal expenditures, by category
			- nfd_expend_A...for all categories A-G
				- "total annual HH nonfood expenditure, nominal clothing for 
				clothing and adults"
		- Total annual nonfood nominal consumption, by category
			- nfd_consum_A...for all categories A-G
				- "total Annual HH nonfood consumption, nominal clothing for 
			children and adults"	
	Note that neither of these measures are per-capita, but total for the 
	household.

*/
cd "$raw/ifls3_hh"
local expend "expenditure"
local consum "consumption"
use b1_ks3, clear
tempfile nonfood_year
rename ks08 nfd_expend
rename ks09a nfd_consum
reshape wide ks08x nfd_expend ks09ax nfd_consum, i(hhid00 version) j(ks3type) string
	local A "clothing for children and adults"
	local B "houshold supplies and furniture"
	local C "medical costs"
	local D "ritual ceremonies, charities and gifts"
	local E "taxes"
	local F "other expenditures not specified above"
	local G "value of non-food items given to others/other parties outside the household on an irregular basis (less than twelve times per year)"
foreach t in expend consum {
	foreach v in A B C D E F G {
		label var nfd_`t'`v' "annual HH nonfood nominal ``t'', ``v''"
	}
}
save `nonfood_year'
****************************************************************************************
* Food consumption and expenditures, monthly by category ****************************************************************************************
/*
	This section will create variables for the following:
		- Total monthly food nominal expenditures, by category
			- fd_expendA...for all categories A-OB
				- "total Monthly HH food expenditure, nominal hulled, cooked 
				rice"
		- Total monthly food nominal consumption, by category
			-fd_consumA...for all categoreis A-OB
				- "total Monthly HH food consumption, nominal hulled, cooked 
				rice"
	Note that neither of these measures are per-capita, but total for the 
	household.
*/
use b1_ks1, clear
tempfile food_month
rename ks02 fd_expend
rename ks03 fd_consum
reshape wide ks02x fd_expend ks03x fd_consum, i(hhid00 version) j(ks1type) string

	local A "hulled, cooked rice"
	local AA "granulated sugar"
	local B "corn"
	local BA "coffee"
	local C "sago/flour"
	local CA "tea"
	local D "cassava, tapioca, dried cassava"
	local DA "cocoa"
	local E "other staple foods, like sweet potatoes, potatoes, yams, etc."
	local EA "soft drinks like Fanta, Sprite, etc."
	local F "vegetables"
	local FA "alcoholic beverages like beer, palm wine, rice wine, etc."
	local G "beans like mung-beans, peanuts, soya-beans, etc."
	local GA "betel nut (for chewing, traditional drug, others)"
	local H "fruits like papaya, mango, banana, etc."
	local HA "cigarettes, tobacco"
	local I "noodles, rice noodles, macaroni, shrimp chips, other chips, etc."
	local IA "prepared food (eaten at home)"
	local IB "prepared food (away from home)"
	local J "cookies, breads, crackers"
	local K "beef, mutton, water buffalo meat, etc."
	local L "chicken, duck and the like"
	local M "fresh fish, oysters, shrimp, squid, etc."
	local N "salted fish, smoked fish"
	local OA "other dishes, like: jerky, shredded beef, canned meat, sardine, etc."
	local OB "tofu, tempe, other side dishes"
	local P "eggs"
	local Q "fresh milk, canned milk, powdered milk, etc."
	local R "sweet and salty soy sauce"
	local S "salt"
	local T "shrimp paste"
	local U "chili sauce, tomato sauce, and the like"
	local V "shallot, garlic, chili, candle nuts, coriander, MSG, etc."
	local W "javanese (brown) sugar"
	local X "butter"
	local Y "cooking oil"
	local Z "drinking water"
* Now let's run a loop to properly name these variables:
foreach t in expend consum {
	foreach v in A AA B BA C D DA E EA F FA G GA H HA I IA IB J K L M N OA OB P Q R S T U V W X Y Z {
		label var fd_`t'`v' "monthly HH food nominal ``t'', ``v''"
	}
}
save `food_month'
****************************************************************************************
* Prep consumption aggregates for merging ****************************************************************************************
/*
	This section will create variables for the following:
		- Total monthly HH food nominal expenditures, aggregated across categories
			- fd_expend
		- Total monthly nonfood nominal expenditures, aggregated across 
		categories
			- nfd_expend
		- Total monthly food real expenditures, aggregated across categories
			- fd_expend_r
		- Total monthly nonfood real expenditures, aggregated across categories
			- nfd_expend_r
		- Total monthly aggregate (food + nonfood) nominal expenditures
			- agg_expend
		- Total monthly aggregate (food + nonfood) real expenditures
			- agg_expend_r
	Note that neither of these measures are per-capita, but total for the 
	household.
*/
cd "$expenditure"
use pce00, clear
tempfile expenditure_00
rename (xfood xnonfood xtotal rtotal rfood rnonfood) (fd_expend nfd_expend agg_expend agg_expend_r fd_expend_r nfd_expend_r)
label var fd_expend "total monthly food real expenditures, aggregated across categories"
label var nfd_expend "total monthly nonfood nominal expenditures, aggregated across categories"
label var agg_expend "total monthly aggregate (food + nonfood) nominal expenditures"
label var agg_expend_r "total monthly aggregate (food + nonfood) real expenditures"
label var fd_expend_r "total monthly food real expenditures, aggregated across categories"
label var nfd_expend_r "total monthly nonfood real expenditures, aggregated across categories"
	save `expenditure_00', replace
****************************************************************************************
* Household wealth indicators ****************************************************************************************
/*
	This section will create variables for the following:
		- Owns television (indicator)
			- television
		- Owns refrigerator (indicator)
			- fridge
		- Owns stove (indicator)
			- Unclear how to code
		- Uses electricity (indicator)
			- electricity
*/
cd "$raw/ifls3_hh"
use b2_kr, clear
tempfile household_indicators
label define binary 0 "no" 1 "yes"
numlabel binary, mask(#_) add force
* Refrigerator indicator
gen fridge = 1 if kr23 == 1 | kr23 == 3
replace fridge = 0 if kr23 == 6
replace fridge = . if kr23 == .
label var fridge "does the household have a refrigerator?"
* Television indicator
gen television = 1 if kr24a == 1
replace television = 0 if kr24a == 3
replace television = . if kr24a == .
label var television "does the household have a television?"
* Electricity indicator
gen electricity = 1 if kr11 == 1
replace electricity = 0 if kr11 == 3
replace electricity = . if kr11 == .
label var electricity "does the household use electricity?"
	label val fridge television electricity binary
save `household_indicators'
****************************************************************************************
* Create asset index variable ****************************************************************************************
/*
	This section will create the following variable:
		- An asset index
However, it's very unclear to me how this variable was made in Maccini & Yang. Will have to take a close look.
*/
****************************************************************************************
* Merge datsets ****************************************************************************************
use `food_month'

merge 1:1 hhid00 using `expenditure_00'
drop if _merge != 3
drop _merge

merge 1:1 hhid00 using `nonfood_year', nogen
merge 1:1 hhid00 using `household_indicators'
drop if _merge != 3
drop _merge
tempfile ifls3_hh_char
save `ifls3_hh_char'
****************************************************************************************
* Create per capita  variables ****************************************************************************************
/*
	This section will create variables for the following:
		- Per capita nonfood nominal expenditures, by category
		- Per capita nonfood nominal consumption, by category
		- Per capita nonfood nominal expenditures, aggregated across categories
		- Per capita nonfood real expenditures, all categories
		- Per capita aggregate (food + nonfood) real expenditures
		- Per capita aggregate (food + nonfood) nominal expenditures
	Then, we also take the natural log of each of these per capita variables
*/
use `ifls3_hh_char', clear
foreach t in nfd fd agg {
	ds `t'*
	foreach v in `r(varlist)' {
		local lvar `"`: var label `v''"'
		gen `v'_pc = `v'/hhsize
		label var `v'_pc "per capita `lvar'"
		label var `v' "total `lvar'"

		gen ln_`v'_pc = ln(`v'_pc)
		label var ln_`v'_pc "natural log per capita `lvar'"
	}
}
****************************************************************************************
* Finish Up 
****************************************************************************************
local tag 04_ifls3_household_char.do
foreach t in nfd fd ln {
	ds `t'* agg* fridge television electricity
	foreach v in `r(varlist)' {
		rename `v' `v'_00
		notes `v'_00: `tag'
	}
	
}
keep hhid00 ln_agg_expend_r_pc_00 electricity_00 television_00 fridge_00

label data "ifls3 household characteristics"
compress

cd "$clean/ifls3_hh"
save ifls3_household_char, replace

/*
log close
exit
*/








