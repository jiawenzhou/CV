# Leverage Regulation and Small-Business Credit

## Overview
This project investigates whether the 2014 Supplementary Leverage Ratio (SLR) affected small-business lending by large U.S. banks.  
We compare 15 SLR-constrained banks with 18 size-matched peers using a bank–county panel from 2009–2019.

## Data
- **Community Reinvestment Act (CRA)** small-business loan disclosures
- **FFIEC Call Reports** (capital ratios, balance sheet)
- Matched by RSSD identifiers  
- Variables: number of loans, loan amount by size category (<$100k, $100–250k, $250k–1m)

## Methodology
- Difference-in-Differences (DiD) with bank and county-year fixed effects
- Standard errors clustered at the bank level

## Current Status
- Data cleaning completed
- Preliminary regressions suggest SLR-constrained banks increased sub-$100k loans by ≈50% and dollar volume by ≈35% after the rule
- Manuscript in progress

## Repository Structure
- `Result: SLR Effect on Loan Number.xlsx`: reggression result on loan number
- `Result: SLR Effect on Loan Amount.xlsx`: reggression result on loan amount
- `SLR cleaning.do`: data cleaning do file
- `SLR regression.do`: reggression do file 
