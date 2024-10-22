program define detectoutliers
    // Syntax: detectoutliers varlist, method(zscore|iqr) action(flag|remove)
    syntax varlist(numeric), METHOD(string) [ACTION(string)]

    // Check that a valid method has been provided
    if ("`method'" != "zscore" & "`method'" != "iqr") {
        di as error "Invalid method: specify zscore or iqr"
        exit 198
    }

    // Set action to "flag" if not specified
    if ("`action'" == "") local action "flag"

    foreach var of varlist `varlist' {
        // Detect outliers using Z-score method
        if ("`method'" == "zscore") {
            quietly summarize `var', meanonly
            local mean = r(mean)
            local sd = r(sd)
            // Flag or remove values that are more than 3 standard deviations away from the mean
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
            // Flag or remove values outside the IQR bounds
            if ("`action'" == "flag") {
                gen `var'_outlier = (`var' < `lower' | `var' > `upper')
                di as text "Outliers in `var' flagged using IQR"
            }
            else if ("`action'" == "remove") {
                drop if `var' < `lower' | `var' > `upper'
                di as text "Outliers in `var' removed using IQR"
            }
        }
    }
end
