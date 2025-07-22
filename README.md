# Polo, Roccuzzo (2025)
The following repository provides the database and replication package of Polo, Roccuzzo (2025) [link]. 
Any question about these files should be addressed to tommaso.roccuzzo@duke.edu or to michele.polo@unibocconi.it.

All data sources are open access and easily retrievable by interested parties. Links pointing to the necessary data sources are provided at the end of this README file and also within the .R replication file.

For our analyisis, we have relied on:
- R version 4.4.3
- Stata18
- Python 3.13.3


# Available Files:
- File 1 - CDS API HDD.py to download daily mean temperatures from the ERA5-Land database;
- File 2 - CDS API SNSR.py to download total daily surface net solar radiation from the ERA5-Land database;
- File 3 - Dataset Creation.R to combine all imputs and create the dataset of analysis to be then loaded into Stata;
- File 4 - Replication.DO to perform the regression/statystical analysis.


In order to correctly replicate our analyisis one should:
1) download all inputs as decribed in the Data Sources;
2) combine all sources with File 3 - Dataset Creation.R to create the working data sets;
3) run File 4 - Replication.DO file with the daily and monthly datasets created.


# Data Sources:
1) Daily gas balances: https://jarvis.snam.it/public-data?pubblicazione=Bilancio%20Definitivo&periodo=2025&lang=it. Download all gas balances from Jan-2012 to Mar-2025 included;
2) Daily mean temperatures: https://cds.climate.copernicus.eu/datasets/reanalysis-era5-land?tab=overview. Use File 1 to download this data;
3) Daily total surface net solar radiation: https://cds.climate.copernicus.eu/datasets/reanalysis-era5-land?tab=overview. Use File 2 to download this data;
4) Monthly price index: https://esploradati.istat.it/databrowser/#/it/dw/categories/IT1,Z0400PRI,1.0/PRI_CONWHONAT/PRI_CONWHONAT_BRI/DCSP_NICUNOBB2010/IT1,167_33_DF_DCSP_NICUNOBB2010_3,1.0 and https://esploradati.istat.it/databrowser/#/it/dw/categories/IT1,Z0400PRI,1.0/PRI_CONWHONAT/DCSP_NIC1B2015/IT1,167_744_DF_DCSP_NIC1B2015_4,1.0. Download both files;
5) Italian population by province: https://esploradati.istat.it/databrowser/#/it/dw/categories/IT1,POP,1.0/POP_POPULATION/DCIS_POPRES1/IT1,22_289_DF_DCIS_POPRES1_1,1.0. Download the 2024 file;
6) Coordinates of all Italian cities: https://www.gardainformatica.it/database-comuni-italiani. Download and extract the file "gi_comuni.xlsx";

Notice that when matching the coordinates of source 6) with the ERA5-Land database of sources 1) and 2) to download climate data, 11 cells are missing from the ERA5-Land database (see the footnote on pag. 6 of the paper for further explanations). Therefore, the following coordinates should be manually corrected:
# Provincial Capital, Missing Cell ->	Filled Cell
Napoli, (40.8, 14.3) -> (40.9, 14.3)
Venezia, (45.4, 12.3) -> (45.5, 12.3)
Genova, (44.4, 8.9) -> (44.5, 8.9)
Cagliari, (39.2, 9.1) -> (39.3, 9.1)
Trapani, (38, 12.5) -> (38, 12.6)
Siracusa, (37.1, 15.3) -> (37.1, 15.2)
Pesaro, (43.9, 12.9) -> (43.9, 12.8)
Rimini, (44.1, 12.6) -> (44, 12.6)
Savona, (44.3, 8.5) -> (44.3, 8.4)
La Spezia, (44.1, 9.8) -> (44.1, 9.9)
Massa, (44, 10.1) -> (44, 10.2)


Cite as:

Polo, Michele, and Roccuzzo, Tommaso. (2025). Replication Package for “And Yet it Moves: A Study of Natural Gas Consumption during the 2022 Energy Crisis in Italy”. GitHub Repository. Available at: https://github.com/troccuzzo/Polo-Roccuzzo-2025



