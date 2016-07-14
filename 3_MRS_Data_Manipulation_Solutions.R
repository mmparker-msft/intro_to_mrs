

# Help and Solutions
# If you get stuck at any point, you can use the help() function to look up
# the official documentation:
help(rxImport)

# All of these exercises have solutions in an accompanying file, as well:
# 3_MRS_Data_Manipulation_Solutions.R







################################################################################
# Sample Dataset: Airlines Data
################################################################################

# In this module, we'll use a dataset of all the flights originating in the
# three major airports of New York City in 2013 (from the R package 
# 'nycflights13' - thanks to its authors for making it available).





#################################
# Exercise 1
#################################




# Just to make sure you've got rxImport() down, let's load the flights data
# from this CSV file into an XDF:
flightsCsv <- "flights.csv"

# Put it in an XDF file called:
flightsXdf <- "flights.xdf"


rxImport(inData = flightsCsv,
         outFile = flightsXdf)




# Check the results
rxGetInfo(flightsXdf, getVarInfo = TRUE)





################################################################################
# Sorting
################################################################################

# rxSort has three essential arguments, as well as a few others that give it some
# flexiblity. The essential three are inData and outFile (hopefully familiar by
# now), and the argument sortByVars, which takes a vector of the variables to
# use to sort the datasets. That looks something like this:
# sortByVars = c("default", "creditScore")



#################################
# Exercise 2
#################################


# To start with, use rxSort to sort flightsXdf by arrival delay (arr_delay)

# Here's a path to a new XDF file to write to:
flightsSorted <- "flights_sorted.xdf"


# Write your rxSort here:
rxSort(inData = flightsXdf,
       outFile = flightsSorted,
       sortByVars = "arr_delay")




# Check the results: what values of arr_delay are at the top now?
rxDataStep(flightsSorted, numRows = 10)




#################################
# Exercise 3
#################################


# Maybe it would be more useful to sort by *decreasing* arr_delay.
# In rxSort, you can do that by setting decreasing = TRUE
# Try that here:
rxSort(inData = flightsXdf,
       outFile = flightsSorted,
       sortByVars = "arr_delay",
       decreasing = TRUE,
       overwrite = TRUE)



# Check the results - should be a little more interesting!
rxDataStep(flightsSorted, numRows = 10)




#################################
# Exercise 4
#################################

# rxSort is also the function for removing duplicate records from a dataset.
# When you set removeDupKeys = TRUE, rxSort will sort the dataset, but keep only
# the first record for each unique combination of the sortByVars you specify.

# Use rxSort to create a dataset with one record for each unique carrier in
# flightsXdf.
# (There are better ways to do this in practice, but try it to be sure you
# understand how to apply the function)
uniqueCarriers <- "uniqueCarriers.xdf"

rxSort(inData = flightsXdf,
       outFile = uniqueCarriers,
       sortByVars = "carrier",
       removeDupKeys = TRUE,
       overwrite = TRUE)



# Check the results - there should be 16 rows, each with a different carrier:
rxDataStep(uniqueCarriers)







################################################################################
# Merging
################################################################################


# Now have a set of all of the unique carriers in the data - but the variable is
# just two-letter codes. Which codes correspond to which airlines?



#################################
# Exercise 5
#################################

# Use rxMerge to merge the airlines data ("airlines.xdf") onto the 
# de-duplicated dataset you created in the previous exercise (uniqueCarriers).

# rxMerge has a few key arguments:
# - inData1 and inData2: the two datasets to merge
# - outFile: an XDF file to write to
# - type: the type of join you want (try these: "left", "inner", "outer")
# - matchVars: the name of the variable(s) that links the two tables

# Here's the airlines XDF:
airlinesXdf <- "airlines.xdf"

# And a file for the results:
carrier_decoded <- "carrier_decoded.xdf"


# Write your rxMerge here:
rxMerge(inData1 = uniqueCarriers,
        inData2 = airlinesXdf,
        outFile = carrier_decoded,
        overwrite = TRUE,
        
        # Type of join
        type = "left",
        
        # Name the key variable(s)
        matchVars = "carrier"
)



# Check the results
rxDataStep(carrier_decoded)


# Looking just at the carrier variables:
rxDataStep(carrier_decoded, varsToKeep = c("carrier", "name"))










################################################################################
# Creating and Modifying Variables
################################################################################

# The main function for creating and modifying variables in MRS is rxDataStep().
# The transforms argument takes a list() of *named elements*, which would look
# something like this:
# transforms = list( newVar = x / y, anotherVar = x^3)
# Each element in the list() is a new variable we want to create, or an
# existing variable we want to modify. The *name* of the element (newVar and
# anotherVar) goes on the left-hand side of the = sign. The code to compute the
# variable is an R expression that goes on the right-hand side. Just about any
# R expression will work, but see below for some exceptions.


# For example, imagine I want to create a variable that tells me the day of week
# for all of the departures (Monday, Tuesday, etc).
# First, I need to create a proper Date variable from the year, month, and day
# variables. And then I need to print the day of the week for each of those.
# That would look like this:
rxDataStep(inData = flightsXdf,
           outFile = flightsXdf,
           overwrite = TRUE,
           
           # My list of transforms
           transforms = list( 

               # First, create the date by combining year, month, and day
               flightDate = as.Date(paste(year, month, day, sep = "-")),
               
               # Then format to day of week
               dayOfWeek = format(flightDate, "%A")

           )
)


# Check the results
rxDataStep(flightsXdf, numRows = 5)




#################################
# Exercise 6
#################################


