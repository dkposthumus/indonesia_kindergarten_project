clear
#delimit ;
****************************************************************************
* pce1997.do;
* Files used:;
* Original files: buk1ks1.dta, buk1ks2a.dta, buk1ks2a.dta, buk1ks3a.dta, buk1ks3b.dta, buk1kr1.dta,  htrack.dta 
* Files created:;
* pce93nom.dta;
****************************************************************************;
set more off;
set mem 48m;
set lines 200;	 
capture log close;
global dir0 "C:\DOCUME~1\FIRMAN~1\MYDOCU~1\pce\temp\";
global dir01 "C:\DOCUME~1\FIRMAN~1\MYDOCU~1\pce\logfile\";
global dir09 "C:\DOCUME~1\FIRMAN~1\MYDOCU~1\pce\data\";

global dir1 "C:\DOCUME~1\FIRMAN~1\MYDOCU~1\ifls1\hh\";
global dir2 "C:\DOCUME~1\FIRMAN~1\MYDOCU~1\ifls2\hh\";
global dir2p "C:\DOCUME~1\FIRMAN~1\MYDOCU~1\ifls2+\hh\";
global dir3 "C:\DOCUME~1\FIRMAN~1\MYDOCU~1\ifls3\hh\public\";

log using $dir01\pce93, text replace;

use $dir2\ptrack, clear;
keep if member93==1;
bys hhid93: gen hhsize93=_N;
bys hhid93: keep if _n==_N;
keep hhid93 hhsize93;
sort hhid93;
save $dir0\hhsize93, replace;

****************************************************************************;
* I. Create a file with kecamatan ID, kabupaten ID, etc;
****************************************************************************;
use $dir2\htrack, clear;
keep if result93==1;
gen kabid93=(sc01_93*100)+sc02_93;
gen kecid93=(kabid*1000)+sc03_93;
gen provid93=sc01_93;
keep provid kabid kecid hhid93;
sort hhid93;
save $dir0\kabkec93, replace;

****************** Food KS1;
* - If missing, impute by: commid median and up to kecamatan, kabupaten;
* - Convert to monthly;
******************;
use $dir1\buk1ks1, clear;
*drop duplicates;
bys hhid93 item: gen dup=_N;
bys hhid93 item: gen ord=_n;
tab dup;
list if dup==2;
drop if dup==2 & ord==2 ;
list if dup==2;
drop dup ord ncomb* ks01 hhid;

sort hhid93;
merge hhid93 using $dir0\kabkec93;
tab _merge;
keep if _merge==3;
drop _merge;

reshape wide ks02rp ks03rp, i(hhid93) j(item) string;
for var ks02rp* ks03rp*: replace X=0 if X==.;
for var ks02rp* ks03rp*: replace X=. if X>=999997;


sort hhid93;
merge hhid93 using $dir0\kabkec93;
tab _merge;
keep if _merge==3;
drop _merge;

for var ks02rp* ks03rp*: egen medcomX=median(X), by(commid93);
for var ks02rp* ks03rp*: egen medkecX=median(X), by(kecid93);
for var ks02rp* ks03rp*: egen medkabX=median(X), by(kabid93);

for var ks02rp* ks03rp*: replace X=medcomX if X==.;
for var ks02rp* ks03rp*: replace X=medkecX if X==.;
for var ks02rp* ks03rp*: replace X=medkabX if X==.;

*purchased;
gen mstaple=ks02rpA+ks02rpB+ks02rpC+ks02rpD+ks02rpE	;
gen mvege=ks02rpF+ks02rpG+ks02rpH;
gen mdried=ks02rpI+ks02rpJ;
gen mmeat=ks02rpK+ks02rpL+ks02rpO+ks02rpO;
gen mfish=ks02rpM+ks02rpN;
gen mdairy=ks02rpP+ks02rpQ+ks02rpX;
gen moil=ks02rpY;
gen mspices=ks02rpR+ks02rpS+ks02rpT+ks02rpU+ks02rpV+ks02rpW+ks02rpAA;
gen mbeve=ks02rpZ+ks02rpBA+ks02rpCA+ks02rpDA+ks02rpEA	;
gen maltb=ks02rpFA+ks02rpHA;
gen msnack=ks02rpIA /* note: include eating out */;

gen mrice=ks02rpA;
gen mtob=ks02rpHA;

