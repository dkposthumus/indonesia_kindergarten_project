clear
#delimit ;
****************************************************************************
* pce97.do;
* Files used:;
* Original files: bk_sc.dta, bk_ar1.dta, b1_ks0.dta, b1_ks1.dta, b1_ks2.dta, b2_kr.dta;
* Other files: deflate_hh97.dta;
* Files created:;
* pce97nom.dta, pce97.dta;
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

log using $dir01\pce97, text replace;
****************************************************************************;
* I. Create a file with kecamatan ID, kabupaten ID, etc;
****************************************************************************;
use commid93 result93 if result93==1 using $dir2\htrack, clear;
bys commid93: keep if _n==_N;
gen str4 commid=commid93;
sort commid;
save $dir0\origea93, replace;

use sc01_97 sc02_97 sc03_97 sc05_97 commid97 hhid97 mover97 result97 if result97==1 using $dir2\htrack.dta, clear;
gen kecid=(sc01_97*100000)+(sc02_97*1000)+(sc03_97);
gen kabid=(sc01_97*100)+(sc02_97);
rename sc01_97 provid;
keep if mover97~=.;
gen str4 commid=commid97;
sort commid;
merge commid using $dir0\origea93;
tab _merge;
drop if _merge==2;
gen byte origea=(_merge==3);
lab var origea "Original IFLS EA";
lab var kabid "Kabupaten ID";
lab var kecid "Kecamatan ID";
drop _merge commid;
sort hhid;
compress;
save $dir0\hhlist1997, replace;

****************************************************************************;
* II. Housing Expenditures, Book KR (B2_KR.DTA);
****************************************************************************;
#delimit ;
* II.1 Identify outliers;
****************************************************************************;
use hhid kr03 kr04* kr05* using  $dir2\b2_kr, clear;
format kr04 kr05 %12.0f;
tab1 kr04 kr05;
sort hhid;

gen _outlierkr04=1 if kr04>1666666 & kr04~=.;
gen _outlierkr05=1 if kr05>100000000 & kr05~=.;
replace kr04=. if _outlierkr04==1;
replace kr05=. if _outlierkr05==1;

mvencode _outlierkr04, mv(0);
mvencode _outlierkr05, mv(0);
list hhid kr04 kr05 if _outlierkr04==1 | _outlierkr05==1;
sort hhid;
save $dir0\tempkr97, replace;

* II.2 Merge with kecid, kabid, information;
****************************************************************************;
use hhid sc05_97 commid97 kecid kabid provid origea using $dir0\hhlist1997, clear;
sort hhid;
merge hhid using $dir0\tempkr97;
tab _merge;
*Only keep HHs who answered Book 2;
keep if _merge==3;
drop _merge;

tab kr04x;
tab kr05x;

* II.3 Generate median variables ;
****************************************************************************;
egen medcom05=median(kr05), by(commid97);
egen medkec05=median(kr05), by(kecid);
egen medkab05=median(kr05), by(kabid);

egen medcom04=median(kr04), by(commid97);
egen medkec04=median(kr04), by(kecid);
egen medkab04=median(kr04), by(kabid);
compress;

* II.4. Imputation; 
****************************************************************************;
rename kr04 origkr04;
rename kr05 origkr05;

gen kr04=origkr04 if kr04x~=. & origkr04~=.;
replace kr04=medcom04 if origea==1 & kr04x~=. & origkr04==.;
replace kr04=medkec04 if kr04x~=. & kr04==.;
replace kr04=medkab04 if kr04x~=. & kr04==.;

gen kr05=origkr05 if kr05x~=. & origkr05~=.;
replace kr05=medcom05 if origea==1 & kr05x~=. & origkr05==.;
replace kr05=medkec05 if kr05x~=. & kr05==.;
replace kr05=medkab05 if kr05x~=. & kr05==.;

********************* START OF "MANUAL" IMPUTATION  OF KR04 AND KR05 ********************************************************;
replace kr04=medkab04 if origkr04==. & kr04x~=1 & comm=="3129";
replace kr04=medkab04 if origkr04==. & kr04x~=1 & comm=="3134";

replace kr04=medkab04 if origkr04==. & kr04x~=1 & comm=="3248";
replace kr04=medkab04 if origkr04==. & kr04x~=1 & comm=="3249";
replace kr04=medkab04 if origkr04==. & kr04x~=1 & comm=="3543";
replace kr04=medkab04 if origkr04==. & kr04x~=1 & comm=="31AH";

replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="1610";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="3117";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="3243";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="3250";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="3336";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="3401";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="3404";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="3405";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="3407";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="3504";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="3538";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="12EG";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="13AJ";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="13B4";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="13BV";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="16A6";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="16AJ";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="16BO";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="16DA";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="31AW";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="31AX";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="32AN";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="32GI";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="32I1";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="32K3";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="32K6";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="32LC";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="32LJ";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="32NI";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="33NE";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="35A3";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="35BS";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="35C5";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="35FX";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="35KL";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="35N0";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="35N8";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="51AY";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="51BI";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="52A6";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="52BX";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="63C1";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="63C3";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="73AG";
replace kr05=medkec05 if origkr05==. & kr05x~=1 & comm=="73CV";

replace kr05=medcom05 if origkr05==. & kr05x~=1 & comm=="5115";

replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="1201";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="1202";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="1210";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="1212";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="3112";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="3122";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="3127";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="3207";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="3237";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="3239";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="3249";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="3418";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="3543";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="3544";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="3545";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="5204";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="12AT";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="12CH";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="12D4";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="12E1";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="12EK";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="12EX";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="12EY";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="12FC";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="12GY";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="13B7";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="13DA";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="16AI";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="16AL";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="16AR";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="16BA";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="16C2";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="18AD";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="18AJ";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="18AT";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="18AV";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="18CI";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="31AD";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="31AR";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="31BD";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32AM";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32B1";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32CK";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32D9";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32EG";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32F9";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32FO";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32GJ";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32G2";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32GP";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32GS";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32IK";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32JR";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32K2";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32KV";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32L4";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32LE";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32M5";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32MZ";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32N1";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32NL";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32NS";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="32OY";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="33B7";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="33E8";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="33IL";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="33K7";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="33N0";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="33N6";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="33OJ";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="33OL";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="33OR";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="34AA";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="34AS";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="34B2";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="34BS";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="34BX";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35A7";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35AU";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35BT";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35C9";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35EV";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35F4";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35FQ";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35FY";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35G7";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35GW";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35HM";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35IS";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35IU";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35KM";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35LK";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35LO";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35MJ";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35N7";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35OH";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="35RA";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="63AA";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="63AE";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="63CM";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="73CW";
replace kr05=medkab05 if origkr05==. & kr05x~=1 & comm=="73EM";
********************* END OF "MANUAL" IMPUTATION  OF KR04 AND KR05 ********************************************************;

gen  owners=(kr05x~=.);
lab define owners 1 "Owners" 0 "Renters";
lab value owners owners;
lab var owners "Owner or Renter?";

replace kr04=. if _outlierkr04==1;
replace kr05=. if _outlierkr05==1;

gen _outlierkr=(_outlierkr04==1 | _outlierkr05==1);

lab var _outlierkr04 "Any outlier in kr04";
lab var _outlierkr05 "Any outlier in kr05";
lab var _outlierkr "Any outlier in kr";

* II.5 Generate variable containing information on missing values in this data file ;
****************************************************************************;
gen misskr=1 if kr04==. & kr04x~=.;
replace misskr=1 if kr05==. & kr05x~=.;
replace misskr=0 if misskr==.;
lab var misskr "Household w/ missing kr04/kr05"; 
tab misskr, m;

* II.6 Label, compress, sort, and save the data;
****************************************************************************;
lab data "KR with imputed values";
compress;
sort hhid ;
drop med* origk*;
save $dir0\b2_kr97, replace;

****************************************************************************;
* III. Book 1 - KS  Food Consumption: KS02, KS03;
****************************************************************************;
* III.1 Identify outliers;
****************************************************************************;
use hhid ks02 ks03 ks1type using $dir2\b1_ks1, clear;
format ks02 ks03 %12.0f;
compress;

gen byte y=1 if ks1type=="J" & ks02>70000 & ks02~=. ;
replace y=1  if ks1type=="N" & ks02>75000 & ks02~=. ;
replace y=1 if ks1type=="V" & ks02>211300 & ks02~=. ;
list hhid ks1type ks02 if y==1;
replace ks02=. if y==1;

gen byte z=1 if ks1type=="E" & ks03>14000 & ks03~=.;
replace z=1 if ks1type=="G" & ks03>28000 & ks03~=.;
replace z=1 if ks1type=="J" & ks03>100000 & ks03~=.;
replace z=1 if ks1type=="L" & ks03>48000 & ks03~=.;
list hhid ks1type ks03 if z==1;
replace ks03=. if z==1;

bys hhid: egen _outlierks02=max(y);
bys hhid: egen _outlierks03=max(z);
mvencode _outlierks02, mv(0);
mvencode _outlierks03, mv(0);
lab var _outlierks02 "Any outlier in ks02";
lab var _outlierks03 "Any outlier in ks03";
tab1 _outlierks02 _outlierks03;
drop y  z ;
sort hhid;

* III.2. Reshape b1_ks1.dta from long to wide;
****************************************************************************;
reshape wide ks02 ks03, i(hhid) j(ks1type) string;
gen _outlierks=(_outlierks02==1 | _outlierks03==1);
lab var _outlierks02 "Any outlier in ks02";
lab var _outlierks03 "Any outlier in ks03";
lab var _outlierks "Any outlier in ks";
aorder;
sort hhid;
save $dir0\b1_ks197wide, replace;
compress;

* III.3. Merge with kecamatan ID, etc;
****************************************************************************;
use hhid commid97 kecid kabid origea provid using $dir0\hhlist1997, clear;
sort hhid;
merge hhid using $dir0\b1_ks197wide;
tab _merge;
keep if _merge==3;
drop _merge;

* III.4. Generate median variables;
****************************************************************************;
for var ks*: egen medcomX=median(X), by(commid97);
for var ks*: egen medkecX=median(X), by(kecid);
for var ks*: egen medkabX=median(X), by(kabid);

