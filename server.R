
library(shiny)
library(dplyr)
library(knitr)
library(DT) #install.packages('DT')
library(leaflet)
library(tidyr)
library(curl)
library(XLConnect)

source("functions_DirtyHarry_main.R")
source("functions_DirtyHarry_translation.R")
source("dataIO_nofa_db.R")
#DwC event 
# DwC <- read.csv("https://docs.google.com/spreadsheets/d/1aoVXabLjZYP7qaCJuPDrscOYODBwozXd9ZttlyA4Urc/pub?output=csv")
# terms_and_vocabulary <- select(DwC,table_name=Term_placment_DwC.A_event_core,column_name=Term_name)


shinyServer(function(input, output) {
 
  #----------------------------------------------------------------------------
  # Load inndata as reactive input---------------------------------------------  
  #----------------------------------------------------------------------------
  mapping_table <- reactive({
    mapping <- input$mapping_table
    # Note, Shiny needs if statments within reactive content if not to crash when file not loaded
    if(is.null(input$mapping_table))     
      return(NULL) 
    read.csv(mapping$datapath)
  })

  translation_table <- reactive({
    translation_table <- input$translation_table
    if(is.null(input$translation_table))     
      return(NULL) 
    read.csv(translation_table$datapath)
  })
  
  input_data <- reactive({
    inndata <- input$input_data
    if(is.null(input$input_data))     
      return(NULL) 
    loadWorkbook(inndata$datapath, create = F)
  })
  
  output$mapping_table <- DT::renderDataTable(DT::datatable({
    mapping_table()
  }
  ,rownames= FALSE
  ))
  
  output$translation_table <- DT::renderDataTable(DT::datatable({
    translation_table()
  }
  ,rownames= FALSE
  ))
  
  output$input_data <- DT::renderDataTable(DT::datatable({
    input_data()
  }
  ,rownames= FALSE
  ))
  
  #----------------------------------------------------------------------------
  # Merge innputt data and create input datatable------------------------------ 
  #----------------------------------------------------------------------------  
  # creates inndata (flat-file-format)
  inndata <- reactive({
      inndata_wb <- input_data()
      mapping <- mapping_table()

      if (is.null(inndata_wb))
        return(NULL)
      if (is.null(mapping))
        return(NULL)

      get_data_from_xlsx_and_flatten_out(inndata_wb,mapping)

  })

  output$table_inndata <- DT::renderDataTable(DT::datatable({
      inndata()
      }
      ,rownames= FALSE
      ))
  
  #------------------------------------------------------------------------------
  # Get list of valid column names, vocabulary and table placements-------------- 
  #------------------------------------------------------------------------------
  controlled_vocabulary <- reactive({ 
    
    controlled_vocabulary <- NOFA_controlled_vocabulary
    controlled_vocabulary
    
  })
  
  terms_and_vocabulary <- reactive({ 
    
    terms_and_vocabulary <- NOFA_terms_and_vocabulary
    terms_and_vocabulary
    
  })

  output$controlled_vocabulary <- DT::renderDataTable(DT::datatable({
    controlled_vocabulary()
  }
  ,rownames= FALSE
  ))
  
  output$table_terms_and_vocabulary <- DT::renderDataTable(DT::datatable({
    terms_and_vocabulary()
  }
  ,rownames= FALSE
  ))
  
  #----------------------------------------------------------------------------
  # return data pre-fligth check ----------------------------------------------
  #----------------------------------------------------------------------------
  
  preflight_warning <- reactive({ 
    mapping <- mapping_table()
    inndata <- inndata()
    terms_and_vocabulary <- terms_and_vocabulary()
    
    if (is.null(terms_and_vocabulary))
      return(NULL)
    if (is.null(inndata))
      return(NULL)
    if (is.null(mapping))
      return(NULL)

    inndata_names <- names(inndata) 
    inndata_names_in_mapping <- unique(na.omit(unlist(strsplit(as.character(mapping$inputdata_term), c("|"), fixed = TRUE))))

    inndata_names_not_in_mapping <- na.omit(inndata_names[!(inndata_names %in% inndata_names_in_mapping)])

    warning <- data.frame(message = rep("Inndata column not found in mapping:",length(inndata_names_in_mapping)),
                          woops = inndata_names_in_mapping)
    return(warning)
    })
  
  output$preflight_warning_table <- renderTable({ 
    preflight_warning()
  })
  
  output$prefligth_warning_message <- renderText({

    mapping <- mapping_table()
    inndata <- inndata()
    terms_and_vocabulary <- terms_and_vocabulary()

    if (is.null(terms_and_vocabulary))
      return(NULL)
    if (is.null(inndata))
      return(NULL)
    if (is.null(mapping))
      return(NULL)
    "Bad hairday, or just lucky?"
  })
  
  #----------------------------------------------------------------------------
  # Data mapping------ --------------------------------------------------------
  #----------------------------------------------------------------------------

  # returns object outdata (flat-file-format)
  outdata <- reactive({
    inndata <- inndata()
    mapping <- mapping_table()
    translation_table <- translation_table()

    if (is.null(inndata))
      return(NULL)
    if (is.null(mapping))
      return(NULL)
    if (is.null(translation_table))
      return(NULL)

    outdata <- map_data_to_dwc(inndata,mapping,translation_table)
    outdata
  })

  output$outdata <- DT::renderDataTable(DT::datatable({
    outdata()
  }
  ,rownames= FALSE
  ))


  #----------------------------------------------------------------------------
  # Create mapped tables, event, occurrence and mof ---------------------------
  #----------------------------------------------------------------------------

  # create event table
  event <- reactive({
    
    inndata <- inndata()
    outdata <- outdata()
    mapping <- mapping_table()
    
    if (is.null(inndata))
      return(NULL)
    if (is.null(outdata))
      return(NULL)
    if (is.null(mapping))
      return(NULL)
    event <- get_output_data_structure(outdata,mapping,table="event")
    event
  })
  # create data table for display
  output$event <- DT::renderDataTable(DT::datatable({
    event()
  }
  ,rownames= FALSE
  ))
  # create download object from reactive object
  output$event_download <- downloadHandler(
    filename = function() { paste("Mapped_event_data_",Sys.Date(), ".csv", sep="") },
    content = function(file) {
      write.csv(event(), file, na="", row.names = FALSE)
    }
  )

  
  # returns occurrence table
  occurrence <- reactive({
    
    inndata <- inndata()
    outdata <- outdata()
    mapping <- mapping_table()
    
    if (is.null(inndata))
      return(NULL)
    if (is.null(outdata))
      return(NULL)
    if (is.null(mapping))
      return(NULL)
    occurrence <- get_output_data_structure(outdata,mapping,table="occurrence")
    occurrence
  })
  
  output$occurrence <- DT::renderDataTable(DT::datatable({
    occurrence()
  }
  ,rownames= FALSE
  ))
  # create download object from reactive object
  output$occurrence_download <- downloadHandler(
    filename = function() { paste("Mapped_occurrence_data_",Sys.Date(), ".csv", sep="") },
    content = function(file) {
      write.csv(occurrence(), file, na = "", row.names = FALSE)
    }
  )
  
  # returns mof_occurrence table
  mof_occurrence <- reactive({
    
    inndata <- inndata()
    outdata <- outdata()
    mapping <- mapping_table()
    
    if (is.null(inndata))
      return(NULL)
    if (is.null(outdata))
      return(NULL)
    if (is.null(mapping))
      return(NULL)
    mof_occurrence <- get_output_data_structure(outdata,mapping,table="mof_occurrence")
    mof_occurrence
  })
  
  output$mof_occurrence <- DT::renderDataTable(DT::datatable({
    mof_occurrence()
  }
  ,rownames= FALSE
  ))
  
  output$mof_occurrence_download <- downloadHandler(
    filename = function() { paste("Mapped_mof_occurrence_data_",Sys.Date(), ".csv", sep="") },
    content = function(file) {
      write.csv(mof_occurrence(), file, na = "", row.names = FALSE)
    }
  )
  
  

  
}) # end ShinyServer



