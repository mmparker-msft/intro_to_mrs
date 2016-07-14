

# Help and Solutions
# If you get stuck at any point, you can use the help() function to look up
# the official documentation:
help(rxImport)

# All of these exercises have solutions in an accompanying file, as well:
# 4_MRS_Modeling_Solutions.R






################################################################################
# Sample Dataset: Airlines Data
################################################################################

# In this module, we'll use the dataset of all the flights originating in the
# three major airports of New York City in 2013 (from the R package 
# 'nycflights13' - thanks to its authors for making it available).


# Here's some basic setup:
# CSV pointer
flightsCsv <- "flights.csv"

# XDF pointer
flightsXdf <- "flights.xdf"

# Import to XDF
rxImport(inData = flightsCsv,
         outFile = flightsXdf)



# Add a day-of-week variable
rxDataStep(inData = flightsXdf, 
           outFile = flightsXdf, 
           overwrite = TRUE,
           transforms = list(
               dayOfWeek = format(as.Date(paste(year, month, day, 
                                                sep = "-")), format = "%A")
           )
)

# Convert dayOfWeek, origin, and dest to factor
rxFactors(inData = flightsXdf,
          outFile = flightsXdf,
          overwrite = TRUE,
          factorInfo = list(
              dayOfWeek_F = list(varName = "dayOfWeek",
                                 levels = c("Sunday", "Monday", "Tuesday", 
                                            "Wednesday", "Thursday", "Friday",
                                            "Saturday")),
                            origin_F = list(varName = "origin"), 
                            dest_F = list(varName = "dest"),
                            carrier_F = list(varName = "carrier")
          )
)


# Check the results
rxGetInfo(flightsXdf, getVarInfo = TRUE, numRows = 5)






################################################################################
# Metadata Retrieval
################################################################################


# When an XDF file is created or modified, some essential pieces of metadata are
# computed and stored for later retrieval. That makes it easy and very fast to
# get an overview of the data without reading the whole XDF.
# The essential function for retrieving that metadata is rxGetInfo()
# By itself, it just returns the very basic details of the file:
rxGetInfo(flightsXdf)


# But setting two options provides even more output:
# - getVarInfo = TRUE provides an overview of the variables on the dataset, and
# - numRows = 5 (or some other number) returns the first 5 rows of the dataset.

rxGetInfo(flightsXdf, getVarInfo = TRUE, numRows = 5)






################################################################################
# Summary Statistics
################################################################################

# MRS includes a handful of essential functions for calculating summary
# statistics: 
# - rxSummary() for the classic mean, standard deviation, minimum, maximum, etc.
# - rxQuantile() for quantiles (including the median)
# - rxCrossTabs() and rxCube() for frequency tables

# rxSummary() depends on R's formula syntax. There are three key patterns you'll
# use often:
# Summarize a single variable:               ~ arr_delay
# Summarize two or more variables:           ~ arr_delay + dep_delay
# Groupwise summary:               arr_delay ~ dayOfWeek_F

# In short: put variables to summarize on the right-hand side, separated by +
# signs. To do groupwise summary, put the variable to summarize on the LEFT-hand
# side, and the grouping factors on the right.


#################################
# Exercise 1
#################################

# Summarize *departure delay* (dep_delay) for each of the three origin airports:
# Remember: grouping variables must be factors.





################################################################################
# Quantiles
################################################################################

# rxQuantile() calculates quantiles on the dataset, but just for one variable at
# a time. It returns the 0, 25, 50 (median), 75, and 100 quantiles by default:
rxQuantile(varName = "arr_delay", data = flightsXdf)



# But you can use the probs argument to get other quantiles For example:
# probs = c(0.10, 0.90) would return the 10th and 90th quantiles.


#################################
# Exercise 2
#################################

# Use rxQuantile() to compute the 95% interval of arr_delay - that is, the
# 2.5th and 97.5th quantiles:










################################################################################
# Categorical Variables
################################################################################

# MRS includes two functions for creating frequency tables: rxCrossTabs() and
# rxCube(). Their syntax and results are identical, but they provide two 
# different output formats, as we'll see.
# The input variables for both of these functions MUST be factors.
# Both rxCrossTabs() and rxCube() use R's formula syntax, similar to rxSummary():

rxCrossTabs( ~ origin_F, data = flightsXdf)

rxCube( ~ origin_F, data = flightsXdf)





# But with one small difference: variables on the right-hand side are separated
# by a colon (:) instead of a plus (+)
rxCrossTabs( ~ dest_F : origin_F, data = flightsXdf)

rxCube( ~ dest_F : origin_F, data = flightsXdf)



#################################
# Exercise 3
#################################

# The examples above use origin_F and dest_F.
# Use rxGetInfo() to identify another factor on the dataset:




# And use it to create three-factor tables with both rxCrossTabs() and rxCube(),
# and compare the results:










################################################################################
# Modeling Arrival Delay
################################################################################

# Now that we've seen how to do some exploratory analysis, it's time to build
# a model! We'll be using the formula syntax once again: the variable we want to
# predict (the dependent variable) goes on the left-hand side, and the predictors
# (independent variables) go on the right. Here, I'll try to predict arrival
# delay as a function of departure time and origin airport:
mod1 <- rxLinMod(arr_delay ~ dep_time + origin_F, data = flightsXdf)


# Notice that we're assigning the results a name in R's workspace (mod1). The
# model results are very small and will usually fit into memory with no trouble,
# so they don't get written to an XDF.
# Once we've created the model, we can view its results with the summary()
# function from open-source R:
summary(mod1)



# We can also use the model to make new predictions. Let's say I want to know
# which airport is most likely to have delays at 7pm. I can make a new data.frame
# with one row for each airport and the dep_time set to 7pm:
sevenpm <- data.frame(origin_F = factor(c("EWR", "LGA", "JFK"),
                                        levels = c("EWR", "LGA", "JFK")),
                      dep_time = 1900)

# And pass that to rxPredict(). I'll also set writeModelVars = TRUE, so I get
# both the predictors and the predicted value:
rxPredict(modelObject = mod1,
          data = sevenpm,
          writeModelVars = TRUE)

# EWR has a predicted delay of 21 minutes, whereas JFK's predicted delay is just
# 16 minutes.



#################################
# Exercise 4
#################################

# Use rxGetInfo() to review the available variables and build a more complex
# model for predicting arrival delay, then use summary() to evaluate the results.








# Now use rxPredict() to add the predicted values back to flightsXdf.
# To add predictions back to an XDF file, just set outData = flightsXdf
rxPredict(modelObject = mod2,
          data = flightsXdf,
          outData = flightsXdf)



# View the predicted values
rxDataStep(flightsXdf, numRows = 10)


# Compare with the actual arr_delay values - just the first hundred
rxDataStep(flightsXdf, 
           varsToKeep = c("arr_delay", "arr_delay_Pred"),
           numRows = 100
)










