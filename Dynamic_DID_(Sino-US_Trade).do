* This do file runs various dynamic DID specifications using data on China's export to the US in 2000-2009.
* Author: Ian He
* Date: Jun 23, 2023
* Stata Version: 18

clear all

global localdir "D:\research\DID"

global dtadir   "$localdir\Data"
global figdir   "$localdir\Figure"



********************************************************************************
use "$dtadir\USA_AD_CHN.dta", clear

**# Create a series of dummies for duty impositions
gen period_duty = year - year_des_duty
gen treated = (period_duty < . & period_duty >= 0)

gen Dn3 = (period_duty < -2)
forvalues i = 2(-1)1 {
	gen Dn`i' = (period_duty == -`i')
}

forvalues i = 0(1)3 {
	gen D`i' = (period_duty == `i')
}
gen D4 = (period_duty >= 4) & (period_duty != .)


**# Classical Dynamic DID
* ssc install reghdfe, replace
* ssc install ftools, replace

encode hs06, generate(product) // string variables are not allowed for "xtset" and regressions

local dep = "value quantity company_num m_quantity"
foreach y in `dep'{
	quietly{		
		eststo reg_`y': reghdfe ln_`y' Dn3 Dn2 D0-D4, absorb(product year) vce(cluster product#year)
	}
}

estout reg*, keep(D*) ///
	coll(none) cells(b(star fmt(3)) se(par fmt(3))) ///
	starlevels(* .1 ** .05 *** .01) legend ///
	stats(N r2_a, nostar labels("Observations" "Adjusted R-Square") fmt("%9.0fc" 3))



********************************************************************************
**# Sun and Abraham (2021)
* ssc install eventstudyinteract, replace
* ssc install avar, replace
* ssc install event_plot, replace

gen first_union = year_des_duty
gen never_union = (first_union == .)

