/*
capture log close
log using chapter_3, replace text
*/

/*
  program:    	chapter_3.do
  task:			to complete the exercises in chapter 3 of Microeconomics Using 
				Stata.
  
  project:		Honors Thesis Project (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 20Sept2023
*/

version 17
clear all
set linesize 80
macro drop _all

**********************************************************************************Install random stuff             **********************************************************************************

ssc install outsum
ssc install fsum

**********************************************************************************Set Global Macros              **********************************************************************************

global data "~/thesis_independent_study/work/writing/microecon_using_stata/data"
global output "~/thesis_independent_study/work/writing/microecon_using_stata/output"

local chapter ch3

**********************************************************************************Explore data / Create Tables **********************************************************************************

cd $data
use mus203mepsmedexp, clear

* Describe the data in detail: storage type? display format? value label and variable label
ds totexp ltotexp posexp suppins phylim actlim totchr age female income, detail

* Summary statistics for variables
sum totexp ltotexp posexp suppins phylim actlim totchr age female income

* Use tabulate command to see all value and frequencies for a variable
tab income if income <= 0

* Detailed summary statistics
sum totexp, detail

* Test out our two community-sourced commands:
	* outsum -- useless garbage
	* outsum totexp using "$output/`chapter'/outsum_test.tex"
	
	* fsum -- potentially helpful
	fsum totexp 

* Two-way table of frequencies
table female totchr

* Two-way table with row and column percentages and Pearson chi-squared
tab female suppins, row col chi2

* Three-way table of frequences
table female suppins totchr, nototals

* One-way table of summary statistics
table (result) female, stat(count totchr) stat(mean totchr) stat (sd totchr) stat(p50 totchr)

