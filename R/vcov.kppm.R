#
# vcov.kppm
#
#  vcov method for kppm objects
#
#   Original code: Abdollah Jalilian
#
#   $Revision: 1.16 $  $Date: 2024/01/12 00:50:36 $
#

vcov.kppm <- function(object, ...,
                      what=c("vcov", "corr", "fisher"),
                      fast = NULL, rmax = NULL, eps.rmax = 0.01,
                      verbose = TRUE)
{
  what <- if(missing(what)) "vcov" else
          match.arg(what, c("vcov", "corr", "fisher", "internals", "all"))
  verifyclass(object, "kppm")
  fast.given <- !is.null(fast)
  #' secret argument (eg for testing)
  splitup <- resolve.1.default(list(splitup=FALSE), list(...))
  #'
  if(is.null(object$improve)) {
    ## Normal composite likelihood (poisson) case
    ## extract composite likelihood results
    po <- object$po
    ## ensure it was fitted with quadscheme
    if(is.null(getglmfit(po))) {
      warning("Re-fitting model with forcefit=TRUE")
      po <- update(po, forcefit=TRUE)
    }
    ## extract quadrature scheme information
    Q <- quad.ppm(po)
    U <- union.quad(Q)
    nU <- npoints(U)
    wt <- w.quad(Q)
    ## compute fitted intensity values
    lambda <- fitted(po, type="lambda")
    ## extract covariate values
    Z <- model.matrix(po)
    ## trap NA covariate values
    if(anyNA(Z)) {
      bad <- !complete.cases(Z)      
      Z[bad,] <- 0
      warning(paste(percentage(mean(bad)),
                    paren(paste(sum(bad), "out of", length(bad))),
                    "quadrature points had NA covariate values",
                    "and were ignored in the variance calculation"),
              call.=FALSE)
    }
    ## evaluate integrand
    ff <- Z * lambda * wt
    ## trap NA values of integrand
    if(anyNA(ff)) {
      bad <- !complete.cases(ff)
      ff[bad,] <- 0
    }
    ## extract pcf
    g <- pcfmodel(object)
    ## resolve options for algorithm
    maxmat <- spatstat.options("maxmatrix")
    if(!fast.given) {
      fast <- (nU^2 > maxmat)
    } else stopifnot(is.logical(fast))
    ## attempt to compute large matrix: pair correlation function minus 1
    if(!fast) {
      gminus1 <- there.is.no.try(
        matrix(g(c(pairdist(U))) - 1, nU, nU)
        )
    } else {
      if(is.null(rmax)){
        diamwin <- diameter(as.owin(U))
        fnc <- get("fnc", envir = environment(improve.kppm))
        rmax <- if(fnc(diamwin, eps.rmax, g) >= 0) diamwin else
                  uniroot(fnc, lower = 0, upper = diamwin,
                          eps=eps.rmax, g=g)$root
      }
      cp <- there.is.no.try(
        crosspairs(U,U,rmax,what="ijd")
        )
      gminus1 <- if(is.null(cp)) NULL else
                 sparseMatrix(i=cp$i, j=cp$j,
                              x=g(cp$d) - 1,
                              dims=c(nU, nU))
    }
    ## compute quadratic form
    if(!splitup && !is.null(gminus1)) {
      E <- t(ff) %*% gminus1 %*% ff
    } else {
      ## split calculation of (gminus1 %*% ff) into blocks
      nrowperblock <- max(1, floor(maxmat/nU))
      nblocks <- ceiling(nU/nrowperblock)
      g1ff <- NULL
      if(verbose) {
        splat("Splitting large matrix calculation into", nblocks, "blocks")
        pstate <- list()
      }
      if(!fast) {
        for(k in seq_len(nblocks)) {
          if(verbose) pstate <- progressreport(k, nblocks, state=pstate)
          istart <- nrowperblock * (k-1) + 1
          iend   <- min(nrowperblock * k, nU)
          ii <- istart:iend
          gm1 <- matrix(g(c(crossdist(U[ii], U))) - 1, iend-istart+1, nU)
          g1ff <- rbind(g1ff, gm1 %*% ff)
        }
      } else {
        for(k in seq_len(nblocks)) {
          if(verbose) pstate <- progressreport(k, nblocks, state=pstate)
          istart <- nrowperblock * (k-1) + 1
          iend   <- min(nrowperblock * k, nU)
          ii <- istart:iend
          cp <- crosspairs(U[ii], U, rmax, what="ijd")
          gm1 <- sparseMatrix(i=cp$i, j=cp$j,
                              x=g(cp$d) - 1,
                              dims=c(iend-istart+1, nU))
          g1ff <- rbind(g1ff, as.matrix(gm1 %*% ff))
        }
      }
      E <- t(ff) %*% g1ff
    }
    ## asymptotic covariance matrix in the Poisson case
    J <- t(Z) %*% ff
    J.inv <- try(solve(J))
    ## could be singular 
    if(inherits(J.inv, "try-error")) {
      if(what == "internals" || what == "all") {
        return(list(ff=ff, J=J, E=E, J.inv=NULL))
      } else {
        return(NULL)
      }
    }
    ## asymptotic covariance matrix in the clustered case
    vc <- J.inv + J.inv %*% E %*% J.inv
  } else {
    ## Case of quasi-likelihood (or other things from improve.kppm)
    run <- is.null(object$vcov) ||
      (!is.null(fast) && (fast != object$improve$fast.vcov))
    if(run){
      ## Calculate vcov if it hasn't already been so
      ## or if option fast differs from fast.vcov
      args <- object$improve
      internal <- what=="internals"
      if(!is.null(fast))
        args$fast.vcov <- fast
      object <- with(args,
                     improve.kppm(object, type = type,
                                  rmax = rmax, dimyx = dimyx,
                                  fast = fast, vcov = TRUE,
                                  fast.vcov = fast.vcov,
                                  maxIter = 0,
                                  save.internals = internal))
    }
    vc <- object$vcov
  }

  ## Convert from Matrix to ordinary matrix:
  vc <- as.matrix(vc)
  
  switch(what,
         vcov={ return(vc) },
         corr={
           sd <- sqrt(diag(vc))
           co <- vc/outer(sd, sd, "*")
           return(co)
         },
         fisher={
           fish <- there.is.no.try(solve(vc))
           return(fish)
         },
         internals={
           return(list(ff=ff, J=J, E=E, J.inv=J.inv, vc=vc))
         },
         all={
           sd <- sqrt(diag(vc))
           co <- vc/outer(sd, sd, "*")
           fish <- there.is.no.try(solve(vc))
           internals <- list(ff=ff, J=J, E=E, J.inv=J.inv, vc=vc)
           return(list(vcov      = vc,
                       sd        = sd,
                       co        = co,
                       fish      = fish,
                       internals = internals))
         })
  stop(paste("Unrecognised option: what=", what))
}
