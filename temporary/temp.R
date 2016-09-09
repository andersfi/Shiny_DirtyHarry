

#------------------------------------------------------------------------------
# function get_data_from_xlsx_and_flatten_out ---------------------------------
#------------------------------------------------------------------------------
# function takes as innput a mapping table as data.frame (mapping), 
# and a XLConnect workbook object (inndata_wb)
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
  
  # The if statments below does not work on shiny...
  # if (!(is.null(location_sheet))){
  #   location_inn <- readWorksheet(inndata_wb,location_sheet,header = TRUE)
  # }
  # if (is.na(mof_event_sheet)==FALSE){
  #   mof_event_inn <- readWorksheet(inndata_wb,mof_event_inn,header = TRUE)
  # }
  # if (is.na(mof_occurrence_sheet)==FALSE){
  #   mof_occurrence_inn <- readWorksheet(inndata_wb,mof_occurrence_sheet,header = TRUE)
  # }
  
  
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

