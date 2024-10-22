{smcl}
*! version 1.0.0
** {title:detectoutliers: Outlier Detection}

{p 8 12}{cmd:detectoutliers} {it:varlist}, {cmd:method(zscore|iqr)} [ {cmd:action(flag|remove)} ]

{title:Description}
The {cmd:detectoutliers} command detects outliers in a dataset using either the Z-score method or the Interquartile Range (IQR) method. Outliers can be flagged or removed based on the action chosen by the user.

{title:Syntax}
{p 8 12}{cmd:detectoutliers} {it:varlist}, {cmd:method(zscore|iqr)} [{cmd:action(flag|remove)}]

{title:Options}
{p 8 12}{cmd:method(zscore)}: Detects outliers using Z-scores (values more than 3 standard deviations away from the mean).
{p 8 12}{cmd:method(iqr)}: Detects outliers using the Interquartile Range (values outside 1.5*IQR from the 25th or 75th percentile).
{p 8 12}{cmd:action(flag)}: Flags the outliers by generating a new variable {cmd:_outlier} (default).
{p 8 12}{cmd:action(remove)}: Removes the outliers from the dataset.

{title:Examples}
{p 8 12}Detect and flag outliers in {cmd:var1} using Z-scores:
{p 8 12}{cmd:. detectoutliers var1, method(zscore)}

{p 8 12}Detect and remove outliers in {cmd:var2} using IQR:
{p 8 12}{cmd:. detectoutliers var2, method(iqr) action(remove)}
