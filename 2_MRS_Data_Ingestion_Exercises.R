

# Help and Solutions
# If you get stuck at any point, you can use the help() function to look up
# the official documentation:
help(rxImport)

# All of these exercises have solutions in an accompanying file, as well:
# 2_MRS_Data_Ingestion_Solutions.R







################################################################################
# Microsoft R Server: Sample datasets
################################################################################

# All of the exercises in this course depend on the sample data directories
# that are installed with every copy of Microsoft R Server.
# You can print the filepath to these datasets using rxGetOption():
rxGetOption("sampleDataDir")


# And you can list the sample datasets using list.files()
list.files(rxGetOption("sampleDataDir"))


# Fill in the blank with the filepath to the sample data directory below to create 
# a filepath to the dataset "mortDefault2000.csv"
csvFile <- file.path(________________, "mortDefaultSmall2000.csv")



# Check that your filepath works with file.exists()
file.exists(csvFile)





################################################################################
# Exercise 1: Import a CSV File
################################################################################

# Now that you have a filepath to a CSV file, import it.
# In open-source R, you'd do something like this:
# exampleData <- read.csv(csvFile)
# which creates an object called exampleData in your R workspace (that is, in
# your computer's physical memory).

# But to take full advantage of Microsoft R Server's big-data capabilities,
# you'll want to use an XDF file. Unlike exampleData, an XDF file won't exist in
# your computer's physical memory, but on your hard drive.
# First, let's create a filepath for that XDF file.
xdfFile <- "mortDefault2000.xdf"

# Now we have a filepath - but that file doesn't exist yet:
file.exists(xdfFile)


# To create the XDF file, use rxImport to read data from your CSV into a new
# XDF file. Fill in the blanks here:
rxImport(inData = ________,
         outFile = _______)



# If you need help, try the help() function
help(rxImport)


# Now, check that the XDF was created:
file.exists(xdfFile)


# And check that the results look good. rxGetInfo gives you a quick overview of
# any XDF file. This should tell you that there are 10,000 observations of
# 6 variables:
rxGetInfo(xdfFile)









################################################################################
# Exercise 2: Import Selected Variables
################################################################################

# You can specify many options when importing data with rxImport. One 
# commonly-used option is to select only a few variables to keep from the whole
# dataset.

# In MRS, you can do this in two ways:
# - use varsToKeep to name the variables you want to import, or
# - use varsToDrop to name variables that you don't want to import.

# Use either varsToKeep or varsToDrop to create a subset of the CSV data above
# that contains only the variables "creditScore", "houseAge", and "default".

# Hint: When you pass variable names, create a character vector, like this one:
# c("example", "character", "vector")

xdfSubset <- "xdfSubset.xdf"

rxImport(inData = csvFile, 
         outFile = xdfSubset,
         ________ = ____________
)


# Now, use rxGetInfo to check the results. By adding the "numRows = 10" argument,
# rxGetInfo will show us the first ten rows of the dataset along with its
# metadata.
rxGetInfo(xdfSubset, numRows = 10)












################################################################################
# Exercise 3: Append a New Dataset
################################################################################

# So - we've imported one year's worth of mortgage data:
rxGetInfo(xdfFile, numRows = 10)

# Here's the data from 2001:
csv2001 <- file.path(rxGetOption("sampleDataDir"), "mortDefaultSmall2001.csv")

# Use rxImport to append csv2001 to the existing XDF file (xdfFile):
rxImport(____________,
         ____________,
         ____________
)



# Check your results using rxGetInfo. There should now be 20,000 rows,
# and the "year" variable should have a low value of 2000 and a high of 2001:
rxGetInfo(xdfFile, getVarInfo = TRUE)








################################################################################
# Exercise 4: Combine Several CSVs into One XDF
################################################################################

# Now let's combine several CSV files into one XDF at once.
# Here are the filepaths of all of the mortgauge default CSV files:
csvList <- list.files(rxGetOption("sampleDataDir"),
                      pattern = "mortDefaultSmall.*.csv",
                      full.names = TRUE)

# Print to review
csvList


# Use this path for the new XDF file:
xdfAll <- "mortDefaultAll.xdf"


# Now we want to run rxImport() once for each CSV file in csvList. In R, one
# way to do this is to use lapply(). For example, here's how to use lapply() to
# check if each of those files exists:
lapply(csvList, FUN = file.exists)

# It printed TRUE for each of the ten files. We can use similar logic to append
# new data to an XDF file. Here's the framework - fill in the blanks to make it
# work:

lapply(_______, FUN = function(oneCsv) {
    
    rxImport(inData = oneCsv,
             outFile = _________,
             append = _________)
})


# rxGetInfo should now show 100,000 observations (1e+05 in R's scientific notation),
# and the maximum value of "year" should be 2009:
rxGetInfo(xdfAll, getVarInfo = TRUE)


# Troubleshooting tips:

# - append needs to be set to FALSE for the first CSV file, so rxImport knows to
#   create a new XDF file, but set to TRUE for the 2nd-10th CSV files, so rxImport knows
#   to add to an existing XDF file. See the first lapply() example for a hint.

# - If something goes wrong and you need to delete xdfAll, use file.remove(xdfAll)









################################################################################
# Exercise 5: Import a Subset
################################################################################

# Now imagine that you only wanted to pull in the records where a customer had
# defaulted on their loan (that is, where default == 1). In rxImport, you can use
# the rowSelection argument to set one or more criteria. Any comparison that
# produces TRUE or FALSE, like default == 1, can be used to subset, and several
# criteria can be chained together using R's logical operators 
# (for example, default == 1 & houseAge > 10)

