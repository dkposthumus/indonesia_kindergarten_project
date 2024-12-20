/*
capture log close
log using chapter_4, replace text
*/

/*
  program:    	chapter_4.do
  task:			to complete the exercises in chapter 4 ("Linear regression extensions") of Microeconomics Using 
				Stata.
  
  project:		Honors Thesis Project (Daniel Posthumus)
  author:     	Daniel_Posthumus \ 28Sept2023
*/

version 17
clear all
set linesize 80
macro drop _all

**********************************************************************************Install random stuff             **********************************************************************************

ssc install oaxaca
net from http://www.marco-sunder.de/stata/
net install rego

**********************************************************************************Set Global Macros              **********************************************************************************

global data "~/thesis_independent_study/work/writing/microecon_using_stata/data"
global output "~/thesis_independent_study/work/writing/microecon_using_stata/output"

local chapter ch4

**********************************************************************************4.2 In-sample Prediction **********************************************************************************

cd $data

/*

	The predict command, to be used after regressions
		/ The default is to predict for all observations in sample
		/ The qualifer "if e(sample)" ensures predictions are made only for observations used to obtain estimates
		/ Can pull many different statistics (check "help predict")

*/

global varlist suppins phylim actlim totchr age female income

* OLS in levels for positive medical expenditures
use mus203mepsmedexp, clear
keep if totexp > 0
regress totexp $varlist, vce(robust)

* In-sample prediction following OLS in levels
predict yhatlevels
summarize totexp yhatlevels

* Compare median prediction and sample median actual value after OLS
tabstat totexp yhatlevels, stat(count p50) col(stat)

* In-sample prediction in levels from a logarithmic model
qui regress ltotexp $varlist, vce(robust)
qui predict lyhat
generate yhatwrong = exp(lyhat)
generate yhatnormal = exp(lyhat)*exp(0.5*e(rmse)^2)
qui predict uhat, residual
generate expuhat = exp(uhat)
qui summarize expuhat
generate yhatduan = r(mean)*exp(lyhat)

summarize totexp yhatwrong yhatnormal yhatduan yhatlevels

* WE CANNOT IGNORE THE RE-TRANSFORMATION BIAS

* Effect of suppins: 	(1) compare actual means with suppins==1 and suppins==0
bysort suppins: sum totexp
* 						(2) compare predictred means by suppins value
bysort suppins: summarize yhatlevels yhatduan
*						(3) predict with set to suppins==0 versus all set to 1
qui regress totexp $varlist, vce(robust)
preserve
	qui replace suppins = 1
	qui predict yhat1
	qui replace suppins = 0
	qui predict yhat0
	generate treateffect = yhat1 - yhat0
	summarize yhat1 yhat0 treateffect
restore
*						(3b) same as previous, but easier and gives se
regress totexp i.suppins phylim actlim totchr age female income, vce(robust)
margins, dydx(suppins) nofvlabel
*						(4) different fitted models for suppins = 0 and = 1
qui regress totexp $varlist if suppins == 0
qui predict yhatmodel0 
qui regress totexp $varlist if suppins == 1
qui predict yhatmodel1 
generate treateffectra = yhatmodel1 - yhatmodel0
summarize yhatmodel1 yhatmodel0 treateffectra


* Compute standard errors of prediction and forecast with default VCE
qui regress totexp $varlist
display "Estimated standard deviation of the error: s = " e(rmse)
predict yhatstdp, stdp
predict yhatstdf, stdf
summarize yhatlevels yhatstdp yhatstdf

**********************************************************************************4.3 Out-of-sample Prediction **********************************************************************************

* Out-of-sample OLS predictions using correctly specified model
clear all
qui set obs 100
set seed 10101
generate u = 3*rnormal()
generate x = 10 + 4*rnormal()
generate y = 1 + x + u
qui regress y x if _n < 91
qui predict yhatos if _n > 90 	// Predict 10 out-of-sample observations
qui regress y x 
qui predict yhatis if _n > 90 	// Predict 10 in-sample observations
qui generate ferroros = y - yhatos

summarize y yhatis yhatos ferroros if _n > 90

* Out-of-sample prediction under misspecification (omitted regressor)
generate z = 10 + 4*rnormal()
generate ynew = 1 + x + z + u
qui regress ynew x if _n < 91 		// Regression with variable z omitted
qui predict ynewhatos if _n > 90 	// Predict 10 out-of-sample observations
qui regress ynew x 
qui predict ynewhatis if _n > 90 	// Predict 10 in-sample observations
qui generate ferrornewos = ynew - ynewhatos if _n > 90
list ferrornewos in 91/100, clean

