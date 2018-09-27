library(shiny)
# library(datasets)
library(RODBC)
library(forecast)


con <- odbcConnect("SQLEXPRESS")
testReihe <- sqlQuery(con, "SELECT DISTINCT DATEPART(YEAR, [ModifiedDate]) AS Jahr
, DATEPART(MONTH, [ModifiedDate]) AS Monat
 ,(sum([LineTotal]) OVER(PARTITION BY CONCAT(YEAR([ModifiedDate]),'-', MONTH([ModifiedDate])))) AS Monatsssumme
  FROM [AdventureWorks].[Sales].[SalesOrderDetail]
 -- WHERE [ModifiedDate] LIKE '%2011%'
  GROUP BY [ProductID]
		,[LineTotal]
		,[ModifiedDate]
  ORDER BY Jahr, DATEPART(MONTH, [ModifiedDate]) ASC")
Nachfrage <- ts(testReihe[3], start=c(2011,7),end=c(2014,6), frequency
=12 )

shinyServer(function(input, output) {
 


  getDataset <- reactive({
    if (input$variable=="Nachfrage")
    {
      return(Nachfrage)
    }
  })	
  
  output$caption <- renderText({
    paste("Dataset: ", input$variable)
  })
  
  output$dcompPlot <- renderPlot({
    ds_ts <- ts(getDataset(), frequency=12)
    f <- decompose(ds_ts)
    plot(f)
  })
  
  output$arimaForecastPlot <- renderPlot({
    fit <- auto.arima(getDataset())
    plot(forecast(fit, h=input$ahead))
  })
  
  output$etsForecastPlot <- renderPlot({
    fit <- ets(getDataset())
    plot(forecast(fit, h=input$ahead))
  })
  
})