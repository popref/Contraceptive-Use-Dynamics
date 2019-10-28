
*This do file creates a monthly MCPR prevalence for women age 15-45 years using the DHS IR dataset.
	*The code is mostly sourced from the DHS Calendar Tutorial - Example 6, which can be downloaded here: https://www.dhsprogram.com/data/calendar-tutorial/

* download the dataset for individual women's recode: "BDIR72FL.DTA" 
* the datasets are available at https://www.dhsprogram.com/data/available-datasets.cfm

* change to a working directory where the data are stored
* or add the full path to the 'use' command below
cd "~/Analysis/Do Files/Uganda"

* open the dataset to use, selecting just the variables we are going to use
use caseid vcal_1 v000 v005 v007 v008 v011 v018 v021 v023 using "UGIR7AFL.DTA", clear

*In some countries, not all women get the contraceptive calendar module, therefore drop those who do not have vcal_1
drop if vcal_1==""

* Step 6.1
* loop through calendar creating separate variables for each month
* total length of calendar to loop over including leading blanks (80)
local vcal_len = strlen(vcal_1[1])
forvalues i = 1/`vcal_len' {
  gen str1 method`i' = substr(vcal_1,`i',1)
}

* Step 6.2
* drop calendar string variable as we don't need it further
drop vcal_1

* reshape the data file into a file where the month is the unit of analysis
reshape long method, i(caseid) j(i)

* Step 6.3
* find the position of the earliest date of interview (the maximum value of v018)
egen v018_max = max(v018)

* drop cases outside of the five years preceding the earliest interview
* months 0-59 before the earliest interview date
keep if inrange(i,v018_max,v018_max+59)

* Step 6.4
* calculate age in months for each month in the calendar
gen agem = (v008 - v011) - (i - v018)

* calculate century month code for each month
gen cmctime = v008 - (i - v018)
label variable cmctime "Century month code"

* create variable for use of modern method as a 0/100 variable
gen usingmodern = !inlist(method, "0","B","P","T", "8" , "9", "W") * 100
label variable usingmodern "Using modern method"
label def usingmodern 0 "Not using" 100 "Using a modern method"
label val usingmodern usingmodern

* Step 6.5
* compute weight variable
gen wt=v005/1000000

* set up the svy paramters and calculate the mean of usingmodern (which is the MCPR)
svyset v021 [pweight=wt], strata(v023)
*svyset v021 [pw=wt], strata(v022) 

* tabulate mCPR for women 15-44
svy, subpop(if inrange(agem,180,539)): mean usingmodern, over(cmctime) nolegend


**Step 6.6 Create the graph

*Restrict dataset to age 15-44
keep if  inrange(agem,180,539)


  foreach i in 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40 41 42 43 44 45 46 47 48 49 50 51 52 53 54 55 56 57 58 59 60 61 62 63 64 65 66 67 68 69 70 71 72  {
 svy: mean usingmodern if i==`i'
 		matrix a=r(table)
        gen usingmodern_m_`i'=a[1,1]
		gen using_ll_`i'=a[5,1]
		gen using_ul_`i'=a[6,1]
 
 }
 

collapse (mean) usingmodern_* using_ll_* using_ul_* , by(cmctime)
 
reshape long usingmodern_m_ using_ll_ using_ul_ , i(cmctime) j(num)

 
**Insert cross sectional MCPR estimates manually for 2014, 2011 for the specified age range (age 15-44)
gen DHS_mcpr = 27.87 if num==15
replace DHS_mcpr = 21.16 if num==72



 
graph twoway scatter  usingmodern_m_ num , ///
	mlabposition(4) mlabsize(*.75) lpattern(dash)  || ///
	rcap  using_ul_ using_ll_ num , || /// 
	scatter DHS_mcpr num , ///
	ytitle("MCPR", size(*.75) linegap(30) ) ///
	scheme(s2color) ///
	xlabel(15 "2016" 27 "2015" 39 "2014" 51 "2013" 63 "2012" 72 "2011") ///
	xtitle("Year") legend(r(2) order (1 "MCPR, DHS Calendar Estimate" 3  "MCPR 2016, 2011" ))  ///
	graphregion(color(white)  )  ysize(10) xsize(10)  ///
	caption("Data: {it:DHS Uganda}", size(*.7)) title("Calendar Quality Assessment, Uganda")

 
