clear
#delimit ;
****************************************************************************
*pce00.do;
*Files used:;
* Original files: bk_sc.dta, bk_ar1.dta, b1_ks0.dta, b1_ks1.dta, b1_ks2.dta, b2_kr.dta;
* Other files: deflate_hh00.dta;
*Files created:;
* pce00nom.dta, pce00.dta;
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

log using $dir01\pce00, text replace;
****************************************************************************;
* I. Create a file with kecamatan ID, kabupaten ID, etc;
****************************************************************************;
use commid93 result93 if result93==1 using $dir2\htrack, clear;
bys commid93: keep if _n==_N;
gen str4 commid=commid93;
sort commid;
save $dir0\origea93, replace;

use commid00 sc*0099  result00 hhid00 hhid00_9 if result00==1 using $dir3\htrack.dta, clear;
gen kecid=(sc010099*100000)+(sc020099*1000)+(sc030099);
gen kabid=(sc010099*100)+(sc020099);
gen str4 commid=commid00;
sort commid;
merge commid using $dir0\origea93;
tab _merge;
drop if _merge==2;
gen byte origea=(_merge==3);
lab var origea "Original IFLS EA";
lab var kabid "Kabupaten ID";
lab var kecid "Kecamatan ID";
drop _merge commid;
sort hhid00;
compress;
save $dir0\hhlist2000, replace;

****************************************************************************
* II. Housing Expenditures, Book KR (B2_KR.DTA);
****************************************************************************
#delimit ;
* II.1 Identify outliers;
****************************************************************************;
use hhid00 kr03 kr04* kr05* using  $dir3\b2_kr, clear;
format kr04 kr05 %12.0f;
tab1 kr04 kr05;
sort hhid00;

gen _outlierkr04=0;
gen _outlierkr05=1 if kr05==200000000;
list hhid00 kr05 if _outlierkr05==1;
replace kr05=. if kr05==200000000;

mvencode _outlierkr05, mv(0);
list hhid00 kr04 kr05 if _outlierkr04==1 | _outlierkr05==1;
tab1 _outlier*;
sort hhid00;
save $dir0\tempkr00, replace;

* II.2 Merge with kecid, kabid, information;
****************************************************************************;
use hhid* commid00 kecid kabid origea using $dir0\hhlist2000, clear;
sort hhid00;
merge hhid00 using $dir0\tempkr00;
tab _merge;
*Only keep HHs who answered Book 2;
keep if _merge==3;
drop _merge;

tab kr04x;
tab kr05x;

* II.3 Generate median variables ;
****************************************************************************;
egen medcom05=median(kr05), by(commid00);
egen medkec05=median(kr05), by(kecid);
egen medkab05=median(kr05), by(kabid);

egen medcom04=median(kr04), by(commid00);
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

********** START OF THE 'MANUAL' IMPUTATION OF KR04 AND KS05 ************************************************************;
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="3105";

replace kr05=medkec05  if  origkr05==. & kr05x~=1 & com=="12DV";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="13A0";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="13DE";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="31BE";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="31BF";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="32E1";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="35DM";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="52BL";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="16A4";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="31AW";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="31BC";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="32AN";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="32GI";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="32GM";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="32H2";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="32K6";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="32KF";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="32LC";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="32LF";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="32MK";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="32NI";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="32NK";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="33J4";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="34AB";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="35BR";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="35HL";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="51A2";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="51AX";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="52BK";

replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="73AR";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="73EA";
replace kr05=medkec05 if  origkr05==. & kr05x~=1 & com=="73EF";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="1202";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="3249";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="12D3";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="13B0";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="13CB";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="14BZ";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="16AF";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="16AK";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="16C3";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="16DB";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32B0";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32CP" ;
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32CU";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32DJ";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32DQ";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32DY";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32GA";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32GQ";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32GR";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32HN";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32ID";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32IP";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32IS";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32IX";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32I5";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32I7";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32K1";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32LG";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32LH";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32L6";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32MS";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32MW";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32OF";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32OQ";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="33DW";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="33EA";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="33KB";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="33KC";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="34AC";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="34AV";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="35CF";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="35D7";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="35FE";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="35IM";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="35I6";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="35QL";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="35QZ";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="35Q1";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="51AZ";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="63AD";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="63CI";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="73E5";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="12BR";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="12FC";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="12GD";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="12GM";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="16AI";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="16AT";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="16B8";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="16BA";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="16C1";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32B1";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32BQ";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32BV";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32D0";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32G2";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32GS";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32HW";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32K2";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32K9";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32LA";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32LE";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32LR";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="32NZ";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="33K1";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="33NK";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="33OJ";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="33OR";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="34AW";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="34BM";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="34BQ";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="34BZ";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="35GW";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="35MJ";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="35QX";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="51AO";
replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="52BR";

replace kr05=medkab05 if  origkr05==. & kr05x~=1 & com=="73CW";


replace kr04=medkec04 if kr04x==8 & commid=="32NH";

replace kr04=medkab04 if kr04x==8 & commid=="32BI";
replace kr04=medkab04  if kr04x==8 & commid=="32OI";
replace kr04=medkab04  if kr04x==8 & commid=="35D4";
replace kr04=medkab04  if kr04x==8 & commid=="35I4";
replace kr04=medkab04  if kr04x==8 & commid=="5108";

********************* END OF "MANUAL" IMPUTATION  OF KR04 AND KR05 ********************************************************;

gen  owners=(kr05x~=.);
lab define owners 1 "Owners" 0 "Renters";
lab value owners owners;
lab var owners "Owners or renters?";

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
lab var misskr "Household with missng kr04 or kr05";
tab misskr, m;

* II.6 Label, compress, sort, and save the data;
****************************************************************************;
lab data "KRwith imputed values";
compress;
sort hhid00 ;
drop med* origk*;
save $dir0\b2_kr00, replace;

************************************************************************;
* III. Book 1 - KS  Food Consumption: KS02, KS03;
************************************************************************;
* III.1 Identify outliers;
****************************************************************************;
use hhid00 ks02 ks03 ks1type using $dir3\b1_ks1, clear;
format ks02 ks03 %12.0f;
compress;

