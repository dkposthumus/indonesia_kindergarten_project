/*
capture log close
log using  01a_pisa22_sch, replace text
*/

/*
  program:    	01a_pisa22_sch.do
  task:			To import and clean school data from PISA2022.
  
  project:		IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 29Mar2024
*/

version 17
clear all
set linesize 80
macro drop _all

***************************************************************************************Set Global Macros              ***************************************************************************************
global raw "/Users/danielposthumus/thesis_independent_study/work/data_raw"
global clean "/Users/danielposthumus/thesis_independent_study/work/data_clean"
	global code "/Users/danielposthumus/thesis_independent_study/work/code/to_do"
***************************************************************************************Import and merge data ***************************************************************************************
cd "$raw/pisa/2022"
	import sas 2022_sch.sas7bdat
		* obviously, we're only interested in Indonesia: 
		keep if CNT == "IDN"
	e
***************************************************************************************Finish Up ***************************************************************************************
	local tag 01a_pisa22_sch.do
foreach v in  {
	notes `v': `tag'
}
	compress
***************************************************************************************Finishing Up ***************************************************************************************
compress
cd "$clean/pisa/2022"
/*
log close
exit
*/









