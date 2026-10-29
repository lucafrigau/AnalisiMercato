# Rappresentanza minima degli strati nel campionamento stratificato (2.1.0).
#
# Ogni strato non vuoto riceve almeno min(2, N_j) unità: il vincolo
# interviene solo quando l'allocazione teorica lascerebbe uno strato sotto
# quella soglia, e in quel caso il metodo viene dichiarato "vincolata".

popolazione <- function(Nj, sigma_j = NULL) {
  n_tot <- sum(Nj)
  aux <- if (is.null(sigma_j)) {
    stats::rnorm(n_tot)
  } else {
    unlist(lapply(seq_along(Nj), function(j) {
      v <- stats::rnorm(Nj[j])
      if (Nj[j] < 2 || stats::sd(v) == 0) rep(0, Nj[j])
      else (v - mean(v)) / stats::sd(v) * sigma_j[j]
    }))
  }
  data.frame(g   = factor(rep(seq_along(Nj), times = Nj)),
             id  = seq_len(n_tot),
             aux = aux)
}

alloca <- function(Nj, n, method = "proportional", sigma_j = NULL, seed = 1) {
  set.seed(20260921)
  d <- popolazione(Nj, sigma_j)
  r <- samplestrat(data = d, strat_var = "g", aux_var = "aux", id_var = "id",
                   method = method, size_mode = "n", n = n, seed = seed)
  list(nj     = as.integer(as.data.frame(r$strata)$nj),
       Nj     = as.integer(as.data.frame(r$strata)$Nj),
       metodo = as.data.frame(r$summary)$metodo,
       estratti = as.data.frame(r$summary)$n_estratto)
}

test_that("nessuno strato non vuoto resta a zero unità", {
  # Strato C minuscolo: la proporzionale gli darebbe 0,2 unità
  for (met in c("proportional", "optimal")) {
    a <- alloca(c(60, 35, 5), 20, method = met)
    expect_true(all(a$nj >= pmin(2L, a$Nj)), info = met)
    expect_equal(sum(a$nj), 20, info = met)
    expect_equal(a$estratti, 20, info = met)
    expect_true(all(a$nj <= a$Nj), info = met)
  }
})

test_that("uno strato con una sola unità riceve esattamente quella unità", {
  a <- alloca(c(80, 40, 1), 20)
  expect_equal(a$nj[3], 1L)
  expect_equal(sum(a$nj), 20)
})

test_that("con Neyman uno strato a variabilità nulla riceve comunque il minimo", {
  # sigma_j = 0 azzera il peso N_j * sigma_j: senza vincolo lo strato
  # resterebbe fuori dal campione.
  a <- alloca(c(30, 30), 12, method = "optimal", sigma_j = c(0, 4))
  expect_equal(a$nj[1], 2L)
  expect_equal(sum(a$nj), 12)
  expect_match(a$metodo, "vincolata|constrained")
})

test_that("il vincolo non tocca le allocazioni che lo rispettano già", {
  # (23, 34, 43) con n = 10 dà (2, 4, 4): tutti gli strati sono sopra il
  # minimo, quindi l'allocazione resta quella teorica e non è "vincolata".
  a <- alloca(c(23, 34, 43), 10)
  expect_identical(a$nj, c(2L, 4L, 4L))
  expect_false(grepl("vincolata|constrained", a$metodo))

  # la proporzionale resta autoponderata quando il vincolo non morde:
  # f_j uguale in tutti gli strati
  b <- alloca(c(100, 200, 300), 60)
  expect_identical(b$nj, c(10L, 20L, 30L))
  expect_false(grepl("vincolata|constrained", b$metodo))
})

test_that("n insufficiente per i minimi si ferma con un messaggio chiaro", {
  set.seed(1)
  d <- popolazione(c(20, 20, 20, 20))
  expect_error(
    samplestrat(data = d, strat_var = "g", aux_var = "aux", id_var = "id",
                method = "proportional", size_mode = "n", n = 7, seed = 1),
    "non basta a rappresentare|cannot represent"
  )
  # esattamente al limite (2 per strato) l'analisi passa e ogni strato
  # riceve il proprio minimo
  a <- alloca(c(20, 20, 20, 20), 8)
  expect_identical(a$nj, rep(2L, 4))
})

test_that("gli strati saturati restano entro la propria ampiezza", {
  # lo strato da 2 unità viene censito: il minimo coincide con l'ampiezza
  a <- alloca(c(2, 50, 50), 40, method = "proportional")
  expect_equal(a$nj[1], 2L)          # strato saturato: n_j = N_j
  expect_equal(sum(a$nj), 40)
  expect_true(all(a$nj <= a$Nj))
})

test_that("invarianti su configurazioni casuali", {
  set.seed(19)
  for (i in 1:30) {
    M  <- sample(2:5, 1)
    Nj <- sample(1:60, M, replace = TRUE)
    minimi <- pmin(2L, Nj)
    if (sum(Nj) < sum(minimi) + 1) next
    n <- sample(seq(sum(minimi), min(sum(Nj), 40)), 1)
    for (met in c("proportional", "optimal")) {
      a <- alloca(Nj, n, method = met)
      info <- sprintf("Nj=(%s) n=%d %s", paste(Nj, collapse = ","), n, met)
      expect_equal(sum(a$nj), n, info = info)
      expect_true(all(a$nj >= pmin(2L, a$Nj)), info = info)
      expect_true(all(a$nj <= a$Nj), info = info)
    }
  }
})
