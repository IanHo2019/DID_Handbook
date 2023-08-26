* This do file uses Stevenson & Wolfers (2006)'s data to show how to run DID specifications, do DID decomposition, create event study plots for estimates, and take a simple placebo test.
* Author: Ian He
* Date: Aug 26, 2023

clear all

global localdir "D:\research\DID"

global figdir   "$localdir\Figure"
global figdir   "$localdir\Figure"



*** Bacon Decomposition ***************************************************
use "http://pped.org/bacon_example.dta", clear

* We see multiple treatment years.
table year post

* Regression of female suicide on no-fault divorce reforms
eststo reg1: quietly reghdfe asmrs post pcinc asmrh cases, absorb(stfips year) cluster(stfips)

estout reg1, keep(post pcinc asmrh cases _cons) ///
	varlabels(_cons "Constant") ///
	coll(none) cells(b(star fmt(3)) se(par fmt(3))) ///
	starlevels(* .1 ** .05 *** .01) ///
	stats(N r2_a, nostar labels("Observations" "R-Square") fmt("%9.0fc" 3))

* "bacondecomp" command (from the "bacondecomp" package)
bacondecomp asmrs post pcinc asmrh cases, ddetail
graph export "$figdir\DID_Decomposition_bacondecomp.pdf", replace

* "estat bdecomp" command (introduced since Stata 18)
xtdidregress (asmrs pcinc asmrh cases) (post), group(stfips) time(year) vce(cluster stfips)
estat bdecomp, graph
graph export "$figdir\DID_Decomposition_estat.pdf", replace



*** Event Study Plots *****************************************************
gen rel_time = year - _nfd

* install "eventdd" and "matsort"
* The following uses "xtreg".
eventdd asmrs pcinc asmrh cases i.year, ///
	timevar(rel_time) method(fe, cluster(stfips)) ///
	noline graph_op( ///
		xlabel(-20(5)25, nogrid) ///
		xline(0, lpattern(dash) lcolor(gs12) lwidth(thin)) ///
		legend(order(1 "Point Estimate" 2 "95% CI") size(*0.8) position(6) rows(1) region(lc(black))) ///
	)

* The following uses "reghdfe".
eventdd asmrs pcinc asmrh cases, ///
	timevar(rel_time) method(hdfe, cluster(stfips) absorb(stfips year)) ///
	noline graph_op( ///
		xlabel(-20(5)25, nogrid) ///
		xline(0, lpattern(dash) lcolor(gs12) lwidth(thin)) ///
		legend(order(1 "Point Estimate" 2 "95% CI") size(*0.8) position(6) rows(1) region(lc(black))) ///
	)

* Only balanced periods in which all units have data are shown in the plot.
eventdd asmrs pcinc asmrh cases i.year, ///
	timevar(rel_time) method(hdfe, cluster(stfips) absorb(stfips year)) balanced ///
	noline graph_op( ///
		xlabel(, nogrid) ///
		xline(0, lpattern(dash) lcolor(gs12) lwidth(thin)) ///
		legend(order(1 "Point Estimate" 2 "95% CI") size(*0.8) position(6) rows(1) region(lc(black))) ///
	)

* Only specified periods are shown in the plot; periods beyond the window are accumulated.
eventdd asmrs pcinc asmrh cases i.year, ///
	timevar(rel_time) method(hdfe, cluster(stfips) absorb(stfips year)) ///
	accum leads(5) lags(10) ///
	noline graph_op( ///
		xlabel(, nogrid) ///
		xline(0, lpattern(dash) lcolor(gs12) lwidth(thin)) ///
		legend(order(1 "Point Estimate" 2 "95% CI") size(*0.8) position(6) rows(1) region(lc(black))) ///
	)



*** Placebo Test **********************************************************

* Randomly select a placebo treatment time and run TWFE regression for 1000 times
permute post coefficient=_b[post], reps(1000) seed(1) saving("$dtadir\placebo_test.dta", replace): reghdfe asmrs post pcinc asmrh cases, absorb(stfips year) cluster(stfips)

use "$dtadir\placebo_test.dta", clear

* install "dpplot"
dpplot coefficient, ///
	xline(-2.516, lc(red) lp(dash)) xline(0, lc(gs12) lp(solid)) ///
	xtitle("Effect estimate") ytitle("Density of distribution") ///
	xlabel(-3(1)2 -2.516, nogrid labsize(small)) ///
	ylabel(, labsize(small)) caption("")
graph export "$figdir\placebo_test_plot.pdf", replace
