library(readxl)
library(data.table)
library(ncdf4)
library(dplyr)
library(ggplot2)
library(lubridate)
library(openxlsx)

options(digits = 14)



# POPULATION AND PROVINCES
{
  
  ###############################################################################
  # Complete the file path to the ISTAT database on the 2024 Italian population #
  ###############################################################################
  
  file_path <- ""
  
  # Load the original ISTAT database on the 2024 Italian population.
  population_dt <- read_excel(file_path)
  
  # Convert it to a data table.
  population_dt <- as.data.table(population_dt)
  
  # Remove the first 12 rows. 
  population_dt <- population_dt[-(1:12)]
  
  # Remove unnecessary columns and rename remaining ones.
  population_dt[, ...2 := NULL]
  population_dt[, ...3 := NULL]
  setnames(population_dt, "...4", "population")
  setnames(population_dt, "Italia, regioni, province", "provincia")
  
  # Remove duplicate for Valle d'Aosta / Vallèe d'Aoste.
  population_dt <- population_dt[-9]
  
  # Define all the rows to be deleted, i.e., all those values which are not provinces or are repetitions. In total, after the cleaning
  # there should be 107 provinces only.
  to_remove <- c("Abruzzo", "Basilicata", "Calabria", "Campania", "Emilia-Romagna", "Friuli-Venezia Giulia", "Lazio", "Liguria", 
                 "Lombardia", "Marche", "Molise", "Piemonte", "Puglia", "Sardegna", "Sicilia", "Toscana", "Trentino Alto Adige / Südtirol", 
                 "Umbria", "Veneto", "Sud", "Centro", "Nord", "Nord-est", "Provincia Autonoma Bolzano / Bozen", "Mezzogiorno", "Isole",
                 "Provincia Autonoma Trento")
  
  # Remove unnecessary values.
  population_dt <- population_dt[!provincia %in% to_remove]
  rm(to_remove); gc()
  
  # Convert 'population' to numeric.
  population_dt[, population := as.numeric(population)]
  
  # Compute the population share 'share_pop'.
  population_dt[, share_pop := population / sum(population)]
  
  # Compute the provincial capital for each province.
  population_dt[, capoluogo := provincia]
  
  # Assign a single, clear provincial capital to problematic provinces.
  population_dt[provincia == "Verbano-Cusio-Ossola", capoluogo := "Verbania"]
  population_dt[provincia == "Valle d'Aosta / Vallée d'Aoste", capoluogo := "Aosta"]
  population_dt[provincia == "Monza e della Brianza", capoluogo := "Monza"]
  population_dt[provincia == "Bolzano / Bozen", capoluogo := "Bolzano"]  
  population_dt[provincia == "Pesaro e Urbino", capoluogo := "Pesaro"]
  population_dt[provincia == "Reggio nell'Emilia", capoluogo := "Reggio Emilia"]  
  population_dt[provincia == "Forlì-Cesena", capoluogo := "Forlì"]
  population_dt[provincia == "Massa-Carrara", capoluogo := "Massa"]
  population_dt[provincia == "Barletta-Andria-Trani", capoluogo := "Barletta"]
  population_dt[provincia == "Reggio di Calabria", capoluogo := "Reggio Calabria"]
  population_dt[provincia == "Sud Sardegna", capoluogo := "Carbonia"]
    
}



