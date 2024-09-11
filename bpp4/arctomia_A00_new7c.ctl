seed =  -1

seqfile  = arctomia_bpp.phy
Imapfile = arctomia_imap_new7c.txt
outfile  = out.txt
mcmcfile = mcmc.txt
threads  = 3

speciesdelimitation = 0
speciestree         = 0

* Model from pooled new7 A11 analysis (see file "The big 6.txt")

species&tree = 6   ABCDEF GHIJKLM NOPRSTUV X Y Z
                   6      7       8        1 1 1
                  ((ABCDEF, (GHIJKLM, Y)), (NOPRSTUV, (X, Z)));
phase =            0      0       0        0 0 0

usedata = 1                        * 0: no data (prior); 1:seq like
nloci   = 3                          * number of data sets in seqfile

cleandata = 0                      * remove sites with ambiguity data (1:yes, 0:no)?

thetamodel = linked-none
thetaprior = invgamma 3 0.006 e      * add e to also sample theta when distr=invgamma
tauprior   = invgamma 3 0.012

model = Custom arctomia_models.txt
alphaprior = 1 1 4
locusrate  = 2 arctomia_locusrates.txt
clock      = 1
heredity   = 2 heredity.txt        * here: nrDNA, rpb1, mrSSU

print    = 1 0 0 1 1               * MCMC samples, locusrate, heredityscalars, genetrees
finetune = 1
burnin   = 100000
sampfreq = 100
nsample  = 100000