* KS02;
list hhid00 ks02 ks1type  if ks1type=="D" & ks02>50000 & ks02~=.;
gen byte y=1 if ks1type=="D" & ks02>50000 & ks02~=.;
replace y=1 if ks1type=="IB" & ks02>500000 & ks02~=.;
replace y=1 if ks1type=="J" & ks02>300000 & ks02~=.;
replace y=1 if ks1type=="K" & ks02>700000 & ks02~=.;
replace ks02=. if y==1;

* KS03;
gen z=1 if ks1type=="FA" & ks03>30000 & ks03~=.;
replace z=1 if ks1type=="IA" & ks03>350000 & ks03~=.;
replace z=1 if ks1type=="M" & ks03>175000 & ks03~=.;
replace z=1 if ks1type=="Z" & ks03>72500 & ks03~=.;
list hhid ks02 ks03 ks1type if z==1;
replace ks03=. if z==1;

bys hhid00: egen _outlierks02=max(y);
bys hhid00: egen _outlierks03=max(z);
mvencode _outlierks02, mv(0);
mvencode _outlierks03, mv(0);
lab var _outlierks02 "Any outlier in ks02";
lab var _outlierks03 "Any outlier in ks03";
tab1 _outlierks02 _outlierks03;
drop y  z ;
sort hhid00;

* CORRECTION AFTER LOOKUP:
replace ks02=700 if ks1type=="C" & hhid=="1522011";
replace ks02=0 if ks1type=="BA" & hhid=="1611800";
replace ks02=1000 if ks1type=="T" & hhid=="2212700";
replace ks02=429600 if ks1type=="IA" &  hhid=="0311931";

replace ks03=0 if ks1type=="IB" &  hhid=="0452500";
replace ks03=0 if ks1type=="G" & hhid=="0541800";


* III.2. Reshape b1_ks1.dta from long to wide;
****************************************************************************;
reshape wide ks02 ks03, i(hhid) j(ks1type) string;
gen _outlierks=(_outlierks02==1 | _outlierks03==1);
lab var _outlierks02 "Any outlier in ks02";
lab var _outlierks03 "Any outlier in ks03";
lab var _outlierks "Any outlier in ks";
aorder;
sort hhid00;
save $dir0\b1_ks100wide, replace;
compress;

* III.3. Merge with kecamatan ID, etc;
****************************************************************************;
use hhid* commid00 kecid kabid origea using $dir0\hhlist2000, clear;
sort hhid00;
merge hhid00 using $dir0\b1_ks100wide;
tab _merge;
keep if _merge==3;
drop _merge;

* III.4. Generate median variables;
****************************************************************************;
for var ks*: egen medcomX=median(X), by(commid00);
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


********** START OF THE 'MANUAL' IMPUTATION OF KS02 AND KS03 ************************************************************;
replace ks02A=medkabks02A  if origks02A==. & commid=="12GO";
replace ks02A=medkabks02A  if origks02A==. & commid=="32OI";
replace ks02A=medkabks02A  if origks02A==. & commid=="35Q6";

replace ks02AA=medkabks02AA if origks02AA==. & commid=="12GO";

replace ks02B=medkabks02B if origks02B==. & commid=="12GO";
replace ks02B=medkecks02B if origks02B==. & commid=="31BE";

replace ks02BA=medkabks02BA if origks02BA==. & commid=="12GO";
replace ks02BA=medkecks02BA  if origks02BA==. & commid=="31BE";

replace ks02C=medkabks02C if origks02C==. & commid=="12GO";
replace ks02C=medkecks02C if origks02C==. & commid=="16BV";
replace ks02C=medkecks02C if origks02C==. & commid=="34BS";

replace ks02CA=medkabks02CA if origks02CA==. & commid=="12GO";
replace ks02CA=medkecks02CA if origks02CA==. & commid=="31AU";

replace ks02D=medkabks02D if origks02D==. & commid=="12GO";

replace ks02DA=medkabks02DA if origks02DA==. & commid=="12GO";

replace ks02E=medkabks02E if origks02E==. & commid=="12GO";

replace ks02EA=medkabks02EA if origks02EA==. & commid=="31AL";

replace ks02F=medkabks02F if origks02F==. & commid=="12GO";
replace ks02F=medkabks02F if origks02F==. & commid=="35Q6";
replace ks02F=medkecks02F if origks02F==. & commid=="31BE";

replace ks02G=medkabks02G if origks02G==. & commid=="12GO";
replace ks02G=medkecks02H if origks02G==. & commid=="31AV";

replace ks02H=medkabks02H if origks02H==. & commid=="12GO";
replace ks02H=medkecks02H if origks02H==. & commid=="31BE";

replace ks02HA=medkabks02HA if origks02HA==. & commid=="12GO";
replace ks02HA=medkabks02HA if origks02HA==. & commid=="16B0";
replace ks02HA=medkabks02HA if origks02HA==. & commid=="16C8";
replace ks02HA=medkabks02HA if origks02HA==. & commid=="31AL";
replace ks02HA=medkecks02HA if origks02HA==. & commid=="12G3";
replace ks02HA=medkecks02HA if origks02HA==. & commid=="13DC";
replace ks02HA=medkecks02HA if origks02HA==. & commid=="16C0";
replace ks02HA=medkecks02HA if origks02HA==. & commid=="31BE";

replace ks02I=medkabks02I if origks02I==. & commid=="12GO";

replace ks02IA=medkabks02IA if origks02IA==. & commid=="12GO";
replace ks02IA=medkabks02IA if origks02IA==. & commid=="16DB";
replace ks02IA=medkabks02IA if origks02IA==. & commid=="33OJ";
replace ks02IA=medkecks02IA if origks02IA==. & commid=="31BE";

replace ks02IB=medkabks02IB if origks02IB==. & commid=="12GO";
replace ks02IB=medkabks02IB  if origks02IB==. & commid=="31AL";
replace ks02IB=medkabks02IB  if origks02IB==. & commid=="34AC";
replace ks02IB=medkabks02IB  if origks02IB==. & commid=="33OJ";
replace ks02IB=medkecks02IB  if origks02IB==. & commid=="31BE";

replace ks02J=medkabks02J if origks02J==. & commid=="12GO";
replace ks02J=medkecks02J if origks02J==. & commid=="31BE";

