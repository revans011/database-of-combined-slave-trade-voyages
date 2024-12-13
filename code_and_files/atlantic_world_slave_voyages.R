
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


path <- "numeric_lookup_files/"


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

# ----------- turn empty double quotes in character vars into missing ------------------
intra <- intra |>
    mutate(across(where(is.character), ~ na_if(., "")))

trans <- trans |>
    mutate(across(where(is.character), ~ na_if(., "")))

#make the grouping variable to identify which data came from which slavevoyages.org dataset

intra <- intra |>
  mutate(intra_or_trans = "intra_american")

trans <- trans |>
  mutate(intra_or_trans = "trans_atlantic")

#  combine the two datasets

df <- bind_rows(intra,trans) 



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
    year_vessel_construction = as.integer(YRCONS),
    year_vessel_registration = as.integer(YRREG),
    year_voyage_began = as.integer(DATEDEPC),
    year_slave_purchase_began = as.integer(D1SLATRC),
    year_left_last_slaving_port = as.integer(DLSLATRC),
    year_first_disembarkation = as.integer(DATARR34),
    year_second_disembarkation = as.integer(DATARR38),
    year_third_disembarkation = as.integer(DATARR41),
    year_departure_last_place = as.integer(DDEPAMC),
    year_voyage_completed = as.integer(DATARR45),
    period_5_year = as.integer(YEAR5),
    period_decade = as.integer(YEAR10),
    period_quarter_century = as.integer(YEAR25),
    period_century = as.integer(YEAR100),
    year_imputed_voyage_began = as.integer(YEARDEP),
    year_imputed_left_africa = as.integer(YEARAF),
    year_imputed_arrival = as.integer(YEARAM)
  )

#----------months-------------------

df2 <-
df2 |>
  mutate(
    month_voyage_began = as.integer(DATEDEPB),
    month_slave_purchase_began = as.integer(D1SLATRB),
    month_left_last_slaving_port = as.integer(DLSLATRB),
    month_first_disembarkation = as.integer(DATARR33),
    month_second_disembarkation = as.integer(DATARR37),
    month_third_disembarkation = as.integer(DATARR40),
    month_departure_last_place = as.integer(DDEPAMB),
    month_voyage_completed = as.integer(DATARR44)
  )

#-----------day----------

df2 <-
df2 |>
  mutate(
    day_voyage_began = as.integer(DATEDEPA),
    day_slave_purchase_began = as.integer(D1SLATRA),
    day_left_last_slaving_port = as.integer(DLSLATRA),
    day_first_disembarkation = as.integer(DATARR32),
    day_second_disembarkation = as.integer(DATARR36),
    day_third_disembarkation = as.integer(DATARR39),
    day_departure_last_place = as.integer(DDEPAM),
    day_voyage_completed = as.integer(DATARR43)
  )


#---------dates-----------------

df2 <-
df2 |>
mutate(
    voyage_began_date = make_datetime(year = year_voyage_began, month = month_voyage_began, day = day_voyage_began),
    slave_purchase_began_date = make_datetime(year = year_slave_purchase_began, month = month_slave_purchase_began, day = day_slave_purchase_began),
    left_last_slaving_port_date = make_datetime(year = year_left_last_slaving_port, month = month_left_last_slaving_port, day = day_left_last_slaving_port),
    first_disembarkation_date = make_datetime(year = year_first_disembarkation, month = month_first_disembarkation, day = day_first_disembarkation),
    second_disembarkation_date = make_datetime(year = year_second_disembarkation, month = month_second_disembarkation, day = day_second_disembarkation),
    third_disembarkation_date = make_datetime(year = year_third_disembarkation, month = month_third_disembarkation, day = day_third_disembarkation),
    departure_last_place_date = make_datetime(year = year_departure_last_place, month = month_departure_last_place, day = day_departure_last_place),
    voyage_completed_date = make_datetime(year = year_voyage_completed, month = month_voyage_completed, day = day_voyage_completed)
  )


#-------rename the variables with names that are easier to understand --------

