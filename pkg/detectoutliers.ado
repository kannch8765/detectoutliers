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
        
        // Set missing value condition
        if "`nodropmissing'" == "" {
            local missing_cond "& !missing(`var')"
        }
        else {
            local missing_cond ""
        }
        
        // Create observation index and store original values
        tempvar obs_index original_values
        gen `obs_index' = _n
        gen `original_values' = `var'
        
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
        
        // Check data type
        tempvar distinct_vals
        qui duplicates tag `var', gen(`distinct_vals')
        qui sum `distinct_vals'
        local n_distinct = r(max) + 1
        qui count
        local n_total = r(N)
        
        // Define data type thresholds with explicit numeric comparisons
        local DISCRETE_THRESHOLD 100
        local SEMI_DISCRETE_RATIO 10
        local semi_discrete_bound = floor(`n_total'/`SEMI_DISCRETE_RATIO')
        
        // Determine data type
        if `n_distinct' <= `DISCRETE_THRESHOLD' {
            local data_type "discrete"
            di as text "Detected discrete data with `n_distinct' unique values"
        }
        else if `n_distinct' <= `semi_discrete_bound' {
            local data_type "semi-discrete"
            di as text "Detected semi-discrete data with `n_distinct' unique values"
        }
        else {
            local data_type "continuous"
            di as text "Detected continuous data"
        }
        
        // Apply outlier detection with better error handling
        tempvar outlier_indicator
        if "`method'" == "zscore" {
            tempvar zscore
            qui {
                egen `zscore' = std(`trend_removed')
                gen byte `outlier_indicator' = 0
                replace `outlier_indicator' = 1 if abs(`zscore') > 3 `missing_cond'
                
                // Store thresholds for reporting
                local upper_threshold = `initial_mean' + 3*`initial_sd'
                local lower_threshold = `initial_mean' - 3*`initial_sd'
            }
            
            di as text "Using z-score method (threshold = 3)"
        }
        else {  // IQR method
            qui {
                summ `trend_removed', detail
                local iqr = r(p75) - r(p25)
                
                if (`iqr' <= 0) {
                    di as error "Error: Zero or negative IQR in data"
                    exit 198
                }
                
                local lower_threshold = r(p25) - 1.5 * `iqr'
                local upper_threshold = r(p75) + 1.5 * `iqr'
                
                gen byte `outlier_indicator' = 0
                replace `outlier_indicator' = 1 if ///
                    (`trend_removed' < `lower_threshold' | ///
                     `trend_removed' > `upper_threshold') `missing_cond'
            }
            
            di as text "Using IQR method (1.5 × IQR)"
        }
        
        // Generate final outlier indicator
        qui gen byte `var'_outlier = `outlier_indicator'
        label variable `var'_outlier "`var' outliers"
        
        // Report results
        qui count if `var'_outlier == 1
        local n_outliers = r(N)
        qui count if !missing(`var')
        local n_total = r(N)
        local pct_outliers = `n_outliers'/`n_total'*100
        
        di as text _newline "Results for `var':"
        di as text "Number of outliers: " as result `n_outliers'
        di as text "Percentage of outliers: " as result %5.1f `pct_outliers' "%"
        di as text "Outlier thresholds:"
        di as text "  Lower: " as result %8.2f `lower_threshold'
        di as text "  Upper: " as result %8.2f `upper_threshold'
        
        // Visualization
        if "`visualize'" != "" {
            if "`visualize'" == "scatter" {
                if "`data_type'" == "discrete" {
                    // For truly discrete data
                    tempvar jitter_y freq
                    
                    // Calculate frequencies with error checking
                    qui {
                        bysort `var': gen `freq' = _N
                        sum `freq'
                        if r(N) == 0 {
                            di as error "Error: No valid frequencies calculated"
                            exit 198
                        }
                        local max_freq = r(max)
                        
                        // Safer jitter calculation
                        local jitter_amount = max((`upper_threshold' - `lower_threshold') / 100, 0.0001)
                        gen `jitter_y' = `original_values' + ///
                            (runiform(-`jitter_amount', `jitter_amount') * ///
                            (`freq'/`max_freq'))
                    }
                    
                    // Plot with improved aesthetics
                    twoway (scatter `jitter_y' `obs_index' if `var'_outlier == 0, ///
                            msymbol(circle) mcolor(blue%30) msize(tiny)) ///
                           (scatter `jitter_y' `obs_index' if `var'_outlier == 1, ///
                            msymbol(circle) mcolor(red%50) msize(vsmall)), ///
                        legend(order(1 "Normal" 2 "Outlier")) ///
                        title("Scatter plot of `var' with Outliers Highlighted") ///
                        subtitle("(`n_distinct' unique values)") ///
                        ytitle("`var'") xtitle("Observation Number") ///
                        ylabel(, angle(0) grid) ///
                        xlabel(, grid) ///
                        graphregion(color(white)) ///
                        name(`var'_outliers, replace)
                }
                else if "`data_type'" == "semi-discrete" {
                    // For age-like variables
                    twoway (scatter `original_values' `obs_index' if `var'_outlier == 0, ///
                            msymbol(circle) mcolor(blue%5) msize(vtiny)) ///
                           (scatter `original_values' `obs_index' if `var'_outlier == 1, ///
                            msymbol(circle) mcolor(red%20) msize(tiny)), ///
                        legend(order(1 "Normal" 2 "Outlier")) ///
                        title("Scatter plot of `var' with Outliers Highlighted") ///
                        subtitle("(`n_distinct' unique values)") ///
                        ytitle("`var'") xtitle("Observation Number") ///
                        ylabel(, angle(0) grid) ///
                        xlabel(, grid) ///
                        graphregion(color(white)) ///
                        name(`var'_outliers, replace)
                }
                else {
                    // For continuous data
                    twoway (scatter `original_values' `obs_index' if `var'_outlier == 0, ///
                            msymbol(circle) mcolor(blue%30) msize(tiny)) ///
                           (scatter `original_values' `obs_index' if `var'_outlier == 1, ///
                            msymbol(circle) mcolor(red%50) msize(vsmall)), ///
                        legend(order(1 "Normal" 2 "Outlier")) ///
                        title("Scatter plot of `var' with Outliers Highlighted") ///
                        ytitle("`var'") xtitle("Observation Number") ///
                        ylabel(, angle(0) grid) ///
                        xlabel(, grid) ///
                        graphregion(color(white)) ///
                        name(`var'_outliers, replace)
                }
            }
            else {  // box plot
                graph box `var', ///
                    title("Box plot of `var' with Outliers") ///
                    graphregion(color(white)) ///
                    name(`var'_box, replace)
            }
            
            // Display distribution statistics
            di as text _newline "Distribution of normal observations:"
            summarize `var' if `var'_outlier == 0, detail
            if `n_outliers' > 0 {
                di as text _newline "Distribution of outliers:"
                summarize `var' if `var'_outlier == 1, detail
            }
        }
    }
end