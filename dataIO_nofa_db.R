###############################################################################
#
# Returns data fetched from nofa_db as local in-memory dataframes
# - lookup-tables
#
###############################################################################

library(dplyr)
library(RPostgreSQL)
#library(data.table)

# returns connection objects: "nofa_db_RPostgreSQL" using RPostgreSQL
source("db_connect.R") 

#------------------------------------------------------------------------------
# Get list of tables and lookuptables 
#------------------------------------------------------------------------------
# select list of tables from from pg_catalog.pg_tables
nofa_tablelist <- dbGetQuery(nofa_db_RPostgreSQL, "SELECT * FROM pg_catalog.pg_tables 
                             WHERE schemaname='nofa'") 

lookup_tables_names <- filter(nofa_tablelist,grepl("l_",tablename))$tablename
metadata_tables_names <- filter(nofa_tablelist,grepl("m_",tablename))$tablename

# download lookup and admin tables
l_organismQuantityType <-dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"l_organismQuantityType\"") # depricated?
l_sampleSizeUnit <- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"l_sampleSizeUnit\"") # depricated?
l_taxon <- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"l_taxon\"")
l_establishmentMeans<- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"l_establishmentMeans\"")
l_spawningCondition <- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"l_spawningCondition\"")
l_spawningLocation <- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"l_spawningLocation\"")
l_reliability <- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"l_reliability\"")
l_samplingProtocol <- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"l_samplingProtocol\"")
l_sex <- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"l_sex\"")
l_lifeStage <- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"l_lifeStage\"")
l_reproductiveCondition <- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"l_reproductiveCondition\"")
l_mof_occurrence <- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"l_mof_occurrence\"")
m_project <- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"m_project\"")
m_reference <- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"m_reference\"")
m_dataset <- dbGetQuery(nofa_db_RPostgreSQL,"SELECT * FROM nofa.\"m_dataset\"")

#------------------------------------------------------------------------------
# Get vocabulary from lookuptables
# rmarks - kind of corny way of doing it below, probably a smarther way
# rmarks2 - refferenceID not included yet... 
#------------------------------------------------------------------------------
controlled_vocabulary <- data.frame(term=rep("organismQuantityType",length(l_organismQuantityType$organismQuantityType)),value=
      l_organismQuantityType$organismQuantityType)
controlled_vocabulary <-bind_rows(controlled_vocabulary,data.frame(term=rep("sampleSizeUnit",length(l_sampleSizeUnit$sampleSizeUnit))
                                                                   ,value=l_sampleSizeUnit$sampleSizeUnit))
controlled_vocabulary <-bind_rows(controlled_vocabulary,data.frame(term=rep("speciesID",length(l_taxon$speciesID))
                                                                   ,value=as.character(l_taxon$speciesID)))
controlled_vocabulary <-bind_rows(controlled_vocabulary,data.frame(term=rep("establishmentMeans",length(l_establishmentMeans$establishmentMeans)),
                                                                   value=as.character(l_establishmentMeans$establishmentMeans)))
controlled_vocabulary <-bind_rows(controlled_vocabulary,data.frame(term=rep("spawningCondition",length(l_spawningCondition$spawningCondition)),
                                                                   value=as.character(l_spawningCondition$spawningCondition)))
controlled_vocabulary <-bind_rows(controlled_vocabulary,data.frame(term=rep("reliability",length(l_reliability$reliability))
                                                                   ,value=as.character(l_reliability$reliability)))
controlled_vocabulary <-bind_rows(controlled_vocabulary,data.frame(term=rep("samplingProtocol",length(l_samplingProtocol$samplingProtocol))
                                                                   ,value=as.character(l_samplingProtocol$samplingProtocol)))
controlled_vocabulary <-bind_rows(controlled_vocabulary,data.frame(term=rep("sex",length(l_sex$sex))
                                                                   ,value=as.character(l_sex$sex)))
controlled_vocabulary <-bind_rows(controlled_vocabulary,data.frame(term=rep("lifeStage",length(l_lifeStage$lifeStage))
                                                                   ,value=as.character(l_lifeStage$lifeStage)))