variable_names <- c("VOYAGEID", "ADLT1IMP", "ADLT2IMP", "ADLT3IMP", "ADPSALE1", "ADPSALE2", "ADULT1", 
                    "ADULT2", "ADULT3", "ADULT4", "ADULT5", "ADULT6", "ADULT7", "ARRPORT", "ARRPORT2", 
                    "BOY1", "BOY2", "BOY3", "BOY4", "BOY5", "BOY6", "BOY7", "BOYRAT1", "BOYRAT3", "BOYRAT7", 
                    "CAPTAINA", "CAPTAINB", "CAPTAINC", "CHIL1IMP", "CHIL2IMP", "CHIL3IMP", "CHILD1", 
                    "CHILD2", "CHILD3", "CHILD4", "CHILD5", "CHILD6", "CHILD7", "CHILRAT1", "CHILRAT3", 
                    "CHILRAT7", "CONSTREG", "CREW", "CREW1", "CREW2", "CREW3", "CREW4", "CREW5", "CREWDIED", 
                    "D1SLATRA", "D1SLATRB", "D1SLATRC", "DATARR32", "DATARR33", "DATARR34", "DATARR36", 
                    "DATARR37", "DATARR38", "DATARR39", "DATARR40", "DATARR41", "DATARR43", "DATARR44", 
                    "DATARR45", "DATEBUY", "DATEDEP", "DATEDEPA", "DATEDEPAM", "DATEDEPB", "DATEDEPC", 
                    "DATEEND", "DATELAND1", "DATELAND2", "DATELAND3", "DATELEFTAFR", "DDEPAM", "DDEPAMB", 
                    "DDEPAMC", "DEPTREGIMP", "DEPTREGIMP1", "DLSLATRA", "DLSLATRB", "DLSLATRC", "EMBPORT", 
                    "EMBPORT2", "EMBREG", "EMBREG2", "EVGREEN", "FATE", "FATE2", "FATE3", "FATE4", 
                    "FEMALE1", "FEMALE2", "FEMALE3", "FEMALE4", "FEMALE5", "FEMALE6", "FEMALE7", 
                    "FEML1IMP", "FEML2IMP", "FEML3IMP", "GIRL1", "GIRL2", "GIRL3", "GIRL4", "GIRL5", 
                    "GIRL6", "GIRL7", "GIRLRAT1", "GIRLRAT3", "GIRLRAT7", "GUNS", "INFANT1", "INFANT2", 
                    "INFANT3", "INFANT4", "INFANT5", "INFANT6", "JAMCASPR", "MAJBUYPT", "MAJBYIMP", 
                    "MAJBYIMP1", "MAJSELPT", "MALE1", "MALE2", "MALE3", "MALE4", "MALE5", "MALE6", 
                    "MALE7", "MALE1IMP", "MALE2IMP", "MALE3IMP", "MALRAT1", "MALRAT3", "MALRAT7", 
                    "MEN1", "MEN2", "MEN3", "MEN4", "MEN5", "MEN6", "MEN7", "MENRAT1", "MENRAT3", "MENRAT7", 
                    "MJBYPTIMP", "MJSELIMP", "MJSELIMP1", "MJSLPTIMP", "NATINIMP", "NATIONAL", "NCAR13", 
                    "NCAR15", "NCAR17", "NDESERT", "NPAFTTRA", "NPPRETRA", "NPPRIOR", "OWNERA", "OWNERB", 
                    "OWNERC", "OWNERD", "OWNERE", "OWNERF", "OWNERG", "OWNERH", "OWNERI", "OWNERJ", 
                    "OWNERK", "OWNERL", "OWNERM", "OWNERN", "OWNERO", "OWNERP", "PLAC1TRA", "PLAC2TRA", 
                    "PLAC3TRA", "PLACCONS", "PLACREG", "PORTDEP", "PORTRET", "PTDEPIMP", "REGARR", 
                    "REGARR2", "REGDIS1", "REGDIS2", "REGDIS3", "REGEM1", "REGEM2", "REGEM3", "REGISREG", 
                    "RESISTANCE", "RETRNREG", "RETRNREG1", "RIG", "SAILD1", "SAILD2", "SAILD3", "SAILD4", 
                    "SAILD5", "SHIPNAME", "SLA1PORT", "SLAARRIV", "SLADAFRI", "SLADAMER", "SLADVOY", 
                    "SLAMIMP", "SLAS32", "SLAS36", "SLAS39", "SLAVEMA1", "SLAVEMA3", "SLAVEMA7", 
                    "SLAVEMX1", "SLAVEMX3", "SLAVEMX7", "SLAVMAX1", "SLAVMAX3", "SLAVMAX7", "SLAXIMP", 
                    "SLINTEN2", "SLINTEND", "SOURCEA", "SOURCEB", "SOURCEC", "SOURCED", "SOURCEE", 
                    "SOURCEF", "SOURCEG", "SOURCEH", "SOURCEI", "SOURCEJ", "SOURCEK", "SOURCEL", 
                    "SOURCEM", "SOURCEN", "SOURCEO", "SOURCEP", "SOURCEQ", "SOURCER", "TONMOD", 
                    "TONNAGE", "TONTYPE", "TSLAVESD", "TSLAVESP", "TSLMTIMP", "VOY1IMP", "VOY2IMP", 
                    "VOYAGE", "VYMRTIMP", "VYMRTRAT", "WOMEN1", "WOMEN2", "WOMEN3", "WOMEN4", "WOMEN5", 
                    "WOMEN6", "WOMEN7", "WOMRAT1", "WOMRAT3", "WOMRAT7", "XMIMPFLAG", "YEAR5", "YEAR10", 
                    "YEAR25", "YEAR100", "YEARAF", "YEARAM", "YEARDEP", "YRCONS", "YRREG")

