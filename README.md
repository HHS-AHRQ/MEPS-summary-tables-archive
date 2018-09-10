# MEPS summary tables

This repository contains the code needed to create the interactive **Medical Expenditure Panel Survey (MEPS) Household Component summary tables** found on the [MEPS website](https://meps.ahrq.gov/mepsweb/data_stats/quick_tables.jsp). The code is provided for researchers and developers interested in creating similar interactive tables, or in customizing the MEPS summary tables for personal use. The tables created from the code in this repository provide frequently used summary statistics at the national level for:
* Health care use, expenditures, and population characteristics
* Health insurance coverage
* Accessibility and quality of care
* Medical conditions
* Prescribed drug purchases



To run the tables on your local computer, first [download and install RStudio](https://www.rstudio.com/products/rstudio/download/). Then, install and load the Shiny package using the following code:
```
install.packages("shiny")
library(shiny)
```

Next, open the R programs from the [apps](apps) folder in RStudio, highlight the code and click **Run** or **Run App** (if available). Only one Shiny program can be run at a time in RStudio. Note that local links in the navigation bar will not work as expected when using Shiny to run the tables (an external server is needed).

## Code

The [R Programming language](https://www.r-project.org/) (version 3.3.3) was used as the statistical software to create survey statistics from raw MEPS data files and as a templating engine to build individual HTML files. [RStudio's Shiny](http://shiny.rstudio.com/) package was used as a local server to run the interactive tables.

The code for creating these tables is organized as follows:

* [apps](apps): Supplemental folder of RStudio Shiny apps for running the tables locally (no external server needed).
* [build_hc_tables](build_hc_tables): Folder containing code to create data tables from MEPS household component (HC) public use files (PUFs). Also contains R and SAS codes for creating the tables.
* [formatted_tables](formatted_tables): Contains formatted tables for each table series.
* [html](html): HTML templates needed to build index.html files.
* [mepstrends](mepstrends): Main directory containing all components needed to run the summary tables on a server (css, html, js, and json).
* [r](r): Functions, dictionaries, and notes for converting formatted tables to JSON data and building *index.html* files.

## Updating Household Component tables

Each year, after the MEPS full-year-consolidated (FYC) file is released, the following steps can be used to add data from the new year to the existing tables:

1. Update the R/SAS code snippets in [build_hc_tables/code](build_hc_tables/code). For example, the education variable changed in 2016, so the files [education.R](build_hc_tables/code/r/grps/education.R) and [education.sas](build_hc_tables/code/sas/grps/education.sas) were edited.

2. Add new PUF names to [meps_file_names.csv](https://github.com/HHS-AHRQ/MEPS/blob/master/Quick_Reference_Guides/meps_file_names.csv) on the main MEPS repository on the HHS-AHRQ GitHub site. Subsequent codes read this dataset to check file names of new years.

3. On [build_hc_tables/UPDATE.R](build_hc_tables/UPDATE.R), change *year_list* to the new year and *mydir* to a local directory on your computer where you want to store the PUF files.

4. Run [build_hc_tables/UPDATE.R](build_hc_tables/UPDATE.R) (takes approximately 3 hours for one year of data).

5. Test new data by running tables locally using R codes in the [apps](apps) folder.


## Survey background
The **Medical Expenditure Panel Survey (MEPS)**, which began in 1996, is a set of large-scale surveys of families and individuals, their medical providers (doctors, hospitals, pharmacies, etc.), and employers across the United States. The MEPS Household Component (MEPS-HC) survey collects information from families and individuals pertaining to medical expenditures, conditions, and events; demographics (e.g., age, ethnicity, and income); health insurance coverage; access to care; health status; and jobs held. The MEPS-HC is designed to produce national and regional estimates of the health care use, expenditures, sources of payment, and insurance coverage of the U.S. civilian noninstitutionalized population. The sample design of the survey includes weighting, stratification, clustering, multiple stages of selection, and disproportionate sampling.

## Public Domain Disclaimer

The **MEPS summary tables** application is a U.S. Government work developed by the Agency for Healthcare Research and Quality (AHRQ).  This application is in the public domain and may be used, reproduced, modified, built upon and distributed in the United States without further permission from AHRQ.  Reproduction and distribution for a fee is prohibited.  It is requested that in any subsequent use AHRQ be given appropriate acknowledgment.  The use of the HHS or AHRQ seal or logo without prior written authorization is expressly prohibited by law.  Although these data have been processed successfully on a computer system at AHRQ, no warranty expressed or implied is made regarding the accuracy or utility of the data on any other system or for general or scientific purposes, nor shall the act of distribution constitute any such warranty.  AHRQ has relinquished control of the information and no longer has responsibility to protect the integrity, confidentiality or availability of the information.  Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by AHRQ.  AHRQ reserves the right to assert copyright protection internationally.
