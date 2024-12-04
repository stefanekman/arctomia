# +-------------------------------------------------------------------------------------+
# | This script generates summary statistics from a table that contains a column named  |
# | Specimen with a specimen name, a column named Species with the name of the species, |
# | and an arbitrary number of columns with numerical data so summarise. The names of.  |
# | the columns containing the numerical data and the corresponding number of decimals. |
# | to which the means from each specimen should be rounded before presentation should  |
# | be provided manually in the variables numcol and decimals below.                    |
# |                                                                                     |
# | Version 1. Stefan Ekman, 4 Dec 2024                                                 |
# +-------------------------------------------------------------------------------------+


# Headers of columns containing the numerical data to summarise - set manually
numcol <- c("Splen", "Spwid", "Apwid")
# Number of decinals wanted for each of the columns above set manually
decimals <- c(1, 2, 2)


# ------------------------------------------------------------------------------------------------------------
# Function to calculate statistics for a given column
# ------------------------------------------------------------------------------------------------------------
calculate_stats <- function(data, column) {
	stats <- aggregate(data[[column]], by = list(Species = data$Species), 
		FUN = function(x) c(min = min(x, na.rm = TRUE),
			mean = mean(x, na.rm = TRUE),
			max = max(x, na.rm = TRUE),
			sd = sd(x, na.rm = TRUE),
			n = sum(!is.na(x))))

	stats <- data.frame(Species = stats$Species, min = stats$x[,1], mean = stats$x[,2], 
		max = stats$x[,3], sd = stats$x[,4], n = stats$x[,5])

	return(stats)
}


# ------------------------------------------------------------------------------------------------------------
# Function to calculate the range of specimen means per species as well as the range of number of measurements
# ------------------------------------------------------------------------------------------------------------
calculate_specimen_mean_range <- function(data, column) {
	# Calculate means and counts for each specimen
	specimen_means <- aggregate(data[[column]], 
		by = list(Specimen = data$Specimen, Species = data$Species), 
		FUN = function(x) c(mean = mean(x, na.rm = TRUE), count = sum(!is.na(x))))
  
	# Remove rows where mean is NA (no valid measurements)
	specimen_means <- specimen_means[!is.na(specimen_means$x[,1]), ]
  
	# If no valid data remains, return NULL
	if (nrow(specimen_means) == 0) {
		return(NULL)
	}
  
	# Extract means and counts
	means <- specimen_means$x[,1]
	counts <- specimen_means$x[,2]
  
	# Create a data frame with means and counts
	mean_count_df <- data.frame(
		Species = specimen_means$Species,
		mean = means,
		count = counts
	)
  
	# Calculate range of means and specimen counts for each species
	mean_ranges <- aggregate(cbind(mean, count) ~ Species, data = mean_count_df, 
		FUN = function(x) c(min = min(x), median = median(x), max = max(x)))
  
	# Reshape the result
	result <- data.frame(
		Species = mean_ranges$Species,
		min_mean = mean_ranges$mean[,1],
		median_mean = mean_ranges$mean[,2],
		max_mean = mean_ranges$mean[,3],
		min_count = mean_ranges$count[,1],
		median_count = mean_ranges$mean[,2],
		max_count = mean_ranges$count[,3]
	)
  
	return(result)
}


# ------------------------------------------------------------------------------------------------------------
# Function to fix the number of decimals
# ------------------------------------------------------------------------------------------------------------
fix_decimals <- function(col, decimals) {
	trimws(format(round(col, decimals), nsmall = decimals))
}


# ------------------------------------------------------------------------------------------------------------
# Function to calculate the means of each character for each specimen, preserving the input order of
# the specimens
# ------------------------------------------------------------------------------------------------------------
calculate_specimen_means <- function(data, numcol) {
	# Create a factor to preserve the original order of specimens
	data$Specimen <- factor(data$Specimen, levels = unique(data$Specimen))
  
	# Calculate means for each measurement separately
	means_list <- lapply(numcol, function(col) {
		aggregate(as.formula(paste(col, "~ Specimen + Species")), 
		data = data, 
		FUN = function(x) mean(x, na.rm = TRUE))
	})
  
	# Merge the results
	specimen_means <- Reduce(function(x, y) merge(x, y, by = c("Specimen", "Species"), all = TRUE), means_list)
  
	# Sort the result by the original order of specimens
	specimen_means <- specimen_means[order(specimen_means$Specimen),]

	# Move the Species column to the end
	specimen_means <- specimen_means[, c("Specimen", numcol, "Species")]

	rownames(specimen_means) <- specimen_means$Specimen
	specimen_means$Specimen <- NULL
  
  return(specimen_means)
}


# ------------------------------------------------------------------------------------------------------------
# Computations start here
# ------------------------------------------------------------------------------------------------------------

# Set working directory
setwd("~/Dropbox/Forskningprojekt/Arctomia/9. Morphology")

# Read data
data <- read.table("measurements.txt", sep="\t", header=T, na.strings="", stringsAsFactors = FALSE)
# Clean data from accidental all-NA columns
data <- data[, colSums(!is.na(data)) > 0]

# Calculate basic statistics for each feature and species
stats <- lapply(numcol, function(col) calculate_stats(data, col))

# Calculate range of specimen means per species + range of number of measurements
mean_range <- lapply(numcol, function(col) calculate_specimen_mean_range(data, col))

# Calculate specimen means for each specimen
specimen_means <- calculate_specimen_means(data, numcol)
# Fix number of decimals
specimen_means[numcol] <- mapply(fix_decimals, specimen_means[numcol], decimals)

# Print results
for ( i in seq(length(numcol)) ) {
	cat("\n\nStatistics for ")
	cat(numcol[i])
	cat(":\n")
	print(stats[[i]])
	cat("\n\nRange of specimen means and number of measurements for ")
	cat(numcol[i])
	cat(":\n")
	print(mean_range[[i]])
}

cat("\n\nSpecimen means:\n")
print(specimen_means)
cat("\n\n")