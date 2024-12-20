/*
capture log close
log using chapter_8, replace text
*/

/*
  program:    	chapter_8.do
  task:			to complete the exercises in chapter 8 ("Linear Panel-Data: Basics") of Microeconomics Using 
				Stata.
  
  project:		Honors Thesis Project (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 31Oct2023
*/

version 17
clear all
set linesize 80
macro drop _all

****************************************************************************************Install random stuff             ****************************************************************************************



****************************************************************************************Set Global Macros              ****************************************************************************************

global data "~/thesis_independent_study/work/writing/microecon_using_stata/data"
global output "~/thesis_independent_study/work/writing/microecon_using_stata/output"

local chapter ch8

****************************************************************************************8.3 Summary of panel data ****************************************************************************************

cd $data
* Read in dataset and describe
qui use mus208psid, clear
ds, detail

* Summary of dataset 
sum

* xt commands require that the data be in so-called long form -- each observation being a distinct individual-time pair...or an individual-year pair

* Check organization of dataset
list id t exp wks occ in 1/3, clean

* Declare individual identifier and time identifer
xtset id t 

* Panel description of dataset
xtdescribe

* Panel summary statistics: Within and between variation
xtsum id t lwage ed exp exp2 wks south tdum1

* Panel tabulation for a variable
xttab south

* Transition probabilities for a variable
xttrans south, freq

* Simple time-series plot for each of 20 individuals
qui xtline lwage if id<=20, overlay legend(off) saving(graph1.gph, replace)
qui xtline wks if id<=20, overlay legend(off) saving(graph2.gph, replace)
graph combine graph1.gph graph2.gph, iscale(1.4) ysize(2.5) xsize(6.0)

* Scatterplot, quadratic fit, and nonparametric regression (lowess)
graph twoway (scatter lwage exp, msize(small) msymbol(o)) (qfit lwage exp, clstyle(p3) lwidth(medthick)) (lowess lwage exp, bwidth(0.4) clstyle(p1) lwidth(medthick)), plotregion(style(none)) title("Overall variation: log wage versus experience") xtitle("Years of experience", size(medlarge)) scale(titlegap(*5)) ytitle("log hourly wage", size(medlarge)) yscale(titlegap(*5)) legend(pos(4) ring(0) col(1)) legend(size(small)) legend(label(1 "Actual data") label(2 "Quadratic fit") label(3 "Lowess"))

* Scatterplot for within variation -- see book for example

* Pooled OLS with cluster--robust standard errors
use mus208psid, clear

regress lwage exp exp2 wks ed, vce(cluster id)

* Pooled OLS with incorrect default standard errors
regress lwage exp exp2 wks ed

* Time-series autocorrelations for panel data
	* First-order autocorrelation in a variable
sort id t
correlate lwage L.lwage

* Autocorrelation of residual
qui regress lwage exp exp2 wks ed, vce(cluster id)

predict uhat, residuals
forvalues j = 1/6 {
	qui corr uhat L`j'.uhat
	display "Autocorrelation at lag `j' = " %6.3f r(rho)
}

* First-order autocorrelation differs in different year pairs
forvalues s = 2/7 {
	qui corr uhat L1.uhat if t == `s'
	display "Autocorrelation at lag 1 in year `s' = " %6.3f r(rho)
}

* Population-averaged or pooled FGLS estimator with AR(2) error
xtreg lwage exp exp2 wks ed, pa corr(ar 2) vce(robust) nolog

* Estimated error correlation matrix after xtreg, pa 
matrix list e(R)

* Within or FE estimator with cluster--robust standard errors
xtreg lwage exp exp2 wks ed, fe vce(cluster id)

* LSDV model fit using areg with cluster--robust standard errors
areg lwage exp exp2 wks ed, absorb(id) vce(cluster id)
	* Same coefficient estimates as those from xtreg, fe 
	
* LSDV model fit using factor variables with cluster--robust standard errors
qui regress lwage exp exp2 wks ed i.id, vce(cluster id)
estimates table, keep(exp exp2 wks ed _cons) b se b(%12.7f)

* Between estimator with default standard errors
xtreg lwage exp exp2 wks ed, be

* RE estimator with cluster-robust standard errors
xtreg lwage exp exp2 wks ed, re vce(cluster id) theta

* Mundlak correction: RE with individual-specific means added as regressors
sort id 
foreach x of varlist exp exp2 wks ed {
	by id: egen mean`x' = mean(`x')
}
xtreg lwage exp exp2 wks ed meanexp meanexp2 meanwks meaned, re vce(cluster id) 

* Hausman test assuming RE estimator is fully efficient under null hypothesis
* hausman FE RE, sigmamore 

* Prediction after OLS and RE estimation
qui regress lwage exp exp2 wks ed, vce(cluster id)
predict xbols, xb 
qui xtreg lwage exp exp2 wks ed, re 
predict xbre, xb
predict xbure, xbu 
sum lwage exbols xbre xbure



/*
log close
exit
*/









