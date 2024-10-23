program define detectoutliers
    version 14  
    
    syntax varlist(numeric) , METHOD(string) ///
        [ ACTION(string) ///
          VISualize(string) ///
          REPLACE ///
          FORCE ///
          NODROPmissing ]
    
    // Method validation
    if !inlist("`method'", "zscore", "iqr") {
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
        
        // Create temporary variables for analysis
        tempvar obsnum resid pred zscore
        qui gen `obsnum' = _n
        
        // Initial summary for sanity check
        qui summ `var', detail
        local initial_sd = r(sd)
        local initial_iqr = r(p75) - r(p25)
        
        // Check for trend
        qui regress `var' `obsnum'
        local t = abs(_b[`obsnum']/_se[`obsnum'])
        local df = e(df_r)
        local pvalue = 2*ttail(`df',`t')
        local slope = _b[`obsnum']
        
        // Only apply detrending if significant trend and meaningful slope
        if (`pvalue' < 0.05) & (abs(`slope') > `initial_sd'/1000) {
            di as text "Trend detected in `var', applying detrending method"
            
            qui {
                predict `pred'
                predict `resid', residuals
                
                if "`method'" == "zscore" {
                    // Generate z-scores from residuals
                    egen `zscore' = std(`resid')
                    gen byte `var'_outlier = abs(`zscore') > 3 if !missing(`var')
                }
                else {  // IQR method
                    summarize `resid', detail
                    local iqr = r(p75) - r(p25)
                    // Only proceed if IQR is non-zero
                    if (`iqr' > 0) {
                        local lower = r(p25) - 1.5 * `iqr'
                        local upper = r(p75) + 1.5 * `iqr'
                        gen byte `var'_outlier = (`resid' < `lower' | `resid' > `upper') ///
                            if !missing(`var')
                    }
                    else {
                        // Fall back to global method if IQR is zero
                        di as text "Warning: Zero IQR in residuals, falling back to global method"
                        local pvalue = 1  // Force global method
                    }
                }
            }
        }
        else {
            di as text "Using global method for `var'"
            
            qui {
                if "`method'" == "zscore" {
                    // Generate z-scores directly
                    egen `zscore' = std(`var')
                    gen byte `var'_outlier = abs(`zscore') > 3 if !missing(`var')
                }
                else {  // IQR method
                    summarize `var', detail
                    local iqr = r(p75) - r(p25)
                    if (`iqr' > 0) {
                        local lower = r(p25) - 1.5 * `iqr'
                        local upper = r(p75) + 1.5 * `iqr'
                        gen byte `var'_outlier = (`var' < `lower' | `var' > `upper') ///
                            if !missing(`var')
                    }
                    else {
                        di as error "Error: Zero IQR in data"
                        exit 198
                    }
                }
            }
        }
        
        // Label and summarize results
        label variable `var'_outlier "`var' outliers"
        qui count if `var'_outlier == 1
        local n_outliers = r(N)
        qui count if !missing(`var')
        local n_total = r(N)
        local pct_outliers = `n_outliers'/`n_total'*100
        
        di as text _newline "Results for `var':"
        di as text "Number of outliers: " as result `n_outliers'
        di as text "Percentage of outliers: " as result %5.1f `pct_outliers' "%"
        
        // Visualization
        if "`visualize'" == "scatter" {
            // Create jittered variables for better visualization
            tempvar jitter xjitter
            qui {
                // Add proportional random noise for y-axis
                summarize `var', detail
                local range = r(max) - r(min)
                local jitter_amount = `range' / 50  // Increased jitter amount
                gen `jitter' = `var' + (runiform(-`jitter_amount', `jitter_amount')) if !missing(`var')
                
                // Add proportional random noise for x-axis based on number of observations
                count
                local n_obs = r(N)
                local x_jitter = `n_obs' / 50
                gen `xjitter' = `obsnum' + (runiform(-`x_jitter', `x_jitter'))
            }
            
            // Enhanced scatter plot with better jittering and transparency
            twoway (scatter `jitter' `xjitter' if `var'_outlier == 0, ///
                    msymbol(circle) mcolor(blue%15) msize(tiny)) /// More transparency, smaller points
                (scatter `jitter' `xjitter' if `var'_outlier == 1, ///
                    msymbol(circle) mcolor(red%25) msize(vsmall)), /// More transparency
                legend(order(1 "Normal" 2 "Outlier")) ///
                title("Scatter plot of `var' with Outliers Highlighted") ///
                ytitle("`var'") xtitle("Observation Number") ///
                
                // Display distribution statistics
                di as text _newline "Distribution of normal observations:"
                summarize `var' if `var'_outlier == 0, detail
                di as text _newline "Distribution of outliers:"
                summarize `var' if `var'_outlier == 1, detail
            }

            else {  // box plot
                graph box `var', ///
                    title("Box plot of `var' with Outliers") ///
                    name(`var'_box, replace)
            }
        }
end