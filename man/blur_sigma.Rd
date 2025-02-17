% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/param-blur-sigma.R
\name{blur_sigma}
\alias{blur_sigma}
\title{Standard deviation of Gaussian blur}
\usage{
blur_sigma(range = c(0, unknown()), trans = transform_log10())
}
\arguments{
\item{range}{A two-element vector holding the \emph{defaults} for the smallest and
largest possible values, respectively. If a transformation is specified,
these values should be in the \emph{transformed units}.}

\item{trans}{A \code{trans} object from the \code{scales} package, such as
\code{scales::transform_log10()} or \code{scales::transform_reciprocal()}. If not provided,
the default is used which matches the units used in \code{range}. If no
transformation, \code{NULL}.}
}
\description{
The standard deviation of the noise function convolved with array values to
induce blur in lattice data (images).
}
\details{
Additional details...
}
\examples{
img_dat <- data.frame(img = I(list(volcano)))

# options to calibrate gaussian noise
blur_sigma(range = c(0, 10))
blur_sigma() |> get_blur_range(x = img_dat)
}
