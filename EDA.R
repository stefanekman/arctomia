# +-------------------------------------------------------------------------------------+
# | This script generates summary statistics from a table that contains a column named  |
# | Specimen with a specimen name, a column named Species with the name of the species, |
# | and an arbitrary number of columns with numerical data so summarise.                |
# |                                                                                     |
# | Version 3. Stefan Ekman, 10 Dec 2024                                                |
# +-------------------------------------------------------------------------------------+


# ------------------------------------------------------------------------------------------------------------
# Species names must be in a column names "Species"
# Specimen names must be in a column named "Specimen"

# ------------------------------------------------------------------------------------------------------------
# Manually set the parameters below
# ------------------------------------------------------------------------------------------------------------

# --- Set working directory
setwd("~/Dropbox/Forskningprojekt/Arctomia/9. Morphology/stats")

# --- Set input file name
inputfile <- "measurements.txt"

# -- Headers of columns containing the numerical data to summarise
numcol <- c("Splen", "Spwid", "Apwid")

# -- Number of decinals wanted for each of the columns above
decimals <- c(1, 2, 2)

# -- Minimum number of measurements needed for a specimen to be included in the specimen range calculations
cutoffs <- c(1, 1, 1)

# --- Requested level of stability for the cumulative mean per specimen
stability <- 0.05

# -- Name of Excel output file
filename <- "stats.xlsx"

# ------------------------------------------------------------------------------------------------------------

# Read libraries
library(dplyr)
library(tidyr)
library(openxlsx)


# ------------------------------------------------------------------------------------------------------------
# Function to calculate statistics for a given column
# ------------------------------------------------------------------------------------------------------------

calculate_stats <- function(data, column) {
	# Calculate statistics
	stats <- aggregate(data[[column]], by = list(Species = data$Species), 
		FUN = function(x) c(min = min(x, na.rm = TRUE),
			mean = mean(x, na.rm = TRUE),
			max = max(x, na.rm = TRUE),
			sd = sd(x, na.rm = TRUE),
			n = sum(!is.na(x))))

	# Count specimens per species
	specimen_count <- as.data.frame(table(unique(data[c("Specimen", "Species")])$Species))

	# Reshape the result
	stats <- data.frame(Species = stats$Species, min = stats$x[,1], mean = stats$x[,2], 
		max = stats$x[,3], sd = stats$x[,4], n = stats$x[,5], N = specimen_count[,2])

	return(stats)
}


# ------------------------------------------------------------------------------------------------------------
# Function to calculate the range of specimen means per species as well as the range of number of measurements
# ------------------------------------------------------------------------------------------------------------