# Create a new subset in this XDF file, including only records where default == 1
xdfDefaults <- "defaultsOnly.xdf"

# Use rxImport again:
rxImport(inData = csvFile,
         outFile = xdfDefaults,
         __________ = (_____________)
)



# Use rxGetInfo to check the results. There should be just 10,000 records again,
# and the high and low values of "default" should be (1, 1)
rxGetInfo(xdfDefaults, getVarInfo = TRUE)




################################################################################
# Exercise 6: Specify Variable Types
################################################################################


# When you import data, rxImport() does its best to guess how each variable should
# be stored - numeric, character, factor, date, etc. If you need to specify a 
# different type for a variable, you can use the colClasses argument.

# colClasses lets you specify a type for each variable with a named vector. The
# name of the variable to change is on the left, and the desired type is on the 
# right. That would look something like this:
# colClasses = c(name = "character", age = "numeric", country = "factor") 

# For this exercise, let's look at a new dataset of flights. It has three variables:
# - ArrDelay, a measure of how late a flight arrived (in minutes)
# - CRSDepTime, the flight's departure time on the 24-hour clock as a numeric variable
#   (0 is midnight, 6.0 is 6 in the morning, 18.5 is 6 in the evening, etc)
# - DayOfWeek, the day on which the plane departed


# Here's the CSV path
airlineCsv <- file.path(rxGetOption("sampleDataDir"), "AirlineDemoSmall.csv")

# Let's make a new XDF
airlineXdf <- "airline.Xdf"

rxImport(inData = airlineCsv, 
         outFile = airlineXdf)


# Now that we've imported the XDF, let's see how the variables were imported:
rxGetInfo(airlineXdf, getVarInfo = TRUE, numRows = 10)

# CRSDepTime looks like it was correctly imported as a numeric variable.
# ArrDelay has been imported as a character vector, which is definitely wrong.
# DayOfWeek is a character - but to use it in many statistical algorithms, we
# need it to be a factor.

# One more thing: missing values in this dataset are denoted with an "M", so I'm
# setting missingValueString = "M" so they'll be properly converted into NA.

# Use rxImport to import airlineCsv into airlineXdf, and set the colClasses
# argument so that arrDelay is an integer and DayOfWeek is a factor
rxImport(inData = airlineCsv,
         outFile = airlineXdf,
         colClasses = _________________,
         missingValueString = "M",
         overwrite = TRUE
)


# Check the results with rxGetVarInfo
rxGetVarInfo(airlineXdf)





################################################################################
# Exercise 7: Advanced Variable Controls
################################################################################


# Sometimes you need even more control over how a variable is imported. The
# colInfo argument lets you specify types, just like colClasses, but it also
# lets you rename variables, set the levels in a factor, and more.

# colInfo is the most complex argument we've seen so far, so read the description
# and review the example below carefully.
# colInfo takes a list. 
# Each item in that list is a variable in the original dataset (CRSDepTime and DayOfWeek)
# Each variable gets *another* list.
# Each item in the *variable's* list is an argument that modifies the imported variable:
# - type lets you specify the variable type, just like colClasses;
# - newName will change the variable's name to whatever text you provide;
# - levels lets you provide a list of levels that a factor should have.

# Reading in the airline data with colClasses helped, but we could do more. This
# time, use colClasses and colInfo together to:
# 1. Convert the types of the variables (as in Exercise 6)
# 2. Change the name of CRSDepTime to DepartureTime (with the newName argument)
# 3. Re-arrange the levels of DayOfWeek so Sunday is first (with the levels argument)

rxImport(inData = airlineCsv,
         outFile = airlineXdf,
         colClasses = c(__________),
         colInfo = list(
             CRSDepTime = list(newName = __________),
             DayOfWeek = list(type = __________,
                              levels = c("Sunday", "Monday", "Tuesday",
                                         "Wednesday", "Thursday",
                                         "Friday", "Saturday"
         ))),
         overwrite = TRUE)


# Check the results. ArrDelay should be numeric or integer, CRSDepTime renamed to
# DepTime24, and DayOfWeek should be a factor with Sunday as its first level.
rxGetVarInfo(airlineXdf)






################################################################################
# Exercise 8: Import Using ODBC
################################################################################

# rxImport can pull data from databases over an ODBC connection, as well, but
# it takes some additional setup. 

# Here's a SQLite database that's included with MRS:
claimsDB <- file.path(rxGetOption("sampleDataDir"), "claims.sqlite")

# Each database has a specific "connection string" that tells MRS where the
# database is, and how to connect to it. The string varies from database to database,
# but can usually be found in the database's documentation.
# For SQLite, I just specify that I'm connecting with ODBC, and give it the
# location of the database file (claimsDB)
claimsString <- paste0("Driver={SQLite3 ODBC Driver};Database=", claimsDB)


# Next, we'll create a data source using the function RxOdbcData.
# This is the actual connection to the database file. It needs two arguments:
# - sqlQuery, the SQL query we want this data source to use, and
# - connectionString - which takes the database connection string we just created:
claimsSource <- RxOdbcData(sqlQuery = "SELECT * FROM claims",
                           _________ = _________)



# Let's set up a new XDF file
claimsXdf <- "claims.xdf"


# And import the data
rxImport(inData = __________,
         outFile = __________)



# Check the results!
rxGetInfo(claimsXdf, getVarInfo = TRUE)








# Remember to check the help file for rxImport:
help(rxImport)
# and the solutions file, 2_MRS_Data_Ingestion_Solutions.R, if you get stuck at
# any point.

















