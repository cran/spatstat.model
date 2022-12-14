#
# dummify.R
#
# Convert a factor to a matrix of dummy variables, etc.
#
#  $Revision: 1.6 $  $Date: 2022/01/04 05:30:06 $
#

dummify <- function(x) {
  if(is.matrix(x) || is.data.frame(x)) {
    x <- as.data.frame(x)
    y <- do.call(data.frame, lapply(x, dummify))
    return(as.matrix(y))
  }
  # x is 1-dimensional
  if(is.complex(x)) 
    return(as.matrix(data.frame(Re=Re(x), Im=Im(x))))
  # convert factors etc
  if(is.character(x)) 
    x <- factor(x)
  if(is.logical(x)) 
    x <- factor(x, levels=c(FALSE,TRUE))
  if(is.factor(x)) {
    # convert to dummy variables
    nx <- length(x)
    lev <- levels(x)
    y <- matrix(0L, nrow=nx, ncol=length(lev))
    colnames(y) <- lev
    y[cbind(seq_len(nx), as.integer(x))] <- 1L
    return(y)
  }
  # convert to numeric
  y <- as.numeric(x)
  if(!is.matrix(y))
    y <- matrix(y, ncol=1)
  return(y)
}


