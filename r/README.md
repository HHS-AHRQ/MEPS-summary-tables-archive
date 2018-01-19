## r

This folder contains functions, dictionaries, and programs for creating .csv tables, **index.html** files, javascript variables and json files.

[RtoHTML.R](RtoHTML.R): Creates **index.html** files for the [home page](../mepstrends/home) and each summary table ([hc_care](../mepstrends/hc_care), [hc_cond](../mepstrends/hc_cond), [hc_ins](../mepstrends/hc_ins), [hc_pmed](../mepstrends/hc_pmed), and [hc_use](../mepstrends/hc_use))

[RtoJSON.R](RtoJSON.R): Creates **code.js**, **init.js**, and json files of tabular data in **data** folder for each [mepstrends](../mepstrends) table. Main functions are pulled from [functions.R](functions.R)

[codes.R](codes.R): Creates list objects of R and SAS codes to be used as display codes in the interactive tables. Pulls code snippets mainly from [code](../code) folder. These R objects are converted to js variables in [RtoJSON.R](RtoJSON.R)

[dictionaries.R](dictionaries.R): Labels, definitions, titles, desriptions, and instructions for each interactive table. Also defines lists of statistics and grouping variables for each table. These R lists are mainly used in [RtoJSON.R](RtoJSON.R) and [RtoHTML.R](RtoHTML.R)

[functions.R](functions.R): Main helper functions used in [RtoHTML.R](RtoHTML.R), [RtoJSON.R](RtoJSON.R), [codes.R](codes.R), and [tables_run.R](tables_run.R)

[notes.R](notes.R): List of notes for use in footnotes and the 'Notes' paragraph for each interactive table, based on the selected grouping variables and statistic. These R objects are converted to javascript variables in [RtoJSON.R](RtoJSON.R)

[tables_run.R](tables_run.R): Program to create summary table data directly from MEPS Public Use Files (PUFs) that are stored in a local directory (C:/MEPS). R codes are read in from [code/r](../code/r) to ensure that displayed R code on the web tables is consistent with code used to create estimates. Summary tables are then stored in the [tables](../tables) folder as .csv files. These .csv files are converted to json data in [RtoJSON.R](RtoJSON.R)

[transfer_pufs.R](transfer_pufs.R): Short script to download MEPS public use files from the web and store in a local folder
