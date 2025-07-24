********************************************************************************
************************************* DAILY ************************************
********************************************************************************

{

*********************************** CLEANING ***********************************

* Import the working database.
clear


*===============================================================================
* Complete with the file path to the daily data set.
*===============================================================================
import excel "",firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Rename the date variable for consistency with the code.
format date %tdDD/NN/CCYY
rename date Date

* Declare data to be time-series.
tsset Date, daily

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable Day_1 "Sunday"
label variable Day_2 "Monday"
label variable Day_3 "Tuesday"
label variable Day_4 "Wednesday"
label variable Day_5 "Thursday"
label variable Day_6 "Friday"
label variable Day_7 "Saturday"

label variable TimeTrend "Linear Time Trend"

label variable heating "Heating Consumption"
label variable baseload "Baseload Consumption"

* Initialize grouping variables that will be needed for the regressions to distinguish between the two different subsamples.
gen byte sample_pre_crisis = Date < td("01/12/2021")
gen byte sample_crisis = Date >= td("01/12/2021")




************************* REGRESSION: TOTAL CONSUMPTION ************************

* Model for Total Consumption, pre-crisis sample.
* ARDL.
* ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) maxlags(20) maxcombs(1000000)

ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(15 8 1 1)
eststo model0

* ECM.
ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
eststo model1

estat ectest



* Model for Total Consumption, crisis sample.
* ARDL.
* ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) maxlags(20) maxcombs(1000000)

ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 1 0)
eststo model2

* ECM.
ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)
eststo model3

estat ectest



* Export regression tables.
esttab model0 model2 using "ARDL_RDS_DAILY.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis Sample" "Crisis Sample") collabels(none) drop(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) varlabels(RDS "Demand" HDD "Heating‐Degree Days" SNSR "Solar Radiation" price_l3m "Lagged Price Index" _cons "Constant" date "Time Trend") compress sfmt(3 0) postfoot("\midrule" "Daily Seasonal Dummies & Yes & Yes \\" "Monthly Seasonal Dummies & Yes & Yes \\")

esttab model1 model3 using "EMC_RDS_DAILY.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis Sample" "Crisis Sample") collabels(none) drop(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) compress sfmt(3 0) postfoot("\midrule" "Daily Seasonal Dummies & Yes & Yes &\\" "Monthly Seasonal Dummies & Yes & Yes \\")


esttab model1 model3 using "EMC_RDS_TABLE.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis ECM" "Crisis ECM") collabels(none) keep(HDD L.RDS SNSR price_l3m) compress sfmt(3 0) varlabels(L.RDS "Demand" HDD "Heating‐Degree Days" SNSR "Solar Radiation" price_l3m "Lagged Price Index")



************************** TESTS: CRISIS vs PRE-CRISIS *************************

* Test whether the price coefficient estimated on the crisis subsample is different from the one estimated on the pre-crisis subsample: Wald test.
* 1) Generate the Δ terms.
gen dRDS = D.RDS
gen dHDD = D.HDD
gen dSNSR = D.SNSR
gen dprice = D.price_l3m

* 2) Estimate the full Unrestricted Error Model in the two subsamples. Store estimates.
qui reg dRDS L.RDS HDD SNSR price_l3m L(1/14).dRDS L(0/7).dHDD dSNSR dprice Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_pre_crisis
estimates store pre

qui reg dRDS L.RDS HDD SNSR price_l3m L(1/8).dRDS L(0/7).dHDD dSNSR Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_crisis
estimates store crisis

* Combine the estimates and test the two long-term coefficients as non-linear transformations of estimated parameters. 
suest pre crisis
testnl ([pre_mean]price_l3m/[pre_mean]L.RDS) = ([crisis_mean]price_l3m/[crisis_mean]L.RDS)



* Test whether the HDD coefficient estimated on the crisis subsample is different from the one estimated on pre-crisis subsample: Wald test.
* Estimate the full Unrestricted Error Model in the two subsamples. Store estimates.
qui reg dRDS L.RDS HDD SNSR price_l3m L(1/14).dRDS L(0/7).dHDD dSNSR dprice Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_pre_crisis
estimates store pre

qui reg dRDS L.RDS HDD SNSR price_l3m L(1/8).dRDS L(0/7).dHDD dSNSR Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_crisis
estimates store crisis

* Combine the estimates and test the two long-term coefficients as non-linear transformations of estimated parameters. 
qui suest pre crisis
testnl ([pre_mean]HDD/[pre_mean]L.RDS) = ([crisis_mean]HDD/[crisis_mean]L.RDS)



* Test whether the SNSR coefficient estimated on the crisis subsample is different from the one estimated on pre-crisis subsample: Wald test.
* Estimate the full Unrestricted Error Model in the two subsamples. Store estimates.
qui reg dRDS L.RDS HDD SNSR price_l3m L(1/14).dRDS L(0/7).dHDD dSNSR dprice Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_pre_crisis
estimates store pre

qui reg dRDS L.RDS HDD SNSR price_l3m L(1/8).dRDS L(0/7).dHDD dSNSR Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_crisis
estimates store crisis

* Combine the estimates and test the two long-term coefficients as non-linear transformations of estimated parameters. 
qui suest pre crisis
testnl ([pre_mean]SNSR/[pre_mean]L.RDS) = ([crisis_mean]SNSR/[crisis_mean]L.RDS)



* Test whether the ECT coefficient estimated on the crisis subsample is different from the one estimated on pre-crisis subsample: Wald test.
* Estimate the full Unrestricted Error Model in the two subsamples. Store estimates.
qui reg dRDS L.RDS HDD SNSR price_l3m L(1/14).dRDS L(0/7).dHDD dSNSR dprice Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_pre_crisis
estimates store pre

qui reg dRDS L.RDS HDD SNSR price_l3m L(1/8).dRDS L(0/7).dHDD dSNSR Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_crisis
estimates store crisis

* Combine the estimates and test the two long-term coefficients. 
suest pre crisis
test [pre_mean]L.RDS = [crisis_mean]L.RDS




************************* ELASTICITIES, SPLIT SAMPLES **************************

* Average yearly elasticities WITH 95% CIs.
preserve

* Create a variable to track years.
generate int year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t = .
gen upper_eta = . 
gen lower_eta = .

* Generate an ID for the loops.
gen ID = _n