gen mfood=mstaple+mvege+mdried+mmeat+mfish+mdairy+moil+mspices+mbeve+maltb+msnack;

*ownproduced;
gen istaple=ks03rpA+ks03rpB+ks03rpC+ks03rpD+ks03rpE	;
gen ivege=ks03rpF+ks03rpG+ks03rpH;
gen idried=ks03rpI+ks03rpJ;
gen imeat=ks03rpK+ks03rpL+ks03rpO+ks03rpO;
gen ifish=ks03rpM+ks03rpN;
gen idairy=ks03rpP+ks03rpQ+ks03rpX;
gen ioil=ks03rpY;
gen ispices=ks03rpR+ks03rpS+ks03rpT+ks03rpU+ks03rpV+ks03rpW+ks03rpAA;
gen ibeve=ks03rpZ+ks03rpBA+ks03rpCA+ks03rpDA+ks03rpEA	;
gen ialtb=ks03rpFA+ks03rpHA;
gen isnack=ks03rpIA /* note: include eating out */;

gen irice=ks03rpA;
gen itob=ks03rpHA;

gen ifood=istaple+ivege+idried+imeat+ifish+idairy+ioil+ispices+ibeve+ialtb+isnack;

*purchased+ownproduced;
gen xstaple=mstaple+istaple;
gen xvege=mvege+ivege;
gen xdried=mdried+idried;
gen xmeat=mmeat+imeat;
gen xfish=mfish+ifish;
gen xdairy=mdairy+idairy;
gen xoil=moil+ioil;
gen xspices=mspices+ispices;
gen xbeve=mbeve+ibeve;
gen xaltb=maltb+ialtb;
gen xsnack=msnack+isnack;

gen xrice=mrice+irice;
gen xtob=mtob+itob;

gen xfood=mfood+ifood;

*change to monthly;
for var m* i* x*: replace X=X*52/12;

*Label
lab var mstaple "Monthly food consump. ks02: staple";
lab var mvege "Monthly food consump. ks02: vegetable";
lab var mdried "Monthly food consump. ks02: dried food";
lab var mmeat "Monthly food consump. ks02: meat";
lab var mfish "Monthly food consump. ks02: fish";
lab var mdairy "Monthly food consump. ks02: dairy";
lab var moil  "Monthly food consump. ks02: oil";
lab var mspices "Monthly food consump. ks02: spices";
lab var mbeve "Monthly food consump. ks02: beverage";
lab var maltb "Monthly food consump. ks02: alcohol, tobacco";
lab var msnack "Monthly food consump. ks02: snacks";

lab var istaple "Monthly food consump. ks03: staple";
lab var ivege "Monthly food consump. ks03: vegetable";
lab var idried "Monthly food consump. ks03: dried food";
lab var imeat "Monthly food consump. ks03: meat";
lab var ifish "Monthly food consump. ks03: fish";
lab var idairy "Monthly food consump. ks03: dairy";
lab var ioil  "Monthly food consump. ks03: oil";
lab var ispices "Monthly food consump. ks03: spices";
lab var ibeve "Monthly food consump. ks03: beverage";
lab var ialtb "Monthly food consump. ks03: alcohol, tobacco";
lab var isnack "Monthly food consump. ks03: snacks";

lab var xstaple "Monthly food consump. ks02+ks03: staple";
lab var xvege "Monthly food consump. ks02+ks03: vegetable";
lab var xdried "Monthly food consump. ks02+ks03: dried food";
lab var xmeat "Monthly food consump. ks02+ks03: meat";
lab var xfish "Monthly food consump. ks02+ks03: fish";
lab var xdairy "Monthly food consump. ks02+ks03: dairy";
lab var xoil  "Monthly food consump. ks02+ks03: oil";
lab var xspices "Monthly food consump. ks02+ks03: spices";
lab var xbeve "Monthly food consump. ks02+ks03: beverage";
lab var xaltb "Monthly food consump. ks02+ks03: alcohol, tobacco";
lab var xsnack "Monthly food consump. ks02+ks03: snacks";

lab var mrice "Monthly food consump. ks02: rice";
lab var irice "Monthly food consump. ks03: rice";
lab var xrice "Monthly food consump. ks02+ks03: rice";

lab var mtob "Monthly food consump. ks02: tobacco";
lab var itob "Monthly food consump. ks03: tobacco";
lab var xtob "Monthly food consump. ks02+ks03: tobacco";