local dep = "value quantity company_num m_quantity"
foreach y in `dep'{	
	* Regression
	eventstudyinteract ln_`y' Dn3 Dn2 D0-D4, cohort(first_union) control_cohort(never_union) absorb(product year) vce(cluster product#year)
	
	* Visualization
	if "`y'"=="value"{
		local panel = "A)"
		local title = "ln(Value)"
	}
	
	if "`y'"=="quantity"{
		local panel = "B)"
		local title = "ln(Total Quantity)"
	}
	
	if "`y'"=="company_num"{
		local panel = "C)"
		local title = "ln(Number of Exporters)"
	}
	
	if "`y'"=="m_quantity"{
		local panel = "D)"
		local title = "ln(Mean Quantity)"
	}
	
	forvalue i=1/7 {
		local m_`i' = e(b_iw)[1,`i']
		local v_`i' = e(V_iw)[`i',`i']
	}

	matrix input matb_sa= (`m_1',`m_2',0,`m_3',`m_4',`m_5',`m_6',`m_7')
	mat colnames matb_sa= ld3 ld2 ld1 lg0 lg1 lg2 lg3 lg4

	matrix input mats_sa= (`v_1',`v_2',0,`v_3',`v_4',`v_5',`v_6',`v_7')
	mat colnames mats_sa= ld3 ld2 ld1 lg0 lg1 lg2 lg3 lg4

	event_plot matb_sa#mats_sa, ///
		stub_lag(lg#) stub_lead(ld#) ///
		ciplottype(rcap) plottype(scatter) ///
		lag_opt(msymbol(D) mcolor(black) msize(small)) ///
		lead_opt(msymbol(D) mcolor(black) msize(small)) ///
		lag_ci_opt(lcolor(black) lwidth(medthin)) ///
		lead_ci_opt(lcolor(black) lwidth(medthin)) ///
		graph_opt( ///
			title("`panel' `title'", size(medlarge) position(11)) ///
			xtitle("Period", height(5)) xsize(5) ysize(4) ///
			ytitle("Coefficient", height(5)) ///
			xline(0, lpattern(dash) lcolor(gs12) lwidth(thin)) ///
			yline(0, lpattern(solid) lcolor(gs12) lwidth(thin)) ///
			xlabel(-3 "< -2" -2(1)3 4 "> 3", labsize(small)) ///
			ylabel(, labsize(small)) ///
			legend(order(1 "Coefficient" 2 "95% CI") size(*0.8) rows(1) region(lc(black))) ///
			name(sa_`y', replace) ///
			graphregion(color(white)) ///
		)
}

* net install grc1leg.pkg, replace
grc1leg sa_value sa_quantity sa_company_num sa_m_quantity, ///
	legendfrom(sa_value) cols(2) ///
	graphregion(fcolor(white) lcolor(white)) ///
	name(sa_fig, replace)

gr draw sa_fig, ysize(5) xsize(6.5)
graph export "$figdir\SA_DID_Trade_Destruction.pdf", replace



********************************************************************************
**# Callaway & Sant'Anna (2021)
* ssc install csdid, replace
* ssc install drdid, replace

gen gvar = year_des_duty
recode gvar (. = 0)

local dep = "value quantity company_num m_quantity"
foreach y in `dep'{	
	quietly csdid ln_`y', ivar(product) time(year) gvar(gvar) method(dripw) wboot(reps(10000)) rseed(1)
	csdid_estat event, window(-3 4) estore(cs_`y') wboot(reps(10000)) rseed(1)
}

estout cs_*, keep(T*) ///
	coll(none) cells(b(star fmt(3)) se(par fmt(3))) ///
	starlevels(* .1 ** .05 *** .01) legend ///
	stats(N r2_a, nostar labels("Observations" "Adjusted R-Square") fmt("%9.0fc" 3))

* Visualization
local ylist = "value quantity company_num m_quantity"
foreach y in `ylist'{
	if "`y'"=="value"{
		local panel = "A)"
		local title = "ln(Value)"
	}
	
	if "`y'"=="quantity"{
		local panel = "B)"
		local title = "ln(Total Quantity)"
	}
	
	if "`y'"=="company_num"{
		local panel = "C)"
		local title = "ln(Number of Exporters)"
	}
	
	if "`y'"=="m_quantity"{
		local panel = "D)"
		local title = "ln(Mean Quantity)"
	}
	
	event_plot cs_`y', default_look ///
		stub_lag(Tp#) stub_lead(Tm#) together ///
		graph_opt( ///
			xtitle("Period") ytitle("ATT") ///
			title("`panel' `title'", size(medlarge) position(11)) ///
			xlab(-3(1)4, labsize(small)) ///
			ylab(, angle(90) nogrid labsize(small)) ///
			legend(lab(1 "Coefficient") lab(2 "95% CI") size(*0.8) rows(1) region(lc(black))) ///
			name(cs_`y', replace) ///
		)
}

grc1leg cs_value cs_quantity cs_company_num cs_m_quantity, ///
	legendfrom(cs_value) cols(2) ///
	graphregion(fcolor(white) lcolor(white)) ///
	name(cs_fig, replace)

gr draw cs_fig, ysize(5) xsize(6.5)
graph export "$figdir\CS_DID_Trade_Destruction.pdf", replace



********************************************************************************
**# de Chaisemartin & D'Haultfoeuille (2020, 2022)
* ssc install did_multiplegt, replace

egen clst = group(product year)	// construct a interaction variable for clustering later

local dep = "value quantity company_num m_quantity"
foreach y in `dep'{	
	* Regression
	did_multiplegt ln_`y' year_des_duty year treated, ///
		robust_dynamic dynamic(4) placebo(2) jointtestplacebo ///
		seed(1) breps(100) cluster(clst)
	
	* Visualization
	if "`y'"=="value"{
		local panel = "A)"
		local title = "ln(Value)"
	}
	
	if "`y'"=="quantity"{
		local panel = "B)"
		local title = "ln(Total Quantity)"
	}
	
	if "`y'"=="company_num"{
		local panel = "C)"
		local title = "ln(Number of Exporters)"
	}
	
	if "`y'"=="m_quantity"{
		local panel = "D)"
		local title = "ln(Mean Quantity)"
	}
	
	forvalue i=1/8 {
		local m_`i' = e(estimates)[`i',1]
		local v_`i' = e(variances)[`i',1]
	}

	matrix input matb_DIDl= (`m_1',`m_2',`m_3',`m_4',`m_5',0,`m_7',`m_8')
	mat colnames matb_DIDl= lg0 lg1 lg2 lg3 lg4 ld1 ld2 ld3

	matrix input mats_DIDl= (`v_1',`v_2',`v_3',`v_4',`v_5',0,`v_7',`v_8')
	mat colnames mats_DIDl= lg0 lg1 lg2 lg3 lg4 ld1 ld2 ld3

	event_plot matb_DIDl#mats_DIDl, ///
		stub_lag(lg#) stub_lead(ld#) ///
		ciplottype(rcap) plottype(scatter) ///
		lag_opt(msymbol(D) mcolor(black) msize(small)) ///
		lead_opt(msymbol(D) mcolor(black) msize(small)) ///
		lag_ci_opt(lcolor(black) lwidth(medthin)) ///
		lead_ci_opt(lcolor(black) lwidth(medthin)) ///
		graph_opt( ///
			title("`panel' `title'", size(medlarge) position(11)) ///
			xtitle("Period", height(5)) xsize(5) ysize(4) ///
			ytitle("Average Effect", height(5)) ///
			xline(0, lpattern(dash) lcolor(gs12) lwidth(thin)) ///
			yline(0, lpattern(solid) lcolor(gs12) lwidth(thin)) ///
			xlabel(-3/4, nogrid labsize(small)) ///
			ylabel(, labsize(small)) ///
			legend(order(1 "Coefficient" 2 "95% CI") size(*0.8) position(6) rows(1) region(lc(black))) ///
			name(DIDl_`y', replace) ///
			graphregion(color(white)) ///
		)
}

grc1leg DIDl_value DIDl_quantity DIDl_company_num DIDl_m_quantity, ///
	legendfrom(DIDl_value) cols(2) ///
	graphregion(fcolor(white) lcolor(white)) ///
	name(DIDl_fig, replace)

gr draw DIDl_fig, ysize(5) xsize(6.5)
graph export "$figdir\CD_DIDl_Trade_Destruction.pdf", replace



********************************************************************************
**# Borusyak, Jaravel & Spiess (2022)
* ssc install did_imputation, replace

gen Ei = year_des_duty

local ylist = "value quantity company_num m_quantity"
foreach y in `ylist'{
	quietly{
		eststo imp_`y': did_imputation ln_`y' product year Ei, fe(product year) cluster(clst) horizons(0/4) pretrends(2) minn(0) autosample
	}
}

estout imp*, ///
	coll(none) cells(b(star fmt(3)) se(par fmt(3))) ///
	starlevels(* .1 ** .05 *** .01) legend ///
	stats(N r2_a, nostar labels("Observations" "Adjusted R-Square") fmt("%9.0fc" 3))

* Visualization
local ylist = "value quantity company_num m_quantity"
foreach y in `ylist'{
	if "`y'"=="value"{
		local panel = "A)"
		local title = "ln(Value)"
	}
	
	if "`y'"=="quantity"{
		local panel = "B)"
		local title = "ln(Total Quantity)"
	}
	
	if "`y'"=="company_num"{
		local panel = "C)"
		local title = "ln(Number of Exporters)"
	}
	
	if "`y'"=="m_quantity"{
		local panel = "D)"
		local title = "ln(Mean Quantity)"
	}
	
	event_plot imp_`y', default_look ///
		graph_opt( ///
			xtitle("Period") ytitle("Coefficient estimate") ///
			title("`panel' `title'", size(medlarge) position(11)) ///
			xlab(-2(1)3 4 "> 3", labsize(small)) ///
			ylab(, angle(90) nogrid labsize(small)) ///
			yline(0, lcolor(gs8) lpattern(dash)) ///
			legend(size(*0.8) rows(1) region(lc(black))) ///
			name(imp_`y', replace) ///
		)
}

grc1leg imp_value imp_quantity imp_company_num imp_m_quantity, ///
	legendfrom(imp_value) cols(2) ///
	graphregion(fcolor(white) lcolor(white)) ///
	name(imp_fig, replace)

gr draw imp_fig, ysize(5) xsize(6.5)
graph export "$figdir\Imputation_DID_Trade_Destruction.pdf", replace



********************************************************************************
**# Wooldridge (2021)

xtset product year

local ylist = "value quantity company_num m_quantity"
foreach y in `ylist'{
	if "`y'"=="value"{
		local panel = "A) ln(Value)"
	}
	
	if "`y'"=="quantity"{
		local panel = "B) ln(Total Quantity)"
	}
	
	if "`y'"=="company_num"{
		local panel = "C) ln(Number of Exporters)"
	}
	
	if "`y'"=="m_quantity"{
		local panel = "D) ln(Mean Quantity)"
	}
	
	xthdidregress twfe (ln_`y') (treated), group(product) vce(cluster clst)

	estat aggregation, time ///
		graph( ///
			title("`panel'", position(11)) ///
			xtitle("") ytitle("ATT Estimates") ///
			xlabel(, angle(45) labsize(small)) ylabel(, labsize(small)) ///
			legend(order(1 "Point Estimate" 2 "95% CI") rows(1) position(6) region(lc(black))) ///
			name(etwfe_`y', replace) ///
		)
}

grc1leg etwfe_value etwfe_quantity etwfe_company_num etwfe_m_quantity, ///
	legendfrom(etwfe_value) cols(2) ///
	graphregion(fcolor(white) lcolor(white)) ///
	name(etwfe_fig, replace)

gr draw etwfe_fig, ysize(5) xsize(6.5)
graph export "$figdir\ETWFE_DID_Trade_Destruction.pdf", replace
