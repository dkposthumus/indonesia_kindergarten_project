/*
capture log close
log using 02_sum_graphs, replace text
*/

/*
  program:    	02_sum_graphs
  task:			To create graphs that motivate the paper.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 25Dec2023
*/

version 17
clear all
set linesize 80
macro drop _all

*******************************************************************************************Set Global Macros              *******************************************************************************************
global raw "~/thesis_independent_study/work/data_raw"
global clean "~/thesis_independent_study/work/data_clean"
	global code "~thesis_independent_study/work/code/to_do"
		global output "~/thesis_independent_study/work/writing/rough_draft/data"
		global analysis "~/thesis_independent_study/work/writing/rough_draft/analysis"
**************************************************************************************Install appropiate packages           **************************************************************************************
ssc install binscatter
**************************************************************************************Graphs over time/year-of-birth             **************************************************************************************
cd $clean
use master, clear
* Our dob_yr variable is useless; let's create a custom one using age.
drop dob_yr 
	gen dob_yr = 0
		replace dob_yr = 2014 - age_14
		replace dob_yr = .m if age_14 == .
* Create our binned scatterplots
binscatter educ14 dob_yr, xtitle("Year of Birth") ytitle("Years of Education") title("Years of Education Completed by Year of Birth") nodraw
	* graph export "$output/educ_age_scatter.png", replace
binscatter kinder_ever dob_yr, xtitle("Year of Birth") ytitle("Kindergarten attendance") title("Kindergarten Attendance by Year of Birth") nodraw
	* graph export "$output/kinder_age_scatter.png", replace
binscatter exit_age dob_yr, xtitle("Year of Birth") ytitle("Exit Age") title("Exit Age by Year of Birth") nodraw
	* graph export "$output/exit_age_scatter.png", replace
binscatter educ14 dob_yr if inrange(dob_yr,1960,1990), by(kinder_ever) ytitle("Years of Education") xtitle("Year of Birth") legend(label(1 "No Kindergarten") label(2 "Kindergarten") size(small)) graphregion(lcolor(white))
	graph export "$output/kinder_binscatter.png", replace
/*
Create our line graphs, by province.
	First, we want to create our broad geographical 'zones' variable, broken down as the following:
		- Java/Bali
			- Jakarta, West Java, Central Java, Yogyakarta, East Java, Bali, Banten
			- prov_14 = 31, 32, 33, 34, 35, 36, 51
		- Sumatra
			- North Sumatra, West Sumatra, South Sumatra, Lampung, Aceh, Jambi, Riau
			- prov_14 = 11, 12, 13, 14, 15, 16, 18
		- Other
			- Nusa Tenggara, Kalimantan, Sulawesi, Riau Islands, Papua, Banga Belitung Islands
			- prov_14 = 19, 21, 52, 61, 62, 63, 64. 73, 76, 91
*/
gen geo_zone_14 = 0 
		label def geo_zone 1 "Java/Bali" 2 "Sumatra" 3 "Other"
		label val geo_zone_14 geo_zone
	replace geo_zone_14 = 1 if inlist(prov_14,31, 32, 33, 34, 35, 36, 51)
	replace geo_zone_14 = 2 if inlist(prov_14,11, 12, 13, 14, 15, 16, 18)
	replace geo_zone_14 = 3 if inlist(prov_14,19, 21, 52, 61, 62, 63, 64. 73, 76, 91)
		label var geo_zone_14 "Geographical zone (2014)"
