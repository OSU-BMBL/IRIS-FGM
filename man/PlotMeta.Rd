% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/generics.R, R/AddMeta.R
\name{PlotMeta}
\alias{PlotMeta}
\alias{.plotMeta}
\alias{PlotMeta,BRIC-method}
\title{Generate violin plot based on meta data.}
\usage{
PlotMeta(object, ...)

.plotMeta(object = NULL)

\S4method{PlotMeta}{BRIC}(object = NULL)
}
\arguments{
\item{object}{input IRIS-FGM object}
}
\value{
It will generate two violin plots regarding number of RNA count and identified gene number.
}
\description{
This function can plot figure based on numebr total count information and this step is for the quality control. we shoud exclude extreme value in data.
}
\examples{
\dontrun{PlotMeta(object)}
}
