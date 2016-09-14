
library(shiny)
library(dplyr)
#library(knitr)
library(DT) #install.packages('DT')
#library(leaflet)
#library(tidyr)
#library(curl)
library(XLConnect)

source("function_DirtyHarry.R")

#-----------------------------------------------------------------------------
# Chose input terms and vocabulary--------------------------------------------
#-----------------------------------------------------------------------------
# Can be made reactive in shiny app if one want to let the user choose options 
# terms_and_tables is a table containing the columns term and table reffering to destination column and destination table
source("dataIO_nofa_db.R")
terms_and_tables <- NOFA_terms_and_vocabulary # simple translation for laziness - should be done in original source script
names(terms_and_tables) <- c("term","table")




shinyServer(function(input, output) {
 
  #----------------------------------------------------------------------------
  # Load inndata as reactive input---------------------------------------------  
  #----------------------------------------------------------------------------
    
  
  DirtyHarry_out <- reactive({
    inndata <- input$input_data
    if(is.null(input$input_data)) # Note, Shiny needs if statments within reactive content if not to crash when file not loaded    
      return(NULL) 
    mapped_data <- DirtyHarry(inndata,terms_and_tables,out="wb")
    return(mapped_data)
  })
  
  
  # first define file name
  output$downloadDirtyHarry <- downloadHandler(
    filename = function() { 
      paste("mapped_data_",Sys.Date(), '.xlsx', sep='') 
    },
    
    # then define content of file. use XLConnect to write dynamic output to xlsx file.   
    content = function(file) {
      wb_out <- DirtyHarry_out()

      
      # write output to temporary file. Note the use of 'file.rename' instad of 'write...'
      saveWorkbook(wb_out, 'temp.xlsx')
      file.rename('temp.xlsx', file)
    }
  )
  # output$mof_occurrence_download <- downloadHandler(
  #   filename = function() { paste("Mapped_mof_occurrence_data_",Sys.Date(), ".csv", sep="") },
  #   content = function(file) {
  #     write.csv(mof_occurrence(), file, na = "", row.names = FALSE)
  #   }
  # )
  
  

  
}) # end ShinyServer


# output$mapping_table <- DT::renderDataTable(DT::datatable({
#   mapping_table()
# }
# ,rownames= FALSE
# ))
# 
# output$translation_table <- DT::renderDataTable(DT::datatable({
#   translation_table()
# }
# ,rownames= FALSE
# ))
# 
# output$input_data <- DT::renderDataTable(DT::datatable({
#   input_data()
# }
# ,rownames= FALSE
# ))