* Compute yearly averages of consumption and price.
bysort year: egen mean_RDS = mean(RDS)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3623(1)4808 {
	
	qui ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_RDS_t = mean_RDS[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_RDS_t)]
	
	qui replace eta_t = r(estimate) if ID == `i'

	qui replace upper_eta = r(ub) if ID == `i'

	qui replace lower_eta = r(lb) if ID == `i'
		
}

drop ID

replace eta_t = 0 if missing(eta_t)
replace upper_eta = 0 if missing(upper_eta)
replace lower_eta = 0 if missing(lower_eta)

collapse (mean) eta_t upper_eta lower_eta, by(year)

tsset year, yearly 

keep if year < 2025

twoway (tsline eta_t) (rcap lower_eta upper_eta year, lcolor(black)), xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) label(1 "Average Yearly Elasticity") label(2 "95% CI")) ytick(0(0.1)0.5) ylabel(0(0.1)0.5) xtitle("Date")
graph export RDS_Yearly_Elasticity_95_CI.png, as(png) replace 

restore




************************************ Q TILDE ***********************************

qui ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 1 0)

matrix coefficients = e(b)

gen b_RDS_L1 = coefficients[1,1]
gen b_RDS_L2 = coefficients[1,2]
gen b_RDS_L3 = coefficients[1,3]
gen b_RDS_L4 = coefficients[1,4]
gen b_RDS_L5 = coefficients[1,5]
gen b_RDS_L6 = coefficients[1,6]
gen b_RDS_L7 = coefficients[1,7]
gen b_RDS_L8 = coefficients[1,8]
gen b_RDS_L9 = coefficients[1,9]
gen b_HDD = coefficients[1,10]
gen b_HDD_L1 = coefficients[1,11]
gen b_HDD_L2 = coefficients[1,12]
gen b_HDD_L3 = coefficients[1,13]
gen b_HDD_L4 = coefficients[1,14]
gen b_HDD_L5 = coefficients[1,15]
gen b_HDD_L6 = coefficients[1,16]
gen b_HDD_L7 = coefficients[1,17]
gen b_HDD_L8 = coefficients[1,18]
gen b_SNSR = coefficients[1,19]
gen b_SNSR_L1 = coefficients[1,20]
gen b_Month_2 = coefficients[1,22]
gen b_Month_3 = coefficients[1,23]
gen b_Month_4 = coefficients[1,24]
gen b_Month_5 = coefficients[1,25]
gen b_Month_6 = coefficients[1,26]
gen b_Month_7 = coefficients[1,27]
gen b_Month_8 = coefficients[1,28]
gen b_Month_9 = coefficients[1,29]
gen b_Month_10 = coefficients[1,30]
gen b_Month_11 = coefficients[1,31]
gen b_Month_12 = coefficients[1,32]
gen b_Day_2 = coefficients[1,33]
gen b_Day_3 = coefficients[1,34]
gen b_Day_4 = coefficients[1,35]
gen b_Day_5 = coefficients[1,36]
gen b_Day_6 = coefficients[1,37]
gen b_Day_7 = coefficients[1,38]
gen b_TimeTrend = coefficients[1,39]

gen Q_tilde = max(RDS - (b_RDS_L1 * L1.RDS + b_RDS_L2 * L2.RDS + b_RDS_L3 * L3.RDS + b_RDS_L4 * L4.RDS + b_RDS_L5 * L5.RDS + ///
						b_RDS_L6 * L6.RDS + b_RDS_L7 * L7.RDS + b_RDS_L8 * L8.RDS + b_RDS_L9 * L9.RDS + ///
					    b_HDD * HDD + b_HDD_L1 * L1.HDD + b_HDD_L2 * L2.HDD + b_HDD_L3 * L3.HDD + b_HDD_L4 * L4.HDD + ///
					    b_HDD_L5 * L5.HDD + b_HDD_L6 * L6.HDD + b_HDD_L7 * L7.HDD + b_HDD_L8 * L8.HDD + ///
					    b_SNSR * SNSR + b_SNSR_L1 * L1.SNSR + ///
					    b_Month_2 * Month_2 + b_Month_3 * Month_3 + b_Month_4 * Month_4 + b_Month_5 * Month_5 + b_Month_6 * Month_6 + ///
					    b_Month_7 * Month_7 + b_Month_8 * Month_8 + b_Month_9 * Month_9 + b_Month_10 * Month_10 + b_Month_11 * Month_11 + ///
					    b_Month_12 * Month_12 + b_Day_2 * Day_2 + b_Day_3 * Day_3 + b_Day_4 * Day_4 + b_Day_5 * Day_5 + b_Day_6 * Day_6 + ///
					    b_Day_7 * Day_7 + b_TimeTrend * TimeTrend), 0)

drop b_RDS_L1 b_RDS_L2 b_RDS_L3 b_RDS_L4 b_RDS_L5 b_RDS_L6 b_RDS_L7 b_RDS_L8 b_RDS_L9 b_HDD b_HDD_L1 b_HDD_L2 b_HDD_L3 b_HDD_L4 b_HDD_L5 b_HDD_L6 b_HDD_L7 b_HDD_L8 b_SNSR b_SNSR_L1 b_Month_2 b_Month_3 b_Month_4 b_Month_5 b_Month_6 b_Month_7 b_Month_8 b_Month_9 b_Month_10 b_Month_11 b_Month_12 b_Day_2 b_Day_3 b_Day_4 b_Day_5 b_Day_6 b_Day_7 b_TimeTrend

replace Q_tilde = 0 if Date < td("01/12/2021")



preserve

gen int mdate = mofd(Date)

format mdate %tm

collapse (sum) Q_tilde, by(mdate)

keep if mdate > tm(2012m1)

tsset mdate, monthly

tsline Q_tilde, ttick(2012m1 2014m1 2016m1 2018m1 2020m1 2022m1 2024m1) tlabel(2012m1 "Jan 2012" 2014m1 "Jan 2014" 2016m1 "Jan 2016" 2018m1 "Jan 2018" 2020m1 "Jan 2020"  2022m1 "Jan 2022" 2024m1 "Jan 2024" ) xtitle("Date") ytitle("")
graph export Q_tilde.jpg, as(jpg) replace 

restore



* Compute and graph the average yearly elasticity with 95% CIs.
preserve

generate int year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t_Q_tilde = .
gen upper_eta_Q_tilde = . 
gen lower_eta_Q_tilde = .

* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_Q_tilde = mean(Q_tilde)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3623(1)4808 {
	
	qui ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_Q_tilde_t = mean_Q_tilde[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_Q_tilde_t)]
	
	qui replace eta_t_Q_tilde = r(estimate) if ID == `i'

	qui replace upper_eta_Q_tilde = r(ub) if ID == `i'

	qui replace lower_eta_Q_tilde = r(lb) if ID == `i'
		
}

drop ID

replace eta_t_Q_tilde = 0 if missing(eta_t_Q_tilde)
replace upper_eta_Q_tilde = 0 if missing(upper_eta_Q_tilde)
replace lower_eta_Q_tilde = 0 if missing(lower_eta_Q_tilde)

collapse (mean) eta_t_Q_tilde lower_eta_Q_tilde upper_eta_Q_tilde, by(year)

tsset year, yearly 

keep if year < 2025

twoway (tsline eta_t_Q_tilde) (rcap lower_eta_Q_tilde upper_eta_Q_tilde year, lcolor(black)), xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) label(1 "Average Yearly Elasticity") label(2 "95% CI")) ytick(0(0.5)2.1) ylabel(0(0.5)2.1)
graph export Q_tilde_Yearly_Elasticity_95_CI.jpg, as(jpg) replace 

restore




************************ REGRESSION: HEATING & BASELOAD ************************


* Model for Heating Consumption, PRE-CRISIS SAMPLE.
ardl heating HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(15 8 8 1)
eststo model0

ardl heating HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 8 1)
eststo model1

estat ectest

* Model for Heating Consumption, CRISIS SAMPLE.
ardl heating HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 0 0)
eststo model2

ardl heating HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0 0)
eststo model3

estat ectest



* Model for Baseload Consumption, PRE-CRISIS SAMPLE.
ardl baseload HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(19 0 0 0) 
eststo model4

ardl baseload HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(19 0 0 0)
eststo model5

estat ectest

* Model for Baseload Consumption, CRISIS SAMPLE.
ardl baseload HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(12 0 0 0) 
eststo model6

ardl baseload HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(12 0 0 0)
eststo model7

estat ectest


esttab model0 model2 using "ARDL_Heat_DAILY.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis Sample" "Crisis Sample") collabels(none) drop(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) varlabels(HDD "Heating‐Degree Days" SNSR "Solar Radiation" price_l3m "Lagged Price Index" _cons "Constant" date "Time Trend") compress sfmt(3 0) postfoot("\midrule" "Daily Seasonal Dummies & Yes & Yes \\ \\" "Monthly Seasonal Dummies & Yes & Yes\\")

esttab model4 model6 using "ARDL_Base_DAILY.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis Sample" "Crisis Sample") collabels(none) drop(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) varlabels(HDD "Heating‐Degree Days" SNSR "Solar Radiation" price_l3m "Lagged Price Index" _cons "Constant" date "Time Trend") compress sfmt(3 0) postfoot("\midrule" "Daily Seasonal Dummies & Yes & Yes \\ \\" "Monthly Seasonal Dummies & Yes & Yes\\")


esttab model1 model3 using "ECM_Heating.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis Sample" "Crisis Sample") collabels(none) drop(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) compress sfmt(3 0) postfoot("\midrule" "Daily Seasonal Dummies & Yes \\" "Monthly Seasonal Dummies & Yes\\")

esttab model5 model7 using "ECM_Baseload.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Baseload") collabels(none) drop(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) compress sfmt(3 0) postfoot("\midrule" "Daily Seasonal Dummies & Yes & Yes \\ \\" "Monthly Seasonal Dummies & Yes & Yes\\")


esttab model1 model3 using "ECM_Heating_TABLE.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis" "Crisis") collabels(none) keep(HDD L.heating SNSR price_l3m) compress sfmt(3 0) varlabels(L.heating "Heating Demand" HDD "Heating‐Degree Days" SNSR "Solar Radiation" price_l3m "Lagged Price Index")

esttab model5 model7 using "ECM_Baseload_TABLE.tex", replace b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars(r2) label mtitle("Pre-Crisis" "Crisis") collabels(none) keep(HDD L.baseload SNSR price_l3m) compress sfmt(3 0) varlabels(L.baseload "Baseload Demand" HDD "Heating‐Degree Days" SNSR "Solar Radiation" price_l3m "Lagged Price Index")




************************** TESTS: CRISIS vs PRE-CRISIS *************************

* Test whether the price coefficient estimated on the crisis subsample is different from the one estimated on the pre-crisis subsample: Wald test.
* 1) Generate the Δ terms.
gen dheating = D.heating
gen dbaseload = D.baseload

* 2) Estimate the full Unrestricted Error Model in the two subsamples. Store estimates.
qui reg dheating L.heating HDD SNSR price_l3m L(1/8).dheating L(0/7).dHDD L(0/7).dSNSR dprice Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_pre_crisis
estimates store pre

qui reg dheating L.heating HDD SNSR price_l3m L(1/8).dheating L(0/7).dHDD Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_crisis
estimates store crisis

* Combine the estimates and test the two long-term coefficients as non-linear transformations of estimated parameters. 
qui suest pre crisis
test [pre_mean]price_l3m = [crisis_mean]price_l3m
test [pre_mean]L.heating = [crisis_mean]L.heating
testnl ([pre_mean]price_l3m/[pre_mean]L.heating) = ([crisis_mean]price_l3m/[crisis_mean]L.heating)
testnl 0 = ([crisis_mean]price_l3m/[crisis_mean]L.heating)



* Test whether the HDD coefficient estimated on the crisis subsample is different from the one estimated on pre-crisis subsample: Wald test.
* Estimate the full Unrestricted Error Model in the two subsamples. Store estimates.
qui reg dheating L.heating HDD SNSR price_l3m L(1/8).dheating L(0/7).dHDD L(0/7).dSNSR dprice Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_pre_crisis
estimates store pre

qui reg dheating L.heating HDD SNSR price_l3m L(1/8).dheating L(0/7).dHDD Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_crisis
estimates store crisis

