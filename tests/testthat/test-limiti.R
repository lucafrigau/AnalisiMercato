# Opzioni numeriche fuori dai limiti: messaggio del modulo in italiano, con
# il nome che si vede nel pannello, invece di quello inglese di jmvcore
# («distMin must be between 1 and Inf (is 0)»).

test_that("un valore fuori dai limiti ferma l'analisi con un messaggio chiaro", {
  d <- data.frame(a = c(1, 2, 3, 2), b = c(3, 2, 1, 1))
  expect_error(respquality(data = d, pairs = list(list(i1 = "a", i2 = "b")), distMin = 0),
               "La distanza dalla diagonale che conta come segnale deve essere almeno 1: 0|must be at least 1")
  expect_error(respquality(data = d, items = c("a", "b"), pairs = NULL, seqPerc = 120),
               "compreso fra 1 e 100: 120|between 1 and 100")
  expect_error(samplesize(param = "proportion", prop_P = 0.5, delta = 0, N = 500),
               "Il margine di errore Δ deve essere maggiore di 0|greater than 0")
  expect_error(samplesize(param = "proportion", prop_P = 0.5, delta = 0.05, N = 500, confidence = 100),
               "compreso fra 50 e 99,99|between 50 and 99.99")
  expect_error(hc(data = iris[, 1:4], vars = names(iris)[1:4], n_clusters = 1),
               "Il numero di gruppi deve essere almeno 2|at least 2")
  expect_error(mvoutliers(data = d, vars = c("a", "b"), alpha = 0.8),
               "maggiore di 0 e al massimo 0,5|greater than 0 and at most 0.5")
})

test_that("i limiti valgono solo per le opzioni che esistono nelle analisi", {
  # ogni opzione della tabella esiste davvero nell'analisi a cui e' associata
  for (a in names(.limiti_opzioni)) {
    opzioni <- names(formals(get(a)))
    expect_true(all(names(.limiti_opzioni[[a]]) %in% opzioni),
                info = paste(a, paste(setdiff(names(.limiti_opzioni[[a]]), opzioni), collapse = ", ")))
  }
  # i valori predefiniti stanno nei limiti
  expect_silent(.controlla_limiti("respquality", list(seqPerc = 100, missPerc = 50,
                                                       distMin = 3, minSegnali = 2)))
})
