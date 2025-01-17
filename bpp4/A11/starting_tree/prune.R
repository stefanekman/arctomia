# +-----------------------------------------------------------------------+
# | This script inputs a Newick, Nexus, or New Hampshire tree and returns |
# | a pruned tree containing only those terminals fitting a specified.    |
# | string pattern if and only if those terminals form a monophyletic.    |
# | group. Both a rooted and unrooted version of the pruned tree is.      |
# | returned and saved in Newick format.                                  |
# |                                                                       |
# | Stefan Ekman, 16 Jan 2025                                             |
# +-----------------------------------------------------------------------+

# ----------------- Set the parameters below manually ---------------------

# Set the outgroup by label
outgroup <- c("Trapelia_chiodectonoides", "Trapeliopsis_granulosa")

# Specify the string pattern(s) in label names to keep
# Can be more than one pattern, e.g., c("Arctomia", "Gabura")
save <- c("Arctomia")

# Set working directory
setwd("~/R_workdir/arctomia")

# Set name of file containing tree
filename <- "arctout2.con.tre"

# -------------------------------------------------------------------------

# Read libraries
library(ape)
library (stringr)

# Custom stop function on error
custom_stop <- function(msg) {
 	cat(msg)
 	opt <- options(show.error.messages = FALSE)
 	on.exit(options(opt))
 	stop()
}

# Read tree, reroot, and ladderise
error <- F
tryCatch( {tree <- read.tree(filename)}, error=function(e) {error<<-T}, warning=function(w) {error<<-T})
if ( error ) {
	error <- F
	tryCatch( {tree <- read.nexus(filename)}, error=function(e) {error<<-T}, warning=function(w) {error<<-T})
}
if ( error ) {
	custom_stop("Cannot read tree\n\n\n")
}

tree <- root(tree, outgroup=outgroup)
tree <- ladderize(tree, right=F)

# Get tip labels and find the labels to be saved for the pruned tree
labels <- tree$tip.label
keep <- labels[str_detect(labels, paste(save, collapse = "|"))]

# Check if the saved labels form a monophyletic group and, if so,
# return a rooted and an unrooted version of the pruned tree
if ( is.monophyletic(tree, tips=keep) ) {
	newtree <- keep.tip(tree, tip=keep)
	newtree <- ladderize(newtree, right=F)
	newtree2 <- unroot(newtree)
	write.tree(tree, file="original_tree_rerooted_ladderised.tre")
	write.tree(newtree, file="pruned_tree_rooted.tre")
	write.tree(newtree2, file="pruned_tree_unrooted.tre")
} else {
	cat("Selected group is non-monophyletic\n\n\n")
	write.tree(tree, file="original_tree_rerooted_ladderised.tre")
}	