* Two-way table of summary statistics and export as a tex file
collect clear
collect: table female suppins, stat(count totchr) stat(mean totchr) nototals
collect layout (var) (result#suppins#female)
collect preview
collect export "$output/`chapter'/summary_stat.tex", replace

* Summary statistics obtained using command tabstat and export 
tabstat totexp ltotexp, statistics(count mean p50 sd skew kurt) columns (statistics)
	* Without the columns(statistics) option, we actually have variables in the 
	* columns and statistics in the rows:
	tabstat totexp ltotexp, statistics(count mean p50 sd skew kurt)

**********************************************************************************Tests **********************************************************************************
	
* The ttest command can be used to test hypotheses about the population mean of a single variable, and also to test the equality of means

/*
	There is also the oneway command - "One-way analysis of variance"...with 
	three primary options:
	1) Bonferroni multiple-comparison test
	2) Scheffe multiple-comparison test
	3) Sidak multiple-comparison test
*/

* See also the anova command 

**********************************************************************************Data plots **********************************************************************************

* kdensity - provides kernel estimate of the density of the dependent variable

* Kernel density plots with adjustment for highly skewed data 
kdensity totexp if posexp==1, generate(kx1 kd1) n(500)
graph twoway (line kd kx1) if kx1 < 40000, name(levels, replace)

label variable ltotexp "Natural logarithm of expenditure"
kdensity ltotexp if posexp==1, generate(kx2 kd2) n(500)
graph twoway (line kd2 kx2) if kx2 < ln(40000), name(logs, replace)
graph combine levels logs, iscale(1.2) ysize(2.5) xsize(6.0)

**********************************************************************************Transformation of data before regression **********************************************************************************

* The purpose of the transformation is to "straighten out" a relationship
	* Transformations can also make the error term less heteroskedastic
	
**********************************************************************************Linear regression **********************************************************************************

/*
	a robust estimator of the vce is obtained by using the 'vce(robust)' option of the regress commands
	related commands are:
		vce(hc2) -  produces slightly more conservative confidence intervals
		vce(hc3) -  produces even more slightly more conservative CIs
		vce(cluster 'clustvar') cluster-robust standard errors 

We can also use an appropiate 'bootstrap' to compute heteroskedasticity-robust and cluster-robust standard errors
	Basic idea of the bootstrap: sample is used as population, and then we 
	obtain a number of samples from this population by repeatedly resampling 
	observations with replacement
		We then fit the same model to many such 'boostrap samples'
*/

* Pairwise correlation for dependent variable and regressor variables
collect clear
collect: corr ltotexp suppins phylim actlim totchr age female income
collect layout (rowname) (colname)
collect preview
collect export "$output/`chapter'/correlations.tex", replace

pwcorr ltotexp suppins phylim actlim totchr age female income, sig

* OLS regression with heteroskedastcity-robust standard errors
regress ltotexp suppins phylim actlim totchr age female income, vce(robust)
	* In log-linear models, parameters need to be interpreted as semi-elasticities
ereturn list

/*
	Post-estimation commands:
		- Results
			- estat summarize, estat vce, estat ic, etable
		- Store results
			- estimates
		- Prediction
			- predict, predictnl
		- MEs
			- margins, marginsplot
		- Confidence intervals
			- lincom, nlcom
		- Hypothesis tests
			- test, testnl, lrtest
		- Specification tests
			- hausman, linktest
*/

* A regression model can be fit subject to constraints on parameters
	* For example: OLS estimates subject to beta(phylim) = beta(actlim)
	constraint 1 phylim = actlim
	cnsreg ltotexp suppins phylim actlim totchr age female income, constraints(1) vce(robust)

* Wald test of equality of coefficients
qui regress ltotexp suppins phylim actlim totchr age female income, vce(robust)
test phylim = actlim

* Joint test of statistical significance of several variables
test phylim actlim totchr

* Store and then tabulate results from multiple regressions
qui regress ltotexp suppins phylim actlim totchr age female income, vce(robust)
estimates store REG1

qui regress ltotexp suppins phylim actlim totchr age female educyr, vce(robust)
estimates store REG2

esttab REG1 REG2, b(%9.4f) se stats(N r2 F ll)

* Richer table environment using etable
etable, estimates(REG1 REG2) keep(suppins income educyr) cstat(_r_b, nformat(%8.4f)) cstat(_r_se, nformat(%8.4f)) mstat(N) mstat(r2) mstat(F) mstat(ll) column(estimates) stars(0.1 "*" 0.05 "**" 0.01 "***") showstars showstarsnote export("$output/`chapter'/regression1.tex", replace)
	* See also estout, estout, frmttable, outreg2, and collect

* Factor variables for sets of indicator variables and interactions
collect clear
collect: regress ltotexp suppins phylim actlim totchr age female c.income i.famsze c.income#i.famsze, vce(robust) noheader allbaselevels

* Test joint significance of sets of indicator variables and interactions
testparm i.famsze c.income#i.famsze

* Average Marginal Effects (AME) can be calculated using margins postestimation command with the dydx() option
regress ltotexp i.suppins i.phylim i.actlim c.totchr c.age##c.age i.female##c.income, vce(robust) noheader nofvlabel
margins, dydx(*) nofvlabel

* Plot residuals against fitted values
qui reg ltotexp suppins phylim actlim totchr age female income, vce(robust)
rvfplot, msize(tiny) scale(1.2)

* Details on the outlier residuals
predict uhat, residual
predict yhat, xb
list totexp ltotexp yhat uhat if uhat < -5, clean

* Quantile-quantile plot of fitted against actual values
local endash = ustrunescape("/u2013")
qnorm uhat, msize(small) title("Q`endash'Q plot of residuals versus normal") name(graph1, replace)
kdensity uhat, normal legend(off) name(graph2, replace)
graph combine graph1 graph2, iscale(1.2) ysize(2.5) xsize(6.0)

* Compute dfits that combines outliers and leverage
qui regress ltotexp suppins phylim actlim totchr age female income
predict dfits, dfits
scalar threshold = 2*sqrt((e(df_m)+1)/e(N))
display "difts threshold = " %6.3f threshold
tabstat dfits, statistics(min p1 p5 p95 p99 max) format(%9.3f) columns(statistics)

* Stata's robust regression as a check on fat tails
qui use mus203mepsmedexp, replace
rreg ltotexp suppins phylim actlim totchr age female income, genwt(w)
sum w, detail
drop w

* Median regression w/default standard errors
qreg ltotexp suppins phylim actlim totchr age female income, nolog vce(robust)

* Simplest way to test for omitted variable bias -- add additional regressors and see if their coefficient is zero/insignificant

* Variable augmentation test of conditional mean using estat ovtest
qui reg ltotexp suppins phylim actlim totchr age female income, vce(robust)
estat ovtest
* one can also use the command 'linktest'

* Heteroskedasticity tests using estat hettest and option iid
qui reg ltotexp suppins phylim actlim totchr age female income
estat hettest, iid

* Sampling weights

**********************************************************************************Exercises **********************************************************************************

* 1.
use mus203mepsmedexp, clear
local varlist ltotexp suppins phylim actlim totchr age female income
gen num_obs = _n
* default standard error
regress `varlist' if num_obs <= 100
estimates store DEFAULT
* heteroskedastic-robust standard error [vce(robust)]
regress `varlist' if num_obs <= 100, vce(robust)
estimates store ROBUST1

regress `varlist' if num_obs <= 100, vce(hc2)
estimates store ROBUST2

regress `varlist' if num_obs <= 100, vce(hc3)
estimates store ROBUST3
* cluster-robust where clustering is one number of chronic problems
	* number of chronic problems = totchr
regress `varlist' if num_obs <= 100, vce(cluster totchr)
estimates store CLUSTER

esttab DEFAULT ROBUST1 CLUSTER, b(%9.4f) se stats(N r2 F ll)
esttab ROBUST1 ROBUST2 ROBUST3, b(%9.4f) se stats(N r2 F ll)

* 2. 
use mus203mepsmedexp, clear
local varlist ltotexp suppins phylim actlim totchr age female income
regress `varlist', vce(robust)
test age female income

gen male = 1 		if female == 0
replace male = 0 	if female == 1
regress ltotexp suppins phylim actlim totchr age male income, vce(robust)

* test hypothesis that being male has same impact on medical expenditures as aging 10 years (???? how to do)

constraint 1 phylim = actlim 
cnsreg `varlist', constraints(1) vce(robust)

/*
log close
exit
*/









