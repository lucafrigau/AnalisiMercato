# Campionamento sistematico a intervallo frazionario (2.1.0).
#
# k = N/n, partenza r ~ U(0, k] e posizioni ceil(r + (j-1)k). I test
# verificano le proprietà del disegno: n unità sempre, dentro la lista,
# distinte, riproducibili dal seed e con probabilità di inclusione n/N per
# ogni unità anche quando N non è multiplo di n.

posizioni_teoriche <- function(r, N, n) ceiling(r + (N / n) * (seq_len(n) - 1))

estrai <- function(N, n, seed) {
  d <- data.frame(x = seq_len(N), id = seq_len(N))
  r <- samplesyst(data = d, sort_var = NULL, id_var = "id",
                  size_mode = "n", n = n, seed = seed)
  list(summary = as.data.frame(r$summary),
       pos     = as.data.frame(r$extracted)$pos)
}

test_that("il campione ha sempre n unità distinte dentro la lista", {
  casi <- list(c(12, 4),    # N multiplo di n
               c(22, 6),    # N non multiplo di n
               c(37, 5),
               c(100, 7),
               c(10, 1),    # n = 1
               c(10, 10))   # n = N
  for (caso in casi) {
    N <- caso[1]; n <- caso[2]
    for (s in c(1, 2, 17, 99)) {
      e <- estrai(N, n, s)
      info <- sprintf("N=%d n=%d seed=%d", N, n, s)
      expect_equal(e$summary$n_estratto, n, info = info)
      expect_equal(length(e$pos), n, info = info)
      expect_equal(anyDuplicated(e$pos), 0, info = info)
      expect_true(all(e$pos >= 1 & e$pos <= N), info = info)
      expect_equal(e$summary$intervallo, N / n, info = info)
      expect_true(e$summary$partenza > 0 &&
                    e$summary$partenza <= N / n, info = info)
    }
  }
})

test_that("n = N restituisce l'intera popolazione", {
  e <- estrai(10, 10, 3)
  expect_equal(sort(e$pos), 1:10)
})

test_that("le posizioni seguono ceil(r + (j-1)k)", {
  for (caso in list(c(22, 6), c(37, 5), c(100, 7))) {
    e <- estrai(caso[1], caso[2], 5)
    expect_equal(e$pos, posizioni_teoriche(e$summary$partenza, caso[1], caso[2]))
  }
})

test_that("nessuna unità è esclusa a priori e pi_i = n/N", {
  # Verifica esatta: si integra sulla partenza r invece di simularla.
  # L'unità i è estratta quando r cade in uno degli intervalli
  # (i-1-(j-1)k, i-(j-1)k], di lunghezza complessiva 1 dentro (0, k]:
  # la quota di r che la seleziona deve valere 1/k = n/N per ogni i.
  pi_su_griglia <- function(N, n, griglia = 20000) {
    k <- N / n
    conteggi <- integer(N)
    for (r in (seq_len(griglia) - 0.5) * k / griglia) {
      p <- posizioni_teoriche(r, N, n)
      conteggi[p] <- conteggi[p] + 1L
    }
    conteggi / griglia
  }
  for (caso in list(c(10, 3), c(22, 6), c(37, 5), c(12, 4), c(101, 13))) {
    N <- caso[1]; n <- caso[2]
    p <- pi_su_griglia(N, n)
    expect_true(max(abs(p - n / N)) < 0.005,
                info = sprintf("N=%d n=%d max|pi - n/N| = %.4f",
                               N, n, max(abs(p - n / N))))
  }

  # Controllo empirico attraverso il modulo: su molti seed ogni unità
  # della lista viene estratta, e con frequenza vicina a n/N.
  N <- 22; n <- 6; seeds <- 600
  conteggi <- integer(N)
  for (s in seq_len(seeds)) {
    p <- estrai(N, n, s)$pos
    conteggi[p] <- conteggi[p] + 1L
  }
  expect_true(all(conteggi > 0))
  expect_true(max(abs(conteggi / seeds - n / N)) < 0.09)
})

test_that("lo stesso seed dà lo stesso campione, seed diversi no", {
  a <- estrai(53, 9, 20260921)
  b <- estrai(53, 9, 20260921)
  expect_identical(a$pos, b$pos)
  expect_identical(a$summary$partenza, b$summary$partenza)

  diversi <- vapply(1:40, function(s) estrai(53, 9, s)$summary$partenza, numeric(1))
  expect_gt(length(unique(diversi)), 1)
})

test_that("l'estrazione non lascia tracce nel RNG globale", {
  set.seed(4242)
  stato <- .Random.seed
  invisible(estrai(50, 7, 11))
  expect_identical(stato, .Random.seed)
})
