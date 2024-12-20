* Creating a panel dataset
local ifls5 "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Data_Clean/hh_14_data"
local ifls4 "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Data_Clean/hh_7_data"
local panel "/Users/danielposthumus/Thesis_Independent_Study/IFLS5/Work/Data_Clean/hh_panel"

* Will merge HH characteristics and education variables for IFLS5
cd "`ifls5'"
use ifls5_ptrack, clear

merge 1:1 pidlink using ifls5_b3a_dl1_educ

gen ifls = "14"

tempfile ifls5_educ
save `ifls5_educ'

* Then accomplish same merge for IFLS4
cd "`ifls4'"
use ifls4_ptrack, clear

merge 1:1 pidlink using ifls4_b3a_dl1_educ
gen ifls = "07"

tempfile ifls4_educ
save `ifls4_educ'

* Then merge the datasets for the two waves
use `ifls4_educ', clear
append using `ifls5_educ'

compress

cd "`panel'"
save educ_panel, replace
