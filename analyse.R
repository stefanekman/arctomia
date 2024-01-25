library(bppr)
setwd("~/Documents/bppr")

M1 <- stepping.stones()

print(M1$logml)

plot(M1$mean.logl ~ M1$b, pch=19, ty="b", xlab="b", ylab="mean log-likelihood")

# The 95% confidence interval of the log-marginal likelihood is
print(M1$logml + 2 * c(-M1$se, M1$se))