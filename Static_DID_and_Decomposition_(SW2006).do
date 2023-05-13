* This do file runs a static DID specification on Stevenson & Wolfers (2006)'s dataset.
* Author: Ian He
* Institution: The University of Oklahoma
* Date: May 12, 2023

clear all

global localdir "D:\research\DID Example"

global figdir   "$localdir\Figure"


*** Static DID ************************************************************
use "http://pped.org/bacon_example.dta", clear

* We see multiple treatment years.
tab year
tab _nfd


**# TWFE DID
* Regression of female suicide on no-fault divorce reforms
eststo reg1: quietly reghdfe asmrs post pcinc asmrh cases, absorb(stfips year) cluster(stfips)

estout reg1, keep(post pcinc asmrh cases _cons) ///
	varlabels(_cons "Constant") ///
	coll(none) cells(b(star fmt(3)) se(par fmt(3))) ///
	starlevels(* .1 ** .05 *** .01) ///
	stats(N r2_a, nostar labels("Observations" "R-Square") fmt("%9.0fc" 3))


**# Bacon Decomposition

* "bacondecomp" command (from the "bacondecomp" package)
bacondecomp asmrs post pcinc asmrh cases, ddetail
graph export "$figdir\DID_Decomposition_bacondecomp.pdf", replace

* "estat bdecomp" command (introduced since Stata 18)
xtdidregress (asmrs pcinc asmrh cases) (post), group(stfips) time(year) vce(cluster stfips)
estat bdecomp, graph
graph export "$figdir\DID_Decomposition_estat.pdf", replace
