library(shiny)

#source("download_and_datawrangling.R",local=FALSE)


# Define UI for application 
shinyUI(navbarPage(title="DirtyHarry",
                   
### First page: import data and run dirtyHarry ----------------------------                    
tabPanel("mapping",
    pageWithSidebar(
      
      # Application title
      headerPanel("Do I feel lucky?' Well, do you?"),
      
      # Sidebar with input for file downloads and choices
      sidebarPanel(
        #includeMarkdown("text_dirtyHarry_intro.md"),
        selectInput("selected_standard", 
                    label = "Select mapping standard",
                    choices = c("NOFA"="NOFA"),
                    selected = c("NOFA"="NOFA")
        ),
        fileInput('input_data', 'input data as .xlsx',
                  accept = c(
                    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                    'application/vnd.ms-excel'
                  )
        ),
        fileInput('mapping_table', 'Mapping table as .csv',
                  accept = c(
                    'text/csv',
                    'text/comma-separated-values',
                    'text/tab-separated-values',
                    'text/plain',
                    '.csv',
                    '.tsv'
                  )
        ),
        fileInput('translation_table', 'Translation table as .csv',
                  accept = c(
                    'text/csv',
                    'text/comma-separated-values',
                    'text/tab-separated-values',
                    'text/plain',
                    '.csv',
                    '.tsv'
                  )
        ),
        p(),
        img(src="ntnu-vm.png", width = 100)),
      
      # main pannel to show output tables and error messages 
      mainPanel(
        p("Warnings et al."),
        #DT::dataTableOutput("occurrence")
        textOutput("prefligth_warning_message"),
        tableOutput("preflight_warning_table")
        
      )
    )
    ), # End page

### Second page: display outputdata ----------------------------
tabPanel("mapped event",
         pageWithSidebar(

           # Application title
           headerPanel(""),

           # Sidebar with input for file downloads and choices
           sidebarPanel(
             #includeMarkdown("text_dirtyHarry_intro.md"),
             p("Display mapped event data"),
             downloadButton('event_download', 'Download mapped event table'),
             img(src="ntnu-vm.png", width = 100)
             ),

           # main pannel to show output tables and error messages
           mainPanel(
             p("Display Occurrence table"),
             DT::dataTableOutput("event")
             #verbatimTextOutput("mapping_table")

           )
         )), # End page
### third page: display occurrence mapped ----------------------------
tabPanel("mapped occurrence",
         pageWithSidebar(
           
           # Application title
           headerPanel(""),
           
           # Sidebar with input for file downloads and choices
           sidebarPanel(
             #includeMarkdown("text_dirtyHarry_intro.md"),
             p("Display mapped event data"),
             downloadButton('occurrence_download', 'Download mapped occurrence table'),
             img(src="ntnu-vm.png", width = 100)
           ),
           
           # main pannel to show output tables and error messages
           mainPanel(
             p("Display Occurrence table"),
             DT::dataTableOutput("occurrence")
             
           )
         )), # End page### third page: display occurrence mapped ----------------------------
tabPanel("mapped MoF occurrence",
         pageWithSidebar(
           
           # Application title
           headerPanel(""),
           
           # Sidebar with input for file downloads and choices
           sidebarPanel(
             #includeMarkdown("text_dirtyHarry_intro.md"),
             p("Display mapped measurment or facts for the occurrence data"),
             downloadButton('mof_occurrence_download', 'Download mapped mof_occurrence table'),
             img(src="ntnu-vm.png", width = 100)
           ),
           
           # main pannel to show output tables and error messages
           mainPanel(
             p("Display measurment or fact for the occurrence data"),
             DT::dataTableOutput("mof_occurrence")
             
           )
         )) # End page



)

) # end ShinyUI 








