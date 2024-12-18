# Atlantic World Slave Trade Voyages Database

This repo provides R code that makes it easier for scholars to statistically analyze the Trans-Atlantic and Intra-American slave voyages databases available on [SlaveVoyages.org](https://www.slavevoyages.org).

## Objective

To facilitate statistical modeling of the [SlaveVoyages.org](https://www.slavevoyages.org) data by reorganizing in a format consistant with biomedical retrospective datasets.

## Why update the datasets?

The SlaveVoyages.org interface is excellent for teaching and for calculating basic data summaries, but it cannot be easily used to compare the datasets with statistical software, borrow strength between the datasets, or to model relationships among variables. Using the update in this repo, it is possible to model uncertainty, to do Bayesian inference with subjective priors, to do multiple imputation for missing data, to do statistical modeling, as well as machine learning and AI. 


## What we have done

In short, the _Intra-American_ and _Trans-Atlantic voyages_ databases were combined row-wise, and then merged with the _African Origins_ database

### Combined and modifed the _Intra-American_ and _Trans-Atlantic voyages_ databases

The [SlaveVoyages.org](https://www.slavevoyages.org) website allows users to download the Trans-Atlantic and Intra-American databases separately, for analyses.

The R code in this repo:

1. Combines the datasets into one, with a grouping variable called _intra_or_trans_ to distinguish the two original datasets.
2. Makes the variable names user friendly (e.g., REGDIS1 has been renamed _First_region_of_slave_landing_.)
3. Converts dates from character format to date format (yyyy-mm-dd) for easier date arithmetic
4. Replaces numeric codes with real names. For example, in the original datasets, the variable representing the slave ship's rig is called RIG, and it has numbers for values instead of the actual rig names. The new Atlantic-World dataset has the actual rig names. For example, in the original datasets the number 35 represents "Snauw." The Atlantic-World dataset replaces the 35 with the word Snauw. Likewise, in the original datasets, the variable representing first intended port of slave purchase is called EMBREG, and its values are in the form of numbers, such as 60500, which means “Bight of Benin.” The AWSTV dataset renames EMBREG _First_intended_region_of_purchase_of_slaves_, and uses “Bight of Benin” instead of 60500.

7. Reconciles the codebooks with the data. Some of the data available for download is consistent with the 2022 Codebook, rather than the 2023 Codebook. 
8. Removes diatcritical marks, which confounds some statistical packages.
9. Follows R convention by using NA for missing values.
10. Makes day, month, year and period variables integers.

### Merged the combined dataset with the _African Origins_ dataset


## Output

The R script makes an R dataframe called _awstvDatabase_, which is the combined, modified [SlaveVoyages.org](https://www.slavevoyages.org) datasets, and it also exports that new dataset to a .csv file to use in other statistical software. That file is called _Atlantic_World_Slave_Trade_voyages_database_with_origins.csv_

## Quick start

1. Copy the _code_and_files_ folder to your computer.
2. Download the current Trans-Atlantic and Intra-American datasets in CSV format. Put them in the folder with the R script. There should now be three files in _code_and_files_ (the two datasets and an R script) plus a folder called _numeric_lookup_files_.
3. In R, run the R script called **AtlanticWorldSlaveVoyages.R** (useage: AtlanticWorldSlaveVoyages(intra.csv,trans.csv), but replace intra.csv and trans.csv with the names of your downloaded files)

## Short bibliography

Elits, David. "The Trans-Atlantic Slave Trade Database: Origins, Development, Content." _Journal of Slavery and Data Preservation_ 2, no. 3 (2021): 1-8. https://doi.org/10.25971/R9H6-QX59.

O’Malley, Gregory E. and Alex Borucki. “Creation of the Intra-American Slave Trade Database.” _Journal of Slavery and Data Preservation_ 4, no. 2 (2023): 3-21. https://doi.org/10.25971/nkg5-cg94.

Williams, Jennie K. "The Coastwise Traffic to New Orleans Dataset: Documenting North American Voyages in the IASTD." _Journal of Slavery and Data Preservation_ 4, no. 2 (2023): 27-34. https://doi.org/10.25971/bpz3-0f38.

The Trans-Atlantic Slave Trade Database. 2019. SlaveVoyages. https://www.slavevoyages.org (accessed January 1, 2025).

Eltis, David, et al. The Atlantic Slave Trade Database, available online at http://www.slavevoyages.org/voyage/download.

### Imputed data

Estimates. 2019. _SlaveVoyages_. https://slavevoyages.org/assessment/estimates (accessed January 1, 2025).

## License

MIT License

Copyright (c) [year] [fullname]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
