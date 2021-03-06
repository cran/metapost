
## Convert R objects to MetaPost path

## R path to MetaPost code
as.character.knot <- function(x, ..., first=FALSE, last=FALSE, digits=2) {
    n <- length(x)
    x <- lapply(x, rep, length=n)
    dir.left <- rep("", n)
    if (!first) {
        ## knot() constructor has enforced that dir and curl not both spec'ed
        isnadir <- is.na(x$dir.left)
        isnacurl <- is.na(x$curl.left)
        if (!all(isnadir)) {
            dir.left[!isnadir] <- paste0("{dir ",
                                         x$dir.left[!isnadir],
                                         "}")
        }
        if (!all(isnacurl)) {
            dir.left[!isnacurl] <- paste0("{curl ",
                                          x$curl.left[!isnacurl],
                                          "}")
        }
    }
    dir.right <- ""
    if (!last) {
        ## knot() constructor has enforced that dir and curl not both spec'ed
        isnadir <- is.na(x$dir.right)
        isnacurl <- is.na(x$curl.right)
        if (!all(isnadir)) {
            dir.right[!isnadir] <- paste0("{dir ",
                                          x$dir.right[!isnadir],
                                          "}")
        }
        if (!all(isnacurl)) {
            dir.right[!isnacurl] <- paste0("{curl ",
                                           x$curl.right[!isnacurl],
                                           "}")
        }
    }
    paste0(dir.left,
           "(", round(convertX(x$x, "in", valueOnly=TRUE), digits), "in,",
           round(convertY(x$y, "in", valueOnly=TRUE), digits), "in)",
           dir.right)
}

as.character.cycle <- function(x, ...) {
    "cycle"
}

## Construct connector string between two knots
connectorString <- function(x, y, digits) {
    ## First knot
    isnatension.right <- is.na(x$tension.right)
    isnacp.right <- is.na(x$cp.right.x) | is.na(x$cp.right.y)
    tension.right <- ""
    if (!all(isnatension.right)) {
        tension <- x$tension.right[!isnatension.right]
        tension.right[!isnatension.right] <-
            paste0("tension ",
                   ifelse(is.finite(tension),
                          paste0(ifelse(tension < 0, "atleast ", ""),
                                 abs(tension)),
                          "infinity"))
    }
    if (!all(isnacp.right)) {
        tension.right[!isnacp.right] <-
            paste0("controls (",
                   round(convertX(x$cp.right.x[!isnacp.right], "in",
                                  valueOnly=TRUE), digits),
                   "in,",
                   round(convertY(x$cp.right.y[!isnacp.right], "in",
                                  valueOnly=TRUE), digits),
                   "in)")
    }
    ## Second knot
    ## knot() constructor has enforced that tension and cp not both spec'ed
    isnatension.left <- is.na(y$tension.left)
    isnacp.left <- is.na(y$cp.left.x) | is.na(y$cp.left.y)
    tension.left <- ifelse(nchar(tension.right) &
                           (!isnatension.left | !isnacp.left),
                           " and ",
                           ifelse(!nchar(tension.right) &
                                  isnatension.left & !isnacp.left,
                                  "controls ",
                                  ifelse(!nchar(tension.right) &
                                         isnacp.left & !isnatension.left,
                                         "tension ",
                                         "")))
    if (!all(isnatension.left)) {
        tension <- y$tension.left[!isnatension.left]
        tension.left[!isnatension.left] <-
            paste0(tension.left[!isnatension.left],
                   ifelse(is.finite(tension),
                          paste0(ifelse(tension < 0, "atleast ", ""),
                                 abs(tension)),
                          "infinity"))
    }
    if (!all(isnacp.left)) {
        tension.left[!isnacp.left] <-
            paste0(tension.left[!isnacp.left],
                   "(",
                   round(convertX(y$cp.left.x[!isnacp.left], "in",
                                  valueOnly=TRUE), digits),
                   "in,",
                   round(convertY(y$cp.left.y[!isnacp.left], "in",
                                  valueOnly=TRUE), digits),
                   "in)")
    }
    ifelse(nchar(tension.right) | nchar(tension.left),
           paste0("..", tension.right, tension.left, ".."),
           "..")
}

connectKnot <- function(x, y, last=FALSE, digits=2) {
    paste0(connectorString(x, y, digits),
           as.character(y, last=last, digits=digits))
}

as.character.mppath <- function(x, ..., digits=2) {
    n <- length(x)
    if (n == 1) {
        as.character(x$knots[[1]], first=TRUE, last=TRUE, digits=digits)
    } else if (n == 2) {
        paste0(as.character(x$knots[[1]], first=TRUE, digits=digits),
               connectKnot(x$knots[[1]], x$knots[[2]],
                           last=TRUE, digits=digits))
    } else {
        paste0(as.character(x$knots[[1]], first=TRUE, digits=digits),
               paste0(mapply(connectKnot,
                             x$knots[-(n - 1:0)], x$knots[-c(1, n)],
                             MoreArgs=list(digits=digits)),
                      collapse=""),
               connectKnot(x$knots[[n - 1]], x$knots[[n]],
                           last=TRUE, digits=digits))
    }
}

## Generate MetaPost code from R objects (within a file)
metapost <- function(x, file="fig.mp", digits=2) {
    if (!inherits(x, "mppath"))
        stop("'x' must be a path object")
    code <- c("beginfig(1);",
              paste0("draw ", as.character(x, digits=digits), ";"),
              "endfig;",
              "end")
    if (!is.null(file)) {
        writeLines(code, file)
    }
    invisible(code)
}