controlled_vocabulary <-bind_rows(controlled_vocabulary,data.frame(term=rep("reproductiveCondition",length(l_reproductiveCondition$reproductiveCondition))
                                                                   ,value=as.character(l_reproductiveCondition$reproductiveCondition)))
controlled_vocabulary <-bind_rows(controlled_vocabulary,data.frame(term=rep("projectID",length(m_project$projectID))
                                                                   ,value=as.character(m_project$projectID)))
controlled_vocabulary <-bind_rows(controlled_vocabulary,data.frame(term=rep("referenceID",length(m_reference$referenceID))
                                                                   ,value=as.character(m_reference$referenceID)))
controlled_vocabulary <-bind_rows(controlled_vocabulary,data.frame(term=rep("datasetID",length(m_dataset$datasetID))
                                                                   ,value=as.character(m_dataset$datasetID)))
NOFA_controlled_vocabulary <- controlled_vocabulary
#------------------------------------------------------------------------------
# Get info on NOFA tables
#------------------------------------------------------------------------------
db_tableinfo <- dbGetQuery(nofa_db_RPostgreSQL, "SELECT cols.table_name,cols.column_name,cols.column_default,cols.is_nullable,
                                 CASE
                           WHEN cols.data_type = 'character varying' THEN 'character varying' || '(' || cols.character_maximum_length || ')'
                           ELSE cols.data_type
                           END AS data_type,
                           (
                           SELECT pg_catalog.col_description(c.oid, cols.ordinal_position::int)
                           FROM pg_catalog.pg_class c
                           WHERE
                           c.oid = (SELECT 'nofa.occurrence'::regclass::oid)
                           AND c.relname = cols.table_name
                           ) AS column_comment
                           FROM information_schema.columns cols
                           WHERE
                           -- main tables
                           cols.table_catalog = 'nofa' AND cols.table_name = 'occurrence' AND cols.table_schema = 'nofa'
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'event' AND cols.table_schema = 'nofa'
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'location' AND cols.table_schema = 'nofa'
                           --lookup tables
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'l_taxon' AND cols.table_schema = 'nofa'
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'l_samplingProtocol' AND cols.table_schema = 'nofa'
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'l_organismQuantityType' AND cols.table_schema = 'nofa'
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'l_sampleSizeUnit' AND cols.table_schema = 'nofa'
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'l_reliability' AND cols.table_schema = 'nofa'
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'l_referenceType' AND cols.table_schema = 'nofa'
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'l_spawningCondition' AND cols.table_schema = 'nofa'
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'l_spawningLocation' AND cols.table_schema = 'nofa'
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'l_establishmentMeans' AND cols.table_schema = 'nofa'
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'l_rettighetshaver' AND cols.table_schema = 'nofa'
                           -- admin tables
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'm_project' AND cols.table_schema = 'nofa'
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'm_reference' AND cols.table_schema = 'nofa'
                           OR cols.table_catalog = 'nofa' AND cols.table_name = 'm_dataset' AND cols.table_schema = 'nofa'
                           ;")
terms_info <- db_tableinfo

dwc_terms <- terms_info[c("column_name","table_name")]
mof_terms <- data.frame("column_name"=gsub(" ", "", l_mof_occurrence$measurementType, fixed = TRUE),
                                          "table_name"=rep("mof_occurrence",length(gsub(" ", "", l_mof_occurrence$measurementType, fixed = TRUE))))
terms_and_vocabulary <- rbind(dwc_terms,mof_terms)
NOFA_terms_and_vocabulary <- terms_and_vocabulary
      

# cloase db connections 
RPostgreSQL::dbDisconnect(nofa_db_RPostgreSQL)
RPostgreSQL::dbDisconnect(nofa_db_dplyr$con)

#------------------------------------------------------------------------------
# Data pre-flight check 
#------------------------------------------------------------------------------

# Define compulatory columns to be included in location(site?),event and occurrence 
# tables
# event_compulsatory_columns <- c("locationID","eventID","samplingProtocol","recordedBy","projectID")
# location_compulsatory_columns <- c("id")
# occurrence_compulsatory_columns <- c("occurenceID","eventID","speciesID")

