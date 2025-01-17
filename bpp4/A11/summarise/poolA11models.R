# +----------------------------------------------------------+
# | This script pools output from several BPP A11 analyses.  |
# | It is assumed that all A11 MCMC chains are equally long. |
# | Library stringr must be installed.                       |
# | This script was developed for BPP version 4, and may not |
# | work if the format of the output files is different.     |
# | Version 24 Jan 2024. Stefan Ekman.                       |
# +----------------------------------------------------------+

# Manually set the name of the folder containing the BPP outfiles:
# ----------------------------------------------------------------
#
folder <- "/Users/stefanekman/R_workdir/outfiles"
#
# ----------------------------------------------------------------

# The following patterns in the output files are used to identify
# blocks of information:
outfile.pattern <- "Using BPP version"                                         # check that we are dealing with a BPP output file
spnum.start.pattern <- "Posterior probability for # of species"                # start of block containing species number probabilities
spnum.end.pattern <- " prior\\["                                               # end of block containing species number probabilities
spdelim.start.pattern <- "delimited species & their posterior probabilities"   # start of block containing species delimitations
spdelim.end.pattern <- "Posterior probability for # of species"                # end of block containing species delimitations
spmodel.start.pattern <- "List of best models"                                 # start of block containing complete models
spmodel.end.pattern <- "species delimitations & their posterior probabilities" # end of block containing complete models

# Also note that it is assumed that in the list of complete models,
# strings containing species delimitations and models are preceeded
# by a double space.

# Necessary function:
# +-----------------------------------------------------------------------+
# | This function calculates the highest posterior density (HPD)interval  |
# | from "bar chart" data, where the input is a two-column data frame     |
# | with x axis integers in the first column and y axis frequencies       |
# | in the second column. The calculated HPD is the narrowest possible    |
# | continuous interval, assuming an approximately unimodal distribution. |
# | Version 25 Jan 2024. Stefan Ekman.                                    |
# |                                                                       |
# | Input: a data frame ("table"), as described above, and a posterior    |
# | probability cutoff ("prob")on the interval [0, 1], normally 0.95.     |
# | Output: The function returns the following attributes:                |
# |    $lower: the lower bound of the HPD                                 |
# |    $upper: the upper bound of the HPD                                 |
# |    $acc.prob: the accummulated probability when the expansion of the  |
# |               HPD is terminated                                       |
# +-----------------------------------------------------------------------+
hpdxy <- function(table, prob) {

	table[,1]<-as.integer(table[,1])
	table[,2]<-as.numeric(table[,2])
	colnames(table) <- c("col1", "col2")
	table2 <- table[order(table$col2, decreasing=T),]
	# Loop below ensures that interval is continuous
	for ( i in 2:(nrow(table2)-1) ) {
		if ( table2[i,1]> max(table2[1:i-1,1])+1 || table2[i,1]< min(table2[1:i-1,1])-1 ) {
			a <- table2[i,1]
			b <- table2[i,2]
			table2[i,] <- table2[i+1,]
			table2[i+1,1] <- a
			table2[i+1,2] <- b
		}
	}
	p <- 0
	x <- 0
	# Loop below accummulates desired probability
	while ( p<prob ) {
		x <- x+1
		p <- p+table2[x,2]
	}
	table2 <- table2[1:x,]
	start <- min(table2[,1])
	end <- max(table2[,1])
	newList <- list("lower"=start, "upper"=end, "acc.prob"=p)
	return(newList)

}
# ------------------------------------------------------------------------


library(stringr)

setwd(folder)
files <- list.files()

models <- data.frame()
species <- data.frame()
number <- vector()
probs <- vector()
sumprobs <- vector()
bppfiles <- 0

for ( x in 1:length(files) ) {

	a <- readLines(files[x])

	if ( str_detect(a[2], outfile.pattern) ) {
		cat(paste("reading", files[x], "\n"))
		bppfiles <- bppfiles+1 # Count the outfiles from BPP
	} else {
		cat(paste("not reading", files[x], "\n"))
		next
	}

	# Find and extract block with models
	startmodel <- str_which(a, spmodel.start.pattern)[1]+1
	endmodel <- str_which(a, spmodel.end.pattern)[1]-2
	b <- a[startmodel:endmodel]
	c <- str_split(b, "  ") # First split on double space
	d <- as.data.frame(do.call(rbind, c)) # Convert the nested list c to a data frame
	d[,1]<-str_squish(d[,1]) # Remove trailing spaces and make sure internal species are simple
	e <- str_split(d[,1], " ") # Then split rest on single spaces
	f <- as.data.frame(do.call(rbind, e)) # Convert the nested list e to a data frame
	models <- rbind(models, data.frame(f, d[2:3])) # Accumulate lines from different files

	# Find and extract block with species delimitations
	startspecies <- str_which(a, spdelim.start.pattern)[1]+1
	endspecies <- str_which(a, spdelim.end.pattern)[1]-2
	g <- a[startspecies:endspecies]
	g <- str_squish(g)
	h <- str_split(g, " ")
	i <- as.data.frame(do.call(rbind, h)) # Convert the nested list h to a data frame
	species <- rbind(species, i)

	# Find and extract block with species number probabilities
	startnumber <- str_which(a, spnum.start.pattern)[1]+1
	endnumber <- str_which(a, spnum.end.pattern)[length(str_which(a, spnum.end.pattern))]
	number <- seq(1:(endnumber-startnumber+1))
	probs <- as.numeric(str_extract(a[startnumber:endnumber], "[0-9]\\.[0-9]+"))
	if ( bppfiles==1 ) {
		sumprobs <- rep(0, length(probs))
	}
	sumprobs <- sumprobs+probs

}

