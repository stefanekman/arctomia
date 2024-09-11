# +-------------------------------------––––––––––------------------------------------------–+
# | This script performs a nonparametric bootstrap across trees and alignment uncertainty.   |
# |                                                                                          |
# | RPB1 and 5.8S are treated as fixed alignments.                                           |
# |                                                                                          |
# | For each of ITS1, ITS2, nrLSU, and mrSSU, 400 perturbations of the alignment created     |
# | by GUIDANCE2 are kept in the folder, the name of which is passed to variable 'folder'.   |
# |                                                                                          |
# | The script iterates 1000 times, each time randomly sampling one out of the 400 subset.   |
# | alignments, concatenating each subset with the fixed alignments to generate one complete |
# | alignment passed to IQTREE to generate a single bootstrap replicate analysed under a     |
# | SYM+I+G model. Finally, a consensus tree is generated.                                   |
# +------------------------------------------------------------------------------------------+

library(evobiR)
setwd("/Applications/iqtree-2.1.3-MacOSX/bin")
system2("touch", args="/Applications/iqtree-2.1.3-MacOSX/bin/treefile.trees")

for (i in 1:1000) {
	
	# ITS1
	folder <- "/Applications/iqtree-2.1.3-MacOSX/bin/alignments/ITS1"
	files <- list.files(folder, full.names=T)
	ITS1 <- sample(files, 1)
	args <- paste(ITS1[1], "/Applications/iqtree-2.1.3-MacOSX/bin/alignments/parts/ITS1.fasta", sep="")
	system2("cp", args=args)

	# 5.8S
	S <- "/Applications/iqtree-2.1.3-MacOSX/bin/alignments/58S/58S.fasta"
	args <- paste(S, "/Applications/iqtree-2.1.3-MacOSX/bin/alignments/parts/58S.fasta", sep="")
	system2("cp", args=args)

	# ITS2
	folder <- "/Applications/iqtree-2.1.3-MacOSX/bin/alignments/ITS2"
	files <- list.files(folder, full.names=T)
	ITS2 <- sample(files, 1)
	args <- paste(ITS2[1], "/Applications/iqtree-2.1.3-MacOSX/bin/alignments/parts/ITS2.fasta", sep="")
	system2("cp", args=args)

	# nrLSU
	folder <- "/Applications/iqtree-2.1.3-MacOSX/bin/alignments/LSU"
	files <- list.files(folder, full.names=T)
	LSU <- sample(files, 1)
	args <- paste(LSU[1], "/Applications/iqtree-2.1.3-MacOSX/bin/alignments/parts/LSU.fasta", sep="")
	system2("cp", args=args)

	# RPB1
	RPB1 <- "/Applications/iqtree-2.1.3-MacOSX/bin/alignments/RPB1/RPB1.fasta"
	args <- paste(RPB1, "/Applications/iqtree-2.1.3-MacOSX/bin/alignments/parts/RPB1.fasta", sep="")
	system2("cp", args=args)

	# mrSSU
	folder <- "/Applications/iqtree-2.1.3-MacOSX/bin/alignments/mrSSU"
	files <- list.files(folder, full.names=T)
	mrSSU <- sample(files, 1)
	args <- paste(mrSSU[1], "/Applications/iqtree-2.1.3-MacOSX/bin/alignments/parts/mrSSU.fasta", sep="")
	system2("cp", args=args)

	# Concatenate alignments
	setwd ("/Applications/iqtree-2.1.3-MacOSX/bin/alignments/parts")
	rubbish <- SuperMatrix(input="*.fasta")	
	

	# Run IQTREE from within R:
	system2("/Applications/iqtree-2.1.3-MacOSX/bin/iqtree2", args="-s concatenated.fasta --bonly 1 -m SYM+F+I+G --prefix tmp__", stdout=F)
	system2("cat", args="/Applications/iqtree-2.1.3-MacOSX/bin/alignments/parts/tmp__.treefile >> /Applications/iqtree-2.1.3-MacOSX/bin/treefile.trees")
	system2("rm", args="/Applications/iqtree-2.1.3-MacOSX/bin/alignments/parts/*")

}

system2("/Applications/iqtree-2.1.3-MacOSX/bin/iqtree2", args="-t /Applications/iqtree-2.1.3-MacOSX/bin/treefile.trees -con")
