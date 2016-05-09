###############################################################################
# R_EDA_Sandbox.R
# Last updated: 2016-05-08 by MJG
###############################################################################

# A compilation of useful functions to [ideally] deploy on any data set
# Deploy after prepping data (e.g. converting variables, removing NAs, etc.)
# Requires a list of variable names to execute on, don't forget to update list!

# Suggested order of deployment:
#   Convert variables as necessary (e.g. to factors)
#   Plots for EDA on numeric and factor variables
#   Missing flags
#   Missing imputes
#   Trims
#   Transforms

# TODO:
# Adapt code equivalent to PROC MI in SAS to data set *or* create impute code 
#   based on mean, median, mode of the variable

# **See 'Bonus: Demo' at end of code**

#==============================================================================
# Staging & Prep
#==============================================================================

# These commands must be adapted to the data set, they **cannot** be run blind!

# Store data set name for use in titles, etc. later
data.name <- "df$"

# Set response variable
data.response <- "var"

# Assign rownames
df.rn <- as.numeric(rownames(df))

# Assign full column names
df.cn.all <- colnames(df)

# Assign numeric column names
df.cn.num <- colnames(df[, !sapply(df, is.factor)])

# Assign factor column names
df.cn.fac <- colnames(df[, sapply(df, is.factor)])

# Assign column names *except* for missing flag variables
# This is necessary due to order of deployment
df.cn.all <- grep("^[MF_]", colnames(df), value = T, invert = T)

#==============================================================================
# Missing Observations
#==============================================================================

#--------------------------------------
# m.flag()
#--------------------------------------
# Function to create indicator variables as missing flags
m.flag <- function(data, list){
    for (var in list){
        if (sum(is.na(data[, var])) > 0){
            data[paste("MF", var, sep = "_")] <- 
                ifelse(is.na(data[, var]), 1, 0)
        }
    }
    return(data)
}

#==============================================================================
# Numeric Variables
#==============================================================================

#------------------------------------------------------------------------------
# Plots
#------------------------------------------------------------------------------

#--------------------------------------
# num.boxplot()
#--------------------------------------
# Function to create boxplots of numeric variables
num.boxplot <- function(data, list, vs = F){
    temp <- eval(parse(text = paste("data", "$", data.response, sep = "")))
    for (var in list){
        if (vs){
            boxplot(data[, var] ~ temp, col = "grey",
                    main = paste(data.name, var," versus ",
                                 data.name, data.response, sep = ""))
        }
        if (!vs){
            boxplot(data[, var], col = "grey",
                    main = paste("Boxplot of ", data.name, var, sep = ""))
        }
    }
}

#--------------------------------------
# num.hist()
#--------------------------------------
# Function to create histograms of numeric variables
# Optional choice of normal curve overlay
num.hist <- function(data, list, norm = F){
    for (var in list){
        main <- paste("Histogram of ", data.name, var, sep = "")
        sub <- ifelse(norm, "normal curve overlay (blue)", "")
        y <- hist(data[, var], plot = F)
        h <- hist(data[, var], col = "grey", main = main, sub = sub,
                  ylim = c(0, 1.1*max(y$counts)),
                  xlab = paste(data.name, var, sep = ""))
        if (norm){
            xfit <- seq(min(data[, var]), max(data[, var]), length = 100)
            yfit <- dnorm(xfit, mean = mean(data[, var]), sd = sd(data[, var]))
            yfit <- yfit * diff(h$mids[1:2]) * length(data[, var])
            lines(xfit, yfit, col = "blue", lwd = 2)
        }
    }
}

#--------------------------------------
# num.qq()
#--------------------------------------
# Function to create Q-Q plots of numeric variables
num.qq <- function(data, list){
    for (var in list){
        qqnorm(data[, var], pch = 21, bg = "grey",
               main = paste("Normal Q-Q Plot of ", data.name, var, sep = ""))
        qqline(data[, var], lwd = 2, col = "blue")
    }
}