* III.5. Imputation;
****************************************************************************;
for var ks*: gen origX=X;

for var ks*: replace X=origX if origX~=.;
for var ks02*: replace X=medcomX if X==. & origea==1 & _outlierks02~=1;
for var ks02*: replace X=medkecX if X==. & _outlierks02~=1;
for var ks02*: replace X=medkabX if X==. & _outlierks02~=1;
for var ks03*: replace X=medcomX if X==. & origea==1 & _outlierks03~=1;
for var ks03*: replace X=medkecX if X==. & _outlierks03~=1;
for var ks03*: replace X=medkabX if X==. & _outlierks03~=1;

********************* START OF "MANUAL" IMPUTATION  OF KS02 AND KS03 ********************************************************;
replace ks02A=medkabks02A if origks02A==. & commid=="32N1";
replace ks02A=medkabks02A if origks02A==. & commid=="32NL";
replace ks02AA=medkabks02AA if origks02AA==. & commid=="32N1";
replace ks02AA=medkabks02AA if origks02AA==. & commid=="32NL";

replace ks02B=medkabks02B if origks02B==. & commid=="32N1";
replace ks02BA=medkabks02BA if origks02BA==. & commid=="32N1";
replace ks02BA=medkabks02BA if origks02BA==. & commid=="32NL";

replace ks02C=medkabks02C if ks02C==. & commid=="32N1";

replace ks02CA=medkabks02CA if origks02CA==. & commid=="32N1";
replace ks02CA=medkabks02CA if origks02CA==. & commid=="32NL";
replace ks02CA=medkabks02CA if origks02CA==. & commid=="16CO";

replace ks02D=medkabks02D if origks02D==. & commid=="32N1";

replace ks02DA=medkabks02DA if origks02DA==. & commid=="32N1";

replace ks02E=medkabks02E if origks02E==. & commid=="13CU";
replace ks02E=medkabks02E if origks02E==. & commid=="32N1";
replace ks02E=medkabks02E if origks02E==. & commid=="35IS";
replace ks02E=3 if origks02E==. & commid=="31AW";

replace ks02EA=medkabks02EA if origks02EA==. & commid=="32N1";
replace ks02EA=medkabks02EA if origks02EA==. & commid=="32NL";	
replace ks02EA=medkabks02EA if origks02EA==. & commid=="3105";

replace ks02F=medkabks02F if origks02F==. & commid=="32N1";
replace ks02F=medkecks02F if origks02F==. & commid=="12CN";

replace ks02FA=medkabks02FA if origks02FA==. & commid=="32N1";

replace ks02G=medkabks02G if origks02G==. & commid=="16BH";
replace ks02G=medkabks02G if origks02G==. & commid=="32N1";

replace ks02GA=medkabks02GA if origks02GA==. & commid=="32N1";

replace ks02H=medkabks02H if origks02H==. & commid=="31AH";
replace ks02H=medkabks02H if origks02H==. & commid=="32N1";
replace ks02H=medkabks02H if origks02H==. & commid=="32NL";

replace ks02HA=. if origks02HA==. & commid=="3106";

replace ks02HA=medkabks02HA if origks02HA==. & commid=="32BV";
replace ks02HA=medkabks02HA if origks02HA==. & commid=="32KV";
replace ks02HA=medkabks02HA if origks02HA==. & commid=="32LR";
replace ks02HA=medkabks02HA if origks02HA==. & commid=="32N1";
replace ks02HA=medkabks02HA if origks02HA==. & commid=="32NL";
replace ks02HA=medkabks02HA if origks02HA==. & commid=="32OM";
replace ks02HA=medkabks02HA if origks02HA==. & commid=="33K8";

replace ks02HA=medkecks02HA if origks02HA==. & commid=="3105";
replace ks02HA=medkecks02HA if origks02HA==. & commid=="31AM";
replace ks02HA=medkecks02HA if origks02HA==. & commid=="32H6";

replace ks02I=medkabks02I if origks02I==. & commid=="32N1";

replace ks02IA=medkabks02IA if origks02IA==. & commid=="32BR";
replace ks02IA=medkabks02IA if origks02IA==. & commid=="32BV";
replace ks02IA=medkabks02IA if origks02IA==. & commid=="32NL";
replace ks02IA=medkabks02IA if origks02IA==. & commid=="32NQ";
replace ks02IA=medkabks02IA if origks02IA==. & commid=="32OW";
replace ks02IA=medkabks02IA if origks02IA==. & commid=="33OS";

replace ks02IA=medkecks02IA  if origks02IA==. & commid=="32NP";

replace ks02IB=medkabks02IB if origks02IB==. & commid=="32BR";
replace ks02IB=medkabks02IB if origks02IB==. & commid=="32BV";
replace ks02IB=medkabks02IB if origks02IB==. & commid=="32LR";
replace ks02IB=medkabks02IB if origks02IB==. & commid=="32NL";
replace ks02IB=medkabks02IB if origks02IB==. & commid=="32NQ";
replace ks02IB=medkabks02IB if origks02IB==. & commid=="32OM";
replace ks02IB=medkabks02IB if origks02IB==. & commid=="33K8";
replace ks02IB=medkabks02IB if origks02IB==. & commid=="33OS";
replace ks02IB=medkecks02IB if origks02IB==. & commid=="32NP";

replace ks02J=medkabks02J if origks02J==. & commid=="32N1";
replace ks02J=medkabks02J if origks02J==. & commid=="32NL";
replace ks02J=medkabks02J if origks02J==. & commid=="33F5";

replace ks02J=medkecks02J if origks02J==. & commid=="32NJ";

replace ks02K=medkabks02K if origks02K==. & commid=="51AM";

replace ks02L=medkabks02L if origks02L==. & commid=="32N1";
replace ks02L=medkabks02L if origks02L==. & commid=="32NL";

replace ks02M=medkabks02M if origks02M==. & commid=="32N1";
replace ks02M=medkabks02M if origks02M==. & commid=="32NL";

replace ks02N=medkabks02N if origks02N==. & commid=="32N1";
replace ks02N=medkabks02N if origks02N==. & commid=="33F5";
replace ks02N=medkabks02N if origks02N==. & commid=="35IS";

replace ks02OA=medkabks02OA if origks02OA==. & commid=="32N1";

replace ks02OB=medkabks02OB if origks02OB==. & commid=="32N1";
replace ks02P=medkabks02P if origks02P==. & commid=="32N1";

replace ks02Q=medkabks02Q if origks02Q==. & commid=="32N1";

replace ks02R=medkabks02R if origks02R==. & commid=="32N1";

replace ks02S=medkabks02S if origks02S==. & commid=="32N1";
replace ks02S=medkabks02S if origks02S==. & commid=="32NL";
replace ks02T=medkabks02T if origks02T==. & commid=="32N1";

replace ks02U=medkabks02U if origks02U==. & commid=="31AH";
replace ks02U=medkabks02U if origks02U==. & commid=="32N1";
replace ks02U=medkabks02U if origks02U==. & commid=="33FR";

replace ks02V=medkabks02V if origks02V==. & commid=="32N1";
replace ks02V=medkabks02V if origks02V==. & commid=="32NL";
replace ks02V=medkabks02V if origks02V==. & commid=="33F5";
replace ks02V=medkabks02V if origks02V==. & commid=="35IS";


replace ks02W=medkabks02W if origks02W==. & commid=="32N1";
replace ks02W=medkabks02W if origks02W==. & commid=="32NL";

replace ks02X=medkabks02X if origks02X==. & commid=="32N1";

replace ks02Y=medkabks02Y if origks02Y==. & commid=="32N1";
replace ks02Y=medkabks02Y if origks02Y==. & commid=="32NL";
replace ks02Y=medkabks02Y if origks02Y==. & commid=="33K8";

replace ks02Z=medkabks02Z if origks02Z==. & commid=="31AH";
replace ks02Z=medkabks02Z if origks02Z==. & commid=="32N1";
replace ks02Z=medkabks02Z if origks02Z==. & commid=="33F5";

**KS03
replace ks03A=medkabks03A if origks03A==. & commid=="32N1";
replace ks03A=medkabks03A if origks03A==. & commid=="63A7";

replace ks03AA=medkabks03AA if origks03AA==. & commid=="32N1";
replace ks03AA=medkabks03AA if origks03AA==. & commid=="35IP";

replace ks03B=medkabks03B if origks03B==. & commid=="32BV";
replace ks03B=medkabks03B if origks03B==. & commid=="32N1";
replace ks03B=medkabks03B if origks03B==. & commid=="32M5";

replace ks03BA=medkabks03BA if origks03BA==. & commid=="32N1";
replace ks03BA=medkabks03BA if origks03BA==. & commid=="32OW";

replace ks03C=medkabks03C if origks03C==. & commid=="32M5";
replace ks03C=medkabks03C if origks03C==. & commid=="32N1";

replace ks03CA=medkabks03CA if origks03CA==. & commid=="32N1";

replace ks03D=medkabks03D if origks03D==. & commid=="32BV";
replace ks03D=medkabks03D if origks03D==. & commid=="32N1";
replace ks03D=medkabks03D if origks03D==. & commid=="32M5";

replace ks03DA=medkabks03DA if origks03DA==. & commid=="32N1";

replace ks03E=medkabks03E if origks03E==. & commid=="32M5";
replace ks03E=medkabks03E if origks03E==. & commid=="32N1";
replace ks03E=medkabks03E if origks03E==. & commid=="33F5";

replace ks03EA=medkabks03EA if origks03EA==. & commid=="32N1";

replace ks03F=medkabks03F if origks03F==. & commid=="32BI";
replace ks03F=medkabks03F if origks03F==. & commid=="32M5";
replace ks03F=medkabks03F if origks03F==. & commid=="32N1";

replace ks03FA=medkabks03FA if origks03FA==. & commid=="32N1";

replace ks03G=medkabks03G if origks03G==. & commid=="32M5";
replace ks03G=medkabks03G if origks03G==. & commid=="32N1";

