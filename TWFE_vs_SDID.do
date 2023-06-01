* This do file finishes four tasks:
* (1) It shows some Stata commands to run difference-in-differences specifications by the two-way fixed effects (TWFE) model.
* (2) Following Arkhangelsky et al. (2021) and Clarke et al. (2023), it runs synthetic DID. The data are from Orzechowski & Walker (2005) and data from Bhalotra et al. (2022).
* (3) It shows how to run dynamic DID, using data from Serrato & Zidar (2018).
* (4) It briefly instroduces "xthdidregress", a new command introduced in Stata 18.

* Author: Ian He
* Date: May 13, 2023
***********************************************************************

clear all

global localdir "D:\research\DID Example"

global dtadir   "$localdir\Data"
global figdir   "$localdir\Figure"



*************************************************************************
**# Block Treatment: Orzechowski & Walker (2005)
use "$dtadir\OW05_prop99.dta", clear

encode state, gen(state_code)
xtset state_code year
* Balanced panel: 39 states, years from 1970 to 2000.
* Treated group: California (1 unit).
* Control group: 38 other states.


* TWFE DID
xtdidregress (packspercapita) (treated), group(state_code) time(year) vce(cluster state_code)
estat trendplots	// visualization
estat ptrends		// parallel-trends test
estat granger		// anticipation test
estat grangerplot	// time-specific treatment effects

eststo twfe1: qui xtreg packspercapita treated i.year, fe cluster(state_code)

eststo twfe2: qui areg packspercapita treated i.year, absorb(state_code) cluster(state_code)

eststo twfe3: qui reghdfe packspercapita treated, absorb(state_code year) cluster(state_code)

estout twfe*, keep(treated) ///
	coll(none) cells(b(star fmt(3)) se(par fmt(3))) ///
	starlevels(* .1 ** .05 *** .01) legend ///
	stats(N r2_a, nostar labels("Observations" "Adjusted R2") fmt("%9.0fc"3))


* Sythetic DID
eststo syn_did: sdid packspercapita state year treated, vce(placebo) seed(1) ///
	graph g1on ///
	g1_opt(xtitle("") ///
		plotregion(fcolor(white) lcolor(white)) ///
		graphregion(fcolor(white) lcolor(white)) ///
	) ///
	g2_opt(ylabel(0(25)150) ytitle("Packs per capita") ///
		plotregion(fcolor(white) lcolor(white)) ///
		graphregion(fcolor(white) lcolor(white)) ///
	) ///
	graph_export("$figdir\prop99_did_", .pdf)

ereturn list
matrix list e(omega)	// unit-specific weights
matrix list e(lambda)	// time-specific weights

estout twfe* syn_did, keep(treated) ///
	coll(none) cells(b(star fmt(3)) se(par fmt(3))) ///
	starlevels(* .1 ** .05 *** .01) legend ///
	stats(N r2_a, nostar labels("Observations" "Adjusted R2") fmt("%9.0fc"3))


* Compare SDID, DID, and SC
foreach m in sdid did sc {
	if "`m'"=="did" {
		local g_opt = "msize(small)"
	}
	else {
		local g_opt = ""
	}
	
	sdid packspercapita state year treated, ///
		method(`m') vce(noinference) graph g1on `g_opt' ///
		g1_opt(xtitle("") ytitle("") ///
			xlabel(, labsize(tiny)) ///
			ylabel(-100(25)50, labsize(small)) ///
			plotregion(fcolor(white) lcolor(white)) ///
			graphregion(fcolor(white) lcolor(white)) ///
		) ///
		g2_opt(title("`m'") xtitle("") ytitle("") ///
			xlabel(, labsize(small)) ///
			ylabel(0(25)150, labsize(small)) ///
			plotregion(fcolor(white) lcolor(white)) ///
			graphregion(fcolor(white) lcolor(white)) ///
		)
	graph save g1_1989 "$figdir\\`m'_1.gph", replace
	graph save g2_1989 "$figdir\\`m'_2.gph", replace
}

graph combine "$figdir\sdid_2.gph" "$figdir\did_2.gph" "$figdir\sc_2.gph" "$figdir\sdid_1.gph" "$figdir\did_1.gph" "$figdir\sc_1.gph", ///
	cols(3) xsize(3.5) ysize(2) ///
	graphregion(fcolor(white) lcolor(white))
graph export "$figdir\compare_sdid_did_sc.pdf", replace



*************************************************************************
**# Staggered Treatment: Bhalotra et al. (2022)
use "$dtadir\BCGV22_gender_quota.dta", clear

drop if lngdp==.
tab year
isid country year
* Balanced panel: 115 countries, years from 1990 to 2015.
* Treated group: 9 countries.
* Control group: 106 other states.


eststo stagg1: sdid womparl country year quota, vce(bootstrap) seed(3) ///
	graph g1on ///
	g1_opt(xtitle("") ytitle("") xlabel(, labsize(tiny)) ///
		plotregion(fcolor(white) lcolor(white)) ///
		graphregion(fcolor(white) lcolor(white)) ///
	) ///
	g2_opt(ytitle("") ///
		plotregion(fcolor(white) lcolor(white)) ///
		graphregion(fcolor(white) lcolor(white)) ///
	)

ereturn list
matrix list e(tau)	// adoption-period specific estimate
matrix list e(lambda)
matrix list e(omega)
matrix list e(adoption)	// different adoption years

eststo stagg2: sdid womparl country year quota, covariates(lngdp, optimized) vce(bootstrap) seed(3)

eststo stagg3: sdid womparl country year quota, covariates(lngdp, projected) vce(bootstrap) seed(3)

estout stagg*, ///
	coll(none) cells(b(star fmt(3)) se(par fmt(3))) ///
	starlevels(* .1 ** .05 *** .01) legend ///
	stats(N, nostar labels("Observations") fmt("%9.0fc"))



*************************************************************************
**# Staggered Treatment: Serrato & Zidar (2018)
use "$dtadir\SZ18_state_taxes.dta", replace

keep if year >= 1980 & year <= 2010
drop if fips_state == 11 | fips_state == 0 | fips_state > 56

xtset fips_state year
* Balanced panel: 50 states, years from 1980 to 2010.
* Treated group: 15 states.
* Control group: 35 other states.

* Construct dependent variables
gen log_rev_corptax = 100*ln(rev_corptax+1)
gen log_gdp = 100*ln(GDP)
g r_g = 100*rev_corptax/GDP


* Screen out the tax change with a pre-determined threshold
local threshold = 0.5
gen ch_corporate_rate = corporate_rate - L1.corporate_rate
replace ch_corporate_rate = 0 if abs(ch_corporate_rate) <= `threshold'
gen ch_corporate_rate_inc = (ch_corporate_rate > 0 & !missing(ch_corporate_rate))
gen ch_corporate_rate_dec = (ch_corporate_rate < 0 & !missing(ch_corporate_rate))


* Contruct treatment dummies
** Static
gen change_year = year if ch_corporate_rate_dec==1
bysort fips_state: egen tchange_year = min(change_year)
gen treated = (year >= tchange_year)

** Dynamic
gen period = year - tchange_year
gen Dn5 = (period < -4)
forvalues i = 4(-1)1 {
	gen Dn`i' = (period == -`i')
}