#--------------------------------------
# num.scatter()
#--------------------------------------
# Function to create scatterplots of numeric variables
num.scatter <- function(data, list){
    temp <- eval(parse(text = paste("data", "$", data.response, sep = "")))
    for (var in list){
        plot(data[, var], temp, pch = 21, bg = "grey",
             main = paste(data.name, data.response," versus ", 
                          data.name, var, sep = ""),
             ylab = paste(data.name, data.response, sep = ""),
             xlab = paste(data.name, var, sep = ""))
    }
}

#--------------------------------------
# num.plots()
#--------------------------------------
# Function to produce four plots per variable:
#   Scatterplot, Q-Q Plot, Histogram, Boxplot
num.plots <- function(data, list, norm = F, vs = F){
    par(mfcol = c(2, 2))
    for (var in list){
        num.hist(data, var, norm)
        num.scatter(data, var)
        num.boxplot(data, var, vs)
        num.qq(data, var)
    }
    par(mfcol = c(1, 1))
}

#------------------------------------------------------------------------------
# Variable Manipulation
#------------------------------------------------------------------------------

#--------------------------------------
# num.trims()
#--------------------------------------
# Function to trim numeric variables at various percentiles
num.trims <- function(data, list){
    require(scales)
    for (var in list){
        # 1st and 99th
        T99 <- quantile(data[, var], c(0.01, 0.99))
        data[paste(var, "T99", sep = "_")] <- squish(data[, var], T99)
        
        # 5th and 95th
        T95 <- quantile(data[, var], c(0.05, 0.95))
        data[paste(var, "T95", sep = "_")] <- squish(data[, var], T95)
        
        # 10th and 90th
        T90 <- quantile(data[, var], c(0.10, 0.90))
        data[paste(var, "T90", sep = "_")] <- squish(data[, var], T90)
        
        # 25th and 75th
        T75 <- quantile(data[, var], c(0.25, 0.75))
        data[paste(var, "T75", sep = "_")] <- squish(data[, var], T75)
    }
    return(data)
}

#--------------------------------------
# num.trans()
#--------------------------------------
# Function to transform numeric variables
num.trans <- function(data, list){
    for (var in list){
        # Natural Log
        var_ln <- paste(var, "ln", sep = "_")
        data[var_ln] <- (sign(data[, var]) * log(abs(data[, var])+1))
        
        # Square Root
        var_rt <- paste(var, "rt", sep = "_")
        data[var_rt] <- (sign(data[, var]) * sqrt(abs(data[, var])+1))
        
        # Square
        var_sq <- paste(var, "sq", sep = "_")
        data[var_sq] <- (data[, var] * data[, var])
    }
    return(data)
}

#==============================================================================
# Factor Variables
#==============================================================================

#------------------------------------------------------------------------------
# Plots
#------------------------------------------------------------------------------

#--------------------------------------
# fac.barplot()
#--------------------------------------
# Function to create barplots of factor variables
fac.barplot <- function(data, list, cat = F){
    for (var in list){
        temp <- eval(parse(text = paste("data", "$", data.response, sep = "")))
        if (cat){
            barplot(table(temp, data[, var]),
                          main = paste("Variable: ", data.name, var, sep = ""),
                          ylim = c(0, 1.1*max(summary(data[, var]))),
                          ylab = "Frequency", beside = T)
        }
        if (!cat){
            plot(data[, var],
                 main = paste("Variable: ", data.name, var, sep = ""),
                 ylim = c(0, 1.1*max(summary(data[, var]))),
                 ylab = "Frequency")
        }
    }
}

#--------------------------------------
# fac.boxplot()
#--------------------------------------
# Function to create boxplots of categorical variables
fac.boxplot <- function(data, list){
    temp <- eval(parse(text = paste("data", "$", data.response, sep = "")))
    for (var in list){
        plot(data[, var], temp, col = "grey",
             main = paste(data.name, var, " versus ",
                          data.name, data.response, sep = ""))
    }
}

