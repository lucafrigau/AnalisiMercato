# Smoke test dell'Adjusted Rand Index.

test_that("ARI = 1 fra una partizione e se stessa", {
  set.seed(1)
  hc1 <- hclust(dist(iris[, 1:4]), method = "ward.D2")
  cl <- cutree(hc1, k = 3)
  df <- data.frame(p1 = cl, p2 = cl)
  results <- ari(data = df, vars = c("p1", "p2"))
  expect_s3_class(results, "Group")

  mat <- as.data.frame(results$matrix)
  vals <- unlist(mat[vapply(mat, is.numeric, logical(1))])
  vals <- vals[is.finite(vals)]
  expect_true(any(abs(vals - 1) < 1e-9))
})

test_that("ARI ~ 0 fra due partizioni casuali indipendenti", {
  set.seed(123)
  n <- 200
  df <- data.frame(
    p1 = sample(1:4, n, replace = TRUE),
    p2 = sample(1:4, n, replace = TRUE)
  )
  results <- ari(data = df, vars = c("p1", "p2"))
  mat <- as.data.frame(results$matrix)
  vals <- unlist(mat[vapply(mat, is.numeric, logical(1))])
  vals <- vals[is.finite(vals)]
  # con n=200 e 4 livelli random, |ARI| dovrebbe essere piccolo
  expect_true(min(abs(vals[abs(vals - 1) > 1e-9])) < 0.1)
})

test_that("ARI gestisce NA escludendoli pairwise", {
  set.seed(7)
  hc1 <- hclust(dist(iris[, 1:4]), method = "ward.D2")
  cl <- cutree(hc1, k = 3)
  cl2 <- cl
  cl2[1:10] <- NA
  df <- data.frame(p1 = cl, p2 = cl2)
  results <- ari(data = df, vars = c("p1", "p2"))
  mat <- as.data.frame(results$matrix)
  vals <- unlist(mat[vapply(mat, is.numeric, logical(1))])
  vals <- vals[is.finite(vals)]
  expect_true(any(abs(vals - 1) < 1e-9))
})

test_that("partizioni identiche danno ARI = 1 anche nei casi degeneri", {
  # Con tutti singoletti (o tutte le unità in un solo gruppo) la formula
  # di Hubert-Arabie degenera in 0/0: la concordanza è però perfetta.
  val <- function(p1, p2) {
    r <- ari(data = data.frame(A = p1, B = p2), vars = c("A", "B"))
    m <- as.data.frame(r$matrix)
    suppressWarnings(as.numeric(m[2, 2]))
  }
  expect_equal(val(1:4, 1:4), 1)                       # soli singoletti
  expect_equal(val(rep(1, 5), rep(1, 5)), 1)           # gruppo unico
  expect_equal(val(1:4, c(10, 20, 30, 40)), 1)         # etichette diverse
  expect_equal(val(c(1,1,2,2,3), c("b","b","c","c","a")), 1)  # rietichettata
})

test_that("ARI non degenere resta uguale alla formula di Hubert-Arabie", {
  ha <- function(x, y) {
    tab <- table(x, y)
    a <- sum(choose(tab, 2))
    A <- sum(choose(rowSums(tab), 2)); B <- sum(choose(colSums(tab), 2))
    tot <- choose(sum(tab), 2)
    (a - A * B / tot) / ((A + B) / 2 - A * B / tot)
  }
  set.seed(21)
  x <- sample(1:3, 40, TRUE); y <- sample(1:3, 40, TRUE)
  r <- ari(data = data.frame(A = x, B = y), vars = c("A", "B"))
  val <- suppressWarnings(as.numeric(as.data.frame(r$matrix)[2, 2]))
  expect_equal(val, ha(x, y), tolerance = 1e-10)
})

test_that("i livelli dichiarati ma non osservati non producono NaN", {
  # dopo un filtro jamovi un fattore può conservare livelli vuoti: le
  # righe/colonne nulle della tabella di contingenza non devono impedire
  # di riconoscere due partizioni identiche
  f1 <- factor(c("a","b","c"), levels = c("a","b","c","d"))
  f2 <- factor(c("a","b","c"), levels = c("a","b","c","d"))
  r <- ari(data = data.frame(A = f1, B = f2), vars = c("A", "B"))
  val <- suppressWarnings(as.numeric(as.data.frame(r$matrix)[2, 2]))
  expect_equal(val, 1)
})