# COORDINATES AND PROVINCES
{
  
  ###################################################################################
  # Complete the file path to the database on the coordinate of provincial capitals #
  ###################################################################################
  
  file_path <- ""
  
  # Load the database on the Italian provinces' coordinates.
  provinces_dt <- read_excel(file_path)
  
  # Convert it to a data table.
  provinces_dt <- as.data.table(provinces_dt)
  
  # Remove the first unnecessary row.
  provinces_dt <- provinces_dt[-1]
  
  # Set correctly variables' names.
  setnames(provinces_dt, c("sigla_provincia",	"codice_istat",	"denominazione_ita_altra", "denominazione_ita",	"denominazione_altra",	
                           "flag_capoluogo",	"codice_belfiore",	"lat",	"lon",	"superficie_kmq",	"codice_sovracomunale"))
  
  # Retain only variables of interest.
  provinces_dt <- provinces_dt[, c("denominazione_ita", "lat",	"lon")]
  
  # Indicate the 107 provincial capitals of analysis to retain.
  to_keep <- c("Agrigento", "Alessandria", "Ancona", "Aosta", "Arezzo", "Ascoli Piceno", "Asti", "Avellino", "Bari", "Barletta", "Belluno", "Benevento", 
               "Bergamo", "Biella", "Bologna", "Bolzano", "Brescia", "Brindisi", "Cagliari", "Caltanissetta", "Campobasso", "Carbonia", "Caserta", 
               "Catania", "Catanzaro", "Chieti", "Como", "Cosenza", "Cremona", "Crotone", "Cuneo", "Enna", "Fermo", "Ferrara", "Firenze", "Foggia", 
               "Forlì", "Frosinone", "Genova", "Gorizia", "Grosseto", "Imperia", "Isernia", "L'Aquila", "La Spezia", "Latina", "Lecce", "Lecco", 
               "Livorno", "Lodi", "Lucca", "Macerata", "Mantova", "Massa", "Matera", "Messina", "Milano", "Modena", "Monza", "Napoli", "Novara", 
               "Nuoro", "Oristano", "Padova", "Palermo", "Parma", "Pavia", "Perugia", "Pesaro", "Pescara", "Piacenza", "Pisa", "Pistoia", "Pordenone", 
               "Potenza", "Prato", "Ragusa", "Ravenna", "Reggio di Calabria", "Reggio nell'Emilia", "Rieti", "Rimini", "Roma", "Rovigo", "Salerno", 
               "Sassari", "Savona", "Siena", "Siracusa", "Sondrio", "Taranto", "Teramo", "Terni", "Torino", "Trapani", "Trento", "Treviso", "Trieste", 
               "Udine", "Varese", "Venezia", "Verbania", "Vercelli", "Verona", "Vibo Valentia", "Vicenza", "Viterbo")
  
  # Get rid of unnecessary cities.
  provinces_dt <- provinces_dt[denominazione_ita %in% to_keep]
  
  # Uniform names for simplicity.
  provinces_dt[denominazione_ita == "Reggio di Calabria", denominazione_ita := "Reggio Calabria"]
  provinces_dt[denominazione_ita == "Reggio nell'Emilia", denominazione_ita := "Reggio Emilia"]
  
  # Get the centers of the 0.1° x 0.1° cells.
  provinces_dt[, lat := round(as.numeric(lat), 1)]
  provinces_dt[, lon := round(as.numeric(lon), 1)]

  # Define the 12 manual corrections for cells on the coastline or close to it.
  city_updates <- data.table(city = c("Napoli", "Venezia", "Genova", "Cagliari", "Trapani", "Siracusa","Pesaro", "Rimini", "Savona", "La Spezia", 
                                      "Massa", "Reggio Calabria"),
                             lat = c(40.9, 45.5, 44.5, 39.3, 38.0, 37.1, 43.9, 44.0, 44.3, 44.1, 44.0, 38.1),
                             lon = c(14.3, 12.3, 8.9, 9.1, 12.6, 15.2, 12.8, 12.6, 8.4, 9.9, 10.2, 15.7))
  
  # Update the data table by matching city names.
  for (i in 1:nrow(city_updates)) {
    
    provinces_dt[denominazione_ita == city_updates$city[i], `:=`(lat = city_updates$lat[i], lon = city_updates$lon[i])]
    
  }
  
  rm(i, city_updates, to_keep, file_path); gc()
  
  # Generate a sinlge cell identifier.
  provinces_dt[, lat_lon := paste0(round(lat, 1), sep = "-", round(lon, 1))]
  
  # Uniform vars' names for merging.
  setnames(provinces_dt, "denominazione_ita", "capoluogo")
  
  # Create a final unique data table combining population and coordinates.
  provincial_capitals_dt <- population_dt[provinces_dt, on = "capoluogo"]
  
  # Rename vars. 
  setnames(provincial_capitals_dt, c("lat", "lon" ), c("latitude", "longitude"))
  
  # Save the unique identifier for future filtering.
  lat_lon_to_keep <- provincial_capitals_dt$lat_lon
  
  rm(provinces_dt, population_dt); gc()
  
}