replace ks02K=medkabks02K if origks02K==. & commid=="12GO";
replace ks02K=medkecks02K if origks02K==. & commid=="31AV";

replace ks02L=medkabks02L if origks02L==. & commid=="12GO";

replace ks02M=medkabks02M if origks02M==. & commid=="12GO";

replace ks02N=medkabks02N if origks02N==. & commid=="12GO";

replace ks02OA=medkabks02OA if origks02OA==. & commid=="12GO";

replace ks02OB=medkabks02OB if origks02OB==. & commid=="12GO";

replace ks02P=medkabks02P if origks02P==. & commid=="12GO";
replace ks02P=medkabks02P if origks02P==. & commid=="34B1";

replace ks02Q=medkabks02Q if origks02Q==. & commid=="12GO";
replace ks02Q=medkecks02Q if origks02Q==. & commid=="31BE";

replace ks02R=medkabks02R if origks02R==. & commid=="12GO";

replace ks02S=medkabks02S if origks02S==. & commid=="12GO";
replace ks02S=medkabks02S if origks02S==. & commid=="31AL";

replace ks02T=medkabks02T if origks02T==. & commid=="12GO";

replace ks02U=medkabks02U if origks02U==. & commid=="12GO";
replace ks02U=medkabks02U if origks02U==. & commid=="31AL";

replace ks02V=medkabks02V if origks02V==. & commid=="12GO";
replace ks02V=medkabks02V if origks02V==. & commid=="33OJ";

replace ks02W=medkabks02W if origks02W==. & commid=="12GO";

replace ks02X=medkabks02X if origks02X==. & commid=="12GO";
replace ks02X=medkabks02X if origks02X==. & commid=="31AL";

replace ks02Y=medkabks02Y if origks02Y==. & commid=="12GO";

replace ks02Z=medkabks02Z if origks02Z==. & commid=="12GO";

**KS03;

replace ks03A=medkabks03A if origks03A==. & commid=="12GO";

replace ks03AA=medkabks03AA if origks03AA==. & commid=="12GO";
replace ks03AA=medkabks03AA if origks03AA==. & commid=="34B0";

replace ks03B=medkabks03B if origks03B==. & commid=="12GO";

replace ks03BA=medkabks03BA if origks03BA==. & commid=="12GO";

replace ks03C=medkabks03C if origks03C==. & commid=="12GO";

replace ks03CA=medkabks03CA if origks03CA==. & commid=="12GO";

replace ks03D=medkabks03D if origks03D==. & commid=="12GO";

replace ks03DA=medkabks03DA if origks03DA==. & commid=="12GO";

replace ks03E=medkabks03E if origks03E==. & commid=="12GO";

replace ks03F=medkabks03F if origks03F==. & commid=="12GO";
replace ks03F=medkabks03F if origks03F==. & commid=="35Q6";

replace ks03G=medkabks03G if origks03G==. & commid=="12GO";


replace ks03H=medkabks03H if origks03H==. & commid=="12GO";

replace ks03HA=medkabks03HA if origks03HA==. & commid=="12GO";
replace ks03HA=medkabks03HA if origks03HA==. & commid=="32HU";

replace ks03I=medkabks03I if origks03I==. & commid=="12GO";

replace ks03IA=medkabks03IA if origks03IA==. & commid=="12G1";
replace ks03IA=medkabks03IA if origks03IA==. & commid=="12GO";
replace ks03IA=medkabks03IA if origks03IA==. & commid=="31AL";
replace ks03IA=medkabks03IA if origks03IA==. & commid=="320F";

replace ks03IB=medkabks03IB if origks03IB==. & commid=="12GO";
replace ks03IB=medkabks03IB if origks03IB==. & commid=="31AL";

replace ks03J=medkabks03J if origks03J==. & commid=="12GO";
replace ks03J=medkabks03J if origks03J==. & commid=="33OJ";
replace ks03J=medkabks03J if origks03J==. & commid=="34B0";

replace ks03K=medkabks03K if origks03K==. & commid=="12GO";

replace ks03L=medkabks03L if origks03L==. & commid=="12GO";

replace ks03M=medkabks03M if origks03M==. & commid=="12GO";

replace ks03N=medkabks03N if origks03N==. & commid=="12GO";

replace ks03OA=medkabks03OA if origks03OA==. & commid=="12GO";

replace ks03OB=medkabks03OB if origks03OB==. & commid=="12GO";

replace ks03P=medkabks03P if origks03P==. & commid=="12GO";

replace ks03Q=medkabks03Q if origks03Q==. & commid=="12GO";

replace ks03R=medkabks03R if origks03R==. & commid=="12GO";

replace ks03S=medkabks03S if origks03S==. & commid=="12GO";

replace ks03T=medkabks03T if origks03T==. & commid=="12GO";

replace ks03U=medkabks03U if origks03U==. & commid=="12GO";

replace ks03V=medkabks03V if origks03V==. & commid=="12GO";
replace ks03V=medkabks03V if origks03V==. & commid=="33OJ";

replace ks03W=medkabks03W if origks03W==. & commid=="12GO";

replace ks03X=medkabks03X if origks03X==. & commid=="12GO";
replace ks03X=medkabks03X if origks03X==. & commid=="31AL";

replace ks03Y=medkabks03Y if origks03Y==. & commid=="12GO";

replace ks03Z=medkabks03Z if origks03Z==. & commid=="12GO";

for var ks*: replace X=medcomX if origX==. & X==.;

for var ks02*: replace X=. if _outlierks02==1;
for var ks03*: replace X=. if _outlierks03==1;

********** END OF THE 'MANUAL' IMPUTATION OF KS02 AND KS03'************************************************************;


* III.6. Generate total;
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
sort hhid00 ;
drop med* origk* sum*;
compress;
label data "Wide version of b1_ks1, with imputation";
save $dir0\b1_ks100, replace;

