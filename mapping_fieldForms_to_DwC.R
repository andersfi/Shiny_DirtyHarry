###############################################################################
#
# Mapping procedures for easier transformation from field forms etc.
# to standarized data model based upon DwC. 
#
# takes as input either .csv files or spreadsheet workbook containing
# one or more datafiles/spreadsheets (tabular format) and a mapping table
# describing the transformation:
# mapping table content:
# columns drescribing the input data (inndata_table,column_name,data_type)
# columns describing the destination data field (nofa:class,nofa:term)
# colum descring the transfomation/mapping of the data (transformation), using 
# a syntax function:translation, where the function is a function defined below,
# and the translation is a string of operations. 
#
# NOTE - if date is entered in a spreadsheet with date as origin, we assume that 
# the start date is "1899-12-30" conforming to microsoft xl run on windows platform.
#
###############################################################################

#------------------------------------------------------------------------------
# Required packages
#------------------------------------------------------------------------------
library(tidyr)
library(dplyr)
library(rio)
library(stringr)
library(data.table)

#------------------------------------------------------------------------------
# Read data 
#------------------------------------------------------------------------------

file<-"input_data_example.xlsx"
inndata <- import(file, which=1)
#write.csv(tempdata,"input_data_example.csv")
#inndata <- read.csv("input_data_example.csv",stringsAsFactors=FALSE,strip.white=TRUE)
mapping <- read.csv("input_table_mapping.csv",stringsAsFactors=FALSE,strip.white=TRUE)
translation_table <- read.csv("input_table_translation.csv",stringsAsFactors=FALSE,strip.white=TRUE)



#------------------------------------------------------------------------------
# Get list of valid column names, vocabulary and table placements 
#
# Section should return the data.frames; 
# "controlled_vocabulary" with columns "term" and "value" describing the accepted 
# values (as characters) for each term.
# "terms_and_vocabulary" which must contain the columns "table_name" and "column_name" that indicate the 
# term and the table placement in a DwC-A / DB. 
# 
#------------------------------------------------------------------------------
# Here, we import this from DB in the script dataIO_nofa_db.R. 
source("dataIO_nofa_db.R")
# idea: could use consept such as https://docs.google.com/spreadsheets/d/1FYRh04Sk_Udh3XTWjGs8fcedj_0fk-1XTCQ_P1onO6A/edit#gid=0 as input for vanilla DwC. 




#------------------------------------------------------------------------------
# Prefligth check of inndata and mapping table for inconsistencies with given standard
#------------------------------------------------------------------------------

# get vectors of standard terms and mapping terms from innputdata and mapping table
inndata_colums_to_delete <- na.omit(unlist(strsplit(as.character(mapping$inputdata_term[mapping$dwc_term==""]), c("|"), fixed = TRUE))) # returns vector of input data column names signed up for deletion
inndata <- inndata[, !(names(inndata) %in% inndata_colums_to_delete)] # returns inndata as dataframe minus the columns to be deleted
inndata_names <- names(inndata) # returns vector of innput data columnames minus colums signed up for deletion
mapping_dwc_terms <- na.omit(mapping$dwc_term) # returns vector of mapping terms given in the mapping table, split values given with | indicating that the input data columsn should be split into multiple terms
inndata_names_in_mapping <- unique(na.omit(unlist(strsplit(mapping$inputdata_term, c("|"), fixed = TRUE))))

# first create objects to store message and error output in
message <- as.character()
error <- as.character()
warning <- as.character()

# MESSAGE: list indata columns that has been signed up for deletion
if (length(inndata_colums_to_delete)>=1){
  message <- append(message,
                    paste("Column from inndata deleted as described in mapping table:", inndata_colums_to_delete)
                    ,after = length(message))
              }

# WARNINGS for innput data column names not mentioned in the mapping
inndata_names_not_in_mapping <- na.omit(inndata_names[!(inndata_names %in% inndata_names_in_mapping)])
if (length(inndata_names_not_in_mapping)>=1) {
  warning <- append(warning,
                  paste("Inndata column name not mentioned in mapping table:",inndata_names_not_in_mapping))
  
}

# ERROR for mapping table DwC terms not in standard
duplicated_mapping_terms <- mapping_dwc_terms[duplicated(mapping_dwc_terms[!(mapping_dwc_terms=="")])]
if (length(mapping_names_not_vocabulary)>=1) {
  error <- append(error,
                  paste("dwc_terms not unique in mapping table:",duplicated_mapping_terms))
}

# ERROR for mapping table DwC terms not in standard
mapping_names_not_vocabulary <- mapping_dwc_terms[!(mapping_dwc_terms[!(mapping_dwc_terms=="")] %in% dwc_terms)]
if (length(mapping_names_not_vocabulary)>=1) {
  error <- append(error,
                  paste("Inndata column names lacking in mapping table:",inndata_names_not_in_mapping))
}

#------------------------------------------------------------------------------
# The data mapping 
#------------------------------------------------------------------------------
# redo following line by taking table class from NOFA as to get terms automatically fitted into table?
# Create vector of terms to fit into mapped table 
outdata_terms <- as.character(na.omit(mapping$dwc_term[!(mapping$dwc_term=="")])) # get vector of terms to mapp to, exluding empty columns

# Create object to store mapping log 
mapping_log <- as.character()

# Create empty data.frame as startingpoint for filling with mapped values from input data 
outdata <- as.data.frame(matrix(data=NA,nrow=length(inndata[,1]),ncol=length(outdata_terms)))
names(outdata) <- outdata_terms

source("func_to_apply.R")

## loop through all terms in vector of termes to fit into mapped table.. 
for (i in 1:length(outdata_terms)){ 
  
  # Determine the subject,object and action of the mapping (i.e. the source column, the destination column and the function)
  subject <- outdata_terms[i]
  object_colnames <- as.character(na.omit(mapping$inputdata_term[mapping$dwc_term==subject]))# should be term[i]
  object <- data.frame(object_column = inndata[,unlist(strsplit(object_colnames, split=c("|"), fixed = TRUE))])
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
    outdata[,subject] <- translate(object,translation_to_apply)
  }
  # translate_check
  if (func_to_apply == "translate") {
    error <- append(error,translate_check(object,translation_to_apply,subject))
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

#------------------------------------------------------------------------------
# The data structuring - get outdata into rigth tables and format by using
# the 
#------------------------------------------------------------------------------

# MoF occurrences 
mof_occurrence_terms <- c("occurrenceID",outdata_terms[outdata_terms %in% terms_and_vocabulary$column_name[terms_and_vocabulary$table_name=="mof_occurrence"]])
mof_occurrence <- na.omit(gather(outdata[,mof_occurrence_terms],key="occurrenceID"))
names(mof_occurrence) <- c("occurrenceID","measurementMethod","measurmentValue")
mof_occurrence <- filter(mof_occurrence,measurmentValue!="NA")

# occurrences 
occurrence_terms <- c(outdata_terms[outdata_terms %in% terms_and_vocabulary$column_name[terms_and_vocabulary$table_name=="occurrence"]])
occurrence <- outdata[,occurrence_terms]

# event 
event_terms <- outdata_terms[outdata_terms %in% terms_and_vocabulary$column_name[terms_and_vocabulary$table_name=="event"] |
                                 outdata_terms %in% terms_and_vocabulary$column_name[terms_and_vocabulary$table_name=="m_dataset"]]
event <- distinct(outdata[,event_terms],.keep_all = TRUE)