replace ks03GA=medkabks03GA if origks03GA==. & commid=="32N1";

replace ks03H=medkabks03H if origks03H==. & commid=="32M5";
replace ks03H=medkabks03H if origks03H==. & commid=="32N1";

replace ks03HA=medkabks03HA if origks03HA==. & commid=="32N1";

replace ks03I=medkabks03I if origks03I==. & commid=="32N1";

replace ks03IA=medkabks03IA if origks03IA==. & commid=="31AD";
replace ks03IA=medkabks03IA if origks03IA==. & commid=="32BR";
replace ks03IA=medkabks03IA if origks03IA==. & commid=="32BV";
replace ks03IA=medkabks03IA if origks03IA==. & commid=="32OM";
replace ks03IA=medkabks03IA if origks03IA==. & commid=="32OW";
replace ks03IA=medkecks03IA  if origks03IA==. & commid=="32OV";

replace ks03IB=medkabks03IB if origks03IB==. & commid=="32OM";

replace ks03J=medkabks03J if origks03J==. & commid=="31AH";
replace ks03J=medkabks03J if origks03J==. & commid=="32N1";
replace ks03K=medkabks03K if origks03K==. & commid=="32N1";

replace ks03L=medkabks03L if origks03L==. & commid=="32N1";

replace ks03M=medkabks03M if origks03M==. & commid=="16AT";
replace ks03M=medkabks03M if origks03M==. & commid=="32N1";
replace ks03M=medkecks03M if origks03M==. & commid=="32NO";

replace ks03N=medkabks03N if origks03N==. & commid=="16AT";
replace ks03N=medkabks03N if origks03N==. & commid=="32N1";

replace ks03OA=medkabks03OA if origks03OA==. & commid=="16AT";
replace ks03OA=medkabks03OA if origks03OA==. & commid=="32N1";

replace ks03OB=medkabks03OB if origks03OB==. & commid=="16AT";
replace ks03OB=medkabks03OB if origks03OB==. & commid=="32N1";

replace ks03P=medkabks03P if origks03P==. & commid=="16AT";
replace ks03P=medkabks03P if origks03P==. & commid=="32N1";

replace ks03Q=medkabks03Q if origks03Q==. & commid=="32N1";

replace ks03R=medkabks03R if origks03R==. & commid=="32N1";

replace ks03S=medkabks03S if origks03S==. & commid=="32N1";

replace ks03T=medkabks03T if origks03T==. & commid=="32N1";

replace ks03U=medkabks03U if origks03U==. & commid=="32N1";
replace ks03U=medkabks03U if origks03U==. & commid=="33FR";

replace ks03V=medkabks03V if origks03V==. & commid=="32N1";
replace ks03V=medkabks03V if origks03V==. & commid=="35I5";

replace ks03W=medkabks03W if origks03W==. & commid=="32N1";

replace ks03X=medkabks03X if origks03X==. & commid=="32N1";

replace ks03Y=medkabks03Y if origks03Y==. & commid=="32N1";

replace ks03Z=medkabks03Z if origks03Z==. & commid=="31AH";
replace ks03Z=medkabks03Z if origks03Z==. & commid=="32N1";
replace ks03Z=medkabks03Z if origks03Z==. & commid=="35EV";

for var ks*: replace X=medcomX if origX==. & X==.;

for var ks02*: replace X=. if _outlierks02==1;
for var ks03*: replace X=. if _outlierks03==1;

********************* END OF "MANUAL" IMPUTATION  OF KS02 AND KS03 ********************************************************;


* III.6. Generate total;
****************************************************************************;
gen sumks02=ks02A+ks02AA+ks02B+ks02BA+ks02C+ks02CA+ks02D+ks02DA+ks02E+ks02EA+ks02F+ks02FA+ks02G+ks02GA
+ks02H+ ks02HA+ks02I+ks02IA+ks02IB+ ks02J+ks02K+ks02L+ks02M+ks02N+ks02OA+ks02OB+ks02P+ks02Q+ks02S
+ks02R+ks02T+ks02U+ks02V+ks02W+ks02X+ks02Y+ks02Z;

gen sumks03=ks03A+ks03AA+ks03B+ks03BA+ks03C+ks03CA+ks03D+ks03DA+ks03E+ks03EA+ks03F+ks03FA+ks03G+ks03GA  
+ks03H+ ks03HA+ ks03I+ ks03IA+ks03IB+ ks03J+ks03K+ks03L+ks03M+ks03N+ks03OA+ks03OB+ks03P+ks03Q+ks03S 
+ks03R+ks03T+ks03U+ks03V+ks03W+ks03X+ks03Y+ks03Z;

* III.7 Generate variable containing information on missing values in this data file ;
****************************************************************************;
capture drop missks02;
capture drop missks03;
gen missks02=(sumks02==.);
gen missks03=(sumks03==.);

lab var missks02 "Household w/ at least 1 KS02 missing";
lab var missks03 "Household w/ at least 1 KS03 missing";

tab1 miss*;

* III.8 Label, sort, save the data;
****************************************************************************;
sort hhid ;
drop med* origk* sum*;
compress;
label data "Wide version of b1_ks1, with imputation";
save $dir0\b1_ks197, replace;


********************************************************************************;
* IV. KS06 (B1KS2.DTA);
********************************************************************************;
#delimit ;
* IV.1 Identify outliers;
****************************************************************************;
use hhid ks2type ks06 using $dir2\b1_ks2, clear;
gen byte z=1 if ks2type=="F1" & ks06>273000 & ks06~=.;
replace z=1 if ks2type=="B" & ks06>750000 & ks06~=.;
replace z=1 if ks2type=="E" & ks06>1700000 & ks06~=.;
** The following case of outlier is not dropped because it's F2 (arisan);
** replace z=1 if ks2type=="F2" & ks06>1750000 & ks06~=.;
list hhid ks06 ks2type if  z==1;
replace ks06=. if z==1;
sort hhid;
bys hhid: egen _outlierks06=max(z);
lab var _outlierks06 "Any outlier in ks06";
mvencode _outlierks06, mv(0);
tab _outlierks06;
sort hhid;
drop z;
compress;

* IV.2. Generate variable containing information on missing values in this data file ;
****************************************************************************;
gen   x=1 if ks06==.;
replace x=0 if ks2type=="F2";
replace x=0 if x==. ;
egen   missks06=max(x), by(hhid);
lab var missks06 "Household w/ at least 1 KS06 missing, excl. F2";
compress;
drop x;

* IV.3. Reshape b1_ks2.dta from long to wide;
****************************************************************************;
reshape wide ks06, i(hhid ) j(ks2type) string;
tab missks06;
sort hhid ;
compress;
label data "Wide version of b1_ks2";
save $dir0\b1_ks297_wide, replace;

* IV.4. Merge with commid, kecid, kabid info;
****************************************************************************;
use hhid commid97 kecid kabid provid origea using $dir0\hhlist1997, clear;
sort hhid;
merge hhid using $dir0\b1_ks297_wide;
tab _merge;
*Only keep HHs which answered Book 2;
keep if _merge==3;
drop _merge;

inspect ks06*;

* IV.5. Generate median variables;
****************************************************************************;
for var ks*:  egen medcomX=median(X), by(commid97);
for var ks*:  egen medkecX=median(X), by(kecid);
for var ks*:  egen medkabX=median(X), by(kabid);

compress ;

* IV.6. Imputation;
****************************************************************************;
for var ks*: gen origX=X;
for var ks*: replace X=medcomX if X==. & origea==1  & _outlierks06~=1;
for var ks*: replace X=medkecX if X==. & _outlierks06~=1;
for var ks*: replace X=medkabX if X==. & _outlierks06~=1;

********************* START OF "MANUAL" IMPUTATION  OF KS06 ********************************************************;
replace ks06A=medkabks06A if origks06A==. & commid=="32AR";
replace ks06A=medkabks06A if origks06A==. & commid=="32EG";
replace ks06A=medkabks06A if origks06A==. & commid=="33K8";
replace ks06A=medkecks06A if origks06A==. & commid=="13C9";
replace ks06A=medkecks06A if origks06A==. & commid=="32KF" ;

replace ks06B=medkabks06B if origks06B==. & commid=="32EG";
replace ks06B=medkabks06B if origks06B==. & commid=="32KV";
replace ks06B=medkabks06B if origks06B==. & commid=="32NL";
replace ks06B=medkabks06B if origks06B==. & commid=="32OM";
replace ks06B=medkabks06B if origks06B==. & commid=="32OW";
replace ks06B=medkabks06B if origks06B==. & commid=="34BZ";
replace ks06B=medkabks06B if origks06B==. & commid=="52AC" ;
replace ks06B=medkecks06B if origks06B==. & commid=="32KF";
replace ks06B=medkecks06B if origks06B==. & commid=="32NP" ;

replace ks06C=medkabks06C if origks06C==. & commid=="32CK";
replace ks06C=medkabks06C if origks06C==. & commid=="32EG";
replace ks06C=medkabks06C if origks06C==. & commid=="32OM";
replace ks06C=medkabks06C if origks06C==. & commid=="33K8";
replace ks06C=medkabks06C if origks06C==. & commid=="52AC" ;
replace ks06C=medkecks06C if origks06C==. & commid=="32KF";
replace ks06C=medkecks06C if origks06C==. & commid=="32NP" ;

replace ks06C1=medkabks06C1 if origks06C1==. & commid=="52AC";
replace ks06C1=medkecks06C1 if origks06C1==. & commid=="32KF" ;

replace ks06D=medkabks06D if origks06D==. & commid=="31AH";
replace ks06D=medkabks06D if origks06D==. & commid=="32BR";
replace ks06D=medkabks06D if origks06D==. & commid=="32EG";
replace ks06D=medkabks06D if origks06D==. & commid=="32LR";
replace ks06D=medkabks06D if origks06D==. & commid=="32OM";
replace ks06D=medkabks06D if origks06D==. & commid=="33OS";
replace ks06D=medkabks06D if origks06D==. & commid=="52AC";
replace ks06D=medkecks06D  if origks06D==. & commid=="3246";

