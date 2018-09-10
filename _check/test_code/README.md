## test_code

Warning! -- these instructions are probably outdated

The following steps can be used to compare the displayed R and SAS codes with the stored .csv tables:
1. Run [rselenium.R](rselenium.R) to create displayed codes based on a subset of selected options and store them in **r_codes** and **sas_codes** folders for each table series. Note that 'Cross-sectional' and 'Code' must be selected by hand on the web page.
2. Run [test_r_codes.R](test_r_codes.R) and [test_sas_codes.sas](test_sas_codes.sas) to read in the stored .R and .sas codes, and output results to new .csv files in the **r_results** and **sas_results** folders for each table series.
3. Run [compare_tables.R](compare_tables.R) to read in each new .csv file and compare with existing .csv tables from the [tables](../../tables) folder. Note that median estimates created by SAS will be different from stored tables (created by R), because SAS and R  use different methods to calculate medians for survey data.
