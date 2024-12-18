
knitr::opts_chunk$set(echo = TRUE)



# Install and load necessary packages
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")
pacman::p_load(
  rio,           # Import/export data in various formats
  tidyverse,     # Collection of packages for data manipulation and visualization
  janitor,       # snakecase names
  lubridate,     # Work with dates and times
  purrr,         # Functional programming tools
  dplyr,         # Data manipulation
  stringi       # used to remove diacriticals

)



# read the numeric code lookup files


path <- "lookup_files/"


## Need codes from both 2022 and 2023 codebooks to get all the place names

# the region codes from 2022 codebook
table_region_codes_2022 <- rio::import(paste0(path,"region-codes-spss-2022.csv"))
table_region_codes_2022 <- table_region_codes_2022 |> clean_names()

# the region codes from 2023 codebook
table_region_codes_2023<- rio::import(paste0(path,"region-codes-spss-2023-table-2.csv"))
table_region_codes_2023 <- table_region_codes_2023 |> clean_names()

table_region_codes <- rbind(table_region_codes_2022,table_region_codes_2023)

# need NA to use fill to fill down tables
table_region_codes <- table_region_codes |>
mutate(across(everything(), as.character)) %>%
  mutate(across(everything(), ~na_if(., "")))

# this fills down the empty spaces in the broader region categories
table_region_codes <- table_region_codes |> 
  fill(broad_region_value, broad_region, specific_region_value, specific_region_country_or_colony, place_value, places_port_or_location)


# XMIMPFLAG Voyage groupings for estimating imputed slaves
xmimpflag_table <- rio::import(paste0(path,"xmimpflag-table-2023.csv"))


# NATIONAL Country in which ship registered
national_table <-  rio::import(paste0(path,"national-table-2023.csv"))


# TONTYPE Definition of ton used in tonnage
tontype_table <-  rio::import(paste0(path,"tontype-table-2023.csv"))

# RIG Rig of vessel
rig_table <-  rio::import(paste0(path,"rig-table-2023.csv"))

# FATE (FATE1 in 2023 codebook) Particular outcome of voyage
fate_table <-  rio::import(paste0(path,"fate-table-2023.csv"))

# FATE2 Outcome of voyage for slaves
fate2_table <-  rio::import(paste0(path,"fate-2-table-2023.csv"))

# FATE3 Outcome of voyage if vessel captured
fate3_table <-  rio::import(paste0(path,"fate-3-table-2023.csv"))

# FATE4 Outcome of voyage for owner
fate4_table <-  rio::import(paste0(path,"fate-4-table-2023.csv"))

# RESISTANCE African resistance
resistance_table <-  rio::import(paste0(path,"resistance-table-2023.csv"))

# read the slavevoyages.org datasets ------------------------------------------------

intra <- rio::import("Voyages-IAm-May2023.csv")
trans <- rio::import("Voyages-TSTD-May2023.csv")

africanOrigins <- rio::import("AfricanNamesDatabase.csv")


# ----------- turn empty double quotes in character vars into missing ------------------
intra <- intra |>
    mutate(across(where(is.character), ~ na_if(., "")))

trans <- trans |>
    mutate(across(where(is.character), ~ na_if(., "")))

africanOrigins <- africanOrigins |>
  mutate(across(where(is.character), ~ na_if(., "")))


#make the grouping variable to identify which data came from which slavevoyages.org dataset

intra <- intra |>
  mutate(intra_or_trans = "intra_american")

trans <- trans |>
  mutate(intra_or_trans = "trans_atlantic")

#  combine the two datasets

df <- bind_rows(intra,trans) 

#  Merge the names dataset

africanOrigins <- africanOrigins |>
  rename(voyage_id = voyageId,
         sex = sexage)

df <- df |> rename(voyage_id = VOYAGEID)

df <- merge(df, africanOrigins, by = "voyage_id", all.x = TRUE)


# --------- import the updated varaible names

var_names <- rio::import(paste0(path,"awstvd_variables_and_definitions.csv"))


#------ make two functions that look up numeric codes and replace them with their real meanings


# this is for a two column table
# Function to replace codes with corresponding strings
replace_codes <- function(value, lookup_table) {
  # Find the index of the value in the place_value column of the lookup_table
  match_index_place <- match(value, lookup_table$place_value)
  
  # Find the index of the value in the specific_region_value column of the lookup_table
  match_index_region <- match(value, lookup_table$specific_region_value)
  
  # Find the index of the value in the broad_region column of the lookup_table
  match_index_broad <- match(value, lookup_table$broad_region_value)
  
  # Replace the value based on the found indexes
  result <- ifelse(
    !is.na(match_index_place), 
    # If the value matches place_value, replace with places_port_or_location
    lookup_table$places_port_or_location[match_index_place], 
    ifelse(!is.na(match_index_region), 
           # If the value matches specific_region_value, replace with specific_region_country_or_colony
           lookup_table$specific_region_country_or_colony[match_index_region], 
           ifelse(!is.na(match_index_broad), 
                  # If the value matches broad_region, replace with broad_region
                  lookup_table$broad_region[match_index_broad], 
                  # If no match is found, retain the original value
                  value)
    )
  )
  
  return(result)
}