********************************************************************************;
* IV. KS06 (B1_KS2.DTA);
********************************************************************************;
#delimit ;
* IV.1 Identify outliers;
****************************************************************************;
use hhid00 ks2type ks06 using $dir3\b1_ks2, clear;
gen byte z=1 if ks2type=="E" & ks06>4000000 & ks06~=.;
replace z=1 if ks2type=="G" & ks06>2000000 & ks06~=.;
replace z=1 if ks2type=="B" & ks06>775000 & ks06~=.;
list hhid ks06 ks2type if z==1;
replace ks06=. if ks2type=="E" & ks06>4000000 & ks06~=.;
replace ks06=. if ks2type=="G" & ks06>2000000 & ks06~=.;
replace ks06=. if ks2type=="B" & ks06>775000 & ks06~=.;
sort hhid00;
bys hhid00: egen _outlierks06=max(z);
mvencode _outlierks06, mv(0);
lab var _outlierks06 "Any outlier in ks06";
tab _outlierks06;
sort hhid00;
compress;

* IV.2. Generate variable containing information on missing values in this data file ;
****************************************************************************;
gen   x=1 if ks06==.;
replace x=0 if ks2type=="F2";
replace x=0 if x==. ;
egen   missks06=max(x), by(hhid00);
lab var missks06 "Household w/ at least 1 KS06 missing, excl. F2";
compress;
drop x z;

* IV.3. Reshape b1_ks2.dta from long to wide;
****************************************************************************;
reshape wide ks06, i(hhid00) j(ks2type) string;
tab missks06;
sort hhid00;
compress;
label data "Wide version of b1_ks2";
save $dir0\b1_ks200_wide, replace;

* IV.5. Merge with commid, kecid, kabid info;
****************************************************************************;
use hhid* commid00 kecid kabid origea using $dir0\hhlist2000, clear;
sort hhid00;
merge hhid00 using $dir0\b1_ks200_wide;
tab _merge;
*Only keep HHs which answered Book 2;
keep if _merge==3;
drop _merge;

inspect ks06*;

* IV.5. Generate median variables;
****************************************************************************;
for var ks*:  egen medcomX=median(X), by(commid00);
for var ks*:  egen medkecX=median(X), by(kecid);
for var ks*:  egen medkabX=median(X), by(kabid);


compress ;

* IV.6. Imputation;
****************************************************************************;

for var ks*: gen origX=X;
for var ks*: replace X=medcomX if X==. & origea==1  & _outlierks06~=1;
for var ks*: replace X=medkecX if X==. & _outlierks06~=1;
for var ks*: replace X=medkabX if X==. & _outlierks06~=1;

********** START OF THE 'MANUAL' IMPUTATION OF KS06************************************************************;
replace ks06A=medkecks06A if origks06A==. & commid=="31BE";
replace ks06A=medkecks06A if origks06A==. & commid=="33NE";
replace ks06A=medkecks06A if origks06A==. & commid=="33OH";

replace ks06A=medkabks06A if origks06A==. & commid=="12GD";
replace ks06A=medkabks06A if origks06A==. & commid=="13B3";
replace ks06A=medkabks06A if origks06A==. & commid=="32OI";
replace ks06A=medkabks06A if origks06A==. & commid=="33OJ";
replace ks06A=medkabks06A if origks06A==. & commid=="33OR";
replace ks06A=medkabks06A if origks06A==. & commid=="34B0";
replace ks06A=medkabks06A if origks06A==. & commid=="35JH";

replace ks06B=medkecks06B if origks06B==. & commid=="31BE";
replace ks06B=medkecks06B if origks06B==. & commid=="33NE";
replace ks06B=medkecks06B if origks06B==. & commid=="33O1";

replace ks06B=medkabks06B if origks06B==. & commid=="12DX";
replace ks06B=medkabks06B if origks06B==. & commid=="12GD";
replace ks06B=medkabks06B if origks06B==. & commid=="12GO";
replace ks06B=medkabks06B if origks06B==. & commid=="32K8";
replace ks06B=medkabks06B if origks06B==. & commid=="33OJ";

replace ks06C=medkabks06C  if origks06C==. & commid=="12DX";
replace ks06C=medkabks06C  if origks06C==. & commid=="12GO";
replace ks06C=medkabks06C  if origks06C==. & commid=="32K8";
replace ks06C=medkabks06C  if origks06C==. & commid=="32OI";
replace ks06C=medkabks06C  if origks06C==. & commid=="33OJ";

replace ks06C=medkecks06C  if origks06C==. & commid=="31BE";
replace ks06C=medkecks06C  if origks06C==. & commid=="33NE";
replace ks06C=medkecks06C  if origks06C==. & commid=="33O1";

replace ks06C1=medkabks06C1  if origks06C1==. & commid=="12DX";
replace ks06C1=medkabks06C1  if origks06C1==. & commid=="12GO";
replace ks06C1=medkabks06C1  if origks06C1==. & commid=="32LG";

replace ks06C1=medkecks06C1 if origks06C1==. & commid=="33NE";
replace ks06C1=medkecks06C1 if origks06C1==. & commid=="33O1";

replace ks06D=medkabks06D  if origks06D==. & commid=="12DX";
replace ks06D=medkabks06D  if origks06D==. & commid=="12GO";
replace ks06D=medkabks06D  if origks06D==. & commid=="16BV";
replace ks06D=medkabks06D  if origks06D==. & commid=="31AL";
replace ks06D=medkabks06D  if origks06D==. & commid=="33OJ";

replace ks06D=medkecks06D if origks06D==. & commid=="31BE";
replace ks06D=medkecks06D if origks06D==. & commid=="33NE";
replace ks06D=medkecks06D if origks06D==. & commid=="33O1";

replace ks06E=medkabks06E if origks06E==. & commid=="12DX";
replace ks06E=medkabks06E if origks06E==. & commid=="12GZ";
replace ks06E=medkabks06E if origks06E==. & commid=="12GO";
replace ks06E=medkabks06E if origks06E==. & commid=="13CB";
replace ks06E=medkabks06E if origks06E==. & commid=="32OI";
replace ks06E=medkabks06E if origks06E==. & commid=="33OJ";
replace ks06E=medkabks06E if origks06E==. & commid=="34BQ";
replace ks06E=medkabks06E if origks06E==. & commid=="34BS";
replace ks06E=medkabks06E if origks06E==. & commid=="35QT";
replace ks06E=medkabks06E if origks06E==. & commid=="35QX";