replace ks06E=medkabks06E if origks06E==. & commid=="31AH";
replace ks06E=medkabks06E if origks06E==. & commid=="32BV";
replace ks06E=medkabks06E if origks06E==. & commid=="32EG";
replace ks06E=medkabks06E if origks06E==. & commid=="32KV";
replace ks06E=medkabks06E if origks06E==. & commid=="32LR";
replace ks06E=medkabks06E if origks06E==. & commid=="32NL";
replace ks06E=medkabks06E if origks06E==. & commid=="32OM";
replace ks06E=medkabks06E if origks06E==. & commid=="32OW";
replace ks06E=medkabks06E if origks06E==. & commid=="32E8";
replace ks06E=medkabks06E if origks06E==. & commid=="32K8";
replace ks06E=medkabks06E if origks06E==. & commid=="34BZ";
replace ks06E=medkabks06E if origks06E==. & commid=="52AC";
replace ks06E=medkabks06E if origks06E==. & commid=="73CR";
replace ks06E=medkecks06E if origks06E==. & commid=="13B4";
replace ks06E=medkecks06E if origks06E==. & commid=="13CU";
replace ks06E=medkecks06E if origks06E==. & commid=="3106";
replace ks06E=medkecks06E if origks06E==. & commid=="31AS";
replace ks06E=medkecks06E if origks06E==. & commid=="31AW";
replace ks06E=medkecks06E if origks06E==. & commid=="32KF";
replace ks06E=medkecks06E if origks06E==. & commid=="32NP";
replace ks06E=medkecks06E if origks06E==. & commid=="34B4";
replace ks06E=medcomks06E if origks06E==. & commid=="35Q0";

replace ks06F1=medkabks06F1 if origks06F1==. & commid=="32EG";
replace ks06F1=medkabks06F1 if origks06F1==. & commid=="33E8";
replace ks06F1=medkabks06F1 if origks06F1==. & commid=="52AC";
replace ks06F1=medkecks06F1 if origks06F1==. & commid=="32KF";

replace ks06F2=medkabks06F2 if origks06F2==. & commid=="32EG";
replace ks06F2=medkabks06F2 if origks06F2==. & commid=="52AC";
replace ks06F2=medkecks06F2  if origks06F2==. & commid=="32KF";

replace ks06G=medkabks06G if origks06G==. & commid=="32BV";
replace ks06G=medkabks06G if origks06G==. & commid=="32NQ";
replace ks06G=medkabks06G if origks06G==. & commid=="34BZ";
replace ks06G=medkabks06G if origks06G==. & commid=="52AC";
replace ks06G=medkecks06G if origks06G==. & commid=="32KF";

for var ks*: replace X=medcomX if origX==. & X==.;

for var ks06*: replace X=. if _outlierks06==1;
********************* END OF "MANUAL" IMPUTATION  OF KS06 ********************************************************;

* II.7 Generate variable containing information on missing values in this data file ;
****************************************************************************;
capture drop missks06;
gen sumks06=ks06A+ks06B+ks06C+ks06C1+ks06D+ks06E+ks06F1+ks06G;
gen missks06=(sumks06==.);
lab var missks06 "Household w/ at least 1 KS06 missing -excluding F2";
tab missks06;

* IV.8. Save the data
****************************************************************************;
compress;
drop origk* med* sumks;
sort hhid;
save $dir0\b1_ks297, replace;



********************************************************************************;
* V. KS08, KS09a,  (B1_KS3.DTA);
********************************************************************************;
#delimit ;
* V.1. Identify outliers;
****************************************************************************;
use ks08 ks09a ks3type hhid using $dir2\b1_ks3, clear;
sort hhid ks3type;

gen z=1 if ks3type=="A" & ks08>10000000 & ks08~=.;
list hhid ks08 ks3type if z==1;
replace ks08=. if z==1;
bys hhid: egen _outlierks08=max(z);
mvencode _outlierks08, mv(0);
lab var _outlierks08 "Any outlier in ks08";
sort hhid;
drop z ;
compress;

* THIS CASE HAS KS08=9999998, CHANGE INTO MISSING;
replace ks08=. if ks3type=="C" & ks08==9999998;


*ks09 no outlier;
gen _outlierks09=0;
lab var _outlierks09 "Any outlier in ks09";

*V.2. Reshape b1_ks3.dta from long to wide;
****************************************************************************;
reshape wide ks08 ks09a, i(hhid ) j(ks3type) string;
sort hhid; 
compress;
label data "Wide version of b1_ks3 created pre_pce.do";
save $dir0\b1_ks397wide, replace;

*V.3 Merge with kecamatan ID information;
****************************************************************************;
use $dir0\b1_ks397wide, clear;
sort hhid;
save $dir0\tempks397, replace;

use hhid commid97 kecid kabid provid origea using $dir0\hhlist1997, clear;
sort hhid;
merge hhid using $dir0\tempks397;
tab _merge;
*Only keep HHs which answered Book 2;
keep if _merge==3;
drop _merge;

inspect ks*;

*V.4 Generate median variables;
****************************************************************************;
for var ks*: egen medcomX=median(X), by(commid97);
for var ks*: egen medkecX=median(X), by(kecid);
for var ks*: egen medkabX=median(X), by(kabid);

*V.5. Imputation;
****************************************************************************;
for var ks*: gen origX=X;
for var ks08*: replace X=medcomX if X==. & origea==1  & _outlierks08~=1;
for var ks08*: replace X=medkecX if X==. & _outlierks08~=1;
for var ks08*: replace X=medkabX if X==. & _outlierks08~=1;
for var ks09*: replace X=medcomX if X==. & origea==1  & _outlierks09~=1;
for var ks09*: replace X=medkecX if X==. & _outlierks09~=1;
for var ks09*: replace X=medkabX if X==. & _outlierks09~=1;

********************* START OF "MANUAL" IMPUTATION  OF KS06 ********************************************************;
replace ks08A=medkabks08A if origks08A==. & commid=="31AE";
replace ks08A=medkabks08A if origks08A==. & commid=="32BP";
replace ks08A=medkabks08A if origks08A==. & commid=="32BR";
replace ks08A=medkabks08A if origks08A==. & commid=="32BV";
replace ks08A=medkabks08A if origks08A==. & commid=="32EG";
replace ks08A=medkabks08A if origks08A==. & commid=="32KV";
replace ks08A=medkabks08A if origks08A==. & commid=="32NL";
replace ks08A=medkabks08A if origks08A==. & commid=="32OM";
replace ks08A=medkabks08A if origks08A==. & commid=="32OW";
replace ks08A=medkabks08A if origks08A==. & commid=="32K8";
replace ks08A=medkabks08A if origks08A==. & commid=="32OS";
replace ks08A=medkabks08A if origks08A==. & commid=="32KV";
replace ks08A=medkabks08A if origks08A==. & commid=="52AC";
replace ks08A=medkecks08A if origks08A==. & commid=="13C9";
replace ks08A=medkecks08A if origks08A==. & commid=="3102";
replace ks08A=medkecks08A if origks08A==. & commid=="3105";
replace ks08A=medkecks08A if origks08A==. & commid=="32KF";
replace ks08A=medkecks08A if origks08A==. & commid=="32NP";
replace ks08A=medkecks08A if origks08A==. & commid=="34B4";
replace ks08A=medkecks08A if origks08A==. & commid=="63AO";
replace ks08A=medkecks08A if origks08A==. & commid=="63CJ";

replace ks08B=medkabks08B if origks08B==. & commid=="32EG";
replace ks08B=medkabks08B if origks08B==. & commid=="34BZ";
replace ks08B=medkabks08B if origks08B==. & commid=="52AC";
replace ks08B=medkabks08B if origks08B==. & commid=="32KF";
replace ks08B=medkabks08B if origks08B==. & commid=="63CJ";


replace ks08C=medkabks08C if origks08C==. & commid=="32BP";
replace ks08C=medkabks08C if origks08C==. & commid=="32BR";
replace ks08C=medkabks08C if origks08C==. & commid=="32BV";
replace ks08C=medkabks08C if origks08C==. & commid=="32EG";
replace ks08C=medkabks08C if origks08C==. & commid=="32KV";
replace ks08C=medkabks08C if origks08C==. & commid=="32LR";
replace ks08C=medkabks08C if origks08C==. & commid=="32NL";
replace ks08C=medkabks08C if origks08C==. & commid=="32OM";
replace ks08C=medkabks08C if origks08C==. & commid=="32ON";
replace ks08C=medkabks08C if origks08C==. & commid=="32OW";
replace ks08C=medkabks08C if origks08C==. & commid=="33E8";
replace ks08C=medkabks08C if origks08C==. & commid=="33K5";
replace ks08C=medkabks08C if origks08C==. & commid=="33K8";
replace ks08C=medkabks08C if origks08C==. & commid=="33OS";
replace ks08C=medkabks08C if origks08C==. & commid=="52AC";
replace ks08C=medkecks08C if origks08C==. & commid=="32KF";
replace ks08C=medkecks08C if origks08C==. & commid=="32NJ";
replace ks08C=medkecks08C if origks08C==. & commid=="32NP";
replace ks08C=medkecks08C if origks08C==. & commid=="63AO";
replace ks08C=medkecks08C if origks08C==. & commid=="63CJ";



