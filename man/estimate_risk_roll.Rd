% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/estimate_risk_roll.R
\name{estimate_risk_roll}
\alias{estimate_risk_roll}
\title{(Un-)conditional rolling risk estimation using vine copulas}
\usage{
estimate_risk_roll(
  data,
  weights = NULL,
  marginal_settings,
  vine_settings,
  alpha = 0.05,
  risk_measures = c("VaR", "ES_mean"),
  n_samples = 1000,
  cond_vars = NULL,
  cond_u = 0.05,
  n_mc_samples = 1000,
  trace = FALSE,
  cutoff_depth = NULL,
  prior_resid_strategy = FALSE
)
}
\arguments{
\item{data}{Matrix, data.frame or other object coercible to a data.table
storing the numeric asset returns in the named columns (at least 3).
Moreover missing values must be imputed beforehand.}

\item{weights}{Corresponding named non-negative weights of the assets
(conditioning variables must have weight 0). Default \code{NULL} gives equal
weight to each non conditional asset. Alternatively one can use a matrix
with as many rows as vine windows for changing weights. The matrix must have
column names corresponding to the assets and conditional assets have to have
weight 0.}

\item{marginal_settings}{\code{\link{marginal_settings}} S4 object containing the
needed information for the ARMA-GARCH i.e. marginal models fitting. Note
that the \code{marginal_settings} and \code{vine_settings} objects have to match as
described further below.}

\item{vine_settings}{\code{\link{vine_settings}} S4 object containing the
needed information for the vine copula model fitting. Note
that the \code{marginal_settings} and \code{vine_settings} objects have to match as
described further below.}

\item{alpha}{Numeric vector specifying the confidence levels in (0,1) at
which the risk measures should be calculated.}

\item{risk_measures}{Character vector with valid choices for risk
measures to estimate. Currently available are the Value at Risk \code{VaR} which
is implemented in \code{\link[=est_var]{est_var()}} and 3 estimation methods of the Expected
Shortfall \code{ES_mean}, \code{ES_median} and \code{ES_mc} all implemented in \code{\link[=est_es]{est_es()}}
.}

\item{n_samples}{Positive count of samples to be used at the base of the risk
measure estimation.}

\item{cond_vars}{Names of the variables to sample conditionally from
(currently \eqn{\le 2} variables).}

\item{cond_u}{Numeric vector specifying the corresponding quantiles
in (0,1) of the conditional variable(s) conditioned on which the conditional
risk measures should be calculated. Additionally always the conditioning
values corresponding to the residual of one time unit prior are used as
conditional variables (\code{cond_u} = 'prior_resid' in the risk measure output)
if the flag\code{prior_resid} is set to TRUE, otherwise the conditioning values
corresponding to the realized residual are used (\code{cond_u} = 'resid'
in the risk measure output). The latter case corresponds to the default.}

\item{n_mc_samples}{Positive count of samples for the Monte Carlo integration
if the risk measure \code{ES_mc} is used. (See \code{\link[=est_es]{est_es()}})}

\item{trace}{If set to TRUE the algorithm will print a little information
while running.}

\item{cutoff_depth}{Positive count that specifies the depth up to which the
edges of the to be constructed D-vine copula are considered in the algorithm
that determines the ordering for the D-vine fitting using partial
correlations. The default \code{NULL}
considers all edges and seems in most use cases reasonable. This argument is
only relevant if D-vines are used.}

\item{prior_resid_strategy}{Logical flag that indicates whether as the
additionally
used conditioning values the prior day residual (if this flag is TRUE) or the
realized residuals are used. The default are the realized residuals. Note
that the resulting conditional risk measures use realized data so they are
only for comparisons as they suffer from information leakage.}
}
\value{
In the unconditional case an S4 object of class \code{portvine_roll} and
in the conditional case its child class \code{cond_portvine_roll}. For details
see \code{\linkS4class{portvine_roll}}.
}
\description{
As this is the main workhorse function with a lot going on under the hood it
is advised to have a look at the vignettes or even better the package website
as they provide a detailed hands on and theoretical documentation of what
this function is doing and how it is intended to be used. For a short
summarized explanation have a look at the Details section below.
}
\details{
Roughly speaking the function performs the following steps for the
\strong{unconditional risk measure estimation}:
\itemize{
\item Fit for each asset marginal time series models i.e. ARMA-GARCH models in
a rolling window fashion. The models as well as the rolling window size and
training size are specified via the \code{marginal_settings} argument.
\item Model the dependence between the assets with a vine copula model trained on
the standardized residuals transformed to the copula scale via the
probability integral transform. This is also performed in a rolling window
fashion where one can use the same window size for the vine windows
as used for the marginal ones or a smaller window size. This window size, the
training size for the vine copula as well as the copula fitting arguments are
specified via the \code{vine_settings} argument.
\item Using the copula and the forecasted means and volatilities of the assets
one simulates \code{n_samples} many forecasted portfolio level log returns for
every time unit in every specified rolling window.
\item Based on these samples one estimates portfolio level risk measures.
}

Additionally one can perform \strong{conditional risk measure estimation} with up
to two conditional log return series like market indices. Using this approach
does not change the marginal models part but for the copula a D-vine with a
special ordering i.e. the index or the indices are fixed as the rightmost
leafs is fitted. One then simulates conditional forecasted portfolio log
returns which then
results in conditional risk measure estimates that can be particularly
interesting in stress testing like situations. One conditions on a
pre-specified quantile level (\code{cond_u}) of the conditioning assets
(\code{cond_vars}) and for comparison one also conditions either on the behavior
of the conditioning asset one time unit before
(\code{prior_resid_strategy = TRUE}) or the realized behavior of the
conditioning asset (\code{prior_resid_strategy = FALSE}).
}
\section{Matching marginal and vine settings}{

First of all there must be at least 2 marginal windows. Thus \code{train_size} +
\code{refit_size} slot in the \code{\link{marginal_settings}} class object must be smaller
than the overall input data size. Moreover the \code{refit_size} of the marginal
models must be dividable by the \code{refit_size} of the vine copula models e.g.
possible combinations are 50 and 50, 50 and 25, 50 and 10. Furthermore the
\code{train_size} of the vines must be smaller or equal to the \code{train_size} of
the marginal models.
}