* Combine the estimates and test the two long-term coefficients as non-linear transformations of estimated parameters. 
qui suest pre crisis
testnl ([pre_mean]HDD/[pre_mean]L.heating) = ([crisis_mean]HDD/[crisis_mean]L.heating)



* Test whether the SNSR coefficient estimated on the crisis subsample is different from the one estimated on pre-crisis subsample: Wald test.
* Estimate the full Unrestricted Error Model in the two subsamples. Store estimates.
qui reg dheating L.heating HDD SNSR price_l3m L(1/8).dheating L(0/7).dHDD L(0/7).dSNSR dprice Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_pre_crisis
estimates store pre

qui reg dheating L.heating HDD SNSR price_l3m L(1/8).dheating L(0/7).dHDD Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7 TimeTrend if sample_crisis
estimates store crisis

* Combine the estimates and test the two long-term coefficients as non-linear transformations of estimated parameters. 
qui suest pre crisis
testnl ([pre_mean]SNSR/[pre_mean]L.heating) = ([crisis_mean]SNSR/[crisis_mean]L.heating)




********************************* ELASTICITIES *********************************

* Yearly Average Elasticities.
preserve

qui ardl heating HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0 0)

matrix coefficients = e(b)

gen β_heating = coefficients[1, 4]

qui ardl baseload HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(12 0 0 0)

matrix coefficients = e(b)

gen β_baseload = coefficients[1, 4]

qui ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)

matrix coefficients = e(b)

gen β_RDS = coefficients[1, 4]

gen int ydate = yofd(Date)

format ydate %tm

keep if ydate < 2025

collapse (mean) heating baseload price_l3m β_heating β_baseload β_RDS RDS, by(ydate)

gen avg_ε_heating = abs(β_heating * price_l3m / heating)

gen avg_ε_baseload = abs(β_baseload * price_l3m / baseload)

gen avg_ε_RDS = abs(β_RDS * price_l3m / RDS)


tsset ydate, yearly

tsline avg_ε_RDS avg_ε_heating avg_ε_baseload, xtick(2012(1)2024) xlabel(2012(1)2024) xtitle(Date) ytitle("") name(elas_yearly_Heat_Base) legend(label(1 "Total Consumption") label(2 "Heating Consumption") label(3 "Baseload Consumption") rows(1))
graph export Yearly_Elasticity_Base_Heat.jpg, as(jpg) replace 

restore

graph drop _all



* Average yearly elasticities WITH 95% CIs.
preserve

generate int year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t_heat = .
gen upper_eta_heat = . 
gen lower_eta_heat = .
gen eta_t_base = .
gen upper_eta_base = . 
gen lower_eta_base = .

* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_heating = mean(heating)

bysort year: egen mean_baseload = mean(baseload)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3623(1)4808 {
	
	qui ardl heating HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_heating_t = mean_heating[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_heating_t)]
	
	qui replace eta_t_heat = r(estimate) if ID == `i'

	qui replace upper_eta_heat = r(ub) if ID == `i'

	qui replace lower_eta_heat = r(lb) if ID == `i'
		
}


forvalues i = 3623(1)4808 {
	
	qui ardl baseload HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(12 0 0 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_baseload_t = mean_baseload[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_baseload_t)]
	
	qui replace eta_t_base = r(estimate) if ID == `i'

	qui replace upper_eta_base = r(ub) if ID == `i'

	qui replace lower_eta_base = r(lb) if ID == `i'
		
}

drop ID

replace eta_t_base = 0 if missing(eta_t_base)
replace upper_eta_base = 0 if missing(upper_eta_base)
replace lower_eta_base = 0 if missing(lower_eta_base)
replace eta_t_heat = 0 if missing(eta_t_heat)
replace upper_eta_heat = 0 if missing(upper_eta_heat)
replace lower_eta_heat = 0 if missing(lower_eta_heat)


collapse (mean) eta_t_heat eta_t_base upper_eta_heat upper_eta_base lower_eta_heat lower_eta_base, by(year)

tsset year, yearly 

keep if year < 2025

twoway (tsline eta_t_heat) (rcap lower_eta_heat upper_eta_heat year, lcolor(black)) (tsline eta_t_base) (rcap lower_eta_base upper_eta_base year, lcolor(black)), ytick(0(0.1)0.8) ylabel(0(0.1)0.8) xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) order(1 3 2) label(1 "Avg. Yearly Elasticity (Heating)") label(3 "Avg. Yearly Elasticity (Baseload)") label(2 "95% CIs")) name(heat)
graph export Base_Heat_Yearly_Elasticity_95_CI.png, as(png) replace 

restore

graph drop _all




***************************** PREDICTED CONSUMPTION ****************************

* Begin by running a model where we predict the coefficients on the historical data (i.e., before the crisis), and then use the estimated coefficients to predict consumption over the crisis. Then, use the Δ between actual and predicted consumption to measure savings.

ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(15 8 1 1)

estimates store my_ardl_model

forecast create myforecast, replace
forecast estimates my_ardl_model
forecast solve, prefix(predicted_) begin(td("01/12/2021"))

preserve

keep if Date >= td("01/12/2021")

gen int mdate = mofd(Date)

gen year = year(Date)

format mdate %tm

collapse (sum) RDS predicted_RDS, by(mdate)

tsset mdate, monthly

gen savings = predicted_RDS - RDS

tsline RDS predicted_RDS, legend(row(1) pos(6) label(1 "Actual Consumption") label(2 "Predicted Consumption")) name(g1, replace) xtitle("") ytitle("")
graph export g1.png, as(png) replace 

tsline savings, ytick(-300(100)900) ylabel(-300(100)900) name(g2, replace) xtitle("") ytitle("")
graph export g2.png, as(png) replace

restore


graph drop _all



* Placebo test on the whole sample.
preserve

gen int mdate = mofd(Date)

format mdate %tm

collapse (sum) RDS predicted_RDS, by(mdate)

tsset mdate

tsline RDS predicted_RDS, legend(row(1) pos(6) label(1 "Actual Consumption") label(2 "Predicted Consumption")) name(g1, replace) xtitle("") ytitle("")

restore

graph drop _all
drop predicted_RDS

}








********************************************************************************
************************************ MONTHLY ***********************************
********************************************************************************

{
	
*********************************** CLEANING ***********************************

* Import the working database.

clear

*===============================================================================
* Complete with the file path to the daily data set.
*===============================================================================
import excel "",firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Declare data to be time-series.
tsset time, monthly

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable TimeTrend "Linear Time Trend"


gen double date_num = daily(date, "DMY")

format date_num %tdDD/NN/CCYY

drop date

rename date_num Date 

tsline RDS baseload heating, legend(row(1) pos(6) label(1 "Total Consumption") label(2 "Baseload Consumption") label(3 "Heating Consumption")) ytitle("") ttick(2012m1 2014m1 2016m1 2018m1 2020m1 2022m1 2024m1) tlabel(2012m1 "Jan 2012" 2014m1 "Jan 2014" 2016m1 "Jan 2016" 2018m1 "Jan 2018" 2020m1 "Jan 2020"  2022m1 "Jan 2022" 2024m1 "Jan 2024") name(RDS_Base_Heat)
graph export RDS_Base_Heat.png, as(png) replace

graph drop _all



********************************** REGRESSIONS *********************************

ardl RDS HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(12)

ardl RDS HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) ec maxlags(12)

estat ectest



ardl heating HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(12)

ardl heating HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) ec maxlags(12)

estat ectest



ardl baseload HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(12)

ardl baseload HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) ec maxlags(12)

estat ectest




***************************** PREDICTED CONSUMPTION ****************************

* Begin by running a model where we predict the coefficients on the historical data (i.e., before the crisis), and then use the estimated coefficients to predict consumption over the crisis. Then, use the Δ between actual and predicted consumption to measure savings.

gen byte insample = time < 743

ardl RDS HDD SNSR price_l3m if insample, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) maxlags(12)

estimates store my_ardl_model

forecast create myforecast, replace
forecast estimates my_ardl_model
forecast solve, prefix(predicted_) begin(744)

preserve

keep if time >= 743

tsline RDS predicted_RDS, legend(row(1) pos(6) label(1 "Actual Consumption") label(2 "Predicted Consumption")) name(g1, replace) xtitle("") ytick(0(1000)6000) ylabel(0(1000)6000) 
graph export g1.png, as(png) replace 

gen savings = predicted_RDS - RDS

tsline savings, ytick(-300(100)900) ylabel(-300(100)900) name(g2, replace) xtitle("") ytitle("")  
graph export g2.png, as(png) replace 

restore


graph drop _all




******************************* ELASTICITY - RDS *******************************

preserve 

* Initialize variables for elasticity and CIs.
gen eta_t = .
gen upper_eta = . 
gen lower_eta = .

gen year = year(Date)

* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_RDS = mean(RDS)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3(1)158 {
	
	qui ardl RDS HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) ec lags(1 2 0 1)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_RDS_t = mean_RDS[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_RDS_t)]
	
	qui replace eta_t = r(estimate) if ID == `i'

	qui replace upper_eta = r(ub) if ID == `i'

	qui replace lower_eta = r(lb) if ID == `i'
		
}

drop ID

collapse (mean) eta_t upper_eta lower_eta, by(year)

tsset year, yearly 

keep if year < 2025

twoway (tsline eta_t) (rcap lower_eta upper_eta year, lcolor(black)), xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) label(1 "Average Yearly Elasticity") label(2 "95% CI")) ytick(0(0.1)0.5) ylabel(0(0.1)0.5)
graph export RDS_Yearly_Elasticity_95_CI.png, as(png) replace 

restore



*********************** ELASTICITY - HEATING & BASELOAD ************************

* Average yearly elasticities WITH 95% CIs.
preserve

gen year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t_heat = .
gen upper_eta_heat = . 
gen lower_eta_heat = .
gen eta_t_base = .
gen upper_eta_base = . 
gen lower_eta_base = .

* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_heating = mean(heating)

bysort year: egen mean_baseload = mean(baseload)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3(1)158 {
	
	qui ardl heating HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) ec lags(1 2 0 1)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_heating_t = mean_heating[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_heating_t)]
	
	qui replace eta_t_heat = r(estimate) if ID == `i'

	qui replace upper_eta_heat = r(ub) if ID == `i'

	qui replace lower_eta_heat = r(lb) if ID == `i'
		
}


forvalues i = 3(1)158 {
	
	qui ardl baseload HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) ec lags(2 0 0 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_baseload_t = mean_baseload[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_baseload_t)]
	
	qui replace eta_t_base = r(estimate) if ID == `i'

	qui replace upper_eta_base = r(ub) if ID == `i'

	qui replace lower_eta_base = r(lb) if ID == `i'
		
}

drop ID

collapse (mean) eta_t_heat eta_t_base upper_eta_heat upper_eta_base lower_eta_heat lower_eta_base, by(year)

tsset year, yearly 

keep if year < 2025

twoway (tsline eta_t_heat) (rcap lower_eta_heat upper_eta_heat year, lcolor(black)) (tsline eta_t_base) (rcap lower_eta_base upper_eta_base year, lcolor(black)), ytick(0(0.1)0.5) ylabel(0(0.1)0.5) xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) order(1 3 2) label(1 "Avg. Yearly Elasticity (Heating)") label(3 "Avg. Yearly Elasticity (Baseload)") label(2 "95% CIs")) name(heat)
graph export Base_Heat_Yearly_Elasticity_95_CI.png, as(png) replace 

restore

graph drop _all




***************************** ELASTICITY - Q TILDE *****************************

qui ardl RDS HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) lags(1 2 0 1)

matrix coefficients = e(b)

gen b_RDS_L1 = coefficients[1,1]
gen b_HDD = coefficients[1,2]
gen b_HDD_L1 = coefficients[1,3]
gen b_HDD_L2 = coefficients[1,4]
gen b_SNSR = coefficients[1,5]
gen b_Month_2 = coefficients[1,8]
gen b_Month_3 = coefficients[1,9]
gen b_Month_4 = coefficients[1,10]
gen b_Month_5 = coefficients[1,11]
gen b_Month_6 = coefficients[1,12]
gen b_Month_7 = coefficients[1,13]
gen b_Month_8 = coefficients[1,14]
gen b_Month_9 = coefficients[1,15]
gen b_Month_10 = coefficients[1,16]
gen b_Month_11 = coefficients[1,17]
gen b_Month_12 = coefficients[1,18]
gen b_TimeTrend = coefficients[1,19]

gen b_price = coefficients[1,6]
gen b_price_L1 = coefficients[1,7]
gen constant = coefficients[1,20]

gen Q_tilde = RDS - (b_RDS_L1 * L1.RDS + b_HDD * HDD + b_HDD_L1 * L1.HDD + b_HDD_L2 * L2.HDD + b_SNSR * SNSR + ///
				     b_Month_2 * Month_2 + b_Month_3 * Month_3 + b_Month_4 * Month_4 + b_Month_5 * Month_5 + b_Month_6 * Month_6 + ///
					 b_Month_7 * Month_7 + b_Month_8 * Month_8 + b_Month_9 * Month_9 + b_Month_10 * Month_10 + b_Month_11 * Month_11 + ///
					 b_Month_12 * Month_12 + b_TimeTrend * TimeTrend)
					
					
gen check = constant + b_price*price_l3m + b_price_L1*L.price_l3m
				
drop b_RDS_L1 b_HDD b_HDD_L1 b_HDD_L2 b_SNSR b_Month_2 b_Month_3 b_Month_4 b_Month_5 b_Month_6 b_Month_7 b_Month_8 b_Month_9 b_Month_10 b_Month_11 b_Month_12 b_TimeTrend



preserve

gen year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t_Q = .
gen upper_eta_Q = . 
gen lower_eta_Q = .


* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_Q_tilde = mean(Q_tilde)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3(1)158 {
	
	qui ardl RDS HDD SNSR price_l3m, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12) ec lags(1 2 0 1)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_Q_t = mean_Q_tilde[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_Q_t)]
	
	qui replace eta_t_Q = r(estimate) if ID == `i'

	qui replace upper_eta_Q = r(ub) if ID == `i'

	qui replace lower_eta_Q = r(lb) if ID == `i'
		
}

drop ID

collapse (mean) eta_t_Q upper_eta_Q lower_eta_Q, by(year)

tsset year, yearly 

keep if year < 2025

twoway (tsline eta_t_Q) (rcap lower_eta_Q upper_eta_Q year, lcolor(black)), ytick(0(0.1)1) ylabel(0(0.1)1) xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) order(1 2) label(1 "Avg. Yearly Elasticity") label(2 "95% CIs")) name(Q)
* graph export Base_Heat_Yearly_Elasticity_95_CI.png, as(png) replace 

restore

graph drop _all





}








********************************************************************************
******************************** HDD, RDS, SNSSR *******************************
********************************************************************************

