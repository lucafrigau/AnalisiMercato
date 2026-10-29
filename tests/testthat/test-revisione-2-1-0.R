# Comportamenti introdotti con la revisione metodologica della 2.1.0:
#  - Mahalanobis si ferma quando la covarianza è singolare, invece di
#    regolarizzare in silenzio;
#  - la PCA con Promax riporta la matrice Φ delle correlazioni fra
#    componenti ruotate;
#  - il Design Effect distingue la numerosità richiesta dal piano dalla
#    numerosità efficace di un campione già raccolto.

# ---------------------------------------------------------------- Mahalanobis

hc_maha <- function(d, ...) {
  hc(data = d, vars = names(d), dis = "mahalanobis", method = "ward.D2",
     n_clusters = 2, ...)
}

test_that("Mahalanobis funziona con covarianza ben condizionata", {
  set.seed(1)
  d <- data.frame(a = rnorm(60), b = rnorm(60), c = rnorm(60))
  expect_error(hc_maha(d), NA)
})

test_that("Mahalanobis si ferma con variabili perfettamente collineari", {
  set.seed(2)
  a <- rnorm(60); b <- rnorm(60)
  d <- data.frame(a = a, b = b, c = 2 * a - 3 * b)   # c dipende da a e b
  expect_error(hc_maha(d), "invertibile|instabile|invertible|unstable")
})

test_that("Mahalanobis si ferma quando le variabili sono quasi collineari", {
  set.seed(3)
  a <- rnorm(60); b <- rnorm(60)
  d <- data.frame(a = a, b = b, c = a + b + rnorm(60, sd = 1e-7))
  expect_error(hc_maha(d), "invertibile|instabile|invertible|unstable")
})

test_that("Mahalanobis si ferma con p >= n", {
  set.seed(4)
  d <- as.data.frame(matrix(rnorm(5 * 6), nrow = 5))   # 5 osservazioni, 6 variabili
  names(d) <- paste0("v", 1:6)
  expect_error(hc_maha(d), "invertibile|instabile|invertible|unstable|osservazioni|observations")
})

# ------------------------------------------------------------------- Matrice Φ

pca_rot <- function(d, rotazione) {
  pca(data = d, vars = names(d), supp_quant = NULL, supp_qual = NULL,
      supp_qual_map = NULL, id_var = NULL, ncp = 2, rotation = rotazione)
}

dati_due_fattori <- function(n = 150, rho = 0.5, seme = 11) {
  set.seed(seme)
  f1 <- rnorm(n); f2 <- rho * f1 + rnorm(n, sd = sqrt(1 - rho^2))
  data.frame(a = f1 + rnorm(n, 0, .4), b = f1 + rnorm(n, 0, .4), c = f1 + rnorm(n, 0, .5),
             x = f2 + rnorm(n, 0, .4), y = f2 + rnorm(n, 0, .4), z = f2 + rnorm(n, 0, .5))
}

test_that("con Promax la matrice Phi è simmetrica, con 1 sulla diagonale", {
  phi <- as.data.frame(pca_rot(dati_due_fattori(), "promax")$phi)
  expect_equal(nrow(phi), 2)
  m <- as.matrix(phi[, c("PC1", "PC2")])
  expect_equal(diag(m), c(1, 1), ignore_attr = TRUE)
  expect_equal(m[1, 2], m[2, 1])
  expect_true(all(abs(m) <= 1 + 1e-9))
})

test_that("Phi coglie la correlazione fra le componenti ruotate", {
  forte <- as.data.frame(pca_rot(dati_due_fattori(rho = 0.7), "promax")$phi)
  debole <- as.data.frame(pca_rot(dati_due_fattori(rho = 0.0), "promax")$phi)
  expect_gt(abs(forte$PC2[1]), abs(debole$PC2[1]))
})

test_that("con Varimax o senza rotazione la tabella Phi resta vuota", {
  expect_equal(nrow(as.data.frame(pca_rot(dati_due_fattori(), "varimax")$phi)), 0)
  expect_equal(nrow(as.data.frame(pca_rot(dati_due_fattori(), "none")$phi)), 0)
})

# --------------------------------------------------------------- Design Effect

test_that("il Deff distingue numerosità richiesta dal piano e numerosità efficace", {
  r <- deff(mode = "formula", plan = "cluster", rho = 0.05, n_within = 10, n_srs = 200)
  out <- as.data.frame(r$result)
  d <- out$deff
  expect_gt(d, 1)
  expect_equal(out$n_complex, 290)                    # progettazione: 1,45 · 200
  expect_equal(out$n_eff, 138)                        # campione già raccolto: 200 / 1,45 = 137,9
  expect_lt(out$n_eff, 200)
})

test_that("con un piano efficiente la numerosità efficace supera quella raccolta", {
  r <- deff(mode = "formula", plan = "stratified", R2 = 0.3, L = 5, n_srs = 200)
  out <- as.data.frame(r$result)
  expect_lt(out$deff, 1)
  expect_lt(out$n_complex, 200)
  expect_gt(out$n_eff, 200)
})

# ------------------------------------- Benchmark del sistematico nel Deff

deff_sys <- function(N, n) as.data.frame(
  deff(mode = "formula", plan = "systematic", N = N, n_total = n, n_srs = 100)$result)

