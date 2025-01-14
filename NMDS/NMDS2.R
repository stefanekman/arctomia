#
# +----------------------------------------------------------------------------------------+
# | This script performs non-metric multidimensional scaling (nMDS) using Euclidean        |
# | distances into two dimensions. Note that nMDS does not use the distances as they are,  |
# | only the rank order of the distances.                                                  |
# | Basic statistics, including feature vector, are output to a text file, and Shepard     |
# | and a nMDS graphs are provided.                                                        |
# |                                                                                        |
# | Stefan Ekman 19 Nov 2024.                                                              |               
# +----------------------------------------------------------------------------------------+
#


# Load libraries
library(vegan)
library(ggplot2)
library(svglite)
library(dplyr)

# Set working directory
setwd("/Users/stefanekman/R_workdir/nMDS")

# Get data and labels
data <- read.table(file="arctomia_morph.txt", sep="\t", header=T, row.names=1)
class_labels <- as.factor(data$label)
numerical_data <- data[,1:4]

# Preprocess data
numerical_data <- scale(numerical_data)

# Calculate distance matrix
# Note that nMDS does not use the distances as they are, only the rank order of the distances
distance_matrix <- dist(numerical_data, method="euclidean")

# Perform two-dimensional NMDS
nmds_result <- vegan::metaMDS(distance_matrix, k=2, try=100, trymax=100, autotransform=F)
stress <- nmds_result$stress

# Fit environmental vectors (variables) onto the NMDS configuration
envfit_result <- envfit(nmds_result, numerical_data, perm=9999)

# Extract scores for NMDS and environmental vectors
nmds_scores <- scores(nmds_result, display = "sites")
vector_scores <- scores(envfit_result, display = "vectors")

# Convert NMDS scores to data frame and add class labels
nmds_data <- as.data.frame(nmds_scores)
nmds_data$Species <- class_labels

# Convert vectors scores to data frame
vectors_df <- as.data.frame(vector_scores)
vectors_df$variable <- rownames(vector_scores)

# Create basic NMDS plot with points
plot <- ggplot(nmds_data, aes(x = NMDS1, y = NMDS2, color = Species)) +
  geom_point(size = 3) +
  scale_color_manual(values = c("#D82D30", "#693B3F", "#0087CD", "#528635", "#F7931E", "#FF00FF")) +  # Manually define colors
  theme_minimal() +
  labs(title = NULL, x = "NMDS1", y = "NMDS2")

# Set x and y axis limits and add tick marks at every integer from -2 to 2
plot <- plot +
  scale_x_continuous(limits = c(-2, 4), breaks = seq(-2, 4, 1)) +  # Set x-axis from -2 to 4 with ticks at every integer
  scale_y_continuous(limits = c(-2, 2.5), breaks = seq(-2, 2, 1))    # Set y-axis from -2 to 2 with ticks at every integer

# Add arrows to the plot
plot <- plot +
  geom_segment(data = vectors_df, aes(x = 0, y = 0, xend = NMDS1, yend = NMDS2),
               arrow = arrow(type = "closed", length = unit(0.2, "inches")),  # Arrowheads
               color = "grey50",                                              # Medium grey
               linewidth = 1.2,                                               # Line thickness
               alpha = 0.3)                                                   # Opacity

# Add labels to the vectors
plot <- plot +
  geom_text(data = vectors_df, aes(x = NMDS1, y = NMDS2, label = variable),
            color = "black", size = 4, vjust = -0.5)

# Customize the plot appearance: white background, no internal grid lines, with tick marks
plot <- plot +
  theme(
    panel.background = element_rect(fill = "white"),   # Set background to white
    panel.grid.major = element_blank(),                # Remove major grid lines
    panel.grid.minor = element_blank(),                # Remove minor grid lines
    axis.text = element_text(size = 12),               # Customize axis text size
    axis.title = element_text(size = 14),              # Customize axis title size
    axis.ticks = element_line(color = "black")         # Add tick marks
  )
                                         
# Ensure equal scaling on x and y axes
plot <- plot +
  coord_fixed()

# Add the stress value in the upper right corner of the plot
plot <- plot +
  annotate(
    "text",
    x = 2.9, 
    y = 2.5,
    label = paste("stress =", round(stress, 3)),
    size = 4,
    color = "black",
    hjust = 0)

# Save the plot
ggsave("NMDS_plot.svg", plot = plot, dpi = 600, width = 10, height = 8)

# Save basic analysis stats
print(nmds_result) %>% capture.output(file="nmds.txt", append=F)
cat("\n\n\n") %>% capture.output(file="nmds.txt", append=T)
print(envfit_result) %>% capture.output(file="nmds.txt", append=T)

# Save Shepard diagram
pdf(file="shepard.pdf")
stressplot(nmds_result)
dev.off()