replace ks06E=medkecks06E if origks06E==. & commid=="13DE";
replace ks06E=medkecks06E if origks06E==. & commid=="31BE";
replace ks06E=medkecks06E if origks06E==. & commid=="31AV";
replace ks06E=medkecks06E if origks06E==. & commid=="33NE";
replace ks06E=medkecks06E if origks06E==. & commid=="33O1";
replace ks06E=medkecks06E if origks06E==. & commid=="63DG";

replace ks06F1=medkabks06F1 if origks06F1==. & commid=="12DX";
replace ks06F1=medkabks06F1 if origks06F1==. & commid=="12GO";
replace ks06F1=medkabks06F1 if origks06F1==. & commid=="33OJ";

replace ks06F1=medkecks06F1 if origks06F1==. & commid=="33NE";
replace ks06F1=medkecks06F1 if origks06F1==. & commid=="33O1";

replace ks06F2=medkabks06F2 if origks06F2==. & commid=="12DX";
replace ks06F2=medkabks06F2 if origks06F2==. & commid=="12GZ";
replace ks06F2=medkabks06F2 if origks06F2==. & commid=="12GO";
replace ks06F2=medkabks06F2 if origks06F2==. & commid=="33OJ";

replace ks06F2=medkecks06F2 if origks06F2==. & commid=="33NE";
replace ks06F2=medkecks06F2 if origks06F2==. & commid=="33O1";

replace ks06F2=medkabks06F2 if origks06F2==. & commid=="12DX";
replace ks06F2=medkabks06F2 if origks06F2==. & commid=="12GO";
replace ks06F2=medkabks06F2 if origks06F2==. & commid=="31AL";

replace ks06G=medkecks06G if origks06G==. & commid=="31BE";
replace ks06G=medkecks06G if origks06G==. & commid=="33NE";
replace ks06G=medkecks06G if origks06G==. & commid=="33O1";
replace ks06G=medkecks06G if origks06G==. & commid=="52BW";

for var ks06*: replace X=medcomX if origX==. & X==.;

for var ks06*: replace X=. if _outlierks06==1;

********** END OF THE 'MANUAL' IMPUTATION OF KS06************************************************************;

* IV.7 Generate variable containing information on missing values in this data file ;
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
sort hhid00;
save $dir0\b1_ks200, replace;

********************************************************************************;
* V. KS08, KS09a,  (B1_KS3.DTA);
********************************************************************************;
#delimit ;
* V.1. Identify outliers;
****************************************************************************;
use ks08 ks09a ks3type hhid00 using $dir3\b1_ks3, clear;
sort hhid00 ks3type;

gen byte z=1 if ks3type=="A" & ks08>18600000 & ks08~=.;
replace z=1 if ks3type=="C" & ks08>30000000 & ks08~=.;
replace z=1 if ks3type=="E" & ks08>11000000 & ks08~=.;
replace z=1 if ks3type=="F" & ks08>91180000 & ks08~=.;
replace z=1 if ks3type=="G" & ks08>40000000 & ks08~=.;
sort hhid00;
list hhid ks08 ks3type if z==1;
replace ks08=. if ks3type=="A" & ks08>18600000 & ks08~=.;
replace ks08=. if ks3type=="C" & ks08>30000000 & ks08~=.;
replace ks08=. if ks3type=="E" & ks08>11000000 & ks08~=.;
replace ks08=. if ks3type=="F" & ks08>91180000 & ks08~=.;
replace ks08=. if ks3type=="G" & ks08>40000000 & ks08~=.;
bys hhid: egen _outlierks08=max(z);
mvencode _outlierks08, mv(0);
sort hhid00;
drop z ;
compress;

gen _outlierks09=0;

lab var _outlierks08 "Any outlier in ks08";
lab var _outlierks09 "Any outlier in ks09";

tab1 _outlier*;
compress;

*V.2. Reshape b1_ks3.dta from long to wide;
****************************************************************************;
reshape wide ks08 ks09a, i(hhid00 ) j(ks3type) string;
sort hhid00; 
compress;
label data "Wide version of b1_ks3 created pre_pce.do";
save $dir0\b1_ks300_wide, replace;

*V.3 Merge with kecamatan ID information;
****************************************************************************;
#delimit ;
use $dir0\b1_ks300_wide, clear;
sort hhid00;
save $dir0\tempks300, replace;

use hhid* commid00 kecid kabid origea using $dir0\hhlist2000, clear;
sort hhid00;
merge hhid00 using $dir0\tempks300;
tab _merge;
*Only keep HHs which answered Book 2;
keep if _merge==3;
drop _merge;

inspect ks*;

*V.4 Generate median variables;
****************************************************************************;
for var ks*: egen medcomX=median(X), by(commid);
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

********** START OF THE 'MANUAL' IMPUTATION OF KS08 AND KS09 ************************************************************;
replace ks08A=medkabks08A if origks08A==. & commid=="12DX";
replace ks08A=medkabks08A  if origks08A==. & commid=="16B0";
replace ks08A=medkabks08A  if origks08A==. & commid=="32K8";
replace ks08A=medkabks08A  if origks08A==. & commid=="34BS";

replace ks08A=medkecks08A if origks08A==. & commid=="31BE";
replace ks08A=medkecks08A if origks08A==. & commid=="33NE";
replace ks08A=medkecks08A if origks08A==. & commid=="33O1";
replace ks08A=medkecks08A if origks08A==. & commid=="63DG";
 
replace ks08B=medkabks08B if origks08B==. & commid=="12DX";
replace ks08B=medkabks08B if origks08B==. & commid=="12GO";
replace ks08B=medkabks08B if origks08B==. & commid=="31AL";

replace ks08B=medkecks08B if origks08B==. & commid=="31BE";
replace ks08B=medkecks08B if origks08B==. & commid=="33NE";
replace ks08B=medkecks08B if origks08B==. & commid=="33O1";

replace ks08C=medkabks08C if origks08C==. & commid=="16BH";
replace ks08C=medkabks08C if origks08C==. & commid=="12DX";
replace ks08C=medkabks08C if origks08C==. & commid=="12GO";
replace ks08C=medkabks08C if origks08C==. & commid=="32K8";
replace ks08C=medkabks08C if origks08C==. & commid=="33OJ";

replace ks08C=medkecks08C if origks08C==. & commid=="31BE";
replace ks08C=medkecks08C if origks08C==. & commid=="32H2";
replace ks08C=medkecks08C if origks08C==. & commid=="33NE";
replace ks08C=medkecks08C if origks08C==. & commid=="33O1";
replace ks08C=medkecks08C if origks08C==. & commid=="34BO";
 
