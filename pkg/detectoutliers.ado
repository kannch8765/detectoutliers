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
        
        if !_rc & "`replace'" != "" {
            drop `var'_outlier
        }
        
        // Create observation index
        tempvar obs_index
        gen `obs_index' = _n
        
        // Initial summary for data checks
        qui summ `var', detail
        local initial_mean = r(mean)
        local initial_sd = r(sd)
        local initial_iqr = r(p75) - r(p25)
        
        // Check for trend using centered time variable
        tempvar time_c resid pred trend_removed
        qui {
            // Center time to improve numerical stability
            egen `time_c' = std(`obs_index')
            
            // Fit trend model
            reg `var' `time_c'
            predict `pred'
            predict `resid', residuals
            
            // Calculate trend significance
            local t = abs(_b[`time_c']/_se[`time_c'])
            local df = e(df_r)
            local pvalue = 2*ttail(`df',`t')
            local slope = _b[`time_c']
            
            // Calculate relative trend magnitude
            local trend_magnitude = abs(`slope'*r(sd)) / `initial_sd'
        }
        
        // Determine if trend is both statistically and practically significant
        if (`pvalue' < 0.05) & (`trend_magnitude' > 0.1) {
            di as text "Significant trend detected in `var', applying detrending"
            local use_detrended = 1
            gen `trend_removed' = `resid'
        }
        else {
            di as text "No significant trend detected in `var', using original values"
            local use_detrended = 0
            gen `trend_removed' = `var'
        }
        
        // Apply outlier detection to appropriate series
        if "`method'" == "zscore" {
            tempvar zscore
            qui egen `zscore' = std(`trend_removed')
            qui gen byte `var'_outlier = abs(`zscore') > 3 if !missing(`var')
            
            di as text "Using z-score method (threshold = 3)"
        }
        else {  // IQR method
            qui summ `trend_removed', detail
            local iqr = r(p75) - r(p25)
            
            if (`iqr' > 0) {
                local lower = r(p25) - 1.5 * `iqr'
                local upper = r(p75) + 1.5 * `iqr'
                qui gen byte `var'_outlier = (`trend_removed' < `lower' | `trend_removed' > `upper') ///
                    if !missing(`var')
                    
                di as text "Using IQR method (1.5 × IQR)"
            }
            else {
                di as error "Error: Zero IQR in data"
                exit 198
            }
        }
        
        // Label and report results
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
        // Check data type (discrete vs continuous)
        tempvar distinct_vals
        qui duplicates tag `var', gen(`distinct_vals')
        qui sum `distinct_vals'
        local n_distinct = r(max) + 1
        qui count
        local n_total = r(N)
        local discrete_data = `n_distinct' < `n_total' / 10
        
        // Report data characteristics
        if `discrete_data' {
            di as text "Detected discrete data with `n_distinct' unique values"
        }
        else {
            di as text "Detected continuous data"
        }

        // Visualization
        if "`visualize'" != "" {
            if "`visualize'" == "scatter" {
                if `discrete_data' {
                    // For discrete data, use special visualization
                    tempvar jitter_y freq
                    
                    // Calculate frequencies for sizing
                    bysort `var': gen `freq' = _N
                    qui sum `freq'
                    local max_freq = r(max)
                    
                    // Create minimal jitter for discrete data
                    qui {
                        summarize `var', detail
                        local range = r(max) - r(min)
                        local jitter_amount = `range' / 200  // Very small jitter
                        gen `jitter_y' = `var' + ///
                            (runiform(-`jitter_amount', `jitter_amount') * ///
                            (`freq'/`max_freq'))  // Scale jitter by frequency
                    }
                    
                    // Plot with frequency-based transparency
                    twoway (scatter `jitter_y' `obs_index' if `var'_outlier == 0, ///
                            msymbol(circle) mcolor(blue%20) msize(tiny)) ///
                           (scatter `jitter_y' `obs_index' if `var'_outlier == 1, ///
                            msymbol(circle) mcolor(red%40) msize(vsmall)), ///
                        legend(order(1 "Normal" 2 "Outlier")) ///
                        title("Scatter plot of `var' with Outliers Highlighted") ///
                        subtitle("(`n_distinct' unique values)") ///
                        ytitle("`var'") xtitle("Observation Number") ///
                        ylabel(, angle(0)) name(`var'_outliers, replace)
                }
                else {
                    // For continuous data, use regular scatter
                    twoway (scatter `var' `obs_index' if `var'_outlier == 0, ///
                            msymbol(circle) mcolor(blue%30) msize(tiny)) ///
                           (scatter `var' `obs_index' if `var'_outlier == 1, ///
                            msymbol(circle) mcolor(red%50) msize(vsmall)), ///
                        legend(order(1 "Normal" 2 "Outlier")) ///
                        title("Scatter plot of `var' with Outliers Highlighted") ///
                        ytitle("`var'") xtitle("Observation Number") ///
                        ylabel(, angle(0)) name(`var'_outliers, replace)
                }
                
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
    }
end