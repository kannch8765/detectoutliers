program define detectoutliers
    version 14
    
    syntax varlist(numeric), METHOD(string) [ACTION(string) VISUALIZE(string) ///
        REPLACE FORCE NODROPmissing]
    
    // Method validation
    if ("`method'" == "") {
        di as error "You must specify a method: zscore or iqr."
        exit 198
    }
    if ("`method'" != "zscore" & "`method'" != "iqr") {
        di as error "Invalid method: specify zscore or iqr."
        exit 198
    }
    
    // Set default action
    if "`action'" == "" local action "flag"
    if !inlist("`action'", "flag", "remove") {
        di as error "Invalid action: specify flag or remove"
        exit 198
    }
    
    // Visualization validation
    if "`visualize'" != "" & !inlist("`visualize'", "scatter", "box") {
        di as error "Invalid visualization option: specify scatter or box."
        exit 198
    }
    
    foreach var of varlist `varlist' {
        // Check for existing outlier variables
        capture confirm variable `var'_outlier
        if !_rc & "`replace'" == "" {
            di as error "`var'_outlier already exists. Use replace option to overwrite."
            exit 110
        }
        
        // Drop existing outlier variable if replace option specified
        if !_rc & "`replace'" != "" {
            drop `var'_outlier
        }
        
        // Create temporary variables for observation number and calculations
        tempvar obsnum resid pred
        gen `obsnum' = _n
        
        // Check for trend
        quietly regress `var' `obsnum'
        local t = abs(_b[`obsnum']/_se[`obsnum'])
        local df = e(df_r)
        local pvalue = 2*ttail(`df',`t')
        
        if (`pvalue' < 0.05) {
            di as text "Trend detected in `var', applying detrending method"
            
            quietly {
                predict `pred'
                predict `resid', residuals
                
                if "`method'" == "zscore" {
                    summarize `resid', detail
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
                    else if "`action'" == "remove" {
                        drop if abs(`resid' - `mean')/`sd' > 3 & !missing(`var')
                        di as text "Outliers in `var' removed using detrended Z-scores"
                    }
                }
                else {  // IQR method
                    summarize `resid', detail
                    local iqr = r(p75) - r(p25)
                    local lower = r(p25) - 1.5 * `iqr'
                    local upper = r(p75) + 1.5 * `iqr'
                    
                    if "`action'" == "flag" {
                        gen byte `var'_outlier = (`resid' < `lower' | `resid' > `upper') ///
                            if !missing(`var')
                        replace `var'_outlier = . if missing(`var') & "`nodropmissing'" == ""
                        label variable `var'_outlier "`var' outliers (detrended IQR)"
                        qui count if `var'_outlier == 1
                        di as text "Outliers in `var' flagged using IQR"
                        di as text "Number of outliers: " r(N)
                    }
                    else if "`action'" == "remove" {
                        drop if (`resid' < `lower' | `resid' > `upper') & !missing(`var')
                        di as text "Outliers in `var' removed using IQR"
                    }
                }
            }
        }
        else {
            di as text "No significant trend detected in `var', applying global method"
            
            quietly {
                if "`method'" == "zscore" {
                    summarize `var', detail
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
                    else if "`action'" == "remove" {
                        drop if abs((`var' - `mean')/`sd') > 3 & !missing(`var')
                        di as text "Outliers in `var' removed using global Z-scores"
                    }
                }
                else {  // IQR method
                    summarize `var', detail
                    local iqr = r(p75) - r(p25)
                    local lower = r(p25) - 1.5 * `iqr'
                    local upper = r(p75) + 1.5 * `iqr'
                    
                    if "`action'" == "flag" {
                        gen byte `var'_outlier = (`var' < `lower' | `var' > `upper') ///
                            if !missing(`var')
                        replace `var'_outlier = . if missing(`var') & "`nodropmissing'" == ""
                        label variable `var'_outlier "`var' outliers (global IQR)"
                        qui count if `var'_outlier == 1
                        di as text "Outliers in `var' flagged using IQR"
                        di as text "Number of outliers: " r(N)
                    }
                    else if "`action'" == "remove" {
                        drop if (`var' < `lower' | `var' > `upper') & !missing(`var')
                        di as text "Outliers in `var' removed using IQR"
                    }
                }
            }
        }

        // Visualization
        if "`visualize'" != "" {
            if "`visualize'" == "scatter" {
                twoway (scatter `var' `obsnum' if `var'_outlier == 0, msymbol(circle) mcolor(blue)) ///
                       (scatter `var' `obsnum' if `var'_outlier == 1, msymbol(circle) mcolor(red)), ///
                       legend(order(1 "Normal" 2 "Outlier")) ///
                       title("Scatter plot of `var' with Outliers Highlighted") ///
                       ytitle("`var'") xtitle("Observation Number")
            }
            else if "`visualize'" == "box" {
                graph box `var', ///
                    title("Box plot of `var' with Outliers")
            }
        }
    }
end