preserve
			drop if prov_14 == . | urban_14 == .
	keep educ14 kinder_ever exit_age geo_zone_14 dob_yr
		collapse educ14 kinder_ever exit_age, by(geo_zone_14 dob_yr)
		reshape wide educ14 kinder_ever exit_age, i(dob_yr) j(geo_zone_14)
	* Let's quickly multiply our average kinder_ever variable by 100 to create an attendance rate variable (in %)
	foreach v in kinder_ever1 kinder_ever2 kinder_ever3 {
		replace `v' = `v' * 100
			label var `v' "kindergarten attendance rate"
	}
	* Let's plot kindergarten attendance rates by year of birth, broken down by 2014 province
	line kinder_ever1 kinder_ever2 kinder_ever3 dob_yr if inrange(dob_yr, 1960, 1996), legend(label(1 "Java/Bali") label(2 "Sumatra") label(3 "Other") size(small)) xtitle("Year of Birth") ytitle("Kindergarten Attendance Rate (%)")
		graph export "$output/time_series_kinder.png", replace
	* Let's plot average years of education by year of birth, broken down by 2014 province
	line educ141 educ142 educ143 dob_yr if inrange(dob_yr, 1979, 1996), legend(label(1 "Java/Bali") label(2 "Sumatra") label(3 "Other") size(*0.75) rows(3)) xtitle("Year of Birth") ytitle("Years of Education") graphregion(color(white)) saving(time_educ, replace)
		graph export "$output/time_series_educ.png", replace
restore

* Now, we're interested in going one step further with this analysis, now breaking this down by urban vs. non-urban households. Thus, we're going to collapse on three varaibles: geo_zone dob_yr AND urban_14.
preserve
	keep educ14 kinder_ever exit_age geo_zone_14 dob_yr urban_14
	collapse educ14 kinder_ever exit_age, by(geo_zone_14 dob_yr urban_14)
			drop if geo_zone_14 == . | urban_14 == .
		reshape wide educ14 kinder_ever exit_age, i(dob_yr geo_zone_14) j(urban_14)
			reshape wide educ141 kinder_ever1 exit_age1 educ140 kinder_ever0 exit_age0, i(dob_yr) j(geo_zone_14)
	* Let's quickly multiply our average kinder_ever variable by 100 to create an attendance rate variable (in %)
	foreach n in 1 2 3 {
		foreach m in 0 1 {
			replace kinder_ever`m'`n' = kinder_ever`m'`n' * 100
				label var kinder_ever`m'`n' "kindergarten attendance rate"
		}
	}

	line educ1411 educ1401 dob_yr if inrange(dob_yr, 1960, 1996), legend(label(1 "Urban") label(2 "Rural")) title("Java/Bali Years of Education by Year of Birth") xtitle("Year of Birth") ytitle("Years of Education") 
	line educ1412 educ1402 dob_yr if inrange(dob_yr, 1960, 1996), legend(label(1 "Urban") label(2 "Rural")) title("Sumatra Years of Education by Year of Birth") xtitle("Year of Birth") ytitle("Years of Education") 
	line educ1413 educ1403 dob_yr if inrange(dob_yr, 1960, 1996), legend(label(1 "Urban") label(2 "Rural")) title("Other Years of Education by Year of Birth") xtitle("Year of Birth") ytitle("Years of Education") 
	
	line educ1411 educ1412 educ1413 dob_yr if inrange(dob_yr, 1960, 1996), legend(label(1 "Java/Bali") label(2 "Sumatra") label(3 "Other")) title("Urban Years of Education by Year of Birth") xtitle("Year of Birth") ytitle("Years of Education") 
		graph export "$output/line_educ_urban.png", replace
	line educ1401 educ1402 educ1403 dob_yr if inrange(dob_yr, 1960, 1996), legend(label(1 "Java/Bali") label(2 "Sumatra") label(3 "Other")) title("Rural Years of Education by Year of Birth") xtitle("Year of Birth") ytitle("Years of Education") 
	
	line kinder_ever11 kinder_ever12 kinder_ever13 dob_yr if inrange(dob_yr, 1960, 1996), legend(label(1 "Java/Bali") label(2 "Sumatra") label(3 "Other")) title("Urban Rates of Kindergarten Attendance" "by Year of Birth") xtitle("Year of Birth") ytitle("Rate of Kindergarten Attendance") 
		graph export "$output/line_kinder_urban.png", replace
	line kinder_ever01 kinder_ever02 kinder_ever03 dob_yr if inrange(dob_yr, 1960, 1996), legend(label(1 "Java/Bali") label(2 "Sumatra") label(3 "Other")) title("Rural Rates of Kindergarten Attendance" "by Year of Birth") xtitle("Year of Birth") ytitle("Rate of Kindergarten Attendance") 
	line kinder_ever01 kinder_ever02 kinder_ever03 dob_yr if inrange(dob_yr, 1960, 1996), legend(label(1 "Java/Bali") label(2 "Sumatra") label(3 "Other")) title("Rural Rates of Kindergarten Attendance" "by Year of Birth") xtitle("Year of Birth") ytitle("Rate of Kindergarten Attendance") 
