

#------------------------------------------------------------------------------
# function get_data_from_xlsx_and_flatten_out ---------------------------------
#------------------------------------------------------------------------------

# function takes as innput a mapping table as data.frame (mapping), 
# and a XLConnect workbook object (inndata_wb). Uses the mapping for choosing
# which columns that constitute unique identifiers for event and occurrences

get_data_from_xlsx_and_flatten_out <- function(inndata_wb,mapping) {
  
  #inndata_wb <- input_data() #loadWorkbook(input_data$datapath, create = F) 
  sheets_inn <- sort(getSheets(inndata_wb)) # get vector of sheet names
  occurrence_sheet <- sheets_inn[charmatch(x="occur",table=sheets_inn)] # test if occurrenc is one of the sheets .. etc
  event_sheet <- sheets_inn[charmatch(x="event",table=sheets_inn)]
  #location_sheet <- sheets_inn[charmatch(x="location",table=sheets_inn)]
  #mof_event_sheet <- sheets_inn[charmatch(x="mof_event",table=sheets_inn)]
  #mof_occurrence_sheet <- sheets_inn[charmatch(x="mof_occur",table=sheets_inn)]
  # get data from the sheets if they exist
  if (is.na(occurrence_sheet)==FALSE){
    occurrence_inn <- readWorksheet (inndata_wb,occurrence_sheet,header = TRUE)
  }
  if (is.na(occurrence_sheet)==TRUE){
    error <- append(error,
                    paste("We can't find a sheet in your workbook named something starting with 'occurrence'"))
  }
  occurrence_inn <- readWorksheet (inndata_wb,occurrence_sheet,header = TRUE)
  if (is.na(event_sheet)==FALSE){
    event_inn <- readWorksheet (inndata_wb,event_sheet,header = TRUE)
  }

  
  #merge the sheets based upon columns defined in mapping table as event, occurrence and location ID columms
  eventID_columns <- unlist(strsplit(as.character(mapping$inputdata_term[mapping$dwc_term=="eventID"]), "|", fixed = TRUE))
  occurrenceID_columns <- unlist(strsplit(as.character(mapping$inputdata_term[mapping$dwc_term=="occurrenceID"]), "|", fixed = TRUE))
  #locationID_columns <- unlist(strsplit(mapping$inputdata_term[mapping$dwc_term=="locationID"], "|", fixed = TRUE))
  # if (exists("location_inn")==TRUE) {
  #   event_inn <- left_join(event_inn,location_inn,by=locationID_columns)
  # }
  # if (exists("mof_event_inn")==TRUE){
  #   event_inn <- left_join(event_inn,mof_event,by=eventID_columns)
  # }
  # if (exists("mof_occurrence_inn")==TRUE){
  #   occurrence_inn <- left_join(occurrence_inn,mof_occurrence,by=occurrenceID_columns)
  # }
  if (exists("event_inn")==TRUE){
    inndata <- left_join(event_inn,occurrence_inn,by=eventID_columns)
  }

  return(inndata)
}



#------------------------------------------------------------------------------
# Functions prefligth_check_of_inndata_and_mapping_table --------------------------------
# check for inconsistencies with given standard
#------------------------------------------------------------------------------

# message
prefligth_check_of_inndata_and_mapping_table <- function(mapping,inndata,terms_and_vocabulary,omen)
  {
  
    # create object to store message ain 
    message <- as.character()
    warning <- as.character()
    error <- as.character()
    
    # get vectors of standard terms and mapping terms from innputdata and mapping table
    inndata_colums_to_delete <- na.omit(unlist(strsplit(as.character(mapping$inputdata_term[mapping$dwc_term==""]), c("|"), fixed = TRUE))) # returns vector of input data column names signed up for deletion
    inndata <- inndata[, !(names(inndata) %in% inndata_colums_to_delete)] # returns inndata as dataframe minus the columns to be deleted
    inndata_names <- names(inndata) # returns vector of innput data columnames minus colums signed up for deletion
    mapping_dwc_terms <- na.omit(mapping$dwc_term) # returns vector of mapping terms given in the mapping table, split values given with | indicating that the input data columsn should be split into multiple terms
    inndata_names_in_mapping <- unique(na.omit(unlist(strsplit(as.character(mapping$inputdata_term), c("|"), fixed = TRUE))))
    
    
    # MESSAGE: list indata columns that has been signed up for deletion
    if (length(inndata_colums_to_delete)>=1){
      message <- append(message,
                        paste("Input-data deleted:", inndata_colums_to_delete)
                        ,after = length(message))
    }

    
    # WARNINGS for innput data column names not mentioned in the mapping
    inndata_names_not_in_mapping <- na.omit(inndata_names[!(inndata_names %in% inndata_names_in_mapping)])
    if (length(inndata_names_not_in_mapping)>=1) {
      warning <- append(warning,
                        paste("Innput-data column not in mapping table:",as.character(inndata_names_not_in_mapping)),
                        after = length(warning))
    }
  
  # ERROR for mapping DwC terms not unique
  duplicated_mapping_terms <- mapping_dwc_terms[duplicated(mapping_dwc_terms[!(mapping_dwc_terms=="")])]
  if (length(duplicated_mapping_terms)>=1) {
    error <- append(error,
                    paste("dwc_terms not unique in mapping table:",duplicated_mapping_terms))
  }
  
  # ERROR for inputdat_term in mapping not occuring in inndata namespace
  inputdata_term_not_in_inndata <- inndata_names_in_mapping[!(inndata_names_in_mapping %in% names(inndata))]
  if (length(inputdata_term_not_in_inndata)>=1) {
    error <- append(error,
                    paste("I am misspelled or misplaced, inputdata_term in mapping not in input data names:",inputdata_term_not_in_inndata))
  }
  
  
  # ERROR for mapping table DwC terms not in standard
  mapping_names_not_vocabulary <- mapping_dwc_terms[!(mapping_dwc_terms[!(mapping_dwc_terms=="")] %in% terms_and_vocabulary$column_name)]
  if (length(mapping_names_not_vocabulary)>=1) {
    warning <- append(warning,
                      paste("Input column not in mapping, not to appear in output:",mapping_names_not_vocabulary))
  }
  if (omen=="error") {return(error)}
  if (omen=="warning") {return(warning)}
  if (omen=="message") {return(message)}
  
}