lab var mfood "Monthly food consump. ks02: all food";
lab var ifood "Monthly food consump. ks03: all food";
lab var xfood "Monthly food consump. ks02+ks03: all food";

drop med*;
keep hhid93  x* i* m* commid93 kecid93 kabid93 provid93 ;
sort hhid93;
save $dir0\foodexp, replace;

****************** Food KS2A (transfer in and out);
* - If missing, impute by: commid median and up to kecamatan, kabupaten;
* - Convert to monthly;
******************;
*Weekly need to convert to monthly;
use $dir1\buk1ks2a, clear;
sort hhid93;
merge hhid93 using $dir0\kabkec93;
tab _merge;
keep if _merge==3;
drop _merge;
gen miss_ks04a1=0;
gen miss_ks04b1=0;
gen na_ks04a1=0;
gen na_ks04b1=0;
replace miss_ks04a1=1 if ks04a1>=999997;
replace miss_ks04b1=1 if ks04b1>=999997;
replace na_ks04a1=1 if ks04a1==999996;
replace na_ks04b1=1 if ks04b1==999996;

for var ks04*: replace X=. if X>=999995;
for var ks04*: egen medcomX=median(X), by(commid93);
for var ks04*: egen medkecX=median(X), by(kecid93);
for var ks04*: egen medkabX=median(X), by(kabid93);

replace ks04a1=medcomks04a1 if ks04a1==. & na_ks04a1==0;
replace ks04a1=medkecks04a1 if ks04a1==. & na_ks04a1==0;
replace ks04a1=medkabks04a1 if ks04a1==. & na_ks04a1==0;

replace ks04b1=medcomks04b1 if ks04b1==. & na_ks04b1==0;
replace ks04b1=medkecks04b1 if ks04b1==. & na_ks04b1==0;
replace ks04b1=medkabks04b1 if ks04b1==. & na_ks04b1==0;

*Convert to monthly;
for var ks04*: replace X=X*52/12;

rename ks04a1 xfdin;
rename ks04b1 xfdout;

lab var ks05a "Is ks04a1 per HH?";
lab var ks05b "Is ks04b1 per HH?";
lab var xfdin "Monthly food transfer in - ks04a1";
lab var xfdout "Monthly food transfer out - ks04b1";

keep hhid93 commid93 kecid93 kabid93 xfd* ks05* ;
sort hhid93 ;
save $dir0\foodtr, replace;

****************** NON-FOOD 2;
* - If missing, impute by: commid median and up to kecamatan, kabupaten;
* - Already  monthly;
******************;
use $dir1\buk1ks2b, clear;
sort hhid93;
merge hhid93 using $dir0\kabkec93;
tab _merge;
keep if _merge==3;
drop _merge;

keep ks06rp hhid93 nf_item1 commid93 kecid93 kabid93 ks07;
reshape wide ks06rp ks07, i(hhid93) j(nf_item1) ;

for var ks06rp*: gen missX=0;
for var ks06rp*: gen naX=0;

for var ks06rp*: replace missX=1 if X>=999997;
for var ks06rp*: replace naX=1 if X==999996;
for var ks06rp*: replace X=. if X>=999995;

for var ks06rp*: egen medcomX=median(X), by(commid93);
for var ks06rp*: egen medkecX=median(X), by(kecid93);
for var ks06rp*: egen medkabX=median(X), by(kabid93);

for var ks06rp*: replace X=medcomX if X==. & naX==0;
for var ks06rp*: replace X=medkecX if X==. & naX==0;
for var ks06rp*: replace X=medkabX if X==. & naX==0;

*utility personal medical cerem tax other  transf;

lab var ks06rp1 "Monthly non-food exp. ks06rp: utility";
lab var ks06rp2 "Monthly non-food exp. ks06rp: personal items";
lab var ks06rp3 "Monthly non-food exp. ks06rp: hh goods";
lab var ks06rp4 "Monthly non-food exp. ks06rp: recreation";
lab var ks06rp5 "Monthly non-food exp. ks06rp: transportation";
lab var ks06rp6 "Monthly non-food exp. ks06rp: lottery";
lab var ks06rp7 "Monthly non-food exp. ks06rp: transfer";

rename ks06rp1 xutility;
rename ks06rp2 xpersonal;
rename ks06rp3 xhhgood;
rename ks06rp4 xrecreat;
rename ks06rp5 xtransp;
rename ks06rp6 xlottery;
rename ks06rp7 xtransfer;