rm(a, b, c, d, e, f, g, h, i)

# ------------------- Deal with species number ----------------------
cat("\nCounting probabilities of species numbers...\n\n")
sumprobs <- sumprobs/bppfiles
table <- data.frame(number, sumprobs)
table <- format(table, scientific=F, digits=6)
hpd <- hpdxy(table, 0.95)
cat(paste("The 95% highest posterior density interval is ", "[", hpd$lower, "-", hpd$upper, "]", sep=""))
write.table(table, file="poolNumbers.txt", quote=F, sep="\t", row.names=F, col.names=F, append=F)
cat("\nDone => Probabilities of species numbers written to poolNumbers.txt")


# ------------------- Deal with species delimitations ---------------
cat("\n\nCounting species delimitations...\n\n")

colnames(species) <- c("col1", "col2", "col3")
species <- species[order(species$col3),]
uniquespecies <- unique(species$col3)

countspecies <- vector()
freqspecies <- vector()
spdel <- vector()

start <- 0
end <- 0
# The following nonsense line is added to data frame species just to avoid an error when
# the while loop inside the for loop peeks into end+1 when end is the final line of species
species <- rbind(species, c("nonsense", "nonsense", "nonsense"))

for ( y in 1:length(uniquespecies) ) {
	start <- end+1
	end <- end+1
	while ( uniquespecies[y]==species$col3[end+1] ) {
		end <- end+1
	}
	countspecies[y] <- sum(as.integer(species[start:end, 1]))
	freqspecies[y] <- sum(as.numeric(species[start:end, 2]))
	spdel[y] <- species[start,3]
}

freqspecies <- freqspecies/bppfiles
freqspecies <- format(freqspecies, scientific=F, digits=6)
result <- data.frame (countspecies, freqspecies, uniquespecies)
result <- result[order(result$countspecies, decreasing=T),]
result <- result[1:100,]
write.table(result, file="poolSpecies.txt", quote=F, sep="\t", row.names=F, col.names=F, append=F)
cat("Done => 100 best species delimitations written to poolSpecies.txt")


# ------------------- Deal with models ------------------------------
starttime <- Sys.time()
cat("\n\nCounting models... This may take time...\n\n")

colnames(models) <- c("col1", "col2", "col3", "col4", "col5", "col6")
models <- models[order(models$col6),]
uniquemodels <- unique(models$col6)

countmodel <- vector()
freqmodel <- vector()
cumfreq <- vector()
delim <- vector()

pb = txtProgressBar(min=0, max=length(uniquemodels), initial=0, style=3)

start <- 0
end <- 0
# The following nonsense line is added to data frame models just to avoid an error when
# the while loop inside the for loop peeks into end+1 when end is the final line of models
models <- rbind(models, c("nonsense", "nonsense", "nonsense", "nonsense", "nonsense", "nonsense"))

for ( y in 1:length(uniquemodels) ) {
	start <- end+1
	end <- end+1
	while ( uniquemodels[y]==models$col6[end+1] ) {
		end <- end+1
	}
	countmodel[y] <- sum(as.integer(models[start:end, 1]))
	freqmodel[y] <- sum(as.numeric(models[start:end, 2]))
	delim[y] <- models[start,5]
	setTxtProgressBar(pb, y)
}

close(pb)
endtime <- Sys.time()
time <- as.character(round(as.numeric(endtime-starttime, units="mins"), 2))
cat("\nComparing models took", time, "minutes") 

freqmodel <- freqmodel/bppfiles
freqmodel <- format(freqmodel, scientific=F, digits=6)
result <- data.frame (countmodel, freqmodel, delim, uniquemodels)
result <- result[order(result$countmodel, decreasing=T),]
cumfreq <- cumsum(result$freqmodel)
cumfreq <- format(cumfreq, scientific=F, digits=6)
final <- data.frame(result[,1:2], cumfreq, result[,3:4])
cat(paste("\nThe cumulative 95% posterior probability includes", as.character(which(final$cumfreq>=0.95)[1]), "models"))
final <- final[1:100,]
write.table(final, file="poolModels.txt", quote=F, sep="\t", row.names=F, col.names=F, append=F)
cat("\nDone => 100 best complete models written to poolModels.txt")






