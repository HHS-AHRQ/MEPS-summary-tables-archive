## build_hc_tables

This folder contains code to create summary data tables from MEPS household component (HC) public use files (PUFs).

To create / update the tables, open [UPDATE.R](UPDATE.R) in RStudio and edit the *year_list* variable to include the years you want to run, and set the *mydir* variable to a local directory where you want to store the PUF .ssp files. This code then sources other R codes as follows:

1. **build_codes.R**: Pulls R and SAS code outlines for each table series from **codelist_r.R** and **codelist_sas.R** to create complete codes for each statistic and group option ('year' is left as a macro variable). Code outlines are created from code snippets stored in the [code](code) folder.

2. **transfer_pufs.R**: Reads PUF names from  [meps_file_names.csv](https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_file_names.csv) on the main MEPS repository on the HHS-AHRQ GitHub site, downloads them from the MEPS website, and stores them in *mydir*.

3. **tables_run.R**: Runs new tables for each table series.

4. **check_UPDATE.R**: Compares data tables from the new year to previous years to identify anomalies.

5. **tables_format.R**: Formats data tables and stores them in the [formatted_tables](../formatted_tables) directory.

6. **../r/Update_master.R**: Combines formatted tables and stores as an .Rdata object for faster loading..

7. **../r/RtoHTML.R**: Creates index.html files for each table series.

8. **../r/RtoJSON.R**: Creates JSON files for each table series

The final codes are saved in the [mepstrends](../mepstrends) folder to be read and displayed on the interactive tables webpage.