replace ks08D=medkabks08D if origks08D==. & commid=="12DX";
replace ks08D=medkabks08D if origks08D==. & commid=="12GO";
replace ks08D=medkabks08D if origks08D==. & commid=="16AI";
replace ks08D=medkabks08D if origks08D==. & commid=="31AL";
replace ks08D=medkabks08D if origks08D==. & commid=="32JY";
replace ks08D=medkabks08D if origks08D==. & commid=="33OJ";
replace ks08D=medkabks08D if origks08D==. & commid=="34BS";

replace ks08D=medkecks08D if origks08D==. & commid=="16C0";
replace ks08D=medkecks08D if origks08D==. & commid=="31BE";
replace ks08D=medkecks08D if origks08D==. & commid=="32H2";
replace ks08D=medkecks08D if origks08D==. & commid=="33NE";
replace ks08D=medkecks08D if origks08D==. & commid=="33O1";

replace ks08E=medkabks08E if origks08E==. & commid=="12DX";
replace ks08E=medkabks08E if origks08E==. & commid=="12GZ";
replace ks08E=medkabks08E if origks08E==. & commid=="12GD";
replace ks08E=medkabks08E if origks08E==. & commid=="12GO";
replace ks08E=medkabks08E if origks08E==. & commid=="13BL";
replace ks08E=medkabks08E if origks08E==. & commid=="13B6";
replace ks08E=medkabks08E if origks08E==. & commid=="16C6";
replace ks08E=medkabks08E if origks08E==. & commid=="16B8";
replace ks08E=medkabks08E if origks08E==. & commid=="16C8";
replace ks08E=medkabks08E if origks08E==. & commid=="31AL";
replace ks08E=medkabks08E if origks08E==. & commid=="32GE";
replace ks08E=medkabks08E if origks08E==. & commid=="32LG";
replace ks08E=medkabks08E if origks08E==. & commid=="32AR";
replace ks08E=medkabks08E if origks08E==. & commid=="32BV";
replace ks08E=medkabks08E if origks08E==. & commid=="32K2";
replace ks08E=medkabks08E if origks08E==. & commid=="32KV";
replace ks08E=medkabks08E if origks08E==. & commid=="32MF";
replace ks08E=medkabks08E if origks08E==. & commid=="33G4";
replace ks08E=medkabks08E if origks08E==. & commid=="33OJ";
replace ks08E=medkabks08E if origks08E==. & commid=="33OR";
replace ks08E=medkabks08E if origks08E==. & commid=="35CJ";
replace ks08E=medkabks08E if origks08E==. & commid=="35JH";
replace ks08E=medkabks08E if origks08E==. & commid=="35IQ";

replace ks08E=medkecks08E if origks08E==. & commid=="13DF";
replace ks08E=medkecks08E if origks08E==. & commid=="16BD";
replace ks08E=medkecks08E if origks08E==. & commid=="3102";
replace ks08E=medkecks08E if origks08E==. & commid=="31BA";
replace ks08E=medkecks08E if origks08E==. & commid=="31BE";
replace ks08E=medkecks08E if origks08E==. & commid=="31AV";
replace ks08E=medkecks08E if origks08E==. & commid=="35BR";
replace ks08E=medkecks08E if origks08E==. & commid=="51A2";
replace ks08E=medkecks08E if origks08E==. & commid=="33NE";
replace ks08E=medkecks08E if origks08E==. & commid=="33O1";
 
replace ks08F=medkabks08F if origks08F==. & commid=="12DX";
replace ks08F=medkabks08F if origks08F==. & commid=="12GO";
replace ks08F=medkabks08F if origks08F==. & commid=="32MF";

replace ks08F=medkecks08F   if origks08F==. & commid=="33NE";
replace ks08F=medkecks08F   if origks08F==. & commid=="33O1";
replace ks08F=medkecks08F   if origks08F==. & commid=="34AB";

replace ks08G=medkabks08G if origks08G==. & commid=="12DX";
replace ks08G=medkabks08G if origks08G==. & commid=="12GO";
replace ks08G=medkabks08G if origks08G==. & commid=="31AL";

replace ks08G=medkecks08G    if origks08G==. & commid=="31BE";
replace ks08G=medkecks08G    if origks08G==. & commid=="33NE";
replace ks08G=medkecks08G    if origks08G==. & commid=="33O1";
replace ks08G=medkecks08G    if origks08G==. & commid=="52BW";

replace ks09aA=medkabks09aA if origks09aA==. & commid=="12DX";
replace ks09aA=medkabks09aA if origks09aA==. & commid=="16B0";
replace ks09aA=medkabks09aA if origks09aA==. & commid=="12GO";
replace ks09aA=medkabks09aA if origks09aA==. & commid=="31AL";
replace ks09aA=medkabks09aA if origks09aA==. & commid=="32EP";

replace ks09aA=medkecks09aA    if origks09aA==. & commid=="12G0";
replace ks09aA=medkecks09aA    if origks09aA==. & commid=="33NE";
replace ks09aA=medkecks09aA    if origks09aA==. & commid=="33O1";

replace ks09aB=medkabks09aB if origks09aB==. & commid=="12DX";
replace ks09aB=medkabks09aB if origks09aB==. & commid=="12GO";
replace ks09aB=medkabks09aB if origks09aB==. & commid=="31AL";

replace ks09aB=medkecks09aB  if origks09aB==. & commid=="33NE";
replace ks09aB=medkecks09aB  if origks09aB==. & commid=="33O1";

replace ks09aC=medkabks09aC if origks09aC==. & commid=="12DX";
replace ks09aC=medkabks09aC if origks09aC==. & commid=="12GO";
replace ks09aC=medkabks09aC if origks09aC==. & commid=="32JO";
replace ks09aC=medkabks09aC if origks09aC==. & commid=="33OJ";

replace ks09aC=medkecks09aC if origks09aC==. & commid=="32H2";
replace ks09aC=medkecks09aC if origks09aC==. & commid=="33NE";
replace ks09aC=medkecks09aC if origks09aC==. & commid=="33O1";

