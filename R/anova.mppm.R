#
# anova.mppm.R
#
# $Revision: 1.25 $ $Date: 2022/04/26 07:20:39 $
#

anova.mppm <- local({

  do.gripe <- function(...) warning(paste(...), call.=FALSE)
  dont.gripe <- function(...) NULL
  tests.choices <- c("Chisq", "LRT", "Rao", "score", "F", "Cp")
  tests.avail <- c("Chisq", "LRT", "Rao", "score")
  tests.random  <- c("Chisq", "LRT")
  tests.Gibbs <- c("Chisq", "LRT")
  totalnquad <- function(fit) sum(sapply(quad.mppm(fit), n.quad))
  totalusedquad <- function(fit) with(fit$Fit$moadf, sum(.mpl.SUBSET))
  fmlaString <- function(object) { paste(as.expression(formula(object))) }
  creatorString <- function(inter) { inter$creator }
  creatorStrings <- function(interlist) { unique(sapply(interlist, creatorString)) }
  interString <- function(object) {
    inter <- object$Inter$interaction
    if(is.interact(inter)) {
      z <- creatorString(inter)
    } else if(is.hyperframe(inter)) {
      acti <- active.interactions(object)
      actinames <- colnames(acti)[apply(acti, 2, any)]
      z <- unique(unlist(lapply(actinames, function(a, h=inter) { unique(creatorStrings(h[,a,drop=TRUE])) })))
    } else {
      z <- unique(object$Inter$processes)
    }
    paste(z, collapse=", ")
  }
  
  anova.mppm <- function(object, ..., test=NULL, adjust=TRUE,
                         fine=FALSE, warn=TRUE) {
    thecall <- sys.call()

    gripe <- if(warn) do.gripe else dont.gripe
    argh <- list(...)
    
    ## trap outmoded usage
    if("override" %in% names(argh)) {
      gripe("Argument 'override' is superseded and was ignored")
      argh <- argh[-which(names(argh) == "override")]
    }

    ## list of models
    objex <- append(list(object), argh)

    ## Check each model is an mppm object
    if(!all(sapply(objex, is.mppm)))
      stop(paste("Arguments must all be", sQuote("mppm"), "objects"))

    ## are all models Poisson?
    pois <- all(sapply(objex, is.poisson.mppm))
    gibbs <- !pois

    ## single/multiple objects given
    singleobject <- (length(objex) == 1L)
    expandedfrom1 <- FALSE
    if(!singleobject) {
      ## several objects given
      ## require short names of models for output
      argnames <- names(thecall) %orifnull% rep("", length(thecall))
      retain <- is.na(match(argnames,
                            c("test", "adjust", "fine", "warn", "override")))
      shortcall <- thecall[retain]
      modelnames <- vapply(as.list(shortcall[-1L]), short.deparse, "")
    } else if(gibbs) {
      ## single Gibbs model given.
      ## we can't rely on anova.glm in this case
      ## so we have to re-fit explicitly
      Terms <- drop.scope(object)
      if((nT <- length(Terms)) > 0) {
        ## generate models by adding terms sequentially
        objex <- vector(mode="list", length=nT+1)
        envy <- environment(terms(object))
        for(n in 1L:nT) {
          ## model containing terms 1, ..., n-1
          fmla <- paste(". ~ . - ", paste(Terms[n:nT], collapse=" - "))
          fmla <- as.formula(fmla)
          calln <- update(object, fmla, evaluate=FALSE)
          objex[[n]] <- eval(calln, envy)
        }
        ## full model
        objex[[nT+1L]] <- object
        expandedfrom1 <- TRUE
      }
    }

    ## All models fitted using same method?
    Fits <- lapply(objex, getElement, name="Fit")
    fitter <- unique(unlist(lapply(Fits, getElement, name="fitter")))
    if(length(fitter) > 1)
      stop(paste("Models are incompatible;",
                 "they were fitted by different methods (",
                 paste(fitter, collapse=", "), ")" ))

    ## Choice of test
    if(fitter == "glmmPQL") {
#      HACK <- spatstat.options("developer")
#      if(!HACK) 
#        stop("Sorry, analysis of deviance is currently not supported for models with random effects, due to changes in the nlme package", call.=FALSE)
      ## anova.lme requires different format of `test' argument
      ## and does not recognise 'dispersion'
      if(is.null(test))
        test <- FALSE
      else {
        test <- match.arg(test, tests.choices)
        if(!(test %in% tests.random))
          stop(paste("Test", dQuote(test),
                     "is not implemented for random effects models"))
        test <- TRUE
      }
      if(adjust) {
        warn.once("AnovaMppmLMEnoadjust", "adjust=TRUE was ignored; not supported for random-effects models")
        adjust <- FALSE
      }
    } else if(!is.null(test)) {
      test <- match.arg(test, tests.choices)
      if(!(test %in% tests.avail))
        stop(paste("test=", dQuote(test), "is not yet implemented"),
             call.=FALSE)
      if(!pois && !(test %in% tests.Gibbs))
        stop(paste("test=", dQuote(test),
                   "is only implemented for Poisson models"),
             call.=FALSE)
    }
  

    ## Extract glm fit objects 
    fitz <- lapply(Fits, getElement, name="FIT")

    ## Ensure all models were fitted using GLM, or all were fitted using GAM
    isgam <- sapply(fitz, inherits, what="gam")
    isglm <- sapply(fitz, inherits, what="glm")
    usegam <- any(isgam)
    if(usegam && any(isglm)) {
      gripe("Models were re-fitted with use.gam=TRUE")
      objex <- lapply(objex, update, use.gam=TRUE)
    }

    ## Finally do the appropriate ANOVA
    opt <- list(test=test)
    if(fitter == "glmmPQL") {
      ## anova.lme does not recognise 'dispersion' argument
      ## Disgraceful hack:
      ## Modify object to conform to requirements of anova.lme
      fitz <- lapply(fitz, stripGLMM)
      for(i in seq_along(fitz)) {
        call.i <- getCall(objex[[i]])
        names(call.i) <- sub("formula", "fixed", names(call.i))
        fitz[[i]]$call <- call.i
      }
      warning("anova is not strictly valid for penalised quasi-likelihood fits")
    } else {
      ## normal case
      opt <- append(opt, list(dispersion=1))
    }
    result <- try(do.call(anova, append(fitz, opt)))
    if(inherits(result, "try-error"))
      stop("anova failed")
    if(fitter == "glmmPQL" &&
       !singleobject && length(modelnames) == nrow(result))
      row.names(result) <- modelnames
  
    ## Remove approximation-dependent columns if present
    result[, "Resid. Dev"] <- NULL
    ## replace 'residual df' by number of parameters in model
    if("Resid. Df" %in% names(result)) {
      ## count number of quadrature points used in each model
      nq <- totalusedquad(objex[[1L]])
      result[, "Resid. Df"] <- nq - result[, "Resid. Df"]
      names(result)[match("Resid. Df", names(result))] <- "Npar"
    }

    ## edit header 
    if(!is.null(h <- attr(result, "heading"))) {
      ## remove .mpl.Y and .logi.Y from formulae if present
      h <- gsub(".mpl.Y", "", h)
      h <- gsub(".logi.Y", "", h)
      ## delete GLM information if present
      h <- gsub("Model: quasi, link: log", "", h)
      h <- gsub("Model: binomial, link: logit", "", h)
      h <- gsub("Response: ", "", h)
      ## remove blank lines (up to 4 consecutive blanks can occur)
      for(i in 1L:5L)
        h <- gsub("\n\n", "\n", h)
      if(length(objex) > 1 && length(h) > 1) {
        ## anova(mod1, mod2, ...)
        ## change names of models
        fmlae <- unlist(lapply(objex, fmlaString))
        intrx <- unlist(lapply(objex, interString))
        h[2L] <- paste("Model",
                      paste0(1L:length(objex), ":"),
                      fmlae,
                      "\t",
                      intrx,
                      collapse="\n")
      }
      ## Add explanation if we did the stepwise thing ourselves
      if(expandedfrom1)
        h <- c(h[1L], "Terms added sequentially (first to last)\n", h[-1])
      ## Contract spaces in output if spatstat.options('terse') >= 2
      if(!waxlyrical('space'))
        h <- gsub("\n$", "", h)
      ## Put back
      attr(result, "heading") <- h
    }

    if(adjust && !pois) {
      ## issue warning, if not already given
      if(warn) warn.once("anovaMppmAdjust",
                         "anova.mppm now computes the *adjusted* deviances",
                         "when the models are not Poisson processes.")
      ## Corrected pseudolikelihood ratio 
      nmodels <- length(objex)
      if(nmodels > 1) {
        cfac <- rep(1, nmodels)
        for(i in 2:nmodels) {
          a <- objex[[i-1]]
          b <- objex[[i]]
          df <- length(coef(a)) - length(coef(b))
          if(df > 0) {
            ibig <- i-1
            ismal <- i
          } else {
            ibig <- i
            ismal <- i-1
            df <- -df
          }
          bigger <- objex[[ibig]]
          smaller <- objex[[ismal]]
          if(df == 0) {
            gripe("Models", i-1, "and", i, "have the same dimension")
          } else {
            bignames <- names(coef(bigger))
            smallnames <- names(coef(smaller))
            injection <- match(smallnames, bignames)
            if(any(uhoh <- is.na(injection))) {
              gripe("Unable to match",
                    ngettext(sum(uhoh), "coefficient", "coefficients"),
                    commasep(sQuote(smallnames[uhoh])),
                    "of model", ismal, 
                    "to coefficients in model", ibig)
            } else {
              thetaDot <- 0 * coef(bigger)
              thetaDot[injection] <- coef(smaller)
              JH <- vcov(bigger, what="all", new.coef=thetaDot, fine=fine)
#              J   <- if(!logi) JH$Sigma else (JH$Sigma1log+JH$Sigma2log)
#              H   <- if(!logi) JH$A1 else JH$Slog
              J <- JH$fisher
              H <- JH$internals$A1
              G   <- H%*%solve(J)%*%H
              if(df == 1) {
                cfac[i] <- H[-injection,-injection]/G[-injection,-injection]
              } else {
                subs <- subfits(bigger, new.coef=thetaDot)
                Res <- lapply(subs,
                              residuals,
                              type="score",
                              drop=TRUE,
                              dropcoef=TRUE)
                #' pseudoscore for each row
                Ueach <- lapply(Res, integral.msr)
                #' total pseudoscore
                maps <- mapInterVars(bigger, subs)
                U <- sumMapped(Ueach, maps, 0*thetaDot)
                #' apply adjustment
                Uo <- U[-injection]
                Uo <- matrix(Uo, ncol=1)
                Hinv <- solve(H)
                Ginv <- solve(G)
                Hoo <- Hinv[-injection,-injection, drop=FALSE]
                Goo <- Ginv[-injection,-injection, drop=FALSE]
                ## ScoreStat <- t(Uo) %*% Hoo %*% solve(Goo) %*% Hoo %*% Uo
                HooUo <- Hoo %*% Uo
                ScoreStat <- t(HooUo) %*% solve(Goo) %*% HooUo
                ## cfac[i] <- ScoreStat/(t(Uo) %*% Hoo %*% Uo)
                cfac[i] <- ScoreStat/(t(HooUo) %*% Uo)
              }
            }
          }
        }
        ## apply Pace et al (2011) adjustment to pseudo-deviances
        ## (save attributes of 'result' for later reinstatement)
        oldresult <- result
        result$Deviance <- AdjDev <- result$Deviance * cfac
        cn <- colnames(result)
        colnames(result)[cn == "Deviance"] <- "AdjDeviance"
        if("Pr(>Chi)" %in% colnames(result)) 
          result[["Pr(>Chi)"]] <- c(NA, pchisq(abs(AdjDev[-1L]),
                                               df=abs(result$Df[-1L]),
                                               lower.tail=FALSE))
        class(result) <- class(oldresult)
        attr(result, "heading") <- attr(oldresult, "heading")
      }
    }

    return(result)
  }

  sumMapped <- function(xlist, maps, initial) {
    result <- initial
    wantnames <- names(initial)
    for(i in seq_along(xlist)) {
      x <- xlist[[i]]
      gotnames <- names(x)
      unchanged <- gotnames %in% wantnames
      if(any(unchanged)) {
        unames <- gotnames[unchanged]
        result[unames] <- result[unames] + x[unames]
        x <- x[!unchanged]
        gotnames <- names(x)
      }
      cmap <- maps[[i]]
      mapinputs <- names(cmap)
      for(j in seq_along(x)) {
        inputname <- gotnames[j]
        k <- match(inputname, mapinputs)
        if(is.na(k)) {
          warning("Internal error: cannot map variable", sQuote(inputname),
                  "from submodel to full model")
        } else {
          targetnames <- cmap[[k]]
          if(length(unknown <- setdiff(targetnames, wantnames)) > 0) {
            warning("Internal error: unexpected target",
                    ngettext(length(unknown), "variable", "variables"),
                    commasep(sQuote(unknown)))
            targetnames <- intersect(targetnames, wantnames)
          }
          result[targetnames] <- result[targetnames] + x[inputname]
        }
      }
    }
    result
  }
      
  sumcompatible <- function(xlist, required) {
    result <- numeric(length(required))
    names(result) <- required
    for(i in seq_along(xlist)) {
      x <- xlist[[i]]
      namx <- names(x)
      if(!all(ok <- (namx %in% required)))
        stop(paste("Internal error in sumcompatible:",
                   "list entry", i, "contains unrecognised",
                   ngettext(sum(!ok), "value", "values"),
                   commasep(sQuote(namx[!ok]))),
             call.=FALSE)
      inject <- match(namx, required)
      result[inject] <- result[inject] + x
    }
    return(result)
  }

  anova.mppm
})