# NetCDF FILTERING AND HDD COMPUTATION
{
  
  # Create an empty data table with the variables needed.
  hdd_dt <- data.table(date = as.Date(numeric()), HDD = as.numeric())
  
  ######################################################################
  # Complete the file path to the downloaded and unzipped NetCDF files #
  ######################################################################
  file_path <- ""
  
  ##############
  # WARNING!!! #
  ##############
  # When unzipping the NetCDF files, make sure to rename them with the following format: yyyy.1.nc for the files from January to June 
  # and yyyy.2.nc for the files from July to December, where "yyyy" stands for the 4-digit year (e.g., 2012.1.nc).
  
  files_to_open <- list.files(file_path)
  
  for (file in files_to_open) {
    
    ######################################################################
    # Complete the file path to the downloaded and unzipped NetCDF files #
    ######################################################################
    file_path <- ""
    
    file_path <- paste0(file_path, "/", file)
    
    # Open the NetCDF File.
    nc_file <- nc_open(file_path)
    
    # Extract dimensions and variables.
    time <- ncvar_get(nc_file, "valid_time")  
    lat <- ncvar_get(nc_file, "latitude")    
    lon <- ncvar_get(nc_file, "longitude")   
    t2m <- ncvar_get(nc_file, "t2m") 
    
    
    # Create a data table with combinations in reversed dimension order.
    working_dt <- CJ(time = time,
                      lat = lat,
                      lon = lon,
                   sorted = FALSE)
    
    # Reorder the data table to match NetCDF dimension order (lon - lat - time) to ensure that the first dimension is that first to change, 
    # then the second, lastly the third.
    setcolorder(working_dt, c("lon", "lat", "time"))
    
    # Flatten t2m from a 3D array to a vector.
    t2m <- as.vector(t2m)
    
    # Assign the flattened data to the data table.
    working_dt[, t2m := t2m]
    
    # Generate a unique grid identifier. Round coordinates to ensure proper values (some values are not rounded).
    working_dt[, lat_lon := paste0(round(lat, 1), sep = "-", round(lon, 1))]
    
    # Keep only those 107 cells covering the 107 provincial capitals of Italy.
    working_dt_filtered <- working_dt[lat_lon %in% lat_lon_to_keep]
    
    # Convert t2m from °K to °C.
    working_dt_filtered[, t2m := t2m - 273.15]
    
    # Convert the time variable to an actual date-hour format.
    working_dt_filtered[, time := as.POSIXct(time, origin = "1970-01-01")]
    
    # Create a variable identifying the calendar date only (discarding the hour).
    working_dt_filtered[, day_time := as.Date(paste0(year(time), sep = "-", month(time), sep = "-", day(time)))]
    
    # Create a single grid-day identifier to loop over.
    working_dt_filtered[, day_grid := paste0(lat_lon, sep = "_", day_time)]
    
    # Convert to data table. 
    working_dt_filtered <- as.data.table(working_dt_filtered)
    
    # Set order of the data table by location and time.
    setorder(working_dt_filtered, lat_lon, time)
    
    # For each day-grid combination, i.e., for each day and location, re-compute t2m as the mean of daily temperatures.
    working_dt_filtered <- working_dt_filtered[, .(t2m = mean(t2m)), by = .(day_grid)]
    
    # Extract from the day-grid combination the grid identifier.
    working_dt_filtered[, lat_lon := sub("_.*", "", day_grid)]
    
    # Extract from the day-grid combination the calendar date.
    working_dt_filtered[, date := as.Date(sub(".*_", "", day_grid))]
    
    # Remove the day-grid identifier.
    working_dt_filtered[, day_grid := NULL]
    
    # Change the order of variables.
    setcolorder(working_dt_filtered, c("date", "lat_lon", "t2m"))

    # Note that our data table includes also the first date of the following file, we want to get rid of this.
    # Calculate the position of the 4th character from the right of the file name to determine the kind of file that we are dealing with.
    # If it is a Jan-Jun file or a Jul-Dec file. Should be either 1 or 2.
    position <- nchar(file) - 3
    
    # Extract the character at that position.
    result <- substr(file, position, position)
    
    # Then, if we are in a Jan-Jun file, set the max date to be July 1st of the year of the file.
    if (result == "1") {
      
      year <- substr(file, 1, 4)
      
      max_date <- as.Date(paste0(year, sep = "-", "07-01"))
      
    }
    
    # Else, if we are in a Jul-Dec file, set the max date to be January 1st of the following year.
    if (result == "2") {
      
      year <- substr(file, 1, 4)
      
      max_date <- as.Date(paste0(as.character(as.numeric(year) + 1), sep = "-", "01-01"))
      
    }
    
    # Now we can remove the first observation of the following file.
    working_dt_filtered <- working_dt_filtered[date < max_date]
    
    # Compute HDDs following the rule.
    working_dt_filtered[, HDD_daily := fifelse(15.61 - t2m > 0, 15.61 - t2m, 0)]
    
    # Merge the data table with the data table on the population of provincial capitals based on grid identifiers.
    working_dt_filtered <- working_dt_filtered[provincial_capitals_dt, on = "lat_lon"]
    
    # Remove unnecessary columns.
    working_dt_filtered[, c("capoluogo", "latitude", "longitude") := NULL]
    
    # Multiply grid-specific daily HDDs by the respective grid's weight.
    working_dt_filtered[, weighted_hdd_daily := HDD_daily * share_pop]
    
    # Order the variables.
    setorder(working_dt_filtered, date)
    
    # Take the daily sum of weighted HDDs.
    daily_dt <- working_dt_filtered[, .(HDD = sum(weighted_hdd_daily)), by = date]
    
    # Update the hdd_dt data table with the newly derived time series.
    hdd_dt <- rbind(hdd_dt, daily_dt)
    
    print(paste0("HDD, Done with file: ", file))
    
  }
  
  #######################################################
  # Complete the file path to save the data set on HDDs #
  #######################################################
  write.xlsx(hdd_dt, file = "", sheetName = "Sheet1", overwrite = TRUE)
  
}