replace ks09aD=medkabks09aD if origks09aD==. & commid=="12DX";
replace ks09aD=medkabks09aD  if origks09aD==. & commid=="12GO";
replace ks09aD=medkabks09aD  if origks09aD==. & commid=="31AL";
replace ks09aD=medkabks09aD  if origks09aD==. & commid=="33OJ";

replace ks09aD=medkecks09aD if origks09aD==. & commid=="32H2";
replace ks09aD=medkecks09aD if origks09aD==. & commid=="32K7";
replace ks09aD=medkecks09aD if origks09aD==. & commid=="33NE";
replace ks09aD=medkecks09aD if origks09aD==. & commid=="33O1";

replace ks09aF=medkabks09aF if origks09aF==. & commid=="12DX";
replace ks09aF=medkabks09aF if origks09aF==. & commid=="12GO";

replace ks09aF=medkecks09aF if origks09aF==. & commid=="33NE";
replace ks09aF=medkecks09aF if origks09aF==. & commid=="33O1";

for var ks08* ks09*: replace X=medcomX if origX==. & X==.;

for var ks08*: replace X=. if _outlierks08==1;
for var ks09*: replace X=. if _outlierks09==1;

********** END OF THE 'MANUAL' IMPUTATION OF KS08 AND KS09 ************************************************************;
inspect ks*;

compress ;
sort hhid00;

* V.6 Generate variable containing information on missing values in this data file ;
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
sort hhid00;

save $dir0\b1_ks300, replace;

********************************************************************************;
* VI. B1_KS0;
********************************************************************************;
#delimit ;
use  hhid00 ks04b ks07a ks10aa ks10ab ks11aa ks11ab ks12aa ks12ab ks12bb using $dir3\b1_ks0, clear;
sort hhid00;

merge hhid00 using $dir0\hhlist2000;
tab _merge;
keep if _merge==3;
drop _merge commid93;

* VI.1. Identify outliers;
********************************************************************************;
gen byte _outlierks0=1 if ks07a>4500000 & ks07a~=.;
list hhid00 commid ks07a if _outlier==1;
replace ks07a=. if ks07a>4500000 & ks07a~=.;
mvencode _outlierks0, mv(0);
lab var _outlierks0 "Any outlier in ks0.dta";
tab _outlierks0;

* VI.2. Generate median variables;
********************************************************************************;
for var ks*: egen medcomX=median(X), by(commid);
for var ks*: egen medkecX=median(X), by(kecid);
for var ks*: egen medkabX=median(X), by(kabid);

* VI.3. Imputation;
********************************************************************************;
for var ks*: gen origX=X;
for var ks*: replace X=medcomX if X==. & origea==1  & _outlierks0~=1;
for var ks*: replace X=medkecX if X==. & _outlierks0~=1;
for var ks*: replace X=medkabX if X==. & _outlierks0~=1;

********** START OF THE 'MANUAL' IMPUTATION OF KS04B, KS07A, KS10AA, KS10AB, KS11AA, KS11AB, KS12AA, KS12AB, KS12BB*************;

replace ks04b=medkabks04b  if origks04b==. & commid=="12GO";
replace ks04b=medkabks04b  if origks04b==. & commid=="16DB";
replace ks04b=medkabks04b  if origks04b==. & commid=="31A0";
replace ks04b=medkabks04b  if origks04b==. & commid=="31AL";
replace ks04b=medkabks04b  if origks04b==. & commid=="320F";

replace ks04b=medkecks04b   if origks04b==. & commid=="33NE";
replace ks04b=medkecks04b   if origks04b==. & commid=="52BW";

replace ks07a=medkabks07a   if origks07a==. & commid=="12DX";
replace ks07a=medkabks07a   if origks07a==. & commid=="12GO";
replace ks07a=medkabks07a   if origks07a==. & commid=="13BO";
replace ks07a=medkabks07a   if origks07a==. & commid=="31AL";
replace ks07a=medkabks07a   if origks07a==. & commid=="32LG";
replace ks07a=medkabks07a   if origks07a==. & commid=="320F";
replace ks07a=medkabks07a   if origks07a==. & commid=="32BI";
replace ks07a=medkabks07a   if origks07a==. & commid=="35QY";

replace ks07a=medkecks07a   if origks07a==. & commid=="13DE";
replace ks07a=medkecks07a   if origks07a==. & commid=="31BE" ;
replace ks07a=medkecks07a   if origks07a==. & commid=="33NE";
replace ks07a=medkecks07a   if origks07a==. & commid=="3301";

replace ks10aa=medkabks10aa  if origks10aa==. & commid=="12DX";
replace ks10aa=medkabks10aa  if origks10aa==. & commid=="32MF";

replace ks10aa=medkecks10aa  if origks10aa==. & commid=="12G0";
replace ks10aa=medkecks10aa  if origks10aa==. & commid=="16CG";
replace ks10aa=medkecks10aa  if origks10aa==. & commid=="31BE" ;
replace ks10aa=medkecks10aa  if origks10aa==. & commid=="33NE";

replace ks10ab=medkabks10ab  if origks10ab==. & commid=="12DX";
replace ks10ab=medkabks10ab  if origks10ab==. & commid=="32MF";

replace ks10ab=medkecks10ab if origks10ab==. & commid=="31BE" ;
replace ks10ab=medkecks10ab if origks10ab==. & commid=="33NE";

replace ks11aa=medkabks11aa    if origks11aa==. & commid=="12DX";
replace ks11aa=medkabks11aa    if origks11aa==. & commid=="13B6";
replace ks11aa=medkabks11aa    if origks11aa==. & commid=="16C7";
replace ks11aa=medkabks11aa    if origks11aa==. & commid=="32CP";
replace ks11aa=medkabks11aa    if origks11aa==. & commid=="32K8";
replace ks11aa=medkabks11aa    if origks11aa==. & commid=="32MF";

replace ks11aa=medkecks11aa    if origks11aa==. & commid=="12G0";
replace ks11aa=medkecks11aa    if origks11aa==. & commid=="16CG";
replace ks11aa=medkecks11aa    if origks11aa==. & commid=="31BE" ;
replace ks11aa=medkecks11aa    if origks11aa==. & commid=="32IH";
replace ks11aa=medkecks11aa    if origks11aa==. & commid=="33NE";

