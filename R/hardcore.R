#
#
#    hardcore.S
#
#    $Revision: 1.16 $	$Date: 2022/03/07 02:06:12 $
#
#    The Hard core process
#
#    Hardcore()     create an instance of the Hard Core process
#                      [an object of class 'interact']
#	
#
# -------------------------------------------------------------------
#	

Hardcore <- local({

  BlankHardcore <- 
  list(
         name   = "Hard core process",
         creator = "Hardcore",
         family  = "pairwise.family",  # evaluated later
         pot    = function(d, par) {
           v <- 0 * d
           v[ d <= par$hc ] <-  (-Inf)
           attr(v, "IsOffset") <- TRUE
           v
         },
         par    = list(hc = NULL),  # filled in later
         parnames = "hard core distance",
         hasInf = TRUE, 
         selfstart = function(X, self) {
           # self starter for Hardcore
           nX <- npoints(X)
           if(nX < 2) {
             # not enough points to make any decisions
             return(self)
           }
           md <- minnndist(X)
           if(md == 0) {
             warning(paste("Pattern contains duplicated points:",
                           "impossible under Hardcore model"))
             return(self)
           }
           if(!is.na(hc <- self$par$hc)) {
             # value fixed by user or previous invocation
             # check it
             if(md < hc)
               warning(paste("Hard core distance is too large;",
                             "some data points will have zero probability"))
             return(self)
           }
           # take hc = minimum interpoint distance * n/(n+1)
           hcX <- md * nX/(nX+1)
           Hardcore(hc = hcX)
       },
         init   = function(self) {
           hc <- self$par$hc
           if(length(hc) != 1)
             stop("hard core distance must be a single value")
           if(!is.na(hc) && !(is.numeric(hc) && hc > 0))
             stop("hard core distance hc must be a positive number, or NA")
         },
         update = NULL,       # default OK
         print = NULL,        # default OK
         interpret =  function(coeffs, self) {
           return(NULL)
         },
         valid = function(coeffs, self) {
           return(TRUE)
         },
         project = function(coeffs, self) {
           return(NULL)
         },
         irange = function(self, coeffs=NA, epsilon=0, ...) {
           return(self$par$hc)
         },
         hardcore = function(self, coeffs=NA, epsilon=0, ...) {
           return(self$par$hc)
         },
       version=NULL, # evaluated later
       # fast evaluation is available for the border correction only
       can.do.fast=function(X,correction,par) {
         return(all(correction %in% c("border", "none")))
       },
       fasteval=function(X,U,EqualPairs,pairpot,potpars,correction,
                         splitInf=FALSE, ...) {
         # fast evaluator for Hardcore interaction
         if(!all(correction %in% c("border", "none")))
           return(NULL)
         if(spatstat.options("fasteval") == "test")
           message("Using fast eval for Hardcore")
         hc <- potpars$hc
         # call evaluator for Strauss process
         counts <- strausscounts(U, X, hc, EqualPairs)
         forbid <- (counts != 0)
         if(!splitInf) {
           ## usual case
           v <- matrix(ifelseAB(forbid, -Inf, 0), ncol=1L)
         } else {
           ## separate hard core 
           v <- matrix(0, nrow=npoints(U), ncol=1L)
           attr(v, "-Inf") <- forbid
         }
         attr(v, "IsOffset") <- TRUE
         return(v)
       },
       Mayer=function(coeffs, self) {
         # second Mayer cluster integral
         hc <- self$par$hc
         return(pi * hc^2)
       },
       Percy=function(d, coeffs, par, ...) {
         ## term used in Percus-Yevick type approximation
         H <- par$hc
         t <- abs(d/(2*H))
         t <- pmin.int(t, 1)
         y <- 2 * H^2 * (pi - acos(t) + t * sqrt(1 - t^2))
         return(y)
       }
  )
  class(BlankHardcore) <- "interact"
  
  Hardcore <- function(hc=NA) {
    instantiate.interact(BlankHardcore, list(hc=hc))
  }

  Hardcore <- intermaker(Hardcore, BlankHardcore)
  
  Hardcore
})