\section{Parallel processing}{

This function uses the \href{https://www.futureverse.org/}{\code{future}}
framework for parallelization that allows maximum flexibility for the user
while having safe speedups for example regarding random number generation.
The default is of course the standard non parallel sequential evaluation.
The user has to do nothing in order for this default to work. If the user
wants to run the code in parallel there are many options from parallel on a
single machine up to a high performance compute (HPC) cluster, all of this
with just one setting switch i.e. by calling the function \code{\link[future:plan]{future::plan()}}
with the respective argument before the function call. Common options are
\code{future::plan("multisession")} which works on all major operating systems
and uses all available cores to run the code in parallel local R sessions.
To specify the number of workers use
\code{future::plan("multisession", workers = 2)}. To go back to sequential
processing and to shut down the parallel sessions use
\code{future::plan("sequential")}.
For more information have a look at \code{\link[future:plan]{future::plan()}}. The two following
loops are processed in parallel by default if a parallel \code{\link[future:plan]{future::plan()}}
is set:
\itemize{
\item The marginal model fitting i.e. all assets individually in parallel.
\item The vine windows i.e. the risk estimates and the corresponding vine copula
models are computed in parallel for each rolling vine window.
}

In addition the function allows for nested parallelization which has to
be done with care. So in addition to the 2 loops above one can further
run each computation for each time unit in the vine windows in parallel which
might be especially interesting if the \code{n_samples} argument is large. Then
the default parallelization has to be tweaked to not only parallelize the
first level of parallelization which are the 2 loops above. This can be
achieved e.g. via \code{future::plan(list(future::tweak(future::multisession, workers = 4), future::tweak(future::multisession, workers = 2)))}. This
setting would run the 2 primary loops in 4 parallel R sessions and in
addition each of the 4 primary parallel sessions would itself use 2 sessions
within the nested parallel loop over the time units in the vine window. This
results in a need for at least 2 times 4 so 8 threads on the hardware side.
More details can be found in the extensive documentation of the
\href{https://www.futureverse.org/}{\code{future}} framework.
}

\examples{
# For better illustrated examples have a look at the vignettes
# and/or the package website.
\donttest{
data("sample_returns_small")
ex_marg_settings <- marginal_settings(
  train_size = 900,
  refit_size = 50
)
ex_vine_settings <- vine_settings(
  train_size = 100,
  refit_size = 50,
  family_set = c("gaussian", "gumbel"),
  vine_type = "dvine"
)
# unconditionally
risk_roll <- estimate_risk_roll(
  sample_returns_small,
  weights = NULL,
  marginal_settings = ex_marg_settings,
  vine_settings = ex_vine_settings,
  alpha = c(0.01, 0.05),
  risk_measures = c("VaR", "ES_mean"),
  n_samples = 10,
  trace = FALSE
)
# conditional on one asset
risk_roll_cond <- estimate_risk_roll(
  sample_returns_small,
  weights = NULL,
  marginal_settings = ex_marg_settings,
  vine_settings = ex_vine_settings,
  alpha = c(0.01, 0.05),
  risk_measures = c("VaR", "ES_mean"),
  n_samples = 10,
  cond_vars = "GOOG",
  cond_u = c(0.05, 0.5),
  trace = FALSE,
  prior_resid_strategy = TRUE
)

# have a superficial look
risk_roll_cond
# a slightly more detailed look
summary(risk_roll_cond)

# actually use the results by extracting important fitted quantities
fitted_vines(risk_roll_cond)
fitted_marginals(risk_roll_cond)

# and of course most importantly the risk measure estimates
risk_estimates(
  risk_roll,
  risk_measures = "ES_mean",
  alpha = 0.05, exceeded = TRUE
)
risk_estimates(
  risk_roll_cond,
  risk_measures = "ES_mean",
  alpha = 0.05, exceeded = TRUE,
  cond_u = c("prior_resid", 0.5)
)
}
}
\seealso{
\code{\linkS4class{portvine_roll}}, \code{\link{marginal_settings}}, \code{\link{vine_settings}},
\code{\link[=est_var]{est_var()}}, \code{\link[=est_es]{est_es()}}
}
\author{
Emanuel Sommer
}
