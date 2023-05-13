* This do file runs Sun & Abraham (2021)'s DID method using data on China's export to the US in 2000-2009. The main goal is to show how to contruct a table in LaTeX to report the results, considering that as of now there is no package (like "estout") works well with "eventstudyinteract" to export regression results in a table.
* Author: Ian He
* Institution: The University of Oklahoma
* Date: Apr 22, 2023
*************************************************************************

clear all

global localdir "D:\research\DID Example"

global dtadir   "$localdir\Data"
global figdir   "$localdir\Figure"
global tabdir   "$localdir\Table"



*************************************************************************
**# Create a series of dummies for duty impositions
use "$dtadir\CCD_GAD_USA_affirm.dta", clear

gen period_duty = year - year_des_duty

gen Dn3 = (period_duty < -2)
forvalues i = 2(-1)1 {
	gen Dn`i' = (period_duty == -`i')
}

forvalues i = 0(1)3 {
	gen D`i' = (period_duty == `i')
}
gen D4 = (period_duty >= 4) & (period_duty != .)



*************************************************************************
**# Run the IW DID regressions

encode hs06, generate(product)
gen first_union = year_des_duty
gen never_union = (first_union == .)

local dep = "value quantity company_num m_quantity"
foreach y in `dep'{	
	eventstudyinteract ln_`y' Dn3 Dn2 D0-D4, cohort(first_union) control_cohort(never_union) absorb(product year) vce(cluster product#year)
	
	* Store the results in some matrices
	forvalue i=1/7 {
		local m`y'_`i' = e(b_iw)[1,`i']
		local v`y'_`i' = e(V_iw)[`i',`i']
	}
	
	local eN = e(N)
	local er2 = e(r2_a)

	matrix input matb`y'_sa= (`m`y'_1',`m`y'_2',0,`m`y'_3',`m`y'_4',`m`y'_5',`m`y'_6',`m`y'_7')
	mat colnames matb`y'_sa= ld3 ld2 ld1 lg0 lg1 lg2 lg3 lg4

	matrix input mats`y'_sa= (`v`y'_1',`v`y'_2',0,`v`y'_3',`v`y'_4',`v`y'_5',`v`y'_6',`v`y'_7')
	mat colnames mats`y'_sa= ld3 ld2 ld1 lg0 lg1 lg2 lg3 lg4
	
	matrix input mate`y'_sa = (`eN',`er2')
	mat colnames mate`y'_sa = N r2_a
}



*************************************************************************
**# Construct a table
preserve

* Generate labels to describe each row
g labels = ""
local row = 1

forvalue i = -3(1)4 {
	replace labels = "Period `i'" in `row'
	local ++row
	replace labels = "" in `row'
	local ++row
}
replace labels = "Observations" in `row'
local ++row
replace labels = "Adjusted R2" in `row'


* Input coefficients and standard errors
foreach var in value quantity company_num m_quantity {
	quietly{
		local row = 1
		local decimal = 3
		g reg_`var' = ""
		
		forvalue i = 1/8 {
			replace reg_`var' = string(matb`var'_sa[1,`i'], "%12.`decimal'f") in `row'
			local ++row
			local se`var'_`i' = sqrt(mats`var'_sa[1,`i'])
			replace reg_`var' = string(`se`var'_`i'', "%12.`decimal'f") in `row'
			replace reg_`var' = "(" + reg_`var' + ")" in `row'
			local ++row
		}
		replace reg_`var' = string(mate`var'_sa[1,1], "%12.0fc") in `row'
		local ++row
		replace reg_`var' = string(mate`var'_sa[1,2], "%12.`decimal'f") in `row'
	}
}


* Assign aeterisks to denote significance
foreach var in value quantity company_num m_quantity {
	quietly{
		g star90l_`var' = 0
		g star90h_`var' = 0
		g star95l_`var' = 0
		g star95h_`var' = 0
		g star99l_`var' = 0
		g star99h_`var' = 0
		
		local row = 1
		forvalue i = 1/8 {
			replace star90l_`var' = matb`var'_sa[1,`i'] - 1.645 * sqrt(mats`var'_sa[1,`i']) in `row'
			replace star90h_`var' = matb`var'_sa[1,`i'] + 1.645 * sqrt(mats`var'_sa[1,`i']) in `row'
			replace star95l_`var' = matb`var'_sa[1,`i'] - 1.96 * sqrt(mats`var'_sa[1,`i']) in `row'
			replace star95h_`var' = matb`var'_sa[1,`i'] + 1.96 * sqrt(mats`var'_sa[1,`i']) in `row'
			replace star99l_`var' = matb`var'_sa[1,`i'] - 2.576 * sqrt(mats`var'_sa[1,`i']) in `row'
			replace star99h_`var' = matb`var'_sa[1,`i'] + 2.576 * sqrt(mats`var'_sa[1,`i']) in `row'
			local ++row
			local ++row
		}
	}
}

foreach var in value quantity company_num m_quantity {
	quietly{
		gen stars_`var' = ""
		replace stars_`var' = "*" if 0 < star90l_`var' | 0 > star90h_`var'
		replace stars_`var' = "**" if 0 < star95l_`var' | 0 > star95h_`var'
		replace stars_`var' = "***" if 0 < star99l_`var' | 0 > star99h_`var'
		replace reg_`var' = reg_`var' + stars_`var'
	}
}


* There is no estimate for Period -1
drop if _n == 5 | _n == 6



*************************************************************************
**# Export the table

g tab = "\begin{tabular}{l*{5}{l}}" in 1
g colnum = "& (1) & (2) & (3) & (4)" in 1
g titlerow = "Dep. vairable & ln(Value) & ln(Quantity) & ln(Exporters) & ln(Mean Quantity)" in 1
g hline = "\hline" in 1
g end = "\end{tabular}" in 1

listtex tab if _n == 1 using "$tabdir/SA_DID_result.tex", replace
listtex hline if _n == 1, appendto("$tabdir/SA_DID_result.tex")
listtex hline if _n == 1, appendto("$tabdir/SA_DID_result.tex")
listtex colnum if _n==1, appendto("$tabdir/SA_DID_result.tex") rstyle(tabular)
listtex titlerow if _n==1, appendto("$tabdir/SA_DID_result.tex") rstyle(tabular)
listtex hline if _n == 1, appendto("$tabdir/SA_DID_result.tex")
listtex labels reg_value reg_quantity reg_company_num reg_m_quantity if _n<=16, appendto("$tabdir/SA_DID_result.tex") rstyle(tabular)
listtex hline if _n == 1, appendto("$tabdir/SA_DID_result.tex")
listtex hline if _n == 1, appendto("$tabdir/SA_DID_result.tex")
listtex end if _n == 1, appendto("$tabdir/SA_DID_result.tex")

restore
