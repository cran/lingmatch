#' Linguistic Matching and Accommodation
#'
#' Offers a variety of methods to assess linguistic matching or accommodation, where \emph{matching}
#' is general similarity (sometimes called \emph{homophily}), and \emph{accommodation} is some form
#' of conditional similarity (accounting for some base-rate or precedent; sometimes called
#' \emph{alignment}).
#'
#' There are a great many points of decision in the assessment of linguistic similarity and/or
#' accommodation, partly inherited from the great many point of decision inherent in the numerical
#' representation of language. Two general types of matching are implemented here as sets of
#' defaults: Language/Linguistic Style Matching (LSM; Niederhoffer & Pennebaker, 2002; Ireland &
#' Pennebaker, 2010), and Latent Semantic Analysis/Similarity (LSA; Landauer & Dumais, 1997;
#' Babcock, Ta, & Ickes, 2014). See the \code{type} argument for specifics.
#'
#' @param input Texts to be compared; a vector, document-term matrix (dtm; with terms as column names),
#'   or path to a file (.txt or .csv, with texts separated by one or more lines/rows).
#' @param comp Defines the comparison to be made:
#' \itemize{
#'   \item If a \strong{function}, this will be applied to \code{input} within each group (overall if there is
#'     no group; i.e., \code{apply(input, 2, comp)}; e.g., \code{comp = mean} would compare each text to
#'     the mean profile of its group).
#'   \item If a \strong{character} with a length of 1 and no spaces:
#'     \itemize{
#'       \item If it partially matches one of \code{lsm_profiles}'s rownames, that row will be used as the comparison.
#'       \item If it partially matches \code{'auto'}, the highest correlating \code{lsm_profiles} row will be used.
#'       \item If it partially matches \code{'pairwise'}, each text will be compared to one another.
#'       \item If it partially matches \code{'sequential'}, the last variable in \code{group} will be treated as
#'         a speaker ID (see the Grouping and Comparisons section).
#'     }
#'   \item If a \strong{character vector}, this will be processed in the same way as \code{input}.
#'   \item If a \strong{vector}, either (a) logical or factor-like (having n levels < length) and of the same length as
#'     \code{nrow(input)}, or (b) numeric or logical of length less than \code{nrow(input)}, this will be used to
#'     select a subset of \code{input} (e.g., \code{1:10} would treat the first 10 rows of \code{input} as the
#'     comparison; \code{lingmatch(text, type == 'prompt', data)} would use the texts in the \code{text} column
#'     identified by the \code{type} column as the comparison).
#'   \item If a \strong{matrix-like object} (having multiple rows and columns), or a named vector, this will
#'     be treated as a sort of dtm, assuming there are common (column) names between \code{input} and
#'     \code{comp} (e.g., if you had prompt and response texts that were already processed separately).
#' }
#' @param data A matrix-like object as a reference for column names, if variables are referred to in
#'   other arguments (e.g., \code{lingmatch(text, data = data)} would be the same as
#'   \code{lingmatch(data$text)}.
#' @param group A logical or factor-like vector the same length as \code{NROW(input)}, used to defined
#'   groups.
#' @param ... Passes arguments to \code{\link{lma_dtm}}, \code{\link{lma_weight}},
#'   \code{\link{lma_termcat}}, and/or \code{\link{lma_lspace}} (depending on \code{input} and \code{comp}),
#'   and \code{\link{lma_simets}}.
#' @param comp.data A matrix-like object as a source for \code{comp} variables.
#' @param comp.group The column name of the grouping variable(s) in \code{comp.data}; if
#'   \code{group} contains references to column names, and \code{comp.group} is not specified,
#'   \code{group} variables will be looked for in \code{comp.data}.
#' @param order A numeric vector the same length as \code{nrow(input)} indicating the order of the
#'   texts and grouping variables when the type of comparison is sequential. Only necessary if the
#'   texts are not already ordered as desired.
#' @param drop logical; if \code{TRUE}, will drop columns with a sum of 0.
#' @param all.levels logical; if \code{FALSE}, multiple groups are combined. See the Grouping and
#'   Comparisons section.
#' @param type A character at least partially matching 'lsm' or 'lsa'; applies default settings
#'   aligning with the standard calculations of each type:
#'   \tabular{ll}{
#'     LSM \tab \code{lingmatch(text, weight = 'freq', dict = lma_dict(1:9), metric = 'canberra')}\cr
#'     LSA \tab \code{lingmatch(text, weight = 'tfidf', space = '100k_lsa', metric = 'cosine')}\cr
#'   }
#' @section Grouping and Comparisons:
#' Defining groups and comparisons can sometimes be a bit complicated, and requires dataset
#' specific knowledge, so it can't always (readily) be done automatically. Variables entered in the
#' \code{group} argument are treated differently depending on their position and other arguments:
#'
#' \describe{
#'   \item{Splitting}{By default, groups are treated as if they define separate chunks of data in
#'     which comparisons should be calculated. Functions used to calculated comparisons, and
#'     pairwise comparisons are performed separately in each of these groups. For example, if you
#'     wanted to compare each text with the mean of all texts in its condition, a \code{group}
#'     variable could identify and split by condition. Given multiple grouping variables,
#'     calculations will either be done in each split (if \code{all.levels = TRUE}; applied in
#'     sequence so that groups become smaller and smaller), or once after all splits are made (if
#'     \code{all.levels = FALSE}). This makes for 'one to many' comparisons with either calculated
#'     or preexisting standards (i.e., the profile of the current data, or a precalculated profile,
#'     respectively).}
#'   \item{Comparison ID}{When comparison data is identified in \code{comp}, groups are assumed
#'     to apply to both \code{input} and \code{comp} (either both in \code{data}, or separately
#'     between \code{data} and \code{comp.data}, in which case \code{comp.group} may be needed if
#'     the same grouping variable have different names between \code{data} and \code{comp.data}).
#'     In this case, multiple grouping variables are combined into a single factor assumed to
#'     uniquely identify a comparison. This makes for 'one to many' comparisons with specific texts
#'     (as in the case of manipulated prompts or text-based conditions).}
#'   \item{Speaker ID}{If \code{comp} matches \code{'sequential'}, the last grouping variable
#'     entered is assumed to identify something like speakers (i.e., a factor with two or more
#'     levels and multiple observations per level). In this case, the data are assumed to be ordered
#'     (or ordered once sorted by \code{order} if specified). Any additional grouping variables
#'     before the last are treated as splitting groups. This can set up for probabilistic
#'     accommodation metrics. At the moment, when sequential comparisons are made within groups,
#'     similarity scores between speakers are averaged, resulting in mean matching between speakers
#'     within the group.}
#' }
#' @references
#' Babcock, M. J., Ta, V. P., & Ickes, W. (2014). Latent semantic similarity and language style
#'   matching in initial dyadic interactions. \emph{Journal of Language and Social Psychology, 33},
#'   78-88.
#'
#' Ireland, M. E., & Pennebaker, J. W. (2010). Language style matching in writing: synchrony in
#'   essays, correspondence, and poetry. \emph{Journal of Personality and Social Psychology, 99},
#'   549.
#'
#' Landauer, T. K., & Dumais, S. T. (1997). A solution to Plato's problem: The latent semantic
#'   analysis theory of acquisition, induction, and representation of knowledge.
#'   \emph{Psychological Review, 104}, 211.
#'
#' Niederhoffer, K. G., & Pennebaker, J. W. (2002). Linguistic style matching in social interaction.
#'   \emph{Journal of Language and Social Psychology, 21}, 337-360.
#' @seealso For a general text processing function, see \code{\link{lma_process}()}.
#' @return A list with processed components of the input, information about the comparison, and results of
#' the comparison:
#' \itemize{
#'   \item \strong{\code{dtm}}: A sparse matrix; the raw count-dtm, or a version of the original input
#'     if it is more processed.
#'   \item \strong{\code{processed}}: A matrix-like object; a processed version of the input
#'     (e.g., weighted and categorized).
#'   \item \strong{\code{comp.type}}: A string describing the comparison if applicable.
#'   \item \strong{\code{comp}}: A vector or matrix-like object; the comparison data if applicable.
#'   \item \strong{\code{group}}: A string describing the group if applicable.
#'   \item \strong{\code{sim}}: Result of \code{\link{lma_simets}}.
#' }
#' @examples
#' # compare single strings
#' lingmatch("Compare this sentence.", "With this other sentence.")
#'
#' # compare each entry in a character vector with...
#' texts <- c(
#'   "One bit of text as an entry...",
#'   "Maybe multiple sentences in an entry. Maybe essays or posts or a book.",
#'   "Could be lines or a column from a read-in file..."
#' )
#'
#' ## one another
#' lingmatch(texts)
#'
#' ## the first
#' lingmatch(texts, 1)
#'
#' ## the next
#' lingmatch(texts, "seq")
#'
#' ## the set average
#' lingmatch(texts, mean)
#'
#' ## other entries in a group
#' lingmatch(texts, group = c("a", "a", "b"))
#'
#' ## one another, without stop words
#' lingmatch(texts, exclude = "function")
#'
#' ## a standard average (based on function words)
#' lingmatch(texts, "auto", dict = lma_dict(1:9))
#'
#' @export
#' @import methods Matrix
#' @importFrom stats na.omit dpois ppois
#' @importFrom Rcpp sourceCpp
#' @importFrom RcppParallel RcppParallelLibs
#' @useDynLib lingmatch, .registration = TRUE