#------------------------------------------------------------------------------
# map data --------------------------------------------------------------------
#------------------------------------------------------------------------------

map_data_to_dwc <- function(inndata,mapping,translation_table){
  
  outdata_terms <- as.character(na.omit(mapping$dwc_term[!(mapping$dwc_term=="")])) # get vector of terms to mapp to, exluding empty columns
  
  # Create object to store mapping log and errors
  mapping_log <- as.character()
  error <- as.character()
  # Create empty data.frame as startingpoint for filling with mapped values from input data 
  outdata <- as.data.frame(matrix(data=NA,nrow=length(inndata[,1]),ncol=length(outdata_terms)))
  names(outdata) <- outdata_terms
  
  
  
  ## loop through all terms in vector of termes to fit into mapped table.. 
  for (i in 1:length(outdata_terms)){ 
    
    # Determine the subject,object and action of the mapping (i.e. the source column, the destination column and the function)
    subject <- outdata_terms[i]
    object_colnames <- as.character(na.omit(mapping$inputdata_term[mapping$dwc_term==subject]))# should be term[i]
    object <- data.frame(object_column = inndata[,unlist(strsplit(as.character(object_colnames), split=c("|"), fixed = TRUE))])
    func_to_apply <- as.character(na.omit(mapping$translation_function[mapping$dwc_term==subject]))# should be term[i]
    translation_to_apply <- na.omit(mapping$translation[mapping$dwc_term==subject])# should be term[i]
    
    mapping_log <- append(mapping_log,
                          paste("Input-date column",object_colnames,"mapped to", subject, 
                                "using translation function",func_to_apply,":",translation_to_apply))
    # generate_UUID
    if (func_to_apply == "generate_UUID") {
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
      error <- append(error,translate_check(object,translation_to_apply,translation_table))
    }
    # xl_date_translate
    if (func_to_apply == "xl_date_translate"){
      outdata[,subject] <- xl_date_translation(object)
    }
    # xl_date_translation_check
    if (func_to_apply == "xl_date_translate"){
      error <- append(error,xl_date_translation_check(object,object_colnames))
    }
    # conditional_numeric_translation
    if (func_to_apply == "conditional_numeric_translation"){
      outdata[,subject] <- conditional_numeric_translation(object,translation_to_apply)
    }
  }
  
  return(outdata)
}

#------------------------------------------------------------------------------
# Data structuring into event, occurrence and mof tables-----------------------
#------------------------------------------------------------------------------

get_output_data_structure <- function(outdata,mapping,table){
  outdata_terms <- as.character(na.omit(mapping$dwc_term[!(mapping$dwc_term=="")])) # get vector of terms to mapp to, exluding empty columns
  
  # MoF occurrences 
  mof_occurrence_terms <- c("occurrenceID",outdata_terms[outdata_terms %in% terms_and_vocabulary$column_name[terms_and_vocabulary$table_name=="mof_occurrence"]])
  mof_occurrence <- na.omit(gather(outdata[,mof_occurrence_terms],key="occurrenceID"))
  names(mof_occurrence) <- c("occurrenceID","measurementMethod","measurmentValue")
  mof_occurrence <- filter(mof_occurrence,measurmentValue!="NA")
  
  # occurrences 
  occurrence_terms <- c(outdata_terms[outdata_terms %in% terms_and_vocabulary$column_name[terms_and_vocabulary$table_name=="occurrence"]])
  occurrence <- outdata[(outdata$speciesID=="NA")==FALSE,occurrence_terms]
  
  # event 
  event_terms <- outdata_terms[outdata_terms %in% terms_and_vocabulary$column_name[terms_and_vocabulary$table_name=="event"] |
                                 outdata_terms %in% terms_and_vocabulary$column_name[terms_and_vocabulary$table_name=="m_dataset"]]
  event <- distinct(outdata[,event_terms],.keep_all = TRUE)
  if(table=="event") {return(event)}
  if(table=="occurrence") {return(occurrence)}
  if(table=="mof_occurrence") {return(mof_occurrence)}
}
