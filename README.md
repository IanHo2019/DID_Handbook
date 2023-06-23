# DID Handbook
Comments on better coding or error correction are welcomed. **Contact:** [ianho0815@outlook.com](mailto:ianho0815@outlook.com?subject=[GitHub]%20DID%20Handbook).

**Difference in differences** (also written as DID, DiD, or DD, and I prefer using **DID**) is nowadays one of the most popular statistical techniques used in quantitative research in social sciences. The main reason for its popularity is that it's "easy" to understand and apply to empirical research. However, after reading a bunch of high-quality econometrics papers published recently (from 2017 to present), I realize that DID is not as easy as I thought before. The main goal of constructing this repository is to share my improved understanding of DID and my Stata coding for running DID. Note that here I only go over a bit details in each format of DID; please read those papers for greater details.

Before starting, I want to sincerely thank Professor [Corina Mommaerts](https://sites.google.com/site/corinamommaerts/) (UW-Madison), Professor [Christopher Taber](https://www.ssc.wisc.edu/~ctaber/) (UW-Madison), Professor [Bruce Hansen](https://www.ssc.wisc.edu/~bhansen/) (UW-Madison), Professor [Le Wang](https://www.lewangecon.com/) (OU), and Professor [Myongjin Kim](https://sites.google.com/site/mjmyongjinkim/) (OU) for lectures and advice during my exploration for DID. I also thank my former PhD colleagues [Mieon Seong](https://www.youtube.com/@user-es5rt7yi1s), [Ningjing Gao](https://github.com/gao0012), and [JaeSeok Oh](https://github.com/JaeSeok1218) for their persistent support.

---

## Canonical, Classical, and Textbook DID
Difference in differences, as the name implies, involves comparisons between two groups across two periods. The first difference is between groups and the second difference is always between time. Those units that becomes treated after the treatment time constitute the **treated group**; the other units constitute the **control group**. DID typically focuses on identifying and estimating the **average treatment effect on the treated (ATT)**; that is, it measures the average effect of the treatment on those who switch from being untreated to being treated. The dominant approach to implementing DID approach in empirical research is to run a **two-way fixed effects (TWFE)** regression:
$$Y_{it} = \alpha_i + \gamma_t + \beta D_{it} + \varepsilon_{it}$$
where
  * $Y_{it}$ is outcome of interest;
  * $\alpha_i$ is a unit or individual fixed effect;
  * $\gamma_t$ is a time fixed effect;
  * $D_{it}$ is a 0/1 indicator for whether or not unit $i$ participating in the treatment in time period $t$;
  * $\varepsilon_{it}$ are idiosyncratic and time-varying unobservables.

Under **parallel trends**, **no anticipation**, and **treatment effect homogeneity** assumptions, $\beta$ in the TWFE regression is equal to the causal effect of participating in the treatment. Unfortunately, this TWFE regression is NOT generally robust to treatment effect heterogeneity; this is a popular research topic in the current DID literature.

Note that in this handbook I only consider **absorbing treatment**: Once a unit receives a treatment, it cannot get out of the treatment in any future period. Some researchers are trying to extend DID to non-absorbing treatment (also called "**switching treatment**") design; it is feasible, but under additional assumptions.

The TWFE regression can be easily run in Stata by using command `xtreg`, `areg`, `reghdfe`, or `xtdidregress`. Note that `xtdidregress` is only available in Stata 17 or higher, and `reghdfe` can only be used after we install `reghdfe` and `ftools` packages. I like using `reghdfe` because it has flexible options and computes faster than others. The basic syntax of `reghdfe` is:
```stata
reghdfe Y D, absorb(id t) cluster(id)
```
The `absorb` option specifies the fixed effects, and the `cluster` option specifies at what level the standard errors are clustered.

This format of DID involves only two time periods and two groups; that's why I call it canonical, classical, and textbook format. *Canonical* means "standard": this is the original and simplest one showing the key rationale behind the DID; *classical* means "traditional": it has been established for a long time, and sadly it becomes gradually outdated in modern applications; *textbook* means... it has been introduced in many textbooks, such as Jeffrey Wooldrige's *[Econometric Analysis of Cross Section and Panel Data](https://mitpress.mit.edu/9780262232586/econometric-analysis-of-cross-section-and-panel-data/)* (2010) and Bruce Hansen's *[Econometrics](https://press.princeton.edu/books/hardcover/9780691235899/econometrics)* (2022). The TWFE DID can be generalized to multi-period multi-unit cases, only if those treated units get treated in the same period. This kind of treatment is sometimes called **block treatment**.

Before 2017, many researchers naively believed that the TWFE DID could also be easily generalized to cases where units get treated at different periods (i.e., **staggered treatment**). Unfortunately, it is not easy! It is definitely not easy, as described in the following.

---

## Bacon Decomposition for Static DID
First, what is static DID? **Static DID specifications** estimate a single treatment effect that is time invariant. That is, we only get one beta by running a static DID specification, and we use one coefficient to summarize the treatment effect since the policy is implemented. The classical DID is exactly a static DID.

Second, what is Bacon decomposition? This concept comes from [Goodman-Bacon (2021)](https://doi.org/10.1016/j.jeconom.2021.03.014). The author proposes and proves the **DID decomposition theorem**, stating that the TWFE DID estimator (applied to a case with staggered treatment) equals a weighted average of all possible two-group/two-period DID estimators. For emphasizing this finding, the author writes the DID estimator as $\beta^{2\times2}$.

The DID decomposition theorem is important because it tells us the existence of a "bad" comparison in the classical DID if we include units treated at multiple time periods --- that is, comparing the late treatment group to the early treatment group before and after the late treatment. It is suggested that we should do the Bacon decomposition when running a static DID specification, by which we can see where our estimate comes from. For example, a negative DID estimate shows up possibly just because a negative result from a heavily weighted bad comparison.

To do the Bacon decomposition in Stata, [Andrew Goodman-Bacon](http://goodman-bacon.com/) (Federal Reserve Bank of Minneapolis), [Thomas Goldring](https://tgoldring.github.io/) (Georgia State University), and [Austin Nichols](https://scholar.google.com/citations?hl=en&user=De4kiVMAAAAJ&view_op=list_works&sortby=pubdate) (Amazon) wrote the `bacondecomp` package. The basic syntax is:
```stata
bacondecomp Y D, ddtail
```
`Y` is outcome variable, `D` is treatment dummy, and the `ddtail` option is used for more detailed decomposition.

Stata 18 (released on Apr 25, 2023) introduces a new post-estimation command, `estat bdecomp`, for performing a Bacon decomposition. It can be used after the `didregress` or `xtdidregress` command, and a plot can be easily created by adding the `graph` option.

Something sad is that the Bacon decomposition in Stata can work well with **strongly balanced panel data**.

Actually, Bacon decomposition is not the only method of decomposing the DID estimator; another method was proposed by [de Chaisemar & D'Haultfœuille (2020)](https://www.jstor.org/stable/26966322). The `twowayfeweights` package in Stata, written by Clement de Chaisemartin, Xavier D'Haultfoeuille, and [Antoine Deeb](https://sites.google.com/view/antoinedeeb) (World Bank), allows us to apply the second decomposition method, and fortunately this method can work with unbalanced panel data. However, it is noteworthy that these two decompositions are different in explaining the problem in TWFE DID:
  * [Goodman-Bacon (2021)](https://doi.org/10.1016/j.jeconom.2021.03.014) states that the conventional DID estimator can be expressed as a weighted average of all possible $2 \times 2$ DID estimators, some of which relies on **bad comparisons** as described above.
  * [de Chaisemar & D'Haultfœuille (2020)](https://www.jstor.org/stable/26966322) states that the conventional DID estimator can be expressed as a weighted average of causal effects (ATEs) across group-time cells, some of which are assigned **negative weights** (i.e., problem of negative weighting).

---

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

---

## Dynamic DID
Often, researchers are not satisfied when only a static effect is estimated; they may also want to see the long-term effects of a policy. For example, once [Sibal Yang](https://www.econjobrumors.com/topic/mu-jeung-yang/page/7) posts a new problem set on Canvas, what is the effect of the problem set on students' happiness on each day before the due date? Anyway, the classical dynamic DID specifications allow for changes in the treatment effects over time. An example of the dynamic DID specification is shown below:
$$Y_{it} = \alpha_i + \gamma_t + \sum_{k = -4, \ k \neq -1}^5 \beta_k D_{it}^k + \delta_1 \sum_{k < -4} D_{it}^k + \delta_2 \sum_{k > 5} D_{it}^k + \varepsilon_{it}$$
Within dynamic specifications, researchers need to address the issue of multi-collinearity. The most common way to avoid the multi-collinearity is to exclude the treatment dummy for period -1 (the last period before the treatment) as shown above. Additionally, above I binned distant relative periods, which is also a common action to address the imbalance issues.

In this format of DID, an unbiased estimation becomes much more complicated than the classical DID. A lot of econometricians have tried to solve this problem and they are still trying nowadays. In the following, I only cover several brand new (dynamic) DID estimators with their corresponding commands in Stata. Note that some of the following Stata packages are under development, so it is best to read their recent documentations before applying them to your research.


### Interaction-Weighted Estimator for DID
[Sun & Abraham (2021)](https://doi.org/10.1016/j.jeconom.2020.09.006) formalize the assumptions for identification of coefficients in a static/dynamic TWFE model. Specifically, if treatment effects vary across time (i.e., $\beta_k$ changes with $k$), then the estimator in a static TWFE model will be biased, but the estimator in a dynamic TWFE model is still valid under the homogeneity assumption (i.e., $\beta_k$ doesn't change across treated groups). Sadly, when heterogeneous treatment effects are allowed, estimators in both static and dynamic TWFE models are biased.

In response to the contamination in the TWFE models, [Sun & Abraham (2021)](https://doi.org/10.1016/j.jeconom.2020.09.006) propose an interaction-weighted (IW) estimator. Their estimator improves by estimating an interpretable weighted average of **cohort-specific average treatment effect on the treated (CATT)**. Here, a *cohort* is defined as a group consisting of all units that were first treated at the same time.

One of the authors, [Liyang Sun](https://lsun20.github.io/) (MIT), wrote a Stata package `eventstudyinteract` for implementing their IW estimator and constructing confidence interval for the estimation. To use the `eventstudyinteract` command, we have to install one more package: `avar`. The basic syntax is below:
```stata
eventstudyinteract y rel_time_list, \\\
	absorb(id t) cohort(variable) control_cohort(variable) vce(vcetype)
```
Note that we must include a list of relative time indicators as we would have included in the classical dynamic DID regression.

Something sad is that this command is not well compatible with the `estout` package; therefore, to report the results in a figure/table, we may have to first store the results in a matrix and then deal with the matrix. See my coding example [here](./Dynamic_DID_(SA2021).do).


### Doubly Robust Estimator for DID
[Callaway & Sant'Anna (2021)](https://doi.org/10.1016/j.jeconom.2020.12.001) pay a particular attention to the disaggregated causal parameter --- the average treatment effect for group $g$ at time $t$, where a "group" is defined by the time period when units are first treated. They name this parameter as "**group-time average treatment effect**", denoted by $ATT(g,t)$, and propose three different types of DID estimators to estimate it:
  * outcome regression (OR);
  * inverse probability weighting (IPW);
  * doubly robust (DR).

For estimation, Callaway and Sant'Anna suggest we use the DR approach, because this approach only requires us to correctly specify either (but not necessarily both) the outcome evolution for the comparison group or the propensity score model.

The two authors, with [Fernando Rios-Avila](https://www.levyinstitute.org/scholars/fernando-rios-avila) (Levy Economics Institute of Bard College), wrote a Stata package `csdid` to implement the DID estimator proposed in [Callaway & Sant'Anna (2021)](https://doi.org/10.1016/j.jeconom.2020.12.001). Internally, all $2 \times 2$ DID estimates are obtained using the `drdid` command; therefore, to run the `csdid`, we have to install two packages: `csdid` and `drdid`.

The basic syntax is below:
```stata
csdid Y covar, ivar(id) time(t) gvar(group)
```
For running the specification, we need the `gvar` variable which equals the first treatment time for the treated, and 0 for the not treated. Note that this command allows us to include covariates into the regression; in some cases the parallel trends assumption holds potentially only after conditioning on observed covariates.

The command has several built-in methods to estimate the coefficient(s); the default is `dripw`, i.e., the doubly robust DID estimator based on stabilized inverse probability weighting and ordinary least squares, from [Sant'Anna & Zhao (2020)](https://doi.org/10.1016/j.jeconom.2020.06.003). One can use the `method( )` option to change it to other available methods. In addition, by default, robust and asymptotic standard errors are estimated. However, other options are available, such as using a multiplicative wild bootstrap procedure by the `wboot` option. Enter `help csdid` in your Stata command window for learning more details.

[Callaway & Sant'Anna (2021)](https://doi.org/10.1016/j.jeconom.2020.12.001) also provide some aggregation schemes to form more aggregated causal parameters. In Stata, we can produce the aggregated estimates by using the post-estimation `estat` or `csdid_estat` command. The second one is recommended if one uses a bootstrap procedure to estimate the standard errors.


### Multiple Group-Time Estimator for DID
Since 2020, [Clément de Chaisemartin](https://sites.google.com/site/clementdechaisemartin/) (SciencePo) and [Xavier D'Haultfœuille](https://faculty.crest.fr/xdhaultfoeuille/) (CREST) have written a series of papers to propose different DID estimation techniques. Their major contributions include:
  * Their estimators are valid when the treatment effect is heterogenous over time or across groups.
  * Their estimators allow for treatment switching (i.e., treatment is allowed to be revoked). Of course, additional assumptions are required; [de Chaisemar & D'Haultfœuille (2020)](https://www.jstor.org/stable/26966322) explicitly write out three assumptions about strong exogeneity for $Y(1)$, common trends for $Y(1)$, and existence of stable groups that always get treated in a specific time window.
  * Their estimators consider discounting the treatments occurring later in the panel data. (This could be evidence that Economics and Statistics can be combined well.)
  * They propose several placebo estimators (constructed by mimicking the actual estimators) to test "no anticipation" and "parallel trends" assumptions.

Note that when the not-yet-treated groups are used as controls and there are no control variables in the regression, their estimators are numerically equivalent to the estimators in [Callaway & Sant'Anna (2021)](https://doi.org/10.1016/j.jeconom.2020.12.001), introduced in the previous section. Additionally, note that de Chaisemar and D'Haultfœuille use "staggered" to call a treatment design that is not allowed to be revoked. This is very inconsistent with the literature; we usually call this kind of treatment design "absorbing treatment", and we use "staggered treatment" to call a treatment design where timing of adoption differs across groups.

de Chaisemar and D'Haultfœuille wrote a Stata package `did_multiplegt` for applying their estimators. The basic syntax is:
```stata
did_multiplegt Y G T D
```
where `Y` is the outcome variable, `G` is the group variable, `T` is the time variable, and `D` is the treatment dummy. This command has a lot of options, and here I only introduce several important ones:
  * If the `robust_dynamic` option is specified, the estimator proposed in [de Chaisemartin & D'Haultfoeuille (2022)](https://arxiv.org/abs/2007.04267), $DID_{g,l}$, will be used; otherwise, the estimator in [de Chaisemar & D'Haultfœuille (2020)](https://www.jstor.org/stable/26966322), $DID_M$, will be used. `robust_dynamic` must be specified if we want to estimate dynamic treatment effects. We can use the `dynamic(#)` option to specify the number of dynamic effects to be estimated.
  * When `robust_dynamic` is specified, Stata uses the long-difference placebos proposed in [de Chaisemartin & D'Haultfoeuille (2022)](https://arxiv.org/abs/2007.04267). We can add the `firstdiff_placebo` option to make Stata use the first-difference placebos proposed in [de Chaisemar & D'Haultfœuille (2020)](https://www.jstor.org/stable/26966322). Through the `placebo(#)` option, we can specify the number of placebo estimators to be estimated. The number can be at most equal to the number of time period in our data.
  * The command estimates the standard errors by using bootstrap. We can use the `cluster( )` option to require Stata to use a block bootstrap at a specific level. Interaction cannot be directly used in `cluster( )`, but we can generate a interaction term by using the `group( )` function before running regressions.
  * The `discount(#)` option allows us to discount the treatment effects estimated later in the panel.
  * The command by default produces a graph after each regression. By the `graphoptions( )` option, we can modify the appearance of the graph.

The two authors wrote an information-rich documentation (with a long FAQ part) for their package. You can see it by entering `help did_multiplegt` in the command window.

### Imputation Estimator for DID
[Borusyak, Jaravel & Spiess (2023)](https://arxiv.org/abs/2108.12419) propose a finite-sample efficient robust DID estimator using an imputation procedure. The imputation-based method is welcomed because
  1. it is computationally efficient (it only requires estimating a simple TWFE model);
  1. the imputation easily links the parallel trends and no anticipation assumptions to the estimator.

One of the authors, [Kirill Borusyak](https://sites.google.com/view/borusyak) (University College London), wrote a Stata package `did_imputation` for implementing their imputation approach to estimate the dynamic treatment effects and do pre-trend testing in event studies. The basic syntax is:
```stata
did_imputation Y id t Ei, fe(id t) horizons(#) pretrends(#)
```
The `horizons` option tells Stata how many forward horizons of treatment effects we want to estimate, and the `pretrends` option tells Stata to perform a pre-trend testing for some periods. The post-treatment coefficients are reported as `tau0`, `tau1`, ...; the pre-trend coefficients are reported as `pre1`, `pre2`, .... In contrast with the aforementioned approaches, here the number of pre-trend coefficients does not affect the post-treatment effect estimates, which are always computed under the assumption of parallel trends and no anticipation.

Furthermore, [Borusyak, Jaravel & Spiess (2022)](https://arxiv.org/abs/2108.12419) is one of the fruitful papers that points out the infamous "**negative weighting**" problem in the classical DID. This problem arises because the OLS estimation imposes a very strong restriction on treatment effect homogeneity. This is why the classical dynamic DID is called a contaminated estimator by some econometricians.

### Extended TWFE Estimator for DID
[Wooldridge (2021)](https://dx.doi.org/10.2139/ssrn.3906345) claims that "there is nothing inherently wrong with using TWFE in situations such as staggered interventions". Professor Wooldridge proposed an extended TWFE estimator in DID research design (including block and staggered treatments), based on his finding that the traditional TWFE estimator and a two-way Mundlak (TWM) estimator are equivalent.

What is the **two-way Mundlak regression**? [Wooldridge (2021)](https://dx.doi.org/10.2139/ssrn.3906345) defines it as a regression of $Y_{it}$ on a constant term, $X_{it}$ (independent variable of interest), $\frac{1}{T} \sum_t X_{it}$ (the unit-specific average over time), and $\frac{1}{N} \sum_i X_{it}$ (the cross-sectional average for $t$). By Frisch-Waugh-Lovell theorem (a good introduction is in Sections 3.16 and 3.18 of *[Econometrics](https://press.princeton.edu/books/hardcover/9780691235899/econometrics)*) and some algebraic calculations, we can see the coefficient of $X_{it}$ is the same as the one in the traditional TWFE regression. Moreover, adding time-invariant variables ($Z_i$) and unit-invariant variables ($M_t$) does not change the coefficient of $X_{it}$.

Based on the findings above, [Wooldridge (2021)](https://dx.doi.org/10.2139/ssrn.3906345) finds that an unbiased, consistent, and asymptotic efficient estimator for heterogeneous ATTs in DID can be obtained by
  * running a TWFE regression with an inclusion of interactions between treatment-time cohorts and time; or equivalently
  * running a pooled OLS regression with an inclusion of panel-level averages of covariates.

Amazingly, this estimator allows for heterogenous effects over time, over covariates, or over both. 

For example, the traditional TWFE DID regression is
$$Y_{it} = \beta D_{it} + \alpha_i + \gamma_t + \varepsilon_{it}$$
and [Wooldridge (2021)](https://dx.doi.org/10.2139/ssrn.3906345)'s proposed model is an extended TWFE regression:
$$Y_{it} = \eta + \sum_{g = q}^T \alpha_g G_{ig} + \sum_{s=q}^T \gamma_s F_s + \sum_{g = q}^T \sum_{s=g}^T \beta_{gs} D_{it} G_{ig} F_s + \varepsilon_{it}$$
where $q$ denotes the first period the treatment occurs, $G_{ig}$ is a group dummy, and $F_s$ is a dummy indicating post-treatment period ($F_s = 1$ if $t = s$, where $s \in [q, T]$).

To use this estimation strategy in Stata, Fernando Rios-Avila wrote a package named `jwdid`. The basic syntax is:
```stata
jwdid Y, ivar(id) tvar(time) gvar(cohort)
```
Note that this command, unlike `reghdfe`, does not drop singleton observations automatically, so statistical significance may be biased. What's worse, after using this command, we have to manually aggregate the estimates and then plot figures. Fortunately, Stata 18 introduces a new command: `xthdidregress`. One of its functions is to implement [Wooldridge (2021)](https://dx.doi.org/10.2139/ssrn.3906345)'s extended TWFE estimator. The basic syntax is
```stata
xthdidregress twfe (Y) (tvar), group(gvar)
```
In the post-estimation results, only the ATT estimates (for each cohort) at the treatment time and for the periods thereafter are shown; this is because [Wooldridge (2021)](https://dx.doi.org/10.2139/ssrn.3906345) proves that including time dummies and their related interactions for periods prior to the earliest treatment period doesn't affect the coefficient estimates of interest. Thus, after we use `xthdidregress twfe`, it's impossible to draw a figure that presents dynamic effects over the whole time window of our data.

The extended TWFE estimator has a big advantage: it can be obtained from a very basic regression (pooled OLS) so that most researchers can understand it easily. However, a disadvantage is also obvious: its computation could be very intense because it usually includes many interactions and computes a great number of coefficient estimates. In the `xthdidregress` command, we can use the `hettype( )` option (specifying the type of heterogeneous treatment effects) to alter the default `timecohort` to `time` or `cohort` and then the complexity of computation is reduced.


### To be continued...
Potential candidate: [Dube et al. (2023)](https://doi.org/10.3386/w31184).

---

## Examples
In this section, I will show how to use the estimators above in empirical analyses, especially by specific commands/packages in Stata.

### TWFE versus SDID
Here I will use three real-world datasets to show how to run TWFE DID regressions. If available, I will also show the coding for running SDID and then make a comparison.

The data I will use are from three papers:
  * "OW05_prop99.dta" is from Orzechowski & Walker (2005), and you can get the recent version from [here](https://chronicdata.cdc.gov/Policy/The-Tax-Burden-on-Tobacco-1970-2019/7nwe-3aj9). [Abadie et al. (2010)](https://doi.org/10.1198/jasa.2009.ap08746) and [Arkhangelsky et al. (2021)](https://doi.org/10.1257/aer.20190159) use the data to estimate the impact of Proposition 99 (increasing taxes on cigarettes) on sales of cigarettes in packs per capita in California. Note that this is a block treatment case.
  * "BCGV22_gender_quota.dta" is from [Bhalotra et al. (2022)](https://doi.org/10.1162/rest_a_01031). They use the data to estimate the impact of parliamentary gender quotas (reserving seats for women in parliament) on rates of women in parliament. Note that this is a staggered treatment case.
  * "SZ18_state_taxes.dta" is from [Serrato & Zidar (2018)](https://doi.org/10.1016/j.jpubeco.2018.09.006). They use the data to estimate the impact of state corporate tax cut/hike on tax revenue and economic activities. Note that this is a staggered treatment case; however, Serrato & Zidar (2018) use a dynamic standard DID specification (i.e., without solving the problem of negative weighting) so their results may be biased. Also note that unfortunately the `sdid` command cannot run a dynamic specification so we cannot use SDID to update Serrato & Zidar (2018)'s results.

The regression commands I will use include
  * `xtdidregress`, a built-in command (introduced by Stata 17) for running DID regression on panel data. After using it, we can use `estat` to create a trends plot and do some basic tests (if the treatment variables are not continuous).
  * `xtreg`, `areg`, and `reghdfe` are originally written for running fixed effects models, but can also be easily applied to running DID regressions.
  * `sdid`, an external command for running SDID. Through the `method( )` option, we can also use it to run standard DID and synthetic control specifications.
  * `xthdidregress`, a command introduced in Stata 18 for estimating heterogeneous ATT. Note that the `xthdidregress` command allows several kinds of weighting: The `ra`, `ipw`, and `aipw` estimators are from [Callaway & Sant'Anna (2021)](https://doi.org/10.1016/j.jeconom.2020.12.001) and the `twfe` estimator is from [Wooldridge (2021)](https://dx.doi.org/10.2139/ssrn.3906345). I choose to use `aipw` (augmented inverse-probability weighting, also called "doubly robust"). After regression, the `estat aggregation` command allows us to aggregate the ATTs within cohort or time, analyze the dynamic effect within a specified time window, and create plots.

The complete coding for running regressions on the three datasets can be found [here](./TWFE_vs_SDID.do).


### Bacon Decomposition, Event Study Plots, and Placebo Test
The dataset to be used can be loaded into Stata by running the following code:
```stata
use "http://pped.org/bacon_example.dta", clear
```
The panel data contain state-level information (in particular, no-fault divorce onset year and suicide mortality rate) on 49 states (including Washington, D.C. but excluding Alaska and Hawaii) in the US from 1964 to 1996. They are originally used by [Stevenson & Wolfers (2006)](https://www.jstor.org/stable/25098790) to estimate the effect of no-fault (or unilateral) divorce on female suicide rate.

Here, I first run a static TWFE DID specification of female suicide (a staggered treatment) on no-fault divorce reforms:
$$y_{st} = \alpha_s + \gamma_t + \beta D_{st} + \Gamma X_{st} + e_{st}$$
where
 * $\alpha_s$ is a state fixed effect;
 * $\gamma_t$ is a year fixed effect;
 * $D_{st}$ is a treatment dummy equaling to 1 if $t$ is greater than or equal to the no-fault divorce onset year and 0 otherwise;
 * $X_{st}$ are state-level control variables.
 * The treatment group consists of the states adopting unilateral divorce laws, while the control group consists of the remaining states.

The estimated coefficients from all the following commands should be identical (but standard errors and R-squared are different due to different algorithms).
```stata
xtdidregress (asmrs pcinc asmrh cases) (post), group(stfips) time(year) vce(cluster stfips)
xtreg asmrs post pcinc asmrh cases i.year, fe vce(cluster stfips)
areg asmrs post pcinc asmrh cases i.year, absorb(stfips) vce(cluster stfips)
reghdfe asmrs post pcinc asmrh cases, absorb(stfips year) cluster(stfips)
```
`asmrs` is suicide mortality rate, and `post` is treatment dummy $D_{st}$. All the other variables are control variables. Stata reports a DID coefficient in levels of -2.516 (with a standard error of 2.283), which is insignificantly different from zero.

Then we can apply the Bacon decomposition theorem to the TWFE DID model.
```stata
bacondecomp asmrs post pcinc asmrh cases, ddetail
```
It reports that there are 14 timing groups in the dataset, including a never-treated group and an always-treated group. The largest weight is assigned to comparison between always-treated group and timing groups. A scatter plot is [here](./Figure/DID_Decomposition_bacondecomp.pdf).

We can also use the following coding (after `xtdidregress`) to do the decomposition. The scatter plot can be found [here](./Figure/DID_Decomposition_estat.pdf).
```stata
estat bdecomp, graph
```
Keep in mind that Bacon decomposition works as a diagnostic tool, instead of a remedy. The decomposition tells us the seriousness of the "bad comparison" in our DID specification, but it cannot cure it.

The next regression I run is a corresponding dynamic DID. I use the `eventdd` command because it can run the model and generate a plot at the same time. This command allows for some basic regressions (e.g., `xtreg` and `reghdfe`); for plotting results from advanced DID regressions, I recommend the `event_plot` package (which will be detailed in the next example). To use `eventdd`, two packages, `eventdd` and `matsort`, have to be installed.

Finally, I do a timing placebo test by randomly and repeatedly selecting a placebo treatment time and run TWFE regression for 1000 times. This work is done by using Stata built-in command `permute`. The test result shows that my estimate above may not come from an unobservable time trend. A plot (created by the add-in command `dpplot`) from the placebo test can be seen [here](./Figure/placebo_test_plot.pdf).

Complete coding for this example can be found [here](./DID_Example_(SW2006).do).


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

Coding for **interaction-weighted estimation** in DID is:
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

Coding for **doubly robust estimation** in DID is:
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

Coding for **de Chaisemartin & D'Haultfoeuille's estimation** in DID is:
```stata
egen clst = group(product year)

local ylist = "value quantity m_quantity company_num"
foreach y in `ylist'{
	did_multiplegt ln_`y' year_des_duty year treated, ///
		robust_dynamic dynamic(4) placebo(2) jointtestplacebo ///
		seed(1) breps(100) cluster(clst)
}
```
Here I use the estimator in [de Chaisemartin & D'Haultfoeuille (2022)](https://arxiv.org/abs/2007.04267) because I want to estimate dynamic effects. Something noteworthy is that I use the long-difference placebos to do the placebo test; the dynamic effects are estimated using the long-difference DID estimator, so using long-difference placebos is a correct comparison. By contrast, the first-difference placebo estimators are DIDs across consecutive time periods; if `firstdiff_placebo` is added here, the graph produced to illustrate dynamic treatment effects will be meaningless (i.e., not comparable). A related discussion can be found [here](https://www.statalist.org/forums/forum/general-stata-discussion/general/1599964-graph-for-the-dynamic-treatment-effect-using-did_multiplegt-package).

I personally don't like the graphs produced automatically by `did_multiplegt`, and sadly, the `graphoptions( )` option is not flexible as I expect. Therefore, I choose to withdraw and store the estimates in matrices. Then, the `event_plot` command can be used to create graphs. The process of creating graphs is very similar to what I did in applying [Sun & Abraham (2021)](https://doi.org/10.1016/j.jeconom.2020.09.006)'s estimator. My four-panel figure can be seen [here](./Figure/CD_DIDl_Trade_Destruction.pdf).

Coding for **imputation estimation** in DID is:
```stata
gen Ei = year_des_duty

local ylist = "value quantity m_quantity company_num"
foreach y in `ylist'{
	did_imputation ln_`y' product year Ei, fe(product year) cluster(clst) horizons(0/4) pretrends(2) minn(0) autosample
}
```
We need to give Stata a variable for unit-specific date of treatment, whose missing value represents the never-treated unit. I name it `Ei`, following the package documentation.

A four-panel figure presenting the dynamic effects estimated by the imputation approach can be found [here](./Figure/Imputation_DID_Trade_Destruction.pdf). This time, I use the `default_look` option but don't use the `together` option --- this is why the leads and lags are shown as two separate curves in different colors.

Coding for **extended TWFE estimation** in DID is:
```stata
xtset product year

local ylist = "value quantity m_quantity company_num"
foreach y in `ylist'{
	xthdidregress twfe (ln_`y') (treated), group(product) vce(cluster clst)
}
```
As I said before, here we cannot use `estat aggregation, dynamic` to plot a figure for presenting dynamic effects over all horizons. Therefore, I use `estat aggregation, time` to create four panels (see [here](./Figure/ETWFE_DID_Trade_Destruction.pdf)) showing the treatment effect at each point in time.

To summarize, regardless of estimation approaches, the results show persistent and negative effects of USA antidumping duty impositions on the four outcome variables. Complete coding for this example can be found [here](./Dynamic_DID_(Sino-US_Trade).do).