{

*********************************** CLEANING ***********************************

* Import the working database.
clear

*===============================================================================
* Complete with the file path to the daily data set.
*===============================================================================
import excel "",firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Rename the date variable for consistency with the code.
format date %tdDD/NN/CCYY
rename date Date

* Declare data to be time-series.
tsset Date, daily

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable Day_1 "Sunday"
label variable Day_2 "Monday"
label variable Day_3 "Tuesday"
label variable Day_4 "Wednesday"
label variable Day_5 "Thursday"
label variable Day_6 "Friday"
label variable Day_7 "Saturday"

label variable TimeTrend "Linear Time Trend"

label variable heating "Heating Consumption"
label variable baseload "Baseload Consumption"

* Initialize grouping variables that will be needed for the regressions to distinguish between the two different subsamples.
gen byte sample_pre_crisis = Date < td("01/12/2021")
gen byte sample_crisis = Date >= td("01/12/2021")



********************************* HDDs vs RDS **********************************

gen log_RDS = log(RDS)
*gen log_HDD = log(0.0000338817841215185/2 + HDD)
gen log_HDD = log(HDD)


label variable log_RDS "Log Demand"
label variable RDS "Demand"
label variable log_HDD "Log HDDs"
label variable HDD "HDDs"

qui reg RDS HDD
scalar r_squared_linear = round(e(r2), .0001)*100

qui reg log_RDS log_HDD
scalar r_squared_log = round(e(r2), .0001)*100

local rsq = "R² = " + string(r_squared_linear) + "%"

twoway (scatter RDS HDD) (lfit RDS HDD, ytitle("Demand (Millions of Sm³)") legend(off) text(100 16 "`rsq'") name(linear)) 

local rsq = "R² = " + string(r_squared_log) + "%"

twoway (scatter log_RDS log_HDD) (lfit log_RDS log_HDD, ytitle("Log Demand") legend(off) text(3.2 2.5 "`rsq'") name(log)) 

graph combine linear log, cols(2) iscale(1)
graph export HDD_RDS_Linear_Log.jpg, as(jpg) replace


graph drop _all

*********************************** CLEANING ***********************************

* Import the working database.
clear

*===============================================================================
* Complete with the file path to the daily data set.
*===============================================================================
import excel "",firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Declare data to be time-series.
tsset time, monthly

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable TimeTrend "Linear Time Trend"


* Initialize grouping variables that will be needed to graph over the different phases.
gen double date_num = daily(date, "DMY")

format date_num %tdDD/NN/CCYY

drop date

rename date_num Date


* Initialize grouping variables that will be needed to graph over the different phases.
gen group_1 = time < 744
gen group_2 = time > 743 & time < 754
gen group_3 = time > 753 & time < 764
gen group_4 = time > 763



************************************* HDDs *************************************
	
* Create the Monthly/Average Monthly graph for HDDs.
tsset time, monthly 

tsline HDD, tlabel(2012m1 "2012" 2014m1 "2014" 2016m1 "2016" 2018m1 "2018" 2020m1 "2020" 2022m1 "2022" 2024m1 "2024") ytitle("") xtitle("Date") ylabel(, format(%9.0f)) name(Monthly_HDD)

gen month = month(Date)

preserve

collapse (mean) HDD, by(month)

tsset month

tsline HDD, ytitle("") xtick(1 2 3 4 5 6 7 8 9 10 11 12) xlabel(1 2 3 4 5 6 7 8 9 10 11 12) xtitle("Month") ylabel(, format(%9.0f)) name(Average_Monthly_HDD)   

graph combine Monthly_HDD Average_Monthly_HDD, cols(2)
graph export HDD_Final.jpg, as(jpg) replace

graph drop _all

restore



************************************* SNSR *************************************

tsset time, monthly 

tsline SNSR, tlabel(2012m1 "2012" 2014m1 "2014" 2016m1 "2016" 2018m1 "2018" 2020m1 "2020" 2022m1 "2022" 2024m1 "2024") ytitle("") xtitle("Date") ylabel(, format(%9.0f)) name(Monthly_SNSR)

preserve

collapse (mean) SNSR, by(month)

tsset month

tsline SNSR, ytitle("") xtick(1 2 3 4 5 6 7 8 9 10 11 12) xlabel(1 2 3 4 5 6 7 8 9 10 11 12) xtitle("Month") ylabel(, format(%9.0f)) name(Average_Monthly_SNSR)   

graph combine Monthly_SNSR Average_Monthly_SNSR, cols(2)
graph export SNSR_Final.jpg, as(jpg) replace

graph drop _all

restore

drop month



************************************** RDS *************************************

tsset time, monthly 

tsline RDS, tlabel(2012m1 "2012" 2014m1 "2014" 2016m1 "2016" 2018m1 "2018" 2020m1 "2020" 2022m1 "2022" 2024m1 "2024") ytitle("") xtitle("Date") legend(off) tline(2022m2) ylabel(, format(%9.0f)) name(RDS) 
graph export RDS.jpg, as(jpg) replace


tsline price_l3m, tlabel(2012m1 "2012" 2014m1 "2014" 2016m1 "2016" 2018m1 "2018" 2020m1 "2020" 2022m1 "2022" 2024m1 "2024") ytitle("") xtitle("Date") legend(off) tline(2022m2) ylabel(, format(%9.0f)) name(Price) 
graph export Price.jpg, as(jpg) replace

graph drop _all



********************************* HDDs vs SNSR *********************************

forvalues i = 1(1)12{
	
	gen group_`i'_2022 = month(Date) == `i' & year(Date) == 2022
	
	gen group_`i'_2023 = month(Date) == `i' & year(Date) == 2023
	
	gen group_`i'_2024 = month(Date) == `i' & year(Date) == 2024
	
	gen group_`i'_2025 = month(Date) == `i' & year(Date) == 2025
	
}

* Replace with the values to graph.

forvalues i = 1(1)12{
	
	gen block`i'_HDD = HDD if Month_`i' == 1
	
	gen block`i'_SNSR = SNSR if Month_`i' == 1
	
	gen block`i'_2022_HDD = HDD if group_`i'_2022 == 1
	
	gen block`i'_2023_HDD = HDD if group_`i'_2023 == 1
	
	gen block`i'_2024_HDD = HDD if group_`i'_2024 == 1
	
	gen block`i'_2025_HDD = HDD if group_`i'_2025 == 1
	
	gen block`i'_2022_SNSR = SNSR if group_`i'_2022 == 1
	
	gen block`i'_2023_SNSR = SNSR if group_`i'_2023 == 1
	
	gen block`i'_2024_SNSR = SNSR if group_`i'_2024 == 1
	
	gen block`i'_2025_SNSR = SNSR if group_`i'_2025 == 1
	
}



twoway (scatter HDD SNSR, msize(0) connect(l) lcolor(black) lwidth(thin)) ///
	   (scatter block1_HDD block1_SNSR, mcolor(black) msymbol(O))  ///
	   (scatter block2_HDD block2_SNSR, mcolor(black) msymbol(D))  ///
	   (scatter block3_HDD block3_SNSR, mcolor(black) msymbol(T))  ///
	   (scatter block4_HDD block4_SNSR, mcolor(black) msymbol(S))  ///
	   (scatter block5_HDD block5_SNSR, mcolor(black) msymbol(+))  ///
	   (scatter block6_HDD block6_SNSR, mcolor(black) msymbol(X))  ///
	   (scatter block7_HDD block7_SNSR, mcolor(black) msymbol(A))  ///
	   (scatter block8_HDD block8_SNSR, mcolor(black) msymbol(|))  ///
	   (scatter block9_HDD block9_SNSR, mcolor(black) msymbol(V))  ///
	   (scatter block10_HDD block10_SNSR, mcolor(black) msymbol(th))  ///
	   (scatter block11_HDD block11_SNSR, mcolor(black) msymbol(oh))  ///
	   (scatter block12_HDD block12_SNSR, mcolor(black) msymbol(dh))  ///
	   (scatter block1_2022_HDD block1_2022_SNSR, mcolor(red) msymbol(O))  ///
	   (scatter block2_2022_HDD block2_2022_SNSR, mcolor(red) msymbol(D))  ///
	   (scatter block3_2022_HDD block3_2022_SNSR, mcolor(red) msymbol(T))  ///
	   (scatter block4_2022_HDD block4_2022_SNSR, mcolor(red) msymbol(S))  ///
	   (scatter block5_2022_HDD block5_2022_SNSR, mcolor(red) msymbol(+))  ///
	   (scatter block6_2022_HDD block6_2022_SNSR, mcolor(red) msymbol(X))  ///
	   (scatter block7_2022_HDD block7_2022_SNSR, mcolor(red) msymbol(A))  ///
	   (scatter block8_2022_HDD block8_2022_SNSR, mcolor(red) msymbol(|))  ///
	   (scatter block9_2022_HDD block9_2022_SNSR, mcolor(red) msymbol(V))  ///
	   (scatter block10_2022_HDD block10_2022_SNSR, mcolor(red) msymbol(th))  ///
	   (scatter block11_2022_HDD block11_2022_SNSR, mcolor(red) msymbol(oh))  ///
	   (scatter block12_2022_HDD block12_2022_SNSR, mcolor(red) msymbol(dh))  ///
	   (scatter block1_2023_HDD block1_2023_SNSR, mcolor(blue) msymbol(O))  ///
	   (scatter block2_2023_HDD block2_2023_SNSR, mcolor(blue) msymbol(D))  ///
	   (scatter block3_2023_HDD block3_2023_SNSR, mcolor(blue) msymbol(T))  ///
	   (scatter block4_2023_HDD block4_2023_SNSR, mcolor(blue) msymbol(S))  ///
	   (scatter block5_2023_HDD block5_2023_SNSR, mcolor(blue) msymbol(+))  ///
	   (scatter block6_2023_HDD block6_2023_SNSR, mcolor(blue) msymbol(X))  ///
	   (scatter block7_2023_HDD block7_2023_SNSR, mcolor(blue) msymbol(A))  ///
	   (scatter block8_2023_HDD block8_2023_SNSR, mcolor(blue) msymbol(|))  ///
	   (scatter block9_2023_HDD block9_2023_SNSR, mcolor(blue) msymbol(V))  ///
	   (scatter block10_2023_HDD block10_2023_SNSR, mcolor(blue) msymbol(th))  ///
	   (scatter block11_2023_HDD block11_2023_SNSR, mcolor(blue) msymbol(oh))  ///
	   (scatter block12_2023_HDD block12_2023_SNSR, mcolor(blue) msymbol(dh))  ///
	   (scatter block1_2024_HDD block1_2024_SNSR, mcolor(green) msymbol(O))  ///
	   (scatter block2_2024_HDD block2_2024_SNSR, mcolor(green) msymbol(D))  ///
	   (scatter block3_2024_HDD block3_2024_SNSR, mcolor(green) msymbol(T))  ///
	   (scatter block4_2024_HDD block4_2024_SNSR, mcolor(green) msymbol(S))  ///
	   (scatter block5_2024_HDD block5_2024_SNSR, mcolor(green) msymbol(+))  ///
	   (scatter block6_2024_HDD block6_2024_SNSR, mcolor(green) msymbol(X))  ///
	   (scatter block7_2024_HDD block7_2024_SNSR, mcolor(green) msymbol(A))  ///
	   (scatter block8_2024_HDD block8_2024_SNSR, mcolor(green) msymbol(|))  ///
	   (scatter block9_2024_HDD block9_2024_SNSR, mcolor(green) msymbol(V))  ///
	   (scatter block10_2024_HDD block10_2024_SNSR, mcolor(green) msymbol(th))  ///
	   (scatter block11_2024_HDD block11_2024_SNSR, mcolor(green) msymbol(oh))  ///
	   (scatter block12_2024_HDD block12_2024_SNSR, mcolor(green) msymbol(dh))  ///
	   (scatter block1_2025_HDD block1_2025_SNSR, mcolor(orange) msymbol(O))  ///
	   (scatter block2_2025_HDD block2_2025_SNSR, mcolor(orange) msymbol(D)),  ///
	   legend(position(6) rows(2) order(2 3 4 5 6 7 8 9 10 11 12 13 14 26 38 50) label(2 "January") label(3 "February") label(4 "March") label(5 "April") 		label(6 "May") label(7 "June") label(8 "July") label(9 "August") label(10 "September") label(11 "October") label(12 "November") label(13 "December") 	   label(14 "2022") label(26 "2023") label(38 "2024") label(50 "2025")) xtitle("SNSR") ytitle("HDD") ylabel(, format(%9.0f))
graph export HDD_vs_SNSR_by_Month.jpg, as(jpg) replace 

drop group_1_2022 group_1_2023 group_1_2024 group_2_2022 group_2_2023 group_2_2024 group_3_2022 group_3_2023 group_3_2024 group_4_2022 group_4_2023 group_4_2024 group_5_2022 group_5_2023 group_5_2024 group_6_2022 group_6_2023 group_6_2024 group_7_2022 group_7_2023 group_7_2024 group_8_2022 group_8_2023 group_8_2024 group_9_2022 group_9_2023 group_9_2024 group_10_2022 group_10_2023 group_10_2024 group_11_2022 group_11_2023 group_11_2024 group_12_2022 group_12_2023 group_12_2024 block1_HDD block1_SNSR block1_2022_HDD block1_2023_HDD block1_2024_HDD block1_2022_SNSR block1_2023_SNSR block1_2024_SNSR block2_HDD block2_SNSR block2_2022_HDD block2_2023_HDD block2_2024_HDD block2_2022_SNSR block2_2023_SNSR block2_2024_SNSR block3_HDD block3_SNSR block3_2022_HDD block3_2023_HDD block3_2024_HDD block3_2022_SNSR block3_2023_SNSR block3_2024_SNSR block4_HDD block4_SNSR block4_2022_HDD block4_2023_HDD block4_2024_HDD block4_2022_SNSR block4_2023_SNSR block4_2024_SNSR block5_HDD block5_SNSR block5_2022_HDD block5_2023_HDD block5_2024_HDD block5_2022_SNSR block5_2023_SNSR block5_2024_SNSR block6_HDD block6_SNSR block6_2022_HDD block6_2023_HDD block6_2024_HDD block6_2022_SNSR block6_2023_SNSR block6_2024_SNSR block7_HDD block7_SNSR block7_2022_HDD block7_2023_HDD block7_2024_HDD block7_2022_SNSR block7_2023_SNSR block7_2024_SNSR block8_HDD block8_SNSR block8_2022_HDD block8_2023_HDD block8_2024_HDD block8_2022_SNSR block8_2023_SNSR block8_2024_SNSR block9_HDD block9_SNSR block9_2022_HDD block9_2023_HDD block9_2024_HDD block9_2022_SNSR block9_2023_SNSR block9_2024_SNSR block10_HDD block10_SNSR block10_2022_HDD block10_2023_HDD block10_2024_HDD block10_2022_SNSR block10_2023_SNSR block10_2024_SNSR block11_HDD block11_SNSR block11_2022_HDD block11_2023_HDD block11_2024_HDD block11_2022_SNSR block11_2023_SNSR block11_2024_SNSR block12_HDD block12_SNSR block12_2022_HDD block12_2023_HDD block12_2024_HDD block12_2022_SNSR block12_2023_SNSR block12_2024_SNSR group_1_2025 group_2_2025 group_3_2025 group_4_2025 group_5_2025 group_6_2025 group_7_2025 group_8_2025 group_9_2025 group_10_2025 group_11_2025 group_12_2025 block1_2025_HDD block1_2025_SNSR block2_2025_HDD block2_2025_SNSR block3_2025_HDD block3_2025_SNSR block4_2025_HDD block4_2025_SNSR block5_2025_HDD block5_2025_SNSR block6_2025_HDD block6_2025_SNSR block7_2025_HDD block7_2025_SNSR block8_2025_HDD block8_2025_SNSR block9_2025_HDD block9_2025_SNSR block10_2025_HDD block10_2025_SNSR block11_2025_HDD block11_2025_SNSR block12_2025_HDD block12_2025_SNSR


	
}








