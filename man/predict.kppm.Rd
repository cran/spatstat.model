\name{predict.kppm}
\alias{predict.kppm}
\alias{fitted.kppm}
\title{Prediction from a Fitted Cluster Point Process Model}
\description{
  Given a fitted cluster point process model,
  these functions compute the fitted intensity.
}
\usage{
  \method{fitted}{kppm}(object, ...)

  \method{predict}{kppm}(object, ...)
}
\arguments{
  \item{object}{
    Fitted cluster point process model.
    An object of class \code{"kppm"}.
  }
  \item{\dots}{
    Arguments passed to \code{\link{fitted.ppm}} or
    \code{\link{predict.ppm}} respectively.
  }
}
\details{
  These functions are methods for the generic functions
  \code{\link[stats]{fitted}} and \code{\link[stats]{predict}}.
  The argument \code{object} should be a cluster point process model
  (object of class \code{"kppm"}) obtained using
  the function \code{\link{kppm}}.
  
  The \emph{intensity} of the fitted model
  is computed, using \code{\link{fitted.ppm}} or
  \code{\link{predict.ppm}} respectively.
}
\value{
  The value of \code{fitted.kppm} is a numeric vector
  giving the fitted values at the quadrature points. 

  The value of \code{predict.kppm} is usually a pixel image
  (object of class \code{"im"}), but see \code{\link{predict.ppm}}
  for details.
}
\seealso{
  \code{\link{kppm}},
  \code{\link{plot.kppm}},
  \code{\link{vcov.kppm}},
  \code{\link{fitted.ppm}},
  \code{\link{predict.ppm}}
}
\examples{
  fit <- kppm(redwood ~ x, "Thomas")
  predict(fit)
}
\author{\adrian
  and \rolf
}
\keyword{spatial}
\keyword{models}
