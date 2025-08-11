global transpath "/Users/yuyudawang/Desktop/CRA/Transmittal/"
global fdicpath "/Users/yuyudawang/Desktop/CRA/FDIC/"
global crapath "/Users/yuyudawang/Desktop/CRA/"
global bhckpath "/Users/yuyudawang/Desktop/data/"

***find relationship:parent-subsidiry
*import delimited "$fdicpath/raw data/CSV_RELATIONSHIPS.CSV", clear
*keep id_rssd_parent id_rssd_offspring dt_end dt_reln_est dt_start
*rename id_rssd_parent rssdhcr
*rename id_rssd_offspring rssdid
*keep if dt_start<= 20141231 & (dt_end >= 20140101 | dt_end == 99991231)
*duplicates report rssdhcr rssdid



*merge control
import excel "$fdicpath/SLR_relationship.xlsx", sheet("Sheet1") cellrange(A1:D37) firstrow clear
merge 1:m rssdhcr using  "/Users/yuyudawang/Desktop/data/BHCK_2.dta"
keep if _merge==3
drop _merge 
tempfile slr_merge     
drop tier1_ratio
save "$fdicpath/SLR.dta", replace 

*merge CRA
import excel "$fdicpath/SLR_relationship.xlsx", sheet("Sheet1") cellrange(A1:D37) firstrow clear
merge 1:m rssdid using  "$transpath/cra_county_rssdid.dta"
keep if _merge==3
drop _merge
rename activityyear year
gen fips=state*1000+county
drop if fips==.
merge m:m rssdid year using "$fdicpath/SLR.dta"
keep if _merge==3
drop _merge


*merge tier1capital
merge m:1 rssdid year using  "/Users/yuyudawang/Desktop/data/RCFA_1.dta"
drop if _merge==2
drop _merge

gen byte post = (year > 2013) 
egen fips_year = group(fips year)
egen bank_year = group(rssdid year)
gen interaction=post*treatment

*dependent variable
egen numloan_total = rowtotal(numloanlessthan100k  numloanlargethan100klessthan250k numloanlargethan250klessthan1mil)
egen loanamt_total = rowtotal(loanamountlessthan100k  loanlargethan100klessthan250k loanlargethan250klessthan1mil)
gen ln_numloan_lt100k = ln(numloanlessthan100k)
gen ln_numloan_100k_250k= ln(numloanlargethan100klessthan250k)
gen ln_numloan_250k_1m= ln(numloanlargethan250klessthan1mil)
gen ln_numloan_total= ln(numloan_total)
gen ln_loanamt_lt100k= ln(loanamountlessthan100k)
gen ln_loanamt_100k_250k= ln(loanlargethan100klessthan250k)
gen ln_loanamt_250k_1m= ln(loanlargethan250klessthan1mil)
gen ln_loanamt_total= ln(loanamt_total)

label var ln_numloan_lt100k     "ln(# loans < $100k)"
label var ln_numloan_100k_250k  "ln(# loans $100k–250k)"
label var ln_numloan_250k_1m    "ln(# loans $250k–1m)"
label var ln_numloan_total      "ln(total # loans)"
label var ln_loanamt_lt100k     "ln(loan amt < $100k)"
label var ln_loanamt_100k_250k  "ln(loan amt $100k–250k)"
label var ln_loanamt_250k_1m    "ln(loan amt $250k–1m)"
label var ln_loanamt_total      "ln(total loan amt)"
keep if year>2008
keep if year<2020
save "$fdicpath/SLR_reg.dta",replace

**********baseline***************
***reg num_loan***

local counts ln_numloan_total ln_numloan_lt100k ln_numloan_100k_250k ln_numloan_250k_1m

eststo clear
local i = 1                                 

foreach y of local counts {
    /*—— Baseline——*/
    reghdfe `y' interaction, absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
    /*—— +Controls ——*/
    reghdfe `y' interaction liquidity_proxy nonint_ratio ln_assets,                       ///
            absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
}

