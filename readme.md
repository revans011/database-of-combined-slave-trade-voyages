# Atlantic World Slave Voyages

This repo provides R code to make it easier for academics to analyze the Trans-Atlantic and Intra-American databases available on [SlaveVoyages.org]([slavevoyages.org](https://www.slavevoyages.org)) as a single, modernized dataset.

## Why update the datasets?

The SlaveVoyages.org interface is excellent for teaching and for calculating basic data summaries, but it cannot be used to easily explore the data or 
to model relationships among variables. Currently it is not possible, through the interface, to do statistical modeling, machine learning or use AI. 




## What we have done

The website allows users to download the Trans-Atlantic and Intra-American databases seperately. These are well-maintained but legacy databases.
The R code in this repo:

1. combines the datasets
2. updates variables names
3. Converts dates from character format to data format
4. replaces region codes with real place names
5. reconciles different versions of the codebooks
6. A number of variables use numeric codes to represent places, ship rigs, XXX, and so on. The code were replace with their real names.
For example, Rig, region

## Quick start

1. Clone this repo to a folder on your computer
2. Download the current Trans-Atlantic and Intra-American datasets in CSV format. Put them in the folder with the R code
3. 