easy_names <- c("voyage_id", "adults_embarked", "adults_died_middle_passage_imputed", 
                "adults_landed", "second_slave_landing", "third_slave_landing", 
                "adults_embarked_first_port", "adults_died_middle_passage", 
                "adults_dismbarked_first_landing", "adults_embarked_second_port", 
                "adults_embarked_third_port", "adults_disembarked_second_landing", 
                "adults_departure_arrival", "first_disembarkation_port", 
                "second_disembarkation_port", "boys_embarked_first_port", 
                "boys_died_middle_passage", "boys_disembarked_first_landing", 
                "boys_embarked_second_port", "boys_embarked_third_port", 
                "boys_disembarked_second_landing", "boys_departure_arrival", 
                "percentage_boys_embarked", "percentage_boys_landed", 
                "percentage_boys_departure_arrival", "first_captain_name", 
                "second_captain_name", "third_captain_name", "children_embarked", 
                "children_died_middle_passage_imputed", "children_landed", 
                "children_embarked_first_port", "children_died_middle_passage", 
                "children_disembarked_first_landing", "children_embarked_second_port", 
                "children_embarked_third_port", "children_disembarked_second_landing", 
                "children_departure_arrival", "percentage_children_embarked", 
                "percentage_children_landed", "percentage_children_departure_arrival", 
                "vessel_construction_region", "crew_number", "crew_voyage_outset", 
                "crew_departure_last_port", "crew_first_landing", "crew_return_voyage", 
                "crew_end_voyage", "crew_died_total", "slave_purchase_day", 
                "slave_purchase_month", "slave_purchase_year", "first_disembarkation_day", 
                "first_disembarkation_month", "first_disembarkation_year", 
                "second_landing_day", "second_landing_month", "second_landing_year", 
                "third_disembarkation_day", "third_disembarkation_month", 
                "third_disembarkation_year", "voyage_completion_day", 
                "voyage_completion_month", "voyage_completion_year", 
                "slave_purchase_date", "voyage_start_date", "voyage_start_day", 
                "return_voyage_date", "voyage_start_month", "voyage_start_year", 
                "voyage_end_date", "first_landing_date", "second_landing_date", 
                "third_landing_date", "departure_last_port_date", 
                "departure_last_landing_day", "departure_last_landing_month", 
                "departure_last_landing_year", "voyage_start_region", 
                "voyage_start_broad_region", "departure_last_port_day", 
                "departure_last_port_month", "departure_last_port_year", 
                "first_embarkation_port", "second_embarkation_port", 
                "first_embarkation_region", "second_embarkation_region", 
                "voyage_cdrom_1999", "voyage_outcome", "slave_outcome", 
                "captured_voyage_outcome", "owner_voyage_outcome", 
                "females_embarked_first_port", "females_died_middle_passage", 
                "females_disembarked_first_landing", "females_embarked_second_port", 
                "females_embarked_third_port", "females_disembarked_second_landing", 
                "females_departure_arrival", "derived_females_embarked", 
                "derived_females_died_middle_passage", "derived_females_landed", 
                "girls_embarked_first_port", "girls_died_middle_passage", 
                "girls_disembarked_first_landing", "girls_embarked_second_port", 
                "girls_embarked_third_port", "girls_disembarked_second_landing", 
                "girls_departure_arrival", "percentage_girls_embarked", 
                "percentage_girls_landed", "percentage_girls_departure_arrival", 
                "guns_mounted", "infants_embarked_first_port", "infants_died_middle_passage", 
                "infants_disembarked_first_landing", "infants_embarked_second_port", 
                "infants_embarked_third_port", "infants_disembarked_second_landing", 
                "average_slave_price_jamaica", "principal_slave_purchase_place", 
                "imputed_slave_purchase_region", "imputed_broad_slave_purchase_region", 
                "principal_slave_disembarkation_port", "males_embarked_first_port", 
                "males_died_middle_passage", "males_disembarked_first_landing", 
                "males_embarked_second_port", "males_embarked_third_port", 
                "males_disembarked_second_landing", "males_departure_arrival", 
                "derived_males_embarked", "derived_males_died_middle_passage", 
                "derived_males_landed", "percentage_males_embarked", 
                "percentage_males_landed", "percentage_males_departure_arrival", 
                "men_embarked_first_port", "men_died_middle_passage", 
                "men_disembarked_first_landing", "men_embarked_second_port", 
                "men_embarked_third_port", "men_disembarked_second_landing", 
                "men_departure_arrival", "percentage_men_embarked", 
                "percentage_men_landed", "percentage_men_departure_arrival", 
                "imputed_slave_purchase_place", "imputed_slave_disembarkation_region", 
                "imputed_broad_slave_disembarkation_region", "imputed_slave_disembarkation_port", 
                "imputed_ship_registered_country", "ship_registered_country", 
                "slaves_carried_first_port", "slaves_carried_second_port", 
                "slaves_carried_third_port", "crew_deserted_total", 
                "atlantic_crossing_call_port", "ports_call_before_buying_slaves", 
                "americas_call_ports_before_sale", "first_owner_venture", 
                "second_owner_venture", "third_owner_venture", "fourth_owner_venture", 
                "fifth_owner_venture", "sixth_owner_venture", "seventh_owner_venture", 
                "eighth_owner_venture", "ninth_owner_venture", "tenth_owner_venture", 
                "eleventh_owner_venture", "twelfth_owner_venture", 
                "thirteenth_owner_venture", "fourteenth_owner_venture", 
                "fifteenth_owner_venture", "sixteenth_owner_venture", 
                "first_slave_purchase_place", "second_slave_purchase_place", 
                "third_slave_purchase_place", "vessel_construction_place", 
                "vessel_registration_place", "departure_port", "voyage_end_place", 
                "imputed_voyage_start_port", "first_intended_slave_landing_region", 
                "second_intended_slave_landing_region", "first_slave_landing_region", 
                "second_slave_landing_region", "third_slave_landing_region", 
                "first_slave_embarkation_region", "second_slave_embarkation_region", 
                "third_slave_embarkation_region", "vessel_registration_region", 
                "african_resistance", "return_region", "broad_return_region", 
                "vessel_rig", "crew_died_first_trade_africa", "crew_died_africa_coast", 
                "crew_died_middle_passage", "crew_died_americas", 
                "crew_died_return_voyage", "vessel_name", "first_slave_landing_place", 
                "total_slaves_first_port", "slave_deaths_before_leaving_africa", 
                "slave_deaths_arrival_sale", "slave_deaths_africa_americas", 
                "imputed_total_slaves_disembarked", "slaves_disembarked_first_place", 
                "slaves_disembarked_second_place", "slaves_disembarked_third_place", 
                "slaves_identified_age_first_embarkation", "slaves_identified_age_first_landed", 
                "slaves_identified_age_departure_arrival", "slaves_identified_gender_first_embarkation", 
                "slaves_identified_gender_first_landed", "slaves_identified_gender_departure_arrival", 
                "slaves_identified_age_gender_first_embarkation", 
                "slaves_identified_age_gender_first_landed", 
                "slaves_identified_age_gender_departure_arrival", "imputed_total_slaves_embarked", 
                "slaves_intended_second_purchase", "slaves_intended_first_purchase", 
                "first_information_source", "second_information_source", 
                "third_information_source", "fourth_information_source", 
                "fifth_information_source", "sixth_information_source", 
                "seventh_information_source", "eighth_information_source", 
                "ninth_information_source", "tenth_information_source", 
                "eleventh_information_source", "twelfth_information_source", 
                "thirteenth_information_source", "fourteenth_information
_source", 
                "fifteenth_information_source", "sixteenth_information_source", 
                "seventeenth_information_source", "eighteenth_information_source", 
                "standardized_tonnage", "vessel_tonnage", "ton_definition", 
                "total_slaves_boarded_last_port", "total_slaves_purchased", 
                "derived_slaves_embarked_mortality", "voyage_length_home_disembarkation", 
                "voyage_length_africa_disembarkation", "middle_passage_length_days", 
                "derived_slave_deaths_middle_passage", "slave_mortality_rate", 
                "women_embarked_port", "women_died_middle_passage", 
                "women_disembarked_first_landing", "women_embarked_second_port", 
                "women_embarked_third_port", "women_disembarked_second_landing", 
                "women_departure_arrival", "percentage_women_embarked", 
                "percentage_women_landed", "percentage_women_departure_arrival", 
                "imputed_slaves_grouping_voyage", "five_year_period_voyage", 
                "decade_voyage_occurred", "quarter_century_voyage_occurred", 
                "century_voyage_occurred", "imputed_year_departed_africa", 
                "imputed_year_arrival_disembarkation", "imputed_year_voyage_began", 
                "vessel_construction_year", "vessel_registration_year")


# # Create a named vector for renaming variables
 names_mapping <- setNames(easy_names, variable_names)
# 
# # Rename variables in df2 using the mapping
 df2 <- df2 %>%
   rename_with(~ names_mapping[.], all_of(variable_names))

# write the csv file
 
 #write.csv(df2,"Atlantic_World_Slave_voyages.csv")
 