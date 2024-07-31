* Corey Jordan-Zamora;
* Wine Quality Project;

* ---------------(1 + 2) Import + Pre-processing Stages---------------;
PROC IMPORT datafile = "wine_quality.txt" out = wine replace; 
delimiter = '09'x; 
getnames = YES; 
datarow = 2;
RUN; 

TITLE "Wine Dataset";
PROC PRINT;
RUN;

* ---------------(3) Data Exploration Stage---------------;
TITLE "Descriptives of Wine Quality";
PROC MEANS n mean min p25 p50 p75 max std stderr;
var quality;
RUN;

TITLE "Histogram of Wine Quality";
PROC UNIVARIATE normal;
var quality;
histogram / normal (mu = est sigma = est);
RUN;

PROC SGSCATTER;
TITLE "Scatterplot Matrix for Wine Data - to See Association";
matrix quality fixed_acidity volatile_acidity citric_acid residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density pH sulphates alcohol;
RUN;

PROC CORR;
TITLE "Correlation Matrix for All Variables - to See Association";
var quality fixed_acidity volatile_acidity citric_acid residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density pH sulphates alcohol;
RUN;

* ---------------(4) Data Analysis Stage---------------;
* This is the full model so far, but we have got to check for the 3 diagnostics (multicollinearity, outliers, and influential points) to refit model as necessary;
* And then check for 4 model assumptions (linearity, constant variance, independence, and normality) on full model;
TITLE "Regression Model 1: Full Model";
PROC REG;
model quality = fixed_acidity volatile_acidity citric_acid residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density pH sulphates alcohol / vif influence r;
plot student.*(fixed_acidity volatile_acidity citric_acid residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density pH sulphates alcohol predicted.);
plot npp.*student.;
RUN;

TITLE "Proc Print - After Deleting Outliers and Inf. Points for Model 1";
DATA wine_removed; * Naming the new wine dataset this to indicate that it is the one with the removed observations;
set wine;
* Remove these observations: 46, 93, 152, 162, 282, 354, 391, 410, 441, 456, 460, 481, 653, 691, 724, 833, 834, 862, 900, 1080, 1082, 1091, 1234, 1236, 1277, 1300, 1320, 1375, 1404, 1435, 1436, 1479;
if _n_ in (46, 93, 152, 162, 282, 354, 391, 410, 441, 456, 460, 481, 653, 691, 724, 833, 834, 862, 900, 1080, 1082, 1091, 1234, 1236, 1277, 1300, 1320, 1375, 1404, 1435, 1436, 1479) then delete;
RUN;
TITLE "Proc Print - After Deleting Outliers and Inf. Points for Model 1";
PROC PRINT;
RUN;
* Should have 1567 observations read, since 1599 total - 32 removed = 1567 observations, which we do;
* Now, multicollinearity, outliers, and influential points have been addressed for the full model;

* Rerun model without the outliers and influential points - use new wine dataset, wine_removed;
TITLE "Regression Model 2: Full Model w/o Outliers and Influential Points";
PROC REG data = wine_removed;
model quality = fixed_acidity volatile_acidity citric_acid residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density pH sulphates alcohol / vif influence r;
plot student.*(fixed_acidity volatile_acidity citric_acid residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density pH sulphates alcohol predicted.);
plot npp.*student.;
RUN;

* Divide data between training and testing sets in order to move forward with creating a proper final model that we can later test (model validation);
* Create a new dataset wine2, which adds a column that shows the splitting of data between training and testing sets;
* Select training set consisting of 75% of cases and testing set with remaining 25% of cases; 
* surveyselect defines the "selected" variable that either has a value of 1 for cases in training set, or a value of 0 for cases in testing set, and saves data in the dataset wine2;
* I chose the random seed of 724881 as seen below;
TITLE "Training and Testing Sets for Wine Data";
PROC SURVEYSELECT data = wine_removed out = wine2 seed = 724881
samprate = 0.75 outall; * outall - Shows all the data selected (1) and not selected (0) for training;
RUN;

* Create new variable new_quality = quality for training set, and = NA for testing set;
DATA wine2;
set wine2;
if selected then new_quality = quality; * If selected = 1, assign new_quality = quality;
RUN;
PROC PRINT data = wine2;
RUN;

TITLE "Selection Method 1: Backward Selection Method. Model 3";
PROC REG data = wine2;
model new_quality = fixed_acidity volatile_acidity citric_acid residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density pH sulphates alcohol / selection = backward;
RUN;
* After I ran it, these were the variables left in the model (10 predictors remaining, and 1 variable removed):;
* fixed_acidity, volatile_acidity, citric_acid, residual_sugar, chlorides, free_sulfur_dioxide, total_sulfur_dioxide, density, sulphates, alcohol, so removed pH;
* R^2 value was 0.3849; 