#--------------------------------------
# fac.mosaic()
#--------------------------------------
# Function to create mosaic plots of factor variables
fac.mosaic <- function(data, list){
    require(RColorBrewer)
    temp <- eval(parse(text = paste("data", "$", data.response, sep = "")))
    for (var in list){
        plot(temp, data[, var], 
             col = brewer.pal(nlevels(data[, var]), "Spectral"),
             main = paste(data.name, data.response," versus ",
                          data.name, var, sep = ""),
             xlab = paste(data.name, data.response, sep = ""),
             ylab = paste(data.name, var, sep = ""))
    }
}

#------------------------------------------------------------------------------
# Variable Manipulation
#------------------------------------------------------------------------------

#--------------------------------------
# fac.freq()
#--------------------------------------
# Function to display frequencies of factor variables
fac.freq <- function(data, list){
    for (var in list){
        temp <- as.data.frame(summary(data[, var]))
        names(temp)[1] <- paste(data.name, var, sep = "")
        print(temp)
    }
}

#--------------------------------------
# fac.flag()
#--------------------------------------
# Function to create indicator variables from factor variable levels
fac.flag <- function(data, list){
    for (var in list){
        for (level in unique(data[, var])){
            data[paste(var, level, sep = "_")] <- 
                ifelse(data[, var] == level, 1, 0)
        }
    }
    return(data)
}

#==============================================================================
# FIN
#==============================================================================

###############################################################################
# Bonus: Demo
###############################################################################

# Download and assign data
library(ISLR)
auto <- Auto

#------------------------------------------------------------------------------
# Data Prep
#------------------------------------------------------------------------------

# Assign column names
auto.cn.all <- colnames(auto)

# Treat "?" as NA
auto[auto == "?"] <- NA

# Create missing flags
auto <- m.flag(auto, auto.cn.all)

# Assign data.frame with missing values removed
# Note: have to do this until a missing impute solution is coded
auto <- na.omit(auto)

# Handle variable conversions
auto$horsepower <- as.numeric(as.character(auto$horsepower))
auto$cylinders <- as.factor(auto$cylinders)
auto$origin <- as.factor(auto$origin)

# Drop 'name'
auto <- subset(auto, select = -name)

# Assign column names, excluding missing flags
# all = all, numeric = num, factor = fac
auto.cn.all <- grep("^MF_", colnames(auto), value = T, invert = T)
auto.cn.num <- grep("^MF_", colnames(auto[, !sapply(auto, is.factor)]), 
                    value = T, invert = T)
auto.cn.fac <- grep("^MF_", colnames(auto[, sapply(auto, is.factor)]), 
                    value = T, invert = T)

# Assign data name and response name
data.name <- "auto$"
data.response <- "mpg"

#------------------------------------------------------------------------------
# Visual EDA
#------------------------------------------------------------------------------

# Numeric variables
num.plots(auto, auto.cn.num, norm = T)

# Factor variables
fac.barplot(auto, auto.cn.fac)

#------------------------------------------------------------------------------
# Quantitative EDA
#------------------------------------------------------------------------------

# Numeric variables
summary(auto[, auto.cn.num])

# Factor variables
fac.freq(auto, auto.cn.fac)

#------------------------------------------------------------------------------
# Trims, Transforms, and Flags
#------------------------------------------------------------------------------

#--------------------------------------
# Numeric variables
#--------------------------------------
# Trims
auto <- num.trims(auto, auto.cn.num)

# Re-assign column names, excluding missing flags
auto.cn.num <- grep("^MF_", colnames(auto[, !sapply(auto, is.factor)]), 
                    value = T, invert = T)

# Transforms
auto <- num.trans(auto, auto.cn.num)

#--------------------------------------
# Factor variables
#--------------------------------------
# Flags
auto <- fac.flag(auto, auto.cn.fac)

#--------------------------------------
# Verification
#--------------------------------------
auto.names <- data.frame(colnames(auto), sapply(auto, class))
rownames(auto.names) <- seq(1, nrow(auto.names), by = 1)
colnames(auto.names) <- c("Variable", "Class")
View(auto.names)

# All looks good, data are now ready for AVS!

#==============================================================================
# FIN
#==============================================================================