#' S3 methods for tracking which additional packages are needed for steps.
#'
#' Recipe-adjacent packages always list themselves as a required package so that
#' the steps can function properly within parallel processing schemes.
#' @param x A recipe step.
#' @return A character vector.
#' @rdname required_pkgs.tdarec
#' @keywords internal
#' @export
required_pkgs.step_tdarec <- function(x, ...) {
  c("tdarec")
}

#' @title A *recipes* and *dials* Extension for Persistent Homology
#'
#' @description

#' The *tdarec* package extends *recipes* and *dials* by providing
#' pre-processing steps with tunable parameters for computing persistent
#' homology of suitable data and for vectorizing persistent homology.
#'
#' @import recipes
#' @name tdarec
#' @importFrom rlang on_load run_on_load
#' @importFrom dials new_qual_param new_quant_param unknown
"_PACKAGE"

# installed version of {ripserr}, or `NULL` if not installed
.onLoad <- function(...) {
  rlang::run_on_load()
}
rlang::on_load(
  .ripserr_version <-
    if ("ripserr" %in% rownames(utils::installed.packages())) {
      utils::packageVersion("ripserr")
    } else NA_character_
)
# to check that the ripserr engine can handle input data
rlang::on_load({
  # Vietoris-Rips filtration
  .ripserr_vietoris_rips_classes <- if (.ripserr_version == "0.1.1") {
    # https://github.com/cran/ripserr/blob/
    # 8cadc3a86009149418d6f9a61124af9d6372d34e/R/calculate.R#L68
    c(
      "dist", "matrix",
      gsub("as\\.matrix\\.", "",
           as.character(utils::methods(base::as.matrix)))
    )
  } else if (.ripserr_version >= "0.2.0") {
    gsub("vietoris_rips\\.", "",
         as.character(utils::methods(ripserr::vietoris_rips)))
  }
  .ripserr_vietoris_rips_classes <- 
    setdiff(.ripserr_vietoris_rips_classes, "default")
  # cubical filtration
  .ripserr_cubical_classes <- if (.ripserr_version == "0.1.1") {
    # https://github.com/cran/ripserr/blob/
    # 8cadc3a86009149418d6f9a61124af9d6372d34e/R/calculate.R#L177
    c("array", "matrix")
  } else if (.ripserr_version >= "0.2.0") {
    gsub("cubical\\.", "",
         as.character(utils::methods(ripserr::cubical)))
  }
  .ripserr_cubical_classes <- setdiff(.ripserr_cubical_classes, "default")
})
