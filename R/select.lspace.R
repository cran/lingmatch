#' Select Latent Semantic Spaces
#'
#' Retrieve information and links to latent semantic spaces
#' (sets of word vectors/embeddings) available at \href{https://osf.io/489he}{osf.io/489he},
#' and optionally download their term mappings (\href{https://osf.io/xr7jv}{osf.io/xr7jv}).
#'
#' @param query A character used to select spaces, based on names or other features.
#'   If length is over 1, \code{get.map} is set to \code{TRUE}. Use \code{terms} alone to select
#'   spaces based on term coverage.
#' @param dir Path to a directory containing \code{lma_term_map.rda} and downloaded spaces; \cr will look in
#'   \code{getOption('lingmatch.lspace.dir')} and \code{'~/Latent Semantic Spaces'} by default.
#' @param terms A character vector of terms to search for in the downloaded term map, to calculate
#'   coverage of spaces, or select by coverage if \code{query} is not specified.
#' @param get.map Logical; if \code{TRUE} and \code{lma_term_map.rda} is not found in
#'   \code{dir}, the term map (\href{https://osf.io/xr7jv}{lma_term_map.rda}) is
#'   downloaded and decompressed.
#' @param check.md5 Logical; if \code{TRUE} (default), retrieves the MD5 checksum from OSF,
#'   and compares it with that calculated from the downloaded file to check its integrity.
#' @param mode Passed to \code{\link{download.file}} when downloading the term map.
#' @return A list with varying entries:
#'   \itemize{
#'     \item \strong{\code{info}}: The version of \href{https://osf.io/9yzca}{osf.io/9yzca} stored internally; a
#'       \code{data.frame}  with spaces as row names, and information about each space in columns:
#'         \itemize{
#'           \item \strong{\code{terms}}: number of terms in the space
#'           \item \strong{\code{corpus}}: corpus(es) on which the space was trained
#'           \item \strong{\code{model}}: model from which the space was trained
#'           \item \strong{\code{dimensions}}: number of dimensions in the model (columns of the space)
#'           \item \strong{\code{model_info}}: some parameter details about the model
#'           \item \strong{\code{original_max}}: maximum value used to normalize the space; the original
#'             space would be \code{(vectors *} \code{original_max) /} \code{100}
#'           \item \strong{\code{osf_dat}}: OSF id for the \code{.dat} files; the URL would be
#'             https://osf.io/\code{osf_dat}
#'           \item \strong{\code{osf_terms}}: OSF id for the \code{_terms.txt} files; the URL would be
#'             https://osf.io/\code{osf_terms}
#'           \item \strong{\code{wiki}}: link to the wiki for the space
#'           \item \strong{\code{downloaded}}: path to the \code{.dat} file if downloaded,
#'             and \code{''} otherwise.
#'         }
#'     \item \strong{\code{selected}}: A subset of \code{info} selected by \code{query}.
#'     \item \strong{\code{term_map}}: If \code{get.map} is \code{TRUE} or \code{lma_term_map.rda} is found in
#'       \code{dir}, a copy of \href{https://osf.io/xr7jv}{osf.io/xr7jv}, which has space names as
#'       column names, terms as row names, and indices as values, with 0 indicating the term is not
#'       present in the associated space.
#'   }
#' @family Latent Semantic Space functions
#' @examples
#' # just retrieve information about available spaces
#' spaces <- select.lspace()
#' spaces$info[1:10, c("terms", "dimensions", "original_max")]
#'
#' # retrieve all spaces that used word2vec
#' w2v_spaces <- select.lspace("word2vec")$selected
#' w2v_spaces[, c("terms", "dimensions", "original_max")]
#'
#' \dontrun{
#'
#' # select spaces by terms
#' select.lspace(terms = c(
#'   "part-time", "i/o", "'cause", "brexit", "debuffs"
#' ))$selected[, c("terms", "coverage")]
#' }
#' @export