# NetCDF FILTERING AND SNSR COMPUTATION
{
  # Create an empty data table with the variables needed.
  ssr_dt <- data.table(date = as.Date(numeric()), SNSR = as.numeric())
  
  ######################################################################
  # Complete the file path to the downloaded and unzipped NetCDF files #
  ######################################################################
  file_path <- ""
  
  ##############
  # WARNING!!! #
  ##############
  # When unzipping the NetCDF files, make sure to rename them with the following format: yyyy.1.nc for the files from January to June 
  # and yyyy.2.nc for the files from July to December, where "yyyy" stands for the 4-digit year (e.g., 2012.1.nc).
  
  files_to_open <- list.files(file_path)
  
  for (file in files_to_open) {
    
    ######################################################################
    # Complete the file path to the downloaded and unzipped NetCDF files #
    ######################################################################
    file_path <- ""
    
    file_path <- paste0(file_path, "/", file)
    
    # Open the NetCDF File.
    nc_file <- nc_open(file_path)
    
    # Extract dimensions and variables.
    time <- ncvar_get(nc_file, "valid_time")  
    lat <- ncvar_get(nc_file, "latitude")    
    lon <- ncvar_get(nc_file, "longitude")   
    ssr <- ncvar_get(nc_file, "ssr") 
    
    
    # Create a data table with combinations in reversed dimension order.
    working_dt <- CJ(
      time = time,
      lat = lat,
      lon = lon,
      sorted = FALSE
      
    )
    
    # Reorder the data table to match NetCDF dimension order (lon - lat - time) to ensure that the first dimension is that first to change, 
    # then the second, lastly the third.
    setcolorder(working_dt, c("lon", "lat", "time"))
    
    # Flatten ssr from a 3D array to a vector.
    ssr <- as.vector(ssr)
    
    # Assign the flattened data to the data table.
    working_dt[, SNSR := ssr]
    
    # Generate a unique grid identifier.
    working_dt[, lat_lon := paste0(round(lat, 1), sep = "-", round(lon, 1))]
    
    # Keep only those 107 cells covering the 107 provincial capitals of Italy.
    working_dt_filtered <- working_dt[lat_lon %in% lat_lon_to_keep]
    
    # Convert the date variable to an actual date-hour format.
    working_dt_filtered[, time := as.POSIXct(time, origin = "1970-01-01")]
    
    # Change the date variable to the calendar date.
    working_dt_filtered[, date := as.Date(paste0(year(time), sep = "-", month(time), sep = "-", day(time), sep = "-"))]
    
    # Remove the now unnecessary "time" variable.
    working_dt_filtered[, time := NULL]
    
    # Bring the calendar date back by one day.
    working_dt_filtered[, date := date - days(1)]
    
    # Convert to data table. 
    working_dt_filtered <- as.data.table(working_dt_filtered)
    
    # Set order of the data table by location and date.
    setorder(working_dt_filtered, lat_lon, date)
    
    # Remove unnecessary variables.
    working_dt_filtered[, c("lat", "lon") := NULL]
    
    # Change the order of variables.
    setcolorder(working_dt_filtered, c("date", "lat_lon", "SNSR"))
    
    # Merge the data table with the data table on the population of provincial capitals based on grid identifiers.
    working_dt_filtered <- working_dt_filtered[provincial_capitals_dt, on = "lat_lon"]
    
    # Remove unnecessary columns.
    working_dt_filtered[, c("capoluogo", "latitude", "longitude") := NULL]
    
    # Multiply grid-specific daily SNSR by the respective grid's weight.
    working_dt_filtered[, weighted_SNSR_daily := SNSR * share_pop]
    
    # Order the variables.
    setorder(working_dt_filtered, date)
    
    # Take the daily sum of weighted SNSRs
    daily_dt <- working_dt_filtered[, .(SNSR = sum(weighted_SNSR_daily)), by = date]
    
    # Update the ssr_dt data table with the newly derived time series.
    ssr_dt <- rbind(ssr_dt, daily_dt)
    
    print(paste0("SNSR, Done with file: ", file))
    
  }
  
  # Convert SNSR in millions of J/m^2 to obtain meaningful regression coefficients.
  ssr_dt[, SNSR := SNSR / 1000000]
  
  # Filter the data table to retain only observations of interest.
  ssr_dt <- ssr_dt[date > "2011-12-31" & date < "2025-03-01"]
  
  #######################################################
  # Complete the file path to save the data set on SNSR #
  #######################################################
  write.xlsx(ssr_dt, file = "", sheetName = "Sheet1", overwrite = TRUE)
  
}



