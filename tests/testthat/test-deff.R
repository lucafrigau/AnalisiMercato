# Smoke test del Design Effect.
# Verifica le quattro modalità di calcolo:
#  - da rapporto di varianze;
#  - formule analitiche per sistematico, multistadio/grappoli, stratificato.
# Confronto con valori attesi calcolati a mano.

test_that("deff da rapporto di varianze: Deff = V_complex / V_SRS", {
  results <- deff(mode = "variances", var_complex = 2.0, var_srs = 1.0, n_srs = 100)
  res <- as.data.frame(results$result)
  expect_equal(res$deff, 2.0, tolerance = 1e-10)
  expect_equal(res$n_complex, 200)
  expect_match(res$efficienza, "Deff > 1")
})

test_that("deff sistematico: (k+1)/(N+1) con k = N/n", {
  results <- deff(mode = "formula", plan = "systematic",
                   N = 1000, n_total = 100, n_srs = 100)
  res <- as.data.frame(results$result)
  expect_equal(res$deff, 11 / 1001, tolerance = 1e-10)
  expect_match(res$efficienza, "Deff < 1")
})

test_that("deff multistadio/grappoli: 1 + (n-1)·ρ (Kish)", {
  # ρ = 0.1, n_within = 30 → Deff = 1 + 29*0.1 = 3.9
  r_ms <- deff(mode = "formula", plan = "multistage", rho = 0.1,
                n_within = 30, n_srs = 100)
  expect_equal(as.data.frame(r_ms$result)$deff, 3.9, tolerance = 1e-10)

  # Stessa formula per "cluster"
  r_cl <- deff(mode = "formula", plan = "cluster", rho = 0.1,
                n_within = 30, n_srs = 100)
  expect_equal(as.data.frame(r_cl$result)$deff, 3.9, tolerance = 1e-10)
})

test_that("deff stratificato: 1 - R²·(L²-1)/L² (Cochran Eq. 5.51)", {
  # L=4, R²=0.5 → Deff = 1 - 0.5·15/16 = 1 - 0.46875 = 0.53125
  results <- deff(mode = "formula", plan = "stratified",
                   L = 4, R2 = 0.5, n_srs = 100)
  res <- as.data.frame(results$result)
  expect_equal(res$deff, 1 - 0.5 * 15 / 16, tolerance = 1e-10)
})

test_that("deff rifiuta varianze nulle (denominatore)", {
  # var_srs = 0 viene intercettato dal check di jmvcore (min=1e-06)
  expect_error(
    deff(mode = "variances", var_complex = 1, var_srs = 0, n_srs = 100),
    "var_srs"
  )
})

test_that("deff stratificato richiede L >= 2", {
  # L=1 viene intercettato dal check di jmvcore (min=2)
  expect_error(
    deff(mode = "formula", plan = "stratified", L = 1, R2 = 0.3, n_srs = 100),
    "L"
  )
})

test_that("deff sistematico richiede n < N", {
  expect_error(
    deff(mode = "formula", plan = "systematic", N = 100, n_total = 100, n_srs = 100),
    "n < N"
  )
})

test_that("deff: l'arrotondamento per eccesso non aggiunge unità spurie", {
  # 1 + 82 * 0.05 in virgola mobile vale 5.1000000000000005: senza
  # tolleranza ceiling(5.1 * 200) darebbe 1021 invece di 1020.
  r <- as.data.frame(deff(mode = "formula", plan = "cluster", rho = 0.05,
                          n_within = 83, n_srs = 200)$result)
  expect_equal(r$n_complex, 1020)
  expect_equal(r$n_eff, 40)
  r2 <- as.data.frame(deff(mode = "variances", var_complex = 1.1, var_srs = 1,
                           n_srs = 100)$result)
  expect_equal(r2$n_complex, 110)
  expect_equal(r2$n_eff, 91)
})
