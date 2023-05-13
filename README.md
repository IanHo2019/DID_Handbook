# DID Handbook
Comments on better coding or error correction are welcomed. **Contact:** [ianhe2019@ou.edu](mailto:ianhe2019@ou.edu?subject=[GitHub]%20DID%20Handbook).

**Difference in differences** (also written as DID, DiD, or DD, and I prefer using **DID**) is nowadays one of the most popular statistical techniques used in quantitative research in social sciences. The main reason for its popularity is that it's "easy" to understand and apply to empirical research. However, after reading a bunch of high-quality econometrics papers published recently (from 2017 to present), I realize that DID is not as easy as I thought before. The main goal of constructing this repository is to share my improved understanding of DID and my Stata coding for running DID. Note that here I only go over a bit details in each format of DID; please read those papers for greater details.

Before starting, I want to sincerely thank Professor [Corina Mommaerts](https://sites.google.com/site/corinamommaerts/) (UW-Madison), Professor [Christopher Taber](https://www.ssc.wisc.edu/~ctaber/) (UW-Madison), Professor [Bruce Hansen](https://www.ssc.wisc.edu/~bhansen/) (UW-Madison), Professor [Le Wang](https://www.lewangecon.com/) (OU), and Professor [Myongjin Kim](https://sites.google.com/site/mjmyongjinkim/) (OU) for lectures and advice during my exploration for DID. I also thank my PhD colleagues [Mieon Seong](https://www.youtube.com/@user-es5rt7yi1s), [Ningjing Gao](https://github.com/gao0012), and JaeSeok Oh for their persistent support.

## Canonical, Classical, and Textbook DID
Difference in differences, as the name implies, involves comparisons between two groups across two periods. The first difference is between groups and the second difference is always between time. Those units in a group that becomes treated after the treatment time are referred to as the **treated group**. The other units are referred to as the **control group**. DID typically focuses on identifying and estimating the **average treatment effect on the treated (ATT)**; that is, it measures the average effect of the treatment on those who switch from being untreated to being treated. The dominant approach to implementing DID specifications in empirical research is to run **two-way fixed effects (TWFE)** regressions:
$$Y_{it} = \theta_t + \eta_i + \alpha D_{it} + v_{it}$$
where
  * $Y_{it}$ is outcome of interest;
  * $\theta_t$ is a time fixed effect;
  * $\eta_i$ is a unit or individual fixed effect;
  * $D_{it}$ is a 0/1 indicator for whether or not unit $i$ participating in the treatment in time period $t$;
  * $v_{it}$ are idiosyncratic and time-varying unobservables.

Under **treatment effect homogeneity** and under the **parallel trends assumption**, $\alpha$ in the TWFE regression is equal to the causal effect of participating in the treatment. Unfortunately, this TWFE regression is NOT generally robust to treatment effect heterogeneity; this is a popular research topic in current DID literature.

Note that here we only consider the **absorbing treatment**: Once a unit receives a treatment, it cannot get out of the treatment in any future period. Some researchers think that DID can be easily applied to non-absorbing treatment; I don't think so, especially when researchers try to estimate the dynamic effects. 

The TWFE regression can be easily run in Stata by using command `xtdidregress`, `xtreg`, `areg`, or `reghdfe`. To use the `reghdfe` command, we have to install `reghdfe` and `ftools` packages. The basic syntax is below:
```stata
reghdfe Y D, absorb(id t)
```
The `absorb` option is used to specify the fixed effects.

This format of DID involves only two time periods and two groups; that's why I call it canonical, classical, and textbook format. *Canonical* means "standard": this is the original and simplest one showing the key rationale behind the DID; *classical* means "traditional": it has been established for a long time, and sadly it becomes gradually outdated in modern applications; *textbook* means... it has been introduced in many textbooks, such as Jeffrey Wooldrige's *[Econometric Analysis of Cross Section and Panel Data](https://mitpress.mit.edu/9780262232586/econometric-analysis-of-cross-section-and-panel-data/)* (2010) and Bruce Hansen's *[Econometrics](https://press.princeton.edu/books/hardcover/9780691235899/econometrics)* (2022). The TWFE DID can be generalized to multi-period multi-unit cases, only if those treated units get treated in the same period. This kind of treatment is sometimes called **block treatment**.

Before 2017, many researchers naively believed that the TWFE DID could also be easily generalized to cases where units get treated at different periods (i.e., **staggered treatment**). Unfortunately, it is not easy! It is definitely not easy, as described in the following.


## Bacon Decomposition for Static DID
First, what is static DID? **Static DID specifications** estimate a single treatment effect that is time invariant. That is, we only get one beta by running a static DID specification, and we use one coefficient to summarize the treatment effect since the policy is implemented. The classical DID is exactly a static DID.

Second, what is Bacon decomposition? This concept comes from [Goodman-Bacon (2021)](https://doi.org/10.1016/j.jeconom.2021.03.014). The author proposes and proves the **DID decomposition theorem**, stating that the TWFE DID estimator (applied to a case with staggered treatment) equals a weighted average of all possible two-group/two-period DID estimators. For emphasizing this finding, the author writes the DID estimator as $\beta^{2\times2}$.

The DID decomposition theorem is important because it tells us the existence of a "bad" comparison in the classical DID if we include units treated at multiple time periods --- that is, comparing the late treatment group to the early treatment group before and after the late treatment. It is suggested that we should do the Bacon decomposition when running a static DID specification, by which we can see where our estimate comes from. For example, a negative DID estimate shows up possibly just because a negative result from a heavily weighted bad comparison.

To do the Bacon decomposition in Stata, [Andrew Goodman-Bacon](http://goodman-bacon.com/) (Federal Reserve Bank of Minneapolis), [Thomas Goldring](https://tgoldring.github.io/) (Georgia State University), and [Austin Nichols](https://scholar.google.com/citations?hl=en&user=De4kiVMAAAAJ&view_op=list_works&sortby=pubdate) (Amazon) wrote the `bacondecomp` package. The basic syntax is:
```stata
bacondecomp Y D, ddtail
```
`Y` is outcome variable, `D` is treatment dummy, and the `ddtail` option is used for more detailed decomposition. Something sad is that this command can work well only in the cases where we have strongly balanced panel data.

Stata 18 (released on Apr 25, 2023) introduces a new post-estimation command, `estat bdecomp`, for performing a Bacon decomposition. It can be used after the `didregress` or `xtdidregress` command, and a plot can be easily created by adding the `graph` option.


## Synthetic DID for Balanced Panel
[Arkhangelsky et al. (2022)](https://doi.org/10.1257/aer.20190159) propose a method, **synthetic difference in differences (SDID)**, which combines attractive features of both DID and synthetic control (SC) methods.
  * Like DID, SDID allows for a constant difference between treatment and controls over all pretreatment periods.
  * Like SC, SDID reweights and matches pre-exposure trends to relax the conventional "parallel trend" assumption.

The key step in SDID is to find **unit weights** ($\omega_i$) that ensure that the comparison is made between treated units and controls which approximately follow parallel trends prior to the treatments and find **time weights** ($\lambda_t$) that draw higher weights from pre-treatment periods which are more similar to post-treatment periods. By applying these weights to canonical DID (which simply assigns the equal weights to all groups and periods), we can obtain a consistent estimate for the causal effect of treatment. Fortunately, this method can be applied to cases with staggered treatments. Unfortunately, this method cannot be used in case of **unbalanced panel data**, and it does not work to estimate dynamic effects.

SDID can be implemented in Stata by the `sdid` package (written by [Damian Clarke](https://www.damianclarke.net/) at University of Exeter and [Daniel Pailañir](https://daniel-pailanir.github.io/) at Universidad de Chile). The basic syntax is
```stata
sdid depvar groupvar timevar treatment, vce(vcetype)
```
where
  * `depvar` is the dependent variable;
  * `groupvar` is the variable indicating unit, and `timevar` is the variable indicating time periods;
  * `treatment` indicates a unit that is treated at/after a specific time period.
  * `vce(vcetype)` is a required option specifying what methods used for estimating variance. The available inference methods include `bootstrap`, `jackknife`, `placebo`, and `noinference`. If only one unit is treated, then bootstrap and jackknife methods cannot be used. For using placebo method, we need at least one more control unit than treated unit.

Something noteworthy is that we can use the `graph` and `g1on` options to create figures (as Figure 1 in [Arkhangelsky et al., 2022](https://doi.org/10.1257/aer.20190159)) displaying unit weights (in scatter plot), time weights (in area plot), and outcome trends (in line plot).


## Dynamic DID
Often, researchers are not satisfied when only a static effect is estimated; they may also want to see the long-term effects of a policy. For example, once Sibal Yang posts a new problem set on Canvas, what is the effect of the problem set on students’ happiness on each day before the due date? Anyway, the classical dynamic DID specifications allow for changes in the treatment effects over time. An example of the dynamic DID specification is shown below:
$$Y_{it} = \alpha_i + \gamma_t + \sum_{k = -4, \ k \neq -1}^5 \beta_k D_{it}^k + \delta_1 \sum_{k < -4} D_{it}^k + \delta_2 \sum_{k > 5} D_{it}^k + \varepsilon_{it}$$
Within dynamic specifications, researchers need to address the issue of multi-collinearity. The most common way to avoid the multi-collinearity is to exclude the treatment dummy for period -1 (the last period before the treatment) as shown above. Additionally, above I binned distant relative periods, which is also a common action to address the imbalance issues.

In this format of DID, an unbiased estimation becomes much more complicated than the classical DID. A lot of econometricians have tried to solve this problem and they are still trying nowadays. In the following, I only cover several brand new (dynamic) DID estimators with their corresponding commands in Stata. Note that some of the following Stata packages are under development, so it is best to read their recent documentations before applying them to your research.


### Interaction-Weighted Estimator for DID
[Sun & Abraham (2021)](https://doi.org/10.1016/j.jeconom.2020.09.006) propose an interaction-weighted (IW) estimator. Their estimator improves upon the TWFE estimator by estimating an interpretable weighted average of **cohort-specific average treatment effect on the treated (CATT)**. Here, a *cohort* is defined as a group consisting of all units that were first treated at the same time.

One of the authors, [Liyang Sun](https://lsun20.github.io/) at MIT, wrote a Stata package `eventstudyinteract` for implementing their IW estimator and constructing confidence interval for the estimation. To use the `eventstudyinteract` command, we have to install one more package: `avar`. The basic syntax is below:
```stata
eventstudyinteract y rel_time_list, \\\
	absorb(id t) cohort(variable) control_cohort(variable) vce(vcetype)
```
Note that we must include a list of relative time indicators as we would have included in the classical dynamic DID regression.

Something sad is that this command is not well compatible with the `estout` package; therefore, to report the results in a figure/table, we may have to first store the results in a matrix and then deal with the matrix. See my coding example [here](./Dynamic_DID_(SA_2021).do).


### Doubly Robust Estimator for DID
[Callaway & Sant'Anna (2021)](https://doi.org/10.1016/j.jeconom.2020.12.001) pay a particular attention to the disaggregated causal parameter --- the average treatment effect for group $g$ at time $t$, where a "group" is defined by the time period when units are first treated. They name this parameter as "**group-time average treatment effect**", denoted by $ATT(g,t)$, and propose three different types of DID estimators to estimate it:
  * outcome regression (OR);
  * inverse probability weighting (IPW);
  * doubly robust (DR).

For estimation, Callaway and Sant'Anna suggest we use the DR approach, because this approach only requires us to correctly specify either (but not necessarily both) the outcome evolution for the comparison group or the propensity score model.

The two authors, with [Fernando Rios-Avila](https://www.levyinstitute.org/scholars/fernando-rios-avila) at Levy Economics Institute of Bard College, wrote a Stata package `csdid` to implement the DID estimator proposed in [Callaway & Sant'Anna (2021)](https://doi.org/10.1016/j.jeconom.2020.12.001). Internally, all $2 \times 2$ DID estimates are obtained using the `drdid` command; therefore, to run the `csdid`, we have to install two packages: `csdid` and `drdid`.

The basic syntax is below:
```stata
csdid Y covar, ivar(id) time(t) gvar(group)
```
For running the specification, we need the `gvar` variable which equals the first treatment time for the treated, and 0 for the not treated. Note that this command allows us to include covariates into the regression; in some cases the parallel trends assumption holds potentially only after conditioning on observed covariates.

The command has several built-in methods to estimate the coefficient(s); the default is `dripw`, i.e., the doubly robust DID estimator based on stabilized inverse probability weighting and ordinary least squares, from [Sant'Anna & Zhao (2020)](https://doi.org/10.1016/j.jeconom.2020.06.003). One can use the `method( )` option to change it to other available methods. In addition, by default, robust and asymptotic standard errors are estimated. However, other options are available, such as using a multiplicative wild bootstrap procedure by the `wboot` option. Enter `help csdid` in your Stata command window for learning more details.

[Callaway & Sant'Anna (2021)](https://doi.org/10.1016/j.jeconom.2020.12.001) also provide some aggregation schemes to form more aggregated causal parameters. In Stata, we can produce the aggregated estimates by using the post-estimation `estat` or `csdid_estat` command. The second one is recommended if one uses a bootstrap procedure to estimate the standard errors.


### Imputation Estimator for DID
[Borusyak, Jaravel & Spiess (2022, working paper)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4121430) propose a finite-sample efficient robust DID estimator using an imputation procedure. The imputation-based method is welcomed because
  1. it is computationally efficient (it only requires estimating a simple TWFE model);
  1. the imputation easily links the parallel trends and no anticipation assumptions to the estimator.

One of the authors, [Kirill Borusyak](https://sites.google.com/view/borusyak/home) at University College London (UCL), wrote a Stata package `did_imputation` for implementing their imputation approach to estimate the dynamic treatment effects and do pre-trend testing in event studies. The basic syntax is below:
```stata
did_imputation Y id t Ei, fe(id t) horizons(#) pretrends(#)
```
The `horizons` option tells Stata how many forward horizons of treatment effects we want to estimate, and the `pretrends` option tells Stata to perform a pre-trend testing for some periods. The post-treatment coefficients are reported as `tau0`, `tau1`, ...; the pre-trend coefficients are reported as `pre1`, `pre2`, .... In contrast with the aforementioned approaches, here the number of pre-trend coefficients does not affect the post-treatment effect estimates, which are always computed under the assumption of parallel trends and no anticipation.

Furthermore, [Borusyak, Jaravel & Spiess (2022)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4121430) is one of the wonderful papers that points out the infamous "**negative weighting**" problem in the classical DID. This problem arises because the OLS estimation imposes a very strong restriction on treatment effect homogeneity. This is why the classical dynamic DID is called a contaminated estimator by some econometricians.

### To be continued...
Potential candidate: [de Chaisemartin & D'Haultfœuille (2020)](https://www.jstor.org/stable/26966322) and [Dube et al. (2023)](https://doi.org/10.3386/w31184).


## Examples
In this section, I will show how to use the estimators above in empirical analyses, especially by specific commands/packages in Stata.

### TWFE versus SDID
Here I will use three real-world datasets to show how to run TWFE DID regressions. If available, I will also show the coding for running SDID and then make a comparison.

The data I will use are from three papers:
  * "OW05_prop99.dta" is from Orzechowski & Walker (2005), and you can get the recent version from [here](https://chronicdata.cdc.gov/Policy/The-Tax-Burden-on-Tobacco-1970-2019/7nwe-3aj9). [Abadie et al. (2010)](https://doi.org/10.1198/jasa.2009.ap08746) and [Arkhangelsky et al. (2021)](https://doi.org/10.1257/aer.20190159) use the data to estimate the impact of Proposition 99 (increasing taxes on cigarettes) on sales of cigarettes in packs per capita in California. Note that this is a block treatment case.
  * "BCGV22_gender_quota.dta" is from [Bhalotra et al. (2022)](https://doi.org/10.1162/rest_a_01031). They use the data to estimate the impact of parliamentary gender quotas (reserving seats for women in parliament) on rates of women in parliament. Note that this is a staggered treatment case.
  * "SZ18_state_taxes.dta" is from [Serrato & Zidar (2018)](https://doi.org/10.1016/j.jpubeco.2018.09.006). They use the data to estimate the impact of state corporate tax cut/hike on tax revenue and economic activities. Note that this is a staggered treatment case; however, Serrato & Zidar (2018) use a dynamic standard DID specification (i.e., without solving the problem of negative weighting) so their results may be biased. Also note that unfortunately the `sdid` command cannot run a dynamic specification so we cannot use SDID to update Serrato & Zidar (2018)'s results.

The regression commands I will use include
  * `xtdidregress`, a built-in Stata command for running DID regression on panel data. After using it, we can use `estat` to create a trends plot and do some basic tests.
  * `xtreg`, `areg`, and `reghdfe` are originally written for running fixed effects models, but can also be easily applied to running DID regressions.
  * `sdid`, an external command for running SDID. Through the `method( )` option, we can also use it to run standard DID and synthetic control specifications.
  * `xthdidregress`, a command introduced in Stata 18 for estimating heterogeneous ATT. Note that the `xthdidregress` command allows several kinds of weighting and I choose to use `aipw` (augmented inverse-probability weighting, also called "doubly robust"). Although the Stata 18 documentation does not clarify the author(s) of this command, my guess is that the idea of this command originates from [Callaway & Sant'Anna (2021)](https://doi.org/10.1016/j.jeconom.2020.12.001). Note that after regression, the `estat aggregation` command allows us to aggregate the ATTs within cohort or time, analyze the dynamic effect within a specified time window, and create plots.

The complete coding for running regressions on the three datasets can be found [here](./TWFE_vs_SDID.do).


### Bacon Decomposition as a Diagnostic Tool
The dataset to be used can be loaded into Stata by running the following code:
```stata
use "http://pped.org/bacon_example.dta", clear
```
The panel data contain state-level information (in particular, no-fault divorce onset year and suicide mortality rate) on 49 states (including Washington, D.C. but excluding Alaska and Hawaii) in the US from 1964 to 1996. They are originally used by [Stevenson & Wolfers (2006)](https://www.jstor.org/stable/25098790) to estimate the effect of no-fault (or unilateral) divorce on female suicide rate.

Here, I run a static TWFE DID specification of female suicide (a staggered treatment) on no-fault divorce reforms:
$$y_{st} = \alpha_s + \gamma_t + \beta D_{st} + \Gamma X_{st} + e_{it}$$
where
 * $\alpha_s$ is a state fixed effect;
 * $\gamma_t$ is a year fixed effect;
 * $D_{st}$ is a treatment dummy equaling to 1 if $t$ is greater than or equal to the no-fault divorce onset year and 0 otherwise;
 * $X_{st}$ are state-level control variables.
 * The treatment group consists of the states adopting unilateral divorce laws, while the control group consists of the remaining states.

In Stata, `xtdidregress`, `xtreg`, `areg`, or `reghdfe` can be used to run this regression; I prefer `reghdfe` because it works faster and has more flexible options. The estimated coefficients from all these commands should be identical (standard errors and R-squared are different due to different algorithms).
```stata
xtdidregress (asmrs pcinc asmrh cases) (post), group(stfips) time(year) vce(cluster stfips)
xtreg asmrs post pcinc asmrh cases i.year, fe vce(cluster stfips)
areg asmrs post pcinc asmrh cases i.year, absorb(stfips) vce(cluster stfips)
reghdfe asmrs post pcinc asmrh cases, absorb(stfips year) cluster(stfips)
```
`asmrs` is suicide mortality rate, and `post` is treatment dummy $D_{st}$. All the other variables are control variables. Stata reports a DID coefficient in levels of -2.516 (with standard error of 2.283), which is significantly different from zero at 95% confidence level.

Then we can apply the Bacon decomposition theorem to the TWFE DID model.
```stata
bacondecomp asmrs post pcinc asmrh cases, ddetail
```
It reports that there are 14 timing groups in the dataset, including a never-treated group and an always-treated group. The largest weight is assigned to comparison between always-treated group and timing groups. A scatter plot is [here](./Figure/DID_Decomposition_bacondecomp.pdf).

We can also use the following coding (after `xtdidregress`) to do the decomposition. The scatter plot can be found [here](./Figure/DID_Decomposition_estat.pdf).
```stata
estat bdecomp, graph
```

Complete coding for this example can be found [here](./Static_DID_and_Decomposition_(SW2006).do).


### Dynamic DID with Staggered Treatment
If a firm exports a product at a price lower than the price it normally sells in its domestic market, then we say this firm is dumping the product. This unfair foreign pricing behavior can adversely distort the business and economy in import markets. Considering the adverse effect, the WTO Anti-Dumping Agreement allows the governments to react to foreign dumping by taking some **antidumping (AD)** actions. The most typical AD action is imposing higher import duty on the specific product from the specific exporting country, with the hope of raising the unfairly low price to the normal price and thereby mitigating the injury to importing country.

Here, I will employ a dynamic DID specification to estimate the dynamic effects of USA AD duty impositions on China's exporters in a decade from 2000 to 2009. [Bown & Crowley (2007)](https://doi.org/10.1016/j.jinteco.2006.09.005) call this effect "**trade destruction**" and estimate the static effect by running IV, FE, and GMM models with USA and Japanese data. Slides of literature review on this paper can be found [here](./Appendix/Literature_Review_BC2007.pdf).

The dataset I will use is a product-year-level dataset merged from [Global Antidumping Database](https://www.chadpbown.com/global-antidumping-database/) and China Customs data (thanks to China Data Center at Tsingha University). Then dynamic DID specification I will run is as follows:
$$\ln(Y_{h,t}) = \sum_{i = -2, \ i \neq -1}^3 \beta_i AD_{h,t-i}^{USA} + \gamma_1 \sum_{i<-2} AD_{h,t-i}^{USA} + \gamma_2 \sum_{i>3} AD_{h,t-i}^{USA} + \alpha_h + \alpha_t + \epsilon_{h,t}$$
where
 * $Y_{h,t}$ is the outcome variables (including export value, export quantity, number of exporters, and average export quantity) for product $h$ in year $t$.
 * $AD_{h,t-i}^{USA}$ is treatment dummy, equal to 1 if product $h$ received an AD duty from the USA in year $t-i$.
 * $\alpha_h$ is a product fixed effect and $\alpha_t$ is a year fixed effect.
 * Standard errors are clustered at the product-year level, unless specified otherwise.
 * The treatment group is a set of products from China that received the USA AD duties, while the control group is a set of products from China that underwent the AD investigations but finally did not receive the AD duties. Note that I don't include those never-investigated products into control group. The reason is that AD investigations are *non-random*; the products under investigations always have lower export prices and higher export volumes than those without investigations. If I compare the products receiving AD duties against those without undergoing investigations, then my estimator is very likely to be biased.

Information on the year of an AD duty imposition against a specific product (coded at 6-digit Harmonized System level) is stored in variable `year_des_duty`. I use this variable and `year` to construct a series of relative time dummies:
```stata
gen period_duty = year - year_des_duty

gen Dn3 = (period_duty < -2)
forvalues i = 2(-1)1 {
	gen Dn`i' = (period_duty == -`i')
}

forvalues i = 0(1)3 {
	gen D`i' = (period_duty == `i')
}
gen D4 = (period_duty >= 4) & (period_duty != .)
```

Then, it's time to run regressions! Coding for **classical dynamic DID** is:
```stata
local dep = "value quantity company_num m_quantity"
foreach y in `dep'{
	reghdfe ln_`y' Dn3 Dn2 D0-D4, absorb(product year) vce(cluster product#year)
}
```
Traditionally, researchers use pre-treatment coefficients to test for pretrends: If the pre-treatment coefficients is not significantly different from 0, then they conclude that the parallel trends assumption hold. However, [Sun & Abraham (2021)](https://doi.org/10.1016/j.jeconom.2020.09.006) have proved that this action has a serious shortcoming and need correction.

Coding for **interaction-weighted estimation** of DID is:
```stata
gen first_union = year_des_duty
gen never_union = (first_union == .)

local dep = "value quantity company_num m_quantity"
foreach y in `dep'{	
	eventstudyinteract ln_`y' Dn3 Dn2 D0-D4, \\\
		cohort(first_union) control_cohort(never_union) \\\
		absorb(product year) vce(cluster product#year)
}
```
We need to tell Stata which variable corresponds to the initial treatment timing of each unit. I name it `first_union`. This variable should be set to be missing for never treated units. In addition, we need to give Stata a binary variable that corresponds to the control cohort, which can be never-treated units or last-treated units. Here I use never-treated units as the control cohort, and I construct a variable `never_union` to indicate it.

Something noteworthy is that a package named `event_plot` was written by [Kirill Borusyak](https://sites.google.com/view/borusyak/home) for easily plotting the staggered DID estimates, including post-treatment coefficients and, if available, pre-trend coefficients, along with confidence intervals. I use this command to create a four-panel figure (see [here](./Figure/SA_DID_Trade_Destruction.pdf)) showing the dynamic effects on the four outcome variables. For plotting, I usually customize the plot type, but actually you can save a lot of time by using the default type (by using the `default_look` option) if your requirement for visualization is not as high as mine.

Coding for **doubly robust estimation** of DID is:
```stata
gen gvar = year_des_duty
recode gvar (. = 0)

local dep = "value quantity company_num m_quantity"
foreach y in `dep'{	
	quietly csdid ln_`y', ivar(product) time(year) gvar(gvar) \\\
		method(dripw) wboot(reps(10000)) rseed(1)
	csdid_estat event, window(-3 4) estore(cs_`y') wboot(reps(10000)) rseed(1)
}
```
The `cs_did` command may show a very long output table in Stata results window (due to the combination explosion), so I add the `quietly` command before `csdid`. Besides, as in many applications, I care more about the heterogeneous effects at different points in time but not across different groups (instead of the group-time average treatment effect defined by [Callaway & Sant'Anna, 2021](https://doi.org/10.1016/j.jeconom.2020.12.001)); therefore, I use the `csdid_estat` to produce the aggregated estimates only at periods from -3 to 4. Now the output table in results window is shorter. Also note that I use the `wboot` option to estimate wild bootstrap standard errors, with 10,000 repetitions.

As before, I use the `event_plot` command to create a four-panel figure (see [here](./Figure/CS_DID_Trade_Destruction.pdf)) showing the dynamic effects. This time, I use the `default_look` option to save my time; in addition, I use the `together` option to make the leads and lags shown as one continuous curve.

Coding for **imputation estimation** of DID is:
```stata
gen id = product
egen clst = group(product year)
gen Ei = year_des_duty

local ylist = "value quantity company_num m_quantity"
foreach y in `ylist'{
	did_imputation ln_`y' id year Ei, \\\
		fe(product year) cluster(clst) horizons(0/4) pretrends(2) minn(0) autosample
}
```
We need to give Stata a variable for unit-specific date of treatment, whose missing value represents the never-treated unit. I name it `Ei`, following the package documentation.

A four-panel figure presenting the dynamic effects estimated by the imputation approach can be found [here](./Figure/Imputation_DID_Trade_Destruction.pdf). This time, I use the `default_look` option but don't use the `together` option --- this is why the leads and lags are shown as two separate curves in different colors.

To summarize, regardless of estimation approaches, the results show persistent and negative effects of USA antidumping duty impositions on the four outcome variables. Complete coding for this example can be found [here](./Dynamic_DID_(Sino-US_Trade).do).