# SNAM GAS BALANCES
{
  
  ##############
  # WARNING!!! #
  ##############
  # When downloading the gas balances, save them with the format mm-yyyy.xlsx and create a folder for each year, e.g., 2012, 2013, etc.
  
  # Create an empty data table to store results. 
  RDS_dt <- data.table(date = as.Date(character()), RDS = numeric())
  
  # Make a list of all years for which we have data.
  list_years <- c("2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019", "2020", "2021", "2022", "2023", "2024", "2025")
  
  # Then for each year...
  for (year in list_years){
    
    # Update the file path to look for the given year folder.
    
    #########################################################
    # Complete the file path to the downloaded Gas Balances #
    #########################################################
    file_path <- paste0("", year, sep = "")
    
    # List the files in the given year-folder.
    files_to_process <- list.files(file_path)
    
    # Then, for each one of these files...
    for (my_file in files_to_process) {
      
      # Update the file path to consider the given year...
      
      #########################################################
      # Complete the file path to the downloaded Gas Balances #
      #########################################################
      file_path <- paste0("", year, sep = "")
      
      # ... and the given file.
      file_path <- paste0(file_path, "/", my_file, sep = "")
      
      # Account for the fact that the sheet to be selected has to possible names over time.
      possible_sheets <- c("mc da 38,1 MJ", "Sm3 PCS 10,57275 kWhSm3")
      
      # Identify the correct worksheet.
      sheet_name <- excel_sheets(file_path) %>% intersect(possible_sheets) %>% first()
      
      # Read the entire sheet into a data table.
      raw_data <- as.data.table(read_excel(file_path, sheet = sheet_name, col_names = FALSE))
      
      # Find the index of the row where "GG" appears in the first column.
      header_row_index <- which(raw_data$...1 == 1) - 1
      
      # Extract the header row.
      header_row <- raw_data[header_row_index, ]
      
      # Clean the header row from non-text characters.
      header_row <- sapply(header_row[1], function(x) gsub("[^A-Za-z]", "", x))
      
      # Set column names to the values in the header row.
      setnames(raw_data, names(raw_data), as.character(unlist(header_row)))
      
      # Remove rows before the header row.
      cleaned_data <- raw_data[(header_row_index + 1):.N]
      
      # Keep only the two necessary columns: dates and distribution networks' consumption.
      cleaned_data <- cleaned_data[,.(GG, Retididistribuzione)]
      
      # Create a date, the first day of the given month-year combination.
      my_date <- dmy(paste0("01-", my_file, sep = ""))
      
      # From this first date, add the given number of days as stored in the variable "GG" (notice that we must subtract 1 to ensure alignment, "GG" starts at 1 and ends at 28/29/30/31).
      cleaned_data[, date := my_date + (as.numeric(GG) - 1)]
      
      # Change variable's name.
      setnames(cleaned_data, "Retididistribuzione", "RDS")
      
      # Convert to numeric "RDS"
      cleaned_data[, RDS := as.numeric(RDS)]
      
      # Identify the first row for which there is no date, i.e., the first row which does not contain an observation.
      first_na_index <- which(is.na(cleaned_data$GG))[1]
      
      # Filter to retain only rows with observations.
      cleaned_data <-  cleaned_data[1:(first_na_index-1)]
      
      # Remove the original "GG" variable.
      cleaned_data[, GG := NULL]
      
      # Append results to the final results data table.
      RDS_dt <- rbind(RDS_dt, cleaned_data)
      
    }
    
    rm(cleaned_data, raw_data, file_path, files_to_process, first_na_index, header_row, header_row_index, list_years, my_date, my_file, possible_sheets, sheet_name, year); gc()
    
  }
  
  
  
}



