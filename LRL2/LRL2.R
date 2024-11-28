# Load libraries
library(glmnet)
library(caret)
library(dplyr)


# Set working directory
setwd("/Users/stefan/R_workdir/LRL2")

# Read data
alldata <- read.table(file="arctomia_morph.txt", sep="\t", header=T, row.names=1)

# Preprocess numerical data
alldata[,1:4] <- scale(alldata[,1:4])

# Prepare data
X_train <- alldata[alldata$seq==1,]
y_train <- as.factor(X_train$label)
X_train <- X_train[, 1:4]
X_test <- alldata[alldata$seq==0,]
X_test <- X_test[, 1:4]

# Balance data set if the rarest class has < 3 occurences
# Otherwise cv.glmnet may complain
if ( min(table(y_train))<3 ) {

	# Combine X_train and y_train into a single dataframe
	data <- data.frame(X_train, class = y_train)

	# Upsample to balance classes
	up_sampled <- caret::upSample(x = data[, -ncol(data)], y = data$class)

	# Extract X_train and y_train from the upsampled data
	X_train2 <- as.matrix(up_sampled[, -ncol(up_sampled)])
	y_train2 <- up_sampled$Class
} else {
	X_train2 <- X_train
	y_train2 <- y_train
}

# Fit the L2-regularised logistic regression model; alpha = 0 specifies L2 regularisation (Ridge)
# A bug in cv.glmnet makes it output warnings that are not true, hence the suppressing of warnings
suppressWarnings({
	model <- cv.glmnet(X_train2, y_train2, family = "multinomial", alpha = 0, type.measure="class", nfolds=10)
})

# Model performance on original training set
trainprob <- predict(model, newx = as.matrix(X_train), type = "response", s = "lambda.1se")
trainprob <- setNames(as.data.frame(trainprob), colnames(trainprob))
predicted_class <- levels(y_train)[max.col(trainprob)] # maxprob classifications
actual_class <- y_train  # just to get a sensible name for the column
trainres <- cbind(trainprob, predicted_class, actual_class)

# Calculate average Shannon entropy across samples
calculate_entropy <- function(probabilities) {
	-rowSums(probabilities * log2(probabilities + 1e-15))
}
sample_entropies <- calculate_entropy(trainprob)
average_entropy <- mean(sample_entropies)

# Make predictions on the test set
testprob <- predict(model, newx = as.matrix(X_test), type = "response", s = "lambda.1se")
testprob <- setNames(as.data.frame(testprob), colnames(testprob))
testclass <- levels(y_train)[max.col(testprob)] # maxprob classifications
testres <- cbind(testprob, testclass)

# Output results to file
cat("Class membership probabilities and maxprob classification in training data:\n\n") %>% capture.output(file="arctomia_lrl2.txt", append=F)
print(trainres) %>% capture.output(file="arctomia_lrl2.txt", append=T)
cat("\n\n\nConfusion matrix for original training set:\n\n") %>% capture.output(file="arctomia_lrl2.txt", append=T)
caret::confusionMatrix(as.factor(trainclass), y_train) %>% capture.output(file="arctomia_lrl2.txt", append=T)
cat("\n\n\nAverage Shannon entropy across samples of training data: ") %>% capture.output(file="arctomia_lrl2.txt", append=T)
cat(average_entropy) %>% capture.output(file="arctomia_lrl2.txt", append=T)
cat("\n\n\n\nClass membership probabilities and maxprob classification in test data:\n\n") %>% capture.output(file="arctomia_lrl2.txt", append=T)
print(testres) %>% capture.output(file="arctomia_lrl2.txt", append=T)
cat("\n\n\n") %>% capture.output(file="arctomia_lrl2.txt", append=T)
