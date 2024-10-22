{smcl}
{* *! version 1.0.0  22oct2024}{...}
{viewerjumpto "Syntax" "detectoutliers##syntax"}{...}
{viewerjumpto "Description" "detectoutliers##description"}{...}
{viewerjumpto "Options" "detectoutliers##options"}{...}
{viewerjumpto "Examples" "detectoutliers##examples"}{...}
{viewerjumpto "Stored Results" "detectoutliers##results"}{...}
{viewerjumpto "Methods" "detectoutliers##methods"}{...}
{title:Title}

{phang}
{bf:detectoutliers} {hline 2} Detect and handle outliers in numeric variables with trend analysis

{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmdab:detectoutliers} {varlist} {cmd:,} {opt met:hod(string)} [{it:options}]

{synoptset 25 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Required}
{synopt:{opt met:hod(string)}}specify outlier detection method; must be {bf:zscore} or {bf:iqr}{p_end}

{syntab:Optional}
{synopt:{opt act:ion(string)}}specify action to take; either {bf:flag} or {bf:remove}; default is {bf:flag}{p_end}
{synopt:{opt vis:ualize(string)}}specify visualization type; either {bf:scatter} or {bf:box}{p_end}
{synopt:{opt replace}}overwrite existing outlier variables{p_end}
{synopt:{opt force}}skip confirmation prompts{p_end}
{synopt:{opt nodropmissing}}include missing values in analysis{p_end}

{marker description}{...}
{title:Description}

{pstd}
{cmd:detectoutliers} identifies outliers in numeric variables using either Z-score or IQR (Interquartile Range) methods. 
The command first checks for significant trends in the data using regression analysis. If a trend is detected, 
the outlier detection is performed on detrended data to account for the temporal pattern.

{pstd}
For each variable, the command can either flag outliers (creating a new binary variable) or remove them from the dataset. 
The analysis can be visualized using scatter plots (showing trends and outliers) or box plots.

{marker options}{...}
{title:Options}

{dlgtab:Required}

{phang}
{opt method(string)} specifies the method for outlier detection. Must be either:

{phang2}
{cmd:zscore} Uses the Z-score method (> 3 standard deviations from mean)

{phang2}
{cmd:iqr} Uses the Interquartile Range method (> 1.5 IQR from quartiles)

{dlgtab:Optional}

{phang}
{opt action(string)} specifies what to do with detected outliers:

{phang2}
{cmd:flag} Creates a new binary variable {it:varname}_outlier (default)

{phang2}
{cmd:remove} Removes observations identified as outliers

{phang}
{opt visualize(string)} specifies the type of visualization:

{phang2}
{cmd:scatter} Shows a scatter plot with outliers highlighted

{phang2}
{cmd:box} Shows a box plot with outliers

{phang}
{opt replace} allows overwriting of existing outlier variables

{phang}
{opt force} skips confirmation prompts when overwriting variables

{phang}
{opt nodropmissing} includes missing values in the analysis (by default, missing values are excluded)

{marker examples}{...}
{title:Examples}

{pstd}Basic usage with z-score method{p_end}
{phang2}{cmd:. detectoutliers price, method(zscore)}{p_end}

{pstd}Using IQR method with visualization{p_end}
{phang2}{cmd:. detectoutliers price volume, method(iqr) visualize(scatter)}{p_end}

{pstd}Remove outliers and visualize results{p_end}
{phang2}{cmd:. detectoutliers price, method(zscore) action(remove) visualize(box)}{p_end}

{pstd}Multiple variables with replacement of existing outlier variables{p_end}
{phang2}{cmd:. detectoutliers price volume, method(iqr) replace}{p_end}

{pstd}Include missing values in analysis{p_end}
{phang2}{cmd:. detectoutliers price, method(zscore) nodropmissing}{p_end}

{marker methods}{...}
{title:Methods}

{pstd}
The command employs two methods for outlier detection:

{pstd}
1. {bf:Z-score method:} Points are considered outliers if they are more than 3 standard deviations from the mean. 
For trended data, this is applied to the residuals after detrending.

{pstd}
2. {bf:IQR method:} Points are considered outliers if they fall below Q1 - 1.5*IQR or above Q3 + 1.5*IQR, 
where IQR is the interquartile range. For trended data, this is applied to the residuals after detrending.

{pstd}
{bf:Trend Detection:}
The command automatically checks for trends using linear regression. If a significant trend is detected 
(p < 0.05), the outlier detection is performed on the detrended data.

{marker results}{...}
{title:Stored Results}

{pstd}
The command stores the following in {cmd:r()}:

{synoptset 20 tabbed}{...}
{p2col 5 20 24 2: Scalars}{p_end}
{synopt:{cmd:r(N_outliers)}}number of outliers detected{p_end}
{synopt:{cmd:r(pvalue)}}p-value from trend test{p_end}

{title:Author}

{pstd}
Your Name{break}
Your Institution{break}
Your Email{break}

{title:Also see}

{psee}
Online: {helpb sum}, {helpb regress}
{p_end}