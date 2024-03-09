For bootstrap.R and extract.R:

"Furthermore, we designed a simple ML bootstrap procedure that estimates phylogenetic uncertainty stemming also from uncertainty about the alignment itself.
Using an R script, full alignments were generated by randomly selecting one of the 400 alternative GUIDANCE2 alignments for each of the ITS1, ITS2, nrLSU,
and mrSSU and concatenating them with the fixed alignments of 5.8S and RPB1. IQ-TREE was called from within the script to generate a single standard
non-parametric bootstrap replicate, for simplicity using the unpartitioned model (SYM+I+Γ). This process was repeated 1000 times and a consensus tree was
generated from the resulting trees."

For setup.R and analyse.R:

These scripts are for setting up and analyse the results from the R package bppr.

For poolA11models.R:

This script pools the results from several, equally long MCMC chains run by BPP version 4. There is documentation in the script. Note that the script also
includes the function hpdxy, which calcuates the highest posterior density (HPD) when your data consist of integers (here: number of species) and their
corresponding frequencies (summing to 1).
