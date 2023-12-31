## app.R ##
library(shiny)
library(shinydashboard)
library(openxlsx)
library(ggplot2)
library(writexl)
library(ggbiplot)
library(nnet)
library(rio)
library(dplyr)
library(factoextra)
library(plyr)
library(cluster)
library(effects)
library(psychomix)
library(jtools)
library(sjPlot)

#### UI
ui <- dashboardPage( skin = "green",
  
###TITOLO APP
  dashboardHeader(title = "SEGMENTATION"),
  
###ELEMENTI BARRA LATERALE
  dashboardSidebar(
   
    sidebarMenu(
#parte clustering
      menuItem("Cluster analysis", tabName = "cluster", icon = icon("question-sign", lib = "glyphicon")),
      menuSubItem("File upload", tabName = "upload", icon = icon("upload")),
      menuSubItem("Clustering", tabName = "algclust", icon = icon("info-sign", lib = "glyphicon")),
      menuSubItem("Dendrogram", tabName = "dend", icon = icon("chart-bar") ),
      menuSubItem("Silhouette plot", tabName = "silh", icon = icon("chart-bar") ),
      menuSubItem("Pca scree plot", tabName = "pca" , icon = icon("chart-bar")),
      menuSubItem("Pca scores plot", tabName = "pcascores" , icon = icon("chart-bar")),
      menuSubItem("File download", tabName = "download", icon = icon("download")),
#parte descrizione
      menuItem("Description", tabName = "descr" , icon = icon("question-sign", lib = "glyphicon")),
      menuSubItem("File upload", tabName = "upload2", icon = icon("upload")),
      menuSubItem("Logistic regression", tabName = "log", icon = icon("info-sign",lib = "glyphicon")),
      menuSubItem("Effects Plot", tabName = "effp", icon= icon("chart-bar")),
      menuSubItem("Prediction", tabName = "pred", icon = icon("check", lib = "glyphicon")),
      menuSubItem("Mosaic plot", tabName = "mos" , icon = icon("chart-bar"))
    )),

###ELEMENTI PARTE PRINCIPALE
  dashboardBody(
    tabItems(
      
#sezione introduzione cluster analysis
      tabItem(tabName = "cluster", fluidRow(
        box(width =12, solidHeader = TRUE, status = "info",title = "Cluster Analysis",p("Cluster analysis is a classification method used to split a set of statistical units in different groups (clusters) in order to minimize the variability within the groups and maximize the variability between the groups."),
                                                                                p("There are many clustering algorithms suitable for this purpose. The Segmentation App works both with the hierarchical method and the K-Means algorithm: a Non-hierarchical clustering method appropriate to large datasets. "),
                                                                                p("The K-Means method works", strong( "only with numerical variables"), ". Therefore if you have categorical data it's recommended to tranform them in a quantitative form."),
                                                                                p("The hierachical method is recommended for datasets containing a small number of observations. The distance matrix is built using the Euclidean distance, so, even in this case only",strong( "numerical variables are allowed"), "."),
                                                                                p("The aggregation function chosen for the hierarchical clustering is the Ward's method."),
                                                                                p("If you have already identified the segmentation's parameter and decided in which group every statistical unit belongs, on the basis of the parameter chosen, you can skip this part and move to the Description part."),
                                                                                p("You can download the file cointaining the segments' membership only if you open the app in the browser."))
      )),
      
#sezione di upload dei dati
      tabItem(tabName = "upload", 
              h1("FILE UPLOAD"),fluidRow(
                box(width = 4, background = "black", fileInput("file1","Choose file",accept = c(
                  'text/csv',
                  'text/comma-separated-values,text/plain',
                  '.csv',
                  '.xlsx')),
                  radioButtons(
                    "fileType_Input",
                    label = h4("Choose File type"),
                    choices = list(".csv/txt" = 1, ".xlsx" = 2),
                    selected = 1,
                    inline = TRUE
                  )
                  
                ),
                box(width = 2,checkboxInput("standardize", "Standardize", FALSE)),
                box(width = 6,tableOutput("input_file"))
              )
      ),

#sezione algoritmo di clustering
      tabItem(tabName = "algclust",
              h1("CLUSTERING"), fluidRow(
                box(solidHeader = TRUE, status = "danger", title = "Choose Algorithm",    selectInput("select", "Choose Segmentation Algorithm", c("K-Means","Hierarchical"), selected = "K-Means")),
                box( solidHeader = TRUE, status = "warning", title = "Choose Segments' number",numericInput("Clust", "Number of Segments:", 3),
                     br(),
                     actionButton("Update","update",icon ("refresh"))
                     
                    
                     ),
                
                box(width = 8, solidHeader = TRUE, status = "info",title = "Segmentation summary", verbatimTextOutput("summary"))
              )
     ),
#sezione silhouette plot
    tabItem(tabName = "silh",
            fluidRow(
            box(width=12, solidHeader = TRUE, status = "info", title = "Silhouette plot", plotOutput("silhouette",height = 800, width = 1000))
            )
      
    ),
#sezione dendrogramma (solo nel caso del clustering gerarchico)
    tabItem(tabName = "dend",
            fluidRow(
            box(width=12, solidHeader = TRUE, status = "primary", title = "Dendrogram", plotOutput("dendrogram",height = 800, width = 1500))  
            )
            ),
#sezione scree plot
     tabItem(tabName = "pca",
              fluidRow(
               box(title ="PCA Scree Plot", width = 12, solidHeader = TRUE, status = "danger", plotOutput("plotpca",height = 800, width = 1000))
             )
             ),

#sezione scores plot
     tabItem(tabName = "pcascores",
             fluidRow(
               box(title= "PCA Scores Plot",width = 12,solidHeader = TRUE, status = "primary", plotOutput("segmplot",height = 800, width = 1200))
             )
             ),

#sezione download file con l'aggiunta della colonna dei segmenti (Clust)
     tabItem(tabName = "download",
             h1("DOWNLOAD SEGMENTS FILE"), fluidRow(
               box(width = 8, tableOutput("downloadtable")),
               box(width = 4,downloadButton("Downloaddata","download"))
             )),

#sezione introduzione descrizione dei segmenti
     tabItem(tabName = "descr",
             fluidRow(
               box(title="Description of Segments",width = 12,solidHeader = TRUE, status = "danger", 
                   p("The Description part allows the User to predict the segment membership of each statistical unit on the basis of new variables."),
                   p("The aim is to prove that these variables are useful to describe the segments available and to mark the statistical units belonging to different segments."),
                   p("The Segmentation App carries out the Description by means of the Logistic Regression: a classification method used to predict the segment membership (dependent variable) by way of the predictors (indipendent variables) chosen by the User."),
                   p("If you have only two clusters the Binomial Logistic Regression will be executed, while if you have more than two clusters you will see the results of the Multinomial Logistic Regression."),
                   p("To be able to perform this analysis your dataset needs to have the cluster's membership of every statistical unit in the first column and the name of the column must be:", strong("Clust"), "."),
                   p("In the other columns the dataset must have the variables chosen to describe the segments: if you have categorical data converted in a numerical form, select the Converted option, otherwise you can keep the Original option ."),
                   p("If you have acquired the segments through the Cluster Analysis of The Segmentation App, you can use the downloaded .xlsx file for the Logistic Regression. You have only to: ", strong(" remove the column"), "containing the names of the statistical units and", strong("replace the variables"), ".")
                   )
             )
             ),

#sezione upload file contenente le colonna dei segmenti ottenuti attraverso il clustering o stabiliti a priori 
     tabItem(tabName = "upload2",
             h1("DESCRIPTION FILE UPLOAD"),
             fluidRow(
               box(width = 3, background = "green", fileInput("file2","Choose file",accept = c(
                 'text/csv',
                 'text/comma-separated-values,text/plain',
                 '.csv',
                 '.xlsx')),
                 radioButtons(
                   "fileType_Input2",
                   label = h4("Choose File type"),
                   choices = list(".csv/txt" = 1, ".xlsx" = 2),
                   selected = 1,
                   inline = TRUE
                 )
                 
               ),
               box(width=2,title = "Select type of data",solidHeader = TRUE,    selectInput("selectdata", "Choose data type", c("Original","Converted"), selected = "Original")),
               box(width = 7,tableOutput("input_file2"))
             )),

#sezione output modello di regressione logistica
     tabItem(tabName = "log",
             h1("LOGISTIC REGRESSION"),
             fluidRow(
               box(width = 12, title = "Description summary", verbatimTextOutput("logsummary"))
             )),
#sezione effect plot
    tabItem(tabName = "effp",
          fluidRow(
             box(title= "Effect Plots",width = 12,solidHeader = TRUE, status = "info", plotOutput("effplots",height = 800, width = 1000))
            )
        
             ),

#sezione prediction modello di regressione logistica
     tabItem(tabName = "pred",
             h1("SEGMENTS PREDICTION"),
             fluidRow(
               box(width = 6, title = "Prediction", verbatimTextOutput("logpred")),
               box(width = 6, title = "Fitted values", verbatimTextOutput("fittedval"))
             )),
#sezione grafico a mosaico
     tabItem(tabName = "mos",
             fluidRow(
               box(title= "Mosaic Plot",width = 12,solidHeader = TRUE, status = "primary", plotOutput("mosplot",height = 800, width = 1000))
             )

             )
   
    )
  
  
  ) 
)


