require(XLConnect)
require(dplyr)
require(tidyr)

# Convinience for getting data inn when testing. Uncomment when run as stand-alone script. In addition, see line 37 and 38
inndata_url <- "/home/andersfi/R/Shiny/Shiny_DirtyHarry/input_data_example_UiT.xlsx"
# terms_and_tables is a table containing the columns term and table reffering to destination column and destination table

#-----------------------------------------------------------------------------
# Chose input terms and vocabulary--------------------------------------------
#-----------------------------------------------------------------------------
# Can be made reactive in shiny app if one want to let the user choose options 
source("dataIO_nofa_db.R")
terms_and_tables <- NOFA_terms_and_vocabulary 
names(terms_and_tables) <- c("term","table")

#------------------------------------------------------------------------------
# MAIN FUNCTION DirtyHarry-----------------------------------------------------
#------------------------------------------------------------------------------

# function takes as innput a xlsx workbook with sheets describing the data
# (named occurrence*, event*) a table with the mapping (name mapping*), a table with 
# the translation table named translation* (may be empthy).
# output is defined by out 



DirtyHarry <- function(inndata,terms_and_tables,out){
  
  # create vector to save errors and warnings
  error <- character()
  warning <- character()
  
  #----------------------------------------------------------------------------
  # IMPORT AND FLATTEN----- ---------------------------------------------------
  #----------------------------------------------------------------------------
  
  #inndata_wb <- loadWorkbook(input_data$datapath, create = F) # Shiny specific - comment out when run as standalone script
  inndata_wb <- loadWorkbook("/home/andersfi/R/Shiny/Shiny_DirtyHarry/input_data_example_UiT.xlsx", create = F) # uncomment when run as stand alone script
  sheets_inn <- sort(getSheets(inndata_wb)) # get vector of sheet names
  occurrence_sheet <- sheets_inn[charmatch(x="occur",table=sheets_inn)] # test if occurrenc is one of the sheets .. etc
  event_sheet <- sheets_inn[charmatch(x="event",table=sheets_inn)]
  mapping_sheet <- sheets_inn[charmatch(x="mapping",table=sheets_inn)]
  translation_sheet <- sheets_inn[charmatch(x="translation",table=sheets_inn)]
  #mof_event_sheet <- sheets_inn[charmatch(x="mof_event",table=sheets_inn)]
  #mof_occurrence_sheet <- sheets_inn[charmatch(x="mof_occur",table=sheets_inn)]
  
  # get data from the sheets, if they exist
  if (is.na(mapping_sheet)==FALSE){
    mapping_table <- readWorksheet(inndata_wb,mapping_sheet,header = TRUE)
  }
  if (is.na(occurrence_sheet)==TRUE){
    error <- append(error,
                    paste("Bad luck! Can't find the mapping table"))
  }
  if (is.na(translation_sheet)==FALSE){
    translation_table <- readWorksheet(inndata_wb,translation_sheet,header = TRUE)
  }
  if (is.na(translation_sheet)==TRUE){
    error <- append(error,
                    paste("Bad luck! Can't find the translation table"))
  }
  if (is.na(occurrence_sheet)==FALSE){
    occurrence_inn <- readWorksheet(inndata_wb,occurrence_sheet,header = TRUE)
  }
  if (is.na(occurrence_sheet)==TRUE){
    error <- append(error,
                    paste("Bad luck! Can't find the occurrence'ish table"))
  }
  if (is.na(event_sheet)==FALSE){
    event_inn <- readWorksheet(inndata_wb,event_sheet,header = TRUE)
  }

  #----------------------------------------------------------------------------
  # DATA WRANGLING merge and flatten data -------------------------------------
  #----------------------------------------------------------------------------  
  # Note that current implementation assumes each event is listed in the occurrence table,
  # however, each occurrence does not needs to be listed in the event tabel.
  
  eventID_columns <- na.omit(unlist(strsplit(as.character(mapping_table$source_term[mapping_table$destination_term=="eventID"]), "|", fixed = TRUE)))
  occurrenceID_columns <- na.omit(unlist(strsplit(as.character(mapping_table$source_term[mapping_table$destination_term=="occurrenceID"]), "|", fixed = TRUE)))

  if (exists("event_inn")==TRUE){
    inndata <- left_join(event_inn,occurrence_inn,by=eventID_columns)
  } else { 
    inndata <- occurrence_inn
    }

  #############################################################################
  # Data prefligth check 
  #############################################################################
  #----------------------------------------------------------------------------
  # ERROR check if all eventID's are listed in occurrence table ---------------------
  #----------------------------------------------------------------------------
  
  # first make a function that concatenate colums to a string (with | as sep.)
  concatenate_columns <- function(a_data_frame,a_vector_of_column_names){
    columns_without_whitespaces <- data.frame(lapply(a_data_frame[a_vector_of_column_names], trimws)) # trim whitespaces in inputdata
    concetenated_colums <- data.frame((data_inn = apply(format(columns_without_whitespaces), 1, paste0, collapse="_")),stringsAsFactors=FALSE) # concatenate columsn
    names(concetenated_colums) <- c("concetenated_colums")
    return(concetenated_colums$concetenated_colums)
  }
  
  eventID_columns <- as.character(na.omit(unlist(mapping_table$source_term[mapping_table$destination_term=="eventID"])))
  eventID_columns <- unlist(strsplit(eventID_columns,split="|",fixed=TRUE))
  event_inn$fieldNumber <- concatenate_columns(a_data_frame=event_inn,a_vector_of_column_names=eventID_columns)
  occurrence_inn$fieldNumber <- concatenate_columns(a_data_frame=occurrence_inn,a_vector_of_column_names=eventID_columns)

  row_numbers_where_occurrence_eventID_not_in_event <- paste(
    seq(1:length(occurrence_inn$fieldNumber))[(!(occurrence_inn$fieldNumber %in% event_inn$fieldNumber))],collapse=",")
  
  error <- append(error,paste("eventID (or substitude) not found in column(s)", row_numbers_where_occurrence_eventID_not_in_event, "of occurrence table"))
  
  #----------------------------------------------------------------------------
  # WARNING all input data col names in mapping?--------- ---------------------
  #----------------------------------------------------------------------------
    
    # # get vectors of standard terms and mapping terms from innputdata and mapping table
    # inndata_colums_to_delete <- na.omit(unlist(strsplit(as.character(mapping_table$source_term[mapping_table$destination_term==""]), c("|"), fixed = TRUE))) # returns vector of input data column names signed up for deletion
    # inndata <- inndata[, !(names(inndata) %in% inndata_colums_to_delete)] # returns inndata as dataframe minus the columns to be deleted
    # inndata_names <- names(inndata) # returns vector of innput data columnames minus colums signed up for deletion
    # mapping_dwc_terms <- na.omit(mapping$dwc_term) # returns vector of mapping terms given in the mapping table, split values given with | indicating that the input data columsn should be split into multiple terms
    # inndata_names_in_mapping <- 
    
    
    # WARNINGS for innput data column names not mentioned in the mapping
    inndata_names_not_in_mapping <- na.omit(names(inndata)[!(names(inndata) 
                                                            %in% unique(na.omit(unlist(strsplit(as.character(mapping_table$source_term), c("|"), fixed = TRUE)))))])
    if (length(inndata_names_not_in_mapping)>=1) {
      warning <- append(warning,
                        paste("Innput-data column not in mapping table:",as.character(inndata_names_not_in_mapping)),
                        after = length(warning))
    }
  
  #----------------------------------------------------------------------------
  # ERROR destination terms unique?--------------------------------------------
  #----------------------------------------------------------------------------  
  # ERROR for mapping DwC terms not unique
  duplicated_mapping_terms <- na.omit(mapping_table$destination_term)[duplicated(na.omit(mapping_table$destination_term)[!(na.omit(mapping_table$destination_term)=="")])]
  if (length(duplicated_mapping_terms)>=1) {
    error <- append(error,
                    paste("Destination term not unique in mapping table:",duplicated_mapping_terms))
  }
  
  #----------------------------------------------------------------------------
  # ERROR mapped input data terms not in input data?--------- -----------------
  #------------------------------------------ ---------------------------------
  input_data_terms_in_mapping <- unique(na.omit(unlist(strsplit(as.character(mapping_table$source_term), c("|"), fixed = TRUE))))
  mapped_input_data_term_not_in_inndata <- input_data_terms_in_mapping[!(input_data_terms_in_mapping %in% names(inndata))]
  if (length(mapped_input_data_term_not_in_inndata)>=1) {
    error <- append(error,
                    paste("Misspelled, misplaced or misunderstood - inputdata_term in mapping not in input data names:",mapped_input_data_term_not_in_inndata))
  }

  #----------------------------------------------------------------------------
  # ERROR mapping table source term not in standar?---------- -----------------
  #------------------------------------------ ---------------------------------  
  
  mapping_names_not_standard <- as.character(na.omit(mapping_table$destination_term[!(mapping_table$destination_term[!(mapping_table$destination_term=="")] %in% terms_and_tables$term)]))

  if (length(mapping_names_not_standard)>=1) {
    error <- append(error,
                      paste("destination_term '",mapping_names_not_standard, "' not a term in chosen standard. Bad hair day?",sep=""))
  }



#------------------------------------------------------------------------------
# MAP AND TRANSLATE DATA ------------------------------------------------------
#------------------------------------------------------------------------------


  # get vector of terms to mapp to, exluding empty columns
  outdata_terms <- as.character(na.omit(mapping_table$destination_term[!(mapping_table$destination_term=="")])) 
  
  # Create object to store mapping log
  mapping_log <- as.character()
  mapping_error <- as.character()
  
  # check that all mapping_destination terms have a corresponding translation function 
  mapping_terms_without_translation_function <- na.omit(mapping_table$destination_term[mapping_table$translation_function==""])

  if(length(mapping_terms_without_translation_function)>0){
    mapping_error <- append(mapping_log,
                            paste("translation function(s) missing"))
  }     
  
  
  # Create empty data.frame as startingpoint for filling with mapped values from input data 
  outdata <- as.data.frame(matrix(data=NA,nrow=length(inndata[,1]),ncol=length(outdata_terms)))
  names(outdata) <- outdata_terms
  #----------------------------------------------------------------------------
  ## LOOP through all destination terms and map -------------------------------
  #----------------------------------------------------------------------------
  ## Functions defined in "functions_for_translation_DirtyHarry.
  source("functions_for_translation_DirtyHarry.R")
  
  for (i in 1:length(outdata_terms)){ 
    
    # Determine the subject,object and action of the mapping (i.e. the source column, the destination column and the function)
    subject <- outdata_terms[i] # destination_term for which to map data
    object_colnames_string <- as.character(na.omit(mapping_table$source_term[mapping_table$destination_term==subject])) # the source_term corresponding to the destination_term
    object_colnames <- unlist(strsplit(as.character(object_colnames_string), split=c("|"), fixed = TRUE)) # split string
    object_colnames <- trimws(object_colnames,which="both") # , and remove potential whitespaces introduced by slopplyness
    object <- data.frame(object_column = inndata[,object_colnames]) # get the data from which to map. May be one column of input data or several
    func_to_apply <- as.character(na.omit(mapping_table$translation_function[mapping_table$destination_term==subject])) # get the translation function corresponding to destination_term
    translation_to_apply <- na.omit(mapping_table$translation[mapping_table$destination_term==subject]) # get the corresponding translation as described by the translation column in the mapping_table
    
    mapping_log <- append(mapping_log,
                          paste("Input-data column(s)",object_colnames_string,"mapped to", subject, 
                                "using translation function",func_to_apply,translation_to_apply))
    

    # generate_UUID
    if (func_to_apply == "generate_UUID"){
      outdata[,subject] <- generate_UUID(object)
    }
    # numeric_operation
    if (func_to_apply == "numeric_operation") {
      outdata[,subject] <- numeric_operation(object,translation_to_apply)
    }
    # paste_values
    if (func_to_apply == "paste_values") {
      outdata[,subject] <- paste_values(object,translation_to_apply)
    }
    # fill_column_using
    if (func_to_apply == "fill_column_using") {
      outdata[,subject] <- fill_column_using(object,translation_to_apply)
    }
    # translate
    if (func_to_apply == "translate") {
      outdata[,subject] <- translate(object,translation_to_apply,translation_table,subject)
    }
    # translate_check
    if (func_to_apply == "translate") {
      mapping_error <- append(error,translate_check(object,translation_to_apply,translation_table))
    }
    # xl_date_translate
    if (func_to_apply == "xl_date_translate"){
      outdata[,subject] <- xl_date_translation(object)
    }
    # xl_date_translation_check
    if (func_to_apply == "xl_date_translate"){
      mapping_error <- append(error,xl_date_translation_check(object,object_colnames))
    }
    # conditional_numeric_translation
    if (func_to_apply == "conditional_numeric_translation"){
      outdata[,subject] <- conditional_numeric_translation(object,translation_to_apply)
    }
  }
  


  #------------------------------------------------------------------------------
  # STRUCTUR DATA into destination_tables ---------------------------------------
  #------------------------------------------------------------------------------
  # WARNING: This part is written for NOFA 
  # Other datamodels may give unplesent suprises if applied without modifying this section. i.e. 
  # this section could probably be modified to be general, but when then probably need a data-model input of some sort? 
  # However, it should be a very small efforth to make it map to a DwC-A. 
  
  # Get list of tables for which destination_term is used, exluding lookup-tables (in NOFA starting with "l_")
  # Outdata_terms defined above
  tables_found <- unique(terms_and_tables$table[terms_and_tables$term %in% outdata_terms])
  lookup_tables <- tables_found[startsWith(tables_found,prefix="l_")]
  tables_to_be_mapped <- tables_found[!(tables_found %in% lookup_tables)]
  termes_not_mapped <- terms_and_tables$term[terms_and_tables$table %in% c("event","occurrence","mof_occurrence","mof_event","m_dataset")]
  
  if(is.null(tables_to_be_mapped)==FALSE){
    mapping_log <- append(mapping_error,paste("we found terms mapping to the following tables:",paste(tables_found,collapse=", "),
                                              ". only terms belonging to event, occurrence and mof_occurrence, mof_event, m_dataset will be mapped"))
  }

  # MoF occurrences - if there are data assigned for mof_occurrences
  if("mof_occurrence" %in% tables_to_be_mapped==TRUE){
    mof_occurrence_terms <- c("occurrenceID",outdata_terms[outdata_terms %in% terms_and_tables$term[terms_and_tables$table=="mof_occurrence"]])
    if(length(mof_occurrence_terms)>1){
      mof_occurrence <- na.omit(gather(outdata[,mof_occurrence_terms],key="occurrenceID"))
      names(mof_occurrence) <- c("occurrenceID","measurementMethod","measurmentValue")
      mof_occurrence <- filter(mof_occurrence,measurmentValue!="NA")
    }
  }

# MoF event - if there are data assigned for mof_occurrences
  if("mof_event" %in% tables_to_be_mapped==TRUE){
    mof_event_terms <- c("eventID",outdata_terms[outdata_terms %in% terms_and_tables$term[terms_and_tables$table=="mof_event"]])
    if(length(mof_event_terms)>1){
      mof_event <- na.omit(gather(outdata[,mof_event_terms],key="eventID"))
      names(mof_event) <- c("eventID","measurementMethod","measurmentValue")
      mof_event <- filter(mof_event,measurmentValue!="NA")
    }
  }


  # occurrences 
  if("occurrence" %in% tables_to_be_mapped==TRUE){
  occurrence_terms <- c(outdata_terms[outdata_terms %in% terms_and_tables$term[terms_and_tables$table=="occurrence"]])
  occurrence <- outdata[(outdata$speciesID=="NA")==FALSE,occurrence_terms]
  }
  
  # event
  if("event" %in% tables_to_be_mapped==TRUE){
  event_terms <- outdata_terms[outdata_terms %in% terms_and_tables$term[terms_and_tables$table=="event"]]
  event <- distinct(outdata[,event_terms],.keep_all = TRUE) # return unique rows for events 
  }
  
  if("m_dataset" %in% tables_to_be_mapped==TRUE){
    m_datset_terms <- outdata_terms[outdata_terms %in% terms_and_tables$term[terms_and_tables$table=="m_dataset"]]
    m_dataset <- distinct(outdata[,m_datset_terms],.keep_all = TRUE) # return unique rows for events 
  }

  #------------------------------------------------------------------------------
  # GATHER OUTPUT into xlsx sheet       -----------------------------------------
  #------------------------------------------------------------------------------
  
  wb <- loadWorkbook("outdata_mapping.xlsx", create = TRUE)
  
  if(exists("event")==TRUE){
    createSheet(wb,name="event")
    writeWorksheet(wb, 
                   data=event, 
                   sheet = "event", startRow = 1, startCol = 1)
    setColumnWidth(wb, "event", column=c(1:dim(event)[2]),width = -1)
  }
  
  if(exists("occurrence")==TRUE){
    createSheet(wb,name="occurrence")
    writeWorksheet(wb, 
                   data=occurrence, 
                   sheet = "occurrence", startRow = 1, startCol = 1)
    setColumnWidth(wb, "occurrence", column=c(1:dim(event)[2]),width = -1)
  }
  
  if(exists("mof_occurrence")==TRUE){
    createSheet(wb,name="mof_occurrence")
    writeWorksheet(wb, 
                   data=mof_occurrence, 
                   sheet = "mof_occurrence", startRow = 1, startCol = 1)
    setColumnWidth(wb, "mof_occurrence", column=c(1:dim(event)[2]),width = -1)
  }
  
  if(exists("mof_event")==TRUE){
    createSheet(wb,name="mof_event")
    writeWorksheet(wb, 
                   data=mof_event, 
                   sheet = "mof_event", startRow = 1, startCol = 1)
    setColumnWidth(wb, "mof_event", column=c(1:dim(event)[2]),width = -1)
  }
  
  if(exists("m_dataset")==TRUE){
    createSheet(wb,name="m_dataset")
    writeWorksheet(wb, 
                   data=m_dataset, 
                   sheet = "m_dataset", startRow = 1, startCol = 1)
    setColumnWidth(wb, "m_dataset", column=c(1:dim(event)[2]),width = -1)
  }
  
  # create sheets with mapping and vocabulary tabels (need not to use if() clausul, as they always exsit)
  createSheet(wb,name="mapping_table")
  writeWorksheet(wb, 
                 data=mapping_table, 
                 sheet = "mapping_table", startRow = 1, startCol = 1)
  setColumnWidth(wb, "mapping_table", column=c(1:dim(event)[2]),width = -1)
  
  createSheet(wb,name="translation_table")
  writeWorksheet(wb, 
                 data=translation_table, 
                 sheet = "translation_table", startRow = 1, startCol = 1)
  setColumnWidth(wb, "translation_table", column=c(1:dim(event)[2]),width = -1)
  
  createSheet(wb,name="terms_and_tables")
  writeWorksheet(wb, 
                 data=terms_and_tables, 
                 sheet = "terms_and_tables", startRow = 1, startCol = 1)
  setColumnWidth(wb, "terms_and_tables", column=c(1:dim(event)[2]),width = -1)
  
  # write errors and messages to a wb sheet
  errors_and_messages_1 <- character()
  errors_and_messages_2 <- character()
  
  if(length(error)>0){
    errors_and_messages_1 <- append(errors_and_messages_1,cbind(rep("error",length(error))))
    errors_and_messages_2 <- append(errors_and_messages_2,error)
  }
  if(length(mapping_error)>0){
    errors_and_messages_1 <- append(errors_and_messages_1,cbind(rep("mapping_error",length(mapping_error))))
    errors_and_messages_2 <- append(errors_and_messages_2,mapping_error)
  }
  if(length(warning)>0){
    errors_and_messages_1 <- append(errors_and_messages_1,cbind(rep("warning",length(warning))))
    errors_and_messages_2 <- append(errors_and_messages_2,warning)
  }
  if(length(mapping_log)>0){
    errors_and_messages_1 <- append(errors_and_messages_1,cbind(rep("mapping_log",length(mapping_log))))
    errors_and_messages_2 <- append(errors_and_messages_2,mapping_log)
  }
  
  if(length(errors_and_messages_1)>0){
    errors_and_messages <- as.data.frame(cbind(errors_and_messages_1,errors_and_messages_2))
    names(errors_and_messages) <- c("message_type","message")
    
  }

  if(exists("errors_and_messages")==TRUE){
    createSheet(wb,name="errors_and_messages")
    writeWorksheet(wb, 
                   data=errors_and_messages, 
                   sheet = "errors_and_messages", startRow = 1, startCol = 1)
    setColumnWidth(wb, "errors_and_messages", column=c(1:dim(event)[2]),width = -1)
  }
  

  if(out=="wb"){
    return(wb)
  }

}

#garg <- DirtyHarry(inndata,terms_and_tables,out="wb")
#saveWorkbook(garg)