restore
	
preserve
	keep geo_zone_14 dob_yr urban_14
		collapse urban_14, by(geo_zone_14 dob_yr)
		reshape wide urban_14, i(dob_yr) j(geo_zone_14)
	* Let's make our average urban_14 variable rates of urban residence by multiplying it by 100:
	foreach v in urban_141 urban_142 urban_143 {
		replace `v' = `v' * 100
			label var `v' "rates of urban residence"
	}
	line urban_141 urban_142 urban_143 dob_yr if inrange(dob_yr, 1960, 1996), legend(label(1 "Java/Bali") label(2 "Sumatra") label(3 "Other")) title("Rates of Urban Residence by Year of Birth") ytitle("Years of Education") xtitle("Year of Birth")
		graph export "$output/time_series_urban.png", replace
restore
**************************************************************************************In-School / Pass Rates            **************************************************************************************
preserve
	drop if kinder_ever == . | kinder_ever == .d | kinder_ever == .m
	keep in_schl* kinder_ever pidlink
	reshape long in_schl, i(pidlink kinder_ever) j(year)
	gen in_schl_total = in_schl
	reshape wide in_schl, i(pidlink year in_schl_total) j(kinder_ever)
	collapse in_schl0 in_schl1 in_schl_total, by(year)
	foreach v in 0 1 { 
		replace in_schl`v' = in_schl`v' * 100
	}
	keep if inrange(year,0,14)
	line in_schl0 in_schl1 year, xline(6 9 12) legend(label(1 "No Kindergarten") label(2 "Kindergarten") size(0.75*) rows(1)) ytitle("Attendance Rate") xtitle("Grade in School") graphregion(color(white)) saving("$analysis/in_schl", replace)
	graph export "$output/in_school.png", replace
restore

preserve
	drop if kinder_ever == . | kinder_ever == .d | kinder_ever == .m
	keep pass* kinder_ever pidlink
	reshape long pass, i(pidlink kinder_ever) j(year)
	gen pass_total = pass
	reshape wide pass, i(pidlink year pass_total) j(kinder_ever)
	collapse pass1 pass0 pass_total, by(year)
	line pass0 pass1 year, legend(label(1 "No kindergarten") label(2 "Kindergarten")) title("Pass rates, By Grade") yscale(range(0 1)) xtitle("Grade in School") ytick(0(0.2)1) ylabel(0(0.2)1)
	graph export "$output/pass_sample.png", replace
restore
**************************************************************************************Years of Education Histogram          **************************************************************************************
preserve 
	keep if sample == 1
	hist educ14, percent width(1) discrete start(0) xtitle("Years of Education Completed") ytitle("Percent of Sample")
	graph export "$output/hist_educ14.png", replace
