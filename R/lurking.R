# Lurking variable plot for arbitrary covariate.
#
#
# $Revision: 1.75 $ $Date: 2022/02/12 09:11:35 $
#

lurking <- function(object, ...) {
  UseMethod("lurking")
}

lurking.ppp <- lurking.ppm <- function(object, covariate,
                          type="eem",
                          cumulative=TRUE,
                          ..., 
                          plot.it=TRUE,
                          plot.sd=is.poisson(object), 
                          clipwindow=default.clipwindow(object),
                          rv = NULL,
                          envelope=FALSE, nsim=39, nrank=1,
                          typename,
                          covname, oldstyle=FALSE,
                          check=TRUE,
                          verbose=TRUE,
                          nx=128,
                          splineargs=list(spar=0.5),
                          internal=NULL) {
  cl <- match.call()
  clenv <- parent.frame()
    
  ## validate object
  if(is.ppp(object)) {
    X <- object
    object <- ppm(X ~1, forcefit=TRUE)
    dont.complain.about(X)
  } else verifyclass(object, "ppm")
  
  ## default name for covariate
  if(missing(covname) || is.null(covname)) {
    co <- cl$covariate
    covname <- if(is.name(co)) as.character(co) else
               if(is.expression(co)) format(co[[1]]) else NULL
  }
  
    
  Xsim <- NULL
  if(!identical(envelope, FALSE)) {
    ## compute simulation envelope
    if(!identical(envelope, TRUE)) {
      ## some kind of object
      Y <- envelope
      if(is.list(Y) && all(sapply(Y, is.ppp))) {
        Xsim <- Y
        envelope <- TRUE
      } else if(inherits(Y, "envelope")) {
        Xsim <- attr(Y, "simpatterns")
        if(is.null(Xsim))
          stop("envelope does not contain simulated point patterns")
        envelope <- TRUE
      } else stop("Unrecognised format of argument: envelope")
      nXsim <- length(Xsim)
      if(missing(nsim) && (nXsim < nsim)) {
        warning(paste("Only", nXsim, "simulated patterns available"))
        nsim <- nXsim
      }
    }
  }
    
  ## may need to refit the model
  if(plot.sd && is.null(getglmfit(object)))
    object <- update(object, forcefit=TRUE, use.internal=TRUE)

  ## match type argument
  type <- pickoption("type", type,
                     c(eem="eem",
                       raw="raw",
                       inverse="inverse",
                       pearson="pearson",
                       Pearson="pearson"))
  if(missing(typename))
    typename <- switch(type,
                       eem="exponential energy weights",
                       raw="raw residuals",
                       inverse="inverse-lambda residuals",
                       pearson="Pearson residuals")

  ## extract spatial locations
  Q <- quad.ppm(object)
  ## datapoints <- Q$data
  quadpoints <- union.quad(Q)
  Z <- is.data(Q)
  wts <- w.quad(Q)
  ## subset of quadrature points used to fit model
  subQset <- getglmsubset(object)
  if(is.null(subQset)) subQset <- rep.int(TRUE, n.quad(Q))
  
  #################################################################
  ## compute the covariate
    
  if(is.im(covariate)) {
    covvalues <- covariate[quadpoints, drop=FALSE]
    covrange <- internal$covrange %orifnull% range(covariate, finite=TRUE)
  } else if(is.vector(covariate) && is.numeric(covariate)) {
    covvalues <- covariate
    covrange <- internal$covrange %orifnull% range(covariate, finite=TRUE)
    if(length(covvalues) != quadpoints$n)
      stop("Length of covariate vector,", length(covvalues), "!=",
           quadpoints$n, ", number of quadrature points")
  } else if(is.expression(covariate)) {
    ## Expression involving covariates in the model
    glmdata <- getglmdata(object)
    if(is.null(glmdata)) {
      ## default 
      glmdata <- data.frame(x=quadpoints$x, y=quadpoints$y)
      if(is.marked(quadpoints))
        glmdata$marks <- marks(quadpoints)
    } else if(is.data.frame(glmdata)) {
      ## validate
      if(nrow(glmdata) != npoints(quadpoints))
        stop("Internal error: nrow(glmdata) =", nrow(glmdata),
             "!=", npoints(quadpoints), "= npoints(quadpoints)")
    } else stop("Internal error: format of glmdata is not understood")
    ## ensure x and y are in data frame 
    if(!all(c("x","y") %in% names(glmdata))) {
      glmdata$x <- quadpoints$x
      glmdata$y <- quadpoints$y
    } 
    if(!is.null(object$covariates)) {
      ## Expression may involve an external covariate that's not used in model
      neednames <- all.vars(covariate)
      if(!all(neednames %in% colnames(glmdata))) {
        moredata <- mpl.get.covariates(object$covariates, quadpoints,
                                       covfunargs=object$covfunargs)
        use <- !(names(moredata) %in% colnames(glmdata))
        glmdata <- cbind(glmdata, moredata[,use,drop=FALSE])
      }
    }
    ## Evaluate expression
    sp <- parent.frame()
    covvalues <- eval(covariate, envir= glmdata, enclos=sp)
    covrange <- internal$covrange %orifnull% range(covvalues, finite=TRUE)
    if(!is.numeric(covvalues))
      stop("The evaluated covariate is not numeric")
  } else 
    stop(paste("The", sQuote("covariate"), "should be either",
               "a pixel image, an expression or a numeric vector"))

  #################################################################
  ## Secret exit
  if(identical(internal$getrange, TRUE))
    return(covrange)
    
  ################################################################
  ## Residuals/marks attached to appropriate locations.
  ## Stoyan-Grabarnik weights are attached to the data points only.
  ## Others (residuals) are attached to all quadrature points.
  resvalues <- 
    if(!is.null(rv)) rv
    else if(type=="eem") eem(object, check=check)
    else residuals(object, type=type, check=check)

  if(inherits(resvalues, "msr")) {
    ## signed or vector-valued measure; extract increment masses
    resvalues <- resvalues$val
    if(ncol(as.matrix(resvalues)) > 1)
      stop("Not implemented for vector measures; use [.msr to split into separate components")
  }

  ## NAMES OF THINGS
  ## name of the covariate
  if(is.null(covname)) 
    covname <- if(is.expression(covariate)) covariate else "covariate"
  ## type of residual/mark
  if(missing(typename)) 
    typename <- if(!is.null(rv)) "rv" else ""

  clip <-
    (!is.poisson.ppm(object) || !missing(clipwindow)) &&
    !is.null(clipwindow)

  ## CALCULATE
  stuff <- LurkEngine(object=object,
                      type=type, cumulative=cumulative, plot.sd=plot.sd,
                      quadpoints=quadpoints,
                      wts=wts,
                      Z=Z,
                      subQset=subQset,
                      covvalues=covvalues,
                      resvalues=resvalues,
                      clip=clip,
                      clipwindow=clipwindow,
                      cov.is.im=is.im(covariate),
                      covrange=covrange,
                      typename=typename,
                      covname=covname,
                      cl=cl, clenv=clenv,
                      oldstyle=oldstyle, check=check, verbose=verbose,
                      nx=nx, splineargs=splineargs,
                      envelope=envelope, nsim=nsim, nrank=nrank, Xsim=Xsim,
                      internal=internal)
    
  ## ---------------  PLOT ----------------------------------
  if(plot.it && inherits(stuff, "lurk")) {
    plot(stuff, ...)
    return(invisible(stuff))
  } else {
    return(stuff)
  }
}

