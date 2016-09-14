library(shiny)

#source("download_and_datawrangling.R",local=FALSE)


# Define UI for application 
shinyUI(navbarPage(title="DirtyHarry",
                   
### First page: import data and run dirtyHarry ----------------------------                    
tabPanel("mapping",
    pageWithSidebar(
      
      # Application title
      headerPanel("DirtyHarry - a blunt instrument for data mapping (v 0.1 Beta)"),
      # Sidebar with input for file downloads and choices
      sidebarPanel(
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
        downloadButton('downloadDirtyHarry', 'Download mapped data'),
        p(),
        img(src="ntnu-vm.png", width = 100)),
      
      # main pannel to show output tables and error messages 
      mainPanel(
        includeMarkdown("text_shiny_mainpage_vignett.md")
        #DT::dataTableOutput("occurrence")
        #textOutput("prefligth_warning_message"),
        #tableOutput("preflight_warning_table")
        
      )
    )
    ) # End page

# ### Second page: display output,data ----------------------------
# tabPanel("mapped event",
#          pageWithSidebar(
# 
#            # Application title
#            headerPanel(""),
# 
#            # Sidebar with input for file downloads and choices
#            sidebarPanel(
#              #includeMarkdown("text_dirtyHarry_intro.md"),
#              p("Display mapped event data"),
#              downloadButton('event_download', 'Download mapped event table'),
#              img(src="ntnu-vm.png", width = 100)
#              ),
# 
#            # main pannel to show output tables and error messages
#            mainPanel(
#              p("Display Occurrence table"),
#              DT::dataTableOutput("event")
#              #verbatimTextOutput("mapping_table")
# 
#            )
#          )), # End page



)

) # end ShinyUI 








