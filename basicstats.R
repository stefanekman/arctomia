data <- read.table("~/Dropbox/Forskningprojekt/Arctomia/9. Morphology/measurements.txt", sep="\t", header=T, na.strings="", stringsAsFactors = FALSE)


# Function to calculate statistics for a given column
calculate_stats <- function(data, column) {
  stats <- aggregate(data[[column]], by = list(Species = data$Species), 
                     FUN = function(x) c(mean = mean(x, na.rm = TRUE),
                                         min = min(x, na.rm = TRUE),
                                         max = max(x, na.rm = TRUE),
                                         sd = sd(x, na.rm = TRUE),
                                         n = sum(!is.na(x))))
  return(stats)
}


# Function to calculate the range of specimen means per species as well as the range of number of measurements
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
                           FUN = function(x) c(min = min(x), max = max(x)))
  
  # Reshape the result
  result <- data.frame(
    Species = mean_ranges$Species,
    min_mean = mean_ranges$mean[,1],
    max_mean = mean_ranges$mean[,2],
    min_specimens = mean_ranges$count[,1],
    max_specimens = mean_ranges$count[,2]
  )
  
  return(result)
}


# Function to calculate the means of each character for each specimen,
# preserving the input order of the specimens
calculate_specimen_means <- function(data) {
  # Create a factor to preserve the original order of specimens
  data$Specimen <- factor(data$Specimen, levels = unique(data$Specimen))
  
  # Calculate means for each measurement separately
  splen_means <- aggregate(Splen ~ Specimen + Species, data = data, 
                           FUN = function(x) mean(x, na.rm = TRUE))
  spwid_means <- aggregate(Spwid ~ Specimen + Species, data = data, 
                           FUN = function(x) mean(x, na.rm = TRUE))
  apwid_means <- aggregate(Apwid ~ Specimen + Species, data = data, 
                           FUN = function(x) mean(x, na.rm = TRUE))
  
  # Merge the results
  specimen_means <- merge(splen_means, spwid_means, by = c("Specimen", "Species"), all = TRUE)
  specimen_means <- merge(specimen_means, apwid_means, by = c("Specimen", "Species"), all = TRUE)
  
  # Sort the result by the original order of specimens
  specimen_means <- specimen_means[order(specimen_means$Specimen),]
  
  return(specimen_means)
}



# Calculate basic statistics for each feature and species
splen_stats <- calculate_stats(data, "Splen")
spwid_stats <- calculate_stats(data, "Spwid")
apwid_stats <- calculate_stats(data, "Apwid")

# Calculate range of specimen means per species + range of number of measurements
splen_mean_range <- calculate_specimen_mean_range(data, "Splen")
spwid_mean_range <- calculate_specimen_mean_range(data, "Spwid")
apwid_mean_range <- calculate_specimen_mean_range(data, "Apwid")

# Calculate means for each specimen
specimen_means <- calculate_specimen_means(data)


# Print results
cat("\n\nStatistics for Splen:\n")
print(splen_stats)
cat("\n\nRange of specimen means and number of specimens for Splen:\n")
print(splen_mean_range)

cat("\n\nStatistics for Spwid:\n")
print(spwid_stats)
cat("\n\nRange of specimen means and number of specimens for Spwid:\n")
print(spwid_mean_range)

cat("\n\nStatistics for Apwid:\n")
print(apwid_stats)
cat("\n\nRange of specimen means and number of specimens for Apwid:\n")
print(apwid_mean_range)

cat("\n\nSpecimen means:\n")
print(specimen_means)
cat("\n\n")