# ...........  calculations common to all methods .........................

LurkEngine <- function(object, type, cumulative=TRUE, plot.sd=TRUE, 
                       quadpoints, wts, Z, subQset, 
                       covvalues, resvalues, 
                       clip, clipwindow, cov.is.im=FALSE, covrange, 
                       typename, covname,
                       cl, clenv,
                       oldstyle=FALSE, check=TRUE,
                       verbose=FALSE, nx, splineargs,
                       envelope=FALSE, nsim=39, nrank=1, Xsim=list(),
                       internal=list(), checklength=TRUE) {
  stopifnot(is.ppm(object) || is.slrm(object))
  ## validate covariate values
  covvalues <- as.numeric(covvalues)
  resvalues <- as.numeric(resvalues)
  if(checklength) {
    nqu <- npoints(quadpoints)
    nco <- length(covvalues)
    nre <- length(resvalues)
    nwt <- length(wts)
    nZ  <- length(Z)
    should <- if(type == "eem") c(nco, nwt, nZ) else c(nco, nwt, nZ, nre) 
    if(!all(should == nqu)) {
      typeblurb <- paste("type =", sQuote(type))
      typeblurb <- paren(typeblurb, "[")
      gripe1 <- paste("Failed initial data check",
                      paste0(typeblurb, ":"))
      gripe2 <- paste("!=", nqu, "= npoints(quadpoints)")
      if(nco != nqu)
        stop(paste(gripe1, "length(covvalues) =", nco, gripe2))
      if(nwt != nqu)
        stop(paste(gripe1, "length(wts) =", nwt, gripe2))
      if(nZ != nqu)
        stop(paste(gripe1, "length(Z) =", nZ, gripe2))
    }
    if(type == "eem" && nre != sum(Z)) 
      stop(paste("Failed initial data check [type='eem']: ",
                 "length(resvalues) =", nre, 
                 "!=", sum(Z), "= sum(Z)"))
  }
  ##
  nbg <- is.na(covvalues)
  if(any(offending <- nbg & subQset)) {
    if(cov.is.im) {
      warning(paste(sum(offending), "out of", length(offending),
                    "quadrature points discarded because",
                    ngettext(sum(offending), "it lies", "they lie"),
                    "outside the domain of the covariate image"))
    } else {
      warning(paste(sum(offending), "out of", length(offending),
                    "covariate values discarded because",
                    ngettext(sum(offending), "it is NA", "they are NA")))
    }
  }
  ## remove data with invalid covariate values
  ok <- !nbg & subQset
  if(!(allok <- all(ok))) {
    quadpoints <- quadpoints[ok]
    covvalues <- covvalues[ok]
    okdata <- ok[Z]   # which original data points are retained
    ## Zok    <- Z & ok # which original quadrature pts are retained as data pts
    Z      <- Z[ok]   # which of the retained quad pts are data pts
    wts    <- wts[ok]
    resvalues <- resvalues[if(type == "eem") okdata else ok]
  } 
  if(any(is.infinite(covvalues) | is.nan(covvalues)))
    stop("covariate contains Inf or NaN values")

  ## now determine the data points
  datapoints <- quadpoints[Z]

  ## Quadrature points marked by covariate value
  covq <- quadpoints %mark% as.numeric(covvalues)
  
  if(type == "eem") {
    ## data points marked by residuals and covariate
    res <- datapoints %mark% as.numeric(resvalues)
    covres <- datapoints %mark% (as.numeric(covvalues)[Z])
  } else {
    ## quadrature points marked by residuals and covariate
    res <- quadpoints %mark% as.numeric(resvalues)
    covres <- quadpoints %mark% as.numeric(covvalues)
  }

  ## Clip to subwindow if needed
  if(clip) {
    covq <- covq[clipwindow]
    res <- res[clipwindow]
    covres <- covres[clipwindow]
    clipquad <- inside.owin(quadpoints, w=clipwindow)
    wts <- wts[ clipquad ]
    Z  <- Z[ clipquad ]
  }

  ## handle internal data
  saveworking <- isTRUE(internal$saveworking)
  Fisher      <- internal$Fisher  # possibly from a larger model
  covrange    <- internal$covrange

  ## >>>>>>>>>>>>  START ANALYSIS <<<<<<<<<<<<<<<<<<<<<<<<
  ## -----------------------------------------------------------------------
  ## (A) EMPIRICAL CUMULATIVE FUNCTION
  ## based on data points if type="eem", otherwise on quadrature points
  
  ## Reorder the data/quad points in order of increasing covariate value
  ## and then compute the cumulative sum of their residuals/marks
  markscovres <- marks(covres)
  o <- fave.order(markscovres)
  covsort <- markscovres[o]
  marksort <- marks(res)[o]
  cummark <- cumsum(ifelse(is.na(marksort), 0, marksort))
  if(anyDuplicated(covsort)) {
    right <- !duplicated(covsort, fromLast=TRUE)
    covsort <- covsort[right]
    cummark <- cummark[right]
  }
  ## we'll plot(covsort, cummark) in the cumulative case

  ## (B) THEORETICAL MEAN CUMULATIVE FUNCTION
  ## based on all quadrature points
    
  ## Range of covariate values
  covqmarks <- marks(covq)
  covrange <- covrange %orifnull% range(covqmarks, na.rm=TRUE)
  if(diff(covrange) > 0) {
    ## Suitable breakpoints
    cvalues <- seq(from=covrange[1L], to=covrange[2L], length.out=nx)
    csmall <- cvalues[1L] - diff(cvalues[1:2])
    cbreaks <- c(csmall, cvalues)
    ## cumulative area as function of covariate values
    covclass <- cut(covqmarks, breaks=cbreaks)
    increm <- tapply(wts, covclass, sum)
    cumarea <- cumsum(ifelse(is.na(increm), 0, increm))
  } else {
    ## Covariate is constant
    cvalues <- covrange[1L]
    covclass <- factor(rep(1, length(wts)))
    cumarea <- increm <- sum(wts)
  }
  ## compute theoretical mean (when model is true)
  mean0 <- if(type == "eem") cumarea else numeric(length(cumarea))
  ## we'll plot(cvalues, mean0) in the cumulative case
  
  ## (A'),(B') DERIVATIVES OF (A) AND (B)
  ##  Required if cumulative=FALSE  
  ##  Estimated by spline smoothing (with x values jittered)
  if(!cumulative) {
    ## fit smoothing spline to (A) 
    ss <- do.call(smooth.spline,
                  append(list(covsort, cummark),
                         splineargs)
                  )
    ## estimate derivative of (A)
    derivmark <- predict(ss, covsort, deriv=1)$y 
    ## similarly for (B) 
    ss <- do.call(smooth.spline,
                  append(list(cvalues, mean0),
                         splineargs)
                  )
    derivmean <- predict(ss, cvalues, deriv=1)$y
  }
  
  ## -----------------------------------------------------------------------
  ## Store what will be plotted
  
  if(cumulative) {
    empirical <- data.frame(covariate=covsort, value=cummark)
    theoretical <- data.frame(covariate=cvalues, mean=mean0)
  } else {
    empirical <- data.frame(covariate=covsort, value=derivmark)
    theoretical <- data.frame(covariate=cvalues, mean=derivmean)
  }

  ## ------------------------------------------------------------------------
  
  ## (C) STANDARD DEVIATION if desired
  ## (currently implemented only for Poisson)
  ## (currently implemented only for cumulative case)

  if(plot.sd && !is.poisson(object))
    warning(paste("standard deviation is calculated for Poisson model;",
                  "not valid for this model"))

  if(plot.sd && cumulative) {
    if(is.ppm(object)) {
      ## Fitted intensity at quadrature points
      lambda <- fitted(object, type="trend", check=check)
      if(!allok) lambda <- lambda[ok]
      ## Fisher information for coefficients
      asymp <- vcov(object,what="internals")
      Fisher <- Fisher %orifnull% asymp$fisher
      ## Local sufficient statistic at quadrature points
      suff <- asymp$suff
      if(!allok && !is.null(suff)) suff <- suff[ok, , drop=FALSE]
    } else if(is.slrm(object)) {
      ## Fitted intensity at quadrature points
      lambda <- predict(object, type="intensity")[quadpoints, drop=FALSE]
      ## Fisher information for coefficients
      Fisher <- Fisher %orifnull% vcov(object, what="Fisher")
      ## Sufficient statistic at quadrature points
      suff <- model.matrix(object)
      if(!allok && !is.null(suff)) suff <- suff[ok, , drop=FALSE]
    } else stop("object should be a ppm or slrm")
    ## Clip if required
    if(clip) {
      lambda <- lambda[clipquad]
      if(!is.null(suff))
        suff   <- suff[clipquad, , drop=FALSE]  ## suff is a matrix
    }
    ## First term: integral of lambda^(2p+1)
    switch(type,
           pearson={
             varI <- cumarea
           },
           raw={
             ## Compute sum of w*lambda for quadrature points in each interval
             dvar <- tapply(wts * lambda, covclass, sum)
             ## tapply() returns NA when the table is empty
             dvar[is.na(dvar)] <- 0
             ## Cumulate
             varI <- cumsum(dvar)
           },
           inverse=, ## same as eem
           eem={
             ## Compute sum of w/lambda for quadrature points in each interval
             dvar <- tapply(wts / lambda, covclass, sum)
             ## tapply() returns NA when the table is empty
             dvar[is.na(dvar)] <- 0
             ## Cumulate
             varI <- cumsum(dvar)
           })

    if(!oldstyle) {
      ## check feasibility of variance calculations
      if(length(Fisher) == 0 || length(suff) == 0) {
        warning("Model has no fitted coefficients; using oldstyle=TRUE")
        oldstyle <- TRUE
      } else {
        ## variance-covariance matrix of coefficients
        V <- try(solve(Fisher), silent=TRUE)
        if(inherits(V, "try-error")) {
          warning("Fisher information is singular; reverting to oldstyle=TRUE")
          oldstyle <- TRUE
        }
      }
    }

    if(!oldstyle && any(dim(V) != ncol(suff))) {
      #' drop rows and columns
      nama <- colnames(suff)
      V <- V[nama, nama, drop=FALSE]
    }
    
    working <- NULL
      
    ## Second term: B' V B
    if(oldstyle) {
      varII <- 0
      if(saveworking) 
        working <- data.frame(varI=varI)
    } else {
      ## lamp = lambda^(p + 1)
      lamp <- switch(type,
                     raw     = lambda, 
                     pearson = sqrt(lambda),
                     inverse =,
                     eem     = as.integer(lambda > 0))
      ## Compute sum of w * lamp * suff for quad points in intervals
      Bcontrib <- as.vector(wts * lamp) * suff
      dB <- matrix(, nrow=length(cumarea), ncol=ncol(Bcontrib),
                   dimnames=list(NULL, colnames(suff)))
      for(j in seq_len(ncol(dB))) 
        dB[,j] <- tapply(Bcontrib[,j], covclass, sum, na.rm=TRUE)
      ## tapply() returns NA when the table is empty
      dB[is.na(dB)] <- 0
      ## Cumulate columns
      B <- apply(dB, 2, cumsum)
      if(!is.matrix(B)) B <- matrix(B, nrow=1)
      ## compute B' V B for each i 
      varII <- quadform(B, V)
      ##  was:   varII <- diag(B %*% V %*% t(B))
      if(saveworking) 
        working <- cbind(data.frame(varI=varI, varII=varII),
                         as.data.frame(B))
    }
    ##
    ## variance of residuals
    varR <- varI - varII
    ## trap numerical errors
    nbg <- (varR < 0)
    if(any(nbg)) {
      ran <- range(varR)
      varR[nbg] <- 0
      relerr <- abs(ran[1L]/ran[2L])
      nerr <- sum(nbg)
      if(relerr > 1e-6) {
        warning(paste(nerr, "negative",
                      ngettext(nerr, "value (", "values (min="),
                      signif(ran[1L], 4), ")",
                      "of residual variance reset to zero",
                      "(out of", length(varR), "values)"))
      }
    }
    theoretical$sd <- sqrt(varR)
  }

  ## 
  if(envelope) {
    ## compute envelopes by simulation
    cl$plot.it <- FALSE
    cl$envelope <- FALSE
    cl$rv <- NULL
    if(is.null(Xsim))
      Xsim <- simulate(object, nsim=nsim, progress=verbose)
    values <- NULL
    if(verbose) {
      cat("Processing.. ")
      state <- list()
    }
    for(i in seq_len(nsim)) {
      ## evaluate lurking variable plot for simulated pattern
      cl$object <- update(object, Xsim[[i]])
      result.i <- eval(cl, clenv)
      ## interpolate empirical values onto common sequence
      f.i <- with(result.i$empirical,
                  approxfun(covariate, value, rule=2))
      val.i <- f.i(theoretical$covariate)
      values <- cbind(values, val.i)
      if(verbose) state <- progressreport(i, nsim, state=state)
    }
    if(verbose) cat("Done.\n")
    hilo <- if(nrank == 1) apply(values, 1, range) else
            apply(values, 1, orderstats, k=c(nrank, nsim-nrank+1))
    theoretical$upper <- hilo[1L,]
    theoretical$lower <- hilo[2L,]
  }
  ## ----------------  RETURN COORDINATES ----------------------------
  stuff <- list(empirical=empirical,
                theoretical=theoretical)
  attr(stuff, "info") <- list(typename=typename,
                              cumulative=cumulative,
                              covrange=covrange,
                              covname=covname,
                              oldstyle=oldstyle)
  if(saveworking) attr(stuff, "working") <- working
  class(stuff) <- "lurk"
  return(stuff)
}