replace ks08D=medkabks08D if origks08D==. & commid=="31AH";
replace ks08D=medkabks08D if origks08D==. & commid=="32BI";
replace ks08D=medkabks08D if origks08D==. & commid=="32BP";
replace ks08D=medkabks08D if origks08D==. & commid=="32BV";
replace ks08D=medkabks08D if origks08D==. & commid=="32EG";
replace ks08D=medkabks08D if origks08D==. & commid=="32LR";
replace ks08D=medkabks08D if origks08D==. & commid=="32NL";
replace ks08D=medkabks08D if origks08D==. & commid=="32OM";
replace ks08D=medkabks08D if origks08D==. & commid=="32OW";
replace ks08D=medkabks08D if origks08D==. & commid=="33E8";
replace ks08D=medkabks08D if origks08D==. & commid=="34BZ";
replace ks08D=medkabks08D if origks08D==. & commid=="34CC";
replace ks08D=medkabks08D if origks08D==. & commid=="35QY";
replace ks08D=medkabks08D if origks08D==. & commid=="52AC";
replace ks08D=medkabks08D if origks08D==. & commid=="63DI";
replace ks08D=medkecks08D if origks08D==. & commid=="31AW";
replace ks08D=medkecks08D if origks08D==. & commid=="32C2";
replace ks08D=medkecks08D if origks08D==. & commid=="32KF";
replace ks08D=medkecks08D if origks08D==. & commid=="32LJ";
replace ks08D=medkecks08D if origks08D==. & commid=="32NJ";
replace ks08D=medkecks08D if origks08D==. & commid=="32NP";
replace ks08D=medkecks08D if origks08D==. & commid=="32OV";
replace ks08D=medkecks08D if origks08D==. & commid=="52BW";
replace ks08D=medkecks08D if origks08D==. & commid=="63AO";
replace ks08D=medkecks08D if origks08D==. & commid=="63CJ";

replace ks08E=medkabks08E if origks08E==. & commid=="13B6";
replace ks08E=medkabks08E if origks08E==. & commid=="16BH" ;
replace ks08E=medkabks08E if origks08E==. & commid=="31AH" ;
replace ks08E=medkabks08E if origks08E==. & commid=="32AR";
replace ks08E=medkabks08E if origks08E==. & commid=="32BV";
replace ks08E=medkabks08E if origks08E==. & commid=="32CK";
replace ks08E=medkabks08E if origks08E==. & commid=="32EG" ;
replace ks08E=medkabks08E if origks08E==. & commid=="32KV" ;
replace ks08E=medkabks08E if origks08E==. & commid=="32LR";
replace ks08E=medkabks08E if origks08E==. & commid=="32NL";
replace ks08E=medkabks08E if origks08E==. & commid=="32OW";
replace ks08E=medkabks08E if origks08E==. & commid=="33E8" ;
replace ks08E=medkabks08E if origks08E==. & commid=="33G8" ;
replace ks08E=medkabks08E if origks08E==. & commid=="33K8";
replace ks08E=medkabks08E if origks08E==. & commid=="33KK";
replace ks08E=medkabks08E if origks08E==. & commid=="33KL";
replace ks08E=medkabks08E if origks08E==. & commid=="33NK" ;
replace ks08E=medkabks08E if origks08E==. & commid=="33OS" ;
replace ks08E=medkabks08E if origks08E==. & commid=="34BZ";
replace ks08E=medkabks08E if origks08E==. & commid=="35IS";
replace ks08E=medkabks08E if origks08E==. & commid=="35MO";
replace ks08E=medkabks08E if origks08E==. & commid=="35QT" ;
replace ks08E=medkabks08E if origks08E==. & commid=="35QX" ;
replace ks08E=medkabks08E if origks08E==. & commid=="35RC";
replace ks08E=medkabks08E if origks08E==. & commid=="5206";
replace ks08E=medkecks08E if origks08E==. & commid=="31AW";
replace ks08E=medkecks08E if origks08E==. & commid=="31AZ";
replace ks08E=medkecks08E if origks08E==. & commid=="31BC";
replace ks08E=medkecks08E if origks08E==. & commid=="32C2";
replace ks08E=medkecks08E if origks08E==. & commid=="32K3";
replace ks08E=medkecks08E if origks08E==. & commid=="32K4";
replace ks08E=medkecks08E if origks08E==. & commid=="32KF";
replace ks08E=medkecks08E if origks08E==. & commid=="32LF";
replace ks08E=medkecks08E if origks08E==. & commid=="32LJ";
replace ks08E=medkecks08E if origks08E==. & commid=="52BW";


replace ks08F=medkabks08F if origks08F==. & commid=="32D9";
replace ks08F=medkabks08F if origks08F==. & commid=="32EG";
replace ks08F=medkabks08F if origks08F==. & commid=="33E8" ;
replace ks08F=medkabks08F if origks08F==. & commid=="52AC";

replace ks08G=medkabks08G if origks08G==. & commid=="31AK";
replace ks08G=medkabks08G if origks08G==. & commid=="31AN";
replace ks08G=medkabks08G if origks08G==. & commid=="32BI";
replace ks08G=medkabks08G if origks08G==. & commid=="32BV";
replace ks08G=medkabks08G if origks08G==. & commid=="32EG";
replace ks08G=medkabks08G if origks08G==. & commid=="32NL";
replace ks08G=medkabks08G if origks08G==. & commid=="32NQ";
replace ks08G=medkabks08G if origks08G==. & commid=="32ON";
replace ks08G=medkabks08G if origks08G==. & commid=="33E8";
replace ks08G=medkabks08G if origks08G==. & commid=="35QY";
replace ks08G=medkabks08G if origks08G==. & commid=="52AC";
replace ks08G=medkabks08G if origks08G==. & commid=="63CM";
replace ks08G=medkecks08G if origks08G==. & commid=="13BV";
replace ks08G=medkecks08G if origks08G==. & commid=="31A9";
replace ks08G=medkecks08G if origks08G==. & commid=="32K3";
replace ks08G=medkecks08G if origks08G==. & commid=="32KF";

*ks09a
replace ks09aA=medkabks09aA if origks09aA==. & commid=="32BV";
replace ks09aA=medkabks09aA if origks09aA==. & commid=="32EG";
replace ks09aA=medkabks09aA if origks09aA==. & commid=="33K8";
replace ks09aA=medkabks09aA if origks09aA==. & commid=="34BE";
replace ks09aA=medkabks09aA if origks09aA==. & commid=="34CC";
replace ks09aA=medkabks09aA if origks09aA==. & commid=="35C9";
replace ks09aA=medkabks09aA if origks09aA==. & commid=="52AC";
replace ks09aA=medkabks09aA if origks09aA==. & commid=="63CM";
replace ks09aA=medkecks09aA if origks09aA==. & commid=="16A4";
replace ks09aA=medkecks09aA if origks09aA==. & commid=="3105" ;
replace ks09aA=medkecks09aA if origks09aA==. & commid=="32KF" ;
replace ks09aA=medkecks09aA if origks09aA==. & commid=="35BS" ;
replace ks09aA=medkecks09aA if origks09aA==. & commid=="63AO";

replace ks09aB=medkabks09aB if origks09aB==. & commid=="32EG";
replace ks09aB=medkabks09aB if origks09aB==. & commid=="34BE";
replace ks09aB=medkabks09aB if origks09aB==. & commid=="52AC";
replace ks09aB=medkecks09aB if origks09aB==. & commid=="32KF";

replace ks09aC=medkabks09aC if origks09aC==. & commid=="32EG";
replace ks09aC=medkabks09aC if origks09aC==. & commid=="33E8";
replace ks09aC=medkabks09aC if origks09aC==. & commid=="33K8";
replace ks09aC=medkabks09aC if origks09aC==. & commid=="35QT";
replace ks09aC=medkabks09aC if origks09aC==. & commid=="52AC";
replace ks09aC=medkecks09aC if origks09aC==. & commid=="32KF";

replace ks09aD=medkabks09aD if origks09aD==. & commid=="32EG";
replace ks09aD=medkabks09aD if origks09aD==. & commid=="33E8";
replace ks09aD=medkabks09aD if origks09aD==. & commid=="52AC";
replace ks09aD=medkecks09aD if origks09aD==. & commid=="32KF";

replace ks09aF=medkabks09aF if origks09aF==. & commid=="32EG";
replace ks09aF=medkabks09aF if origks09aF==. & commid=="33E8";
replace ks09aF=medkabks09aF if origks09aF==. & commid=="52AC";
replace ks09aF=medkecks09aF if origks09aF==. & commid=="32KF";

for var ks*: replace X=medcomX if origX==. & X==.;

for var ks08*: replace X=. if _outlierks08==1;
for var ks09*: replace X=. if _outlierks09==1;

********************* END OF "MANUAL" IMPUTATION  FOR KR08 AND KR09 ********************************************************;

inspect ks*;

compress ;
sort hhid;

* V.6. Generate variable containing information on missing values in this data file ;
****************************************************************************;
gen sumks08=ks08A+ks08B+ks08C+ks08D+ks08E+ks08F+ks08G;
capture drop missks08;
gen missks08=(sumks08==.);

gen sumks09=ks09aA+ks09aB+ks09aC+ks09aD+ks09aF;
capture drop missks09;
gen missks09=(sumks09==.);

*V.7. Save the data;
****************************************************************************;
lab var  missks08 "Household w/ at least 1 KS08 missing";
lab var  missks09 "Household w/ at least 1 KS09a missing";
tab1 miss*;
drop med* origk* sum*;
compress;
sort hhid;

save $dir0\b1_ks397, replace;

********************************************************************************;
* VI. B1_KS0;
********************************************************************************;
#delimit ;
use  hhid ks04b ks07a ks10aa ks10ab ks11aa ks11ab ks12aa ks12ab ks12bb using $dir2\b1_ks0, clear;
sort hhid;

merge hhid using $dir0\hhlist1997;
tab _merge;
keep if _merge==3;
drop _merge commid93;


* VI.1 Identifying outliers;
****************************************************************************;
gen _outlierks0=1 if ks04b>500000 & ks04b~=.;
list hhid ks04b  if ks04b>500000 & ks04b~=.;
replace ks04b=. if ks04b>500000 & ks04b~=.;

replace _outlierks0=1 if ks07a>3000000 & ks07a~=.; 
list hhid ks07a if ks07a>3000000 & ks07a~=.;
replace ks07a=. if ks07a>3000000 & ks07a~=.;

replace _outlierks0=1 if ks11aa>2800000 & ks11aa~=.;
list hhid ks11aa if ks11aa>2800000 & ks11aa~=.;
replace ks11aa=. if ks11aa>2800000 & ks11aa~=.;

lab var _outlierks0 "Any outlier in ks0.dta";
mvencode _outlierks0, mv(0);
tab _outlierks0;

* VI.2  Generate medians;
****************************************************************************;
for var ks*: egen medcomX=median(X), by(commid97);
for var ks*: egen medkecX=median(X), by(kecid);
for var ks*: egen medkabX=median(X), by(kabid);


