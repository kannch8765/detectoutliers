program define detectoutliers
    // Syntax: detectoutliers varlist, method(zscore|iqr) action(flag|remove) visualize(scatter|box)
    syntax varlist(numeric), METHOD(string) [ACTION(string) VISUALIZE(string)]

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
        // Detect outliers using Z-score method
        if ("`method'" == "zscore") {
            quietly summarize `var', meanonly
            local mean = r(mean)
            local sd = r(sd)
            
            if ("`action'" == "flag") {
                gen `var'_outlier = abs(`var' - `mean') / `sd' > 3
                di as text "Outliers in `var' flagged using Z-scores"
            }
            else if ("`action'" == "remove") {
                drop if abs(`var' - `mean') / `sd' > 3
                di as text "Outliers in `var' removed using Z-scores"
            }
        }

        // Detect outliers using IQR method
        else if ("`method'" == "iqr") {
            quietly summarize `var', detail
            local iqr = r(p75) - r(p25)
            local lower = r(p25) - 1.5 * `iqr'
            local upper = r(p75) + 1.5 * `iqr'

            if ("`action'" == "flag") {
                gen `var'_outlier = (`var' < `lower' | `var' > `upper')
                di as text "Outliers in `var' flagged using IQR"
            }
            else if ("`action'" == "remove") {
                drop if `var' < `lower' | `var' > `upper'
                di as text "Outliers in `var' removed using IQR"
            }
        }

        // Visualization options
        if ("`visualize'" == "scatter") {
            scatter `var' _n if !missing(`var'), ///
                msymbol(circle) mcolor(blue) ///
                legend(off) title("Scatter plot of `var'")
        }
        else if ("`visualize'" == "box") {
            graph box `var', ///
                title("Box plot of `var' with Outliers")
        }
    }
end