*xnonfood2 IS ALL KS06 EXCLUDING TRANSFER AND ARISAN ;
gen xnonfood2=xutility+xpersonal+xhhgood+xrecreat+xtransp+xlottery;

lab var xnonfood2 "Monthly non-food exp. ks06rp: all";

drop med* na* miss*;


sort hhid93;
save $dir0\nfoodks2, replace;

****************** NON-FOOD 2 (DURABLES);
* - If missing, impute by: commid median and up to kecamatan, kabupaten;
* - Convert annual to monthly;
******************;
use $dir1\buk1ks3a, clear;
sort hhid93;
merge hhid93 using $dir0\kabkec93;
tab _merge;
keep if _merge==3;
drop _merge;

keep ks08rp hhid93 nf_item2 commid93 kecid93 kabid93 ks09;
reshape wide ks08rp ks09, i(hhid93) j(nf_item2) ;

for var ks08rp*: gen missX=0;
for var ks08rp*: gen naX=0;

for var ks08rp*: replace missX=1 if X>=99999997;
for var ks08rp*: replace naX=1 if X==99999996;
for var ks08rp*: replace X=. if X>=99999995;

for var ks08rp*: egen medcomX=median(X), by(commid93);
for var ks08rp*: egen medkecX=median(X), by(kecid93);
for var ks08rp*: egen medkabX=median(X), by(kabid93);

for var ks08rp*: replace X=medcomX if X==. & naX==0;
for var ks08rp*: replace X=medkecX if X==. & naX==0;
for var ks08rp*: replace X=medkabX if X==. & naX==0;

*monthly;
for var ks08rp*: replace X=X/12;

*cloth furn medical cerem tax other  ;

lab var ks08rp1 "Monthly non-food exp. ks08rp: clothing";
lab var ks08rp2 "Monthly non-food exp. ks08rp: furniture";
lab var ks08rp3 "Monthly non-food exp. ks08rp: medical";
lab var ks08rp4 "Monthly non-food exp. ks08rp: ceremonies";
lab var ks08rp5 "Monthly non-food exp. ks08rp: tax";
lab var ks08rp6 "Monthly non-food exp. ks08rp: other";


rename ks08rp1 xcloth;
rename ks08rp2 xfurn;
rename ks08rp3 xmedical;
rename ks08rp4 xcerem;
rename ks08rp5 xtax;
rename ks08rp6 xoth;

gen xnonfood3=xcloth+xfurn+xmedical+xcerem+xtax+xoth;

lab var xnonfood3 "Monthly non-food exp. ks08rp: all";

drop med* na* miss* ;

sort hhid93;
save $dir0\nfoodks3, replace;

****************** EDUCATION;
* - If missing, impute by: commid median and up to kecamatan, kabupaten;
* - Convert the annual to  monthly;
******************;
use $dir1\buk1ks3b, clear;
sort hhid93;
merge hhid93 using $dir0\kabkec93;
tab _merge;
keep if _merge==3;
drop _merge;
for var ks1*1: gen missX=0;
for var ks1*1: gen naX=0;
for var ks1*1: replace missX=1 if X>=999997;
for var ks1*1: replace naX=1 if X==999996;
for var ks1*1: replace X=. if X>=999995;

for var ks1*1: egen medcomX=median(X), by(commid93);
for var ks1*1: egen medkecX=median(X), by(kecid93);
for var ks1*1: egen medkabX=median(X), by(kabid93);

for var ks1*1: replace X=medcomX if X==. & naX==0;
for var ks1*1: replace X=medkecX if X==. & naX==0;
for var ks1*1: replace X=medkabX if X==. & naX==0;

for var ks1*1: replace X=0 if X==. & naX==0;
for var ks1*1: replace X=0 if X==. & naX==0;
for var ks1*1: replace X=0 if X==. & naX==0;


replace ks11a1=ks11a1/12;
replace ks11b1=ks11b1/12;

gen xeducall=ks10a1+ks10b1+ks11a1+ks11b1+ks12b1;

***!!!;
replace xeducall=0 if xeducall==.;