* VI.3 Imputation
****************************************************************************;
for var ks*: gen origX=X;
for var ks*: replace X=medcomX if X==. & origea==1  & _outlierks0~=1;
for var ks*: replace X=medkecX if X==. & _outlierks0~=1;
for var ks*: replace X=medkabX if X==. & _outlierks0~=1;

********** START OF THE 'MANUAL' IMPUTATION OF KS04B, KS07A, KS10AA, KS10AB, KS11AA, KS11AB, KS12AA, KS12AB, KS12BB*************;

replace ks04b=medkabks04b  if origks04b==. & commid=="32BP";
replace ks04b=medkabks04b  if origks04b==. & commid=="32BR";
replace ks04b=medkabks04b  if origks04b==. & commid=="32BS";
replace ks04b=medkabks04b  if origks04b==. & commid=="32BV";
replace ks04b=medkabks04b  if origks04b==. & commid=="32C2";
replace ks04b=medkabks04b  if origks04b==. & commid=="32LE";
replace ks04b=medkabks04b  if origks04b==. & commid=="32LR";
replace ks04b=medkabks04b  if origks04b==. & commid=="32LU";
replace ks04b=medkabks04b  if origks04b==. & commid=="32NQ";
replace ks04b=medkabks04b  if origks04b==. & commid=="32ON";
replace ks04b=medkabks04b  if origks04b==. & commid=="32OW";
replace ks04b=medkabks04b  if origks04b==. & commid=="32OX";
replace ks04b=medkabks04b  if origks04b==. & commid=="33OS";
replace ks04b=medkabks04b  if origks04b==. & commid=="35IP";
replace ks04b=medkecks04b if origks04b==. & commid=="3246";
replace ks04b=medkecks04b if origks04b==. & commid=="32K3";
replace ks04b=medkecks04b if origks04b==. & commid=="32K4";
replace ks04b=medkecks04b if origks04b==. & commid=="32KF";
replace ks04b=medkecks04b if origks04b==. & commid=="32LD";
replace ks04b=medkecks04b if origks04b==. & commid=="32NJ";

replace ks07a=medkabks07a   if origks07a==. & commid=="31AN";
replace ks07a=medkabks07a   if origks07a==. & commid=="3246";
replace ks07a=medkabks07a   if origks07a==. & commid=="32BI";
replace ks07a=medkabks07a   if origks07a==. & commid=="32BV";
replace ks07a=medkabks07a   if origks07a==. & commid=="32CK";
replace ks07a=medkabks07a   if origks07a==. & commid=="32EG";
replace ks07a=medkabks07a   if origks07a==. & commid=="32JR";
replace ks07a=medkabks07a   if origks07a==. & commid=="32LU";
replace ks07a=medkabks07a   if origks07a==. & commid=="32NL";
replace ks07a=medkabks07a   if origks07a==. & commid=="32NP";
replace ks07a=medkabks07a   if origks07a==. & commid=="32NQ";
replace ks07a=medkabks07a   if origks07a==. & commid=="32OM";
replace ks07a=medkabks07a   if origks07a==. & commid=="32OX";
replace ks07a=medkabks07a   if origks07a==. & commid=="52AC";
replace ks07a=medkabks07a   if origks07a==. & commid=="63CM";
replace ks07a=medkecks07a if origks07a==. & commid=="32K3";
replace ks07a=medkecks07a if origks07a==. & commid=="32K4";
replace ks07a=medkecks07a if origks07a==. & commid=="32K6";
replace ks07a=medkecks07a if origks07a==. & commid=="32KF";
replace ks07a=medkecks07a if origks07a==. & commid=="32LD";
replace ks07a=medkecks07a if origks07a==. & commid=="32LJ";

replace ks10aa=medkabks10aa    if origks10aa==. & commid=="32EG";
replace ks10aa=medkabks10aa    if origks10aa==. & commid=="52AC";
replace ks10aa=medkecks10aa if origks10aa==. & commid=="31AW";
replace ks10aa=medkecks10aa if origks10aa==. & commid=="32KF";
replace ks10aa=medkecks10aa if origks10aa==. & commid=="63CJ";

replace ks10ab=medkabks10ab    if origks10ab==. & commid=="31A1";
replace ks10ab=medkabks10ab    if origks10ab==. & commid=="52AC";
replace ks10ab=medkecks10ab if origks10ab==. & commid=="32KF";

replace ks11aa=medkabks11aa   if origks11aa==. & commid=="13CX";
replace ks11aa=medkabks11aa   if origks11aa==. & commid=="32EG";
replace ks11aa=medkabks11aa   if origks11aa==. & commid=="32NL";
replace ks11aa=medkabks11aa   if origks11aa==. & commid=="33E8";
replace ks11aa=medkabks11aa   if origks11aa==. & commid=="52AC";
replace ks11aa=medkecks11aa if origks11aa==. & commid=="32KF";
replace ks11aa=medkecks11aa if origks11aa==. & commid=="32NP";
replace ks11aa=medkecks11aa if origks11aa==. & commid=="63CJ";

replace ks11ab=medkabks11ab    if origks11ab==. & commid=="31A1";
replace ks11ab=medkabks11ab    if origks11ab==. & commid=="33E8";
replace ks11ab=medkabks11ab    if origks11ab==. & commid=="33K8";
replace ks11ab=medkabks11ab    if origks11ab==. & commid=="33OS";
replace ks11ab=medkabks11ab    if origks11ab==. & commid=="52AC";
replace ks11ab=medkabks11ab    if origks11ab==. & commid=="63CM";
replace ks11ab=medkecks11ab if origks11ab==. & commid=="32KF";

replace ks12aa=medkabks12aa   if origks12aa==. & commid=="32EG";
replace ks12aa=medkabks12aa   if origks12aa==. & commid=="32NL";
replace ks12aa=medkabks12aa   if origks12aa==. & commid=="33E8";
replace ks12aa=medkabks12aa   if origks12aa==. & commid=="52AC";
replace ks12aa=medkecks12aa if origks12aa==. & commid=="32KF";
replace ks12aa=medkecks12aa if origks12aa==. & commid=="32NP";
replace ks12aa=medkecks12aa if origks12aa==. & commid=="63CJ";

replace ks12ab=medkabks12ab   if origks12ab==. & commid=="31A1";
replace ks12ab=medkabks12ab   if origks12ab==. & commid=="33E8";
replace ks12ab=medkabks12ab   if origks12ab==. & commid=="52AC";
replace ks12ab=medkecks12ab if origks12ab==. & commid=="32KF";

replace ks12bb=medkabks12bb   if origks12bb==. & commid=="31A1";
replace ks12bb=medkabks12bb   if origks12bb==. & commid=="33E8";
replace ks12bb=medkabks12bb   if origks12bb==. & commid=="52AC";
replace ks12bb=medkecks12bb if origks12bb==. & commid=="32KF";

for var ks07a* ks10* ks1*: replace X=. if _outlierks0==1;

********** END OF THE 'MANUAL' IMPUTATION OF KS04B, KS07A, KS10AA, KS10AB, KS11AA, KS11AB, KS12AA, KS12AB, KS12BB*************;

* VI.4 Generate variable containing information on missing values in this data file ;
****************************************************************************;
gen miss4b=1 if ks04b==.;
lab var miss4b "Household with missing ks04b";
mvencode miss4b, mv(0);
tab miss4b;

gen miss7a=1 if ks07a==.;
lab var miss7a "Household with missing ks07a";
mvencode miss7a, mv(0);
tab miss7a;

gen miss10aa=1 if ks10aa==.;
lab var miss10aa "Household with missing ks10aa";
mvencode miss10aa, mv(0);
tab miss10aa;

gen miss10ab=1 if ks10ab==.;
lab var miss10ab "Household with missing ks10ab";
mvencode miss10ab, mv(0);
tab miss10ab;

gen miss11aa=1 if ks11aa==.;
lab var miss11aa "Household with missing ks11aa";
mvencode miss11aa, mv(0);
tab miss11aa;

gen miss11ab=1 if ks11ab==.;
lab var miss11aa "Household with missing ks11ab";
mvencode miss11ab, mv(0);
tab miss11ab;

gen miss12aa=1 if ks12aa==.;
lab var miss12aa "Household with missing ks12aa";
mvencode miss12aa, mv(0);
tab miss12aa;

gen miss12ab=1 if ks12ab==.;
lab var miss12ab "Household with missing ks12ab";
mvencode miss12ab, mv(0);
tab miss12ab;

gen miss12bb=1 if ks12bb==.;
lab var miss12bb "Household with missing ks12bb";
mvencode miss12bb, mv(0);
tab miss12bb;


drop  med* origks*;
sort hhid ;
compress ;
label data "Shorter version of b1_ks0 created using pre_pce.do";
save $dir0\b1_ks097, replace;

************************************************************************************;
* VII. MERGE ALL EXPENDITURE FILES;
************************************************************************************;
use $dir0\b1_ks097, clear;
merge hhid  using $dir0\b1_ks197;
tab _merge;
* _merge=1 hh w/ outliers in ks02/ks03;
* _merge=2 hh w/ outliers in ks04b/ks07a/ks11aa;
list hhid _merge if _merge~=3;
*keep if _merge==3;
rename _merge _m1;
sort hhid ;
merge hhid  using $dir0\b1_ks297;
tab _merge;
* _merge=1 hh w/ outliers in ks06;
* _merge=2 hh w/ outliers in ks02/ks03/ks04b/ks07a/ks11aa;
list hhid _merge if _merge~=3;
*keep if _merge==3;
rename _merge _m2 ;
sort hhid ;
merge hhid  using $dir0\b1_ks397;
tab _merge;
* _merge=1 hh w/ outliers in ks08/ks09a;
* _merge=2 hh w/ outliers in ks02/ks03/ks04b/ks07a/ks11aa/ks06 ;
list hhid _merge if _merge~=3;
*keep if _merge==3;
rename _merge _m3;
sort hhid ;
merge hhid  using $dir0\b2_kr97;
tab _merge;
* _merge=1 hh in Book 1-KS but not in Book 2 - KR;
* _merge=2 hh in Book 2-KR but not in Book 1 - KS;
list hhid _merge if _merge~=3;
*keep if _merge==3;
rename _merge _mkr;