# Use rxDataStep to calculate the airspeed (in miles per hour) of each flight,
# using the distance and air_time variables from flightsXdf. 
# Take note: air_time is in minutes!

rxDataStep(inData = flightsXdf,
           outFile = flightsXdf,
           overwrite = TRUE,
           transforms = list( speed = distance / (air_time / 60) )
)


# Check the results. Your minimum speed should be 76.8, and max 703.4
rxGetInfo(flightsXdf, getVarInfo = TRUE, numRows = 5)




################################################################################
# Complex Transformations Example
################################################################################

# I've included the complex transformations example from the video here - 
# there's no exercise, but I think you'll find it useful to walk through the
# example again to see what's happening.




################################################################################
# Complex transforms setup
################################################################################

# Setting up a toy XDF with 9 rows, split into three chunks:
chunks_df <- data.frame(date = seq(Sys.Date(), length.out = 9, by = "1 day"),
                        chunk = (1:9 + 2) %/% 3,
                        x = sample(21:29, size = 9),
                        stringsAsFactors = FALSE
)

# The data frame
chunks_df


# Creating an XDF
chunks <- "chunks.xdf"

# Importing and appending, three rows at a time
for(i in 1:3) {
    rxImport(inData = chunks_df[chunks_df$chunk %in% i, ],
             outFile = chunks,
             append = file.exists(chunks))
}

# Check the results
rxGetInfo(chunks, getVarInfo = TRUE, numRows = 9)



# Imagine you wanted to scale the variable x so that its lowest value mapped to
# zero, its highest value mapped to one. In R, you could do that with the code
# (x - min(x)) / (max(x) - min(x))
# Let's see what happens when you use that inside rxDataStep:
rxDataStep(inData = chunks,
           outFile = chunks,
           overwrite = TRUE,
           transforms = list(
               xScaledNaive = (x - min(x)) / (max(x) - min(x)) 
           )
)


# Check the results
rxDataStep(chunks)

# Clearly, that isn't right. If you look closely, you can see that rxDataStep
# is scaling x using its minimum and maximum values *on each chunk*. But it
# should be using the *overall* min and max of x.


# Fortunately, it's easy to get those values from other ScaleR functions. For
# min and max, we can extract the overall values from the XDF metadata using
# rxGetVarInfo(). You can calculate means, medians, standard deviations and like
# using the function rxSummary(), which you'll learn about in the next module.
xMin <- rxGetVarInfo(chunks)$x$low
xMax <- rxGetVarInfo(chunks)$x$high

# Check the results
xMin
xMax



# Now we can use xMin and xMax to scale x the right way. We pass those values
# to rxDataStep using the transformObjects function, and then use them in our
# transforms in place of min(x) and max(x).
rxDataStep(inData = chunks,
           outFile = chunks,
           overwrite = TRUE,
           
           # transformObjects takes a list of *named elements*. xMin and xMax
           # are the objects we want to pass, but rxDataStep requires them to
           # have a new name. So I'll call them varMin and varMax instead.
           # Annoying, but it helps prevent errors in the long run.
           transformObjects = list(varMin = xMin, varMax = xMax),
           
           # Now I can use varMin and varMax (NOT xMin and xMax!) in my
           # transforms:
           transforms = list( 
               xScaledCorrect = (x - varMin) / (varMax - varMin)  
           )
)


# Check the results
rxDataStep(chunks)




















################################################################################
# Factors
################################################################################

# In a way, factors are also "complex" - if we just use R's factor() function
# to create them inside rxDataStep(), they could have different (and 
# incompatible) levels on different chunks. So to create factors in Microsoft R,
# we'll usually use the function rxFactors().

# The key argument in rxFactors() is factorInfo, which is a bit like rxDataStep's
# transforms argument. Just like transforms, factorInfo takes a list of named
# elements, and each of those elements corresponds to a new variable you'd like
# to create.

# But instead of taking R expressions, each element in factorInfo takes 
# *another* list. Each element in *that* list gives rxFactor some information
# about how to create/modify the factor in question. At the simplest, you can
# just specify a variable to convert to a factor with the argument varName.
# Here, I'll convert the 'name' variable in airlinesXdf to a factor:
rxFactors(inData = airlinesXdf,
          outFile = airlinesXdf,
          overwrite = TRUE,
          
          factorInfo = list( 
              name_Factor = list(varName = "name") 
          )

)

# Check the results
rxGetVarInfo(airlinesXdf)




# You can also specify the exact levels you want for the factor with the
# levels argument, which is used in conjunction with varName like this:
rxFactors(inData = flightsXdf,
          outFile = flightsXdf,
          overwrite = TRUE,
          
          factorInfo = list( 
              origin_Factor = list(varName = "origin",
                                   levels = c("EWR", "LGA", "JFK")
              )
          )
          
)


# Check the results
rxGetVarInfo(flightsXdf)



#################################
# Exercise 7
#################################



# Use rxFactors to convert the dayOfWeek variable into a factor.
# Use the newLevels argument to specify the order of the days in an order you
# prefer (Sunday first, Monday first, etc.)


rxFactors(inData = flightsXdf,
          outFile = flightsXdf,
          overwrite = TRUE,
          factorInfo = list( dayOfWeek_Factor = list(
                                 newVar = "dayOfWeek",
                                 levels = c("Sunday", "Monday", "Tuesday",
                                            "Wednesday", "Thursday", "Friday",
                                            "Saturday")
                             )
          )
)



# Check the results
rxGetVarInfo(flightsXdf)



