\name{integral.msr}
\alias{integral.msr}
\title{
  Integral of a Measure
}
\description{
  Computes the integral (total value) of a measure over its domain.
}
\usage{
\method{integral}{msr}(f, domain=NULL, weight=NULL, \dots)
}
\arguments{
  \item{f}{
    A signed measure or vector-valued measure (object of class
    \code{"msr"}).
  }
  \item{domain}{
    Optional window specifying the domain of integration.
    Alternatively a tessellation.
  }
  \item{weight}{
    Optional. A pixel image (object of class \code{"im"})
    or a \code{function(x,y)} giving a numerical weight
    to be applied to the integration.
  }
  \item{\dots}{
    Ignored.
  }
}
\details{
  The integral (total value) of the measure over its domain is
  calculated.

  If \code{domain} is a window (class \code{"owin"}) then the integration
  will be restricted to this window. If \code{domain} is a tessellation
  (class \code{"tess"}) then the integral of \code{f} in each
  tile of \code{domain} will be computed.

  For a multitype measure \code{m}, use \code{\link{split.msr}}
  to separate the contributions for each type of point,
  as shown in the Examples.

  If \code{weight} is given, it should be a pixel image or a function of
  coordinates \eqn{x} and \eqn{y} returning numerical values.
  Then each increment of the measure
  will be multiplied by the corresponding value of \code{weight}.
  Effectively, \code{weight} becomes the integrand, and 
  the result is the integral of \code{weight} with respect to the
  measure \code{f}.
}
\value{
  A numeric value, vector, or matrix.

  \code{integral(f)} returns a numeric value (for a signed measure)
  or a vector of values (for a vector-valued measure).

  If \code{domain} is a tessellation then \code{integral(f, domain)}
  returns a numeric vector with one entry for each tile
  (if \code{f} is a signed measure)
  or a numeric matrix with one row for each tile
  (if \code{f} is a vector-valued measure).
}
\seealso{
  \code{\link{msr}},
  \code{\link{integral}}
}
\examples{
   fit <- ppm(cells ~ x)
   rr <- residuals(fit)
   integral(rr)

   # vector-valued measure
   rs <- residuals(fit, type="score")
   integral(rs)

   # multitype
   fitA <- ppm(amacrine ~ x)
   rrA <- residuals(fitA)
   sapply(split(rrA), integral)

   # multitype and vector-valued
   rsA <- residuals(fitA, type="score")
   sapply(split(rsA), integral)

   ## integral over a subregion
   integral(rr, domain=square(0.5))
   ## integrals over the tiles of a tessellation
   integral(rr, domain=quadrats(cells, 2))

   ## weighted integral
   integral(rr, weight=function(x,y){y})
}
\author{
  \spatstatAuthors.
}
\keyword{spatial}
\keyword{math}
