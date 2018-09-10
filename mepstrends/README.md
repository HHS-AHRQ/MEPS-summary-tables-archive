## mepstrends

This folder contains all components necessary for running the interactive tables on a web server. To run the tables locally (i.e. without an external server), you must run the R codes in the [apps](../apps) folder. Note that links between apps in the navigation bar will not work if running locally.

The [home](home) folder contains the **index.html** file for the main landing page for the MEPS summary tables.

The [src](src) folder contains the css, img, and js files read by each web page. AHRQ branding elements are omitted from the published version on GitHub.

The following folders each represent a separate summary table as follows:
* [hc_care](hc_care): Accessibility and quality of care
* [hc_cond](hc_cond): Medical conditions
* [hc_ins](hc_ins): Health insurance
* [hc_pmed](hc_pmed): Prescribed drugs
* [hc_use](hc_use): Use, expenditures, and population

Each of these folders contains an **index.html** file (created by [RtoHTML.R](../r/RtoHTML.R)) and a **json** folder (created by [RtoJSON.R](../r/RtoJSON.R)) containing initial javascript variables (init.js), R and SAS codes (**code** folder) and json data for each selected table (**data** folder).