replace ks11ab=medkabks11ab if origks11ab==. & commid=="12DX";
replace ks11ab=medkabks11ab if origks11ab==. & commid=="32MF";

replace ks11ab=medkecks11ab    if origks11ab==. & commid=="31BE" ;
replace ks11ab=medkecks11ab    if origks11ab==. & commid=="33NE";

replace ks12aa=medkabks12aa if origks12aa==. & commid=="12DX";
replace ks12aa=medkabks12aa if origks12aa==. & commid=="16DB";
replace ks12aa=medkabks12aa if origks12aa==. & commid=="32MF";

replace ks12aa=medkecks12aa if origks12aa==. & commid=="12G0";
replace ks12aa=medkecks12aa if origks12aa==. & commid=="31BE" ;
replace ks12aa=medkecks12aa if origks12aa==. & commid=="33NE";

replace ks12ab=medkabks12ab if origks12ab==. & commid=="12DX";
replace ks12ab=medkabks12ab if origks12ab==. & commid=="32MF";

replace ks12ab=medkecks12ab if origks12ab==. & commid=="31BE" ;
replace ks12ab=medkecks12ab if origks12ab==. & commid=="33NE";


replace ks12bb=medkabks12bb if origks12bb==. & commid=="12DX";
replace ks12bb=medkabks12bb if origks12bb==. & commid=="32MF";

replace ks12bb=medkecks12bb if origks12bb==. & commid=="31BE";
replace ks12bb=medkecks12bb if origks12bb==. & commid=="33NE";

for var ks07a* ks10* ks1* : replace X=medcomX if origX==. & X==.;

for var ks07a* ks10* ks1*: replace X=. if _outlierks0==1;

********** END OF THE 'MANUAL' IMPUTATION OF KS04B, KS07A, KS10AA, KS10AB, KS11AA, KS11AB, KS12AA, KS12AB, KS12BB*************;

* VI.4 Generate variable containing information on missing values in this data file;
********************************************************************************;
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

* VI.5 Save the file;
************************************************************************************;
drop  med* origk*;
sort hhid00 ;
compress ;
label data "Shorter version of b1_ks0 created using pre_pce.do";
save $dir0\b1_ks000, replace;

************************************************************************************;
* VII. MERGE ALL EXPENDITURE FILES;
************************************************************************************;
#delimit ;
use $dir0\b1_ks000, clear;
merge hhid00  using $dir0\b1_ks100;
tab _merge;
* _merge=1 hh w/ outliers in ks02/ks03;
* _merge=2 hh w/ outliers in ks04b/ks07a/ks11aa;
list hhid00 _merge if _merge~=3;
*keep if _merge==3;
rename _merge _m1;
sort hhid00 ;
merge hhid00  using $dir0\b1_ks200;
tab _merge;
* _merge=1 hh w/ outliers in ks06;
* _merge=2 hh w/ outliers in ks02/ks03/ks04b/ks07a/ks11aa;
list hhid00 _merge if _merge~=3;
*keep if _merge==3;
rename _merge _m2; 
sort hhid00 ;
merge hhid00  using $dir0\b1_ks300;
tab _merge;
* _merge=1 hh w/ outliers in ks08/ks09a;
* _merge=2 hh w/ outliers in ks02/ks03/ks04b/ks07a/ks11aa/ks06; 
list hhid00 _merge if _merge~=3;
*keep if _merge==3;
rename _merge _m3;
sort hhid00 ;
merge hhid00  using $dir0\b2_kr00;
tab _merge;
* _merge=1 hh in Book 1-KS but not in Book 2 - KR;
* _merge=2 hh in Book 2-KR but not in Book 1 - KS;
list hhid00 _merge if _merge~=3;
*keep if _merge==3;
rename _merge _mkr;

gen z=missks02+missks03+missks06+miss4b+miss7a+missks08+missks09+misskr+miss10aa+miss10ab+miss11aa+miss11ab+miss12aa+miss12ab+miss12bb;
gen missing=1 if z>0 & z~=. ;
replace missing=0 if missing==. & z~=.;

drop z ;
lab var missing "Household with at least 1 part of expenditure missing";
tab missing, m;
lab data "Merged Book1/KS with missing value & outlier information. Wide version";
save $dir0\pre_pce00.dta, replace;


******************************************************************************;
*VIII. PCE  ;
******************************************************************************;
use $dir0\pre_pce00,clear;
**FOOD (KS02, KS03, AND KS04B), MONTHLY;

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
sort hhid00;

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

sort hhid00;
drop ks0* ;
compress;
save $dir0\pce00_wo_hhsize.dta, replace;


****************************************************************************************************
* IX. MERGE WITH HHSIZE.DTA,  DATA FROM AR WITH INFO ON HHSIZE (AR01==1 OR 5)
*************************************************************************************************
#delimit ;
use hhid00 member00 if member00==1 using $dir3\ptrack, clear;
bys hhid00: gen hhsize=_N;
bys hhid00: keep if _n==_N;
lab var hhsize "HH size";
sort hhid00;
save $dir0\hhsize00, replace;

merge hhid00  using $dir0\pce00_wo_hhsize.dta;
lab var _merge "1=KS/KRmonthly 2=  3=both";
tab _merge ;
keep if _merge==3;
tab missing _merge, m;
tab _mkr _merge, m;

inspect hhexp ;
inspect hhsize;

*PER CAPITA EXPENDITURES: HHEXP/HHSIZE

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
rename sc010099 provid;
keep hhid00* commid00 prov kabid kecid orige x* m* i* w* _out* hh* *pce hhsize owners; 
drop miss* member;
des;
sum;
lab data "Per Capita Expenditure 2000";
sort hhid00;
save $dir09\pce00nom.dta, replace;


*************************************************************************************************;
* X. Creating the smaller file containing only the nominal and the real consumption aggregate;
*************************************************************************************************;
#delimit ;
use $dir09\pce2000nom.dta, clear;
merge hhid00 using $dir09\deflate_hh00;
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
keep hhid00 hhsize xtotal xfood xnonfood rtotal rfood rnonfood;
sort hhid00;
compress;
lab data "Real HH Per Capita Expenditure 2000";
save $dir09\pce00.dta, replace;

log close; 
