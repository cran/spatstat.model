#'
#' rppm.R
#' 
#'  Recursive Partitioning for Point Process Models
#'
#'  $Revision: 1.24 $  $Date: 2023/02/14 04:25:45 $

rppm <- function(..., rpargs=list()) {
  ## do the equivalent of ppm(...)
  cl <- match.call()
  cl[[1]] <- as.name('ppm')
  if("rpargs" %in% names(cl)) cl$rpargs <- NULL
  cl$forcefit <- TRUE
  pfit <- eval(cl, envir=parent.frame())
  ## 
  if(!is.poisson(pfit))
    warning("Interpoint interaction will be ignored", call.=FALSE)
  df <- getglmdata(pfit)
  gf <- getglmfit(pfit)
  sf <- getglmsubset(pfit)
  rp <- do.call(rpart,
                resolve.defaults(list(formula=formula(gf),
                                      data=df,
                                      subset=sf,
                                      weights=df$.mpl.W),
                                 rpargs,
                                 list(method="poisson")))
  result <- list(pfit=pfit, rp=rp, rpargs=rpargs)
  class(result) <- c("rppm", class(result))
  return(result)
}

# undocumented
as.ppm.rppm <- function(object) { object$pfit }

print.rppm <- function(x, ...) {
  splat("Point process model with recursive partitioning")
  splat("Data:", sQuote(x$pfit$Qname))
  splat("Covariates:", commasep(sQuote(variablesinformula(formula(x$pfit)))))
  splat("Regression tree:")
  print(x$rp)
  invisible(NULL)
}

plot.rppm <- local({

  argsPlotRpart <- c("x", "uniform", "branch",
                     "compress", "margin", "minbranch")
  argsTextRpart <- c("splits", "label", "FUN", "all", "pretty",
                     "digits", "use.n", "fancy",
                     "fwidth", "fheight", "bg", "minlength")
  
  plot.rppm <- function(x, ..., what=c("tree", "spatial"), treeplot=NULL) {
    xname <- short.deparse(substitute(x))
    what <- match.arg(what)
    switch(what,
           tree = {
             xrp <- x$rp
             if(is.function(treeplot)) 
               return(treeplot(xrp, ...))
             dont.complain.about(xrp)
             out <- do.call.matched(plot,
                                    list(x=quote(xrp), ...),
                                    funargs=argsPlotRpart,
                                    extrargs=graphicsPars("plot"))
             # note: plot.rpart does not pass arguments to 'lines'
             do.call.matched(text,
                             list(x=quote(xrp), ...),
                             funargs=argsTextRpart,
                             extrargs=graphicsPars("text"))
           },
           spatial = {
             p <- predict(x)
             dont.complain.about(p)
             out <- do.call("plot",
                            resolve.defaults(list(x=quote(p)),
                                             list(...),
                                             list(main=xname)))
           })
    return(invisible(out))
  }

  plot.rppm

})


#' prune method

prune.rppm <- function(tree, ...) {
  tree$rp <- rpart::prune(tree$rp, ...)
  return(tree)
}

#' predict method

predict.rppm <- function(object, ...) {
  model <- object$pfit
  tree  <- object$rp
  #' assemble covariates for prediction, using rules of predict.ppm
  co <- predict(model, ..., type="covariates", check=FALSE, repair=FALSE)
  newdata <- co$newdata
  masque  <- co$mask
  #' perform prediction using the tree
  pred <- predict(tree, newdata=co$newdata)
  #' pack up appropriately
  if(is.null(masque))
    return(pred)
  imago <- as.im(masque, value=1.0)
  if(!is.marked(model)) {
    out <- imago
    out[] <- pred
  } else {
    lev <- levels(marks(data.ppm(model)))
    nlev <- length(lev)
    out <- rep(list(imago), nlev)
    names(out) <- lev
    splitpred <- split(pred, newdata$marks)
    for(i in seq_len(nlev))
      out[[i]][] <- splitpred[[i]]
    out <- as.solist(out)
  }
  return(out)
}
    
fitted.rppm <- function(object, ...) {
  predict(object, locations=response(object))
}

response.rppm <- function(object) {
  data.ppm(as.ppm(object))
}

is.poisson.rppm <- function(x) { is.poisson(as.ppm(x)) }

is.marked.rppm <- function(X, ...) { is.marked(as.ppm(X)) }

is.multitype.rppm <- function(X, ...) { is.multitype(as.ppm(X)) }

residuals.rppm <- function(object,
                           type=c("raw", "inverse", "Pearson"),
                           ...) {
  type <- match.arg(type)
  Q <- quad.ppm(as.ppm(object))
  lambda <- predict(object)
  residualMeasure(Q, lambda, type)
}

terms.rppm <- function(x, ...) { terms(x$pfit) }

update.rppm <- function(object, ..., envir=environment(terms(object))) {
  pfit <- update(object$pfit, ..., envir=envir)
  if(!is.poisson(pfit))
    warning("Interpoint interaction will be ignored", call.=FALSE)
  df <- getglmdata(pfit)
  gf <- getglmfit(pfit)
  sf <- getglmsubset(pfit)
  rpargs <- resolve.1.default("rpargs", ...) %orifnull% object$rpargs
  rp <- do.call(rpart,
                resolve.defaults(list(formula=formula(gf),
                                      data=df,
                                      subset=sf,
                                      weights=df$.mpl.W),
                                 rpargs,
                                 list(method="poisson")))
  result <- list(pfit=pfit, rp=rp, rpargs=rpargs)
  class(result) <- c("rppm", class(result))
  return(result)
}
