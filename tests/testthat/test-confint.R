# Smoke test degli Intervalli di confidenza.
# Verifica:
#  - modalità "manuale" (nessuna variabile selezionata) per media e proporzione;
#  - modalità "da dataset" per variabili numeriche (media) e categoriali (proporzione);
#  - SE per la media coerente con la formula standard di Cochran s/√n · √(1−f);
#  - applicazione del fattore correttivo per popolazione finita (1−f);
#  - rifiuto di livello di "successo" inesistente.
#
# Nota: in modalità manuale jmvcore richiede comunque un dataset (anche
# minimale) per inizializzare l'analisi; passiamo un data.frame fittizio.

.dummy_data <- function() data.frame()  # 0 colonne: evita un bug noto di
# jmvcore::select su `varsRequired` vuoto quando la modalità manuale
# non seleziona variabili (chiamata programmatica; in jamovi UI non
# si manifesta).

test_that("confint manuale per la proporzione (popolazione infinita)", {
  results <- confint(
    data = .dummy_data(), data_var = NULL,
    param = "proportion",
    n_manual = 100,
    p_manual = 0.4,
    use_fpc = FALSE,
    confidence = 95
  )
  expect_s3_class(results, "Group")

  res <- as.data.frame(results$result)
  # IC simmetrico attorno alla stima
  expect_equal(res$stima, 0.4)
  expect_lt(res$lower, 0.4)
  expect_gt(res$upper, 0.4)
  # SE atteso: v(p̂) = p̂q̂/(n−1) [Cochran 1977, eq. 3.13]. Il
  # denominatore n−1 rende la proporzione il caso particolare della
  # media applicata alla variabile indicatrice 0/1 (vedi test sotto).
  expect_equal(res$se, sqrt(0.4 * 0.6 / 99), tolerance = 1e-8)
})

test_that("la proporzione è il caso 0/1 della media (coerenza interna)", {
  set.seed(4)
  x01 <- rbinom(60, 1, 0.35)
  r_media <- confint(data = data.frame(y = as.numeric(x01)), data_var = "y",
                     N = 500, use_fpc = TRUE, confidence = 95)
  r_prop <- confint(
    data = data.frame(y = factor(x01, levels = c(0, 1), labels = c("no", "si"))),
    data_var = "y", success_level = "si",
    N = 500, use_fpc = TRUE, confidence = 95)
  a <- as.data.frame(r_media$result)
  b <- as.data.frame(r_prop$result)
  expect_equal(a$se, b$se, tolerance = 1e-12)
  expect_equal(a$lower, b$lower, tolerance = 1e-12)
  expect_equal(a$upper, b$upper, tolerance = 1e-12)
})

test_that("il fattore correttivo per popolazioni finite è disattivato di default", {
  # Con use_fpc attivo di default uno studente otterrebbe un IC corretto
  # per una popolazione di 1000 unità senza averlo mai richiesto.
  set.seed(11)
  df <- data.frame(x = rnorm(40))
  r_def <- confint(data = df, data_var = "x", confidence = 95)
  r_bigN <- confint(data = df, data_var = "x", N = 41, confidence = 95)
  expect_equal(as.data.frame(r_def$result)$se,
               as.data.frame(r_bigN$result)$se, tolerance = 1e-12)
  # e coincide con la formula senza correzione
  expect_equal(as.data.frame(r_def$result)$se, sd(df$x) / sqrt(40),
               tolerance = 1e-10)
})

test_that("confint rifiuta n > N quando la correzione è attiva", {
  df <- data.frame(x = rnorm(200))
  expect_error(
    confint(data = df, data_var = "x", N = 100, use_fpc = TRUE),
    "supera la popolazione|exceeds the declared population"
  )
})

test_that("confint manuale per la media usa SE = s/√n · √(1−f) [Cochran]", {
  results <- confint(
    data = .dummy_data(), data_var = NULL,
    param = "mean",
    n_manual = 30,
    mean_manual = 10,
    sd_manual = 2,
    N = 100,
    use_fpc = TRUE,
    confidence = 95
  )
  res <- as.data.frame(results$result)
  se_atteso <- 2 / sqrt(30) * sqrt(1 - 30/100)
  expect_equal(res$se, se_atteso, tolerance = 1e-8)
})

test_that("confint da dataset (variabile numerica → media)", {
  set.seed(42)
  df <- data.frame(x = rnorm(50, mean = 5, sd = 1))
  results <- confint(
    data = df, data_var = "x",
    N = 100, use_fpc = TRUE, confidence = 95
  )
  res <- as.data.frame(results$result)
  expect_equal(res$stima, mean(df$x), tolerance = 1e-10)
  expect_equal(res$se, sd(df$x) / sqrt(50) * sqrt(1 - 50/100), tolerance = 1e-10)
})

test_that("confint da dataset (variabile categoriale → proporzione)", {
  set.seed(7)
  df <- data.frame(y = sample(c("Sì", "No"), 200, replace = TRUE, prob = c(0.3, 0.7)))
  results <- confint(
    data = df, data_var = "y",
    success_level = "Sì",
    N = 1000, use_fpc = TRUE, confidence = 95
  )
  res <- as.data.frame(results$result)
  p_hat <- mean(df$y == "Sì")
  expect_equal(res$stima, p_hat, tolerance = 1e-10)
})

test_that("confint rifiuta un success_level non presente fra i livelli", {
  df <- data.frame(y = sample(c("A", "B"), 50, replace = TRUE))
  expect_error(
    confint(data = df, data_var = "y", success_level = "ZZZ", confidence = 95),
    "ZZZ"
  )
})

test_that("confint: senza FPC (use_fpc=FALSE) la formula si riduce a SCR", {
  r1 <- confint(data = .dummy_data(), data_var = NULL,
                param = "mean", n_manual = 30, mean_manual = 0,
                sd_manual = 1, N = 100, use_fpc = FALSE, confidence = 95)
  r2 <- confint(data = .dummy_data(), data_var = NULL,
                param = "mean", n_manual = 30, mean_manual = 0,
                sd_manual = 1, N = 100, use_fpc = TRUE, confidence = 95)
  se1 <- as.data.frame(r1$result)$se
  se2 <- as.data.frame(r2$result)$se
  # Con FPC, SE è inferiore
  expect_lt(se2, se1)
  # Senza FPC, SE = s/√n
  expect_equal(se1, 1 / sqrt(30), tolerance = 1e-10)
})

test_that("l'opzione n_manual non ammette n = 1 (rifiutato dal backend)", {
  src <- paste(readLines(testthat::test_path("..", "..", "R", "confint.h.R")),
               collapse = "\n")
  expect_match(src, '"n_manual",\\s*\\n\\s*n_manual,\\s*\\n\\s*min=2')
})
