# Smoke test del calcolo della Numerosità Campionaria.
# Verifica le formule analitiche per proporzione e media,
# con e senza fattore correttivo per popolazione finita (FPC).
# Riferimento: Cochran (1977) Sampling Techniques.

test_that("samplesize proporzione SCR: n = z²P(1-P)/Δ²", {
  results <- samplesize(
    param = "proportion", replacement = TRUE,
    delta = 0.03, confidence = 95, prop_P = 0.5
  )
  res <- as.data.frame(results$result)
  z <- qnorm(0.975)
  n_atteso <- z^2 * 0.5 * 0.5 / 0.03^2
  expect_equal(res$n_teorico, n_atteso, tolerance = 1e-8)
  expect_equal(res$n_consigliato, ceiling(n_atteso))
})

test_that("samplesize proporzione SSR: include FPC", {
  results <- samplesize(
    param = "proportion", replacement = FALSE,
    N = 1000, delta = 0.03, confidence = 95, prop_P = 0.5
  )
  res <- as.data.frame(results$result)
  z <- qnorm(0.975)
  v <- 0.5 * 0.5
  n_atteso <- (z^2 * v * 1000) / ((1000 - 1) * 0.03^2 + z^2 * v)
  expect_equal(res$n_teorico, n_atteso, tolerance = 1e-8)
  # Frazione f = n_eff/N
  expect_equal(res$frazione, ceiling(n_atteso) / 1000, tolerance = 1e-8)
})

test_that("samplesize media SSR: n = z²σ²N / [(N-1)Δ² + z²σ²]", {
  results <- samplesize(
    param = "mean", replacement = FALSE,
    N = 10000, delta = 2, confidence = 95, mean_sigma = 10
  )
  res <- as.data.frame(results$result)
  z <- qnorm(0.975)
  n_atteso <- (z^2 * 100 * 10000) / ((10000 - 1) * 4 + z^2 * 100)
  expect_equal(res$n_teorico, n_atteso, tolerance = 1e-8)
})

test_that("samplesize media SCR: n = z²σ²/Δ², variance attesa = σ²/n", {
  results <- samplesize(
    param = "mean", replacement = TRUE,
    delta = 0.5, confidence = 95, mean_sigma = 2
  )
  res <- as.data.frame(results$result)
  z <- qnorm(0.975)
  n_atteso <- z^2 * 4 / 0.25
  expect_equal(res$n_teorico, n_atteso, tolerance = 1e-8)
  # var_attesa = σ²/n_eff per SCR
  expect_equal(res$var_attesa, 4 / ceiling(n_atteso), tolerance = 1e-8)
})

test_that("samplesize: Δ deve essere strettamente positivo", {
  # jmvcore intercetta i valori fuori range (min=1e-06) prima del modulo
  expect_error(
    samplesize(param = "proportion", delta = 0, prop_P = 0.5),
    "delta"
  )
  expect_error(
    samplesize(param = "mean", delta = -1, mean_sigma = 1),
    "delta"
  )
})

test_that("samplesize proporzione: Δ < 1 (vincolo applicato dal modulo)", {
  expect_error(
    samplesize(param = "proportion", delta = 1.2, prop_P = 0.5),
    "minore di 1|smaller than 1"
  )
})

test_that("samplesize media accetta Δ > 1 (es. ±2 punti)", {
  results <- samplesize(
    param = "mean", replacement = FALSE,
    N = 10000, delta = 2, confidence = 95, mean_sigma = 10
  )
  expect_s3_class(results, "Group")
})

test_that("samplesize media: σ deve essere strettamente positivo", {
  # jmvcore intercetta mean_sigma=0 (min=1e-06)
  expect_error(
    samplesize(param = "mean", delta = 0.5, mean_sigma = 0),
    "mean_sigma"
  )
})

test_that("samplesize: per Δ piccolissimo con SSR, n_eff è limitato a N", {
  # Per popolazione finita, n_teorico ≤ N matematicamente (asintoto).
  # Verifica che n_consigliato sia comunque cappato a N.
  results <- samplesize(param = "proportion", replacement = FALSE,
                         N = 50, delta = 0.001, confidence = 99, prop_P = 0.5)
  res <- as.data.frame(results$result)
  expect_lte(res$n_consigliato, 50)
})

test_that("la varianza attesa usa la stessa FPC della formula di n", {
  # n deriva da Var = (V/n)·(N−n)/(N−1): la varianza riportata deve
  # usare la stessa espressione, non (1−f) = (N−n)/N.
  N <- 2000
  res <- as.data.frame(samplesize(
    param = "proportion", prop_P = 0.5, delta = 0.04,
    confidence = 95, replacement = FALSE, N = N)$result)
  n_eff <- res$n_consigliato
  atteso <- ((N - n_eff) / (N - 1)) * 0.25 / n_eff
  expect_equal(res$var_attesa, atteso, tolerance = 1e-12)
  # invertendo il SE si ritrova il margine richiesto (n arrotondato per
  # eccesso rende il margine effettivo appena minore di quello chiesto)
  delta_ric <- stats::qnorm(0.975) * res$se_attesa
  expect_lte(delta_ric, 0.04 + 1e-12)
  expect_gt(delta_ric, 0.04 * 0.97)
})

test_that("samplesize rifiuta P = 0 e P = 1", {
  expect_error(
    samplesize(param = "proportion", prop_P = 0, delta = 0.05, N = 500),
    "strettamente compreso|strictly between"
  )
  expect_error(
    samplesize(param = "proportion", prop_P = 1, delta = 0.05, N = 500),
    "strettamente compreso|strictly between"
  )
})