# plot a lurk object


plot.lurk <- function(x, ..., shade="grey") {
  xplus <- append(x, attr(x, "info"))
  with(xplus, {
    ## work out plot range
    mr <- range(0, empirical$value, theoretical$mean, na.rm=TRUE)
    if(!is.null(theoretical$sd))
      mr <- range(mr,
                  theoretical$mean + 2 * theoretical$sd,
                  theoretical$mean - 2 * theoretical$sd,
                  na.rm=TRUE)
    if(!is.null(theoretical$upper))
      mr <- range(mr, theoretical$upper, theoretical$lower, na.rm=TRUE)

    ## start plot
    vname <- paste(if(cumulative)"cumulative" else "marginal", typename)
    do.call(plot,
            resolve.defaults(
              list(covrange, mr),
              list(type="n"),
              list(...),
              list(xlab=covname, ylab=vname)))
    ## Envelopes
    if(!is.null(theoretical$upper)) {
      Upper <- theoretical$upper
      Lower <- theoretical$lower
    } else if(!is.null(theoretical$sd)) {
      Upper <- with(theoretical, mean+2*sd)
      Lower <- with(theoretical, mean-2*sd)
    } else Upper <- Lower <- NULL
    if(!is.null(Upper) && !is.null(Lower)) {
      xx <- theoretical$covariate
      if(!is.null(shade)) {
        ## shaded envelope region
        shadecol <- if(is.colour(shade)) shade else "grey"
        xx <- c(xx,    rev(xx))
        yy <- c(Upper, rev(Lower))
        dont.complain.about(yy)
        do.call.matched(polygon,
                        resolve.defaults(list(x=quote(xx), y=quote(yy)),
                                         list(...),
                                         list(border=shadecol, col=shadecol)))
      } else {
        do.call(lines,
                resolve.defaults(
                  list(x = quote(xx), y=quote(Upper)),
                  list(...),
                  list(lty=3)))
        do.call(lines,
                resolve.defaults(
                  list(x = quote(xx), y = quote(Lower)),
                  list(...),
                  list(lty=3)))
      }
    }
    ## Empirical
    lines(value ~ covariate, empirical, ...)
    ## Theoretical mean
    do.call(lines,
            resolve.defaults(
              list(mean ~ covariate, quote(theoretical)),
              list(...),
              list(lty=2)))
  })
  return(invisible(NULL))
}

#'  print a lurk object

print.lurk <- function(x, ...) {
  splat("Lurking variable plot (object of class 'lurk')")
  info <- attr(x, "info")
  with(info, {
    splat("Residual type: ", typename)
    splat("Covariate on horizontal axis: ", covname)
    splat("Range of covariate values: ", prange(covrange))
    splat(if(cumulative) "Cumulative" else "Non-cumulative", "plot")
  })
  has.bands <- !is.null(x$theoretical$upper)
  has.sd    <- !is.null(x$theoretical$sd)
  if(!has.bands && !has.sd) {
    splat("No confidence bands computed")
  } else {
    splat("Includes",
          if(has.sd) "standard deviation for" else NULL,
          "confidence bands")
    if(!is.null(info$oldstyle)) 
      splat("Variance calculation:",
            if(info$oldstyle) "old" else "new",
            "style")
  }
  return(invisible(NULL))
}
