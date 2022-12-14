\name{summary.ppm}
\alias{summary.ppm}
\alias{print.summary.ppm}
\title{Summarizing a Fitted Point Process Model}
\description{
  \code{summary} method for class \code{"ppm"}.
}
\usage{
  \method{summary}{ppm}(object, \dots, quick=FALSE, fine=FALSE)
  \method{print}{summary.ppm}(x, \dots)
}
\arguments{
  \item{object}{A fitted point process model.}
  \item{\dots}{Ignored.}
  \item{quick}{Logical flag controlling the scope of the summary.}
  \item{fine}{
    Logical value passed to \code{\link{vcov.ppm}} determining
    whether to compute the quick, coarse estimate of variance
    (\code{fine=FALSE}, the default) or the slower, finer estimate
    (\code{fine=TRUE}).
  }
  \item{x}{Object of class \code{"summary.ppm"} as returned by
    \code{summary.ppm}.
  }
}
\details{
  This is a method for the generic \code{\link{summary}}
  for the class \code{"ppm"}. An object of class \code{"ppm"}
  describes a fitted point process model. See \code{\link{ppm.object}})
  for details of this class. 
  
  \code{summary.ppm} extracts information about the
  type of model that has been fitted, the data to which the model was
  fitted, and the values of the fitted coefficients.
  (If \code{quick=TRUE} then only the information about the type
  of model is extracted.)

  \code{print.summary.ppm} prints this information in a
  comprehensible format.

  In normal usage, \code{print.summary.ppm} is invoked implicitly
  when the user calls \code{summary.ppm} without assigning its value
  to anything. See the examples.

  You can also type \code{coef(summary(object))} to extract a table
  of the fitted coefficients of the point process model \code{object}
  together with standard errors and confidence limits. 
}
\value{
  \code{summary.ppm} returns an object of class \code{"summary.ppm"},
  while \code{print.summary.ppm} returns \code{NULL}.
}
\examples{
  # invent some data
  X <- rpoispp(42)
  # fit a model to it
  fit <- ppm(X ~ x, Strauss(r=0.1))
  # summarize the fitted model
  summary(fit)
  # `quick' option
  summary(fit, quick=TRUE)
  # coefficients with standard errors and CI
  coef(summary(fit))
  coef(summary(fit, fine=TRUE))

  # save the full summary
  s <- summary(fit)
  # print it
  print(s)
  s
  # extract stuff
  names(s)
  coef(s)
  s$args$correction
  s$name
  s$trend$value

  \donttest{
    # multitype pattern
    fit <- ppm(demopat ~marks, Poisson())
    summary(fit)
  }

  # model with external covariates
  fitX <- ppm(X, ~Z, covariates=list(Z=function(x,y){x+y}))
  summary(fitX)
}
\author{\adrian
  and \rolf
}
\keyword{spatial}
\keyword{methods}
\keyword{models}