gen z=missks02+missks03+missks06+miss4b+miss7a+missks08+missks09+misskr+miss10aa+miss10ab+miss11aa+miss11ab+miss12aa
+miss12ab+miss12bb;
gen missing=1 if z>0 & z~=.; 
replace missing=0 if missing==. & z~=.;

drop z ;
lab var missing "Household with at least 1 part of expenditure missing";
tab missing, m;
save $dir0\pre_pce97.dta, replace;


******************************************************************************;
*VIII. PCE  ;
******************************************************************************;
use $dir0\pre_pce97,clear;

**FOOD (KS02, KS03, AND KS04B), MONTHLY;
** Market purchased;
gen mrice=ks02A*52/12;
gen mstaple=(ks02A+ks02B+ks02C+ks02D+ks02E)*52/12 ;
gen mvege=(ks02F+ks02G+ks02H)*52/12;
gen mdried=(ks02I+ks02J)*52/12 ;
gen mmeat=(ks02K+ks02L+ks02OA+ks02OB)*52/12 ;
gen mfish=(ks02M+ks02N)*52/12;
gen mdairy=(ks02P+ks02Q)*52/12; 
gen mspices=(ks02R+ks02S+ks02T+ks02U+ks02V)*52/12;
gen msugar=(ks02W+ks02AA)*52/12; 
gen moil=(ks02X+ks02Y)*52/12;
gen mbeve=(ks02Z+ks02BA+ks02CA+ks02DA+ks02EA)*52/12 ;
gen maltb=(ks02FA+ks02GA+ks02HA)*52/12 ;
gen msnack=(ks02IA)*52/12;
gen mfdout=(ks02IB)*52/12;

**Self-produced;
gen irice=ks03A*52/12;
gen istaple=(ks03A+ks03B+ks03C+ks03D+ks03E)*52/12 ;
gen ivege=(ks03F+ks03G+ks03H)*52/12;
gen idried=(ks03I+ks03J)*52/12 ;
gen imeat=(ks03K+ks03L+ks03OA+ks03OB)*52/12 ;
gen ifish=(ks03M+ks03N)*52/12;
gen idairy=(ks03P+ks03Q)*52/12; 
gen ispices=(ks03R+ks03S+ks03T+ks03U+ks03V)*52/12;
gen isugar=(ks03W+ks03AA)*52/12; 
gen ioil=(ks03X+ks03Y)*52/12;
gen ibeve=(ks03Z+ks03BA+ks03CA+ks03DA+ks03EA)*52/12 ;
gen ialtb=(ks03FA+ks03GA+ks03HA)*52/12 ;
gen isnack=(ks03IA)*52/12;
gen ifdout=(ks03IB)*52/12;
 
*Consumption=market purchased+self-produced;
gen xrice=mrice+irice;
gen xstaple=mstaple+istaple;
gen xvege=mvege+ivege;
gen xdried=mdried+idried;
gen xmeat=mmeat+imeat;
gen xfish=mfish+ifish;
gen xdairy=mdairy+idairy;
gen xspices=mspices+ispices; 
gen xsugar=msugar+isugar;
gen xoil=moil+ioil;
gen xbeve=mbeve+ibeve;
gen xaltb=maltb+ialtb;
gen xsnack=msnack+isnack;
gen xfdout=mfdout+ifdout; 

*TOTAL MONTHLY;
*mfood: total ks02;
gen mfood =mstaple+mvege+mdried+mmeat+mfish+mdairy+mspices+msugar+moil+mbeve+maltb+msnack+mfdout;

*ifood: total ks03;
gen ifood =istaple+ivege+idried+imeat+ifish+idairy+ispices+isugar+ioil+ibeve+ialtb+isnack+ifdout;

*xfdtout: Food transfer, ks04b;
gen xfdtout=ks04b*52/12;
lab var xfdtout "Monthly food transfer, ks04b";

******************************************************************;
*MONTHLY EXPENDITURE ON FOOD: KS02 AND KS03 (NOT INCLUDING KS04B)
*****************************************************************;
gen xfood =xstaple+xvege+xdried+xmeat+xfish+xdairy+xspices+xsugar+xoil+xbeve+xaltb+xsnack+xfdout;
lab var xfood "Monthly food consumption, ks02 and ks03";

lab var mrice "Monthly food consumption ks02: rice"; 
lab var mstaple "Monthly food consumption ks02: staple"; 
lab var mvege "Monthly food consumption ks02: vegetable, fruit";
lab var mdried "Monthly food consumption ks02: dried food";
lab var mmeat "Monthly food consumption ks02: meat";
lab var mfish "Monthly food consumption ks02: fish";
lab var mdairy "Monthly food consumption ks02: dairy";
lab var mspices "Monthly food consumption ks02: spices";
lab var msugar "Monthly food consumption ks02: sugar";
lab var moil "Monthly food consumption ks02: oil" ;
lab var mbeve "Monthly food consumption ks02: beverages";
lab var maltb "Monthly food consumption ks02: alcohol/tobacco";
lab var msnack "Monthly food consumption ks02: snacks";
lab var mfdout "Monthly food consumption ks02: food out of home";

lab var irice "Monthly food consumption ks03: rice";
lab var istaple "Monthly food consumption ks03: staple"; 
lab var ivege "Monthly food consumption ks03: vegetable, fruit";
lab var idried "Monthly food consumption ks03: dried food";
lab var imeat "Monthly food consumption ks03: meat";
lab var ifish "Monthly food consumption ks03: fish";
lab var idairy "Monthly food consumption ks03: dairy";
lab var ispices "Monthly food consumption ks03: spices";
lab var isugar "Monthly food consumption ks03: sugar";
lab var ioil "Monthly food consumption ks03: oil" ;
lab var ibeve "Monthly food consumption ks03: beverages";
lab var ialtb "Monthly food consumption ks03: alcohol/tobacco";
lab var isnack "Monthly food consumption ks03: snacks";
lab var ifdout "Monthly food consumption ks03: food out of home";

lab var xrice "Monthly food consumption ks02+ks03: rice" ;
lab var xstaple "Monthly food consumption ks02+ks03: staple"; 
lab var xvege "Monthly food consumption ks02+ks03: vegetable, fruit";
lab var xdried "Monthly food consumption ks02+ks03: dried food";
lab var xmeat "Monthly food consumption ks02+ks03: meat";
lab var xfish "Monthly food consumption ks02+ks03: fish";
lab var xdairy "Monthly food consumption ks02+ks03: dairy";
lab var xspices "Monthly food consumption ks02+ks03: spices";
lab var xsugar "Monthly food consumption ks02+ks03: sugar";
lab var xoil "Monthly food consumption ks02+ks03: oil" ;
lab var xbeve "Monthly food consumption ks02+ks03: beverages";
lab var xaltb "Monthly food consumption ks02+ks03: alcohol/tobacco";
lab var xsnack "Monthly food consumption ks02+ks03: snacks";
lab var xfdout "Monthly food consumption ks02+ks03: food out of home";

lab var mfood "Monthly food cons.,market purch. all ks02";
lab var ifood "Monthly food cons.,own-prod. all ks03";


*END OF FOOD;

* NON-FOOD FROM KS2TYPE (KS06), MONTHLY;

rename ks06A xutility;
rename ks06B xpersonal;
rename ks06C xhhgood;
rename ks06C1 xdomest;
rename ks06D xrecreat;
rename ks06E xtransp;
rename ks06F1 xlottery;
rename ks06F2 xarisan;
rename ks06G xtransf2;

lab var xutility "Monthly expend. on utility ks06A";
lab var xpersonal "Monthly expend. on personal goods ks06B";
lab var xhhgood "Monthly expend. on hh goods ks06C";
lab var xdomest "Monthly expend. on domestic goods ks06C1";
lab var xrecreat "Monthly expend. on recreation ks06D";
lab var xtransp "Monthly expend. on transport. ks06E";
lab var xlottery "Monthly expend. on lottery ks06F1";
lab var xarisan "Monthly expend. on arisan ks06F2";
lab var xtransf2 "Monthly expend. on transfer ks06G";

rename ks07a inonfood;
lab var inonfood "Monthly non-food own-produce (ks07a)";


*xnonfood2 IS ALL KS06 EXCLUDING TRANSFER AND ARISAN ;
gen xnonfood2=xutility+xpersonal+xhhgood+xdomest+xrecreat+xtransp+xlottery ;

*totks06 IS ALL KS06 ;
gen totks06=xnonfood2+xtransf2+xarisan;

lab var xnonfood2 "Monthly non-food expend. ks2type, transfer & arisan excl.";
lab var totks06 "Monthly non-food expend. ks2type, transfer & arisan incl.";
sort hhid ;

*NON-FOOD FROM KS3TYPE (KS08, KS09A), CONVERTED TO MONTHLY FIGURES;

gen mcloth=ks08A/12;
gen mfurn=ks08B/12;
gen mmedical=ks08C/12;
gen mcerem=ks08D/12;
gen mtax=ks08E/12;
gen mother=ks08F/12;
gen mtransf3=ks08G/12;

gen icloth=ks09aA/12;
gen ifurn=ks09aB/12;
gen imedical=ks09aC/12;
gen icerem=ks09aD/12;
gen iother=ks09aF/12;

gen xcloth=mcloth+icloth;
gen xfurn=mfurn+ifurn;
gen xmedical=mmedical+imedical;
gen xcerem=mcerem+icerem;
gen xtax=mtax;
gen xother=mother+iother;
gen xtransf3=mtransf3;
	
*xnonfood3 IS ALL KS08 and KS09a EXCLUDING TRANSFER ;
gen xnonfood3=xcloth+xfurn+xmedical+xcerem+xtax+xother; 

