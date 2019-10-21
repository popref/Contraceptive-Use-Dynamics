
*This do file creates a monthly MCPR prevalence for women age 15-45 years using the DHS IR dataset.
	*The code is mostly sourced from the DHS Calendar Tutorial - Example 6, which can be downloaded here: https://www.dhsprogram.com/data/calendar-tutorial/

* download the dataset for individual women's recode: "BDIR72FL.DTA" 
* the datasets are available at https://www.dhsprogram.com/data/available-datasets.cfm

* change to a working directory where the data are stored
* or add the full path to the 'use' command below
cd "~/Analysis/Do Files/Bangladesh"

* open the dataset to use, selecting just the variables we are going to use
use caseid vcal_1 v000 v005 v007 v008 v011 v018 v021 v023 using "BDIR72FL.DTA", clear

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

* simply tabulate CPR for each month, and restrict age group to age 15-45 (months 180-539)
tab cmctime usingany [iw=wt] if inrange(agem,180,539), row nofreq

* set up the svy paramters and calculate the mean of usingmodern (which is the MCPR)
svyset v021 [pweight=wt], strata(v023)
*svyset v021 [pw=wt], strata(v022) 

* tabulate mCPR for women 15-44
svy, subpop(if inrange(agem,180,539)): mean usingmodern, over(cmctime) nolegend


**Step 6.6 
*Compare the restrospective calendar estimate to the current DHS estimate for the period of overlap
*Open DHS comparison year
use "BDIR72FL.DTA", clear

svyset v021 [pweight=v005], strata(v023)
svy: tab v313 if v013!=7, ci
