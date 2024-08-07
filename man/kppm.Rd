\name{kppm}
\alias{kppm}
\alias{kppm.formula}
\alias{kppm.ppp}
\alias{kppm.quad}
\concept{point process model}
\concept{Cox point process}
\concept{cluster process}
\concept{Neyman-Scott cluster process}
\title{Fit Cluster or Cox Point Process Model}
\description{
  Fit a homogeneous or inhomogeneous cluster process or
  Cox point process model to a point pattern.
}
\usage{
  kppm(X, \dots)

  \method{kppm}{formula}(X,
                clusters = c("Thomas","MatClust","Cauchy","VarGamma","LGCP"),
                \dots,
                data=NULL)

  \method{kppm}{ppp}(X,
       trend = ~1,
       clusters = c("Thomas","MatClust","Cauchy","VarGamma","LGCP"),
       data = NULL,
       ...,
       covariates=data,
       subset,
       method = c("mincon", "clik2", "palm", "adapcl"),
       penalised = FALSE,
       improve.type = c("none", "clik1", "wclik1", "quasi"),
       improve.args = list(),
       weightfun=NULL,
       control=list(),
       stabilize=TRUE,
       algorithm,
       trajectory=FALSE,
       statistic="K",
       statargs=list(),
       rmax = NULL,
       epsilon=0.01,
       covfunargs=NULL,
       use.gam=FALSE,
       nd=NULL, eps=NULL,
       ppm.improve.type=c("none", "ho", "enet"),
       ppm.improve.args=list())

\method{kppm}{quad}(X,
       trend = ~1,
       clusters = c("Thomas","MatClust","Cauchy","VarGamma","LGCP"),
       data = NULL,
       ...,
       covariates=data,
       subset,
       method = c("mincon", "clik2", "palm", "adapcl"),
       penalised = FALSE,
       improve.type = c("none", "clik1", "wclik1", "quasi"),
       improve.args = list(),
       weightfun=NULL,
       control=list(),
       stabilize=TRUE,
       algorithm,
       trajectory=FALSE,
       statistic="K",
       statargs=list(),
       rmax = NULL,
       epsilon=0.01,
       covfunargs=NULL,
       use.gam=FALSE,
       nd=NULL, eps=NULL,
       ppm.improve.type=c("none", "ho", "enet"),
       ppm.improve.args=list())
}
\arguments{
  \item{X}{
    A point pattern dataset (object of class \code{"ppp"} or
    \code{"quad"}) to which the model should be fitted, or a
    \code{formula} in the \R language defining the model. See Details.
  }
  \item{trend}{
    An \R formula, with no left hand side,
    specifying the form of the log intensity.
  }
  \item{clusters}{
    Character string determining the cluster model.
    Partially matched.
    Options are \code{"Thomas"}, \code{"MatClust"},
    \code{"Cauchy"}, \code{"VarGamma"} and \code{"LGCP"}.
  }
  \item{data,covariates}{
    The values of spatial covariates (other than the Cartesian
    coordinates) required by the model.
    A named list of pixel images, functions, windows,
    tessellations or numeric constants.
  }
  \item{\dots}{
    Additional arguments. See Details.
  }
  \item{subset}{
    Optional.
    A subset of the spatial domain,
    to which the model-fitting should be restricted.
    A window (object of class \code{"owin"})
    or a logical-valued pixel image (object of class \code{"im"}),
    or an expression (possibly involving the names of entries in \code{data})
    which can be evaluated to yield a window or pixel image.
  }
  \item{method}{
    The fitting method. Either 
    \code{"mincon"} for minimum contrast,
    \code{"clik2"} for second order composite likelihood,
    \code{"adapcl"} for adaptive second order composite likelihood,
    or \code{"palm"} for Palm likelihood.
    Partially matched.
  }
  \item{penalised}{
    Logical value specifying whether the objective function (the composite
    likelihood or contrast) should be modified by adding a penalty against
    extreme values of cluster scale. 
  }
\item{improve.type}{
    Method for updating the initial estimate of the trend.
    Initially the trend is estimated as if the process
    is an inhomogeneous Poisson process.
    The default, \code{improve.type = "none"}, is to use this initial estimate.
    Otherwise, the trend estimate is
    updated by \code{\link{improve.kppm}}, using information
    about the pair correlation function.
    Options are \code{"clik1"}
    (first order composite likelihood, essentially equivalent to \code{"none"}),
    \code{"wclik1"} (weighted first order composite likelihood) and
    \code{"quasi"} (quasi likelihood).
  }
  \item{improve.args}{
    Additional arguments passed to \code{\link{improve.kppm}} when
    \code{improve.type != "none"}. See Details.
  }
  \item{weightfun}{
    Optional weighting function \eqn{w}
    in the composite likelihoods or Palm likelihood.
    A \code{function} in the \R language,
    or one of the strings \code{"threshold"} or \code{"taper"}.
    See Details.
  }
  \item{control}{
    List of control parameters passed to the optimization function
    \code{\link[stats]{optim}}.
  }
  \item{stabilize}{
    Logical value specifying whether to numerically stabilize
    the optimization algorithm, by specifying suitable default values of
    \code{control$fnscale} and \code{control$parscale}.
  }
  \item{algorithm}{
    Character string determining the mathematical algorithm
    to be used to solve the fitting problem.
    If \code{method="mincon", "clik2"} or \code{"palm"} this argument
    is passed to the generic optimization function
    \code{\link[stats]{optim}}
    (renamed as the argument \code{method} to \code{\link[stats]{optim}})
    with default \code{"Nelder-Mead"}.
    If \code{method="adapcl"} the argument is passed to the
    equation solver \code{\link[nleqslv]{nleqslv}}
    (renamed as the argument \code{method} to \code{\link[nleqslv]{nleqslv}})
    with default \code{"Bryden"}.
  }
  \item{trajectory}{
    Logical value specifying whether to save the history of all
    function evaluations performed by the optimization algorithm.
  }
  \item{statistic}{
    Name of the summary statistic to be used
    for minimum contrast estimation: either \code{"K"} or \code{"pcf"}.
  }
  \item{statargs}{
    Optional list of arguments to be used when calculating
    the \code{statistic}. See Details.
  }
  \item{rmax}{
    Maximum value of interpoint distance
    to use in the composite likelihood.
  }
  \item{epsilon}{
    Tuning parameter for the adaptive composite likelihood method.
  }
  \item{covfunargs,use.gam,nd,eps}{
    Arguments passed to \code{\link{ppm}} when fitting the intensity.
  }
  \item{ppm.improve.type,ppm.improve.args}{
    Arguments controlling the initial fit of the trend.
    Passed to \code{\link{ppm}} as the arguments
    \code{improve.type} and \code{improve.args} respectively.
  }
}
\details{
  This function fits a clustered point process model to the
  point pattern dataset \code{X}. 

  The model may be either a \emph{Neyman-Scott cluster process}
  or another \emph{Cox process}.
  The type of model is determined by the argument \code{clusters}.
  Currently the options 
  are \code{clusters="Thomas"} for the Thomas process,
  \code{clusters="MatClust"} for the \Matern cluster process,
  \code{clusters="Cauchy"} for the Neyman-Scott cluster process
  with Cauchy kernel,
  \code{clusters="VarGamma"} for the Neyman-Scott cluster process
  with Variance Gamma kernel (requires an additional argument \code{nu}
  to be passed through the dots; see \code{\link[spatstat.random]{rVarGamma}} for details),
  and \code{clusters="LGCP"} for the log-Gaussian Cox process (may
  require additional arguments passed through \code{\dots}; see
  \code{\link[spatstat.random]{rLGCP}} for details on argument names).
  The first four models are Neyman-Scott cluster processes.
  
  The algorithm first estimates the intensity function
  of the point process using \code{\link{ppm}}.
  The argument \code{X} may be a point pattern
  (object of class \code{"ppp"}) or a quadrature scheme
  (object of class \code{"quad"}). The intensity is specified by
  the \code{trend} argument.
  If the trend formula is \code{~1} (the default)
  then the model is \emph{homogeneous}. The algorithm begins by
  estimating the intensity as the number of points divided by
  the area of the window.
  Otherwise, the model is \emph{inhomogeneous}. 
  The algorithm begins by fitting a Poisson process with log intensity
  of the form specified by the formula \code{trend}.
  (See \code{\link{ppm}} for further explanation).

  The argument \code{X} may also be a \code{formula} in the
  \R language. The right hand side of the formula gives the
  \code{trend} as described above. The left hand side of the formula
  gives the point pattern dataset to which the model should be fitted.

  If \code{improve.type="none"} this is the final estimate of the
  intensity. Otherwise, the intensity estimate is updated, as explained in
  \code{\link{improve.kppm}}. Additional arguments to
  \code{\link{improve.kppm}} are passed as a named list in
  \code{improve.args}.
  
  The cluster parameters of the model are then fitted
  either by minimum contrast estimation,
  or by a composite likelihood method (maximum
  composite likelihood, maximum Palm likelihood, or by solving the adaptive 
  composite likelihood estimating equation).

  \describe{
   \item{Minimum contrast:}{
      If \code{method = "mincon"} (the default) clustering parameters of
      the model will be fitted
      by minimum contrast estimation, that is, by matching the theoretical
      \eqn{K}-function of the model to the empirical \eqn{K}-function
      of the data, as explained in \code{\link{mincontrast}}.

      For a homogeneous model (\code{ trend = ~1 })
      the empirical \eqn{K}-function of the data is computed
      using \code{\link[spatstat.explore]{Kest}},
      and the parameters of the cluster model are estimated by
      the method of minimum contrast.

      For an inhomogeneous model, 
      the inhomogeneous \eqn{K} function is estimated
      by \code{\link[spatstat.explore]{Kinhom}} using the fitted intensity.
      Then the parameters of the cluster model
      are estimated by the method of minimum contrast using the
      inhomogeneous \eqn{K} function. This two-step estimation
      procedure is due to Waagepetersen (2007).
  
      If \code{statistic="pcf"} then instead of using the
      \eqn{K}-function, the algorithm will use
      the pair correlation function \code{\link[spatstat.explore]{pcf}} for homogeneous
      models and the inhomogeneous pair correlation function
      \code{\link[spatstat.explore]{pcfinhom}} for inhomogeneous models.
      In this case, the smoothing parameters of the pair correlation
      can be controlled using the argument \code{statargs},
      as shown in the Examples.

      Additional arguments \code{\dots} will be passed to
      \code{\link{clusterfit}} to control the minimum contrast fitting
      algorithm.

      The optimisation is performed by the generic
      optimisation algorithm \code{\link[stats]{optim}}.
    }
    \item{Second order composite likelihood:}{
      If \code{method = "clik2"} the clustering parameters of the
      model will be fitted by maximising the second-order composite likelihood
      (Guan, 2006). The log composite likelihood is
      \deqn{
	\sum_{i,j} w(d_{ij}) \log\rho(d_{ij}; \theta)
	- \left( \sum_{i,j} w(d_{ij}) \right)
	\log \int_D \int_D w(\|u-v\|) \rho(\|u-v\|; \theta)\, du\, dv
      }{
	sum[i,j] w(d[i,j]) log(rho(d[i,j]; theta))
	- (sum[i,j] w(d[i,j]))
	log(integral[D,D] w(||u-v||) rho(||u-v||; theta) du dv)
      }
      where the sums are taken over all pairs of data points
      \eqn{x_i, x_j}{x[i], x[j]} separated by a distance
      \eqn{d_{ij} = \| x_i - x_j\|}{d[i,j] = ||x[i] - x[j]||}
      less than \code{rmax},
      and the double integral is taken over all pairs of locations
      \eqn{u,v} in the spatial window of the data.
      Here \eqn{\rho(d;\theta)}{rho(d;theta)} is the
      pair correlation function of the model with
      cluster parameters \eqn{\theta}{theta}.
      
      The function \eqn{w} in the composite likelihood
      is a weighting function and may be chosen arbitrarily.
      It is specified by the argument \code{weightfun}.
      If this is missing or \code{NULL} then the default is
      a threshold weight function,
      \eqn{w(d) = 1(d \le R)}{w(d) = 1(d <= R)}, where \eqn{R} is \code{rmax/2}.
      If it is specified, the argument \code{weightfun} should
      be a \code{function} in the \R language with one argument.
      Alternatively \code{weightfun} may be
      one of the strings \code{"threshold"} or \code{"taper"}
      representing the functions
      \eqn{w(d) = 1(d \le R)}{w(d) = 1(d <= R)}
      and
      \eqn{w(d) = min(1, R/d)} respectively.
      
      The optimisation is performed by the generic
      optimisation algorithm \code{\link[stats]{optim}}.
    }
    \item{Palm likelihood:}{
      If \code{method = "palm"} the clustering parameters of the
      model will be fitted by maximising the Palm loglikelihood
      (Tanaka et al, 2008)
      \deqn{
	\sum_{i,j} w(x_i, x_j) \log \lambda_P(x_j \mid x_i; \theta)
	- \int_D w(x_i, u) \lambda_P(u \mid x_i; \theta) {\rm d} u
      }{
	sum[i,j] w(x[i], x[j]) log(lambdaP(x[j] | x[i]; theta))
	- integral[D] w(x[i], u) lambdaP(u | x[i]; theta) du
      }
      with the same notation as above. Here
      \eqn{\lambda_P(u|v;\theta)}{lambdaP(u|v;theta)} is the Palm intensity of
      the model at location \eqn{u} given there is a point at \eqn{v}.

      The optimisation is performed by the generic
      optimisation algorithm \code{\link[stats]{optim}}.
    }
    \item{Adaptive Composite likelihood:}{
      If \code{method = "cladap"} the clustering parameters of the
      model will be fitted by solving the adaptive second order 
      composite likelihood estimating equation (Lavancier et al, 2021).
      The estimating function is
      \deqn{
	\sum_{u, v}
	w(\epsilon \frac{| g(0; \theta) - 1 |}{g(\|u-v\|; \theta)-1})
  	\frac{\nabla_\theta g(\|u-v\|;\theta)}{g(\|u-v\|;\theta)}
	- 
	\int_D \int_D
	w(\epsilon \frac{ | g(u,v; \theta) - 1|}{g(\|u-v\|; \theta)-1})
	\nabla_\theta g(\|u-v\|; \theta) 
	\rho(u) \rho(v)\, du\, dv
      }{
	\sum[u,v] w(epsilon |g(0; theta)-1|/(g(||u-v||; theta)-1)) 
	g'(||u-v||; theta) / g(||u-v||; theta) - integral[D,D] 
	w(epsilon |g(0; theta)-1|/(g(||u-v||; theta)-1))
	g'(||u-v||; theta) rho(u) rho(v) du dv
      }
      where the sum is taken over all distinct pairs of points.
      Here \eqn{g(d;\theta)}{g(d; theta)} is the
      pair correlation function  with
      parameters \eqn{\theta}{theta}.
      The partial derivative with respect to \eqn{\theta}{theta} 
      is \eqn{g'(d; \theta)}{g'(d; theta)}, and \eqn{\rho(u)}{rho(u)} denotes
      the fitted intensity function of the model.
      
      The tuning parameter \eqn{\epsilon}{epsilon} is 
      independent of the data. It can be specified by the
      argument \code{epsilon} and has default value \eqn{0.01}.
      
      The function \eqn{w} in the estimating function
      is a weighting function of bounded support \eqn{[-1,1]}.
      It is specified by the argument \code{weightfun}.
      If this is missing or \code{NULL} then the default is
      \eqn{
	w(d) = 1(\|d\| \le 1) \exp(1/(r^2-1))}{w(d) = 1(||d|| \le 1)
	exp(1/(d^2-1))
      }
      The estimating equation is solved using the
      nonlinear equation solver \code{\link[nleqslv]{nleqslv}}
      from the package \pkg{nleqslv}. The package \pkg{nleqslv}
      must be installed in order to use this option.
    }   
  }
  If \code{penalised=TRUE}, the fitting procedure is modified by
  adding a penalty against extreme values of the cluster scale,
  as proposed by Baddeley et al (2022).

  If \code{trajectory=TRUE}, the resulting object contains the history
  of all points in the cluster parameter space which were evaluated by
  the optimization algorithm. The trajectory can be extracted by
  \code{traj(fit)} or \code{traj(obsurf(fit))} where \code{fit} is the
  fitted model object.
}
\section{Cluster parameters for Neyman-Scott models}{
  For Neyman-Scott models, the fitting procedure searches
  for the best-fitting values of the parameters
  that control the intensity of parents and the physical scale
  of the clusters. (Any parameters that control the shape of the clusters
  must be specified separately and are assumed to be fixed.)

  The fitted object \code{fit} contains the fitted cluster parameters as
  the element \code{fit$par} in the format described below.
  Initial estimates for these cluster
  parameters can be specified using the argument \code{startpar} in the
  same format.
  
  The cluster parameters will be stored in a \emph{named} numeric vector
  \code{par} of length 2. The first value is always \code{kappa},
  the intensity of parents (cluster centres).
  The format is as follows:
  \itemize{
    \item
    for \code{clusters="Thomas"},
    a vector \code{c(kappa, sigma2)} where
    \code{sigma2} is the square of the cluster standard deviation;
    \item
    for \code{clusters="MatClust"},
    a vector \code{c(kappa, R)} where
    \code{R} is the radius of the cluster;
    \item
    for \code{clusters="Cauchy"},
    a vector \code{c(kappa, eta2)} where
    \code{eta2 = code{4 * scale^2}}
    where \code{scale} is the scale parameter for the model
    as used in \code{\link[spatstat.random]{rCauchy}};
    \item
    for \code{clusters="VarGamma"},
    a vector \code{c(kappa, eta)} where
    \code{eta} is equivalent to the
    scale parameter \code{omega} used in  \code{\link[spatstat.random]{rVarGamma}}.
  }
  
  For \code{clusters="VarGamma"} it will be necessary to specify
  the shape parameter \code{nu} as described in the help for
  \code{\link[spatstat.random]{rVarGamma}}. This is specified separately as an argument
  \code{nu} in the call to \code{kppm}.
}
\section{Optimization algorithm}{
  The following details allow greater control over the fitting
  procedure.
  
  For the first three fitting methods
  (\code{method="mincon", "clik2"} and \code{"palm"}), 
  the optimisation is performed by the generic
  optimisation algorithm \code{\link[stats]{optim}}.
  The behaviour of this algorithm can be controlled
  by the following arguments to \code{kppm}:
  \itemize{
    \item
    \code{startpar} determines the initial estimates of the cluster parameters.
    \item
    \code{algorithm} determines the particular optimization
    method. This argument is passed to \code{\link[stats]{optim}} as the
    argument \code{method}. Options are listed in the help for
    \code{\link[stats]{optim}}. The default is the Nelder-Mead
    simplex method.
    \item
    \code{control} is a named list of control parameters,
    documented in the help for \code{\link[stats]{optim}}.
    Useful control arguments include
    \code{trace}, \code{maxit} and \code{abstol}.
    \item
    \code{lower} and \code{upper} specify bounds for the
    cluster parameters, when \code{algorithm="L-BFGS-B"} or
    \code{algorithm="Brent"}, as described in the help for \code{\link[stats]{optim}}. 
  }

  For \code{method="adapcl"}, the estimating equation is solved
  using the nonlinear equation solver \code{\link[nleqslv]{nleqslv}}
  from the package \pkg{nleqslv}. 
  The package \pkg{nleqslv} must be installed in order to use this
  option.
  The behaviour of this algorithm can be controlled
  by the following arguments to \code{kppm}:
  \itemize{
    \item
    \code{startpar} determines the initial estimates of the cluster parameters.
    \item
    \code{algorithm} determines the method for solving
    the equation. This argument is passed to \code{\link[nleqslv]{nleqslv}} as the
    argument \code{method}. Options are listed in the help for
    \code{\link[nleqslv]{nleqslv}}.
    \item
    \code{globStrat} determines the global strategy
    to be applied. This argument is is passed to \code{\link[nleqslv]{nleqslv}}
    as the argument \code{global}. Options are listed in the help for
    \code{\link[nleqslv]{nleqslv}}.
    \item
    \code{control} is a named list of control parameters,
    documented in the help for \code{\link[nleqslv]{nleqslv}}.
  }
}
\section{Log-Gaussian Cox Models}{
  To fit a log-Gaussian Cox model,
  specify \code{clusters="LGCP"} and use additional arguments
  to specify the covariance structure. These additional arguments can
  be given individually in the call to \code{kppm}, or they can be
  collected together in a list called \code{covmodel}.

  For example a \Matern model with parameter \eqn{\nu=0.5} could be specified
  either by \code{kppm(X, clusters="LGCP", model="matern", nu=0.5)} or by
  \code{kppm(X, clusters="LGCP", covmodel=list(model="matern", nu=0.5))}.

  The argument \code{model} specifies the type of covariance
  model: the default is \code{model="exp"} for an exponential covariance.
  Additional arguments specify the shape parameters of the covariance
  model. For example if \code{model="matern"} then the additional argument
  \code{nu} is required. 

  The available models are as follows:
  \describe{
    \item{\code{model="exponential"}:}{
      the exponential covariance function
      \deqn{C(r) = \sigma^2 \exp(-r/h)}{C(r) = sigma^2 * exp(-r/h)}
      where \eqn{\sigma^2} is the (fitted) variance parameter,
      and \eqn{h} is the (fitted) scale parameter.
      No shape parameters are required.
    }
    \item{\code{model="gauss"}:}{
      the Gaussian covariance function
      \deqn{C(r) = \sigma^2 \exp(-(r/h)^2)}{C(r) = sigma^2 * exp(-(r/h)^2)}
      where \eqn{\sigma^2} is the (fitted) variance parameter,
      and \eqn{h} is the (fitted) scale parameter.
      No shape parameters are required.
    }
    \item{\code{model="stable"}:}{
      the stable covariance function
      \deqn{
	C(r) = \sigma^2 \exp(-(r/h)^\alpha)
      }{
	C(r) = sigma^2 * exp(-(r/h)^alpha)
      }
      where \eqn{\sigma^2} is the (fitted) variance parameter,
      \eqn{h} is the (fitted) scale parameter,
      and \eqn{\alpha} is the shape parameter \code{alpha}.
      The parameter \code{alpha} must be given, either as a stand-alone
      argument, or as an entry in the list \code{covmodel}.
    }
    \item{\code{model="gencauchy"}:}{
      the generalised Cauchy covariance function
      \deqn{
	C(r) = \sigma^2 (1 + (x/h)^\alpha)^{-\beta/\alpha}
      }{
	C(r) = sigma^2 * (1 + (x/h)^\alpha)^(-\beta/\alpha)
      }
      where \eqn{\sigma^2} is the (fitted) variance parameter,
      \eqn{h} is the (fitted) scale parameter,
      and \eqn{\alpha} and \eqn{\beta} are the shape parameters
      \code{alpha} and \code{beta}.
      The parameters \code{alpha} and \code{beta}
      must be given, either as stand-alone arguments, or as entries
      in the list \code{covmodel}.
    }
    \item{\code{model="matern"}:}{
      the Whittle-\Matern covariance function
      \deqn{
	C(r) = \sigma^2 \frac{1}{2^{\nu-1} \Gamma(\nu)}
	       (\sqrt{2 \nu} \, r/h)^\nu K_\nu(\sqrt{2\nu}\, r/h)
      }{
	C(r) = \sigma^2 * 2^(1-\nu) * \Gamma(\nu)^(-1) *
	       (sqrt(2 *\nu) * r/h)^\nu * K[\nu](sqrt(2 * nu) * r/h)
      }
      where \eqn{\sigma^2} is the (fitted) variance parameter,
      \eqn{h} is the (fitted) scale parameter,
      and \eqn{\nu} is the shape parameter \code{nu}.
      The parameter \code{nu} must be given, either as a stand-alone
      argument, or as an entry in the list \code{covmodel}.
    }
  }
  Note that it is not possible to use \emph{anisotropic} covariance models
  because the \code{kppm} technique assumes the pair correlation function
  is isotropic.
}
\value{
  An object of class \code{"kppm"} representing the fitted model.
  There are methods for printing, plotting, predicting, simulating
  and updating objects of this class.
}
\section{Error and warning messages}{
  See \code{\link{ppm.ppp}} for a list of common error messages
  and warnings originating from the first stage of model-fitting.
}
\seealso{
  Methods for \code{kppm} objects:
  \code{\link{plot.kppm}},
  \code{\link{fitted.kppm}},
  \code{\link{predict.kppm}},
  \code{\link{simulate.kppm}},
  \code{\link{update.kppm}},
  \code{\link{vcov.kppm}},
  \code{\link[spatstat.model:methods.kppm]{methods.kppm}},
  \code{\link{as.ppm.kppm}},
  \code{\link{as.fv.kppm}},
  \code{\link{Kmodel.kppm}},
  \code{\link{pcfmodel.kppm}}.

  See also \code{\link{improve.kppm}} for improving the fit of a
  \code{kppm} object.

  Minimum contrast fitting algorithm:
  higher level interface \code{\link{clusterfit}};
  low-level algorithm \code{\link{mincontrast}}.

  Alternative fitting algorithms:
  \code{\link{thomas.estK}},
  \code{\link{matclust.estK}},
  \code{\link{lgcp.estK}},
  \code{\link{cauchy.estK}},
  \code{\link{vargamma.estK}},
  \code{\link{thomas.estpcf}},
  \code{\link{matclust.estpcf}},
  \code{\link{lgcp.estpcf}},
  \code{\link{cauchy.estpcf}},
  \code{\link{vargamma.estpcf}}.

  Summary statistics:
  \code{\link[spatstat.explore]{Kest}},
  \code{\link[spatstat.explore]{Kinhom}},
  \code{\link[spatstat.explore]{pcf}},
  \code{\link[spatstat.explore]{pcfinhom}}.

  For fitting Poisson or Gibbs point process models, see \code{\link{ppm}}.
}
\references{
  Baddeley, A., Davies, T.M., Hazelton, M.L., Rakshit, S. and Turner,
  R. (2022) Fundamental problems in fitting spatial cluster
  process models. \emph{Spatial Statistics} \bold{52}, 100709.
  DOI: \code{10.1016/j.spasta.2022.100709}

  Guan, Y. (2006) 
  A composite likelihood approach in fitting spatial point process models.
  \emph{Journal of the American Statistical Association}
  \bold{101}, 1502--1512.

  Guan, Y., Jalilian, A. and Waagepetersen, R. (2015)
  Quasi-likelihood for spatial point processes.
  \emph{Journal of the Royal Statistical Society, Series B}
  \bold{77}, 677-697.

  Jalilian, A., Guan, Y. and Waagepetersen, R. (2012)
  Decomposition of variance for spatial Cox processes.
  \emph{Scandinavian Journal of Statistics} \bold{40}, 119--137.

  Lavancier, F., Poinas, A., and Waagepetersen, R. (2021)
  Adaptive estimating function inference for nonstationary
  determinantal point processes.
  \emph{Scandinavian Journal of Statistics}, \bold{48} (1), 87--107.
  
  Tanaka, U. and Ogata, Y. and Stoyan, D. (2008)
  Parameter estimation and model selection for
  Neyman-Scott point processes. 
  \emph{Biometrical Journal} \bold{50}, 43--57.

  Waagepetersen, R. (2007)
  An estimating function approach to inference for
  inhomogeneous Neyman-Scott processes.
  \emph{Biometrics} \bold{63}, 252--258.
}
\examples{
  online <- interactive()
  if(!online) op <- spatstat.options(npixel=32, ndummy.min=16)

  # method for point patterns
  kppm(redwood, ~1, "Thomas")
  # method for formulas
  kppm(redwood ~ 1, "Thomas")

  # different models for clustering
  if(online) kppm(redwood ~ x, "MatClust") 
  kppm(redwood ~ x, "MatClust", statistic="pcf", statargs=list(stoyan=0.2)) 
  kppm(redwood ~ x, cluster="Cauchy", statistic="K")
  kppm(redwood, cluster="VarGamma", nu = 0.5, statistic="pcf")

  # log-Gaussian Cox process (LGCP) models
  kppm(redwood ~ 1, "LGCP", statistic="pcf")
  kppm(redwood ~ x, "LGCP", statistic="pcf",
                            model="matern", nu=0.3,
                            control=list(maxit=10))

  # Different fitting techniques
  fitc <- kppm(redwood ~ 1, "Thomas", method="c")
  fitp <- kppm(redwood ~ 1, "Thomas", method="p")
  # penalised fit
  fitmp <- kppm(redwood ~ 1, "Thomas", penalised=TRUE)
  # quasi-likelihood improvement 
  fitq <- kppm(redwood ~ x, "Thomas", improve.type = "quasi")

  if(!online) spatstat.options(op)
}
\author{
  \spatstatAuthors,
  with contributions from \abdollah and \rasmus.
  Adaptive composite likelihood method contributed by Chiara Fend
  and modified by Adrian Baddeley.
  Penalised optimization developed by Adrian Baddeley, \tilman
  and \martinH.
}
\keyword{spatial}
\keyword{models}