********************************************************************************
******************************** BAI-PERRON TEST *******************************
********************************************************************************

{

*********************************** CLEANING ***********************************

* Import the working database.

clear

*===============================================================================
* Complete with the file path to the monthly data set.
*===============================================================================
import excel "",firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Declare data to be time-series.
tsset time, monthly

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable TimeTrend "Linear Time Trend"


gen double date_num = daily(date, "DMY")

format date_num %tdDD/NN/CCYY

drop date

rename date_num Date 

gen dRDS = D.RDS
gen dHDD = D.HDD
gen dprice_l3m = D.price_l3m 
xtbreak test dRDS L.RDS L.HDD L.SNSR L.price_l3m L.dRDS L(0/1).dHDD L.dprice_l3m TimeTrend Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12, breaks(1) h(1)

}








********************************************************************************
********************************* CHECK NO SNSR ********************************
********************************************************************************

{

*********************************** CLEANING ***********************************

* Import the working database.
clear
*===============================================================================
* Complete with the file path to the daily data set.
*===============================================================================
import excel "",firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Rename the date variable for consistency with the code.
format date %tdDD/NN/CCYY
rename date Date

* Declare data to be time-series.
tsset Date, daily

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable Day_1 "Sunday"
label variable Day_2 "Monday"
label variable Day_3 "Tuesday"
label variable Day_4 "Wednesday"
label variable Day_5 "Thursday"
label variable Day_6 "Friday"
label variable Day_7 "Saturday"

label variable TimeTrend "Linear Time Trend"

label variable heating "Heating Consumption"
label variable baseload "Baseload Consumption"

* Initialize grouping variables that will be needed for the regressions to distinguish between the two different subsamples.
gen byte sample_pre_crisis = Date < td("01/12/2021")
gen byte sample_crisis = Date >= td("01/12/2021")




************************* REGRESSION: TOTAL CONSUMPTION ************************

* Model for Total Consumption, pre-crisis sample.
* ARDL.
ardl RDS HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 1)

* ECM.
ardl RDS HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1)



* Model for Total Consumption, crisis sample.
* ARDL.
ardl RDS HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 0)

* ECM.
ardl RDS HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0)




************************* ELASTICITIES, SPLIT SAMPLES **************************

* Average yearly elasticities WITH 95% CIs.
preserve

* Create a variable to track years.
generate int year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t = .
gen upper_eta = . 
gen lower_eta = .

* Generate an ID for the loops.
gen ID = _n

* Compute yearly averages of consumption and price.
bysort year: egen mean_RDS = mean(RDS)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3623(1)4808 {
	
	qui ardl RDS HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec maxlags(20) lags(9 8 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_RDS_t = mean_RDS[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_RDS_t)]
	
	qui replace eta_t = r(estimate) if ID == `i'

	qui replace upper_eta = r(ub) if ID == `i'

	qui replace lower_eta = r(lb) if ID == `i'
		
}

drop ID

replace eta_t = 0 if missing(eta_t)
replace upper_eta = 0 if missing(upper_eta)
replace lower_eta = 0 if missing(lower_eta)

collapse (mean) eta_t upper_eta lower_eta, by(year)

tsset year, yearly 

keep if year < 2025

twoway (tsline eta_t) (rcap lower_eta upper_eta year, lcolor(black)), xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) label(1 "Average Yearly Elasticity") label(2 "95% CI")) ytick(0(0.1)0.5) ylabel(0(0.1)0.5) xtitle("Date")
graph export RDS_Yearly_Elasticity_95_CI.png, as(png) replace 

restore




************************************ Q TILDE ***********************************

qui ardl RDS HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 0)

matrix coefficients = e(b)

gen b_RDS_L1 = coefficients[1,1]
gen b_RDS_L2 = coefficients[1,2]
gen b_RDS_L3 = coefficients[1,3]
gen b_RDS_L4 = coefficients[1,4]
gen b_RDS_L5 = coefficients[1,5]
gen b_RDS_L6 = coefficients[1,6]
gen b_RDS_L7 = coefficients[1,7]
gen b_RDS_L8 = coefficients[1,8]
gen b_RDS_L9 = coefficients[1,9]
gen b_HDD = coefficients[1,10]
gen b_HDD_L1 = coefficients[1,11]
gen b_HDD_L2 = coefficients[1,12]
gen b_HDD_L3 = coefficients[1,13]
gen b_HDD_L4 = coefficients[1,14]
gen b_HDD_L5 = coefficients[1,15]
gen b_HDD_L6 = coefficients[1,16]
gen b_HDD_L7 = coefficients[1,17]
gen b_HDD_L8 = coefficients[1,18]
gen b_Month_2 = coefficients[1,20]
gen b_Month_3 = coefficients[1,21]
gen b_Month_4 = coefficients[1,22]
gen b_Month_5 = coefficients[1,23]
gen b_Month_6 = coefficients[1,24]
gen b_Month_7 = coefficients[1,25]
gen b_Month_8 = coefficients[1,26]
gen b_Month_9 = coefficients[1,27]
gen b_Month_10 = coefficients[1,28]
gen b_Month_11 = coefficients[1,29]
gen b_Month_12 = coefficients[1,30]
gen b_Day_2 = coefficients[1,31]
gen b_Day_3 = coefficients[1,32]
gen b_Day_4 = coefficients[1,33]
gen b_Day_5 = coefficients[1,34]
gen b_Day_6 = coefficients[1,35]
gen b_Day_7 = coefficients[1,36]
gen b_TimeTrend = coefficients[1,37]

gen Q_tilde= max(RDS - (b_RDS_L1 * L1.RDS + b_RDS_L2 * L2.RDS + b_RDS_L3 * L3.RDS + b_RDS_L4 * L4.RDS + b_RDS_L5 * L5.RDS + ///
						b_RDS_L6 * L6.RDS + b_RDS_L7 * L7.RDS + b_RDS_L8 * L8.RDS + b_RDS_L9 * L9.RDS + ///
					    b_HDD * HDD + b_HDD_L1 * L1.HDD + b_HDD_L2 * L2.HDD + b_HDD_L3 * L3.HDD + b_HDD_L4 * L4.HDD + ///
					    b_HDD_L5 * L5.HDD + b_HDD_L6 * L6.HDD + b_HDD_L7 * L7.HDD + b_HDD_L8 * L8.HDD + ///
					    b_Month_2 * Month_2 + b_Month_3 * Month_3 + b_Month_4 * Month_4 + b_Month_5 * Month_5 + b_Month_6 * Month_6 + ///
					    b_Month_7 * Month_7 + b_Month_8 * Month_8 + b_Month_9 * Month_9 + b_Month_10 * Month_10 + b_Month_11 * Month_11 + ///
					    b_Month_12 * Month_12 + b_Day_2 * Day_2 + b_Day_3 * Day_3 + b_Day_4 * Day_4 + b_Day_5 * Day_5 + b_Day_6 * Day_6 + ///
					    b_Day_7 * Day_7 + b_TimeTrend * TimeTrend), 0)
									
drop b_RDS_L1 b_RDS_L2 b_RDS_L3 b_RDS_L4 b_RDS_L5 b_RDS_L6 b_RDS_L7 b_RDS_L8 b_RDS_L9 b_HDD b_HDD_L1 b_HDD_L2 b_HDD_L3 b_HDD_L4 b_HDD_L5 b_HDD_L6 b_HDD_L7 b_HDD_L8 b_Month_2 b_Month_3 b_Month_4 b_Month_5 b_Month_6 b_Month_7 b_Month_8 b_Month_9 b_Month_10 b_Month_11 b_Month_12 b_Day_2 b_Day_3 b_Day_4 b_Day_5 b_Day_6 b_Day_7 b_TimeTrend

replace Q_tilde = 0 if Date < td("01/12/2021")



preserve

gen int mdate = mofd(Date)

format mdate %tm

collapse (sum) Q_tilde, by(mdate)

keep if mdate > tm(2012m1)

tsset mdate, monthly

tsline Q_tilde, ttick(2012m1 2014m1 2016m1 2018m1 2020m1 2022m1 2024m1) tlabel(2012m1 "Jan 2012" 2014m1 "Jan 2014" 2016m1 "Jan 2016" 2018m1 "Jan 2018" 2020m1 "Jan 2020"  2022m1 "Jan 2022" 2024m1 "Jan 2024" ) xtitle("Date") ytitle("")
graph export Q_tilde.jpg, as(jpg) replace 

restore



* Compute and graph the average yearly elasticity with 95% CIs.
preserve

generate int year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t_Q_tilde = .
gen upper_eta_Q_tilde = . 
gen lower_eta_Q_tilde = .

* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_Q_tilde = mean(Q_tilde)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3623(1)4808 {
	
	qui ardl RDS HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_Q_tilde_t = mean_Q_tilde[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_Q_tilde_t)]
	
	qui replace eta_t_Q_tilde = r(estimate) if ID == `i'

	qui replace upper_eta_Q_tilde = r(ub) if ID == `i'

	qui replace lower_eta_Q_tilde = r(lb) if ID == `i'
		
}

