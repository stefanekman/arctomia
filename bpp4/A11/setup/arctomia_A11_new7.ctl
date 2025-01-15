seed =  -1

seqfile  = arctomia_bpp.phy
Imapfile = arctomia_imap_free.txt
outfile  = out.txt
mcmcfile = mcmc.txt
threads  = 3

* speciesdelimitation = 1 0 2        * species delimitation rjMCMC algorithm0 and finetune(e)
speciesdelimitation = 1 1 2 1     * species delimitation rjMCMC algorithm1 finetune (a m)

speciestree = 1

speciesmodelprior = 3              * 0: uniform LH; 1:uniform rooted trees; 2: uniformSLH; 3: uniformSRooted

species&tree = 24  A B C D E F G H I J K L M N O P R S T U V X Y Z
                   1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
                  ((D,(A,(C,(F,(B,E))))),((Y,(G,((J,L),((H,K),(I,M))))),((Z,X),((O,(N,P)),(U,(S,(R,(T,V))))))));
                  * MrBayes consensus tree

phase =            0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

usedata = 1                        * 0: no data (prior); 1:seq like
nloci = 3                          * number of data sets in seqfile

cleandata = 0                      * remove sites with ambiguity data (1:yes, 0:no)?

thetamodel = linked-none
thetaprior = invgamma 3 0.006      * add e to also sample theta)
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
