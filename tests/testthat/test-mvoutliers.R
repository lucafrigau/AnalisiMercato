# Outlier multivariati: distanza di Mahalanobis, soglia del chi-quadrato,
# righe con mancanti e covarianza singolare.

test_that("la distanza coincide con stats::mahalanobis e trova l'outlier", {
  set.seed(11)
  x <- rnorm(60)
  d <- data.frame(reddito = x, spesa = x + rnorm(60, sd = 0.3))
  # nessuno dei due valori e' estremo da solo, la combinazione si'
  d[61, ] <- c(2, -2)
  d$reddito[5] <- NA
  r <- mvoutliers(data = d, vars = c("reddito", "spesa"), alpha = 0.001)
  riep <- as.data.frame(r$riepilogo)
  expect_equal(riep$n, 60)
  expect_equal(riep$escluse, 1)
  expect_equal(riep$soglia, qchisq(0.999, 2))

  completi <- complete.cases(d)
  atteso <- mahalanobis(d[completi, ], colMeans(d[completi, ]), cov(d[completi, ]))
  expect_equal(.distanze_mahalanobis(d[completi, ]), atteso)

  out <- as.data.frame(r$outlier)
  expect_true(r$outlier$visible)
  expect_false(is.null(r$riepilogo$notes[["mascheramento"]]))
  expect_equal(out$riga[1], 61)
  expect_equal(out$v_reddito[1], 2)
})

test_that("con tutte le dummy di una variabile la covarianza e' singolare", {
  d <- data.frame(a = c(1, 0, 0, 1, 0, 1), b = c(0, 1, 1, 0, 1, 0),
                  z = c(3, 5, 4, 6, 2, 4))
  expect_error(mvoutliers(data = d, vars = c("a", "b", "z")),
               "non è invertibile|not invertible")
})

test_that("con meno di due variabili l'analisi non parte", {
  r <- mvoutliers(data = data.frame(a = 1:5), vars = "a")
  expect_equal(nrow(as.data.frame(r$outlier)), 0)
})