forvalues i = 0(1)5 {
	gen D`i' = (period == `i')
}
gen D6 = (period >= 6 & period != .)


* Static DID
local ylist = "log_rev_corptax log_gdp r_g"
local i = 1
foreach yvar in `ylist' {
	quietly{
		eststo areg`i': areg `yvar' treated i.fips_state, absorb(year) cluster(fips_state)
		eststo hdreg`i': reghdfe `yvar' treated, absorb(fips_state year) cluster(fips_state)
		eststo sdid`i': sdid `yvar' fips_state year treated, vce(bootstrap) seed(2018)
		local ++i
	}
}

estout areg1 hdreg1 sdid1 areg2 hdreg2 sdid2 areg3 hdreg3 sdid3, keep(treated) ///
	coll(none) cells(b(star fmt(3)) se(par fmt(3))) ///
	starlevels(* .1 ** .05 *** .01) legend ///
	stats(N r2_a, nostar labels("Observations" "Adj. R2") fmt("%9.0fc" 3))


* Dynamic DID (sdid cannot do this)
local ylist = "log_rev_corptax log_gdp r_g"
local i = 1
foreach yvar in `ylist' {
	quietly{
		eststo areg`i': areg `yvar' Dn5-Dn2 D0-D6 i.fips_state, absorb(year) cluster(fips_state)
		eststo hdreg`i': reghdfe `yvar' Dn5-Dn2 D0-D6, absorb(fips_state year) cluster(fips_state)
		local ++i
	}
	
}

estout areg1 hdreg1 areg2 hdreg2 areg3 hdreg3, keep(D*) ///
	coll(none) cells(b(star fmt(3)) se(par fmt(3))) ///
	starlevels(* .1 ** .05 *** .01) legend ///
	stats(N r2_a, nostar labels("Observations" "Adj. R2") fmt("%9.0fc" 3))


**# Stata 18 new command: xthdidregress
local controls = "FederalIncomeasStateTaxBase sales_wgt throwback FedIncomeTaxDeductible Losscarryforward FranchiseTax"
local ps_var = "FederalIncomeasStateTaxBase sales_wgt throwback FedIncomeTaxDeductible FranchiseTax"

xthdidregress aipw (log_gdp `controls') (treated `ps_var'), group(fips_state) vce(cluster fips_state)

* Visualizing ATT for each cohort
estat atetplot
graph export "$figdir\SZ18_cohort_ATT.pdf", replace

* Visualizing ATT over cohort
estat aggregation, cohort ///
	graph(xlab(, angle(45) labsize(small)) legend(rows(1) position(6)))
graph export "$figdir\SZ18_cohort_agg_ATT.pdf", replace

* Visualizing ATT over time
estat aggregation, time ///
	graph(xlab(, angle(45) labsize(small)) legend(rows(1) position(6)))
graph export "$figdir\SZ18_time_agg_ATT.pdf", replace

* Visualizing dynamic effects
estat aggregation, dynamic(-5/6) ///
	graph( ///
		title("Dynamic Effects on Log State GDP", size(medlarge)) ///
		xlab(, labsize(small) nogrid) ///
		legend(rows(1) position(6)) ///
		xline(0, lpattern(dash) lcolor(gs12) lwidth(thin)) ///
	)
graph export "$figdir\SZ18_dynamic_ATT.pdf", replace