calculate_specimen_mean_range <- function(data, column, cutoff) {
	# Calculate means and counts for each specimen
	specimen_means <- aggregate(data[[column]], 
		by = list(Specimen = data$Specimen, Species = data$Species), 
		FUN = function(x) c(mean = mean(x, na.rm = TRUE), count = sum(!is.na(x))))
  
	# Remove rows where mean is NA (no valid measurements) or count is less than cutoff
	specimen_means <- specimen_means[!is.na(specimen_means$x[,1]) & specimen_means$x[,2] >= cutoff, ]
  
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
  
	# Calculate range of means and measurement counts for each species
	mean_ranges <- aggregate(cbind(mean, count) ~ Species, data = mean_count_df, 
		FUN = function(x) c(min = min(x), median = median(x), max = max(x)))

  	# Count specimens per species
	specimen_count <- as.data.frame(table(unique(specimen_means[c("Specimen", "Species")])$Species))

	# Reshape the result
	result <- data.frame(
		Species = mean_ranges$Species,
		min_mean = mean_ranges$mean[,1],
		median_mean = mean_ranges$mean[,2],
		max_mean = mean_ranges$mean[,3],
		min_count = mean_ranges$count[,1],
		median_count = mean_ranges$count[,2],
		max_count = mean_ranges$count[,3],
		N = specimen_count[,2]
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
# Function to calculate the means of each character for each specimen while preserving the input order of
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
# Function to calculate the number of measurements needed for the cumulative mean to change stability or less
# If measurements_needed=n, then n is the number where the change from n-1 to n is stability or less
# ------------------------------------------------------------------------------------------------------------

calc_cum_mean <- function(data, numcol, stability) {
	# Function to calculate cumulative mean stability
	calc_stability <- function(x) {
		n <- length(x)
		for (i in 2:n) {
			if (abs(mean(x[1:i]) - mean(x[1:(i-1)])) / mean(x[1:(i-1)]) <= 0.05) {
			return(i)
		}
	}
	return(n)
	}
  
	# Process each column in numcol
	results <- lapply(numcol, function(column) {
	data_clean <- data %>% 
	filter(!is.na(!!sym(column)))
    
	column_results <- data_clean %>%
	group_by(Specimen) %>%
	summarise(
		measurements_needed = replicate(1000, {
			calc_stability(sample(!!sym(column)))
		}) %>% mean() %>% ceiling(),
	total_measurements = n(),
	.groups = 'drop'
	) %>%
	mutate(
		measurements_needed = pmin(measurements_needed, total_measurements),
		feature = column
	)
    
	return(column_results)
	})
  
	# Combine results for all columns
	combined_results <- bind_rows(results)
  
	# Ensure original order of specimens is maintained
	final_results <- combined_results %>%
	right_join(data %>% select(Specimen) %>% distinct(), by = "Specimen") %>%
	arrange(match(Specimen, unique(data$Specimen))) %>%
	select(Specimen, feature, measurements_needed, total_measurements)
  
	return(final_results)
}


# ------------------------------------------------------------------------------------------------------------
# Computations start here
# ------------------------------------------------------------------------------------------------------------

# Read data
data <- read.table(inputfile, sep="\t", header=T, na.strings="", stringsAsFactors = FALSE)
# Clean data from accidental all-NA columns
data <- data[, colSums(!is.na(data)) > 0]
# Clean data from rows without any data
data <- data[!apply(data[, numcol], 1, function(x) all(is.na(x) | x == "")), ]

# Calculate basic statistics for each feature and species
stats <- lapply(numcol, function(col) calculate_stats(data, col))

# Calculate range of specimen means per species + range of number of measurements
mean_range <- mapply(function(col, cutoff) 
	calculate_specimen_mean_range(data, col, cutoff), 
	numcol, 
	cutoffs, 
	SIMPLIFY = F)

# Calculate specimen means for each specimen
specimen_means <- calculate_specimen_means(data, numcol)

# Fix number of decimals
specimen_means[numcol] <- mapply(fix_decimals, specimen_means[numcol], decimals)

# Calculate stable measurements for each feature
cum_mean_results <- calc_cum_mean(data, numcol, stability)

# Reshape cum_mean_results
cum_mean_wide <- cum_mean_results %>%
	tidyr::pivot_wider(
		id_cols = Specimen,
		names_from = feature,
		values_from = c(measurements_needed, total_measurements),
		names_glue = "{feature}_{.value}"
	)

# Reorder columns
column_order <- c("Specimen")
for (feature in numcol) {
	column_order <- c(column_order, 
		paste0(feature, "_measurements_needed"), 
		paste0(feature, "_total_measurements"))
}

cum_mean_wide <- cum_mean_wide[, column_order]


# ------------------------------------------------------------------------------------------------------------
# Write statistics to Excel file
# ------------------------------------------------------------------------------------------------------------
 
# Create a new workbook
wb <- createWorkbook()

for (i in seq(length(numcol))) {
	# Add a new worksheet for each column
	addWorksheet(wb, numcol[i])
  
	# Write statistics
	writeData(wb, numcol[i], paste("Statistics for", numcol[i]), startRow = 1)
	writeData(wb, numcol[i], stats[[i]], startRow = 2, rowNames = TRUE)
  
	# Write range of specimen means
	writeData(wb, numcol[i], paste0("Range of specimen means and number of measurements for", numcol[i], ", cutoff = ", 
		cutoffs[i], " measurements per specimen"), startRow = nrow(stats[[i]]) + 4)
	writeData(wb, numcol[i], mean_range[[i]], startRow = nrow(stats[[i]]) + 5, rowNames = TRUE)
}

# Add a new worksheet for specimen means
addWorksheet(wb, "Specimen Means")
writeData(wb, "Specimen Means", "Specimen means", startRow = 1)
writeData(wb, "Specimen Means", specimen_means, startRow = 2, rowNames = TRUE)

# Add a new worksheet for cum_mean_results
addWorksheet(wb, "Stable Measurements")

# Write the title
writeData(wb, "Stable Measurements", paste0("Number of specimens to achieve stable means, stability within ", stability), 
	startRow = 1, startCol = 1)

# Write the main headers
int_numcol <- c("", sapply(numcol, function(x) c(x, "")))
subheaders <- c("Specimens", rep(c("Needed", "Total"), length(numcol)))
headers <- t(data.frame(int_numcol, subheaders))
writeData(wb, "Stable Measurements", headers, startRow = 3, startCol = 1, colNames=F, rowNames=F)

# Write the data
writeData(wb, "Stable Measurements", cum_mean_wide, startRow = 5, startCol = 1, colNames=F, rowNames=F)

# Save the workbook
saveWorkbook(wb, filename, overwrite = TRUE)
