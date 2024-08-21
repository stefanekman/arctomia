# R preprocwssing:

alldata <- read.table("~/R_workdir/arctomia_morph3.txt", sep="\t", header=T, row.names=1)

train <- subset(alldata, seq=="1") # use only sequenced specimens
train <- train[,-7] # remove column with sequencing flags
train <- train[,-5] # do not use thallus structure character

newdata <- subset(alldata, seq=="0") # unsequenced data
newdata <- newdata[,-7] # remove column with sequencing flags
newdata <- newdata[,-6] # test data should not have any labels
newdata <- newdata[,-5] # do not use thallus structure character

write.csv(train, file="train4.csv", row.names=F)
write.csv(newdata, file="newdata4.csv", row.names=F)
