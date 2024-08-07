library(dplyr)
library(MASS)
library(outliers)

alldata <- read.table("~/R_workdir/arctomia_morph.txt", sep="\t", header=T, row.names=1)
alldata[,1:3] <- scale(alldata[,1:3])
alldata$L <- as.numeric(alldata$L)
alldata$W <- as.numeric(alldata$W)
alldata$Ap <- as.numeric(alldata$Ap)
data <- alldata[,-5]

train <- subset(alldata, seq=="1") # use only sequenced specimens
train <- train[,-5] # remove column with sequencing flags

newdata <- subset(alldata, seq=="0") # unsequenced data
newdata <- newdata[,-5]

cat("normality tests on lm() residuals\n\n") %>% capture.output(file="arctomia_output.txt", append=F)
arc <- lm(L ~ label, data=train)
summary(arc) %>% capture.output(file="arctomia_output.txt", append=T)
shapiro.test(arc$residuals) %>% capture.output(file="arctomia_output.txt", append=T)
arc <- lm(W ~ label, data=train)
summary(arc) %>% capture.output(file="arctomia_output.txt", append=T)
shapiro.test(arc$residuals) %>% capture.output(file="arctomia_output.txt", append=T)
arc <- lm(Ap ~ label, data=train)
summary(arc) %>% capture.output(file="arctomia_output.txt", append=T)
shapiro.test(arc$residuals) %>% capture.output(file="arctomia_output.txt", append=T)

cat("\n\noutlier tests\n\n") %>% capture.output(file="arctomia_output.txt", append=T)
outliers::dixon.test(train$L) %>% capture.output(file="arctomia_output.txt", append=T)
outliers::dixon.test(train$W) %>% capture.output(file="arctomia_output.txt", append=T)
outliers::dixon.test(train$Ap) %>% capture.output(file="arctomia_output.txt", append=T)


cat("\n\nLDA in MASS, train on sequenced specimens\n\n") %>% capture.output(file="arctomia_output.txt", append=T)
# Standard LDA without cross validation
arclda <- lda(x=train[,1:3], grouping=train[,4])
arclda %>% capture.output(file="arctomia_output.txt", append=T)
pred <- predict(arclda, method="plug-in", dimen=3)
pred %>% capture.output(file="arctomia_output.txt", append=T)
confmatr <- table(train$label, pred$class) # confusion matrix
confmatr %>% capture.output(file="arctomia_output.txt", append=T)
correct <- sum(diag(confmatr))/sum(confmatr)*100 # how well does the LDA classify?
correct %>% capture.output(file="arctomia_output.txt", append=T)

cat("\n\nmake prediction on all specimens, incl. unsequenced specimens\n\n") %>% capture.output(file="arctomia_output.txt", append=T)
pred <- predict(arclda, newdata=data[,1:3], method="plug-in", dimen=3) # now run prediction on all data!
pred %>% capture.output(file="arctomia_output.txt", append=T)


# Generate graph - use MASS library

# start by adding predicted class to unsequenced specimens
classes <- cbind(attr(pred$x, which="dimnames")[[1]], as.character(pred$class))
newdata[,4] <- classes[,2][match(row.names(newdata), classes[,1])]
data <- rbind(train, newdata)

arclda2 <- lda(x=data[,1:3], grouping=data[,4]) # new LDA with all data
cat("\n\nNew LDA with all data incl. predicted classes for unsequenced specimens, for making graph\n\n") %>% capture.output(file="arctomia_output.txt", append=T)
arclda2 %>% capture.output(file="arctomia_output.txt", append=T)
pred <- predict(arclda2, method="plug-in", dimen=3)
pred %>% capture.output(file="arctomia_output.txt", append=T)

# create table of species and corresponding colour numbers
cat <- unique(data$label)
num <- seq(1:(length(cat)))
coltable <- cbind(cat, num)
colnum <- as.integer(match(data[[4]], coltable))
# colours picked from phylogenetic tree
mycols <- c("#0087CD", "#528635", "#693B3F", "#D82D30", "#F7931E", "#FF00FF")
palette(mycols)
# custom arrow colour with transparency
arcol <- rgb(200, 200, 200, max=255, alpha = 200)

png("lda.png", width=20, height=20, unit="cm", res=600)

plot(LD2 ~ LD1, data = pred$x)
points(LD2 ~ LD1, data=pred$x, pch=16, cex=2, col=colnum)
arrows(0, 0, arclda2$scaling[1,1], arclda2$scaling[1,2], length=0.1, angle=20, col=arcol, lwd=2)
arrows(0, 0, arclda2$scaling[2,1], arclda2$scaling[2,2], length=0.1, angle=20, col=arcol, lwd=2)
arrows(0, 0, arclda2$scaling[3,1], arclda2$scaling[3,2], length=0.1, angle=20, col=arcol, lwd=2)
# text(LD2 ~ LD1, data=pred$x, labels = rownames(pred$x))

dev.off()


library(WeDiBaDis)
cat("\n\nweighted-distance-based discriminant analysis in WeDiBaDis\n\n") %>% capture.output(file="arctomia_output.txt", append=T)
arc <- WeDiBaDis::WDBdisc(data=train, datatype="m", classcol=4, method="WDB", distance="euclidean", new.ind=newdata[,1:3])
summary(arc) %>% capture.output(file="arctomia_output.txt", append=T)


library(mda)
cat("\n\nmixture discriminant analysis (MDA)\n\n") %>% capture.output(file="arctomia_output.txt", append=T)
arcmda <- mda(label ~ ., data=train)
arcmda %>% capture.output(file="arctomia_output.txt", append=T)
arcmda$confusion %>% capture.output(file="arctomia_output.txt", append=T)
predict(arcmda, newdata=data, type="class") %>% capture.output(file="arctomia_output.txt", append=T)
predict(arcmda, newdata=data, type="posterior") %>% capture.output(file="arctomia_output.txt", append=T)
predict(arcmda, newdata=data, type="hierarchical") %>% capture.output(file="arctomia_output.txt", append=T)
# Rausch & Kelley 2009: MDA can be viewed as an extension of LDA that models the within-group multivariate density of the predictors 
# through a mixture (i.e., a weighted sum) of multivariate normal distributions (Fraley & Raftery, 2002). In principle, this approach 
# is useful for one of two purposes: (1) to model multivariate nonnormality or nonlinear relationships among variables within each group, 
# allowing for more accurate classification; or (2) to determine whether latent/underlying subclasses may be present in each group.