drop ID

replace eta_t_Q_tilde = 0 if missing(eta_t_Q_tilde)
replace upper_eta_Q_tilde = 0 if missing(upper_eta_Q_tilde)
replace lower_eta_Q_tilde = 0 if missing(lower_eta_Q_tilde)

collapse (mean) eta_t_Q_tilde lower_eta_Q_tilde upper_eta_Q_tilde, by(year)

tsset year, yearly 

keep if year < 2025

twoway (tsline eta_t_Q_tilde) (rcap lower_eta_Q_tilde upper_eta_Q_tilde year, lcolor(black)), xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) label(1 "Average Yearly Elasticity") label(2 "95% CI")) ytick(0(0.5)2.1) ylabel(0(0.5)2.1)
graph export Q_tilde_Yearly_Elasticity_95_CI.jpg, as(jpg) replace 

restore




************************ REGRESSION: HEATING & BASELOAD ************************


* Model for Heating Consumption, PRE-CRISIS SAMPLE.
ardl heating HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 1)
eststo model0

ardl heating HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1)
eststo model1

estat ectest

* Model for Heating Consumption, CRISIS SAMPLE.
ardl heating HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 0)
eststo model2

ardl heating HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0)
eststo model3

estat ectest



* Model for Baseload Consumption, PRE-CRISIS SAMPLE.
ardl baseload HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(19 0 0) 

ardl baseload HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(19 0 0)

* Model for Baseload Consumption, CRISIS SAMPLE.
ardl baseload HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(12 0 0) 

ardl baseload HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(12 0 0)



********************************* ELASTICITIES *********************************

* Yearly Average Elasticities.
preserve

qui ardl heating HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0)

matrix coefficients = e(b)

gen β_heating = coefficients[1, 4]

qui ardl baseload HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(12 0 0)

matrix coefficients = e(b)

gen β_baseload = coefficients[1, 4]

qui ardl RDS HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 0)

matrix coefficients = e(b)

gen β_RDS = coefficients[1, 4]

gen int ydate = yofd(Date)

format ydate %tm

keep if ydate < 2025

collapse (mean) heating baseload price_l3m β_heating β_baseload β_RDS RDS, by(ydate)

gen avg_ε_heating = abs(β_heating * price_l3m / heating)

gen avg_ε_baseload = abs(β_baseload * price_l3m / baseload)

gen avg_ε_RDS = abs(β_RDS * price_l3m / RDS)


tsset ydate, yearly

tsline avg_ε_RDS avg_ε_heating avg_ε_baseload, xtick(2012(1)2024) xlabel(2012(1)2024) xtitle(Date) ytitle("") name(elas_yearly_Heat_Base) legend(label(1 "Total Consumption") label(2 "Heating Consumption") label(3 "Baseload Consumption") rows(1))
graph export Yearly_Elasticity_Base_Heat.jpg, as(jpg) replace 

restore

graph drop _all



* Average yearly elasticities WITH 95% CIs.
preserve

generate int year = year(Date)

* Initialize variables for elasticity and CIs.
gen eta_t_heat = .
gen upper_eta_heat = . 
gen lower_eta_heat = .
gen eta_t_base = .
gen upper_eta_base = . 
gen lower_eta_base = .

* Generate an ID for the loops.
gen ID = _n

bysort year: egen mean_heating = mean(heating)

bysort year: egen mean_baseload = mean(baseload)

bysort year: egen mean_price_l3m = mean(price_l3m)

forvalues i = 3623(1)4808 {
	
	qui ardl heating HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_heating_t = mean_heating[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_heating_t)]
	
	qui replace eta_t_heat = r(estimate) if ID == `i'

	qui replace upper_eta_heat = r(ub) if ID == `i'

	qui replace lower_eta_heat = r(lb) if ID == `i'
		
}


forvalues i = 3623(1)4808 {
	
	qui ardl baseload HDD price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(12 0 0)

	qui scalar mean_price_t = mean_price_l3m[`i']
	
	qui scalar mean_baseload_t = mean_baseload[`i']
	
	qui lincom -[price_l3m * (mean_price_t / mean_baseload_t)]
	
	qui replace eta_t_base = r(estimate) if ID == `i'

	qui replace upper_eta_base = r(ub) if ID == `i'

	qui replace lower_eta_base = r(lb) if ID == `i'
		
}

drop ID

replace eta_t_base = 0 if missing(eta_t_base)
replace upper_eta_base = 0 if missing(upper_eta_base)
replace lower_eta_base = 0 if missing(lower_eta_base)
replace eta_t_heat = 0 if missing(eta_t_heat)
replace upper_eta_heat = 0 if missing(upper_eta_heat)
replace lower_eta_heat = 0 if missing(lower_eta_heat)


collapse (mean) eta_t_heat eta_t_base upper_eta_heat upper_eta_base lower_eta_heat lower_eta_base, by(year)

tsset year, yearly 

keep if year < 2025

twoway (tsline eta_t_heat) (rcap lower_eta_heat upper_eta_heat year, lcolor(black)) (tsline eta_t_base) (rcap lower_eta_base upper_eta_base year, lcolor(black)), ytick(0(0.1)0.8) ylabel(0(0.1)0.8) xtick(2012(1)2024) xlabel(2012(1)2024) legend(rows(1) position(6) order(1 3 2) label(1 "Avg. Yearly Elasticity (Heating)") label(3 "Avg. Yearly Elasticity (Baseload)") label(2 "95% CIs")) name(heat)
graph export Base_Heat_Yearly_Elasticity_95_CI.png, as(png) replace 

restore

graph drop _all




***************************** PREDICTED CONSUMPTION ****************************

* Begin by running a model where we predict the coefficients on the historical data (i.e., before the crisis), and then use the estimated coefficients to predict consumption over the crisis. Then, use the Δ between actual and predicted consumption to measure savings.

ardl RDS HDD price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) lags(9 8 0)

estimates store my_ardl_model

forecast create myforecast, replace
forecast estimates my_ardl_model
forecast solve, prefix(predicted_) begin(td("01/12/2021"))

preserve

keep if Date >= td("01/12/2021")

gen int mdate = mofd(Date)

gen year = year(Date)

format mdate %tm

collapse (sum) RDS predicted_RDS, by(mdate)

tsset mdate, monthly

gen savings = predicted_RDS - RDS

tsline RDS predicted_RDS, legend(row(1) pos(6) label(1 "Actual Consumption") label(2 "Predicted Consumption")) name(g1, replace) xtitle("") ytitle("")
graph export g1.png, as(png) replace 

tsline savings, ytick(-300(100)900) ylabel(-300(100)900) name(g2, replace) xtitle("") ytitle("")
graph export g2.png, as(png) replace