# Function to replace codes with corresponding strings
# this is for a one column table, with col names value and label
replace_codes_one_column_table <- function(value, lookup_table) {
  # Find the index of the value in the place_value column of the lookup_table
  match_index_place <- match(value, lookup_table$value)
  
  # Replace the value based on the found indexes
  result <- ifelse(
    !is.na(match_index_place), 
    # If the value matches place_value, replace with places_port_or_location
    lookup_table$label[match_index_place], 
    
    # If no match is found, retain the original value
    value)

  
  return(result)
}


# Region codes to place names
# some codes are not in the codebook, like 80703
df1 <- df |>
  mutate(
    PLACCONS = replace_codes(PLACCONS, table_region_codes),
    PLACREG = replace_codes(PLACREG, table_region_codes),
    PORTDEP = replace_codes(PORTDEP, table_region_codes),
    EMBPORT = replace_codes(EMBPORT, table_region_codes),
    EMBPORT2 = replace_codes(EMBPORT2, table_region_codes),
    PLAC1TRA = replace_codes(PLAC1TRA, table_region_codes),
    PLAC2TRA = replace_codes(PLAC2TRA, table_region_codes),
    PLAC3TRA = replace_codes(PLAC3TRA, table_region_codes),
    MAJBUYPT = replace_codes(MAJBUYPT, table_region_codes),
    MJBYPTIMP = replace_codes(MJBYPTIMP, table_region_codes),
    NPAFTTRA = replace_codes(NPAFTTRA, table_region_codes),
    ARRPORT = replace_codes(ARRPORT, table_region_codes),
    ARRPORT2 = replace_codes(ARRPORT2, table_region_codes),
    SLA1PORT = replace_codes(SLA1PORT, table_region_codes),
    ADPSALE1 = replace_codes(ADPSALE1, table_region_codes),
    ADPSALE2 = replace_codes(ADPSALE2, table_region_codes),
    MAJSELPT = replace_codes(MAJSELPT, table_region_codes),
    MJSLPTIMP = replace_codes(MJSLPTIMP, table_region_codes),
    PORTRET = replace_codes(PORTRET, table_region_codes),
    CONSTREG = replace_codes(CONSTREG, table_region_codes),
    REGISREG = replace_codes(REGISREG, table_region_codes),
    DEPTREGIMP = replace_codes(DEPTREGIMP, table_region_codes),
    EMBREG = replace_codes(EMBREG, table_region_codes),
    EMBREG2 = replace_codes(EMBREG2, table_region_codes),
    REGEM1 = replace_codes(REGEM1, table_region_codes),
    REGEM2 = replace_codes(REGEM2, table_region_codes),
    REGARR = replace_codes(REGARR, table_region_codes),
    REGARR2 = replace_codes(REGARR2, table_region_codes),
    REGDIS1 = replace_codes(REGDIS1, table_region_codes),
    REGDIS2 = replace_codes(REGDIS2, table_region_codes),
    REGDIS3 = replace_codes(REGDIS3, table_region_codes),
    MJSELIMP = replace_codes(MJSELIMP, table_region_codes),
    RETRNREG = replace_codes(RETRNREG, table_region_codes),
    MJSELIMP1 = replace_codes(MJSELIMP1, table_region_codes),
    RETRNREG1 = replace_codes(RETRNREG1, table_region_codes)
  )


# Convert character variables to ASCII to remove diacritical marks, which makes it hard to
 # for some functions to read

 df2 <- df1 |>
   mutate(across(where(is.character), ~ iconv(., from = "UTF-8", to = "ASCII//TRANSLIT")))
 


# XMIMPFLAG code to names. 
# Note that the codes skip. For example code 109 does not exist.
# Voyage groupings for estimating imputed slaves

df1 <- df1 |> mutate(
XMIMPFLAG = replace_codes_one_column_table(XMIMPFLAG, xmimpflag_table))


# NATIONAL code to place names 

df1 <- df1 |> mutate(
NATIONAL = replace_codes_one_column_table(NATIONAL, national_table))


# TONTYPE code to names 

df1 <- df1 |> mutate(
TONTYPE = replace_codes_one_column_table(TONTYPE, tontype_table))

