#' Unpacking operator
#'
#' Assign values to name(s).
#'
#' @param x A name structure, see details.
#'
#' @param value A list of values, vector of values, or \R object to assign.
#'
#' @section Left-hand side syntax:
#'
#' **the basics**
#'
#' At its simplest the left-hand side may be a single variable name, in which
#' case \code{\%<-\%} performs regular assignment,
#' \code{x \%<-\% list(1, 2, 3)}.
#'
#' To specify multiple variable names use a call to `c()`, for example
#' \code{c(x, y, z) \%<-\% c(1, 2, 3)}.
#'
#' When `value` is neither an atomic vector nor a list, \code{\%<-\%} will try
#' to destructure `value` into a list before assigning variables, see
#' [destructure()].
#'
#' **nested names**
#'
#' One can also nest calls to `c()` when needed, `c(x, c(y, z))`. This nested
#' structure is used to unpack nested right-hand side values,
#' \code{c(x, c(y, z)) \%<-\% list(1, list(2, 3))}.
#'
#' **collector variables**
#'
#' To gather extra values from the beginning, middle, or end of `value` use a
#' collector variable. Collector variables are indicated with a `...`
#' prefix, \code{c(...start, z) \%<-\% list(1, 2, 3, 4)}.
#'
#' **skipping values**
#'
#' Use `.` in place of a variable name to skip a value without raising an error
#' or assigning the value, \code{c(x, ., z) \%<-\% list(1, 2, 3)}.
#'
#' Use `...` to skip multiple values without raising an error or assigning the
#' values, \code{c(w, ..., z) \%<-\% list(1, NA, NA, 4)}.
#'
#' @return
#'
#' \code{\%<-\%} invisibly returns `value`.
#'
#' \code{\%<-\%} is used primarily for its assignment side-effect. \code{\%<-\%}
#' assigns into the environment in which it is evaluated.
#'
#' @seealso
#'
#' For more on unpacking custom objects please refer to
#' [destructure()].
#'
#' @name operator
#' @md
#' @export
#' @examples
#' # basic usage
#' c(a, b) %<-% list(0, 1)
#'
#' a  # 0
#' b  # 1
#'
#' # unpack and assign nested values
#' c(c(e, f), c(g, h)) %<-% list(list(2, 3), list(3, 4))
#'
#' e  # 2
#' f  # 3
#' g  # 4
#' h  # 5
#'
#' # can assign more than 2 values at once
#' c(j, k, l) %<-% list(6, 7, 8)
#'
#' # assign columns of data frame
#' c(erupts, wait) %<-% faithful
#'
#' erupts  # 3.600 1.800 3.333 ..
#' wait    # 79 54 74 ..
#'
#' # assign only specific columns, skip
#' # other columns
#' c(mpg, cyl, disp, ...) %<-% mtcars
#'
#' mpg   # 21.0 21.0 22.8 ..
#' cyl   # 6 6 4 ..
#' disp  # 160.0 160.0 108.0 ..
#'
#' # skip initial values, assign final value
#' TODOs <- list("make food", "pack lunch", "save world")
#'
#' c(..., task) %<-% TODOs
#'
#' task  # "save world"
#'
#' # assign first name, skip middle initial,
#' # assign last name
#' c(first, ., last) %<-% c("Ursula", "K", "Le Guin")
#'
#' first  # "Ursula"
#' last   # "Le Guin"
#'
#' # simple model and summary
#' mod <- lm(hp ~ gear, data = mtcars)
#'
#' # extract call and fstatistic from
#' # the summary
#' c(modcall, ..., modstat, .) %<-% summary(mod)
#'
#' modcall
#' modstat
#'
#' # unpack nested values w/ nested names
#' fibs <- list(1, list(2, list(3, list(5))))
#'
#' c(f2, c(f3, c(f4, c(f5)))) %<-% fibs
#'
#' f2  # 1
#' f3  # 2
#' f4  # 3
#' f5  # 5
#'
#' # unpack first numeric, leave rest
#' c(f2, fibcdr) %<-% fibs
#'
#' f2      # 1
#' fibcdr  # list(2, list(3, list(5)))
#'
#' # swap values without using temporary variables
#' c(a, b) %<-% c("eh", "bee")
#'
#' a  # "eh"
#' b  # "bee"
#'
#' c(a, b) %<-% c(b, a)
#'
#' a  # "bee"
#' b  # "eh"
#'
#' # unpack `strsplit` return value
#' names <- c("Nathan,Maria,Matt,Polly", "Smith,Peterson,Williams,Jones")
#'
#' c(firsts, lasts) %<-% strsplit(names, ",")
#'
#' firsts  # c("Nathan", "Maria", ..
#' lasts   # c("Smith", "Peterson", ..
#'
`%<-%` <- function(x, value) {
  ast <- tree(substitute(x))
  cenv <- parent.frame()

  if (length(ast) != 1 && ast[[1]] != "c") {
    return(old_operator(ast, value, cenv))
  }

  internals <- calls(ast)
  lhs <- tryCatch(
    variables(ast),
    error = function(e) {
      stop(
        "invalid `%<-%` left-hand side, expecting symbol, but ", e$message,
        call. = FALSE
      )
    }
  )

  #
  # standard assignment
  #
  if (is.null(internals)) {
    assign(as.character(ast), value, envir = cenv)
    return(invisible(value))
  }

  if (any(internals != "c")) {
    name <- internals[which(internals != "c")][1]
    stop(
      "invalid `%<-%` left-hand side, unexpected call `", name, "`",
      call. = FALSE
    )
  }

  # if (is_list(lhs) && is_list(car(lhs))) {
  #   lhs <- car(lhs)
  # }

  massign(lhs, value, envir = cenv)

  invisible(value)
}