lingmatch <- function(input = NULL, comp = mean, data = NULL, group = NULL, ..., comp.data = NULL, comp.group = NULL, order = NULL,
                      drop = FALSE, all.levels = FALSE, type = "lsm") {
  inp <- as.list(substitute(...()))
  # setting up a default type if specified
  if (!missing(type) && !is.null(type)) {
    type <- if (grepl("lsm|lang|ling|style|match", type, TRUE)) "lsm" else "lsa"
    ni <- names(inp)
    if (type == "lsm" && !"dict" %in% ni) inp$dict <- lma_dict(1:9)
    if (type != "lsm" && !"space" %in% ni) inp$space <- "100k_lsa"
    if (!"metric" %in% ni) inp$metric <- if (type == "lsm") "canberra" else "cosine"
    if (is.null(attr(input, "type")) || length(attr(input, "type")) == 1) {
      if (type == "lsm" && !"percent" %in% ni) inp$percent <- TRUE
      if (type != "lsm" && !"weight" %in% ni) inp$weight <- "tfidf"
    }
  }
  mets <- c("jaccard", "euclidean", "canberra", "cosine", "pearson")
  inp$metric <- if (!is.null(inp$metric)) match_metric(inp$metric)$selected else "cosine"
  if (!length(inp$metric) || all(inp$metric == "")) inp$metric <- "cosine"
  vs <- c("input", "comp", "group", "order", "data", "comp.data", "comp.group")
  opt <- as.list(match.call(expand.dots = FALSE))[vs]
  names(opt) <- vs
  # organizing options for preprocessing
  dsp <- lapply(c("lma_dtm", "lma_weight", "lma_lspace", "lma_termcat", "lma_simets"), function(f) {
    a <- names(as.list(args(f)))
    a <- a[-c(1, length(a))]
    inp[a[a %in% names(inp)]]
  })
  names(dsp) <- c("p", "w", "m", "c", "s")
  # fetches input from data or environment
  gv <- function(a, data = NULL) {
    ta <- a
    if (is.character(a)) {
      if (!is.null(data) && a %in% colnames(data)) {
        return(unlist(data[, a]))
      } else if (length(ta) == 1 || !any(grepl(" ", a, fixed = TRUE))) ta <- parse(text = a)
    }
    ta <- tryCatch(eval(ta, parent.frame(2)), error = function(e) NULL)
    if (!length(ta) || (!is.null(dim(ta)) && !dim(ta)[1])) {
      ta <- tryCatch(eval(a, data, parent.frame(2)), error = function(e) NULL)
      if (!length(ta) || (!is.null(dim(ta)) && !dim(ta)[1])) {
        ta <- tryCatch(eval(a, globalenv()), error = function(e) NULL)
        if (is.null(ta)) {
          ta <- tryCatch(eval(a, data), error = function(e) NULL)
          if (is.null(ta)) {
            p <- 2
            while (is.null(ta) && p < 99) {
              p <- p + 1
              ta <- tryCatch(eval(a, parent.frame(p)), error = function(e) NULL)
            }
          }
          if (is.null(ta)) stop("could not find ", deparse(a), call. = FALSE)
        }
      }
    }
    ta
  }
  gd <- function(a, data = NULL) {
    r <- if (is.character(a) && length(a) == 1 && grepl("\\.(?:csv|txt|tsv|tab)$", a, TRUE)) {
      if (file.exists(a)) {
        r <- if (grepl("txt$", a)) {
          readLines(a, warn = FALSE)
        } else {
          r <- read.table(a, TRUE, if (grepl("csv$", a)) "," else "\t", '"', comment.char = "")
          r[, which(!vapply(r, is.numeric, TRUE))[1]]
        }
        r[r != ""]
      } else {
        stop(a, " does not exist", call. = FALSE)
      }
    } else if (is.character(a)) a else gv(a, data)
    if (is.factor(r)) r <- as.character(r)
    if (is.character(r) && length(r) == 1 && grepl("\\.(?:csv|txt|tsv|tab)$", r, TRUE)) r <- gd(r)
    r
  }
  # weight, categorize, and/or map
  wmc <- function(a) {
    if (!is.null(colnames(a)) || (length(dsp$c) == 0 && length(dsp$m) == 0)) {
      if (length(dsp$w) != 0) a <- do.call(lma_weight, c(list(a), lapply(dsp$w, eval, parent.frame(2))))
      if (length(dsp$c) != 0) a <- do.call(lma_termcat, c(list(a), lapply(dsp$c, eval, parent.frame(2))))
      if (length(dsp$m) != 0) a <- do.call(lma_lspace, c(list(a), lapply(dsp$m, eval, parent.frame(2))))
    }
    a
  }
  # initial data parsing
  # input
  if (missing(input)) {
    if (!is.null(data)) {
      opt$input <- opt$data
      input <- data
    } else {
      input <- file.choose()
      opt$input <- input
    }
  }
  if (is.function(input) || ((is.list(input) || is.numeric(input)) && is.null(dim(input)))) {
    stop(
      "enter a character vector or matrix-like object as input",
      call. = FALSE
    )
  }
  if (missing(data)) data <- input
  input <- if (is.character(input) && all(input %in% colnames(data))) data[, input] else gd(opt$input, data)
  if (!missing(group) && is.data.frame(input)) input <- as.matrix(input[, vapply(input, is.numeric, TRUE)])
  rx <- NROW(input)
  # comp
  if (!missing(comp)) {
    comp <- gd(opt$comp, if (missing(comp.data)) if (is.call(opt$comp)) NULL else data else comp.data)
    if (!missing(comp.data) && is.character(comp) && all(comp %in% colnames(comp.data))) comp <- comp.data[, comp]
    if (!missing(data) && is.character(comp) && all(comp %in% colnames(data))) comp <- data[, comp]
    if (is.logical(comp)) comp <- which(comp)
    if (missing(comp.data) && !is.null(colnames(comp))) comp.data <- comp
  } else if (missing(comp) && missing(group) && missing(comp.data) && missing(comp.group)) {
    opt$comp <- comp <- "pairwise"
  } else {
    opt$comp <- "mean"
  }
  if (length(opt$comp) > 1) opt$comp <- deparse(opt$comp)
  if (is.factor(input)) input <- as.character(input)
  if (is.factor(comp)) {
    comp <- as.character(comp)
  } else if (is.data.frame(comp)) {
    comp <- comp[, vapply(comp, is.numeric, TRUE)]
  }
  do.wmc <- TRUE
  if ("dict" %in% names(inp) && any(class(input) %in% c("matrix", "data.frame")) &&
    is.null(attr(input, "Type"))) {
    cn <- colnames(input)
    dn <- gv(inp$dict)
    if (is.list(dn)) dn <- names(dn)
    if (any(!(ck <- dn %in% cn))) {
      cat_map <- structure(c(rep(colnames(lsm_profiles), 2), "article", "prep"), names = c(
        colnames(lsm_profiles), "personal_pronouns", "impersonal_pronouns", "articles", "auxiliary_verbs",
        "adverbs", "prepositions", "conjunctions", "negations", "quantifiers", "articles", "preps"
      ))
      cn <- sub("^liwc[ .:_-]+", "", tolower(cn))
      tr <- cn %in% names(cat_map)
      if (any(tr)) colnames(input)[tr] <- cat_map[cn[tr]]
      ck <- dn %in% colnames(input)
    }
    if (sum(ck) / length(ck) > .75) {
      inp$dict <- NULL
      if (any(!ck)) dn <- dn[ck]
      input <- input[, dn]
      do.wmc <- FALSE
      if (!missing(comp) && any(class(comp) %in% c("matrix", "data.frame")) && all(dn %in% colnames(comp))) {
        comp <- comp[, dn]
      }
    }
  }
  if (!is.matrix(input) && is.character(input)) {
    # if input looks like text, seeing if other text can be added, then converting to a dtm
    if (is.character(comp) && (length(comp) > 1 || grepl(" ", comp, fixed = TRUE))) {
      input <- c(comp, input)
      comp <- seq_along(comp)
      opt$comp <- "text"
    }
    input <- do.call(lma_dtm, c(list(input), dsp$p))
  }
  if (is.data.frame(comp)) comp <- as.matrix(comp)
  cc <- if (is.numeric(comp) && (!is.null(comp.data) || is.null(dim(comp)))) {
    1
  } else if (is.character(comp)) {
    comp <- tolower(comp)
    2
  } else {
    0
  }
  # group and order
  agc <- c("c", "list", "cbind", "data.frame")
  if (missing(group) && !missing(comp.group)) {
    group <- NULL
    opt$group <- opt$comp.group
  }
  if (!missing(group) && !(is.null(colnames(data)) && rx == length(opt$group) - 1)) {
    group <- if (length(opt$group) > 1 && as.character(opt$group[1]) %in% agc &&
      !grepl("[$[]", as.character(opt$group[1]))) {
      group <- tryCatch(gv(opt$group, data), error = function(e) NULL)
      if (is.character(group) && is.null(dim(group)) && all(group %in% colnames(data))) {
        group <- data[, group]
      }
      if (is.null(group)) lapply(opt$group[-1], gv, data) else group
    } else {
      if (!is.null(colnames(data)) && is.character(opt$group) && length(opt$group) < nrow(data)) {
        if (!all(opt$group %in% colnames(data))) {
          stop("group appears to be column names, but were not found in data", call. = FALSE)
        }
        group <- data[, opt$group]
        if (!is.list(group)) group <- if (is.matrix(group)) as.data.frame(group, stringsAsFactors = FALSE) else list(group)
      } else {
        group <- gv(opt$group, data)
        if (is.factor(group)) {
          group <- as.character(group)
        } else if (is.matrix(group)) {
          group <- as.data.frame(group, row.names = FALSE, stringsAsFactors = FALSE)
        }
        if (is.null(dim(group))) list(group) else lapply(group, as.character)
      }
    }
  }
  if (!missing(comp.group) || (!is.null(comp.data) && !missing(group))) {
    cg <- opt[[if (missing(comp.group)) "group" else "comp.group"]]
    if (!is.null(cg)) {
      cg <- if (!is.null(comp.data) && length(cg) > 1 &&
        as.character(cg[1]) %in% agc && !grepl("[$[]", as.character(cg[1]))) {
        cg <- tryCatch(gv(cg, comp.data), error = function(e) NULL)
        if (is.character(cg) && all(cg %in% colnames(comp.data))) cg <- comp.data[, cg]
        if (is.null(cg)) lapply(as.character(cg[-1]), gv, comp.data) else cg
      } else if (is.character(cg)) {
        if (cg %in% colnames(comp.data)) {
          list(comp.data[, cg])
        } else {
          stop("groups not found in comp.data", call. = FALSE)
        }
      } else {
        list(gv(cg, comp.data))
      }
      if (is.list(cg) && length(cg) == 1 && !is.null(dim(cg[[1]]))) {
        cg <- as.data.frame(cg[[1]], stringsAsFactors = FALSE)
      } else if (is.character(cg) && !missing(comp.group) && all(cg %in% colnames(comp.data))) {
        cg <- comp.data[, cg]
      }
      if (!missing(comp.group) || length(if (is.list(cg)) cg[[1]] else cg) == nrow(comp.data)) {
        if (all.levels) {
          comp.group <- cg
        } else {
          comp.group <- do.call(paste, cg)
          if (length(group) > 1) {
            group <- do.call(paste, group)
            if (!is.null(comp.data) && any(ck <- !(ckg <- unique(group)) %in% unique(comp.group))) {
              if (all(ck)) {
                stop("group and comp.group had no levels in common", call. = FALSE)
              } else {
                warning("levels not found in comp.group: ", paste(ckg[ck], collapse = ", "), call. = FALSE)
                group <- group[ck <- group %in% ckg[!ck]]
                input <- input[ck, , drop = FALSE]
              }
            }
          }
        }
      }
    }
  }
  if (!missing(group)) {
    if (is.matrix(group)) group <- as.data.frame(group)
    if (length(if (is.list(group)) group[[1]] else group) != rx) {
      stop("length(group) != nrow(input)", call. = FALSE)
    }
  }
  if (!missing(order)) {
    order <- gv(opt$order, data)
    if (!is.null(order)) {
      if (length(order) == rx) {
        input <- input[order, ]
        group <- lapply(group, "[", order)
      } else {
        warning("length(order) != nrow(input), so order was not applied", call. = FALSE)
      }
    } else {
      warning("failed to apply order", call. = FALSE)
    }
  }
  if (is.character(input)) input <- matrix(as.numeric(input), rx)
  if (is.data.frame(input) && any(ckvc <- !vapply(input, is.numeric, TRUE))) {
    if (all(ckvc)) {
      for (col in seq_along(ckvc)) input[, col] <- as.numeric(input[, col])
    } else {
      input <- input[, !ckvc]
      warning("some input variables were not numeric, so they were removed")
    }
  }
  dtm <- Matrix(if (is.data.frame(input)) as.matrix(input) else input, sparse = TRUE)
  if (do.wmc) input <- wmc(input)
  if (is.null(dim(input))) input <- t(as.matrix(input))
  if (cc == 2 && (length(comp) > 1 || any(grepl(" ", comp, fixed = TRUE)))) {
    comp <- do.call(lma_dtm, c(list(comp), dsp$p))
    cc <- 1
  }
  # if comp appears to be a dtm, unifying input and comp
  if (cc == 1 && !is.null(names(comp))) comp <- t(as.matrix(comp))
  cr <- nrow(comp)
  cn <- colnames(comp)
  if (!is.null(cn)) {
    cc <- 1
    nn <- cn[!cn %in% colnames(input)]
    if (length(nn) != 0) {
      input <- cbind(
        input, matrix(0, nrow(input), length(nn), dimnames = list(NULL, nn))
      )
    }
    input <- rbind(matrix(0, cr, ncol(input), dimnames = list(NULL, colnames(input))), input)
    input[seq_len(cr), cn] <- as.matrix(comp[seq_len(cr), ])
    comp <- seq_len(cr)
  }
  if (drop) {
    if (sum(su <- colSums(input, na.rm = TRUE) != 0) != 0) {
      input <- input[, su, drop = FALSE]
    } else {
      stop("input is all 0s after processing", call. = FALSE)
    }
  }
  nc <- ncol(input)
  # finalizing comp
  if (is.numeric(comp) && (cc == 1 || opt$comp == "text")) {
    comp.data <- input[comp, , drop = FALSE]
    if (!missing(comp.group) && !all.levels) {
      if (!anyDuplicated(comp.group) && nrow(comp.data) == length(comp.group)) {
        rownames(comp.data) <- comp.group
      }
    } else if (nrow(comp.data) == 1) {
      comp.data <- structure(as.numeric(comp.data[1, ]),
        names = colnames(comp.data)
      )
    }
    input <- input[-comp, , drop = FALSE]
  } else if (cc == 2) {
    ckp <- FALSE
    if (grepl("^pa|^se", comp)) {
      opt$comp <- if (grepl("^pa", comp)) "pairwise" else "sequential"
    } else if (any(!is.na(p <- pmatch(comp, rownames(lsm_profiles))))) {
      opt$comp <- rownames(lsm_profiles)[p]
      ckp <- TRUE
      comp.data <- lsm_profiles[p, , drop = FALSE]
    } else if (grepl("^au", comp)) {
      p <- colMeans(input, na.rm = TRUE)
      p <- which.max(lma_simets(lsm_profiles, p, "pearson"))
      opt$comp <- paste("auto:", names(p))
      ckp <- TRUE
      comp.data <- lsm_profiles[p, , drop = FALSE]
    } else {
      opt$comp <- substitute(comp)
    }
    if (ckp) {
      if (any(ckp <- !(cn <- colnames(input)) %in% (bn <- colnames(comp.data)))) {
        if (all(ckp)) stop("input and comp have no columns in common", call. = FALSE)
        if ("articles" %in% cn && !"articles" %in% bn) bn[bn == "article"] <- "articles"
        if ("preps" %in% cn && !"preps" %in% bn) bn[bn == "prep"] <- "preps"
        colnames(comp.data) <- bn
        if (any(ckp <- !cn %in% bn)) {
          warning("input columns were not found in comp: ", paste(cn[ckp], collapse = ", "), call. = FALSE)
          comp.data <- comp.data[, cn[!ckp], drop = FALSE]
        }
      } else {
        comp.data <- comp.data[, cn, drop = FALSE]
      }
    }
  } else if (!is.null(comp.data)) {
    cn <- colnames(input)
    cns <- cn[ck <- cn %in% colnames(comp.data)]
    if (!any(ck)) {
      stop("input and comp have no columns in common", call. = FALSE)
    } else if (any(!ck)) {
      warning("input columns were not found in comp: ", paste(cn[!ck], collapse = ", "), call. = FALSE)
      input <- input[, cns]
    }
    comp.data <- comp.data[, cns, drop = FALSE]
  }
  compmeanck <- opt$comp == "mean"
  sim <- speaker <- NULL
  if (!is.null(group)) {
    if (!is.null(comp.data) && (NROW(comp.data) == 1 || (is.list(group) && length(group[[1]]) != nrow(input)))) {
      group <- NULL
      warning("group does not appear to be meaningful for this comparison, so it was ignored",
        call. = FALSE
      )
    } else if (!is.list(group)) group <- list(group)
    gl <- length(group)
    if (opt$comp == "sequential") {
      speaker <- group[[gl]]
      group <- if (gl == 1) NULL else group[-gl]
      gl <- length(group)
    }
    if (gl > 1 && !all.levels) {
      group <- list(do.call(paste, group))
      gl <- 1
    }
    if (gl) {
      sim <- as.data.frame(group, stringsAsFactors = FALSE)
      colnames(sim) <- paste0("g", seq_len(gl))
      for (m in inp$metric) sim[, m] <- NA
      mets <- seq_along(inp$metric) + gl
    }
  } else if (opt$comp == "sequential" && is.null(speaker)) speaker <- seq_len(nrow(input))
  # making comparisons
  sal <- dsp$s
  ck_grouppair <- !(!is.null(group) && if (is.null(comp.group)) {
    !is.null(rownames(comp.data))
  } else {
    !anyDuplicated(comp.group)
  })
  if (ck_grouppair && !is.logical(sal$mean)) {
    sal$mean <- isTRUE(grepl("T", sal$mean, fixed = TRUE))
  }
  ckf <- is.function(comp)
  apply_comp <- function(m) {
    a <- names(as.list(args(comp)))
    if ("na.rm" %in% a) {
      apply(m, 2, comp, na.rm = TRUE)
    } else if ("na.action" %in% a) {
      apply(m, 2, comp, na.action = na.omit)
    } else {
      apply(m, 2, comp)
    }
  }
  if (is.null(group)) {
    if (!is.null(speaker)) sal$group <- speaker
    if (!is.null(comp.data)) {
      if (ckf) {
        opt$comp <- paste(if (length(opt$comp.data) > 1) deparse(opt$comp.data) else opt$comp.data, opt$comp)
        sal$b <- comp.data <- if (is.null(dim(comp.data))) {
          comp.data
        } else if (compmeanck) colMeans(comp.data, na.rm = TRUE) else apply_comp(comp.data)
      } else {
        sal$b <- comp.data
      }
    } else if (ckf) {
      sal$b <- comp.data <- if (compmeanck) {
        colMeans(input, na.rm = TRUE)
      } else {
        apply_comp(input)
      }
    }
    if (!"b" %in% names(sal) && (is.numeric(comp) || !is.null(dim(comp)))) sal$b <- comp
    sim <- do.call(lma_simets, c(list(input), sal))
  } else {
    gs <- as.character(unique(sim[, 1]))
    cks <- !is.null(speaker)
    ckc <- !is.null(comp.data)
    ckp <- cc == 2 && opt$comp == "pairwise"
    if (gl == 1) {
      if (opt$comp != "pairwise") {
        if (opt$comp == "sequential") {
          group <- sim[, 1]
          sim <- do.call(rbind, lapply(gs, function(g) {
            su <- which(group == g)
            s <- speaker[su]
            r <- if (length(su) < 2 || length(unique(s)) < 2) {
              data.frame(group = g, structure(as.list(numeric(length(mets)) + 1),
                names = inp$metric
              ), row.names = paste(su, collapse = ", "), stringsAsFactors = FALSE)
            } else {
              sal$group <- s
              r <- do.call(lma_simets, c(list(input[su, , drop = FALSE]), sal))
              rs <- as.integer(unlist(strsplit(rownames(r), "[^0-9]+")))
              rownames(r) <- strsplit(do.call(sprintf, c(
                paste(gsub("[0-9]+", "%i", rownames(r)), collapse = "|"), as.list(rs - 1 + su[1])
              )), "|", fixed = TRUE)[[1]]
              data.frame(group = g, r, stringsAsFactors = FALSE)
            }
          }))
        } else {
          if (is.null(sal$pairwise)) sal$pairwise <- ck_grouppair
          flat <- ckf || !isTRUE(sal$pairwise) || isTRUE(sal$mean)
          sal$return.list <- !flat
          if (!flat) fsim <- list()
          ckmc <- FALSE
          if (!ckc && ckf) {
            ckmc <- TRUE
            opt$comp <- paste0(if (length(opt$group) == 1) paste(opt$group, ""), "group ", opt$comp)
            comp.data <- as.data.frame(
              matrix(NA, length(gs), nc, dimnames = list(gs, colnames(input))),
              stringsAsFactors = FALSE
            )
          }
          for (g in gs) {
            su <- sim[, 1] == g
            sal$b <- NULL
            if (ckc) {
              sal$b <- comp.data[if (!is.null(comp.group)) comp.group == g else g, , drop = FALSE]
            } else {
              sal$b <- input[su, ]
            }
            if (ckf && !is.null(dim(sal$b))) {
              sal$b <- if (compmeanck) colMeans(sal$b, na.rm = TRUE) else apply_comp(sal$b)
            }
            if (!is.null(sal$b) && ckmc) comp.data[g, ] <- sal$b
            if (sum(su) == 1 && is.null(sal$b)) {
              sim[su, mets] <- 1
              next
            }
            tm <- do.call(lma_simets, c(list(input[su, , drop = FALSE]), sal))
            if (flat) {
              sim[su, mets] <- tm
            } else {
              fsim[[g]] <- tm
            }
          }
          if (!flat) sim <- fsim
        }
      } else {
        ug <- unique(group[[1]])
        if (isTRUE(sal$mean)) {
          sim <- data.frame(group[[1]], NA, stringsAsFactors = FALSE)
          colnames(sim) <- c(opt$group, sal$metric)
          for (g in ug) {
            su <- group[[1]] == g
            sim[su, -1] <- if (sum(su) == 1) 1 else do.call(lma_simets, c(list(input[su, ]), sal))
          }
        } else {
          sim <- lapply(structure(ug, names = ug), function(g) {
            su <- group[[1]] == g
            if (sum(su) != 1) {
              do.call(lma_simets, c(list(input[su, ]), sal))
            } else {
              rep(NA, length(sal$metric))
            }
          })
        }
      }
    } else if (gl > 1) {
      for (i in seq_len(gl - 1)) sim <- cbind(sim, sim[, mets])
      sug <- seq_len(gl)
      cn <- paste0("g", sug)
      mn <- length(inp$metric)
      mw <- seq_len(mn)
      colnames(sim)[-sug] <- paste0(rep(vapply(seq_along(cn), function(e) {
        paste0(cn[seq_len(e)], collapse = "_")
      }, ""), each = mn), "_", inp$metric)
      group <- vapply(sug, function(g) do.call(paste, group[seq_len(g)]), character(nrow(sim)))
      if (!missing(comp.group)) {
        comp.group <- vapply(sug, function(g) {
          do.call(paste, comp.group[seq_len(g)])
        }, character(length(comp.group[[1]])))
      }
      if (is.null(sal$pairwise)) sal$pairwise <- ck_grouppair
      flat <- ckf || isTRUE(sal$mean)
      if (!flat) fsim <- list()
      ssl <- if (is.null(speaker)) TRUE else !is.na(speaker)
      for (g in unique(sim[, 1])) {
        if (!flat && is.null(fsim[[g]])) fsim[[g]] <- list()
        su <- which(sim[, 1] == g & ssl)
        sg <- group[su, , drop = FALSE]
        sx <- input[su, , drop = FALSE]
        gck <- ckc && !missing(comp.group)
        if (gck) {
          gcsub <- comp.group[, 1] == g
          if (!any(gcsub)) {
            warning("the first comparison group has no levels in common with the first data group",
              call. = FALSE
            )
            gck <- FALSE
          }
        }
        for (s in sug) {
          usg <- unique(sg[, s])
          if (length(usg) == 1) {
            ssg <- list(sx)
            names(ssg) <- usg
          } else {
            ssg <- lapply(usg, function(ss) sx[sg[, s] == ss, , drop = FALSE])
            names(ssg) <- usg
          }
          if (length(ssg) != 0) {
            for (ssn in names(ssg)) {
              ssu <- su[sg[, s] == ssn]
              if (!flat && is.null(fsim[[g]][[ssn]])) fsim[[g]][[ssn]] <- list()
              if (cks) {
                sal$group <- speaker[ssu]
              } else if (ckf && !is.null(dim(ssg[[ssn]]))) {
                sal$b <- if (compmeanck) {
                  colMeans(ssg[[ssn]], na.rm = TRUE)
                } else {
                  apply_comp(ssg[[ssn]])
                }
              }
              csu <- gl + mw + (mn * (s - 1))
              if (gck) {
                gcsu <- comp.group[, s] == ssn & gcsub
                if (!any(gcsu)) {
                  warning(
                    "no ", paste(usg, collapse = ", "), " level found in the comparison group(s)"
                  )
                } else {
                  sal$b <- comp.data[gcsu, , drop = FALSE]
                }
              }
              ssim <- do.call(lma_simets, c(list(ssg[[ssn]]), sal))
              if (flat) {
                sim[ssu, csu] <- ssim
              } else {
                fsim[[g]][[ssn]][[colnames(sim)[csu]]] <- ssim
              }
            }
          }
        }
      }
      if (!flat) sim <- fsim
    }
  }
  list(
    dtm = dtm,
    processed = input,
    comp.type = if (!is.null(opt$comp)) {
      if (is.character(opt$comp)) {
        opt$comp
      } else {
        gsub('"', "'", as.character(deparse(opt$comp)))
      }
    },
    comp = comp.data,
    group = if (!is.null(opt$group)) {
      if (is.character(opt$group)) {
        opt$group
      } else {
        gsub('"', "'", as.character(deparse(opt$group)))
      }
    },
    sim = sim
  )
}