lab var mcloth "Monthly non-food expend: clothing,ks08A";
lab var mfurn "Monthly non-food expend: furniture,ks08B";
lab var mmedical "Monthly non-food expend: medical,ks08C";
lab var mcerem "Monthly non-food expend: ceremony,ks08D";
lab var mtax "Monthly non-food expend: tax,ks08E";
lab var mother "Monthly non-food expend: other,ks08F";
lab var mtransf3 "Monthly non-food expend: transfer,ks08G";

lab var icloth "Monthly non-food expend: clothing,ks09aA";
lab var ifurn "Monthly non-food expend: furniture,ks09aB";
lab var imedical "Monthly non-food expend: medical,ks09aC";
lab var icerem "Monthly non-food expend: ceremony,ks09aD";
lab var iother "Monthly non-food expend: other,ks09aF";

lab var xcloth "Monthly non-food expend: clothing,ks08A+ks09aA";
lab var xfurn "Monthly non-food expend: furniture,ks08B+ks09aB";
lab var xmedical "Monthly non-food expend: medical,ks08C+ks09aC";
lab var xcerem "Monthly non-food expend: ceremony,ks08D+ks09aD";
lab var xtax "Monthly non-food expend: tax,ks08E";
lab var xother "Monthly non-food expend: other,ks08F+ks09aF";
lab var xtransf3 "Monthly non-food expend: transfer,ks08G";

lab var xnonfood3 "Monthly non-food expend. ks3type(all ks08,ks09a excl. ks08G)";


**HOUSING;

gen xhrent=kr04 if kr04x~=.;
gen xhown=kr05 if kr05x~=.;
gen xhouse=kr04 if kr04x~=.;
replace xhouse=kr05 if kr05x~=.;

lab var xhrent "Monthly expend. on housing:rent (kr04)";
lab var xhown "Monthly expend. on housing:own  (kr05)";
lab var xhouse "Monthly expend. on housing (kr04/kr05)"; 

********;
*EDUCATIOn;

gen xedutuit=ks10aa/12;
gen xeduunif=ks11aa/12;
gen xedutran=ks12aa/12;
gen xeduc=xedutuit+xeduunif+xedutran;
gen xedutuitout=ks10ab/12;
gen xeduunifout=ks11ab/12;
gen xedutranout=ks12ab/12;
gen xedubordout=ks12bb/12;
gen xeducout=xedutuitout+xeduunifout+xedutranout+xedubordout;
gen xeducall=xeduc+xeducout;

lab var xedutuit "Monthly expend. on educ.:tuition, ks10aa";
lab var xeduunif "Monthly expend. on educ.:uniform, ks11aa";
lab var xedutran "Monthly expend. on educ.:transport, ks12aa";
lab var xedutuitout "Monthly expend. on educ. out of home:tuition, ks10ab";
lab var xeduunifout "Monthly expend. on educ. out of home:uniform, ks11ab";
lab var xedutranout "Monthly expend. on educ. out of home:transport, ks12ab";
lab var xedubordout "Monthly expend. on educ. out of home:boarding, ks12bb";
lab var xeduc "Monthly expend. on educ ks10aa-ks12aa";
lab var xeducout "Monthly expend. on educ, out of home ks10ab-ks12bb";
lab var xeducall "Monthly expend. on educ, all (ks10aa-ks12bb)";

*NOTE: FOR CALCULATING HH EXPENDITURE, USE XEDUC (EXPEND. ON KIDS INSIDE THE HOME) ;

*********************************;
*MONTHLY EXPENDITURE CATEGORIES;
******************************;

drop ks02* ks03*;

***************************************;
* HOUSEHOLD EXPENDITURE: XFOOD + XNONFOOD;
***************************************;

**FOOD : xfood: total of KS02 and KS03, already generated; 

**NONFOOD:xnonfood=xnonfood2+xnonfood3+xhousing+xeduc+inonfood, 
SO IT IS THE TOTAL OF KS06 WITHOUT ARISAN + TOTAL KS08,KS09 + HOUSING + EDUCATION FOR CHILDREN IN THE HOME ONLY + OWN-PRODUCED NON0-FOOD. 
ks06 w/o arisan, ks08, ks09a, ks10aa-ks12aa, ks07a). Generated below:;

gen xnonfood=xnonfood2+xnonfood3+xhouse+xeduc+inonfood;
lab var xnonfood "Monthly non-food expenditure"; 

** HHEXP: MONTHLY HOUSEHOLD EXPENDITURE; 
gen hhexp=xfood+xnonfood;
lab var hhexp "Monthly expenditure";
inspect hhexp;
 

**********************************;
*OTHER CATEGORIES;
**************************************;

*MONTHLY FOOD CONSUMPTION: FROM KS02,KS03 AND TRANSFER OF FOOD OUT;
gen hhfood=xfood+xfdtout;
lab var hhfood "Monthly consumption on food (ks02,ks03 AND ks04b)";

*MONTHLY TRANSFER: FROM KS04B, KS06G, KS8G, AND EDUC FOR KID OUTSIDE THE HOME monthly;
gen xtransfer=xfdtout+xtransf2+xtransf3+xeducout;
lab var xtransfer "Monthly transfer (from ks04b,ks6G,ks08G,ks10ab-ks12bb)";

*MONTHLY EXPENDITURES ON HOUSEHOLD EXPENSES ;
gen xhhx=xutility+xhhgood+xdomest+xfurn;
lab var xhhx "Monthly expend. on household expenses";

*MONTHLY EXPENDITURES ON TRANSPORTATION: xtransp (already generated);

*MONTHLY EXPENDITURES ON MEDICAL: xmedical (already generated);

*MONTHLY EXPENDITURES ON ENTERTAINMENT;
gen xentn=xrecreat+xlottery+xcerem;
lab var xentn "Monthly expend. on entertainment";

*MONTHLY EXPENDITURES ON DURABLES;
gen xdura=xfurn+xother+xtransf3 ;
lab var xdura "Monthly expend. on durables";

*MONTHLY EXPENDITURES ON CEREMONIES AND TAX;
gen xritax=xcerem+xtax;
lab var xritax "Monthly expend. on ritual and tax";

sort hhid;
drop ks0* ;
compress;
save $dir0\pce_wo_hhsize.dta, replace;

****************************************************************************************************;
* IX. MERGE WITH HHSIZE.DTA,  DATA FROM AR WITH INFO ON HHSIZE (AR01==1 OR 5);
*************************************************************************************************;
#delimit ;
use hhid97 member97 if member97==1 using $dir2\ptrack, clear;
bys hhid97: gen hhsize=_N;
bys hhid97: keep if _n==_N;
lab var hhsize "HH size";
sort hhid97;
save $dir0\hhsize, replace;

merge hhid97  using $dir0\pce_wo_hhsize.dta;
lab var _merge "1=KS/KRmonthly 2=peg_hh97.dta 3=both";
tab _merge ;
keep if _merge==3;
tab missing _merge, m;
tab _mkr _merge, m;

inspect hhexp ;
inspect hhsize;

*PER CAPITA EXPENDITURES: HHEXP/HHSIZE;

gen pce=hhexp/hhsize;
lab var pce "Per capita expenditure";

inspect pce;
sum pce, detail;
sum pce if missing==0 , detail;

gen lnpce=log(pce);
lab var lnpce "Log of per capita expenditure";


**EXPENDITURE SHARES:  EXPEND. x 100 / HHEXP;

gen wrice=xrice*100/hhexp;
gen wstaple=xstaple*100/hhexp;
gen wvege=xvege*100/hhexp;
gen wfood=xfood*100/hhexp;
gen woil=xoil*100/hhexp	;
gen wmedical=xmedical*100/hhexp;
gen wcloth=xcloth*100/hhexp;
gen wdairy=xdairy*100/hhexp;
gen weducall=xeducall*100/hhexp;
gen whous=xhous*100/hhexp;
gen wmtfs=(xmeat+xfish)*100/hhexp;
gen wnonfood=xnonfood*100/hhexp;
gen waltb=xaltb*100/hhexp;

lab var wrice "Expend. share: rice";

lab var wstaple "Expend. share: staple food";
lab var wvege "Expend. share: vegetable";
lab var woil "Expend. share: oil";
lab var waltb "Expend. share: alcohol+tobacco";
lab var wfood "Expend. share: food";

lab var wmedical "Expend. share: medical cost";
lab var wcloth "Expend. share: clothing";
lab var wdairy "Expend. share: dairy";
lab var weducall "Expend. share: education (all)";
lab var whous "Expend. share: housing";
lab var wmtfs "Expend. share: meat+fish";
lab var wnonfood "Expend. share: nonfood excl.arisan";

compress;
tab1 miss*, m;
keep hhid97* commid97 prov kabid kecid orige x* m* i* w* _out* hh* *pce hhsize owners; 
drop miss* member mover;
des;
sum;
lab data "Per Capita Expenditure 1997";
sort hhid;
save $dir09\pce97nom.dta, replace;

*************************************************************************************************;
* X. Creating the smaller file containing only the nominal and the real consumption aggregate;
*************************************************************************************************;
#delimit ;
use $dir09\pce97nom.dta, clear;
merge hhid97 using $dir09\deflate_hh97;
tab _merge;
rename hhexp xtotal;
* deflate using temporal deflator with December 2000 as the base;
gen temptotal=xtotal*cpi_tornq;
gen tempfood=xfood*cpi_tornq;
gen tempnonfood=xnonfood*cpi_tornq;
* deflate using spatial deflator with Jakarta as the base;
gen rtotal=temptotal/cpi_sp00;
gen rfood=tempfood/cpi_sp00;
gen rnonfood=tempnonfood/cpi_sp00;
lab var xtotal "Monthly HH expenditure, nominal";
lab var xfood "Monthly HH food expenditure, nominal";
lab var xnonfood "Monthly HH non-food expenditure, nominal";
lab var rtotal "Monthly HH expenditure, real";
lab var rfood "Monthly HH food expenditure, real";
lab var rnonfood "Monthly HH non-food expenditure, real";
keep hhid97 hhsize xtotal xfood xnonfood rtotal rfood rnonfood;
sort hhid97 ;
compress;
lab data "Real HH Per Capita Expenditure 1997";
save $dir09\pce97.dta, replace;

log close;
