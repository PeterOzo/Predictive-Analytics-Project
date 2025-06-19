
rsconnect::setAccountInfo(name='xxxxxxxxxxx',
                          token='xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
                          secret='xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx')

# Prevent terra package installation/loading
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Force install packages without terra dependencies
if (!requireNamespace("sf", quietly = TRUE)) {
  install.packages("sf")
}

# Explicitly avoid terra-dependent versions
Sys.setenv("_R_CHECK_FORCE_SUGGESTS_" = "FALSE")




# Load required libraries
library(shiny)
library(shinydashboard)
library(DT)
library(plotly)
library(ggplot2)
library(dplyr)
library(corrplot)
library(randomForest)
library(glmnet)
library(shinycssloaders)
library(shinyWidgets)
library(leaflet)
library(viridis)

# Define UI
ui <- dashboardPage(
  dashboardHeader(
    title = "AnalyticsPro - Seattle Housing Analytics",
    titleWidth = 350
  ),
  
  dashboardSidebar(
    width = 250,
    sidebarMenu(
      menuItem("Dashboard", tabName = "dashboard", icon = icon("dashboard")),
      menuItem("Data Explorer", tabName = "data", icon = icon("table")),
      menuItem("Visualization", tabName = "viz", icon = icon("chart-line")),
      menuItem("Correlation Analysis", tabName = "corr", icon = icon("project-diagram")),
      menuItem("Price Predictor", tabName = "predict", icon = icon("calculator")),
      menuItem("Model Performance", tabName = "models", icon = icon("cogs")),
      menuItem("Geographic Analysis", tabName = "geo", icon = icon("map-marked-alt")),
      menuItem("Report Generator", tabName = "report", icon = icon("file-alt")),
      menuItem("About Author", tabName = "author", icon = icon("user"))
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
        .main-header .navbar {
          background-color: #3c8dbc;
        }
        .skin-blue .main-header .logo {
          background-color: #367fa9;
        }
        .box.box-solid.box-primary > .box-header {
          background: #3c8dbc;
          background-color: #3c8dbc;
        }
        .value-box .icon {
          font-size: 60px;
        }
        .interpretation-box {
          background-color: #f0f8ff;
          padding: 15px;
          border-left: 4px solid #3c8dbc;
          margin: 10px 0;
          border-radius: 5px;
        }
        .insight-box {
          background-color: #e8f5e8;
          padding: 12px;
          border-left: 4px solid #5cb85c;
          margin: 8px 0;
          border-radius: 4px;
        }
      "))
    ),
    
    tabItems(
      # Dashboard Tab
      tabItem(tabName = "dashboard",
              fluidRow(
                valueBoxOutput("total_properties"),
                valueBoxOutput("avg_price"),
                valueBoxOutput("price_range")
              ),
              
              fluidRow(
                box(
                  title = "Price Distribution", status = "primary", solidHeader = TRUE,
                  width = 6, height = 400,
                  withSpinner(plotlyOutput("price_dist", height = "350px"))
                ),
                box(
                  title = "Key Statistics", status = "primary", solidHeader = TRUE,
                  width = 6, height = 400,
                  withSpinner(DT::dataTableOutput("summary_stats"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Price vs Living Space", status = "primary", solidHeader = TRUE,
                  width = 12, height = 450,
                  withSpinner(plotlyOutput("price_vs_sqft", height = "400px"))
                )
              )
      ),
      
      # Data Explorer Tab
      tabItem(tabName = "data",
              fluidRow(
                box(
                  title = "Dataset Overview", status = "primary", solidHeader = TRUE,
                  width = 12,
                  p("Seattle Housing Price Dataset: 21,613 entries with 21 variables"),
                  p("Source: Kaggle - Seattle House Sales Prices"),
                  p("Author: Peter Chika Ozo-Ogueji - American University Kogod School of Business")
                )
              ),
              
              fluidRow(
                box(
                  title = "Data Filters", status = "primary", solidHeader = TRUE,
                  width = 3,
                  sliderInput("price_filter", "Price Range ($)",
                              min = 75000, max = 8000000, 
                              value = c(75000, 8000000),
                              step = 25000),
                  sliderInput("bedrooms_filter", "Bedrooms",
                              min = 0, max = 11, value = c(0, 11)),
                  sliderInput("bathrooms_filter", "Bathrooms",
                              min = 0.5, max = 8, value = c(0.5, 8), step = 0.25),
                  checkboxGroupInput("waterfront_filter", "Waterfront",
                                     choices = list("No" = "0", "Yes" = "1"),
                                     selected = c("0", "1")),
                  actionButton("reset_filters", "Reset Filters", 
                               class = "btn-warning")
                ),
                box(
                  title = "Housing Data", status = "primary", solidHeader = TRUE,
                  width = 9,
                  withSpinner(DT::dataTableOutput("data_table"))
                )
              )
      ),
      
      # Enhanced Visualization Tab
      tabItem(tabName = "viz",
              fluidRow(
                box(
                  title = "Visualization Controls", status = "primary", solidHeader = TRUE,
                  width = 3,
                  selectInput("x_var", "X Variable:",
                              choices = list(
                                "Price" = "price",
                                "Living Space (sqft)" = "sqft_living",
                                "Lot Size (sqft)" = "sqft_lot",
                                "Bedrooms" = "bedrooms",
                                "Bathrooms" = "bathrooms",
                                "Floors" = "floors",
                                "House Age" = "house_age"
                              )),
                  selectInput("y_var", "Y Variable:",
                              choices = list(
                                "Price" = "price",
                                "Living Space (sqft)" = "sqft_living",
                                "Lot Size (sqft)" = "sqft_lot",
                                "Bedrooms" = "bedrooms",
                                "Bathrooms" = "bathrooms",
                                "Floors" = "floors",
                                "House Age" = "house_age"
                              ), selected = "price"),
                  selectInput("color_var", "Color By:",
                              choices = list(
                                "None" = "none",
                                "Waterfront" = "waterfront",
                                "View" = "view",
                                "Condition" = "condition",
                                "Grade" = "grade"
                              )),
                  selectInput("plot_type", "Plot Type:",
                              choices = list(
                                "Scatter Plot" = "scatter",
                                "Box Plot" = "box",
                                "Histogram" = "hist",
                                "Density Plot" = "density"
                              ))
                ),
                box(
                  title = "Interactive Visualization", status = "primary", solidHeader = TRUE,
                  width = 9, height = 600,
                  withSpinner(plotlyOutput("custom_plot", height = "400px")),
                  div(class = "interpretation-box",
                      h5("💡 Visualization Insights:"),
                      uiOutput("viz_interpretation")
                  )
                )
              )
      ),
      
      # Enhanced Correlation Analysis Tab
      tabItem(tabName = "corr",
              fluidRow(
                box(
                  title = "Correlation Matrix", status = "primary", solidHeader = TRUE,
                  width = 8, height = 650,
                  withSpinner(plotOutput("correlation_plot", height = "550px"))
                ),
                box(
                  title = "Price Correlations", status = "primary", solidHeader = TRUE,
                  width = 4, height = 650,
                  withSpinner(DT::dataTableOutput("correlation_table")),
                  br(),
                  div(class = "interpretation-box",
                      h5("🔍 Key Correlation Insights:"),
                      tags$ul(
                        tags$li(strong("Living Space (0.70):"), " Strongest predictor - larger homes command higher prices"),
                        tags$li(strong("Bathrooms (0.53):"), " Moderate correlation - each bathroom adds significant value"),
                        tags$li(strong("House Age (-0.05):"), " Surprisingly weak negative correlation"),
                        tags$li(strong("Grade & View:"), " Quality assessments strongly influence pricing")
                      )
                  )
                )
              ),
              
              fluidRow(
                box(
                  title = "Correlation Analysis Interpretation", status = "info", solidHeader = TRUE,
                  width = 12,
                  div(class = "insight-box",
                      h4("📊 What These Correlations Tell Us:"),
                      tags$div(
                        style = "display: flex; justify-content: space-between;",
                        tags$div(
                          style = "width: 48%;",
                          h5("Strong Positive Correlations (> 0.5):"),
                          tags$ul(
                            tags$li("sqft_living (0.70) - Living space is the #1 price driver"),
                            tags$li("bathrooms (0.53) - Premium for additional bathrooms"),
                            tags$li("sqft_living vs bathrooms (0.75) - Larger homes have more bathrooms")
                          )
                        ),
                        tags$div(
                          style = "width: 48%;",
                          h5("Business Implications:"),
                          tags$ul(
                            tags$li("Focus marketing on living space square footage"),
                            tags$li("Bathroom count is a key value driver"),
                            tags$li("House age has minimal impact on price"),
                            tags$li("Quality features (grade, view) matter more than basic specs")
                          )
                        )
                      )
                  )
                )
              )
      ),
      
      # Enhanced Price Predictor Tab
      tabItem(tabName = "predict",
              fluidRow(
                box(
                  title = "House Features Input", status = "primary", solidHeader = TRUE,
                  width = 4,
                  numericInput("pred_bedrooms", "Number of Bedrooms:", value = 3, min = 1, max = 11),
                  numericInput("pred_bathrooms", "Number of Bathrooms:", value = 2.25, min = 0.5, max = 8, step = 0.25),
                  numericInput("pred_sqft_living", "Living Space (sqft):", value = 2080, min = 290, max = 13540),
                  numericInput("pred_sqft_lot", "Lot Size (sqft):", value = 15000, min = 520, max = 1651359),
                  numericInput("pred_floors", "Number of Floors:", value = 1.5, min = 1, max = 3.5, step = 0.5),
                  selectInput("pred_waterfront", "Waterfront View:", 
                              choices = list("No" = 0, "Yes" = 1)),
                  selectInput("pred_view", "View Rating (0-4):", 
                              choices = list("0" = 0, "1" = 1, "2" = 2, "3" = 3, "4" = 4)),
                  selectInput("pred_condition", "Condition (1-5):", 
                              choices = list("1" = 1, "2" = 2, "3" = 3, "4" = 4, "5" = 5), selected = "3"),
                  selectInput("pred_grade", "Grade (3-13):", 
                              choices = as.list(setNames(3:13, 3:13)), selected = "7"),
                  numericInput("pred_house_age", "House Age (years):", value = 35, min = 0, max = 124),
                  br(),
                  actionButton("predict_price", "Predict Price", class = "btn-success btn-lg")
                ),
                box(
                  title = "Price Prediction Results", status = "primary", solidHeader = TRUE,
                  width = 8,
                  h3("Predicted House Price:"),
                  div(id = "prediction_result", 
                      style = "font-size: 36px; color: #3c8dbc; font-weight: bold; text-align: center; padding: 20px;",
                      textOutput("prediction_display")),
                  br(),
                  div(class = "interpretation-box",
                      h4("🎯 Prediction Model Details:"),
                      p("This prediction uses coefficients derived from the OLS.small model (MSE: 0.097129, R² = 0.65) combined with Random Forest variable importance rankings."),
                      
                      h5("📈 Key Factor Effects (from OLS model):"),
                      tags$div(
                        style = "display: flex; justify-content: space-between;",
                        tags$div(
                          style = "width: 48%;",
                          h6("Positive Price Effects:"),
                          tags$ul(
                            tags$li("Bathrooms: +8.4% per additional"),
                            tags$li("Living space: +0.018% per sqft"),
                            tags$li("Floors: +7.7% per additional"),
                            tags$li("Waterfront: +31.5% premium"),
                            tags$li("House age: +0.6% per year (surprising!)")
                          )
                        ),
                        tags$div(
                          style = "width: 48%;",
                          h6("Categorical Effects:"),
                          tags$ul(
                            tags$li("View ratings: 18% to 25% premium"),
                            tags$li("Condition 3-5: 15% to 23% increase"),
                            tags$li("High grades (8-13): 72% to 134% premium"),
                            tags$li("Bedrooms: -3.3% per additional (counterintuitive)")
                          )
                        )
                      )
                  ),
                  
                  br(),
                  h4("📊 Variable Importance (Random Forest):"),
                  tags$ol(
                    tags$li(strong("House Age"), " (222.4% IncMSE) - Most important predictor"),
                    tags$li(strong("Lot Size"), " (152.6% IncMSE) - Property size matters"),
                    tags$li(strong("Grade"), " (96.8% IncMSE) - Quality assessment"),
                    tags$li(strong("Living Space"), " (73.0% IncMSE) - Liveable area"),
                    tags$li(strong("View Rating"), " (64.2% IncMSE) - Scenic value")
                  )
                )
              )
      ),
      
      # Model Performance Tab
      tabItem(tabName = "models",
              fluidRow(
                box(
                  title = "Model Comparison Results", status = "primary", solidHeader = TRUE,
                  width = 12,
                  h3("10-Fold Cross Validation Results"),
                  withSpinner(DT::dataTableOutput("model_results"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Model Performance Visualization", status = "primary", solidHeader = TRUE,
                  width = 6,
                  withSpinner(plotlyOutput("model_comparison"))
                ),
                box(
                  title = "Final Model Selection", status = "primary", solidHeader = TRUE,
                  width = 6,
                  h4("Best Models Selected:"),
                  tags$div(
                    style = "background-color: #f0f8ff; padding: 15px; border-left: 4px solid #3c8dbc;",
                    h5(strong("For Predictive Accuracy:")),
                    p("Random Forest (RF.full) - MSE: 0.08630"),
                    p("Explains ~70% of variance in house prices"),
                    br(),
                    h5(strong("For Interpretation:")),
                    p("OLS Small Model - MSE: 0.09713"),
                    p("Explains ~65% of variance in house prices"),
                    p("Best for understanding feature effects")
                  )
                )
              )
      ),
      
      # Enhanced Geographic Analysis Tab
      tabItem(tabName = "geo",
              fluidRow(
                box(
                  title = "Geographic Filters", status = "primary", solidHeader = TRUE,
                  width = 3,
                  sliderInput("geo_price_range", "Price Range ($)",
                              min = 75000, max = 8000000,
                              value = c(200000, 2000000),
                              step = 50000),
                  selectInput("geo_color_by", "Color Points By:",
                              choices = list(
                                "Price" = "price",
                                "Price per SqFt" = "price_per_sqft",
                                "Grade" = "grade",
                                "View" = "view",
                                "Condition" = "condition",
                                "House Age" = "house_age"
                              )),
                  checkboxGroupInput("geo_waterfront", "Waterfront Properties:",
                                     choices = list("Include Waterfront" = "1", "Include Non-Waterfront" = "0"),
                                     selected = c("0", "1")),
                  sliderInput("geo_sample_size", "Sample Size (for performance):",
                              min = 100, max = 5000, value = 1000, step = 100),
                  actionButton("update_map", "Update Map", class = "btn-primary")
                ),
                box(
                  title = "Geographic Distribution of Housing Prices", status = "primary", solidHeader = TRUE,
                  width = 9, height = 700,
                  withSpinner(leafletOutput("price_map", height = "600px"))
                )
              ),
              
              fluidRow(
                box(
                  title = "Geographic Analysis Insights", status = "info", solidHeader = TRUE,
                  width = 12,
                  div(class = "insight-box",
                      h4("🗺️ Key Geographic Patterns:"),
                      tags$div(
                        style = "display: flex; justify-content: space-between;",
                        tags$div(
                          style = "width: 30%;",
                          h5("High-Value Areas:"),
                          tags$ul(
                            tags$li("Waterfront properties (Lake Washington, Puget Sound)"),
                            tags$li("Bellevue and Redmond (tech hub premium)"),
                            tags$li("Downtown Seattle core"),
                            tags$li("Magnolia and Queen Anne neighborhoods")
                          )
                        ),
                        tags$div(
                          style = "width: 30%;",
                          h5("Price Drivers by Location:"),
                          tags$ul(
                            tags$li("Proximity to water features"),
                            tags$li("Tech company headquarters"),
                            tags$li("School district quality"),
                            tags$li("Transportation access")
                          )
                        ),
                        tags$div(
                          style = "width: 30%;",
                          h5("Investment Insights:"),
                          tags$ul(
                            tags$li("Waterfront: 31.5% price premium"),
                            tags$li("View quality correlates with location"),
                            tags$li("Grade varies significantly by area"),
                            tags$li("Age patterns reflect development history")
                          )
                        )
                      )
                  )
                )
              )
      ),
      
      # Report Generator Tab
      tabItem(tabName = "report",
              fluidRow(
                box(
                  title = "Analytics Report Summary", status = "primary", solidHeader = TRUE,
                  width = 12,
                  h3("Seattle Housing Price Analysis - Executive Summary"),
                  
                  h4("Business Question:"),
                  p("For real estate agents or individuals looking to sell a house in Seattle, what are the most important home features to consider when predicting the sales price?"),
                  
                  h4("Key Findings:"),
                  tags$div(
                    style = "background-color: #f9f9f9; padding: 15px; border: 1px solid #ddd;",
                    h5("Most Important Features for Price Prediction:"),
                    tags$ol(
                      tags$li(strong("House Age"), " - Most influential predictor (222.4% IncMSE)"),
                      tags$li(strong("Lot Size (sqft_lot)"), " - Size of entire property (152.6% IncMSE)"),
                      tags$li(strong("Grade"), " - Appraisal grade of the house (96.8% IncMSE)"),
                      tags$li(strong("Living Space"), " - Liveable square footage (73.0% IncMSE)"),
                      tags$li(strong("View Rating"), " - Scenic outlook quality (64.2% IncMSE)")
                    ),
                    
                    h5("Model Performance:"),
                    tags$ul(
                      tags$li("Random Forest model: 70% variance explained (best for prediction)"),
                      tags$li("OLS model: 65% variance explained (best for interpretation)")
                    ),
                    
                    h5("Key Insights from OLS Model:"),
                    tags$ul(
                      tags$li("Each additional bathroom increases price by 8.4%"),
                      tags$li("Living space increases price by 0.018% per sqft"),
                      tags$li("Each additional floor increases price by 7.7%"),
                      tags$li("Waterfront properties command 31.5% price premium"),
                      tags$li("Counterintuitively, additional bedrooms decrease price by 3.3%")
                    )
                  ),
                  
                  h4("Actionable Recommendations:"),
                  tags$div(
                    style = "background-color: #e8f5e8; padding: 15px; border-left: 4px solid #5cb85c;",
                    tags$ul(
                      tags$li("Focus on property age, lot size, and grade when pricing"),
                      tags$li("Emphasize waterfront and view features in marketing"),
                      tags$li("Consider bathroom count as a key selling point"),
                      tags$li("Use Random Forest model for accurate price predictions"),
                      tags$li("Quality improvements (grade, condition) yield highest ROI")
                    )
                  ),
                  
                  br(),
                  downloadButton("download_report", "Download Full Report", 
                                 class = "btn-primary btn-lg"),
                  br(), br(),
                  p(em("Report generated by AnalyticsPro - Author: Peter Chika Ozo-Ogueji, American University"))
                )
              )
      ),
      
      # Author Tab
      tabItem(tabName = "author",
              fluidRow(
                box(
                  title = "About the Author", status = "primary", solidHeader = TRUE, width = 12,
                  HTML("
                    <div style='padding: 20px;'>
                      <div class='row'>
                        <div class='col-md-4 text-center'>
                          <div style='background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                                      color: white; padding: 30px; border-radius: 15px; margin-bottom: 20px;'>
                            <i class='fas fa-user-graduate fa-5x' style='margin-bottom: 15px;'></i>
                            <h3>Peter Chika Ozo-Ogueji</h3>
                            <h5 style='margin-bottom: 20px; opacity: 0.9;'>Data Scientist | ML Engineer | Analytics Expert</h5>
                            <p><i class='fas fa-map-marker-alt'></i> Maryland, USA</p>
                            <div style='margin: 15px 0;'>
                              <p><i class='fas fa-envelope' style='margin-right: 8px;'></i>
                                <a href='mailto:po3783a@american.edu' style='color: #fff; text-decoration: none; border-bottom: 1px solid rgba(255,255,255,0.3);' 
                                   onmouseover='this.style.borderBottom=\"1px solid #fff\"' onmouseout='this.style.borderBottom=\"1px solid rgba(255,255,255,0.3)\"'>
                                  po3783a@american.edu
                                </a>
                              </p>
                              <p><i class='fab fa-linkedin' style='margin-right: 8px;'></i>
                                <a href='http://linkedin.com/in/peterchika/' target='_blank' rel='noopener noreferrer' 
                                   style='color: #fff; text-decoration: none; border-bottom: 1px solid rgba(255,255,255,0.3);'
                                   onmouseover='this.style.borderBottom=\"1px solid #fff\"' onmouseout='this.style.borderBottom=\"1px solid rgba(255,255,255,0.3)\"'>
                                  linkedin.com/in/peterchika
                                </a>
                              </p>
                              <p><i class='fab fa-github' style='margin-right: 8px;'></i>
                                <a href='https://github.com/PeterOzo' target='_blank' rel='noopener noreferrer' 
                                   style='color: #fff; text-decoration: none; border-bottom: 1px solid rgba(255,255,255,0.3);'
                                   onmouseover='this.style.borderBottom=\"1px solid #fff\"' onmouseout='this.style.borderBottom=\"1px solid rgba(255,255,255,0.3)\"'>
                                  github.com/PeterOzo
                                </a>
                              </p>
                            </div>
                            <div style='margin-top: 20px;'>
                              <span style='background: rgba(255,255,255,0.2); padding: 5px 10px; border-radius: 15px; margin: 2px; display: inline-block; font-size: 0.9em;'>Python</span>
                              <span style='background: rgba(255,255,255,0.2); padding: 5px 10px; border-radius: 15px; margin: 2px; display: inline-block; font-size: 0.9em;'>R</span>
                              <span style='background: rgba(255,255,255,0.2); padding: 5px 10px; border-radius: 15px; margin: 2px; display: inline-block; font-size: 0.9em;'>SQL</span>
                              <span style='background: rgba(255,255,255,0.2); padding: 5px 10px; border-radius: 15px; margin: 2px; display: inline-block; font-size: 0.9em;'>AWS</span>
                              <span style='background: rgba(255,255,255,0.2); padding: 5px 10px; border-radius: 15px; margin: 2px; display: inline-block; font-size: 0.9em;'>Power BI</span>
                            </div>
                          </div>
                        </div>
                        <div class='col-md-8'>
                          <h3><i class='fas fa-graduation-cap'></i> Education & Academic Excellence</h3>
                          <div style='background: #f8f9fa; padding: 15px; border-radius: 8px; margin-bottom: 15px;'>
                            <div class='row'>
                              <div class='col-md-6'>
                                <ul style='list-style: none; padding-left: 0;'>
                                  <li style='margin-bottom: 8px;'><i class='fas fa-award' style='color: #3498DB; margin-right: 8px;'></i><strong>Master of Data Science</strong><br><small>American University (2024-2025)</small></li>
                                  <li style='margin-bottom: 8px;'><i class='fas fa-award' style='color: #3498DB; margin-right: 8px;'></i><strong>MS in Analytics</strong><br><small>American University, Kogod (2023-2024)</small></li>
                                </ul>
                              </div>
                              <div class='col-md-6'>
                                <ul style='list-style: none; padding-left: 0;'>
                                  <li style='margin-bottom: 8px;'><i class='fas fa-award' style='color: #27AE60; margin-right: 8px;'></i><strong>MEd in Mathematics</strong><br><small>Philippines College of Health Sciences</small></li>
                                  <li style='margin-bottom: 8px;'><i class='fas fa-award' style='color: #27AE60; margin-right: 8px;'></i><strong>BSc in Statistics</strong><br><small>Federal University of Technology Owerri</small></li>
                                </ul>
                              </div>
                            </div>
                          </div>
                          
                          <h3><i class='fas fa-briefcase'></i> Professional Experience</h3>
                          <div style='background: #e8f5e8; padding: 15px; border-radius: 8px; margin-bottom: 15px;'>
                            <div class='row'>
                              <div class='col-md-6'>
                                <h5><i class='fas fa-chalkboard-teacher'></i> Graduate Assistant - American University</h5>
                                <ul style='font-size: 0.9em;'>
                                  <li>Teaching Statistical Machine Learning & Data Science</li>
                                  <li>Enhanced student understanding by 15%</li>
                                  <li>Python, R programming instruction</li>
                                </ul>
                              </div>
                              <div class='col-md-6'>
                                <h5><i class='fas fa-laptop-code'></i> Data Science Intern - METY Technology</h5>
                                <ul style='font-size: 0.9em;'>
                                  <li>Healthcare analytics & cost optimization</li>
                                  <li>ML models with 10% accuracy improvement</li>
                                  <li>SQL optimization reducing costs by 15%</li>
                                </ul>
                              </div>
                            </div>
                            <div style='margin-top: 15px;'>
                              <h5><i class='fas fa-university'></i> Assistant Bank Data Analyst - Polaris Bank Limited</h5>
                              <p style='font-size: 0.9em; margin: 0;'>Fraud management system implementation • 30% fraud reduction using IBM analytics • Data warehouse architecture • Predictive modeling & risk analysis</p>
                            </div>
                          </div>
                          
                          <h3><i class='fas fa-trophy'></i> Achievements & Recognition</h3>
                          <div style='background: #fff3cd; padding: 15px; border-radius: 8px; margin-bottom: 15px;'>
                            <div class='row'>
                              <div class='col-md-6'>
                                <ul style='list-style: none; padding-left: 0; font-size: 0.9em;'>
                                  <li><i class='fas fa-medal' style='color: #F39C12; margin-right: 8px;'></i><strong>Google Hackathon Winner</strong></li>
                                  <li><i class='fas fa-chart-line' style='color: #E74C3C; margin-right: 8px;'></i><strong>COVID-19 Research:</strong> 96.75% accuracy</li>
                                  <li><i class='fas fa-users' style='color: #9B59B6; margin-right: 8px;'></i><strong>Smith Analytics Consortium</strong> Participant</li>
                                </ul>
                              </div>
                              <div class='col-md-6'>
                                <ul style='list-style: none; padding-left: 0; font-size: 0.9em;'>
                                  <li><i class='fas fa-microscope' style='color: #3498DB; margin-right: 8px;'></i><strong>Penn Conference</strong> on Big Data</li>
                                  <li><i class='fas fa-robot' style='color: #2ECC71; margin-right: 8px;'></i><strong>AI & Robotics Club</strong> Member</li>
                                  <li><i class='fas fa-graduation-cap' style='color: #1ABC9C; margin-right: 8px;'></i><strong>Graduate Faculty Fellow</strong></li>
                                </ul>
                              </div>
                            </div>
                          </div>
                          
                          <h3><i class='fas fa-cogs'></i> Technical Expertise</h3>
                          <div style='background: #e3f2fd; padding: 15px; border-radius: 8px;'>
                            <div class='row'>
                              <div class='col-md-4'>
                                <h5>Programming</h5>
                                <span style='background: #3498DB; color: white; padding: 3px 8px; border-radius: 10px; margin: 2px; display: inline-block; font-size: 0.8em;'>Python</span>
                                <span style='background: #3498DB; color: white; padding: 3px 8px; border-radius: 10px; margin: 2px; display: inline-block; font-size: 0.8em;'>R</span>
                                <span style='background: #3498DB; color: white; padding: 3px 8px; border-radius: 10px; margin: 2px; display: inline-block; font-size: 0.8em;'>SQL</span>
                                <span style='background: #3498DB; color: white; padding: 3px 8px; border-radius: 10px; margin: 2px; display: inline-block; font-size: 0.8em;'>Shell</span>
                              </div>
                              <div class='col-md-4'>
                                <h5>ML & AI</h5>
                                <span style='background: #27AE60; color: white; padding: 3px 8px; border-radius: 10px; margin: 2px; display: inline-block; font-size: 0.8em;'>TensorFlow</span>
                                <span style='background: #27AE60; color: white; padding: 3px 8px; border-radius: 10px; margin: 2px; display: inline-block; font-size: 0.8em;'>PyTorch</span>
                                <span style='background: #27AE60; color: white; padding: 3px 8px; border-radius: 10px; margin: 2px; display: inline-block; font-size: 0.8em;'>Scikit-learn</span>
                                <span style='background: #27AE60; color: white; padding: 3px 8px; border-radius: 10px; margin: 2px; display: inline-block; font-size: 0.8em;'>NLP</span>
                              </div>
                              <div class='col-md-4'>
                                <h5>Cloud & BI</h5>
                                <span style='background: #E67E22; color: white; padding: 3px 8px; border-radius: 10px; margin: 2px; display: inline-block; font-size: 0.8em;'>AWS</span>
                                <span style='background: #E67E22; color: white; padding: 3px 8px; border-radius: 10px; margin: 2px; display: inline-block; font-size: 0.8em;'>Power BI</span>
                                <span style='background: #E67E22; color: white; padding: 3px 8px; border-radius: 10px; margin: 2px; display: inline-block; font-size: 0.8em;'>Tableau</span>
                                <span style='background: #E67E22; color: white; padding: 3px 8px; border-radius: 10px; margin: 2px; display: inline-block; font-size: 0.8em;'>BigQuery</span>
                              </div>
                            </div>
                          </div>
                        </div>
                      </div>
                      
                      <hr style='margin: 30px 0;'>
                      
                      <div class='row'>
                        <div class='col-md-6'>
                          <h3><i class='fas fa-flask'></i> Featured Research Projects</h3>
                          <div style='background: #f8f9fa; padding: 15px; border-radius: 8px;'>
                            <h5><i class='fas fa-virus'></i> COVID-19 Misinformation Detection</h5>
                            <p style='font-size: 0.9em; margin-bottom: 10px;'>Fine-tuned RoBERTa & LLaMA models achieving <strong>96.75% accuracy</strong> with AUC-ROC of 0.97. Applied advanced NLP techniques for social media analysis.</p>
                            
                            <h5><i class='fas fa-heartbeat'></i> ICU Patient Monitoring System</h5>
                            <p style='font-size: 0.9em; margin-bottom: 10px;'>Developed adaptive ML model using MIMIC-III dataset. Engineered 25+ clinical features for real-time critical condition detection.</p>
                            
                            <h5><i class='fas fa-mobile-alt'></i> Health App Success Prediction</h5>
                            <p style='font-size: 0.9em; margin: 0;'>Built ML model with <strong>84.4% accuracy</strong> for METY Technology. Analyzed 180+ apps, identified AI features as #1 success driver.</p>
                          </div>
                        </div>
                        
                        <div class='col-md-6'>
                          <h3><i class='fas fa-chart-bar'></i> Key Analytics Insights</h3>
                          <div style='background: #e8f5e8; padding: 15px; border-radius: 8px;'>
                            <ul style='list-style: none; padding-left: 0;'>
                              <li style='margin-bottom: 8px;'><i class='fas fa-bullseye' style='color: #E74C3C; margin-right: 8px;'></i><strong>Fraud Reduction:</strong> 30% decrease using IBM analytics platform</li>
                              <li style='margin-bottom: 8px;'><i class='fas fa-chart-line' style='color: #27AE60; margin-right: 8px;'></i><strong>Revenue Impact:</strong> 35% increase through ML forecasting</li>
                              <li style='margin-bottom: 8px;'><i class='fas fa-brain' style='color: #3498DB; margin-right: 8px;'></i><strong>NLP Excellence:</strong> 97% AUC-ROC for text classification</li>
                              <li style='margin-bottom: 8px;'><i class='fas fa-users' style='color: #9B59B6; margin-right: 8px;'></i><strong>Teaching Impact:</strong> 15% improvement in student outcomes</li>
                              <li style='margin-bottom: 8px;'><i class='fas fa-database' style='color: #F39C12; margin-right: 8px;'></i><strong>Cost Optimization:</strong> 15% reduction in healthcare costs</li>
                            </ul>
                          </div>
                        </div>
                      </div>
                      
                      <hr style='margin: 30px 0;'>
                      <div style='background: linear-gradient(135deg, #74b9ff 0%, #0984e3 100%); padding: 20px; border-radius: 10px; color: white; text-align: center;'>
                        <h4><i class='fas fa-quote-left'></i> Professional Philosophy</h4>
                        <p style='font-style: italic; font-size: 1.1em; margin: 15px 0;'>
                          \"I turn coffee into code and data into insights! As a dedicated data scientist, I leverage advanced analytics 
                          and machine learning to solve complex real-world challenges. My research in COVID-19 misinformation detection 
                          and healthcare analytics represents my commitment to using data science for public health and social good.\"
                        </p>
                        <div style='margin-top: 20px;'>
                          <span style='background: rgba(255,255,255,0.2); padding: 8px 15px; border-radius: 20px; margin: 0 5px; display: inline-block;'>
                            <i class='fas fa-heart'></i> Passionate Problem Solver
                          </span>
                          <span style='background: rgba(255,255,255,0.2); padding: 8px 15px; border-radius: 20px; margin: 0 5px; display: inline-block;'>
                            <i class='fas fa-lightbulb'></i> Innovation Driver
                          </span>
                          <span style='background: rgba(255,255,255,0.2); padding: 8px 15px; border-radius: 20px; margin: 0 5px; display: inline-block;'>
                            <i class='fas fa-handshake'></i> Collaborative Leader
                          </span>
                        </div>
                      </div>
                    </div>
                  ")
                )
              )
      )
    )
  )
)

# Define Server
server <- function(input, output, session) {
  
  # Load and preprocess the actual Seattle housing data
  housing_data <- reactive({
    # Read the actual CSV file
    tryCatch({
      df <- read.csv("house_sales.csv", stringsAsFactors = FALSE)
      
      # Data preprocessing following the project specifications
      cat("Original dataset size:", nrow(df), "rows\n")
      
      # Remove outlier: house with 33 bedrooms (as identified in the project)
      outlier_count <- sum(df$bedrooms == 33, na.rm = TRUE)
      if(outlier_count > 0) {
        cat("Removing", outlier_count, "outlier(s) with 33 bedrooms\n")
        df <- df[df$bedrooms != 33, ]
      }
      
      # Create house_age variable (2024 - yr_built)
      df$house_age <- 2024 - df$yr_built
      
      # Create binary renovated variable
      # 0 indicates no renovation (yr_renovated = 0)
      # 1 indicates renovated (yr_renovated != 0)
      df$renovated <- ifelse(df$yr_renovated == 0, 0, 1)
      
      # Create price per sqft for geographic analysis
      df$price_per_sqft <- df$price / df$sqft_living
      
      # Remove unnecessary variables as per project specifications
      unnecessary_vars <- c("id", "date", "sqft_above", "sqft_basement", 
                            "zipcode", "yr_built", "yr_renovated", 
                            "sqft_living15", "sqft_lot15")
      df <- df[, !names(df) %in% unnecessary_vars]
      
      # Convert categorical variables to factors
      df$waterfront <- as.factor(df$waterfront)
      df$view <- as.factor(df$view)
      df$condition <- as.factor(df$condition)
      df$grade <- as.factor(df$grade)
      df$renovated <- as.factor(df$renovated)
      
      # Ensure numeric variables are properly formatted
      numeric_vars <- c("price", "bedrooms", "bathrooms", "sqft_living", 
                        "sqft_lot", "floors", "house_age", "lat", "long", "price_per_sqft")
      for(var in numeric_vars) {
        if(var %in% names(df)) {
          df[[var]] <- as.numeric(df[[var]])
        }
      }
      
      # Remove any rows with missing essential data
      essential_vars <- c("price", "bedrooms", "bathrooms", "sqft_living")
      df <- df[complete.cases(df[essential_vars]), ]
      
      cat("Final dataset size:", nrow(df), "rows,", ncol(df), "columns\n")
      cat("Variables included:", paste(names(df), collapse = ", "), "\n")
      
      return(df)
      
    }, error = function(e) {
      # Fallback to sample data if CSV file is not found
      cat("Error loading house_sales.csv:", e$message, "\n")
      cat("Using sample data instead...\n")
      
      # Generate sample data as fallback
      set.seed(123)
      n <- 21612  # Original size minus 1 outlier
      df <- data.frame(
        price = round(rlnorm(n, meanlog = log(540084), sdlog = 0.8)),
        bedrooms = sample(1:11, n, replace = TRUE, 
                          prob = c(0.009, 0.128, 0.454, 0.318, 0.074, 0.013, 0.002, 0.001, 0.0003, 0.0001, 0.00005)),
        bathrooms = round(runif(n, 0.5, 8), 2),
        sqft_living = round(rnorm(n, 2080, 918)),
        sqft_lot = round(rlnorm(n, log(15000), 1.2)),
        floors = sample(c(1, 1.5, 2, 2.5, 3, 3.5), n, replace = TRUE, 
                        prob = c(0.49, 0.05, 0.36, 0.03, 0.06, 0.01)),
        waterfront = sample(0:1, n, replace = TRUE, prob = c(0.9925, 0.0075)),
        view = sample(0:4, n, replace = TRUE, prob = c(0.90, 0.05, 0.02, 0.02, 0.01)),
        condition = sample(1:5, n, replace = TRUE, prob = c(0.003, 0.025, 0.65, 0.3, 0.022)),
        grade = sample(3:13, n, replace = TRUE, 
                       prob = c(0.001, 0.003, 0.013, 0.10, 0.205, 0.274, 0.220, 0.134, 0.041, 0.008, 0.001)),
        house_age = 2024 - sample(1900:2015, n, replace = TRUE),
        renovated = sample(0:1, n, replace = TRUE, prob = c(0.83, 0.17)),
        lat = runif(n, 47.1559, 47.7776),
        long = runif(n, -122.5158, -121.3152)
      )
      
      # Create price per sqft
      df$price_per_sqft <- df$price / df$sqft_living
      
      # Convert to factors
      df$waterfront <- as.factor(df$waterfront)
      df$view <- as.factor(df$view)
      df$condition <- as.factor(df$condition)
      df$grade <- as.factor(df$grade)
      df$renovated <- as.factor(df$renovated)
      
      return(df)
    })
  })
  
  # Filtered data based on user inputs
  filtered_data <- reactive({
    df <- housing_data()
    
    # Apply price filter
    df <- df[df$price >= input$price_filter[1] & df$price <= input$price_filter[2], ]
    
    # Apply bedrooms filter
    df <- df[df$bedrooms >= input$bedrooms_filter[1] & df$bedrooms <= input$bedrooms_filter[2], ]
    
    # Apply bathrooms filter
    df <- df[df$bathrooms >= input$bathrooms_filter[1] & df$bathrooms <= input$bathrooms_filter[2], ]
    
    # Apply waterfront filter
    if (!is.null(input$waterfront_filter)) {
      df <- df[as.character(df$waterfront) %in% input$waterfront_filter, ]
    }
    
    # Remove any rows with NA values in filtered columns
    df <- df[complete.cases(df[c("price", "bedrooms", "bathrooms", "waterfront")]), ]
    
    return(df)
  })
  
  # Geographic filtered data
  geo_filtered_data <- eventReactive(input$update_map, {
    df <- housing_data()
    
    # Apply price filter
    df <- df[df$price >= input$geo_price_range[1] & df$price <= input$geo_price_range[2], ]
    
    # Apply waterfront filter
    if (!is.null(input$geo_waterfront)) {
      df <- df[as.character(df$waterfront) %in% input$geo_waterfront, ]
    }
    
    # Sample data for performance
    if (nrow(df) > input$geo_sample_size) {
      df <- df[sample(nrow(df), input$geo_sample_size), ]
    }
    
    return(df)
  }, ignoreNULL = FALSE)
  
  # Reset filters to match actual data ranges
  observe({
    df <- housing_data()
    if (nrow(df) > 0) {
      # Update price filter with actual data range
      min_price <- floor(min(df$price, na.rm = TRUE)/1000)*1000
      max_price <- ceiling(max(df$price, na.rm = TRUE)/1000)*1000
      
      updateSliderInput(session, "price_filter", 
                        min = min_price,
                        max = max_price,
                        value = c(min_price, max_price))
      
      updateSliderInput(session, "geo_price_range",
                        min = min_price,
                        max = max_price,
                        value = c(200000, 2000000))
      
      # Update bedrooms filter
      min_bed <- min(df$bedrooms, na.rm = TRUE)
      max_bed <- max(df$bedrooms, na.rm = TRUE)
      
      updateSliderInput(session, "bedrooms_filter",
                        min = min_bed,
                        max = max_bed,
                        value = c(min_bed, max_bed))
      
      # Update bathrooms filter
      min_bath <- floor(min(df$bathrooms, na.rm = TRUE)*4)/4
      max_bath <- ceiling(max(df$bathrooms, na.rm = TRUE)*4)/4
      
      updateSliderInput(session, "bathrooms_filter",
                        min = min_bath,
                        max = max_bath,
                        value = c(min_bath, max_bath))
    }
  })
  
  # Reset filters to actual data ranges
  observeEvent(input$reset_filters, {
    df <- housing_data()
    if (nrow(df) > 0) {
      # Reset price filter
      min_price <- floor(min(df$price, na.rm = TRUE)/1000)*1000
      max_price <- ceiling(max(df$price, na.rm = TRUE)/1000)*1000
      updateSliderInput(session, "price_filter", value = c(min_price, max_price))
      
      # Reset bedrooms filter
      min_bed <- min(df$bedrooms, na.rm = TRUE)
      max_bed <- max(df$bedrooms, na.rm = TRUE)
      updateSliderInput(session, "bedrooms_filter", value = c(min_bed, max_bed))
      
      # Reset bathrooms filter
      min_bath <- floor(min(df$bathrooms, na.rm = TRUE)*4)/4
      max_bath <- ceiling(max(df$bathrooms, na.rm = TRUE)*4)/4
      updateSliderInput(session, "bathrooms_filter", value = c(min_bath, max_bath))
      
      # Reset waterfront filter
      updateCheckboxGroupInput(session, "waterfront_filter", selected = c("0", "1"))
    }
  })
  
  # Dashboard outputs
  output$total_properties <- renderValueBox({
    valueBox(
      value = formatC(nrow(housing_data()), format = "f", big.mark = ",", digits = 0),
      subtitle = "Total Properties",
      icon = icon("home"),
      color = "blue"
    )
  })
  
  output$avg_price <- renderValueBox({
    valueBox(
      value = paste0("$", formatC(round(mean(housing_data()$price)), format = "f", big.mark = ",", digits = 0)),
      subtitle = "Average Price",
      icon = icon("dollar-sign"),
      color = "green"
    )
  })
  
  output$price_range <- renderValueBox({
    df <- housing_data()
    valueBox(
      value = paste0("$", formatC(round(max(df$price) - min(df$price)), format = "f", big.mark = ",", digits = 0)),
      subtitle = "Price Range",
      icon = icon("chart-line"),
      color = "yellow"
    )
  })
  
  # Price distribution plot with currency formatting
  output$price_dist <- renderPlotly({
    df <- housing_data()
    p <- ggplot(df, aes(x = price)) +
      geom_histogram(bins = 50, fill = "#3c8dbc", alpha = 0.7) +
      labs(title = "Distribution of House Prices",
           x = "Price ($)", y = "Frequency") +
      theme_minimal() +
      scale_x_continuous(labels = function(x) paste0("$", formatC(x/1000, format = "f", big.mark = ",", digits = 0), "K"))
    ggplotly(p) %>%
      layout(xaxis = list(title = "Price"))
  })
  
  # Summary statistics
  output$summary_stats <- DT::renderDataTable({
    df <- housing_data()
    numeric_vars <- df[, sapply(df, is.numeric)]
    summary_df <- data.frame(
      Variable = names(numeric_vars),
      Mean = round(sapply(numeric_vars, mean, na.rm = TRUE), 2),
      Median = round(sapply(numeric_vars, median, na.rm = TRUE), 2),
      SD = round(sapply(numeric_vars, sd, na.rm = TRUE), 2)
    )
    
    DT::datatable(summary_df, options = list(pageLength = 10, dom = 't'))
  })
  
  # Price vs sqft plot with proper formatting
  output$price_vs_sqft <- renderPlotly({
    df <- housing_data()
    p <- ggplot(df, aes(x = sqft_living, y = price, color = factor(waterfront))) +
      geom_point(alpha = 0.6, size = 0.8) +
      geom_smooth(method = "lm", se = FALSE) +
      labs(title = "Price vs Living Space",
           x = "Living Space (sqft)", y = "Price ($)",
           color = "Waterfront") +
      theme_minimal() +
      scale_y_continuous(labels = function(x) paste0("$", formatC(x/1000, format = "f", big.mark = ",", digits = 0), "K")) +
      scale_color_manual(values = c("0" = "#999999", "1" = "#3c8dbc"),
                         labels = c("0" = "No", "1" = "Yes"))
    ggplotly(p)
  })
  
  # Data table
  output$data_table <- DT::renderDataTable({
    DT::datatable(filtered_data(), 
                  options = list(scrollX = TRUE, pageLength = 15))
  })
  
  # Custom visualization
  output$custom_plot <- renderPlotly({
    df <- housing_data()
    
    if (input$plot_type == "scatter") {
      p <- ggplot(df, aes_string(x = input$x_var, y = input$y_var))
      
      if (input$color_var != "none") {
        p <- p + geom_point(aes_string(color = input$color_var), alpha = 0.6)
      } else {
        p <- p + geom_point(alpha = 0.6, color = "#3c8dbc")
      }
      
      p <- p + theme_minimal() +
        labs(title = paste(input$y_var, "vs", input$x_var))
      
    } else if (input$plot_type == "box") {
      if (input$color_var != "none") {
        p <- ggplot(df, aes_string(x = factor(input$color_var), y = input$y_var)) +
          geom_boxplot(aes_string(fill = factor(input$color_var))) +
          theme_minimal() +
          labs(title = paste(input$y_var, "by", input$color_var))
      } else {
        p <- ggplot(df, aes_string(x = 1, y = input$y_var)) +
          geom_boxplot(fill = "#3c8dbc") +
          theme_minimal() +
          labs(title = paste("Distribution of", input$y_var))
      }
      
    } else if (input$plot_type == "hist") {
      p <- ggplot(df, aes_string(x = input$x_var)) +
        geom_histogram(bins = 30, fill = "#3c8dbc", alpha = 0.7) +
        theme_minimal() +
        labs(title = paste("Histogram of", input$x_var))
      
    } else if (input$plot_type == "density") {
      p <- ggplot(df, aes_string(x = input$x_var)) +
        geom_density(fill = "#3c8dbc", alpha = 0.7) +
        theme_minimal() +
        labs(title = paste("Density plot of", input$x_var))
    }
    
    ggplotly(p)
  })
  
  # Visualization interpretation
  output$viz_interpretation <- renderUI({
    interpretation_text <- ""
    
    if (input$plot_type == "scatter") {
      if (input$x_var == "sqft_living" && input$y_var == "price") {
        interpretation_text <- "Strong positive relationship (r=0.70) between living space and price. Each additional sqft increases price by ~0.018%."
      } else if (input$x_var == "bathrooms" && input$y_var == "price") {
        interpretation_text <- "Moderate positive correlation (r=0.53). Each additional bathroom increases price by approximately 8.4%."
      } else if (input$x_var == "house_age" && input$y_var == "price") {
        interpretation_text <- "Weak negative correlation (r=-0.05). Surprisingly, older houses show slight price increases of 0.6% per year."
      } else {
        interpretation_text <- paste("Examine the relationship pattern between", input$x_var, "and", input$y_var, "for pricing insights.")
      }
    } else if (input$plot_type == "box") {
      if (input$color_var == "waterfront") {
        interpretation_text <- "Waterfront properties show 31.5% price premium compared to non-waterfront homes."
      } else if (input$color_var == "view") {
        interpretation_text <- "View ratings show clear price progression: View 4 commands 25.2% premium, View 1-3 show 9.7%-18% increases."
      } else if (input$color_var == "condition") {
        interpretation_text <- "Condition ratings 3-5 show 14.9%-23.4% price increases compared to condition 1-2."
      } else if (input$color_var == "grade") {
        interpretation_text <- "Grade 8-13 properties show dramatic 72%-134% price premiums, reflecting quality's massive impact."
      }
    } else if (input$plot_type == "hist") {
      interpretation_text <- paste("Distribution shape of", input$x_var, "shows data patterns and potential outliers.")
    }
    
    HTML(paste0("<p style='margin: 0; font-size: 0.9em;'>", interpretation_text, "</p>"))
  })
  
  # Correlation analysis
  output$correlation_plot <- renderPlot({
    df <- housing_data()
    numeric_vars <- df[, sapply(df, is.numeric)]
    cor_matrix <- cor(numeric_vars, use = "complete.obs")
    
    corrplot(cor_matrix, method = "color", type = "upper", 
             order = "hclust", tl.cex = 0.8, tl.col = "black",
             title = "Correlation Matrix of Numeric Variables")
  })
  
  output$correlation_table <- DT::renderDataTable({
    df <- housing_data()
    numeric_vars <- df[, sapply(df, is.numeric)]
    cor_matrix <- cor(numeric_vars, use = "complete.obs")
    
    price_corr <- cor_matrix[, "price"]
    price_corr <- price_corr[names(price_corr) != "price"]
    price_corr_sorted <- sort(abs(price_corr), decreasing = TRUE)
    
    corr_df <- data.frame(
      Variable = names(price_corr_sorted),
      Correlation = round(price_corr[names(price_corr_sorted)], 3),
      Abs_Correlation = round(price_corr_sorted, 3)
    )
    
    DT::datatable(corr_df, options = list(pageLength = 10, dom = 't')) %>%
      DT::formatStyle('Correlation', 
                      backgroundColor = DT::styleInterval(c(-0.3, 0.3), c('#ffcccc', '#ffffff', '#ccffcc')))
  })
  
  # Enhanced Price prediction with proper model coefficients
  observeEvent(input$predict_price, {
    # Using the actual OLS.small model coefficients from the research
    # Base calculation using log-linear model then converting back
    
    # Start with intercept (log scale)
    log_price <- 1.138e+01  # Intercept from OLS.small model
    
    # Add effects based on OLS.small coefficients
    log_price <- log_price + (-3.295e-02 * input$pred_bedrooms)  # Bedrooms coefficient
    log_price <- log_price + (8.043e-02 * input$pred_bathrooms)  # Bathrooms coefficient  
    log_price <- log_price + (1.845e-04 * input$pred_sqft_living)  # Living space coefficient
    log_price <- log_price + (7.733e-02 * input$pred_floors)  # Floors coefficient
    log_price <- log_price + (5.785e-03 * input$pred_house_age)  # House age coefficient
    
    # Waterfront effect
    if (as.numeric(input$pred_waterfront) == 1) {
      log_price <- log_price + 3.145e-01  # Waterfront coefficient
    }
    
    # View effects (relative to view 0)
    view_coeffs <- c(0, 1.803e-01, 9.658e-02, 1.270e-01, 2.518e-01)  # view0, view1, view2, view3, view4
    view_level <- as.numeric(input$pred_view) + 1
    if (view_level <= length(view_coeffs)) {
      log_price <- log_price + view_coeffs[view_level]
    }
    
    # Condition effects (relative to condition 1)
    condition_coeffs <- c(0, -1.427e-02, 1.489e-01, 1.677e-01, 2.342e-01)  # condition1, 2, 3, 4, 5
    condition_level <- as.numeric(input$pred_condition)
    if (condition_level <= length(condition_coeffs)) {
      log_price <- log_price + condition_coeffs[condition_level]
    }
    
    # Grade effects (relative to grade 1) - only including available grades 3-13
    grade_coeffs <- c(-5.117e-02, -5.690e-02, -1.061e-02, 2.076e-01, 4.870e-01,
                      7.227e-01, 9.557e-01, 1.115e+00, 1.231e+00, 1.318e+00, 1.340e+00)
    names(grade_coeffs) <- c("3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13")
    
    grade_level <- as.character(input$pred_grade)
    if (grade_level %in% names(grade_coeffs)) {
      log_price <- log_price + grade_coeffs[grade_level]
    }
    
    # Convert from log scale back to actual price
    predicted_price <- exp(log_price)
    
    # Ensure reasonable bounds
    predicted_price <- max(predicted_price, 75000)  # Minimum reasonable price
    predicted_price <- min(predicted_price, 10000000)  # Maximum reasonable price
    
    # Store the prediction for display
    output$prediction_display <- renderText({
      paste0("$", formatC(round(predicted_price), format = "f", big.mark = ",", digits = 0))
    })
  })
  
  # Model results
  output$model_results <- DT::renderDataTable({
    model_data <- data.frame(
      Model = c("RF.full", "RF.small", "LASSO.small.wts", "LASSO.small", 
                "LASSO.full.wts", "LASSO.full", "OLS.small", "WLS.small", 
                "OLS.full", "WLS.full"),
      MSE = c(0.086300, 0.091526, 0.097070, 0.097091,
              0.097089, 0.097110, 0.097129, 0.097135,
              0.097169, 0.097179),
      RMSE = c(0.293768, 0.302532, 0.311560, 0.311595,
               0.311591, 0.311625, 0.311655, 0.311665,
               0.311720, 0.311736),
      Method = c("Random Forest", "Random Forest", "LASSO", "LASSO", "LASSO", "LASSO", 
                 "OLS", "WLS", "OLS", "WLS"),
      Specification = c("Full", "Small", "Small.wts", "Small", "Full.wts", "Full", 
                        "Small", "Small", "Full", "Full"),
      R_Squared = c(0.70, 0.68, 0.65, 0.65, 0.65, 0.65, 0.65, 0.65, 0.68, 0.68)
    )
    
    DT::datatable(model_data, options = list(pageLength = 10)) %>%
      DT::formatRound(columns = c("MSE", "RMSE", "R_Squared"), digits = 4) %>%
      DT::formatStyle('MSE', 
                      backgroundColor = DT::styleInterval(c(0.090, 0.095), c('#ccffcc', '#ffffcc', '#ffcccc')))
  })
  
  # Model comparison plot
  output$model_comparison <- renderPlotly({
    model_data <- data.frame(
      Model = c("RF.full", "RF.small", "LASSO.small.wts", "LASSO.small", 
                "LASSO.full.wts", "LASSO.full", "OLS.small", "WLS.small", 
                "OLS.full", "WLS.full"),
      MSE = c(0.086300, 0.091526, 0.097070, 0.097091,
              0.097089, 0.097110, 0.097129, 0.097135,
              0.097169, 0.097179)
    )
    
    p <- ggplot(model_data, aes(x = reorder(Model, -MSE), y = MSE, fill = MSE)) +
      geom_bar(stat = "identity", alpha = 0.8) +
      scale_fill_gradient(low = "#2ECC71", high = "#E74C3C") +
      labs(title = "Model Performance Comparison (10-Fold CV)",
           x = "Model", y = "Mean Squared Error") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
    
    ggplotly(p)
  })
  
  # Enhanced Geographic map
  output$price_map <- renderLeaflet({
    df <- geo_filtered_data()
    
    if (nrow(df) == 0) {
      # Return empty map if no data
      leaflet() %>%
        addTiles() %>%
        setView(lng = -122.3, lat = 47.6, zoom = 10)
    } else {
      # Create color palette based on selected variable
      color_var <- input$geo_color_by
      if (color_var == "price_per_sqft") {
        pal <- colorNumeric(palette = viridis(10), domain = df$price_per_sqft)
        color_values <- df$price_per_sqft
        legend_title <- "Price per SqFt ($)"
      } else if (color_var == "price") {
        pal <- colorNumeric(palette = viridis(10), domain = df$price)
        color_values <- df$price
        legend_title <- "Price ($)"
      } else {
        pal <- colorNumeric(palette = viridis(10), domain = df[[color_var]])
        color_values <- df[[color_var]]
        legend_title <- paste(color_var)
      }
      
      leaflet(df) %>%
        addTiles() %>%
        addCircleMarkers(
          lng = ~long, lat = ~lat,
          color = ~pal(color_values),
          popup = ~paste(
            "<b>Price:</b> $", formatC(price, format = "f", big.mark = ",", digits = 0), "<br>",
            "<b>Price/SqFt:</b> $", round(price_per_sqft, 0), "<br>",
            "<b>Bedrooms:</b>", bedrooms, "<br>",
            "<b>Bathrooms:</b>", bathrooms, "<br>",
            "<b>Living Space:</b>", formatC(sqft_living, format = "f", big.mark = ",", digits = 0), " sqft<br>",
            "<b>Grade:</b>", grade, "<br>",
            "<b>View:</b>", view, "<br>",
            "<b>Waterfront:</b>", ifelse(waterfront == 1, "Yes", "No")
          ),
          radius = 4,
          opacity = 0.7,
          fillOpacity = 0.6
        ) %>%
        addLegend(pal = pal, values = color_values, title = legend_title,
                  position = "bottomright") %>%
        setView(lng = -122.3, lat = 47.6, zoom = 10)
    }
  })
  
  # Download report
  output$download_report <- downloadHandler(
    filename = function() {
      paste("Seattle_Housing_Analytics_Report_", Sys.Date(), ".html", sep = "")
    },
    content = function(file) {
      # Generate comprehensive HTML report
      report_html <- paste0(
        "<html><head><title>Seattle Housing Analytics Report</title>",
        "<style>body{font-family: Arial, sans-serif; margin: 40px; line-height: 1.6;} ",
        "h1{color: #3c8dbc; border-bottom: 3px solid #3c8dbc; padding-bottom: 10px;} ",
        "h2{color: #367fa9; border-left: 4px solid #3c8dbc; padding-left: 15px;} ",
        "h3{color: #2c6fbb;} ",
        ".summary{background-color: #f0f8ff; padding: 20px; border-left: 6px solid #3c8dbc; margin: 20px 0; border-radius: 5px;} ",
        ".finding{background-color: #f9f9f9; padding: 15px; margin: 15px 0; border: 1px solid #ddd; border-radius: 5px;} ",
        ".highlight{background-color: #e8f5e8; padding: 15px; border-left: 4px solid #5cb85c; margin: 15px 0; border-radius: 5px;} ",
        "table{border-collapse: collapse; width: 100%; margin: 20px 0;} ",
        "th, td{border: 1px solid #ddd; padding: 12px; text-align: left;} ",
        "th{background-color: #3c8dbc; color: white;} ",
        ".metric{display: inline-block; background: #f8f9fa; padding: 10px 15px; margin: 5px; border-radius: 5px; border-left: 3px solid #3c8dbc;} ",
        ".author-section{background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 10px; margin: 20px 0;}</style></head><body>",
        
        "<h1>🏠 AnalyticsPro - Seattle Housing Price Analysis Report</h1>",
        "<div class='author-section'><h3>📊 Comprehensive Data Science Analysis</h3>",
        "<p><strong>Author:</strong> Peter Chika Ozo-Ogueji</p>",
        "<p><strong>Institution:</strong> American University, Kogod School of Business</p>",
        "<p><strong>Program:</strong> Master of Data Science | MS in Analytics</p>",
        "<p><strong>Generated:</strong> ", Sys.Date(), "</p></div>",
        
        "<div class='summary'>",
        "<h2>🎯 Executive Summary</h2>",
        "<p><strong>Business Question:</strong> For real estate agents or individuals looking to sell a house in Seattle, what are the most important home features to consider when predicting the sales price?</p>",
        "<p><strong>Key Finding:</strong> House age, lot size, and grade are the most influential predictors, with our Random Forest model achieving 70% variance explained.</p>",
        "</div>",
        
        "<h2>📈 Dataset Overview</h2>",
        "<div class='finding'>",
        "<div style='display: flex; justify-content: space-between; flex-wrap: wrap;'>",
        "<div class='metric'><strong>Properties:</strong> ", formatC(nrow(housing_data()), format = "f", big.mark = ",", digits = 0), "</div>",
        "<div class='metric'><strong>Avg Price:</strong> $", formatC(round(mean(housing_data()$price, na.rm = TRUE)), format = "f", big.mark = ",", digits = 0), "</div>",
        "<div class='metric'><strong>Median Price:</strong> $", formatC(round(median(housing_data()$price, na.rm = TRUE)), format = "f", big.mark = ",", digits = 0), "</div>",
        "<div class='metric'><strong>Price Range:</strong> $", formatC(round(max(housing_data()$price) - min(housing_data()$price)), format = "f", big.mark = ",", digits = 0), "</div>",
        "</div>",
        "<ul>",
        "<li><strong>Source:</strong> Kaggle Seattle House Sales Prices dataset</li>",
        "<li><strong>Preprocessing:</strong> Removed 1 outlier (33 bedrooms), created house_age variable</li>",
        "<li><strong>Features:</strong> Physical specs, location attributes, quality assessments</li>",
        "<li><strong>Geographic Coverage:</strong> Seattle metropolitan area</li>",
        "</ul>",
        "</div>",
        
        "<h2>🔍 Key Analytical Findings</h2>",
        "<div class='highlight'>",
        "<h3>🏆 Most Important Features (Random Forest Variable Importance):</h3>",
        "<ol>",
        "<li><strong>House Age</strong> (222.4% IncMSE) - Most influential predictor</li>",
        "<li><strong>Lot Size</strong> (152.6% IncMSE) - Total property size</li>",
        "<li><strong>Grade</strong> (96.8% IncMSE) - Quality appraisal score</li>",
        "<li><strong>Living Space</strong> (73.0% IncMSE) - Interior square footage</li>",
        "<li><strong>View Rating</strong> (64.2% IncMSE) - Scenic outlook quality</li>",
        "</ol>",
        "</div>",
        
        "<h2>📊 Model Performance Analysis</h2>",
        "<div class='finding'>",
        "<h3>🎯 Best Performing Models:</h3>",
        "<table>",
        "<tr><th>Model</th><th>MSE</th><th>RMSE</th><th>R-Squared</th><th>Purpose</th></tr>",
        "<tr style='background-color: #e8f5e8;'><td><strong>Random Forest (Full)</strong></td><td>0.0863</td><td>0.2938</td><td>70%</td><td>Best Prediction</td></tr>",
        "<tr><td>OLS Small</td><td>0.0971</td><td>0.3117</td><td>65%</td><td>Best Interpretation</td></tr>",
        "<tr><td>LASSO Small (Weighted)</td><td>0.0971</td><td>0.3116</td><td>65%</td><td>Regularized</td></tr>",
        "</table>",
        
        "<h3>💡 Model Selection Rationale:</h3>",
        "<ul>",
        "<li><strong>Random Forest:</strong> Superior predictive accuracy, handles non-linear relationships</li>",
        "<li><strong>OLS Model:</strong> Excellent interpretability for business insights</li>",
        "<li><strong>Cross-Validation:</strong> 10-fold CV ensures robust performance estimates</li>",
        "</ul>",
        "</div>",
        
        "<h2>💰 Quantitative Price Effects (OLS Model Insights)</h2>",
        "<div class='highlight'>",
        "<h3>📈 Positive Price Drivers:</h3>",
        "<ul>",
        "<li><strong>Bathrooms:</strong> +8.4% per additional bathroom</li>",
        "<li><strong>Living Space:</strong> +0.018% per square foot</li>",
        "<li><strong>Floors:</strong> +7.7% per additional floor</li>",
        "<li><strong>Waterfront:</strong> +31.5% premium for waterfront properties</li>",
        "<li><strong>House Age:</strong> +0.6% per year (surprisingly positive)</li>",
        "</ul>",
        
        "<h3>🏷️ Categorical Feature Premiums:</h3>",
        "<ul>",
        "<li><strong>View Ratings:</strong> 18% to 25.2% increase (Views 1-4 vs View 0)</li>",
        "<li><strong>Condition:</strong> 14.9% to 23.4% increase (Conditions 3-5 vs 1-2)</li>",
        "<li><strong>High Grades:</strong> 72% to 134% premium (Grades 8-13 vs lower grades)</li>",
        "<li><strong>Bedrooms:</strong> -3.3% per additional bedroom (counterintuitive finding)</li>",
        "</ul>",
        "</div>",
        
        "<h2>🗺️ Geographic Analysis Insights</h2>",
        "<div class='finding'>",
        "<h3>📍 High-Value Location Patterns:</h3>",
        "<ul>",
        "<li><strong>Waterfront Areas:</strong> Lake Washington, Puget Sound shorelines</li>",
        "<li><strong>Tech Corridors:</strong> Bellevue, Redmond (proximity to major employers)</li>",
        "<li><strong>Urban Core:</strong> Downtown Seattle, Capitol Hill</li>",
        "<li><strong>Premium Neighborhoods:</strong> Magnolia, Queen Anne, Ballard</li>",
        "</ul>",
        
        "<h3>🎯 Location-Based Investment Insights:</h3>",
        "<ul>",
        "<li>Waterfront proximity commands significant premiums</li>",
        "<li>Grade and view quality vary systematically by neighborhood</li>",
        "<li>Transportation access correlates with pricing patterns</li>",
        "<li>School district quality influences family-oriented areas</li>",
        "</ul>",
        "</div>",
        
        "<h2>💼 Business Recommendations</h2>",
        "<div class='highlight'>",
        "<h3>🎯 For Real Estate Professionals:</h3>",
        "<ul>",
        "<li><strong>Pricing Strategy:</strong> Focus on house age, lot size, and grade as primary factors</li>",
        "<li><strong>Marketing Emphasis:</strong> Highlight waterfront access and scenic views</li>",
        "<li><strong>Value Propositions:</strong> Bathroom count as key selling point (+8.4% per bath)</li>",
        "<li><strong>Quality Improvements:</strong> Grade and condition upgrades yield highest ROI</li>",
        "</ul>",
        
        "<h3>📊 Pricing Model Applications:</h3>",
        "<ul>",
        "<li><strong>Automated Valuation:</strong> Use Random Forest for accurate price predictions</li>",
        "<li><strong>Market Analysis:</strong> Apply OLS coefficients for feature impact assessment</li>",
        "<li><strong>Investment Decisions:</strong> Prioritize properties with improvement potential</li>",
        "<li><strong>Competitive Analysis:</strong> Benchmark against model predictions</li>",
        "</ul>",
        "</div>",
        
        "<h2>🔬 Technical Methodology</h2>",
        "<div class='finding'>",
        "<h3>📋 Data Preprocessing:</h3>",
        "<ul>",
        "<li>Outlier removal (33-bedroom property)</li>",
        "<li>Feature engineering (house_age, renovated status)</li>",
        "<li>Variable type conversions and data cleaning</li>",
        "<li>Missing value handling and validation</li>",
        "</ul>",
        
        "<h3>🤖 Modeling Approaches:</h3>",
        "<ul>",
        "<li><strong>OLS/WLS:</strong> Linear relationships and statistical inference</li>",
        "<li><strong>LASSO Regression:</strong> Feature selection and regularization</li>",
        "<li><strong>Random Forest:</strong> Non-linear patterns and variable importance</li>",
        "<li><strong>Cross-Validation:</strong> 10-fold CV for robust performance assessment</li>",
        "</ul>",
        
        "<h3>⚠️ Model Limitations:</h3>",
        "<ul>",
        "<li>Heteroscedasticity present in OLS models</li>",
        "<li>Historical data may not reflect current market conditions</li>",
        "<li>Geographic clustering effects not explicitly modeled</li>",
        "<li>Seasonal variations not captured in the analysis</li>",
        "</ul>",
        "</div>",
        
        "<h2>🎓 Academic & Professional Impact</h2>",
        "<div class='author-section'>",
        "<h3>👨‍🎓 About the Author</h3>",
        "<p><strong>Peter Chika Ozo-Ogueji</strong> is a Master's candidate in Data Science at American University, specializing in predictive analytics and machine learning applications. His research focuses on healthcare analytics, fraud detection, and real estate market analysis.</p>",
        
        "<h4>🏆 Key Achievements:</h4>",
        "<ul>",
        "<li>Graduate Teaching Assistant for Statistical Machine Learning</li>",
        "<li>Data Science Intern at METY Technology (15% cost reduction)</li>",
        "<li>COVID-19 Misinformation Detection Research (96.75% accuracy)</li>",
        "<li>Banking Analytics - 30% fraud reduction implementation</li>",
        "</ul>",
        
        "<h4>📧 Contact Information:</h4>",
        "<p>Email: po3783a@american.edu | LinkedIn: linkedin.com/in/peterchika | GitHub: github.com/PeterOzo</p>",
        "</div>",
        
        "<h2>📝 Conclusions & Future Work</h2>",
        "<div class='summary'>",
        "<p><strong>Primary Conclusion:</strong> This analysis successfully identified house age, lot size, and grade as the most important features for Seattle housing price prediction. The Random Forest model provides excellent predictive accuracy (70% variance explained), while the OLS model offers valuable insights into specific feature effects.</p>",
        
        "<h4>🔮 Future Research Directions:</h4>",
        "<ul>",
        "<li>Incorporate neighborhood-specific economic indicators</li>",
        "<li>Add temporal analysis for market trend prediction</li>",
        "<li>Include external factors (school ratings, crime statistics)</li>",
        "<li>Develop real-time pricing models with market updates</li>",
        "</ul>",
        
        "<p><em>This analysis demonstrates the power of combining multiple modeling approaches to achieve both predictive accuracy and business interpretability in real estate analytics.</em></p>",
        "</div>",
        
        "<hr style='margin: 40px 0; border: 2px solid #3c8dbc;'>",
        "<p style='text-align: center; color: #666;'><em>Report generated by AnalyticsPro Dashboard - ITEC 621 Predictive Analytics Project<br>American University Kogod School of Business - ", Sys.Date(), "</em></p>",
        "</body></html>"
      )
      
      writeLines(report_html, file)
    }
  )
}

# Run the application
shinyApp(ui = ui, server = server)