test_that("con N multiplo di n il benchmark del sistematico si calcola", {
  out <- deff_sys(1000, 100)          # k = 10 intero
  expect_equal(out$deff, (10 + 1) / (1000 + 1))
  expect_equal(out$n_complex, 2)                      # 100 · 11/1001 = 1,1
  expect_equal(out$n_eff, 9100)                       # 100 · 1001/11, intero esatto

  out2 <- deff_sys(1200, 40)          # k = 30 intero
  expect_equal(out2$deff, (30 + 1) / (1200 + 1))
})

test_that("con N non multiplo di n il benchmark non viene calcolato", {
  out <- deff_sys(1000, 37)           # k = 27,03 non intero
  expect_true(is.na(out$deff))
  expect_true(is.na(out$n_complex))
  expect_true(is.na(out$n_eff))
  # e la formula dichiarata lo dice
  inp <- as.data.frame(deff(mode = "formula", plan = "systematic",
                            N = 1000, n_total = 37, n_srs = 100)$inputs)
  expect_match(inp$formula, "non calcolabile|not available")
})

test_that("casi limite del benchmark del sistematico", {
  # n = 1: k = N, benchmark definito
  out <- deff_sys(500, 1)
  expect_equal(out$deff, (500 + 1) / (500 + 1))
  # n = N: il disegno è un censimento, l'analisi lo rifiuta
  expect_error(deff_sys(500, 500), "n < N")
  # N/2: k = 2 intero
  expect_equal(deff_sys(500, 250)$deff, (2 + 1) / (500 + 1))
  # N primo con n che non lo divide
  expect_true(is.na(deff_sys(101, 10)$deff))
})

# ------------- Contributi e cos² delle osservazioni dopo rotazione

pca_ind <- function(d, rotazione, ncp = 2) {
  r <- pca(data = d, vars = names(d), supp_quant = NULL, supp_qual = NULL,
           supp_qual_map = NULL, id_var = NULL, ncp = ncp, rotation = rotazione,
           show_ind = TRUE, top_ind = nrow(d))
  comp <- paste0("PC", seq_len(ncp))
  list(coord   = as.matrix(as.data.frame(r$ind_group$ind_coord)[, comp]),
       contrib = as.matrix(as.data.frame(r$ind_group$ind_contrib)[, comp]),
       cos2    = as.matrix(as.data.frame(r$ind_group$ind_cos2)[, comp]),
       id      = as.data.frame(r$ind_group$ind_coord)$id)
}

test_that("con Varimax cos² e contributi seguono le coordinate ruotate", {
  d <- dati_due_fattori(n = 80, rho = 0.3, seme = 21)
  v <- pca_ind(d, "varimax")
  # cos² coerente con le coordinate: il rapporto coord²/cos² è la stessa
  # distanza al quadrato dall'origine su tutte le componenti
  d2 <- v$coord^2 / v$cos2
  expect_equal(d2[, 1], d2[, 2], tolerance = 1e-8, ignore_attr = TRUE)
  # contributi: somma 100 per componente e proporzionali a coord²
  expect_equal(unname(colSums(v$contrib)), c(100, 100), tolerance = 1e-8)
  expect_equal(v$contrib[, 1], 100 * v$coord[, 1]^2 / sum(v$coord[, 1]^2),
               tolerance = 1e-8, ignore_attr = TRUE)
})

test_that("la rotazione ortogonale conserva la distanza dall'origine", {
  d <- dati_due_fattori(n = 80, rho = 0.3, seme = 21)
  gr <- pca_ind(d, "none"); vx <- pca_ind(d, "varimax")
  # le righe delle due tabelle possono essere ordinate diversamente:
  # si riallineano per id prima del confronto
  i <- match(gr$id, vx$id)
  expect_equal(unname(rowSums(gr$coord^2)), unname(rowSums(vx$coord[i, ]^2)),
               tolerance = 1e-8)
  # e con essa la qualità di rappresentazione complessiva sul piano
  expect_equal(unname(rowSums(gr$cos2)), unname(rowSums(vx$cos2[i, ])),
               tolerance = 1e-8)
})

test_that("senza rotazione valgono le stesse formule (rotazione identità)", {
  d <- dati_due_fattori(n = 80, rho = 0.3, seme = 21)
  g <- pca_ind(d, "none")
  d2 <- g$coord^2 / g$cos2
  expect_equal(d2[, 1], d2[, 2], tolerance = 1e-8, ignore_attr = TRUE)
  expect_equal(g$contrib[, 1], 100 * g$coord[, 1]^2 / sum(g$coord[, 1]^2),
               tolerance = 1e-8, ignore_attr = TRUE)
})

test_that("con Promax contributi e cos² restano quelli non ruotati", {
  d <- dati_due_fattori(n = 80, rho = 0.6, seme = 21)
  g <- pca_ind(d, "none"); pm <- pca_ind(d, "promax")
  i <- match(g$id, pm$id)
  expect_equal(g$cos2, pm$cos2[i, ], tolerance = 1e-8, ignore_attr = TRUE)
  expect_equal(g$contrib, pm$contrib[i, ], tolerance = 1e-8, ignore_attr = TRUE)
  # mentre le coordinate sono quelle ruotate, quindi diverse
  expect_false(isTRUE(all.equal(g$coord, pm$coord[i, ], tolerance = 1e-6,
                                check.attributes = FALSE)))
})