label var interaction     "SLR×Post"
label var liquidity_proxy "Liquidity Proxy"
label var nonint_ratio    "Non-interest Inc. Ratio"
label var ln_assets       "Ln(Assets)"

local out "$fdicpath/result/reg_numloan.xlsx"
cap erase "`out'"

local titles "Total Total lt100k lt100k 100–250k 100–250k 250k–1m 250k–1m"

local i = 1
foreach m of numlist 1/8 {
    estimates restore model`m'
    local title : word `i' of `titles'

    if `i'==1 {
        outreg2 using "`out'", replace excel dec(3) se nocons label ///
            ctitle("`title'") addtext("Bank FE","Yes","County×Year FE","Yes") ///
            addstat("Within R-sq", e(r2_within))
    }
    else {
        outreg2 using "`out'", append  excel dec(3) se nocons label ///
            ctitle("`title'") addtext("Bank FE","Yes","County×Year FE","Yes") ///
            addstat("Within R-sq", e(r2_within))
    }
    local ++i
}



***reg loan_amt***
local counts ln_loanamt_total ln_loanamt_lt100k ln_loanamt_100k_250k ln_loanamt_250k_1m

eststo clear
local i = 1                                 

foreach y of local counts {
    /*—— Baseline——*/
    reghdfe `y' interaction, absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
    /*—— +Controls ——*/
    reghdfe `y' interaction liquidity_proxy nonint_ratio ln_assets,                       ///
            absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
}

label var interaction     "SLR×Post"
label var liquidity_proxy "Liquidity Proxy"
label var nonint_ratio    "Non-interest Inc. Ratio"
label var ln_assets       "Ln(Assets)"

local out "$fdicpath/result/reg_loanamt.xlsx"
cap erase "`out'"

local titles "Total Total lt100k lt100k 100–250k 100–250k 250k–1m 250k–1m"

local i = 1
foreach m of numlist 1/8 {
    estimates restore model`m'
    local title : word `i' of `titles'

    if `i'==1 {
        outreg2 using "`out'", replace excel dec(3) se nocons label ///
            ctitle("`title'") ///
            addtext("Bank FE","Yes","County×Year FE","Yes") ///
            addstat("Within R-sq", e(r2_within))
    }
    else {
        outreg2 using "`out'", append  excel dec(3) se nocons label ///
            ctitle("`title'") ///
            addtext("Bank FE","Yes","County×Year FE","Yes") ///
            addstat("Within R-sq", e(r2_within))
    }
    local ++i
}

   
  


**********Treat*Post*SLR***************
***reg num_loan***
use "$fdicpath/SLR_reg.dta",clear
gen interaction2=post*treatment*tier1_ratio
gen interaction3=post*tier1_ratio
local counts ln_numloan_total ln_numloan_lt100k ln_numloan_100k_250k ln_numloan_250k_1m

eststo clear
local i = 1                                 

foreach y of local counts {
    /*—— Baseline——*/
    reghdfe `y' interaction interaction2 interaction3, absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
    /*—— +Controls ——*/
    reghdfe `y' interaction interaction2 interaction3 liquidity_proxy nonint_ratio ln_assets,                       ///
            absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
}


