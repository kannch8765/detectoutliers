# Outlier Detection Package

This package includes a command `detectoutliers` that allows users to detect outliers using the Z-score or IQR method. The outliers can be flagged or removed from the dataset.

## Installation
1. Copy the `detectoutliers.ado` and `detectoutliers.sthlp` files into your Stata `ADO` directory (e.g., C:\Users\YourName\Documents\Stata\ado\personal\ on Windows).
2. You can then use the command in Stata like this:
. detectoutliers varlist, method(zscore|iqr) [action(flag|remove)]

## Usage
- To detect outliers using Z-scores and flag them:
detectoutliers var1, method(zscore) action(flag)
- To detect outliers using IQR and remove them:
detectoutliers var2, method(iqr) action(remove)