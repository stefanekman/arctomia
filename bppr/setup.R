# +-------------------------------------------------------------------------------+
# This script is for setting up BPP A00 runs for marginal likelihood estimation   |
# by bppr, with n=8 and a=5                                                       |
# 1. Change parameters ctlfile and imapfile in setup.R                            |
# 2. Change name of ctl file                                                      |
# 3. Open ctl file and check that Imapfile, species&tree, and phase are in order  |
# 4. Change name of imap file                                                     |
# 5. Open imap file and make sure it agrees with species&tree in ctl file         |
# 6. Run this script                                                              |
# +-------------------------------------------------------------------------------+


library(bppr)
setwd("~/Documents/bppr")

ctlfile <- "arctomia_A00_new7j.ctl"
imapfile <- "input/arctomia_imap_new7j.txt"

b <- make.beta(n=8, a=5, method="step-stones")
make.bfctlf(b, ctlf=ctlfile, betaf="beta.txt")

dir <- c("1", "2", "3", "4", "5", "6", "7", "8")

files <- c("input/bpp", "input/arctomia_bpp.phy", "input/heredity.txt", "input/arctomia_locusrates.txt", "input/arctomia_models.txt")
files[6] <- imapfile

for (i in dir) {
	file.copy(files, i)
}

print(noquote(paste("./bpp --cfile", ctlfile)))