restore
**************************************************************************************Number of Schools Over Time          **************************************************************************************
preserve
use master, clear
keep if sample == 1
	keep pidlink elem_per* junior_per* senior_per* num_elem* num_junior* num_senior* educ14 prov_97 kab_97
	ds elem_per* junior_per* senior_per* num_elem* num_junior* num_senior* educ14
	collapse (mean) `r(varlist)', by(prov_97 kab_97)
	* let's build a basic scatterplot; first, we need to reshape 
	foreach k in elem junior senior {
		foreach y in 97 00 07 14 {
			rename `k'_per_10000_`y' _`k'`y'
			rename num_`k'_`y' __`k'`y'
		}
	}
	reshape long _elem _junior _senior __elem __junior __senior, i(prov_97 kab_97 educ14) j(year) string
				destring year, replace
			replace year = 1997 if year == 97 
			replace year = 2000 if year == 0
			replace year = 2007 if year == 7
			replace year = 2014 if year == 14
	graph box _elem _junior _senior, over(year) graphregion(color(white)) ytitle("Number of Schools per 10,000 People") legend(label(1 "Elementary") label(2 "Junior High") label(3 "Senior High") rows(1)) noout note("")
		graph export "$output/schl_box.png", replace
	graph box __elem __junior __senior, over(year) graphregion(color(white)) ytitle("Number of Schools per 10,000 People") legend(label(1 "Elementary") label(2 "Junior High") label(3 "Senior High") rows(1)) noout note("")
	reshape long _, i(prov_97 kab_97 educ14 year) j(level) string
				rename _ num_sch
					drop if num_sch > 150 | num_sch == .
			replace level = "Elementary" if level == "elem" 
			replace level = "Junior High" if level == "junior" 
			replace level = "Senior High" if level == "senior"
	tw (scatter num_sch year, msymbol(p)) (lfit num_sch year), by(level) legend(label(1 "Number of Schools per 10,000 People") label(2 "Linear Trend Line")) xtitle("")
		graph export "$output/schl_scatter.png", replace
restore 
**************************************************************************************Instrument over time        **************************************************************************************
preserve
	use master, clear
		keep if sample == 1
	keep pidlink kec_privpopkinder90 kec_privpopkinder00 kec_pubpopkinder90 kec_pubpopkinder00 kec_popkinder90 kec_popkinder00 prov_97 kab_97 kec_97
	gen one = 1
	collapse (mean) kec_privpopkinder90 kec_privpopkinder00 kec_pubpopkinder90 kec_pubpopkinder00 kec_popkinder90 kec_popkinder00 (sum) one, by(prov_97 kab_97 kec_97)
	reshape long kec_privpopkinder kec_pubpopkinder kec_popkinder, i(prov_97 kab_97 kec_97 one) j(yr)
	foreach k in pub priv {
		foreach y in 00 {
			replace kec_`k'popkinder = kec_`k'popkinder`y' if yr == `y'
			drop kec_`k'popkinder`y'
		}
	}
	replace kec_popkinder = kec_popkinder00 if yr == 0
	drop kec_popkinder00
	rename (kec_popkinder kec_privpopkinder kec_pubpopkinder) (num_total num_priv num_pub)
	replace yr = 1990 if yr == 90
	replace yr = 2000 if yr == 0
	* box plot 
		graph box num_priv num_pub num_total, over(yr) ytitle("Kindergartens per 10,000 People") legend(label(1 "Private") label(2 "Public") label(3 "Total") rows(1)) graphregion(color(white)) noout note("")
		graph export "$output/kinder_box.png", replace
	reshape long num_, i(prov_97 kab_97 kec_97 one yr) j(type) string
	replace type = "Private" if type == "priv" 
	replace type = "Public" if type == "pub" 
	replace type = "Total" if type == "total"
	tw (scatter num_ yr [w=one], msymbol(oh)) (lfit num_ yr), by(type) legend(label(1 "Number of Kindergartens per 10,000 People") label(2 "Linear Trend Line")) xtitle("")
		graph export "$output/kinder_numscatter.png", replace
restore
**************************************************************************************Province Fixed-Effects Scatter       **************************************************************************************
use master, clear 
	keep if sample == 1
tw (scatter educ14 kinder_ever, msymbol(p) graphregion(color(white))) (lfit educ14 kinder_ever, graphregion(fcolor(white))), by(prov_97, plotregion(fcolor(white)) note("")) xtitle("") ytitle("Years of Education") legend(label(1 "Years of Education")) 
	graph export "$output/kinder_educ_prov.png", replace
	
	
	
	
	
	
	
	
	
