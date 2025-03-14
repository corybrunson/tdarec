#' This script provides helper files for the code generating scripts
#' 'build-pre/build-*.R'.
#'
#' Refer to the following resources for guidance:
#' https://blog.r-hub.io/2020/02/10/code-generation/
#' https://www.tidymodels.org/learn/develop/recipes/
#'
#' Customization steps are tagged "CHOICE:".

#' SETUP

#' Attach packages.

library(TDAvec)
# library(devtools)
library(tibble)
library(dplyr)
library(purrr)
library(tidyr)

#' RETRIEVAL

#' Retrieve functions and their attributes from {TDAvec}.

lsf.str("package:TDAvec") |> 
  enframe(name = NULL, value = "structure") |> 
  mutate(name = map_chr(structure, as.character)) |> 
  filter(grepl("^compute[A-Za-z]+$", name)) |> 
  # exclude helper function
  filter(name != "computeLimits") |> 
  mutate(fun = map(name, \(s) getFromNamespace(s, ns = "TDAvec"))) |> 
  mutate(args = map(fun, formals)) |> 
  print() -> tdavec_functions

# tabulate original argument defaults
tdavec_functions |> 
  select(fun = name, args) |> 
  mutate(args = lapply(args, as.list)) |> 
  mutate(args = lapply(args, enframe, name = "arg", value = "default")) |> 
  unnest(args) |> 
  # dataset is not a tunable parameter
  filter(arg != "D") |> 
  # scale sequences are handled separately and should default to `NULL`
  filter(arg != "scaleSeq" & arg != "xSeq" & arg != "ySeq") |> 
  # encase default as a code string (retaining quotes)
  mutate(default = sapply(default, deparse)) |> 
  print(n = Inf) -> tdavec_defaults

#' Retrieve and adapt documentation from {TDAvec}.

# retrieve function titles from {TDAvec}
# https://stackoverflow.com/a/46712167/4556798
# char_by_tag <- function(x, tag) {
#   x_tags <- vapply(x, function(e) attr(e, "Rd_tag"), "")
#   vapply(x[x_tags == tag], as.character, "")
# }
tdavec_functions |> 
  select(name) |> 
  mutate(help = map(name, help, package = "TDAvec")) |> 
  mutate(doc = map(help, utils:::.getHelpFile)) |> 
  # mutate(title = map_chr(doc, char_by_tag, tag = "\\title")) |> 
  mutate(title = map_chr(
    doc,
    \(x) unlist(x[vapply(x, function(e) attr(e, "Rd_tag"), "") == "\\title"])
  )) |> 
  print() -> tdavec_content

# words to keep capitalized
proper_names <- c("Betti", "Euler")

#' ADAPTATION

#' Rename functions and parameters.

# CHOICE: rename functions for step names & documentation
vec_renames <- c(
  EulerCharacteristic = "EulerCharacteristicCurve",
  NormalizedLife = "NormalizedLifeCurve",
  PersistentEntropy = "PersistentEntropySummary",
  Stats = "DescriptiveStatistics",
  TemplateFunction = "TentTemplateFunctions"
)
tdavec_functions |> 
  select(name) |> 
  mutate(rename = gsub("^compute", "", name)) |> 
  mutate(rename = ifelse(
    rename %in% names(vec_renames),
    unname(vec_renames[rename]),
    rename
  )) |> 
  print() -> tdavec_renames

# all parameters used by {TDAvec} vectorization functions
tdavec_functions |> 
  transmute(name, arg = map(args, names)) |> 
  unnest(arg) |> 
  nest(funs = c(name)) |> 
  # filter(arg != "D") |> 
  arrange(desc(map_int(funs, nrow))) |> 
  print() -> tdavec_args
# which vectorizations use which parameters
tdavec_args |> 
  mutate(funs = map(funs, deframe)) |> 
  mutate(funs = map(funs, gsub, pattern = "compute", replacement = "")) |> 
  mutate(funs = map_chr(funs, paste, collapse = ", ")) |> 
  print(n = Inf)

# CHOICE: assign parameter names (existing or new) for recipe steps
arg_params <- c(
  homDim = "hom_degree",
  maxhomDim = "max_hom_degree",
  scaleSeq = "xseq",
  xSeq = "xseq",
  ySeq = "yseq",
  evaluate = "evaluate",
  # ComplexPolynomial
  m = "num_coef",
  polyType = "poly_type",
  # PersistenceBlock
  tau = "block_size",
  # PersistenceImage
  sigma = "img_sigma",
  # PersistenceLandscape
  k = "num_levels",
  generalized = "generalized",
  kernel = "weight_func",
  h = "bandwidth",
  # TODO: Check that the silhouette function uses this as a distance power.
  # PersistenceSilhouette
  p = "weight_power",
  # TemplateFunction
  delta = "tent_delta",
  d = "num_bins",
  epsilon = "tent_offset",
  # TropicalCoordinates
  r = "num_bars"
)