restore


graph drop _all



* Placebo test on the whole sample.
preserve

gen int mdate = mofd(Date)

format mdate %tm

collapse (sum) RDS predicted_RDS, by(mdate)

tsset mdate

tsline RDS predicted_RDS, legend(row(1) pos(6) label(1 "Actual Consumption") label(2 "Predicted Consumption")) name(g1, replace) xtitle("") ytitle("")

restore

graph drop _all
drop predicted_RDS

}








********************************************************************************
************************************* TESTS ************************************
********************************************************************************

{

*********************************** CLEANING ***********************************

* Import the working database.
clear
*===============================================================================
* Complete with the file path to the daily data set.
*===============================================================================
import excel "",firstrow

*===============================================================================
* Set the working directory.
*===============================================================================
cd ""

* Rename the date variable for consistency with the code.
format date %tdDD/NN/CCYY
rename date Date

* Declare data to be time-series.
tsset Date, daily

* Label accordingly variables.
label variable Month_1 "January"
label variable Month_2 "February"
label variable Month_3 "March"
label variable Month_4 "April"
label variable Month_5 "May"
label variable Month_6 "June"
label variable Month_7 "July"
label variable Month_8 "August"
label variable Month_9 "September"
label variable Month_10 "October"
label variable Month_11 "November"
label variable Month_12 "December"

label variable Day_1 "Sunday"
label variable Day_2 "Monday"
label variable Day_3 "Tuesday"
label variable Day_4 "Wednesday"
label variable Day_5 "Thursday"
label variable Day_6 "Friday"
label variable Day_7 "Saturday"

label variable TimeTrend "Linear Time Trend"

label variable heating "Heating Consumption"
label variable baseload "Baseload Consumption"

* Initialize grouping variables that will be needed for the regressions to distinguish between the two different subsamples.
gen byte sample_pre_crisis = Date < td("01/12/2021")
gen byte sample_crisis = Date >= td("01/12/2021")


************************************* TESTS ************************************

gen Δprice = D.price_l3m

* Define your variable list
local varlist "RDS HDD SNSR price_l3m Δprice"

* Open file for writing LaTeX table
file open latex_table using "unitroot_table.tex", write replace

* Write LaTeX table header
file write latex_table "\begin{table}[htbp]" _n
file write latex_table "\centering" _n
file write latex_table "\caption{Unit Root Test Results}" _n
file write latex_table "\label{tab:unitroot}" _n
file write latex_table "\begin{tabular}{lcccccc}" _n
file write latex_table "\toprule" _n
file write latex_table "Variable & ADF Stat & ADF p-val & PP Stat & PP p-val & KPSS Stat & KPSS p-val \\" _n
file write latex_table "\midrule" _n

* Loop through variables and write results
foreach var of local varlist {
    display "Processing variable: `var'"
    
    * Run ADF test (Augmented Dickey-Fuller)
    quietly dfuller `var', regress
    local adf_stat = string(r(Zt), "%8.3f")
    local adf_pval = string(r(p), "%6.3f")
    
    * Run Phillips-Perron test
    quietly pperron `var', regress
    local pp_stat = string(r(Zt), "%8.3f")
    local pp_pval = string(r(p), "%6.3f")
    
    * Run KPSS test
    quietly kpss `var'
    local kpss_stat = string(r(kpss10), "%8.3f")
    local kpss_pval = string(r(p10), "%6.3f")
    
    * Handle missing p-values (replace with "--" if missing)
    if "`adf_pval'" == "." local adf_pval "--"
    if "`pp_pval'" == "." local pp_pval "--"
    if "`kpss_pval'" == "." local kpss_pval "--"
    
    * Write row to table
    file write latex_table "`var' & `adf_stat' & `adf_pval' & `pp_stat' & `pp_pval' & `kpss_stat' & `kpss_pval' \\" _n
}

* Write table footer
file write latex_table "\bottomrule" _n
file write latex_table "\end{tabular}" _n
file write latex_table "\begin{tablenotes}" _n
file write latex_table "\footnotesize" _n
file write latex_table "\item Notes: ADF = Augmented Dickey-Fuller test; PP = Phillips-Perron test; KPSS = Kwiatkowski-Phillips-Schmidt-Shin test." _n
file write latex_table "\item Null hypothesis for ADF and PP: variable has a unit root (non-stationary)." _n
file write latex_table "\item Null hypothesis for KPSS: variable is stationary." _n
file write latex_table "\end{tablenotes}" _n
file write latex_table "\end{table}" _n

* Close the file
file close latex_table

* Display completion message
display "LaTeX table saved as 'unitroot_table.tex'"
display "Variables processed: `varlist'"




*===============================================================================
* ARDL Bounds Test Table - F-statistic and 1% Confidence Level Bounds
*===============================================================================

set more off

// Create the LaTeX table file
file open boundstable using "ardl_bounds_1pct.tex", write replace

// Write table header
file write boundstable "\begin{table}[htbp]" _n
file write boundstable "\centering" _n
file write boundstable "\caption{ARDL Bounds Test Results: F-statistic and 1\% Confidence Level Bounds}" _n
file write boundstable "\label{tab:ardl_bounds_1pct}" _n
file write boundstable "\begin{tabular}{lccc}" _n
file write boundstable "\toprule" _n
file write boundstable "Model & F-statistic & Lower Bound (1\%) & Upper Bound (1\%) \\" _n
file write boundstable "\midrule" _n

*===============================================================================
* Model 1: Demand (pre-crisis sample)
*===============================================================================
quietly ardl RDS HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 1 1)
estat ectest

matrix bounds = r(cvmat)

local fstat_1 = string(e(F_pss), "%6.3f")
local lower_1 = string(bounds[1,5], "%5.2f")
local upper_1 = string(bounds[1,6], "%5.2f")

file write boundstable "Demand (pre-crisis sample) & `fstat_1' & `lower_1' & `upper_1' \\" _n

*===============================================================================
* Model 2: Demand (crisis sample)
*===============================================================================
quietly ardl RDS HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 1 0)
estat ectest

matrix bounds = r(cvmat)

local fstat_2 = string( e(F_pss), "%6.3f")
local lower_2 = string(bounds[1,5], "%5.2f")
local upper_2 = string(bounds[1,6], "%5.2f")

file write boundstable "Demand (crisis sample) & `fstat_2' & `lower_2' & `upper_2' \\" _n

*===============================================================================
* Model 3: Heating (pre-crisis sample)
*===============================================================================
quietly ardl heating HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(15 8 8 1)
estat ectest

matrix bounds = r(cvmat)

local fstat_3 = string( e(F_pss), "%6.3f")
local lower_3 = string(bounds[1,5], "%5.2f")
local upper_3 = string(bounds[1,6], "%5.2f")

file write boundstable "Heating (pre-crisis sample) & `fstat_3' & `lower_3' & `upper_3' \\" _n

*===============================================================================
* Model 4: Heating (crisis sample)
*===============================================================================
quietly ardl heating HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(9 8 0 0)
estat ectest

matrix bounds = r(cvmat)

local fstat_4 = string( e(F_pss), "%6.3f")
local lower_4 = string(bounds[1,5], "%5.2f")
local upper_4 = string(bounds[1,6], "%5.2f")

file write boundstable "Heating (crisis sample) & `fstat_4' & `lower_4' & `upper_4' \\" _n

*===============================================================================
* Model 5: Baseload (pre-crisis sample)
*===============================================================================
quietly ardl baseload HDD SNSR price_l3m if sample_pre_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(19 0 0 0)
estat ectest

matrix bounds = r(cvmat)

local fstat_5 = string( e(F_pss), "%6.3f")
local lower_5 = string(bounds[1,5], "%5.2f")
local upper_5 = string(bounds[1,6], "%5.2f")

file write boundstable "Baseload (pre-crisis sample) & `fstat_5' & `lower_5' & `upper_5' \\" _n

*===============================================================================
* Model 6: Baseload (crisis sample)
*===============================================================================
quietly ardl baseload HDD SNSR price_l3m if sample_crisis, bic trendvar exog(Month_2 Month_3 Month_4 Month_5 Month_6 Month_7 Month_8 Month_9 Month_10 Month_11 Month_12 Day_2 Day_3 Day_4 Day_5 Day_6 Day_7) ec lags(12 0 0 0)
estat ectest

matrix bounds = r(cvmat)

local fstat_6 = string( e(F_pss), "%6.3f")
local lower_6 = string(bounds[1,5], "%5.2f")
local upper_6 = string(bounds[1,6], "%5.2f")

file write boundstable "Baseload (crisis sample) & `fstat_6' & `lower_6' & `upper_6' \\" _n

*===============================================================================
* Close table and add notes
*===============================================================================
file write boundstable "\bottomrule" _n
file write boundstable "\end{tabular}" _n
file write boundstable "\begin{tablenotes}" _n
file write boundstable "\small" _n
file write boundstable "\item \textbf{Notes:} This table reports the computed F-statistic and the most extreme bounds for the F-statistic at the 1\% confidence level. " _n
file write boundstable "The bounds test evaluates the null hypothesis of no cointegration among the variables. " _n
file write boundstable "Critical values at the 1\% level represent the most stringent test for cointegration." _n
file write boundstable "\end{tablenotes}" _n
file write boundstable "\end{table}" _n

// Close file
file close boundstable

}
