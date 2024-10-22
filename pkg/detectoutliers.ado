program define detectoutliers
    version 14  // Specify Stata version for compatibility
    
    syntax varlist(numeric) , METHOD(string) [ACTION(string) VISUALIZE(string) ///
        Replace Force NODROPmissing]
    
    // Input validation
    if !inlist("`method'", "zscore", "iqr") {
        di as error "Invalid method: specify zscore or iqr"
        exit 198
    }
    
    // Set defaults
    if "`action'" == "" local action "flag"
    if !inlist("`action'", "flag", "remove") {
        di as error "Invalid action: specify flag or remove"
        exit 198
    }
    
    if "`visualize'" != "" & !inlist("`visualize'", "scatter", "box") {
        di as error "Invalid visualization: specify scatter or box"
        exit 198
    }
    
    // Check for existing outlier variables
    foreach var of varlist `varlist' {
        capture confirm variable `var'_outlier
        if !_rc & "`replace'" == "" {
            di as error "`var'_outlier already exists. Use replace option to overwrite."
            exit 110
        }
    }
    
    // Preserve original dataset if removing outliers
    if "`action'" == "remove" {
        preserve
    }
    
    // Process each variable
    foreach var of varlist `varlist' {
        // Check for missing values
        qui count if missing(`var')
        local nmiss = r(N)
        if `nmiss' > 0 {
            di as text "Warning: `var' has `nmiss' missing values"
            if "`nodropmissing'" == "" {
                di as text "Missing values will be excluded from analysis"
            }
            else {
                di as text "Analysis will include missing values due to nodropmissing option"
            }
        }
        
        // Drop existing outlier variable if replace option specified
        capture confirm variable `var'_outlier
        if !_rc & "`replace'" != "" {
            drop `var'_outlier
        }
        
        // Create temporary variables
        tempvar obs resid pred zscore
        gen `obs' = _n
        
        // Check for trend
        capture {
            quietly regress `var' `obs' if !missing(`var')
            local t = abs(_b[`obs']/_se[`obs'])
            local df = e(df_r)
            local pvalue = 2*ttail(`df',`t')
        }
        if _rc {
            di as error "Error in trend detection for `var'"
            exit _rc
        }
        
        // Main outlier detection
        if (`pvalue' < 0.05) {
            di as text "Trend detected in `var', applying detrending method"
            
            quietly {
                predict `pred'
                predict `resid', residuals
                
                if "`method'" == "zscore" {
                    // Z-score method on residuals
                    summarize `resid' if !missing(`var'), detail
                    local mean = r(mean)
                    local sd = r(sd)
                    
                    if "`action'" == "flag" {
                        gen byte `var'_outlier = abs(`resid' - `mean')/`sd' > 3 ///
                            if !missing(`var')
                        replace `var'_outlier = . if missing(`var') & "`nodropmissing'" == ""
                        
                        label variable `var'_outlier "`var' outliers (detrended z-score)"
                        qui count if `var'_outlier == 1
                        di as text "Outliers in `var' flagged using detrended Z-scores"
                        di as text "Number of outliers: " r(N)
                    }
                    else {  // remove
                        drop if abs(`resid' - `mean')/`sd' > 3 & !missing(`var')
                        di as text "Outliers in `var' removed using detrended Z-scores"
                    }
                }
                else {  // IQR method
                    summarize `resid' if !missing(`var'), detail
                    local iqr = r(p75) - r(p25)
                    local lower = r(p25) - 1.5 * `iqr'
                    local upper = r(p75) + 1.5 * `iqr'
                    
                    if "`action'" == "flag" {
                        gen byte `var'_outlier = (`resid' < `lower' | `resid' > `upper') ///
                            if !missing(`var')
                        replace `var'_outlier = . if missing(`var') & "`nodropmissing'" == ""
                        
                        label variable `var'_outlier "`var' outliers (detrended IQR)"
                        qui count if `var'_outlier == 1
                        di as text "Outliers in `var' flagged using detrended IQR"
                        di as text "Number of outliers: " r(N)
                    }
                    else {  // remove
                        drop if (`resid' < `lower' | `resid' > `upper') & !missing(`var')
                        di as text "Outliers in `var' removed using detrended IQR"
                    }
                }
            }
        }
        else {
            di as text "No significant trend detected in `var', applying global method"
            
            quietly {
                if "`method'" == "zscore" {
                    summarize `var' if !missing(`var'), detail
                    local mean = r(mean)
                    local sd = r(sd)
                    
                    if "`action'" == "flag" {
                        gen byte `var'_outlier = abs((`var' - `mean')/`sd') > 3 ///
                            if !missing(`var')
                        replace `var'_outlier = . if missing(`var') & "`nodropmissing'" == ""
                        
                        label variable `var'_outlier "`var' outliers (global z-score)"
                        qui count if `var'_outlier == 1
                        di as text "Outliers in `var' flagged using global Z-scores"
                        di as text "Number of outliers: " r(N)
                    }
                    else {  // remove
                        drop if abs((`var' - `mean')/`sd') > 3 & !missing(`var')
                        di as text "Outliers in `var' removed using global Z-scores"
                    }
                }
                else {  // IQR method
                    summarize `var' if !missing(`var'), detail
                    local iqr = r(p75) - r(p25)
                    local lower = r(p25) - 1.5 * `iqr'
                    local upper = r(p75) + 1.5 * `iqr'
                    
                    if "`action'" == "flag" {
                        gen byte `var'_outlier = (`var' < `lower' | `var' > `upper') ///
                            if !missing(`var')
                        replace `var'_outlier = . if missing(`var') & "`nodropmissing'" == ""
                        
                        label variable `var'_outlier "`var' outliers (global IQR)"
                        qui count if `var'_outlier == 1
                        di as text "Outliers in `var' flagged using global IQR"
                        di as text "Number of outliers: " r(N)
                    }
                    else {  // remove
                        drop if (`var' < `lower' | `var' > `upper') & !missing(`var')
                        di as text "Outliers in `var' removed using global IQR"
                    }
                }
            }
        }
        
        // Visualization with proper handling of missing values
        if "`visualize'" != "" {
            if "`visualize'" == "scatter" {
                twoway (scatter `var' `obs' if `var'_outlier == 0, ///
                        msymbol(circle) mcolor(blue)) ///
                       (scatter `var' `obs' if `var'_outlier == 1, ///
                        msymbol(circle) mcolor(red)) ///
                       (scatter `var' `obs' if missing(`var'_outlier), ///
                        msymbol(triangle) mcolor(gray)), ///
                       legend(order(1 "Normal" 2 "Outlier" 3 "Missing")) ///
                       title("Scatter plot of `var' with Outliers Highlighted") ///
                       ytitle("`var'") xtitle("Observation Number")
            }
            else if "`visualize'" == "box" {
                graph box `var' if !missing(`var'), ///
                    title("Box plot of `var' with Outliers")
            }
        }
    }
    
    // Restore original dataset if removing outliers
    if "`action'" == "remove" {
        restore, not
    }
end