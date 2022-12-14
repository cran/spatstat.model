# 
#  fitted.ppm.R
#
# method for 'fitted' for ppm objects
#
#   $Revision: 1.19 $   $Date: 2022/01/20 02:05:37 $
# 

fitted.ppm <- function(object, ..., type="lambda", dataonly=FALSE,
                       new.coef=NULL, leaveoneout=FALSE,
                       drop=FALSE, check=TRUE, repair=TRUE,
		       ignore.hardcore=FALSE, dropcoef=FALSE) {
  verifyclass(object, "ppm")

  if(check && damaged.ppm(object)) {
    if(!repair)
      stop("object format corrupted; try update(object, use.internal=TRUE)")
    message("object format corrupted; repairing it.")
    object <- update(object, use.internal=TRUE)
  }

  if(leaveoneout) {
    ## Leave-one-out calculation for data points only
    if(missing(dataonly)) dataonly <- TRUE
    if(!dataonly)
      stop("Leave-one-out calculation requires dataonly=TRUE")
    if(!is.null(new.coef))
      stop("Leave-one-out calculation requires new.coef=NULL")
    if(length(coef(object)) == 0)
      warning("Model has no fitted coefficients; using leaveoneout=FALSE")
  }
  
  coeffs <- adaptcoef(new.coef, coef(object), drop=dropcoef)
  
  uniform <- is.poisson.ppm(object) && no.trend.ppm(object)

  typelist <- c("lambda", "cif",    "trend", "link")
  typevalu <- c("lambda", "lambda", "trend", "link")
  if(is.na(m <- pmatch(type, typelist)))
    stop(paste("Unrecognised choice of ", sQuote("type"),
               ": ", sQuote(type), sep=""))
  type <- typevalu[m]
  
  if(uniform) {
    lambda <- exp(coeffs[[1L]])
    Q <- quad.ppm(object, drop=drop)
    lambda <- rep.int(lambda, n.quad(Q))
  } else {
    glmdata <- getglmdata(object, drop=drop)
    glmfit  <- getglmfit(object)
    Vnames <- object$internal$Vnames
    interacting <- (length(Vnames) != 0)
    
    # Modification of `glmdata' may be required
    if(interacting) 
      switch(type,
           trend={
             ## zero the interaction statistics
             glmdata[ , Vnames] <- 0
           },
           link=,
           lambda={
             if(!ignore.hardcore) {
               ## Find any dummy points with zero conditional intensity
               forbid <- matrowany(as.matrix(glmdata[, Vnames]) == -Inf)
               ## Exclude these locations from predict.glm
               glmdata <- glmdata[!forbid, ]
	     } else {
	       ## Compute positive part of cif
               Q <- quad.ppm(object, drop=drop)
               X <- Q[["data"]]
               U <- union.quad(Q)
               E <- equalpairs.quad(Q)
               eva <- evalInteraction(X, U, E,
                                      object$interaction,
                                      object$correction, 
                                      splitInf=TRUE)
	       forbid <- attr(eva, "-Inf") %orifnull% logical(npoints(U))
	       ## Use positive part of interaction
               if(ncol(eva) != length(Vnames)) 
                 stop(paste("Internal error: evalInteraction yielded",
                            ncol(eva), "variables instead of", length(Vnames)),
                      call.=FALSE)
	       glmdata[,Vnames] <- as.data.frame(eva)
	     }
           })

    # Compute predicted [conditional] intensity values
    changecoef <- !is.null(new.coef) || (object$method != "mpl")
    lambda <- GLMpredict(glmfit, glmdata, coeffs, changecoef=changecoef,
                         type = ifelse(type == "link", "link", "response"))

    # Note: the `newdata' argument is necessary in order to obtain
    # predictions at all quadrature points. If it is omitted then
    # we would only get predictions at the quadrature points j
    # where glmdata$SUBSET[j]=TRUE. Assuming drop=FALSE.

    if(interacting && type=="lambda" && !ignore.hardcore) {
     # reinsert zeroes
      lam <- numeric(length(forbid))
      lam[forbid] <- 0
      lam[!forbid] <- lambda
      lambda <- lam
    }

  }
  if(dataonly)
    lambda <- lambda[is.data(quad.ppm(object))]

  if(leaveoneout) {
    ## Perform leverage calculation
    dfb <- dfbetas(object, multitypeOK=TRUE)
    delta <- with(dfb, 'discrete')[with(dfb, 'is.atom'),,drop=FALSE]
    ## adjust fitted value
    mom <- model.matrix(object)[is.data(quad.ppm(object)),,drop=FALSE]
    if(type == "trend" && !uniform && interacting)
      mom[, Vnames] <- 0
    lambda <- lambda * exp(- rowSums(delta * mom))
  }
  lambda <- unname(as.vector(lambda))
  return(lambda)
}

adaptcoef <- function(new.coef, fitcoef, drop=FALSE) {
  ## a replacement for 'fitcoef' will be extracted from 'new.coef' 
  if(is.null(new.coef)) {
    coeffs <- fitcoef
  } else if(length(new.coef) == length(fitcoef)) {
    coeffs <- new.coef
  } else {
    fitnames <- names(fitcoef)
    newnames <- names(new.coef)
    if(is.null(newnames) || is.null(fitnames))
      stop(paste("Argument new.coef has wrong length",
                 length(new.coef), ": should be", length(fitcoef)),
           call.=FALSE)
    absentnames <- setdiff(fitnames, newnames)
    excessnames <- setdiff(newnames, fitnames)
    if((nab <- length(absentnames)) > 0)
      stop(paste(ngettext(nab, "Coefficient", "Coefficients"),
                 commasep(sQuote(absentnames)),
                 ngettext(nab, "is", "are"),
                 "missing from new.coef"),
           call.=FALSE)
    if(!drop && ((nex <- length(excessnames)) > 0)) 
      stop(paste(ngettext(nex, "Coefficient", "Coefficients"),
                 commasep(sQuote(excessnames)),
                 ngettext(nab, "is", "are"),
                 "present in new.coef but not in coef(object)"),
           call.=FALSE)
    #' extract only the relevant coefficients
    coeffs <- new.coef[fitnames]
  }
  return(coeffs)
}

