\name{is.stationary.ppm}
\alias{is.stationary.ppm}
\alias{is.stationary.kppm}
\alias{is.stationary.slrm}
\alias{is.stationary.dppm}
\alias{is.stationary.detpointprocfamily}
\alias{is.poisson.ppm}
\alias{is.poisson.kppm}
\alias{is.poisson.slrm}
\alias{is.poisson.interact}
\title{
  Recognise Stationary and Poisson Point Process Models
}
\description{
  Given a point process model (either a model that has been fitted to
  data, or a model specified by its parameters), 
  determine whether the model is a stationary point process,
  and whether it is a Poisson point process.
}
\usage{
\method{is.stationary}{ppm}(x)
\method{is.stationary}{kppm}(x)
\method{is.stationary}{slrm}(x)
\method{is.stationary}{dppm}(x)
\method{is.stationary}{detpointprocfamily}(x)

\method{is.poisson}{ppm}(x)
\method{is.poisson}{kppm}(x)
\method{is.poisson}{slrm}(x)
\method{is.poisson}{interact}(x)
}
\arguments{
  \item{x}{
    A fitted spatial point process model
    (object of class \code{"ppm"}, \code{"kppm"},
    \code{"lppm"}, \code{"dppm"} or \code{"slrm"})
    or a specification of a Gibbs point process model
    (object of class \code{"rmhmodel"})
    or a similar object.
  }
}
\details{
  The argument \code{x} represents a fitted spatial point process model
  or a similar object.

  \code{is.stationary(x)} returns \code{TRUE} if \code{x} represents
  a stationary point process, and \code{FALSE} if not.

  \code{is.poisson(x)} returns \code{TRUE} if \code{x} represents
  a Poisson point process, and \code{FALSE} if not.

  The functions \code{is.stationary} and \code{is.poisson} are generic,
  with methods for the classes \code{"ppm"} (Gibbs point process models),
  \code{"kppm"} (cluster or Cox point process models),
  \code{"slrm"} (spatial logistic regression models) and
  \code{"rmhmodel"} (model specifications for the
  Metropolis-Hastings algorithm).
  Additionally \code{is.stationary} has a method for
  classes \code{"detpointprocfamily"} and \code{"dppm"}
  (both determinantal point processes) and
  \code{is.poisson} has a method for 
  class \code{"interact"} (interaction structures for Gibbs models). 

  \code{is.poisson.kppm} will return \code{FALSE}, unless
  the model \code{x} is degenerate:
  either \code{x} has zero intensity so that its realisations are empty
  with probability 1, or it is a log-Gaussian Cox process
  where the log intensity has zero variance.

  \code{is.poisson.slrm} will always return \code{TRUE},
  by convention.
}
\value{
  A logical value.
}
\author{
  \spatstatAuthors.
}
\seealso{
  \code{\link[spatstat.geom]{is.marked}} to determine whether a model is a marked
  point process. 

  \code{\link[spatstat.model]{summary.ppm}} for detailed information about a
  fitted model.

  Model-fitting functions 
  \code{\link[spatstat.model]{ppm}},
  \code{\link[spatstat.model]{dppm}},
  \code{\link[spatstat.model]{kppm}},
  \code{\link[spatstat.model]{slrm}}.
}
\examples{
  fit <- ppm(cells ~ x)
  is.stationary(fit)
  is.poisson(fit)

  fut <- kppm(redwood ~ 1, "MatClust")
  is.stationary(fut)
  is.poisson(fut)

  fot <- slrm(cells ~ x)
  is.stationary(fot)
  is.poisson(fot)

}
\keyword{spatial}
\keyword{models}
