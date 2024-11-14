# detectoutliers: A Stata Command for Outlier Detection

## Overview
`detectoutliers` is a custom Stata command (requires Stata 14 or newer) designed to detect and handle outliers in numeric variables with automatic trend detection and data type recognition. It supports two popular methods for outlier detection:
- **Z-score**: Flags observations more than 3 standard deviations from the mean
- **IQR**: Flags observations outside 1.5 times the interquartile range (IQR)

## Features
- **Intelligent Data Analysis**:
  - Automatic trend detection and detrending
  - Automatic data type recognition (discrete, semi-discrete, continuous)
  - Handles missing values
- **Multiple Detection Methods**:
  - Z-score method (3 SD threshold)
  - IQR method (1.5 × IQR)
- **Flexible Handling Options**:
  - Flag outliers (creates `variable_outlier` indicator)
  - Remove outliers
- **Visualization Options**:
  - Scatter plots (with adaptive jittering for discrete data)
  - Box plots
  - Customized visualization based on data type
- **Comprehensive Reporting**:
  - Number and percentage of outliers
  - Threshold values
  - Distribution statistics for normal and outlier observations

## Syntax
```stata
detectoutliers varlist, method(zscore|iqr) [options]

Options:
    method(string)         required; specify "zscore" or "iqr"
    action(string)         optional; specify "flag" (default) or "remove"
    visualize(string)      optional; specify "scatter" or "box"
    replace               optional; replace existing outlier variables
    force                 optional; override certain safety checks
    nodropmissing        optional; include missing values in analysis
```