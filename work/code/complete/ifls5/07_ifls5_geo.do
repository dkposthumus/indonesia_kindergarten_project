/*
capture log close
log using 07_ifls5_geo, replace text
*/

/*
  program:    	07_ifls5_geo.do
  task:			To construct geography-related variables of IFLS5 households.
  
  project:		Economics Honors Thesis (Starting Early: Returns on... Daniel Posthumus)
  author:     	Daniel_Posthumus \ 27Dec2023
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
* Create relevant geography-related variables *******************************************************************************************
cd "$raw/ifls5_hh"
* We want four geographical variables, all of which can be found in a single raw data-file.
use bk_sc1, clear
* First, we want to create our urban dummy variable; this will be taken straight from the variable sc05 ("Urban/Rural"), where 1 is "urban" and 2 "rural".
gen urban_14 = 0 
	replace urban_14 = 1 if sc05 == 1
	replace urban_14 = .m if sc05 == .
		label var urban "is household urban? (2014)"
		label def binary 0 "no" 1 "yes"
		label val urban binary
* Next, we want a prov_14 variable, capturing the code of the households' province in 2014.
rename sc01_14_14 prov_14
	label var prov_14 "province code (2014)"
* Next, the Kabupaten code
rename sc02_14_14 kab_14
	label var kab_14 "kabupaten code (2014)"
* Next, the kecamatan code
rename sc03_14_14 kec_14 
	label var kec_14 "kecamatan code (2014)"
keep hhid14_9 urban_14 prov_14 kab_14 kec_14 
* In anticipation of merging 1:m on hhid14_9, let's check if hhid14_9 is a unique identifier in this data:
duplicates report hhid14_9 
	isid hhid14_9 
* Now that we've confirmed hhid14_9 IS unique, we can finish with this data.
*******************************************************************************************
* Label provincial code data *******************************************************************************************
/*
prov_14 is based on BPS's 2014 provincial codes, listed below (for the values of prov_14 in our data): 
	11:		Aceh 
	12: 	North Sumatra
	13:		West Sumatra
	14:		Riau 
	15:		Jambi 
	16: 	South Sumatra 
	18:		Lampung
	19:		Banga Belitung Islands
	21:		Riau Islands
	31:		Jakarta
	32:		West Java 
	33: 	Central Java
	34:		Yogyakarta
	35:		East Java
	36:		Banten
	51:		Bali 
	52:		West Nusa Tenggara 
	61:		West Kalimantan
	62:		Central Kalimantan
	63:		South Kalimantan
	64:		East Kalimantan 
	73:		South Sulawesi 
	76:		West Sulawesi 
	91: 	Papua
*/

* Now we need to create a value label with these corresponding provinces:
label def prov_14 11 "11:Aceh" 12 "12:North Sumtra" 13 "13:West Sumatra" 14 "14:Riau" 15 "15:Jambi" 16 "16:South Sumatra" 18 "18:Lampung" 19 "19:Banga Belitung Islands" 21 "21:Riau Islands" 31 "31:Jakarta" 32 "32:West Java" 33 "33:Central Java" 34 "34:Yogyakarta" 35 "35:East Java" 36 "36:Banten" 51 "51:Bali" 52 "52:West Nusa Tengara" 61 "61:West Kalimantan" 62 "62:Central Kalimantan" 63 "63:South Kalimantan" 64 "64:East Kalimantan" 73 "73:South Sulawesi" 76 "76:West Sulawesi" 91 "91:Papua"
	label val prov_14 prov_14
*******************************************************************************************
* Finishing up *******************************************************************************************
local tag 07_ifls5_geo.do
foreach v in urban_14 prov_14 kab_14 kec_14  {
	notes `v': `tag'
}
	label data "ifls5 geographical variables"
	compress
cd "$clean/ifls5_hh"
save ifls5_geo, replace


/*
log close
exit
*/