# PRICES
{
  
  # Set the file path to the file with the ISTAT price index.
  
  ##############################################################
  # Complete the file path to the downloaded Price Index files #
  ##############################################################
  file_path <- ""
  
  # List the files to process.
  files_to_process <- list.files(file_path)
  
  # Prepare an empty data table to be uploaded.
  prices <- data.table(price = numeric())
  
  # For each file to process...
  for (file in files_to_process) {
    
    # ... recall the file path...
    
    ##############################################################
    # Complete the file path to the downloaded Price Index files #
    ##############################################################
    file_path <- ""
    
    # ... and upload it to point to the correct file.
    file_path <- paste0(file_path, "/", file, sep = "")
    
    # Open the file as a data table. No column names as the file is horizontal.
    raw_data <- as.data.table(read_excel(file_path, col_names = FALSE))
    
    # Retain only the 9th row, the one with the actual prices.
    price <- raw_data[9, ]
    
    # Transpose the prices.
    transposed_price <- transpose(price)
    
    # Generate an ID counting observations.
    transposed_price[, ID := .I]
    
    # Delete the first observation, which is the name of the variable, not an actual price.
    transposed_price <- transposed_price[ID > 1]
    
    # Remove the now unnecessary ID.
    transposed_price[, ID := NULL]
    
    # Rename.
    setnames(transposed_price, "V1", "price")
    
    # Convert to numeric.
    transposed_price[, price := as.numeric(price)]
    
    # Add to the empty data table.
    prices <- rbind(prices, transposed_price)
    
  }
  
  # Now, create a "date" variable assigning the correct date to all observations starting from January 2011.
  prices[, date := seq.Date(from = as.Date("2011-01-01"), by = "month", length.out = .N)]
  
  # Define a scaling factor to account for the different bases. The index is constant at the merging point, thus the ratio is sufficient.
  scaling_factor <- prices[date == "2016-01-01", price] / prices[date == "2015-12-01", price]
  
  # Re-scale the base 2010 values to concord with base 2015 ones.
  prices[, price := fifelse(date < "2016-01-01", round(price * scaling_factor, 1), price)]
  
  # Change columns' order.
  setcolorder(prices, c("date", "price"))
  
  # Lag the ISTAT price index by 3 months.
  setnames(prices, "price", "price_l0")
  prices[, price_l3m := shift(price_l0, n = 3, type = "lag")]
  
  # Retain only observations of interest.
  prices <- prices[date >= "2012-01-01" & date < "2025-03-01"]
  
  rm(file, file_path, files_to_process, raw_data, price, transposed_price, scaling_factor); gc()
  
}  