# document parameters
param_docs <- list(
  hom_degree = c(
    "The homological degree of the features to be transformed."
  ),
  max_hom_degree = c(
    "The highest degree, starting from 0, of the features to be transformed."
  ),
  xseq = c(
    "A discretization grid, as an increasing numeric vector.",
    "`xseq` overrides the other `x*` parameters with a warning."
  ),
  xother = c(
    "Limits and resolution of a discretization grid;",
    "specify only one of `xlen` and `xby`."
  ),
  yseq = c(
    "Combined with `xseq` to form a 2-dimensional discretization grid."
  ),
  yother = c(
    "Limits and resolution of a discretization grid;",
    "specify only one of `ylen` and `yby`."
  ),
  evaluate = c(
    "The method by which to vectorize continuous functions over a grid,",
    "either 'intervals' or 'points'.",
    "Some functions only admit one method."
  ),
  # ComplexPolynomial
  num_coef = c(
    "The number of coefficients of a convex polynomial",
    "fitted to finite persistence pairs."
  ),
  poly_type = c(
    "The type of complex polynomial to fit ('R', 'S', or 'T')."
  ),
  # PersistenceImage
  img_sigma = c(
    "The standard deviation of the gaussian distribution",
    "convolved with persistence diagrams to obtain persistence images."
  ),
  # PersistenceLandscape
  num_levels = c(
    "The number of levels of a persistence landscape to vectorize.",
    "If `num_levels` is greater than the length of a landscape,",
    "then additional levels of zeros will be included."
  ),
  generalized = c(
    "Logical indicator to compute generalized functions."
  ),
  # TODO: Inherit iff the choices are exactly the same.
  # weight_func = c("parsnip::nearest_neighbor"),
  weight_func = c(
    "A _single_ character for the type of kernel function",
    "used to compute generalized landscapes."
  ),
  bandwidth = c(
    "The bandwidth of a kernel function."
  ),
  # PersistenceSilhouette
  weight_power = c(
    "The power of weights in a persistence silhouette function."
  ),
  # TropicalCoordinates
  num_bars = c(
    "Number of bars (persistent pairs) over which to maximize...."
  ),
  # TemplateFunction
  tent_delta = c(
    "The length of the increment used to discretize tent template functions."
  ),
  num_bins = c(
    "The number of bins along each axis in the discretization grid."
  ),
  tent_offset = c(
    "The vertical shift applied to the discretization grid."
  ),
  # PersistenceBlock
  block_size = c(
    "The scaling factor of the squares used to obtain persistence blocks.",
    "The side length of the square centered at a feature \\eqn{{(b,p)}}",
    "is obtained by multiplying \\eqn{{2p}} by this factor."
  )
)

# CHOICE: assign param default values (omit to inherit from original args)
list(
  # consistent behavior across all steps
  hom_degree = 0L,
  max_hom_degree = Inf,
  # missing or disfavored original defaults
  img_sigma = 1,
  num_levels = 6L, bandwidth = 0.1,
  tent_delta = 0.1, num_bins = 12L, tent_offset = 0
) |> 
  sapply(deparse) |> 
  enframe(name = "param", value = "default") |> 
  print() -> param_new_defaults
# use to impute missing or overwrite original defaults
tdavec_defaults |> 
  left_join(enframe(arg_params, name = "arg", value = "param"), by = "arg") |> 
  left_join(param_new_defaults, by = "param", suffix = c("_arg", "_param")) |> 
  mutate(default = ifelse(is.na(default_param), default_arg, default_param)) |> 
  select(-contains("default_")) |> 
  print(n = Inf) -> param_defaults

# # CHOICE: assign dials to parameters
# param_dials <- c(
#   hom_degree = "hom_degree",
#   max_hom_degree = "hom_degree",
#   # TODO: Revisit this name.
#   num_levels = "num_levels",
#   weight_power = "weight_power",
#   img_sigma = "img_sigma",
#   block_size = "block_size"
# )

# list (tunable) parameters
param_bullets <- c(
  hom_degree = "Homological degree",
  max_hom_degree = "Highest homological degree",
  xseq = "Discretization intervals",
  yseq = "2D discretization intervals",
  evaluate = "Evaluation method",
  num_coef = "# Polynomial coefficients",
  poly_type = "Type of polynomial",
  img_sigma = "Convolved Gaussian standard deviation",
  num_levels = "# Levels or envelopes",
  generalized = "Use generalized functions?",
  bandwidth = "Kernel bandwidth",
  weight_power = "Exponent weight",
  num_bars = "# Bars (persistence pairs)",
  tent_delta = "Discretization grid increment",
  num_bins = "Discretization grid bins",
  tent_offset = "Discretization grid offset",
  block_size = "Square side length scaling factor"
)

