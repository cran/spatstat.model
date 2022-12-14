# 
#  fitted.mppm.R
#
# method for 'fitted' for mppm objects
#
#   $Revision: 1.4 $   $Date: 2021/12/27 10:20:31 $
# 

fitted.mppm <- function(object, ...,
                        type="lambda", dataonly=FALSE) {
#  sumry <- summary(object)

  type <- pickoption("type", type, c(lambda="lambda",
                                     cif   ="lambda",
                                     trend ="trend"), multi=FALSE, exact=FALSE)
  # extract fitted model object and data frame
  glmfit  <- object$Fit$FIT
  glmdata <- object$Fit$moadf
  # interaction names
  Vnames <- unlist(object$Fit$Vnamelist)
  interacting <- (length(Vnames) > 0)
  # row identifier
  id <- glmdata$id

  ## secret arguments
  dotargs <- list(...)
  new.coef <- dotargs$new.coef
  dropcoef <- isTRUE(dotargs$dropcoef)
    
  # Modification of `glmdata' may be required
  if(interacting) 
    switch(type,
           trend={
             # zero the interaction statistics
             glmdata[ , Vnames] <- 0
           },
           lambda={
             # Find any dummy points with zero conditional intensity
             forbid <- matrowany(as.matrix(glmdata[, Vnames]) == -Inf)
             # exclude from predict.glm
             glmdata <- glmdata[!forbid, ]
           })

  # Possibly updated coefficients
  coeffs <- adaptcoef(new.coef, coef(object), drop=dropcoef)
  
  # Compute predicted [conditional] intensity values
  values <- GLMpredict(glmfit, glmdata, coeffs, !is.null(new.coef), type="response")
  # Note: the `glmdata' argument is necessary in order to obtain
  # predictions at all quadrature points. If it is omitted then
  # we would only get predictions at the quadrature points j
  # where glmdata$SUBSET[j]=TRUE.

  if(interacting && type=="lambda") {
   # reinsert zeroes
    vals <- numeric(length(forbid))
    vals[forbid] <- 0
    vals[!forbid] <- values
    values <- vals
  }

  names(values) <- NULL
  
  if(dataonly) {
    # extract only data values
    isdata <- (glmdata$.mpl.Y != 0)
    values <- values[isdata]
    id     <- id[isdata]
  }

  return(split(values, id))
}