# SET UP OF THE WORKING DATABASE
{
  # Find the HDD file.
  
  ###############################################
  # Complete the file path to the HDDs data set #
  ###############################################
  file_path <- ""
  
  # Open it as a data table.
  hdd_dt <- as.data.table(read_excel(file_path))
  
  hdd_dt <- hdd_dt[date < as.Date("2025-03-01")]
  
  # Find the SNSR file.
  
  ###############################################
  # Complete the file path to the SNSR data set #
  ###############################################
  file_path <- ""
  
  # Open it as a data table.
  snsr_dt <- as.data.table(read_excel(file_path))
  
  snsr_dt <- snsr_dt[date < as.Date("2025-03-01")]
  
  # Merge the two by the common daily date variable "date".
  daily_dt <- merge(hdd_dt, snsr_dt, by = "date")
  
  # Convert the variable to an actual date.
  daily_dt[, date := as.Date(date)]
  
  # Merge daily HDD and SNSR with the data from SNAM gas balances.
  daily_dt <- merge(daily_dt, RDS_dt, by = "date")
  
  # Generate a "month_year" to merge with prices data.
  daily_dt[, month_year := paste0(year(date), sep = "-", month(date))]
  
  # Generate the same variable in the data table on prices (remember, prices are at MONTHLY FREQUENCY).
  prices[, month_year := paste0(year(date), sep = "-", month(date))]
  
  # Merge daily observations with monthly prices.
  daily_dt <- merge(daily_dt, prices, by = "month_year", all.x = TRUE)
  
  # Remove the duplicated date column.
  daily_dt[, date.y := NULL]
  
  # Rename variables.
  setnames(daily_dt, "date.x", "date")
  
  # Generate a "month" variable to create monthly dummies
  daily_dt[, month := month(date)]
  
  # Generate the 12 monthly dummies.
  for (i in 1:12) {
    
    daily_dt[, paste0("Month_", i) := fifelse(month == i, 1, 0)]
    
  }
  
  # Remove the now unnecessary "month" variable.
  daily_dt[, month := NULL]
  
  # Order the data table.
  setorder(daily_dt, date)
  
  # Generate the linear time-trend.
  daily_dt[, TimeTrend := .I-1]
  
  # Recover the weekday to generate day-dummies..
  daily_dt[, day := weekdays(date)]
  
  # Create day-specific dummies.
  i <- 1
  
  for (this_day in unique(daily_dt$day)) {
    
    daily_dt[, paste0("Day_", i) := fifelse(day == this_day, 1, 0)]
    
    i <- i + 1
    
  }
  
  
  # Now we want to distinguish between base-load and space-heating consumption.
  # The rule: take June's and September's consumption by day in year x and average them out, then take the max between RDS - Base and 0.
  
  # Keep track of the year and of the month of each observation.
  daily_dt[, years := year(date)]
  daily_dt[, month := month(date)]
  
  # Make an empty copy of the data table to store the data and add to it an empty 'baseload' variable.
  all_years <- daily_dt[, .(years, day)][0]
  all_years[, baseload := as.numeric(NA)]
  
  # Now, for each year...
  for (year in unique(daily_dt$years)) {
    
    # ...store June's consumption.
    june <- daily_dt[years == year & month == 6, .(RDS, day)]
    
    # Store September's consumption.
    september <- daily_dt[years == year & month == 9, .(RDS, day)]
    
    # Merge the two months' consumption.
    june_september <- rbind(june, september)
    
    # Compute the average consumption for the two months by day.
    june_september <- june_september[, .(baseload = mean(RDS)), by = .(day)]
    
    # Create a variable to track the year under scrutiny.
    june_september[, years := year]
    
    # Add the data to our final data table.
    all_years <- rbind(all_years, june_september)
    
  }
  
  # Merge the base-load consumption's data with the original data table.
  daily_dt <- merge(daily_dt, all_years, by = c("years", "day"), all.x = TRUE)
  
  # For 2025, set baseload to be equal to the previous year.
  for (this_date in unique(daily_dt[years == 2025]$date)) {
    
    previous_year_date <- as.Date(this_date) - years(1)
    
    daily_dt[date == this_date, baseload := daily_dt[date == previous_year_date]$baseload]
    
  }
  
  setorder(daily_dt, date)
  
  # Generate the 'heating' consumption variable.
  daily_dt[, heating := max(RDS - baseload, 0, na.rm = TRUE), by = date]
  
  daily_dt[, effective_baseload := min(RDS, baseload, na.rm = TRUE), by = date]
  
  rm(previous_year_date, this_date, all_years, june, june_september, september, year); gc()
  
  # Perform the monthly aggregation of RDS, HDD, SNSR. Prices are all the same by month, so taking the max() suffices to retain the corresponding value.
  monthly_dt <- daily_dt[, .(RDS = sum(RDS), HDD = sum(HDD), SNSR = sum(SNSR), price_l3m = max(price_l3m), price_l0 = max(price_l0), 
                             heating = sum(heating), effective_baseload = sum(effective_baseload)), by = month_year]
  
  # Generate a monthly date, i.e., the first of each month.
  monthly_dt[, date := as.Date(paste0(month_year, "-01", sep =""))]
  
  # Change variables' order.
  setcolorder(monthly_dt, c("date", "RDS", "HDD", "SNSR", "price_l0", "price_l3m"))
  
  # Generate a "month" variable to create monthly dummies
  monthly_dt[, month := month(date)]
  
  # Generate the 12 monthly dummies.
  for (i in 1:12) {
    
    monthly_dt[, paste0("Month_", i) := fifelse(month == i, 1, 0)]
    
  }
  
  rm(i, this_day); gc()
  
  # Remove the now unnecessary "month" variable.
  monthly_dt[, month := NULL]
  
  # Change the data order.
  setorder(monthly_dt, date)
  
  # Generate the linear time-trend.
  monthly_dt[, TimeTrend := .I-1]
  
  # Generate a time index to simplify the management of monthly dates.
  monthly_dt[, time := .I + 623]
  
  # Format the "date" variable.
  monthly_dt[, date := format(date, "%d-%m-%Y")]

  # Remove unnecessary variables.
  daily_dt[, c("years", "day", "month", "baseload") := NULL]
  
  setnames(daily_dt, "effective_baseload", "baseload")
  
  daily_dt[, month_year := NULL]
  
  monthly_dt[, month_year := NULL]
  
  setcolorder(daily_dt, c("date", "RDS", "baseload", "heating", "HDD", "SNSR", "price_l0", "price_l3m", "Day_1", "Day_2", "Day_3", "Day_4", "Day_5", "Day_6", "Day_7", "Month_1", "Month_2", "Month_3", "Month_4", "Month_5", "Month_6", "Month_7", "Month_8", "Month_9", "Month_10", "Month_11", "Month_12", "TimeTrend"))
  
  # Save the daily database.
  
  #####################################################
  # Complete the file path to save the daily data set #
  ######################################################
  write.xlsx(daily_dt, file = "", sheetName = "Sheet1", overwrite = TRUE)
  
  setnames(monthly_dt, "effective_baseload", "baseload")
  
  setcolorder(monthly_dt, c("date", "RDS", "baseload", "heating", "HDD", "SNSR", "price_l0", "price_l3m", "Month_1", "Month_2", "Month_3", "Month_4", "Month_5", "Month_6", "Month_7", "Month_8", "Month_9", "Month_10", "Month_11", "Month_12", "TimeTrend", "time"))
  
  setorder(monthly_dt, time)
  
  # Save the monthly database
  
  #######################################################
  # Complete the file path to save the monthly data set #
  #######################################################
  write.xlsx(monthly_dt, file = "", sheetName = "Sheet1", overwrite = TRUE)
  
  
}
