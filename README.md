# DID Handbook
Comments on better coding or error correction are welcomed. **Contact:** [ianhe@ou.edu](mailto:ianhe@ou.edu?subject=[GitHub]%20DID%20Handbook).

**Difference in differences** (also written as DID, DiD, or DD, and I prefer using **DID**) is nowadays one of the most popular statistical techniques used in quantitative research in social sciences. The main reason for its popularity is that it's "easy" to understand and apply to empirical research. However, after reading a bunch of high-quality econometrics paper published recently (from 2017 to present), I realize that DID is not as easy as I thought before. The main goal of constructing this repository is to share my improved understanding of DID and my Stata coding for running DID. Note that here I only go over a bit details in each format of DID; please read those papers for greater details.

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

The TWFE regression can be easily run in Stata by using command `xtreg` or `reghdfe`. To use the latter command, we have to install `reghdfe` and `ftools` packages. The basic syntax is below:
```stata
reghdfe Y D, absorb(id t)
```
The `absorb` option is used to specify the fixed effects.

This format of DID involves only two time periods and two groups; that's why I call it canonical, classic, and textbook format. *Canonical* means "standard": this is the original and simplest one showing the key rationale behind the DID; *classical* means "traditional": it has been established for a long time, and sadly it becomes gradually outdated in modern applications; *textbook* means... it has been introduced in many textbooks, such as Bruce Hansen's *[Econometrics](https://press.princeton.edu/books/hardcover/9780691235899/econometrics)* (2022) and Jeffrey Wooldrige's *[Econometric Analysis of Cross Section and Panel Data](https://mitpress.mit.edu/9780262232586/econometric-analysis-of-cross-section-and-panel-data/)* (2010).

Before 2017, many researchers naively believe that the TWFE DID can be easily generalized to include more time periods and more groups. Unfortunately, it is not easy! It is definitely not easy, as shown in the following.

## Bacon Decomposition for Static DID
First, what is static DID? **Static DID specifications** estimate a single treatment effect that is time invariant. That is, we only get one beta by running a static DID specification, and we use the one beta to summarize the treatment effect on the moment when the policy is implemented. The classical DID is exactly a static DID.

Second, what is Bacon decomposition? This concept comes from [Goodman-Bacon (2021)](https://doi.org/10.1016/j.jeconom.2021.03.014). The author proposes and proves the **DID decomposition theorem**, stating that the TWFE DID estimator equals a weighted average of all possible two-group/two-period DID estimators. For emphasizing this finding, the author writes the DID estimator as $\beta^{2\times2}$.

The DID decomposition theorem is important because it tells us the existence of a "bad" comparison in the classical DID if we include units treated at multiple time periods --- that is, comparing the late treatment group to the early treatment group before and after the late treatment. It is suggested that we should do the Bacon decomposition when running a static DID specification, by which we can see where our estimate comes from. For example, a negative DID estimate shows up possibly just because a negative result from a heavily weighted bad comparison.

To do the Bacon decomposition in Stata, please install the `bacondecomp` package and use the following syntax:
```stata
bacondecomp Y D, ddtail
```
`Y` is outcome variable, `D` is treatment dummy, and the `ddtail` option is used for more detailed decomposition.

## Dynamic DID
Often, researchers are not satisfied when only a static effect is estimated; they may also want to see the long-term effects of a policy. For example, once Sibal Yang posts a new problem set on Canvas, what is the effect of the problem set on students’ happiness on each day before the due date? Anyway, the classical dynamic DID specifications allow for changes in the treatment effects over time. An example of the dynamic DID specification is shown below:
$$Y_{it} = \alpha_i + \gamma_t + \sum_{k \in \{-4, -3, -2, 0, 1, 2, 3, 4, 5\}} \beta_k D_{it}^k + \delta_1 \sum_{k < -4} D_{it}^k + \delta_2 \sum_{k > 5} D_{it}^k + \varepsilon_{it}$$
Within dynamic specifications, researchers need to address the issue of multi-collinearity. The most common way to avoid the multi-collinearity is to exclude the treatment dummy for period -1 (the last period before the treatment) as I did above. Additionally, above I binned distant relative periods, which is also a common action in empirical research.

In this format of DID, an unbiased estimation becomes much more complicated than the classical DID. A lot of econometricians are trying to solve this problem and they are keep trying. In the following, I only cover several brand new (dynamic) DID estimators with their corresponding commands in Stata.

### Interaction-Weighted Estimator for DID
[Sun & Abraham (2021)](https://doi.org/10.1016/j.jeconom.2020.09.006) proposes an interaction-weighted (IW) estimator. Their estimator improves upon the TWFE estimator by estimating an interpretable weighted average of **cohort-specific average treatment effect on the treated (CATT)**. Here, a *cohort* is defined as a group consisting of all units that were first treated at the same time.

One of the authors, [Liyang Sun](https://lsun20.github.io/) at MIT, wrote a Stata package `eventstudyinteract` for implementing their IW estimator and constructing confidence interval for the estimation. To use the `eventstudyinteract` command, we have to install one more package: `avar`. The basic syntax is below:
```stata
eventstudyinteract y rel_time_list, \\\
  absorb(id t) cohort(variable) control_cohort(variable) vce(vcetype)
```
Note that we must include a list of relative time indicators as we would have included in the classical dynamic DID regression.

Something sad is that this command is not well compatible with the `estout` package; I still don't find a good package/command to export the results from the IW DID regression.

### Imputation Estimator for DID
[Borusyak, Jaravel & Spiess (2022, working paper)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4121430) proposes a finite-sample efficient robust DID estimator using an imputation procedure. The imputation-based method is welcomed because
  1. it is computationally efficient (it only requires estimating a simple TWFE model);
  1. the imputation easily links the parallel trends and no anticipation assumptions to the estimator.

One of the authors, [Kirill Borusyak](https://sites.google.com/view/borusyak/home) at University College London (UCL), wrote a Stata package `did_imputation` for implementing their imputation approach to estimate the dynamic treatment effects and do pre-trend testing in event studies. The basic syntax is below:
```stata
did_imputation Y id t Ei, fe(id t) horizons(#) pretrends(#)
```
The `horizons` option tells Stata how many forward horizons of treatment effects we want to estimate, and the `pretrends` option tells Stata to perform a pre-trend testing for some periods. The post-treatment coefficients are reported as `tau0`, `tau1`, ...; the pre-trend coefficients are reported as `pre1`, `pre2`, .... In contrast with the aforementioned approaches, here the number of pre-trend coefficients does not affect the post-treatment effect estimates, which are always computed under the assumption of parallel trends and no anticipation.

Furthermore, [Borusyak, Jaravel & Spiess (2022)](https://papers.ssrn.com/sol3/papers.cfm?abstract_id=4121430) is one of the wonderful papers that points out the infamous "**negative weighting**" problem in the classical DID. This problem arises because the OLS estimation imposes a very strong restriction on treatment effect homogeneity. This is why the classical dynamic DID is called a contaminated estimator by some econometricians.

### To be continued...
Potential candidate: [Callaway & Sant'Anna (2021)](https://doi.org/10.1016/j.jeconom.2020.12.001).

## Examples
In this section, I will show how to use the estimators above in empirical analyses, especially by specific commands/packages in Stata.

### The Impact of No-Fault Divorce Reforms on Female Suicide ([Stevenson & Wolfers, 2006](https://www.jstor.org/stable/25098790))
The dataset can be loaded into Stata by running the following code:
```stata
use "http://pped.org/bacon_example.dta", clear
```
The panel data contain state-level information (in particular, no-fault divorce onset year and suicide mortality rate) on 49 states (including Washington, D.C. but excluding Alaska and Hawaii) in the US from 1964 to 1996. They are originally used by [Stevenson & Wolfers (2006)](https://www.jstor.org/stable/25098790) to estimate the effect of no-fault (or unilateral) divorce on female suicide rate.

Here, I run a static TWFE DID specification of female suicide on no-fault divorce reforms:
$$y_{st} = \alpha_s + \gamma_t + \beta D_{st} + \Gamma X_{st} + e_{it}$$
where
 * $\alpha_s$ is a state fixed effect;
 * $\gamma_t$ is a year fixed effect;
 * $D_{st}$ is a treatment dummy equaling to 1 if $t$ is greater than or equal to the no-fault divorce onset year and 0 otherwise;
 * $X_{st}$ are state-level control variables.
 * The treatment group consists of the states adopting unilateral divorce laws, while the control group consists of the remaining states.

In Stata, either `reghdfe` or `xtreg` command can be used to run this regression; I prefer `reghdfe` because it works faster and has more flexible options. The estimation results from both commands should be identical.
```stata
reghdfe asmrs post pcinc asmrh cases, absorb(stfips year)
xtreg asmrs post pcinc asmrh cases i.year, fe
```
`asmrs` is suicide mortality rate, and `post` is treatment dummy $D_{st}$. All the other variables are control variables. Stata reports a DID coefficient in levels of -2.52 (with standard error of 1.10), which is significantly different from zero at 95% confidence level.

Then we can apply the Bacon decomposition theorem to the TWFE DID model.
```stata
bacondecomp asmrs post pcinc asmrh cases, ddetail
```
It reports that there are 14 timing groups in the dataset, including a never-treated group and an always-treated group. The largest weight is assigned to comparison between always-treated group and timing groups. A scatter plot is [here](./Figure/DID_Decomposition_Detail.pdf).

Complete coding for this example can be found [here](./Static_DID_and_Decomposition_(SW2006).do).

### The Impact of Antidumping Duty on the China's Export to the US
If a firm exports a product at a price lower than the price it normally sells in its domestic market, then we say this firm is dumping the product. This unfair foreign pricing behavior can adversely distort the business and economy in import markets. Considering the adverse effect, the WTO Anti-Dumping Agreement allows the governments to react to foreign dumping by taking some **antidumping (AD)** actions. The most typical AD action is imposing higher import duty on the specific product from the specific exporting country, with the hope of raising the unfairly low price to the normal price and thereby mitigating the injury to importing country.

Here, I will employ a dynamic DID specification to estimate the dynamic effects of USA AD duty impositions on China's exporters in a decade from 2000 to 2009. [Bown & Crowley (2007)](https://doi.org/10.1016/j.jinteco.2006.09.005) call this effect "**trade destruction**" and estimate the static effect by running IV, FE, and GMM models with USA and Japanese data. Slides of literature review on this paper can be found [here](./Appendix/Literature_Review_BC2007.pdf).

The dataset I will use is a product-year-level dataset merged from [Global Antidumping Database](https://www.chadpbown.com/global-antidumping-database/) and China Customs data (thanks to China Data Center at Tsingha University). Then dynamic DID specification I will run is as follows:
$$\ln(Y_{h,t}) = \sum_{i=-2}^{3} \beta_i AD_{h,t+i}^{USA} + \gamma_1 \sum_{i<-2} AD_{h,t+i}^{USA} + \gamma_2 \sum_{i>3} AD_{h,t+i}^{USA} + \alpha_h + \alpha_t + \epsilon_{h,t}$$
where
 * $Y_{h,t}$ is the outcome variables (including export value, export quantity, number of exporters, and average export quantity) for product $h$ in year $t$.
 * $AD_{h,t+i}^{USA}$ is treatment dummy, equal to 1 if product $h$ received an AD duty from the USA in year $t+i$.
 * $\alpha_h$ is a product fixed effect and $\alpha_t$ is a year fixed effect.
 * Standard errors are clustered at the product-year level.
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
	eventstudyinteract ln_`y' Dn3 Dn2 D0-D4, cohort(first_union) control_cohort(never_union) absorb(product year) vce(cluster product#year)
}
```
We need to tell Stata which variable corresponds to the initial treatment timing of each unit. I name it `first_union`. This variable should be set to be missing for never treated units. In addition, we need to give Stata a binary variable that corresponds to the control cohort, which can be never-treated units or last-treated units. Here I use never-treated units as the control cohort, and I construct a variable `never_union` to indicate it.

Coding for imputation estimation of DID is:
```stata
gen id = product
egen clst = group(product year)
gen Ei = year_des_duty

local ylist = "value quantity company_num m_quantity"
foreach y in `ylist'{
	did_imputation ln_`y' id year Ei, fe(product year) cluster(clst) horizons(0/4) pretrends(2) minn(0) autosample
}
```
We need to give Stata a variable for unit-specific date of treatment, whose missing value represents the never-treated unit. I name it `Ei`, following the package documentation.

Something noteworthy is that a package named `event_plot` was written for easily plotting the staggered DID estimates, including post-treatment coefficients and, if available, pre-trend coefficients, along with confidence intervals. I use this command to create a four-panel figure (see [here](./Figure/Imputation_DID_Trade_Destruction.pdf)) showing the dynamic estimated effects on four outcome variables. Regardless of estimation approaches, my results show persistent and negative effects on all outcome variables.

Complete coding for this example can be found [here](./Dynamic_DID_(Sino-US_Trade).do).
