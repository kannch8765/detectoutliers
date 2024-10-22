# detectoutliers: A Stata Command for Outlier Detection

## Overview  
`detectoutliers` is a custom Stata command designed to detect and handle outliers in numeric variables. It supports two popular methods for outlier detection:
- **Z-score**: Flags observations more than 3 standard deviations from the mean.
- **IQR**: Flags observations outside 1.5 times the interquartile range (IQR).

This command allows users to:
- **Flag** or **remove** outliers.
- **Visualize** outliers using **scatter plots** or **box plots**.

---

## Features  
- Detect outliers using **Z-score** or **IQR** methods.  
- Choose between **flagging** or **removing** outliers.  
- Visualize results with **scatter plots** or **box plots** for better interpretation.  
- Supports **multiple numeric variables** at once.

---

## Syntax  
```stata
detectoutliers varlist, method(zscore|iqr) [action(flag|remove) visualize(scatter|box)]

Options
-method(zscore|iqr): Specify the outlier detection method.
-action(flag|remove): Choose whether to flag outliers (default) or remove them.
-visualize(scatter|box): Display results using scatter or box plots.

---
##Installation
Follow the steps below to install the detectoutliers command:

1. Locate Your Personal ADO Directory
In Stata, type the following command:

sysdir

You should see output like this:
   PERSONAL   /Users/yourname/ado/personal/
   PLUS       /Users/yourname/ado/plus/
Make a note of the PERSONAL directory path. This is where you will copy the command files.

2. Copy the Files to the Personal Directory
Navigate to the PERSONAL directory on your computer. Example paths:

Windows: C:\Users\yourname\ado\personal\
macOS: /Users/yourname/ado/personal/
Linux: /home/yourname/ado/personal/
If the personal folder doesn’t exist, create it manually.

Copy the following files into the PERSONAL directory:

detectoutliers.ado
detectoutliers.sthlp

3. Verify the Installation
Check if Stata recognizes the directory:
In Stata, type:

adopath

Ensure that the PERSONAL directory appears in the list of paths.

Test the Help File:
In Stata, type:

help detectoutliers

This should display the help documentation for the command.

---
##Run a Sample Command:
To confirm the command works, try:

detectoutliers income, method(zscore) action(flag) visualize(scatter)

This will flag outliers in the income variable and generate a scatter plot.

Usage Examples
Flag outliers using Z-score:
detectoutliers income, method(zscore) action(flag)

Remove outliers using IQR:
detectoutliers age, method(iqr) action(remove)

Visualize outliers using a box plot:
detectoutliers income, method(iqr) visualize(box)

Detect outliers for multiple variables:
detectoutliers income age, method(zscore) action(flag) visualize(scatter)

---
##Troubleshooting
Issue: Command Not Found
If Stata says the command is not recognized, try refreshing the ADO path:

clear all
adopath + "C:\Users\yourname\ado\personal\"  // Replace with your actual path

Issue: Help File Not Found
Ensure the detectoutliers.sthlp file is correctly placed in the same personal directory as the .ado file.
License


---
##
This command is distributed under the MIT License. Feel free to modify and redistribute it.


---
##
Author
Developed by: Li Minfeng
For questions, contact: E046339@u.nus.edu