select.lspace <- function(query = NULL, dir = getOption("lingmatch.lspace.dir"), terms = NULL,
                          get.map = FALSE, check.md5 = TRUE, mode = "wb") {
  if (ckd <- dir == "") dir <- "~/Latent Semantic Spaces"
  if (!missing(query) && !is.character(query) && !is.null(colnames(query))) {
    terms <- colnames(query)
    query <- NULL
  }
  map_path <- normalizePath(paste0(dir, "/lma_term_map.rda"), "/", FALSE)
  if (missing(get.map) && (file.exists(map_path) || length(terms) > 1)) get.map <- TRUE
  if (!exists("lma_term_map")) lma_term_map <- NULL
  if (get.map && ckd && !dir.exists(dir)) stop("specify `dir` or use `lma_initdirs()` to download the term map")
  if (get.map && !(file.exists(map_path) || !is.null(lma_term_map))) {
    fi <- tryCatch(
      strsplit(readLines("https://api.osf.io/v2/files/xr7jv", 1, TRUE, FALSE, "utf-8"), '[:,{}"]+')[[1]],
      error = function(e) NULL
    )
    if (!file.exists(map_path) || (!is.null(fi) && md5sum(map_path) != fi[which(fi == "md5") + 1])) {
      dir.create(dir, FALSE, TRUE)
      status <- tryCatch(download.file(
        "https://osf.io/download/xr7jv", map_path,
        mode = mode
      ), error = function(e) 1)
      if (!status && check.md5 && !is.null(fi)) {
        ck <- md5sum(map_path)
        if (fi[which(fi == "md5") + 1] == ck) {
          load(map_path)
          save(lma_term_map, file = map_path, compress = FALSE)
        } else {
          warning(paste0(
            "The term map's MD5 (", ck, ") does not seem to match the one on record;\n",
            "double check and try manually downloading at https://osf.io/xr7jv/?show=revision"
          ))
        }
      }
    }
  } else if (!file.exists(map_path) && !is.null(terms)) {
    stop("The term map could not be found; specify dir or run lma_initdirs('~') to download it", call. = FALSE)
  }
  r <- list(info = lss_info, selected = lss_info[NULL, ])
  r$info[, "wiki"] <- paste0("https://osf.io/489he/wiki/", rownames(lss_info))
  r$info[, "downloaded"] <- normalizePath(paste0(dir, "/", rownames(r$info), ".dat"), "/", FALSE)
  r$info[!file.exists(r$info[, "downloaded"]), "downloaded"] <- ""
  if (get.map) {
    if (!is.null(lma_term_map)) {
      r$term_map <- lma_term_map
    } else if (file.exists(map_path) && is.null(lma_term_map)) {
      load(map_path)
      r$term_map <- lma_term_map
      rm(list = "lma_term_map")
    }
  }
  if (!is.null(terms)) {
    if (length(terms) > 1 && "term_map" %in% names(r)) {
      terms <- tolower(terms)
      overlap <- terms[terms %in% rownames(r$term_map)]
      if (length(overlap)) {
        r$info$coverage <- colSums(r$term_map[overlap, , drop = FALSE] != 0) / length(terms)
        r$selected <- r$info[order(r$info$coverage, decreasing = TRUE)[1:5], ]
        r$space_terms <- overlap
      } else {
        warning("no terms were found")
      }
    }
  }
  if (!is.null(query)) {
    query <- paste0(query, collapse = "|")
    if (!length(sel <- grep(query, rownames(lss_info), TRUE))) {
      collapsed <- vapply(
        seq_len(nrow(lss_info)),
        function(r) paste(c(rownames(lss_info)[r], lss_info[r, ]), collapse = " "), ""
      )
      if (!length(sel <- grep(query, collapsed, TRUE))) {
        sel <- grep(paste(strsplit(query, "[[:space:],|]+")[[1]], collapse = "|"), collapsed, TRUE)
      }
    }
    if (length(sel)) r$selected <- r$info[sel, ]
  }
  r
}