estfe model*, labels(rssdid "Bank FE" fips_year "County×Year FE")
esttab model* using ///
   "$fdicpath/result/reg_numloan_SLR.tex", replace ///
   r2 p star(* 0.10 ** 0.05 *** 0.01) noconstant width(\hsize) depvars ///
   varlabels( interaction      "Post×Treatment"            ///
   interaction2      "SLR×Post×Treatment"            ///
   interaction3      "SLR×Treatment"            ///
              liquidity_proxy  "Liquidity Proxy"               ///
              nonint_ratio     "Non-interest Inc. Ratio"       ///
              ln_assets        "Ln(Assets)" )                  ///
   mlabels("Base Total" "Ctrl Total" "Base lt100k"  "Ctrl lt100k" "Base 100–250k" "Ctrl 100–250k" "Base 250k–1m"  "Ctrl 250k–1m")  indicate(`r(indicate_fe)')


***reg loan_amt***
local counts ln_loanamt_total ln_loanamt_lt100k ln_loanamt_100k_250k ln_loanamt_250k_1m

eststo clear
local i = 1                                 

foreach y of local counts {
    /*—— Baseline——*/
    reghdfe `y' interaction interaction2 interaction3, absorb(fips year) vce(cluster rssdid)
    eststo model`i'
    local ++i
    /*—— +Controls ——*/
    reghdfe `y' interaction interaction2 interaction3 liquidity_proxy nonint_ratio ln_assets,                       ///
            absorb(fips year) vce(cluster rssdid)
    eststo model`i'
    local ++i
}


estfe model*, labels(rssdid   "Bank FE" ///
                     fips_year "County×Year FE")
esttab model* using ///
   "$fdicpath/result/reg_loanamt_SLR.tex", replace ///
   r2 p star(* 0.10 ** 0.05 *** 0.01) noconstant width(\hsize) depvars ///
   varlabels( interaction      "Post×Treatment"            ///
   interaction2      "SLR×Post×Treatment"            ///
   interaction3      "SLR×Treatment"            ///
              liquidity_proxy  "Liquidity Proxy"               ///
              nonint_ratio     "Non-interest Inc. Ratio"       ///
              ln_assets        "Ln(Assets)" )                  ///
   mlabels("Base Total" "Ctrl Total" "Base lt100k"  "Ctrl lt100k" "Base 100–250k" "Ctrl 100–250k" "Base 250k–1m"  "Ctrl 250k–1m")  indicate(`r(indicate_fe)')

   

**********Treat*Post*GDP***************
***reg num_loan***
use "$fdicpath/SLR_reg.dta",clear
duplicates report fips year
merge m:1 fips year using "$fdicpath/control/control.dta"
gen lngdp=ln(gdp)
gen ln_medianincome=ln(MedianHouseholdIncome)
gen interaction_gdp=post*treatment*lngdp
gen interaction_medianincome=post*treatment*ln_medianincome
gen interaction_unemploy=post*treatment*UnemploymentRate
gen interaction_poverty=post*treatment*PovertyPercentAllAges
local counts ln_numloan_total ln_numloan_lt100k ln_numloan_100k_250k ln_numloan_250k_1m


eststo clear
local i = 1                                 

foreach y of local counts {
    /*—— Baseline——*/
    reghdfe `y' interaction interaction_gdp, absorb(bank_year fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
}


estfe model*, labels(bank_year   "Bank×Year FE" ///
                     fips_year "County×Year FE")
esttab model* using ///
   "$fdicpath/result/reg_numloan_gdp.tex", replace ///
   r2 p star(* 0.10 ** 0.05 *** 0.01) noconstant width(\hsize) depvars ///
   varlabels( interaction      "Post×Treatment"            ///
			interaction_gdp      "Post×Treatment×GDP" )           ///
   mlabels("Total" "lt100k" "100–250k" "250k–1m")  indicate(`r(indicate_fe)')


***reg loan_amt***
local counts ln_loanamt_total ln_loanamt_lt100k ln_loanamt_100k_250k ln_loanamt_250k_1m

eststo clear
local i = 1                                 

foreach y of local counts {
    reghdfe `y' interaction interaction_gdp, absorb(bank_year fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
}


estfe model*, labels(bank_year   "Bank×Year FE" ///
                     fips_year "County×Year FE")
esttab model* using ///
   "$fdicpath/result/reg_loanamt_gdp.tex", replace ///
   r2 p star(* 0.10 ** 0.05 *** 0.01) noconstant width(\hsize) depvars ///
   varlabels( interaction      "Post×Treatment"            ///
   			interaction_gdp      "Post×Treatment×GDP" )                  ///
   mlabels("Total" "lt100k" "100–250k" "250k–1m")  indicate(`r(indicate_fe)')


**********Treat*Post*medianincome***************
local counts ln_numloan_total ln_numloan_lt100k ln_numloan_100k_250k ln_numloan_250k_1m
eststo clear
local i = 1                                 
foreach y of local counts {
    /*—— Baseline——*/
    reghdfe `y' interaction interaction_medianincome, absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
    /*—— +Controls ——*/
    reghdfe `y' interaction interaction_medianincome liquidity_proxy nonint_ratio ln_assets,                       ///
            absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
}
estfe model*, labels(rssdid   "Bank FE" ///
                     fips_year "County×Year FE")
esttab model* using ///
   "$fdicpath/result/reg_numloan_medianincome.tex", replace ///
   r2 p star(* 0.10 ** 0.05 *** 0.01) noconstant width(\hsize) depvars ///
   varlabels( interaction      "Post×Treatment"            ///
   			interaction_medianincome      "Post×Treatment×MedianHouseholdIncome"            ///
              liquidity_proxy  "Liquidity Proxy"               ///
              nonint_ratio     "Non-interest Inc. Ratio"       ///
              ln_assets        "Ln(Assets)" )                  ///
   mlabels("Base Total" "Ctrl Total" "Base lt100k"  "Ctrl lt100k" "Base 100–250k" "Ctrl 100–250k" "Base 250k–1m"  "Ctrl 250k–1m")  indicate(`r(indicate_fe)')

***reg loan_amt***
local counts ln_loanamt_total ln_loanamt_lt100k ln_loanamt_100k_250k ln_loanamt_250k_1m
eststo clear
local i = 1                                 
foreach y of local counts {
    /*—— Baseline——*/
    reghdfe `y' interaction interaction_medianincome, absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
    /*—— +Controls ——*/
    reghdfe `y' interaction interaction_medianincome liquidity_proxy nonint_ratio ln_assets,                       ///
            absorb(rssdid year) vce(cluster rssdid)
    eststo model`i'
    local ++i
}
estfe model*, labels(rssdid   "Bank FE" ///
                     fips_year "County×Year FE")
esttab model* using ///
   "$fdicpath/result/reg_loanamt_medianincome.tex", replace ///
   r2 p star(* 0.10 ** 0.05 *** 0.01) noconstant width(\hsize) depvars ///
   varlabels( interaction      "Post×Treatment"            ///
   			interaction_medianincome      "Post×Treatment×MedianHouseholdIncome"            ///
              liquidity_proxy  "Liquidity Proxy"               ///
              nonint_ratio     "Non-interest Inc. Ratio"       ///
              ln_assets        "Ln(Assets)" )                  ///
   mlabels("Base Total" "Ctrl Total" "Base lt100k"  "Ctrl lt100k" "Base 100–250k" "Ctrl 100–250k" "Base 250k–1m"  "Ctrl 250k–1m")  indicate(`r(indicate_fe)')

   
   
**********Treat*Post*unemploy***************
local counts ln_numloan_total ln_numloan_lt100k ln_numloan_100k_250k ln_numloan_250k_1m
eststo clear
local i = 1                                 
foreach y of local counts {
    /*—— Baseline——*/
    reghdfe `y' interaction interaction_unemploy, absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
    /*—— +Controls ——*/
    reghdfe `y' interaction interaction_unemploy liquidity_proxy nonint_ratio ln_assets,                       ///
            absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
}
estfe model*, labels(rssdid   "Bank FE" ///
                     fips_year "County×Year FE")
esttab model* using ///
   "$fdicpath/result/reg_numloan_unemploy.tex", replace ///
   r2 p star(* 0.10 ** 0.05 *** 0.01) noconstant width(\hsize) depvars ///
   varlabels( interaction      "Post×Treatment"            ///
   			interaction_unemploy      "Post×Treatment×UnemploymentRate"            ///
              liquidity_proxy  "Liquidity Proxy"               ///
              nonint_ratio     "Non-interest Inc. Ratio"       ///
              ln_assets        "Ln(Assets)" )                  ///
   mlabels("Base Total" "Ctrl Total" "Base lt100k"  "Ctrl lt100k" "Base 100–250k" "Ctrl 100–250k" "Base 250k–1m"  "Ctrl 250k–1m")  indicate(`r(indicate_fe)')

***reg loan_amt***
local counts ln_loanamt_total ln_loanamt_lt100k ln_loanamt_100k_250k ln_loanamt_250k_1m
eststo clear
local i = 1                                 
foreach y of local counts {
    /*—— Baseline——*/
    reghdfe `y' interaction interaction_unemploy, absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
    /*—— +Controls ——*/
    reghdfe `y' interaction interaction_unemploy liquidity_proxy nonint_ratio ln_assets,                       ///
            absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
}
estfe model*, labels(rssdid   "Bank FE" ///
                     fips_year "County×Year FE")
esttab model* using ///
   "$fdicpath/result/reg_loanamt_unemploy.tex", replace ///
   r2 p star(* 0.10 ** 0.05 *** 0.01) noconstant width(\hsize) depvars ///
   varlabels( interaction2      "SLR×Post"            ///
              liquidity_proxy  "Liquidity Proxy"               ///
              nonint_ratio     "Non-interest Inc. Ratio"       ///
              ln_assets        "Ln(Assets)" )                  ///
   mlabels("Base Total" "Ctrl Total" "Base lt100k"  "Ctrl lt100k" "Base 100–250k" "Ctrl 100–250k" "Base 250k–1m"  "Ctrl 250k–1m")  indicate(`r(indicate_fe)')


   
   
**********Treat*Post*poverty***************
local counts ln_numloan_total ln_numloan_lt100k ln_numloan_100k_250k ln_numloan_250k_1m
eststo clear
local i = 1                                 
foreach y of local counts {
    /*—— Baseline——*/
    reghdfe `y' interaction interaction_poverty, absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
    /*—— +Controls ——*/
    reghdfe `y' interaction interaction_poverty liquidity_proxy nonint_ratio ln_assets,                       ///
            absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
}
estfe model*, labels(rssdid   "Bank FE" ///
                     fips_year "County×Year FE")
esttab model* using ///
   "$fdicpath/result/reg_numloan_poverty.tex", replace ///
   r2 p star(* 0.10 ** 0.05 *** 0.01) noconstant width(\hsize) depvars ///
   varlabels( interaction2      "SLR×Post"            ///
              liquidity_proxy  "Liquidity Proxy"               ///
              nonint_ratio     "Non-interest Inc. Ratio"       ///
              ln_assets        "Ln(Assets)" )                  ///
   mlabels("Base Total" "Ctrl Total" "Base lt100k"  "Ctrl lt100k" "Base 100–250k" "Ctrl 100–250k" "Base 250k–1m"  "Ctrl 250k–1m")  indicate(`r(indicate_fe)')

***reg loan_amt***
local counts ln_loanamt_total ln_loanamt_lt100k ln_loanamt_100k_250k ln_loanamt_250k_1m
eststo clear
local i = 1                                 
foreach y of local counts {
    /*—— Baseline——*/
    reghdfe `y' interaction interaction_poverty, absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
    /*—— +Controls ——*/
    reghdfe `y' interaction interaction_poverty liquidity_proxy nonint_ratio ln_assets,                       ///
            absorb(rssdid fips_year) vce(cluster rssdid)
    eststo model`i'
    local ++i
}
estfe model*, labels(rssdid   "Bank FE" ///
                     fips_year "County×Year FE")
esttab model* using ///
   "$fdicpath/result/reg_loanamt_poverty.tex", replace ///
   r2 p star(* 0.10 ** 0.05 *** 0.01) noconstant width(\hsize) depvars ///
   varlabels( interaction2      "SLR×Post"            ///
              liquidity_proxy  "Liquidity Proxy"               ///
              nonint_ratio     "Non-interest Inc. Ratio"       ///
              ln_assets        "Ln(Assets)" )                  ///
   mlabels("Base Total" "Ctrl Total" "Base lt100k"  "Ctrl lt100k" "Base 100–250k" "Ctrl 100–250k" "Base 250k–1m"  "Ctrl 250k–1m")  indicate(`r(indicate_fe)')
