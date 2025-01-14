# +-------------------------------------------------------------------------------------+
# | This script replaces the provisional names used in the analyses with the names.     |
# | appearing in the paper and in the additional data on GitHub. This makes the         |
# | comparison between data and results in the paper and the GitHub repository easier.  |
# |                                                                                     |
# | Make sure you have the files bpp_key.txt, morphology_key.txt, and phylogeny_key.txt |
# | available in the same directory as this script.                                     |
# |                                                                                     |
# | Stefan Ekman, 14 Jan 2025                                                           |
# +-------------------------------------------------------------------------------------+


# -------------- Set the working directory and the filename manually --------------------

setwd("/Users/stefanekman/Dropbox/Forskningprojekt/Arctomia/11. Translation keys")
filename <- "arctomia_morph.txt"

# ---------------------------------------------------------------------------------------

if( !require(stringr) ) {
	install.packages("stringr")
	library(stringr)
}

bpp_key <- read.table("bpp_key.txt", header=F, sep="\t", stringsAsFactors = F)
morphology_key <- read.table("morphology_key.txt", header=F, sep="\t", stringsAsFactors = F)
phylogeny_key <- read.table("phylogeny_key.txt", header=F, sep="\t", stringsAsFactors = F)

present <- function(file, patterns) {
	check <- all(sapply(patterns, function(p) any(str_detect(file, fixed(p)))))
	return(check)
}

file <- readLines(filename)

if ( present(file, bpp_key[,1])==T ) {
	replacements <- setNames(bpp_key[,2], bpp_key[,1])
	newfile <- str_replace_all(file, replacements)
}

if ( present(file, phylogeny_key[,1])==T ) {
	replacements <- setNames(phylogeny_key[,2], phylogeny_key[,1])
	newfile <- str_replace_all(file, replacements)
}

if ( present(file, morphology_key[,1])==T ) {
	replacements <- setNames(morphology_key[,2], morphology_key[,1])
	newfile <- str_replace_all(file, replacements)
}


fileparts <- strsplit(filename, "\\.")[[1]]
basename <- paste(fileparts[-length(fileparts)], collapse = ".")
extension <- fileparts[length(fileparts)]
new_filename <- paste0(basename, "_new.", extension)

writeLines(newfile, new_filename)
