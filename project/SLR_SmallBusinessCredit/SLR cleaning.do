****RCFA_1.dta****
**(bank level)
cd "/Users/yuyudawang/Desktop/data"
import delimited "WRDS_CALL_RCFA_1.csv", clear
desc
br

gen tier1_ratio = rcfa8274 / rcfaa223

gen str8 repdate_str = string(rssd9999, "%08.0f")
gen repdate = daily(repdate_str, "YMD")
format repdate %td
gen date = qofd(repdate)        
format date %tq                
gen year    = year(repdate)
gen quarter = quarter(repdate)   
drop repdate_str repdate
rename rssd9001 rssdid
order rssdid year
sort rssdid year
duplicates list rssdid year quarter
keep if quarter==4

replace rssdsubmissiondate = subinstr(rssdsubmissiondate, ":", " ", 1)
gen double subm_dt = clock(rssdsubmissiondate, "DMY hms")
format subm_dt %tc
gsort subm_dt
bysort rssdid  year quarter (subm_dt): keep if _n == 1

**control variable
gen lnassets = ln(rcfa2170) 
gen lnassets2 = lnassets^2
gen rbc = rcfa8274/rcfaa223
keep rssdid year tier1_ratio 
keep if tier1_ratio !=.
save "RCFA_1.dta", replace
use "RCFA_1.dta", clear
sum tier1_ratio 
keep if tier1_ratio !=.


****BHCK_2.dta****
**(hcr level)
cd "/Users/yuyudawang/Desktop/data"
import delimited "WRDS_HOLDING_BHCK_2.csv", clear
desc
br
gen str8 repdate_str = string(rssd9999, "%08.0f")
gen repdate = daily(repdate_str, "YMD")
format repdate %td
gen date = qofd(repdate)        
format date %tq                
gen year    = year(repdate)
gen quarter = quarter(repdate)   


gen on_assets = bhck2170
gen der_exp   = bhck8725 + bhck8730   
gen sft_exp   = bhckb989                 
gen off_exp   = 0.2*bhck3814
*gen off_exp   = 0.2*bhck3814 + 0.5*bhck3816 + 1.0*bhck3411
* Total Leverage Exposure
egen leverage_exposure = rowtotal(on_assets der_exp sft_exp off_exp)

* SLR
gen slr = bhck8274 / leverage_exposure
gen tier1_ratio=bhck8274 /bhck2170
*keep if tier1_ratio != .
*keep slr tier1_ratio rssd9001 rssd9999

*control
gen ln_assets        = ln(bhck2170)
gen ln_assets_sq     = ln(bhck2170)^2
gen rbc_ratio        = bhck8274 / bhcka223 
gen nonint_ratio     = bhck4079 / bhck4107
gen liquidity_proxy  = (bhckc395 + bhckc397) / bhck2170



drop repdate_str repdate
rename rssd9001 rssdhcr
keep if quarter==4
keep rssdhcr year quarter liquidity_proxy nonint_ratio rbc_ratio ln_assets_sq ln_assets tier1_ratio slr
save "BHCK_2.dta", replace


*select control bank(depend on 2014q2)
**# Bookmark #2
import delimited "WRDS_HOLDING_BHCK_2.csv", clear
desc
br
gen str8 repdate_str = string(rssd9999, "%08.0f")
gen repdate = daily(repdate_str, "YMD")
format repdate %td
gen date = qofd(repdate)        
format date %tq                
gen year    = year(repdate)
gen quarter = quarter(repdate)   
keep if year ==2014
keep if quarter==2
order rssd9001 bhck2170 
gsort bhck2170 rssd9001
rename rssd9001 rssdhcr
*gen treatment
gen treatment = . 
replace treatment = 1 if bhck2170 > 250000000 & bhck2170 != .
replace treatment = 0 if bhck2170 >= 50000000 & bhck2170 <= 250000000
replace treatment = 1 if rssdhcr == 1275216 | rssdhcr == 1199611 
order rssdhcr bhck2170 treatment
rename rssd9017 bank
keep rssdhcr treatment bank
drop if treatment==.
export excel using "rssdhcr",replace
save "/Users/yuyudawang/Desktop/CRA/FDIC/treatment_parent.dta"

