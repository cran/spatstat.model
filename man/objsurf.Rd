\name{objsurf}
\alias{objsurf}
\alias{objsurf.dppm}
\alias{objsurf.kppm}
\alias{objsurf.minconfit}
\title{
  Objective Function Surface
}
\description{
  For a model that was fitted by optimisation,
  compute the values of the objective function in a neighbourhood
  of the optimal value.
}
\usage{
objsurf(x, \dots)

\method{objsurf}{dppm}(x, ..., ngrid = 32, xlim=NULL, ylim=NULL,
                               enclose=FALSE,
                               ratio = 1.5, verbose = TRUE)

\method{objsurf}{kppm}(x, ..., ngrid = 32, xlim=NULL, ylim=NULL,
                               enclose=FALSE,
                               ratio = 1.5, verbose = TRUE)

\method{objsurf}{minconfit}(x, ..., ngrid = 32, xlim=NULL, ylim=NULL,
                               ratio = 1.5, verbose = TRUE)
}
\arguments{
  \item{x}{
    Some kind of model that was fitted
    by finding the optimal value of an objective function. 
    An object of class \code{"dppm"}, \code{"kppm"} or \code{"minconfit"}.
  }
  \item{\dots}{
    Extra arguments are usually ignored.
  }
  \item{ngrid}{
    Number of grid points to evaluate along each axis.
    Either a single integer, or a pair of integers.
    For example \code{ngrid=32} would mean a \code{32 * 32} grid.
  }
  \item{xlim,ylim}{
    Optional. Numeric vectors of length 2, specifying the
    limits for the two parameters to be considered.
  }
  \item{enclose}{
    Logical value specifying whether the default values of
    \code{xlim} and \code{ylim} should enclose the history of all
    function evaluations. See Details.
  }
  \item{ratio}{
    Number greater than 1 determining the default ranges of parameter
    values. See Details.
  }
  \item{verbose}{
    Logical value indicating whether to print progress reports.
  }
}
\details{
  The object \code{x} should be some kind of model that was fitted
  by maximising or minimising the value of an objective function.
  The objective function will be evaluated on a grid of
  values of the model parameters. 

  Currently the following types of objects are accepted:
  \itemize{
    \item
    an object of class \code{"dppm"} representing a
    determinantal point process.
    See \code{\link{dppm}}.
    \item
    an object of class \code{"kppm"} representing a
    cluster point process or Cox point process. 
    See \code{\link{kppm}}.
    \item
    an object of class \code{"minconfit"} representing a
    minimum-contrast fit between a summary function and its
    theoretical counterpart. 
    See \code{\link{mincontrast}}.
  }
  The result is an object of class \code{"objsurf"} which can be
  printed and plotted: see \code{\link{methods.objsurf}}.

  The range of parameter values to be considered is determined by
  \code{xlim} and \code{ylim}. 
  The default values of \code{xlim} and \code{ylim} are
  chosen as follows.
  \itemize{
    \item if \code{enclose=FALSE} (the default), 
    the default values of \code{xlim} and \code{ylim} are
    the ranges from \code{opt/ratio} to \code{opt * ratio}
    where \code{opt} is the optimal parameter value on the surface.
    \item 
    If \code{enclose=TRUE}, 
    and if \code{x} contains a trajectory
    (history of function evaluations),
    then \code{xlim} and \code{ylim} will be the ranges
    of parameter values examined in the trajectory.
  }
}
\value{
  An object of class \code{"objsurf"} which can be
  printed and plotted.
  Essentially a list containing entries \code{x}, \code{y}, \code{z}
  giving the parameter values and objective function values.

  There are methods for \code{plot}, \code{print}, \code{summary},
  \code{image}, \code{contour} and \code{persp}.
}
\author{
  \adrian and \ege.
}
\seealso{
  \code{\link{methods.objsurf}},
  \code{\link{kppm}}, 
  \code{\link{mincontrast}}
}
\examples{
   fit <- kppm(redwood ~ 1, "Thomas")
   os <- objsurf(fit)

   if(interactive()) {
     plot(os)
     contour(os, add=TRUE)
     persp(os)
   }
}
\keyword{spatial}
\keyword{models}
