\name{Hardcore}
\alias{Hardcore}
\title{The Hard Core Point Process Model}
\description{
Creates an instance of the hard core point process model
which can then be fitted to point pattern data.
}
\usage{
  Hardcore(hc=NA)
}
\arguments{
  \item{hc}{The hard core distance}
}
\value{
  An object of class \code{"interact"}
  describing the interpoint interaction
  structure of the hard core
  process with hard core distance \code{hc}.
}
\details{
  A hard core process with 
  hard core distance \eqn{h} and abundance
  parameter \eqn{\beta}{beta} 
  is a pairwise interaction point process
  in which distinct points are not allowed to come closer
  than a distance \eqn{h} apart.

  The probability density is zero if any pair of points
  is closer than \eqn{h} units apart, and otherwise equals
  \deqn{
    f(x_1,\ldots,x_n) =
    \alpha \beta^{n(x)} 
  }{
    f(x_1,\ldots,x_n) =
    alpha . beta^n(x) 
  }
  where \eqn{x_1,\ldots,x_n}{x[1],\ldots,x[n]} represent the 
  points of the pattern, \eqn{n(x)} is the number of points in the
  pattern, and \eqn{\alpha}{alpha} is the normalising constant.

  The function \code{\link{ppm}()}, which fits point process models to 
  point pattern data, requires an argument 
  of class \code{"interact"} describing the interpoint interaction
  structure of the model to be fitted. 
  The appropriate description of the hard core process
  pairwise interaction is 
  yielded by the function \code{Hardcore()}. See the examples below.

  If the hard core distance argument \code{hc} is missing or \code{NA},
  it will be estimated from the data when \code{\link{ppm}} is called.
  The estimated value of \code{hc} is the minimum nearest neighbour distance
  multiplied by \eqn{n/(n+1)}, where \eqn{n} is the
  number of data points.
}
\seealso{
  \code{\link{Strauss}},
  \code{\link{StraussHard}},
  \code{\link{MultiHard}},
  \code{\link{ppm}},
  \code{\link{pairwise.family}},
  \code{\link{ppm.object}}
}
\references{
  Baddeley, A. and Turner, R. (2000)
  Practical maximum pseudolikelihood for spatial point patterns.
  \emph{Australian and New Zealand Journal of Statistics}
  \bold{42}, 283--322.

  Ripley, B.D. (1981) 
  \emph{Spatial statistics}.
  John Wiley and Sons.
}
\examples{
   Hardcore(0.02)
   # prints a sensible description of itself

   ppm(cells ~1, Hardcore(0.05))
   # fit the stationary hard core process to `cells'

   # estimate hard core radius from data
   ppm(cells ~1, Hardcore())
   \donttest{
     # equivalent:
     ppm(cells ~1, Hardcore)
   }

   \donttest{
     # fit a nonstationary hard core process
     # with log-cubic polynomial trend
     ppm(cells ~ polynom(x,y,3), Hardcore(0.05))
   }
}
\author{
  \adrian
  and \rolf
}
\keyword{spatial}
\keyword{models}
