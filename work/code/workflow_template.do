capture log close
log using _do_file_name_, replace text

//  program:    template.do
//  task:		template do-file
//  project:	IFLS5; Independent Study/Honors Thesis (Daniel Posthumus)
//  author:     Daniel_Posthumus \ _date_

version 10
clear all
set linesize 80
macro drop _all



log close
exit
