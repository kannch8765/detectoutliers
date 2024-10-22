program define detectoutliers
    // Syntax: detectoutliers varlist, method(zscore|iqr) action(flag|remove) visualize(scatter|box) window(#)
    syntax varlist(numeric), METHOD(string) [ACTION(string) VISUALIZE(string) WINDOW(int)]

    // Default to a window of 30 periods for rolling calculations if not specified
    if ("`window'" == "") local window 30

    // Check that a valid method has been provided
    if ("`method'" != "zscore" & "`method'" != "iqr") {
        di as error "Invalid method: specify zscore or iqr"
        exit 198
    }

    // Set action to "flag" if not specified
    if ("`action'" == "") local action "flag"

    // Check for valid visualization option, if provided
    if ("`visualize'" != "" & "`visualize'" != "scatter" & "`visualize'" != "box") {
        di as error "Invalid visualization: specify scatter or box"
        exit 198
    }

    foreach var of varlist `varlist' {
        // Check for a trend in the data using linear regression on time (index variable _n)
        gen _n = _n  // Generate a time variable for trend detection if not present
        regress `var' _n
        local slope = _b[_n]       // Slope of the regression
        local pvalue = _p[_n]      // P-value of the slope

        // If p-value < 0.05, we consider the trend to be significant
        if (`pvalue' < 0.05) {
            // A significant trend is detected, apply rolling window method
            di as text "Trend detected in `var', applying rolling window method"

            // Z-score method with rolling mean and standard deviation
            if ("`method'" == "zscore") {
                gen `var'_mean = runmean(`var', `window')
                gen `var'_sd = runsd(`var', `window')

                if ("`action'" == "flag") {
                    gen `var'_outlier = abs(`var' - `var'_mean) / `var'_sd > 3
                    di as text "Outliers in `var' flagged using rolling Z-scores"
                }
                else if ("`action'" == "remove") {
                    drop if abs(`var' - `var'_mean) / `var'_sd' > 3
                    di as text "Outliers in `var' removed using rolling Z-scores"
                }
            }
            // IQR method with rolling window percentiles
            else if ("`method'" == "iqr") {
                gen `var'_p25 = runquantile(`var', 25, `window')
                gen `var'_p75 = runquantile(`var', 75, `window')
                gen `var'_iqr = `var'_p75 - `var'_p25
                gen `var'_lower = `var'_p25 - 1.5 * `var'_iqr
                gen `var'_upper = `var'_p75 + 1.5 * `var'_iqr

                if ("`action'" == "flag") {
                    gen `var'_outlier = (`var' < `var'_lower' | `var' > `var'_upper')
                    di as text "Outliers in `var' flagged using rolling IQR"
                }
                else if ("`action'" == "remove") {
                    drop if `var' < `var'_lower' | `var' > `var'_upper'
                    di as text "Outliers in `var' removed using rolling IQR"
                }
            }
        }
        else {
            // No significant trend, apply global method
            di as text "No significant trend detected in `var', applying global method"

            // Z-score method with global mean and standard deviation
            if ("`method'" == "zscore") {
                quietly summarize `var', meanonly
                local mean = r(mean)
                local sd = r(sd)

                if ("`action'" == "flag") {
                    gen `var'_outlier = abs(`var' - `mean') / `sd' > 3
                    di as text "Outliers in `var' flagged using global Z-scores"
                }
                else if ("`action'" == "remove") {
                    drop if abs(`var' - `mean') / `sd' > 3
                    di as text "Outliers in `var' removed using global Z-scores"
                }
            }
            // IQR method with global percentiles
            else if ("`method'" == "iqr") {
                quietly summarize `var', detail
                local iqr = r(p75) - r(p25)
                local lower = r(p25) - 1.5 * `iqr'
                local upper = r(p75) + 1.5 * `iqr'

                if ("`action'" == "flag") {
                    gen `var'_outlier = (`var' < `lower' | `var' > `upper')
                    di as text "Outliers in `var' flagged using global IQR"
                }
                else if ("`action'" == "remove") {
                    drop if `var' < `lower' | `var' > `upper'
                    di as text "Outliers in `var' removed using global IQR"
                }
            }
        }

        // Visualization options
        if ("`visualize'" == "scatter") {
            // Scatter plot with outliers colored differently
            twoway (scatter `var' _n if `var'_outlier == 0, msymbol(circle) mcolor(blue)) ///
                   (scatter `var' _n if `var'_outlier == 1, msymbol(circle) mcolor(red)), ///
                   legend(off) title("Scatter plot of `var' with Outliers Highlighted")
        }
        else if ("`visualize'" == "box") {
            // Box plot with outliers colored differently (Stata doesn't support color for individual outliers in box plot)
            graph box `var', ///
                title("Box plot of `var' with Outliers")
        }
    }
end