#### SERVER
server <- function(input, output,session) { 

#file upload
  data_file<- reactive({inFile <- input$file1
  
  if (is.null(inFile)) {
    return(NULL) }
  
  if (input$fileType_Input == "1") {
    read.csv(inFile$datapath,
             header = TRUE,
             stringsAsFactors = FALSE)
  } else {
    read.xlsx(inFile$datapath,
              sheet=1)
  }})
  
#opzione standardizzare
  data_file_final <- reactive({
    if (input$standardize){
      scale(data_file()[,-1], center = TRUE, scale = TRUE)
    }
    else {
      data_file()[,-1]
    }
  })

#tabella file upload
  output$input_file <- renderTable({
    if (is.null(data_file_final())) {
      return() }
    else {
      data_file_final()
    }
    
  })
  
#summary clustering (gruppi, centri finali, numero elementi per gruppo)
  
  algorithm <- reactive({ 
    if (input$select == "K-Means") {
    kmeans(data_file_final(),input$Clust)
    }
    else {
    distmatr <- dist(data_file_final(), method = "euclidean") 
    hclust(distmatr, method="ward")   
    }
    })
  Group <- reactive ({
    if (input$select == "K-Means") {
    as.character(algorithm()$cluster)
    }
    else {
    as.character(cutree(algorithm(), k=input$Clust))  
    }
    })
  groupmeans <- reactive ({
    aggregate(data_file()[,-1],by = list(Group()), FUN = mean)
   })
  withincluster <- reactive({algorithm()$withinss})
  betwdivtot <- reactive({(algorithm()$betweenss/algorithm()$totss)*100})
  
  
  output$summary <- renderPrint({
    
    input$Update
    isolate(
     
      
      if (is.null(input$file1)) {
        
        return(data.frame())
      }
      else {
        
        if (input$select == "K-Means") {
        Summary = list(Group = Group(), Final_Centers =groupmeans(), Number_of_elements = table(Group()), Within_sum_of_squares = withincluster(), Between_sum_of_squares_percentage = betwdivtot() )
        Summary
        }
        else {
        Summary = list(Group = Group(), Final_Centers =groupmeans(), Number_of_elements = table(Group()),  Model_Summary = algorithm() )
        Summary  
        }
      }
    )
  })
#dendrogramma 
  output$dendrogram = renderPlot({
    if (input$select == "K-Means") {
      print("Dendrogram available only for hierarchical clustering")
    }
    else {
      plot(algorithm(), main="", cex.main =1.5,cex = 1.5, xlab = "", ylab = "", sub = "", axes = FALSE)
      rect.hclust(algorithm(),input$Clust)
    }
  })

#silhouette plot
  output$silhouette = renderPlot({
    if (input$select == "K-Means"){
      dis <- dist(data_file_final(), method = "euclidean")
      sil <- silhouette (algorithm()$cluster, dis)
      plot(sil, main="", cex.main = 1.5, cex.sub = 1.5, cex.lab = 1.5, cex.axis = 1.5)
    }
    else {
      dis2 <- dist(data_file_final(), method = "euclidean")
      sil2 <- silhouette (cutree(algorithm(), k=input$Clust), dis2)
      plot(sil2, main="",cex.main = 1.5, cex.sub = 1.5, cex.lab = 1.5, cex.axis = 1.5)
      
    }
  })

#pca plot (scree plot)      
      output$plotpca = renderPlot({ 
        
        if (is.null(input$file1)) {
          
          return(data.frame())
        }
        else {
          data.pca <- prcomp(data_file_final(),center = TRUE,scale. = TRUE)
          fviz_eig(data.pca, barfill = "green", barcolor = "yellow")+theme(text=element_text(size=20))     
        }
      })

#pca plot (scores plot)            
      output$segmplot = renderPlot({  
        
        
          if (is.null(input$file1)) {
            
            return(data.frame())
          }
          
          
          
          clustersalg <- if (input$select == "K-Means") {
             as.character(algorithm()$cluster)
           }
           else {
             as.character(cutree(algorithm(), k=input$Clust)) 
           }
          data.pca <- prcomp(data_file_final(),
                             center = TRUE,
                             scale. = TRUE)
          
    
         
          scoreplot <-  ggbiplot(data.pca,
                        obs.scale = 1,
                        var.scale = 1,
                        groups = clustersalg,
                        ellipse = TRUE,
                        circle = TRUE)
          scoreplot <- scoreplot + scale_color_discrete(name = '')
          scoreplot <- scoreplot + theme(legend.direction = 'horizontal',
                         legend.position = 'top')
          scoreplot <- scoreplot + theme(text=element_text(size=20)) 
          print(scoreplot)
          
    })
      

#file nuovo da scaricare      
    
    
      output$downloadtable <- renderTable({
         
          
          if (is.null(input$file1)) {
           
            return(data.frame())
          }
          
          else {
            Clust <- Group()
            datasettable <- data.frame(Clust,data_file())
            datasettable
          }
        
    
      })
    
     
      
      
      
  # Downloadable xlsx file  
      output$Downloaddata <- downloadHandler(
        filename = function() {
          "downloadablefile.xlsx"
        },
        content = function(file) {
          Clust <- Group()
          datasetcompl <- data.frame(Clust,data_file())
          datasetcompl
          write_xlsx(datasetcompl, path = file)
        }
      )
  
### DESCRIPTION PART
# CANCELLARE LA COLONNA DEI NOMI:I PREDICTORS DEVONO ESSERE VARIABILI QUANTITATIVE

#file da uploadare
      data_file2<- reactive({inFile2 <- input$file2
      
      if (is.null(inFile2)) {
        return(NULL) }
      
      if (input$fileType_Input2 == "1") {
        read.csv(inFile2$datapath,
                 header = TRUE,
                 stringsAsFactors = FALSE)
      } else {
        read.xlsx(inFile2$datapath,
                  sheet=1)
      }})
      
      
      output$input_file2 <- renderTable({
        if (is.null(data_file2())) {
          return() }
        else {
          data_file2()
        }
        
      }) 

#summary regressione logistica 
      data_file2_bis <- reactive({data.frame(data_file2())})
      data_file2_tris <- reactive({
        if (input$selectdata == "Original") {
          data_file2_bis()
        }
        else {data_file2_bis()[sapply(data_file2_bis(), is.numeric)] <- lapply(data_file2_bis()[sapply(data_file2_bis(), is.numeric)], 
                                                                     as.factor)
        }
      })
      lvls <- reactive({unique(unlist(data_file2_bis()[1]))})
      
      freq <- reactive({sapply(data_file2_bis()[1], 
                     function(x) table(factor(x, levels = lvls(), 
                                              ordered = TRUE)))})
      numclasses <- reactive({length(freq())})
      logit <- reactive({ 
        if (numclasses() == 2) { 
          Factclust<- as.factor(data_file2_bis()$Clust)
          data_file_3 <- cbind(Factclust,data_file2_bis()[-1])
          data_file_3s <- if (input$selectdata == "Original") {
            data_file_3
          }
          else {data_file_3[sapply(data_file_3, is.numeric)] <- lapply(data_file_3[sapply(data_file_3, is.numeric)], 
                                                                       as.factor)
          }
          glm(Factclust~. , family = binomial, data = data_file_3)
        } 
        else {
          data_file_4 <- data_file2_bis()
          data_file_4s <- if (input$selectdata == "Original") {
            data_file_4
          }
          else {data_file_4[sapply(data_file_4, is.numeric)] <- lapply(data_file_4[sapply(data_file_4, is.numeric)], 
                                                                       as.factor)
          }
          multinom(Clust~., data = data_file_4) 
        }
      })
      logitsum <- reactive({summary(logit())})
      numregs <- reactive (as.numeric({length(data_file2_bis())}))
      numobs <- reactive (as.numeric({length(data_file2_bis()[,1])}))
      t.ratio <- reactive({
        if (numclasses() == 2) {
          return()
        }
        else {
          logitsum()$coefficients/logitsum()$standard.errors
          }
          })
      signTest <- reactive({
        if (numclasses() == 2) {
          return()
        }
        else {
          2*(1-pt(abs(t.ratio()), df = logitsum()$edf))
         }
        })

      
      
      output$logsummary <- renderPrint({
        
        
        if (numregs() > (2/3)*(numobs())){
          print("the number of observations must be at least 1.5 times higher than the number of variables")
        }
        else {
          if (numclasses() == 2) {
            Summary1 = list(LogitSummary = logitsum())
            Summary1
          }
          else {  
          Summary2 = list(Logitsummary = logitsum(), T.ratio = t.ratio(), P.value = signTest())
          Summary2
          }
        }
      }  
      )
#effect plots
    
    output$effplots = renderPlot({
      if (numclasses() == 2) { 
        eff.tot <-  allEffects(logit(), xlevels=8)
        plot(eff.tot,confint=list(style="bars"), axes=list(y=list(lab="Probability"), ticks=list(at=c(.1,.25,.5,.75,.9))))
      } 
      else {
        eff.tot <-  allEffects(logit(), xlevels=8)
        plot(eff.tot,confint=list(style="bars"),axes=list(y=list(lab="Probability") , ticks=list(at=c(.1,.25,.5,.75,.9))))
      }
    })

#prediction 
      predvect <- reactive({
        if (numclasses() == 2) {
          data_file_5 <- data_file2_bis()
          data_file_5s <- if (input$selectdata == "Original") {
            data_file_5
          }
          else {data_file_5[sapply(data_file_5, is.numeric)] <- lapply(data_file_5[sapply(data_file_5, is.numeric)], 
                                                                       as.factor)
          }
          predic<- predict(logit(), type = "response")
          predic1<-rep("2",nrow(data_file_5))
          predic1[predic < .5]<- 1 
          predic1
        }
        else {
          data_file_6 <- data_file2_bis()
          data_file_6s <- if (input$selectdata == "Original") {
            data_file_6
          }
          else {data_file_6[sapply(data_file_6, is.numeric)] <- lapply(data_file_6[sapply(data_file_6, is.numeric)], 
                                                                       as.factor)
          }
          predict(logit(),data_file_6)
        }
        })
      tabpred <- reactive ({table (predvect(),data_file2_bis()$Clust)})
      modelacc <- reactive({mean(predvect() == data_file2_bis()$Clust)})
      
      output$logpred <- renderPrint({
        
        
        if (numregs() > (2/3)*(numobs())){
          print("the number of observations must be at least 1.5 times higher than the number of variables")
        }
        else {
          Summarypred = list(Prediction = predvect(), Table_prediction = tabpred(), Accuracy = modelacc())
          Summarypred
        }
      }  
      )
      
      fitval <- reactive({
        if (numclasses() == 2) {
          logit()$fitted.values
        }
        else {
          logitsum()$fitted.values
        }
        })
      
      output$fittedval <- renderPrint({
        
        
        if (numregs() > (2/3)*(numobs())){
          print("the number of observations must be at least 1.5 times higher than the number of variables")
        }
        else {
        Summaryfitval = list(Fitted_values = fitval())
        Summaryfitval
        }
      }  
      )
      
#mosaic plot      
      output$mosplot = renderPlot({
        mosaicpl <- mosaicplot(tabpred(), main = "Mosaic Plot", color  = TRUE, xlab = "cluster", cex.axis = 1.5) 
        print(mosaicpl)
      })
}




shinyApp(ui, server)