summarize ynew ynewhatis ynewhatos ferrornewos if _n > 90

**********************************************************************************4.4 Predictive Margins **********************************************************************************

* Factor variables used to define model with interactions and quadratic
qui use mus203mepsmedexp, clear
regress totexp i.suppins i.phylim i.actlim c.totchr c.age##c.age i.female##c.income, vce(robust) noheader nofvlabel

* Predictive margin using sample average
margins

* Predictive margin using sample average with population-average inference
margins, vce(unconditional)

* Predictive margins by categorical regress gender using sample averages
margins female, nofvlabel

* Predictive margins by categorical regressor gender using sample menas
margins female, atmeans nofvlabel

* Predictive margins by categorical regressor gender at specified values
margins female, at(suppins=1 phylim=1 actlim=1 totchr=2 age=70 income=50) nofvlabel

* Margins at 3 different ages (averaged over other regressors' sample values)
	* at ages = 65, 75, 85
margins, at(age=(65(10)85))

* Marginsplot for predictive margins by age
qui margins, at(age=(65(5)90))
marginsplot

* Marginsplot for predictive margins by age for each gender
margins, at(age=(65(5)90)) over(female) nofvlabel
marginsplot

* Marginsplot for predictive margins by age, separate graphs by gender
qui margins, at(age=(65(5)90)) over(female)
marginsplot, by(female)

* Predictive margins for three income values
margins, at(income=(10(10)30))

* Pairwise comparison of predictive margins for three income values
margins, at(income=(10(10)30)) pwcompare(effects)

* Pairwise comparison of predictive margins for six income-gender combinations
margins female, at(income=(10(10)30)) pwcompare(effects) nofvlabel

* Contrasts of predictive margins for gender
margins female, contrast(ci) nofvlabel

* Contrasts of predictive margins for gender at each of three income levels
margins female, at(income=(10(10)30)) contrast(nowald) nofvlabel


* AMEs computed with factor variables used to define model
qui regress totexp i.suppins i.phylim i.actlim c.totchr c.age##c.age## i.female##c.income, vce(robust) noheader

margins, dydx(*) nofvlabel

* MER computed with factor variables
qui regress totexp i.suppins i.phylim i.actlim c.totchr c.age##c.age i.female##c.income, vce(robust) noheader

margins, dydx(*) at(suppins=1 phylim=1 actlim=1 totchr=2 age=70 female=1 income=20) nofvlabel

* Sample average elasticity with respect to income
margins, eyex(income)

* Manual computation of sample average elasticity with respect to income
predict yhat 
generate eincome = (_b[income] + _b[1.female#c.income]*female) * income / yhat
sum eincome

* Elasticity with respect to income evaluated at representative values
margins, eyex(income) at(suppins=1 phylim=1 actlim=1 totchr=2 age=70 female=1 income=20)

* Semi-elasticities: Change in y w.r.t. proportionate change in x
margins, dyex(totchr age income) at(suppins=1 phylim=1 actlim=1 totchr=2 age=70 female=1 income=20)

* t tests on difference in mean log-earnings by gender
qui use mus204mabeldecomp, clear
ttest logyearn, by(female) unequal

* Gender differences in variables for the regression estimation sample
global xlist1 yhrs expr exprsq fellow pgradoth pracsize childu5 visa
qui regress logyearn $xlist1
table () (female) if e(sample), stat(mean logyearn $xlist1) stat(count logyearn) nototals

* Separate earnings regressions for male and female doctors
qui regress logyearn $xlist1 if female==0, vce(robust)
estimates store MALE

qui regress logyearn $xlist1 if female==1, vce(robust)

estimates store FEMALE 
estimates table MALE FEMALE, b(%11.5f) t(%11.2f) stats(N r2 F)

* Tests of coefficient equality in separate regressions
qui regress logyearn $xlist1 if female==0
estimates store MALE
qui regress logyearn $xlist1 if female==1
estimates store FEMALE
suest MALE FEMALE

test _b[MALE_mean:yhrs] = _b[FEMALE_mean:yhrs]

* Blinder-Oaxaca decomposition in logarithmic units
oaxaca logyearn $xlist1, by(female) vce(robust)

* Shapley-Owen decomposition of regressors' contributions to R-squared
rego logyearn yhrs expr exprsq pracsize fellow pgradoth if female==0, vce(robust)

rego logyearn yhrs \ expr exprsq \ pracsize \ fellow pgradoth \ if female==0, vce(robust)

/*
log close
exit
*/