TITLE "Selection Method 2: Adj R^2 Selection Method. Model 4";
PROC REG data = wine2;
model new_quality = fixed_acidity volatile_acidity citric_acid residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density pH sulphates alcohol / selection = adjrsq;
RUN;
/* I chose the second row instead of the first row in the output generated for the adj R^2 selection method, as both rows had the same adj R^2 value,
so it didn't really matter which one I chose,
so I chose row 2 with the one-less predictor as it made more business-sense (one less variable to keep track of).
Also, row 2 had the same R^2 value as the backwards selection method */
* After I ran it, these were the variables left in the model (10 predictors remaining, and 1 variable removed):;
* fixed_acidity, volatile_acidity, citric_acid, residual_sugar, chlorides, free_sulfur_dioxide, total_sulfur_dioxide, density, sulphates, alcohol, so removed pH;
* R^2 value was 0.3849;
* So overall, same model as backwards selection method, and we'll move forward with this model now that has 10 predictors;

TITLE "Regression Model 5";
PROC REG data = wine2;
model new_quality = fixed_acidity volatile_acidity citric_acid residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density sulphates alcohol / vif influence r;
plot student.*(fixed_acidity volatile_acidity citric_acid residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density sulphates alcohol predicted.);
plot npp.*student.;
RUN;

TITLE "Proc Print - After Deleting Outliers and Inf. Points for Model 5";
DATA wine2_removed;
set wine2;
* Remove these observations: 14, 434, 506, 622;
if _n_ in (14, 434, 506, 622) then delete;
RUN;
TITLE "Proc Print - After Deleting Outliers and Inf. Points for Model 5";
PROC PRINT;
RUN;
* Should have 1563 observations read, since 1567 total - 4 removed = 1563 observations, which we do;
* Now, multicollinearity, outliers, and influential points have been addressed for Model 5;

* Rerun model without the outliers and influential points - use new wine dataset, wine2_removed;
TITLE "Regression Model 6: Adjusted Model 5 w/o Outliers and Influential Points";
PROC REG data = wine2_removed;
model new_quality = fixed_acidity volatile_acidity citric_acid residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density sulphates alcohol / vif influence r;
plot student.*(fixed_acidity volatile_acidity citric_acid residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density sulphates alcohol predicted.);
plot npp.*student.;
RUN;

* However, after removing those points, I see that citric_acid became insignificant, as its p-value was 0.0575, which is greater than our alpha value at 0.05;
* So, I'm going to remove it from our Model 6, and now our model becomes:;
TITLE "Regression Model 7: Adjusted Model 6 w/o Insignificant Predictor";
PROC REG data = wine2_removed;
model new_quality = fixed_acidity volatile_acidity residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density sulphates alcohol / stb vif influence r;
plot student.*(fixed_acidity volatile_acidity residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density sulphates alcohol predicted.);
plot npp.*student.;
RUN;

* ---------------(5) Compute Predictions---------------;
* Compute predictions on new value;
TITLE "Compute Predictions";

* Create dataset with new value;
data pred;
input quality fixed_acidity volatile_acidity residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density sulphates alcohol; * Only do predictions on final model;
datalines;
. 13 0.9 5.8 0.225 20 157 0.9984 1.44 10.7
. 5.2 0.28 1.3 0.061 5 17 0.9933 0.48 9.1
;
RUN;
PROC PRINT;
RUN;

* Join/combine new dataset with original, well, edited dataset that had the removed outliers + influential points, wine_removed, since you want to use full dataset when computing predictions;
data prediction;
set pred wine_removed;
RUN;
PROC PRINT;
RUN;

* Compute regression analysis and confidence interval for average estimate;
PROC REG;
model quality = fixed_acidity volatile_acidity residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density sulphates alcohol / p clm cli;
RUN;

* ---------------(6) Testing---------------;
* Get predicted values for the missing new_quality in test set for final model (Model 7);
TITLE "Validation - Test Set";
PROC REG data = wine2_removed;
model new_quality = fixed_acidity volatile_acidity residual_sugar chlorides free_sulfur_dioxide total_sulfur_dioxide density sulphates alcohol;
* out = outm7 defines dataset containing Model 7 predicted values for test set;
output out = outm7 (where = (new_quality =.)) p = yhat; * Predicted y for test set for M7;
RUN;

PROC PRINT data = outm7;
RUN;

* Summarize the results of the cross-validations for M7;
TITLE "Difference between Observed and Predicted in Test Set";
DATA outm7_sum;
set outm7;
d = quality - yhat; * d is the difference between observed and predicted values in test set;
absd = abs(d);
RUN;

* Compute predictive statistics: root mean square error (rmse) and mean absolute error (mae);
PROC SUMMARY data = outm7_sum;
var d absd;
output out = outm7_stats std(d) = rmse mean(absd) = mae; * These two are the performance stats (RMSE and MAE);
RUN;
PROC PRINT data = outm7_stats;
TITLE "Validation Statistics for Model";
RUN;

* Compute correlation of observed and predicted values in test set;
PROC CORR data = outm7;
var quality yhat; * This computes R value for test set, which we will use this value to compute for R^2 value and CV R^2 value;
RUN;