lab var ks10a1 "Monthly educ expend ks10a1: tuition in hh";
lab var ks10b1 "Monthly educ expend ks10b1: tuition out hh";
lab var ks11a1 "Monthly educ expend ks11a1: other in hh";
lab var ks11b1 "Monthly educ expend ks11b1: other out hh";
lab var ks12b1 "Monthly educ expend ks12b1: boarding out hh";

rename ks10a1 xedutuit;
rename ks10b1 xedutuitout;
rename ks11a1 xeduoth;
rename ks11b1 xeduothout;
rename ks12b1 xedubordout;

lab var xeducall "Monthly educ expend: all";

drop med* na* miss* *_ ks*;
sort hhid93;
save $dir0\educexp, replace;

******************HOUSING;
* - If missing, impute by: commid median and up to kecamatan, kabupaten;
* - Already  monthly;
******************;
use $dir1\buk1kr1, clear;
keep hhid93 kr03* kr04* kr05* commid93;
sort hhid93;
merge hhid93 using $dir0\kabkec93;
tab _merge;
keep if _merge==3;
drop _merge;

for var kr04* kr05*: gen missX=0;
for var kr04* kr05*: gen naX=0;
for var kr04* kr05*: replace missX=1 if X>=999997;
for var kr04* kr05*: replace naX=1 if X==999996;
for var kr04* kr05*: replace X=. if X>=999995;

for var kr04* kr05*: egen medcomX=median(X), by(commid93);
for var kr04* kr05*: egen medkecX=median(X), by(kecid93);
for var kr04* kr05*: egen medkabX=median(X), by(kabid93);

for var kr04* kr05*: replace X=medcomX if X==. & naX==0;
for var kr04* kr05*: replace X=medkecX if X==. & naX==0;
for var kr04* kr05*: replace X=medkabX if X==. & naX==0;

lab var kr04r1 "Monthly rent, rent: kr04r1";
lab var kr04r1 "Monthly rent, own: kr05r1";

rename kr04r1 xrent;
rename kr05r1 xown;
gen xhouse=xrent if xrent~=.;

replace xhouse=xown if xrent==. & xown~=.;
lab var xhouse "Monthly housing expend: kr04r1/kr05r1";

drop med* na* miss* kr*;
sort hhid93;
save $dir0\housingexp, replace;

****************** COMBINE;
use $dir0\foodexp, clear;
merge hhid93 using $dir0\foodtr;
tab _merge;
drop _merge;
sort hhid93;
merge hhid93 using $dir0\nfoodks2;
tab _merge;
drop _merge;
sort hhid93;
merge hhid93 using $dir0\nfoodks3;
tab _merge;
drop _merge;
sort hhid93;
merge hhid93 using $dir0\educexp;
tab _merge;
drop _merge;
sort hhid93;
merge hhid93 using $dir0\housingexp;
tab _merge;
drop _merge;
sort hhid93;

gen xfoodtot=xfood+xfdin+xfdout;
gen xnonfoodtot=xnonfood2+xnonfood3+xeducall+xhouse;

lab var xfoodtot "Monthly food expend: ks02+ks03+ks04";
lab var xnonfoodtot "Monthly non-food expend: ks06+ks08+educ";

gen xhhexp=xfoodtot+xnonfoodtot;

lab var xhhexp "Monthly hh expenditure";

gen wtobacco=xtob/xhhexp*100;
gen wtobfood=xtob/xfoodtot*100;
gen wrice=xrice/xhhexp*100;
gen wricefood=xrice/xfoodtot*100;

lab  var wtobacco "Monthly share of tobacco out of hhexp";
lab  var wrice "Monthly share of rice out of hhexp";
lab  var wtobfood "Monthly share of tobacco out of food expend";
lab  var wricefood "Monthly share of rice out of food expend";

sum xhhexp xfoodtot xnonfoodtot wtob* wrice*;
compress;
sort hhid93;
merge hhid93 using $dir0\hhsize93;
tab _merge;
drop _merge;

gen pce=xhhexp/hhsize;
lab var pce "Monthly HH per capita expenditure";
sort hhid93;
compress;
lab data "HH expenditure file - 1993";


compress;
capture drop med*;
capture drop miss1*;
capture drop miss4b;
capture drop miss7a ;
capture drop missk*; 
capture drop kr*; 
capture drop ks*; 
capture drop _m*;
capture drop imptype*;
capture drop origk*;
des;
sum;
lab data "Per Capita Expenditure 1993";
sort hhid;
save $dir09\pce93nom.dta, replace;


log close;
