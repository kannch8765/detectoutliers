program define detectoutliers
    version 14  
    
    syntax varlist(numeric) , METHOD(string) ///
        [ ACTION(string) ///
          VISualize(string) ///
          REPLACE ///
          FORCE ///
          NODROPmissing ]
    
    // [Previous validation code remains the same until the foreach loop]
    
    foreach var of varlist `varlist' {
        // [Previous variable checks remain the same]
        
        // Check data type before processing
        tempvar distinct_vals
        qui duplicates tag `var', gen(`distinct_vals')
        qui sum `distinct_vals'
        local n_distinct = r(max) + 1
        qui count
        local n_total = r(N)
        // Adjust threshold - if more than 100 unique values, treat as continuous
        local discrete_data = `n_distinct' < 100
        
        // Store original values for plotting
        tempvar original_values
        qui gen `original_values' = `var'
        
        // [Previous trend detection code remains the same until outlier detection]
        
        // Apply outlier detection to appropriate series and store results
        tempvar outlier_indicator
        if "`method'" == "zscore" {
            tempvar zscore
            qui egen `zscore' = std(`trend_removed')
            qui gen byte `outlier_indicator' = abs(`zscore') > 3 if !missing(`var')
            
            // Store thresholds for reporting
            local upper_threshold = `initial_mean' + 3*`initial_sd'
            local lower_threshold = `initial_mean' - 3*`initial_sd'
            
            di as text "Using z-score method (threshold = 3)"
        }
        else {  // IQR method
            qui summ `trend_removed', detail
            local iqr = r(p75) - r(p25)
            
            if (`iqr' > 0) {
                local lower_threshold = r(p25) - 1.5 * `iqr'
                local upper_threshold = r(p75) + 1.5 * `iqr'
                qui gen byte `outlier_indicator' = ///
                    (`trend_removed' < `lower_threshold' | `trend_removed' > `upper_threshold') ///
                    if !missing(`var')
                    
                di as text "Using IQR method (1.5 × IQR)"
            }
            else {
                di as error "Error: Zero IQR in data"
                exit 198
            }
        }
        
        // Generate final outlier indicator variable
        qui gen byte `var'_outlier = `outlier_indicator'
        label variable `var'_outlier "`var' outliers"
        
        // Report results and thresholds
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
        
        if `discrete_data' {
            di as text "Detected discrete data with `n_distinct' unique values"
        }
        else if `n_distinct' > 100 & `n_distinct' < `n_total' / 10 {
            di as text "Detected semi-discrete data with `n_distinct' unique values"
        }
        else {
            di as text "Detected continuous data"
        }
        
        // Visualization
        if "`visualize'" != "" {
            if "`visualize'" == "scatter" {
                if `discrete_data' {
                    // For truly discrete data
                    tempvar jitter_y freq
                    
                    // Calculate frequencies for sizing
                    bysort `var': gen `freq' = _N
                    qui sum `freq'
                    local max_freq = r(max)
                    
                    // Jitter proportional to frequency
                    qui {
                        local jitter_amount = (`upper_threshold' - `lower_threshold') / 100
                        gen `jitter_y' = `original_values' + ///
                            (runiform(-`jitter_amount', `jitter_amount') * ///
                            (`freq'/`max_freq'))
                    }
                    
                    // Plot with frequency-based transparency
                    twoway (scatter `jitter_y' `obs_index' if `var'_outlier == 0, ///
                            msymbol(circle) mcolor(blue%30) msize(tiny)) ///
                           (scatter `jitter_y' `obs_index' if `var'_outlier == 1, ///
                            msymbol(circle) mcolor(red%50) msize(vsmall)), ///
                        legend(order(1 "Normal" 2 "Outlier")) ///
                        title("Scatter plot of `var' with Outliers Highlighted") ///
                        subtitle("(`n_distinct' unique values)") ///
                        ytitle("`var'") xtitle("Observation Number") ///
                        ylabel(, angle(0)) name(`var'_outliers, replace)
                }
                else if `n_distinct' > 100 & `n_distinct' < `n_total' / 10 {
                    // For age-like variables (many unique values but still discrete)
                    twoway (scatter `original_values' `obs_index' if `var'_outlier == 0, ///
                            msymbol(circle) mcolor(blue%5) msize(vtiny)) ///
                           (scatter `original_values' `obs_index' if `var'_outlier == 1, ///
                            msymbol(circle) mcolor(red%20) msize(tiny)), ///
                        legend(order(1 "Normal" 2 "Outlier")) ///
                        title("Scatter plot of `var' with Outliers Highlighted") ///
                        subtitle("(`n_distinct' unique values)") ///
                        ytitle("`var'") xtitle("Observation Number") ///
                        ylabel(, angle(0)) name(`var'_outliers, replace)
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
                        ylabel(, angle(0)) name(`var'_outliers, replace)
                }
            }
            else {  // box plot
                graph box `var', ///
                    title("Box plot of `var' with Outliers") ///
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