# RIG code to names 

df1 <- df1 |> mutate(
RIG = replace_codes_one_column_table(RIG, rig_table))

# FATE code to names 

df1 <- df1 |> mutate(
FATE = replace_codes_one_column_table(FATE, fate_table))

# FATE2 code to names 

df1 <- df1 |> mutate(
FATE2 = replace_codes_one_column_table(FATE2, fate2_table))

# FATE3 code to names 

df1 <- df1 |> mutate(
FATE3 = replace_codes_one_column_table(FATE3, fate3_table))

# FATE4 code to names 

df1 <- df1 |> mutate(
FATE4 = replace_codes_one_column_table(FATE4, fate4_table))

# RESISTANCE code to names 

df1 <- df1 |> mutate(
RESISTANCE = replace_codes_one_column_table(RESISTANCE, resistance_table))


#-------years and periods----------

df2 <-
df2 |>
  mutate(
    YRCONS = as.integer(YRCONS),
    YRREG = as.integer(YRREG),
    DATEDEPC = as.integer(DATEDEPC),
    D1SLATRC = as.integer(D1SLATRC),
    DLSLATRC = as.integer(DLSLATRC),
    DATARR34 = as.integer(DATARR34),
    DATARR38 = as.integer(DATARR38),
    DATARR41 = as.integer(DATARR41),
    DDEPAMC = as.integer(DDEPAMC),
    DATARR45 = as.integer(DATARR45),
    YEAR5 = as.integer(YEAR5),
    YEAR10 = as.integer(YEAR10),
    YEAR25 = as.integer(YEAR25),
    YEAR100 = as.integer(YEAR100),
    YEARDEP = as.integer(YEARDEP),
    YEARAF = as.integer(YEARAF),
    YEARAM = as.integer(YEARAM)
  )

#----------months-------------------

df2 <-
df2 |>
  mutate(
     DATEDEPB = as.integer(DATEDEPB),
     D1SLATRB = as.integer(D1SLATRB),
     DLSLATRB = as.integer(DLSLATRB),
     DATARR33 = as.integer(DATARR33),
     DATARR37 = as.integer(DATARR37),
     DATARR40 = as.integer(DATARR40),
     DDEPAMB = as.integer(DDEPAMB),
     DATARR44 = as.integer(DATARR44)
  )

#-----------day----------

df2 <-
df2 |>
  mutate(
     DATEDEPA = as.integer(DATEDEPA),
     D1SLATRA = as.integer(D1SLATRA),
     DLSLATRA = as.integer(DLSLATRA),
     DATARR32 = as.integer(DATARR32),
     DATARR36 = as.integer(DATARR36),
     DATARR39 = as.integer(DATARR39),
     DDEPAM = as.integer(DDEPAM),
     DATARR43 = as.integer(DATARR43)
  )




#---------dates-----------------


# Custom function to handle incomplete dates
convert_dates <- function(date_vector) {
  sapply(date_vector, function(date) {
    # Split the date into parts
    parts <- unlist(strsplit(date, ","))
    day <- ifelse(parts[1] != "", parts[1], "01")   # Default missing day to 01
    month <- ifelse(parts[2] != "", parts[2], "01") # Default missing month to 01
    year <- ifelse(parts[3] != "", parts[3], NA)    # Missing year remains NA
    
    # Combine corrected parts into complete date
    full_date <- paste(day, month, year, sep = ",")
    
    # Convert to Date format (yyyy-mm-dd)
    if (!is.na(year)) {
      return(format(as.Date(full_date, format = "%d,%m,%Y"), "%Y-%m-%d"))
    } else {
      return(NA) # Return NA if year is missing
    }
  })
}



df2 <- df2 |>
  mutate(DATEDEP = as.Date(convert_dates(DATEDEP)),
         DATEBUY = as.Date(convert_dates(DATEBUY)),
         DATELEFTAFR = as.Date(convert_dates(DATELEFTAFR)), 
         DATELAND1 = as.Date(convert_dates(DATELAND1)),
         DATELAND2 = as.Date(convert_dates(DATELAND2)),
         DATELAND3 = as.Date(convert_dates(DATELAND3)),
         DATEDEPAM = as.Date(convert_dates(DATEDEPAM)),
         DATEEND = as.Date(convert_dates(DATEEND))
  )



#-------rename the variables with names that are easier to understand --------

names(df2) <- c("voyage_id", var_names$Definition_Underscore)

#give the R dataframe a better name to work with
awstvDatabase <- df2

write.csv(awstvDatabase,"Atlantic_World_Slave_Trade_voyages_database_with_origins.csv")
 
 
 
