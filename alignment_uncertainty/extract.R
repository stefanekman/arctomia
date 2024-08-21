# +--------------------------------------------------------------+
# | This script extracts the regions of a concatenated alignment |
# | WITHOUT dropping taxa that are empty for some regions        |
# +--------------------------------------------------------------+

library(ape)

all <- read.dna("arctomia.fasta", format="fasta", as.matrix=T)

ITS1 <- all[,1:215]
write.dna(ITS1, file="ITS1.fasta", format="fasta")

S <- all[,216:369]
write.dna(S, file="58S.fasta", format="fasta")

ITS2 <- all[,370:539]
write.dna(ITS2, file="ITS2.fasta", format="fasta")

LSU <- all[,540:1494]
write.dna(LSU, file="LSU.fasta", format="fasta")

# First get the entire RPB1, then drop every third position
# starting from position 3 to get 1st and 2nd positions
RPB1 <- all[,1495:1974]
RPB1_12 <- RPB1[,-seq(3,480,3)]
write.dna(RPB1_12, file="RPB1_12.fasta", format="fasta")

RPB1_3 <- all[,seq(1497,1974,3)]
write.dna(RPB1_3, file="RPB1_3.fasta", format="fasta")

mrSSU <- all[,1975:2835]
write.dna(mrSSU, file="mrSSU.fasta", format="fasta")
