## code

This folder contains snippets of [R](r) and [SAS](sas) codes for displaying code on the summary tables web page. The R codes are also used in [tables_run.R](../r/tables_run.R) to create the summary table csv files.

### R
The following subfolders are located in the [R](r) directory:
* [dsgn](r/dsgn): survey design objects needed to analyze survey data
* [grps](r/grps): code to define human-readable grouping variables from variables on the MEPS public use files (e.g. age groups, region, health status)
* [load](r/load): code snippets needed to read in .ssp files and merge datasets prior to running survey analyses
* [stats_use](r/stats_use): Code specific to the use and expenditures tables. Most of these 'svyby' codes are located in [codes.R](../r/codes.R). The 'svyby' codes for these statistics are more complex, thus they have a separate folder.

### SAS
The following subfolders are located in the [SAS](sas) directory:
* [grps](sas/grps): code to define human-readable grouping variables from variables on the MEPS public use files (e.g. age groups, region, health status)
* [load](sas/load): code snippets needed to read in .ssp files and merge datasets prior to running survey analyses
* [stats_care](sas/stats_care): PROC SURVEY code snippets pertaining to the **Accessibility and quality of care** tables.
* [stats_cond](sas/stats_cond): PROC SURVEY code snippets pertaining to the **Medical conditions** tables, with separate codes when stratified by event or source of payment (sop)
* [stats_ins](sas/stats_ins): PROC SURVEY code snippets pertaining to the **Health insurance** tables.
* [stats_pmed](sas/stats_pmed): PROC SURVEY code snippets pertaining to the **Prescribed drugs** tables, with separate codes when stratified by therapeutic class (TC1name) or generic drug name (RXDRGNAM).
* [stats_use](sas/stats_use): PROC SURVEY code snippets pertaining to the **Use, expenditures, and population** tables, with separate codes when stratified by event type, source of payment (sop), or both
