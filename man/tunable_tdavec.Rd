% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tunable.R, R/zzz-step-vpd-ecc.R,
%   R/zzz-step-vpd-nl.R, R/zzz-step-vpd-pes.R, R/zzz-step-vpd-pi.R,
%   R/zzz-step-vpd-pl.R, R/zzz-step-vpd-ps.R, R/zzz-step-vpd-vab.R,
%   R/zzz-step-vpd-vpb.R
\name{tunable_tdavec}
\alias{tunable_tdavec}
\alias{tunable.step_vpd_ecc}
\alias{tunable.step_vpd_nl}
\alias{tunable.step_vpd_pes}
\alias{tunable.step_vpd_pi}
\alias{tunable.step_vpd_pl}
\alias{tunable.step_vpd_ps}
\alias{tunable.step_vpd_vab}
\alias{tunable.step_vpd_vpb}
\title{\code{tunable()} methods for {tdavec}}
\usage{
\method{tunable}{step_vpd_ecc}(x, ...)

\method{tunable}{step_vpd_nl}(x, ...)

\method{tunable}{step_vpd_pes}(x, ...)

\method{tunable}{step_vpd_pi}(x, ...)

\method{tunable}{step_vpd_pl}(x, ...)

\method{tunable}{step_vpd_ps}(x, ...)

\method{tunable}{step_vpd_vab}(x, ...)

\method{tunable}{step_vpd_vpb}(x, ...)
}
\arguments{
\item{x}{A recipe step object}

\item{...}{Not used.}
}
\value{
A tibble object.
}
\description{
These functions define what parameters \emph{can} be tuned for specific steps.
They also define the recommended objects from the {dials} package that can be
used to generate new parameter values and other characteristics.
}
\keyword{internal}
