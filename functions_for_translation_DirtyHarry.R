###############################################################################
#
# Functions to be applied to datamapping. Each functions should take as input
# a vector or matrix of values. 
#
###############################################################################
library(dplR)
library(dplyr)
#------------------------------------------------------------------------------
# generate_UUID
#------------------------------------------------------------------------------
generate_UUID <- function(object)
{
  ID_columns_as_vector <- data.frame(ID = apply(format(object), 1, paste0, collapse="|"))
  ID_columns_unique <- data.frame(unique(ID_columns_as_vector))
  
  if (require('dplR','dplyr')) {
    ug <- uuid.gen()
    UUID <- character()
    for(i in 1:length(ID_columns_unique$ID)) {
      ID_columns_unique$UUID[i] <- ug()
    }
    UUID_out <- left_join(ID_columns_as_vector,ID_columns_unique,by="ID")
    return(UUID_out$UUID)
  } else {
    warning('library dplR and dplyr is missing')
  }
}

#------------------------------------------------------------------------------
# paste
#------------------------------------------------------------------------------

paste_values <- function(object,translation_to_apply)
{
  
  translation <- unlist(strsplit(translation_to_apply, split="=", fixed = TRUE))
  if (length(translation)>0){
    if (translation[1]=="prefix") {
      output_data <- cbind(translation[2],object)
    }
    
    if (translation[1]=="sufix") {
      output_data <- cbind(object,translation[2])
      }
    } else {
    output_data <- object
  } 
  output_data_as_vector <- data.frame(data_inn = apply(format(output_data), 1, paste0, collapse="|"))
  return(output_data_as_vector)
}
  

#------------------------------------------------------------------------------
# fill_column_using
#------------------------------------------------------------------------------

fill_column_using <- function(object,translation_to_apply){
  output_data_as_vector <- rep(translation_to_apply,dim(object)[1])
  return(output_data_as_vector)
}

#------------------------------------------------------------------------------
# translate
#------------------------------------------------------------------------------

translate <- function(object,translation_to_apply,translation_table,subject){
  
  object_inn <- data.frame(lapply(object, trimws)) # trim whitespaces in inputdata
  object_inn <- data.frame((data_inn = apply(format(object), 1, paste0, collapse="_")),stringsAsFactors=FALSE) # concatenate columsn
  object_inn <- data.frame(lapply(object_inn, trimws),stringsAsFactors=FALSE) # trim whitespaces in inputdata
  names(object_inn) <- c("original_value") 

  
  if (translation_to_apply=="translation_table"){
    translation_matrix <- as.data.frame(translation_table[translation_table$destination_term==subject,c("original_value","translated_value")],stringsAsFactors=FALSE)
  } else {
    translation_matrix_temp <- unlist(strsplit(translation_to_apply,"|",fixed=TRUE))
    translation_matrix <- as.data.frame(matrix(unlist(strsplit(translation_matrix_temp,"=",fixed=TRUE)),byrow=TRUE,ncol=2),stringsAsFactors=FALSE)
    names(translation_matrix) <- c("original_value","translated_value")
  } 
  
  translated_values <- object_inn$original_value
  for (i in 1:length(translation_matrix$original_value)){
    translated_values[translated_values %in% translation_matrix$original_value[i]] <- translation_matrix$translated_value[i]
  }
  return(translated_values)
}

translate_check <- function(object,translation_to_apply,translation_table){

  object_inn <- data.frame(lapply(object, trimws)) # trim whitespaces in inputdata
  object_inn <- data.frame((data_inn = apply(format(object), 1, paste0, collapse="_")),stringsAsFactors=FALSE) # concatenate columsn
  names(object_inn) <- c("original_value") 
  
  if (translation_to_apply=="translation_table"){
    translation_matrix <- as.data.frame(translation_table[c("original_value","translated_value")],stringsAsFactors=FALSE)
  } else {
    translation_matrix_temp <- unlist(strsplit(translation_to_apply,"|",fixed=TRUE))
    translation_matrix <- as.data.frame(matrix(unlist(strsplit(translation_matrix_temp,"=",fixed=TRUE)),byrow=TRUE,ncol=2),stringsAsFactors=FALSE)
    names(translation_matrix) <- c("original_value","translated_value")
  } 
  
  value_not_in_translation <- unique(object_inn$original_value)[!(unique(object_inn$original_value) %in% unique(translation_matrix$original_value))]
  if (length(value_not_in_translation)>0){
    return(paste("value not mentioned in translation:", value_not_in_translation))
  }
  
}

#------------------------------------------------------------------------------
# xl_date_translation
#------------------------------------------------------------------------------

xl_date_translation <- function(object){
  return(as.Date(object$object_column,origin="1899-12-30"))
}

xl_date_translation_check <- function(object,object_colnames){
  is.date <- function(x) inherits(x, 'Date')
  if (FALSE %in% sapply(as.Date(object$object_column,origin="1899-12-30"), is.date)) {
    return(paste("column marked as xl_date does not provide valid translation:",object_colnames))
  }
}
  
#------------------------------------------------------------------------------
# numeric_operation
#------------------------------------------------------------------------------

numeric_operation <- function(object,translation_to_apply){
  do_numeric_opertation <- function(x){
    eval(parse(text=paste(x,translation_to_apply,sep="")))
  }
  return(do_numeric_opertation(object))
}

#------------------------------------------------------------------------------
# conditional_numeric_translation
#------------------------------------------------------------------------------
conditional_numeric_translation <- function(object,translation_to_apply){
  return(eval(parse(text=gsub("input_data_column_value",object,translation_to_apply,fixed = TRUE))))
}

