#
#
#    softcore.S
#
#    $Revision: 2.17 $   $Date: 2022/03/07 02:31:44 $
#
#    Soft core processes.
#
#    Softcore()    create an instance of a soft core process
#                 [an object of class 'interact']
#
#
# -------------------------------------------------------------------
#

Softcore <- local({

  BlankSoftcore <- 
  list(
       name     = "Soft core process",
       creator  = "Softcore",
       family   = "pairwise.family",  # evaluated later
       pot      = function(d, par) {
         sig0 <- par$sigma0
         if(is.na(sig0)) {
           p <- -d^(-2/par$kappa)
         } else {
           # expand around sigma0 and set large negative numbers to -Inf
           drat <- d/sig0
           p <- -drat^(-2/par$kappa)
           p[p < -25] <- -Inf
         }
         return(p)
       },
       par      = list(kappa = NULL, sigma0=NA),  # filled in later
       parnames = c("Exponent kappa", "Initial approximation to sigma"),
       hasInf = TRUE, 
       selfstart = function(X, self) {
         # self starter for Softcore
         if(npoints(X) < 2) {
           # not enough points to make any decisions
           return(self)
         }
         md <- minnndist(X)
         if(md == 0) {
           warning(paste("Pattern contains duplicated points:",
                         "impossible under Softcore model"))
           return(self)
         }
         kappa <- self$par$kappa
         if(!is.na(sigma0 <- self$par$sigma0)) {
           # value fixed by user or previous invocation
           # check it
           if((md/sigma0)^(-2/kappa) > 25)
             warning(paste("Initial approximation sigma0 is too large;",
                           "some data points will have zero probability"))
           return(self)
         }
         # take sigma0 = minimum interpoint distance
         Softcore(kappa=kappa, sigma0=md)
       },
       init     = function(self) {
         kappa <- self$par$kappa
         if(!is.numeric(kappa) || length(kappa) != 1 ||
            kappa <= 0 || kappa >= 1)
           stop(paste("Exponent kappa must be a",
                      "positive number less than 1"))
       },
       update = NULL,  # default OK
       print = NULL,    # default OK
       interpret =  function(coeffs, self) {
         theta <- as.numeric(coeffs[1])
         sigma <- theta^(self$par$kappa/2)
         if(!is.na(sig0 <- self$par$sigma0))
           sigma <- sigma * sig0
         return(list(param=list(sigma=sigma),
                     inames="interaction parameter sigma",
                     printable=signif(sigma)))
       },
       valid = function(coeffs, self) {
         theta <- coeffs[1]
         return(is.finite(theta) && (theta >= 0))
       },
       project = function(coeffs, self) {
         if((self$valid)(coeffs, self)) return(NULL) else return(Poisson())
       },
       irange = function(self, coeffs=NA, epsilon=0, ...) {
         # distance d beyond which log(interaction factor) <= epsilon
         if(anyNA(coeffs) || epsilon == 0)
           return(Inf)
         theta <- as.numeric(coeffs[1])
         kappa <- self$par$kappa
         sig0  <- self$par$sigma0
         if(is.na(sig0)) sig0 <- 1
         return(sig0 * (theta/epsilon)^(kappa/2))
       },
       hardcore = function(self, coeffs=NA, epsilon=0, ...) {
         # distance d below which interaction factor <= epsilon
         if(anyNA(coeffs) || epsilon == 0)
           return(0)
         theta <- abs(as.numeric(coeffs[1]))
         if(theta == 0) return(0)
         kappa <- self$par$kappa
         sig0  <- self$par$sigma0
         if(is.na(sig0)) sig0 <- 1
         h <- sig0 * (-log(epsilon)/theta)^(-kappa/2)
         return(h)
       },
       Mayer=function(coeffs, self) {
         # second Mayer cluster integral
         kappa <- self$par$kappa
         sigma <- (self$interpret)(coeffs, self)$param$sigma
         return(pi * (sigma^2) * gamma(1 - kappa))
       },
       version=NULL # filled in later
  )
  class(BlankSoftcore) <- "interact"

  Softcore <- function(kappa, sigma0=NA) {
    instantiate.interact(BlankSoftcore, list(kappa=kappa, sigma0=sigma0))
  }

  Softcore <- intermaker(Softcore, BlankSoftcore)
  
  Softcore
})

                  
