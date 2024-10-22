{smcl}
* help for detectoutliers
-------------------------------------------------------------------------------

Title
-------------------------------------------------------------------------------
detectoutliers -- Detect and handle outliers in numeric variables

Syntax
-------------------------------------------------------------------------------
    detectoutliers varlist, method(zscore|iqr) [action(flag|remove) visualize(scatter|box)]

Description
-------------------------------------------------------------------------------
The detectoutliers command identifies outliers in numeric variables using either 
the Z-score or IQR (Interquartile Range) method. Users can choose to flag outliers 
by generating a new variable or remove them from the dataset. Optional visualization 
of outliers can be displayed using scatter plots or box plots.

Options
-------------------------------------------------------------------------------
* method(zscore|iqr)    -- Required. Specify the method for outlier detection.
* action(flag|remove)   -- Optional. Flag or remove outliers (default: flag).
* visualize(scatter|box) -- Optional. Visualize the outliers with scatter or box plot.

Examples
-------------------------------------------------------------------------------
. detectoutliers income age, method(zscore) action(flag)
. detectoutliers income, method(iqr) action(remove) visualize(box)

Author
-------------------------------------------------------------------------------
Developed by: [Your Name]