# categorize new dials by input type & as quantitative or qualitative
type_class <- c(
  integer = "quant",
  double = "quant",
  logical = "qual",
  character = "qual"
)
dial_types <- c(
  hom_degree     = "integer",
  max_hom_degree = "integer",
  # xseq = "",
  # yseq = "",
  evaluate       = "character",
  num_coef       = "integer",
  poly_type      = "character",
  img_sigma      = "double",
  num_levels     = "integer",
  generalized    = "logical",
  bandwidth      = "double",
  weight_power   = "double",
  num_bars       = "integer",
  tent_delta     = "double",
  num_bins       = "integer",
  tent_offset    = "double",
  block_size     = "double"
)
# CHOICE: assign defaults to new dials & o/w note how to determine from data
# NOTE: Finalizers are written in `R/vpd-finalizers.R`.
dial_ranges_values <- list(
  # highest degree
  hom_degree = c(0L, NA_integer_),
  max_hom_degree = c(0L, NA_integer_),
  evaluate = c("intervals", "points"),
  # number of features
  num_coef = c(1L, NA_integer_),
  poly_type = c("R", "S", "T"),
  # maximum persistence
  img_sigma = c(NA_real_, NA_real_),
  # number of features
  num_levels = c(1L, NA_integer_),
  # generalized = c(FALSE, TRUE),
  # TODO: Consult Berry, Chen, Cisewski-Kehe, & Fasy (2020).
  bandwidth = c(NA_real_, NA_real_),
  weight_power = c("1", "2"),
  # number of features
  num_bars = c(1L, NA_integer_),
  # TODO: Consult Perea, Munch, & Khasawneh (2023).
  tent_delta = c(NA_real_, NA_real_),
  # TODO: Consult Perea, Munch, & Khasawneh (2023).
  num_bins = c(1L, NA_integer_),
  # TODO: Consult Perea, Munch, & Khasawneh (2023).
  tent_offset = c(NA_real_, NA_real_),
  block_size = c(0, 1)
)
# dial range endpoints
dial_inclusive <- list(
  hom_degree = c(TRUE, TRUE),
  max_hom_degree = c(TRUE, TRUE),
  num_coef = c(TRUE, TRUE),
  img_sigma = c(TRUE, TRUE),
  num_levels = c(TRUE, TRUE),
  weight_power = c(TRUE, TRUE),
  num_bars = c(TRUE, TRUE),
  tent_delta = c(TRUE, TRUE),
  num_bins = c(TRUE, TRUE),
  tent_offset = c(TRUE, TRUE),
  block_size = c(TRUE, TRUE)
)
# dial transformations
dial_transforms <- list(
  # hom_degree = NULL,
  img_sigma = expr(transform_log10()),
  # TODO: Revisit this choice. Compare to publication. Harmonize with endpoints.
  tent_delta = expr(transform_log10()),
  tent_offset = expr(transform_log10()),
  block_size = expr(transform_log10())
)



#' HELPERS

#' Format text.

# abbr_vec <- function(name) tolower(gsub("^compute", "", name))
# get snakecase name of vectorization method
vec_sname <- function(name) {
  name <- tdavec_renames$rename[tdavec_renames$name == name]
  name <- snakecase::to_snake_case(name)
  name
}
# vec_sname("computePersistenceLandscape")

# capitalize proper names
capitalize_proper_names <- function(full_name) {
  for (s in proper_names) {
    full_name <- gsub(tolower(s), s, full_name)
  }
  full_name
}
# capitalize_proper_names("euler characteristic curve")

# wrap external objects in hyperlink syntax
# [ggplot2::draw_key_point()]
link_obj <- function(name) {
  env <- pryr::where(name)
  pkg <- gsub("^package\\:", "", attr(env, "name"))
  # search <- paste0("package:", pkg)
  # stopifnot(name %in% as.character(lsf.str(search)))
  res <- paste0(
    "[",
    if (pkg == "tdarec") "" else paste0(pkg, "::"),
    name,
    if (class(get(name)) == "function") "()" else "",
    "]"
  )
  res
}
# load_all()
# link_obj("step_phom_point_cloud")
# link_obj("computePersistenceLandscape")
# # FIXME: This should link to `dials::check_param`, but it is not exported.
# link_obj("check_param")

# surround lines of documentation with "#' " and "\n"
doc_wrap <- function(s) paste0("#' ", s, "\n")
