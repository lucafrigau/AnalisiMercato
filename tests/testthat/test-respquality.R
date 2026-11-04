# Qualita' delle risposte: sequenze di risposte uguali, mancanti, distanza
# dalla diagonale delle coppie di controllo e conteggio dei segnali.

test_that("la sequenza piu' lunga si interrompe con un mancante", {
  m <- .matrice_risposte(data.frame(
    a = c(5, 1, 3, NA),
    b = c(5, 2, 3, NA),
    c = c(5, 2, NA, 4),
    d = c(5, 2, 3, 4)))
  expect_equal(.sequenza_piu_lunga(m), c(4L, 3L, 2L, 2L))
  expect_equal(as.integer(rowSums(is.na(m))), c(0L, 0L, 1L, 2L))
  # una riga tutta mancante ha sequenza 0
  expect_equal(.sequenza_piu_lunga(.matrice_risposte(data.frame(a = NA, b = NA))), 0L)
})

test_that("distanza dalla diagonale: codici numerici e modalita' testuali", {
  # numeri: la differenza fra i codici
  dc <- .distanza_coppia(c(1, 5, 3, NA), c(1, 1, 5, 2))
  expect_equal(dc$d, c(0, 4, 2, NA))
  expect_equal(dc$massimo, 4)
  expect_equal(sum(dc$tabella$n), 3)

  # modalita' testuali: conta la posizione, nell'ordine dei livelli
  f1 <- factor(c("Mai", "Spesso", "Sempre"), levels = c("Mai", "Spesso", "Sempre"))
  f2 <- factor(c("Mai", "Mai", "Spesso"), levels = c("Mai", "Spesso", "Sempre"))
  expect_equal(.distanza_coppia(f1, f2)$d, c(0, 1, 1))

  # fattori con modalita' numeriche: contano i valori
  g1 <- factor(c("1", "5"))
  g2 <- factor(c("2", "4"))
  expect_equal(.distanza_coppia(g1, g2)$d, c(1, 1))

  expect_error(.distanza_coppia(f1, factor(c("a", "b", "c", "d"))),
               "numero diverso|different number")
  expect_error(.distanza_coppia(f1, c(1, 2, 3)), "stesso tipo|same type")
})

test_that("l'analisi conta i segnali ed elenca i rispondenti", {
  d <- data.frame(
    i1 = c(5, 1, 3, NA, 2),
    i2 = c(5, 2, 3, NA, 4),
    i3 = c(5, 3, 3, NA, 1),
    i4 = c(5, 4, 3, 2, 5),
    d17 = c(1, 1, 5, 2, 3),
    d43 = c(5, 1, 1, 2, 3))
  r <- respquality(data = d, items = c("i1", "i2", "i3", "i4"),
                   pairs = list(list(i1 = "d17", i2 = "d43")),
                   seqPerc = 100, missPerc = 50, distMin = 3, minSegnali = 1)
  riep <- as.data.frame(r$riepilogo)
  # tutte uguali: righe 1 e 3; meta' mancanti: riga 4; distanza >= 3:
  # righe 1 e 3
  expect_equal(riep$n, c(2, 1, 2))
  ris <- as.data.frame(r$rispondenti)
  expect_equal(ris$riga, c(1, 3, 4))
  expect_equal(ris$segnali, c(2, 2, 1))
  expect_equal(ris$d1, c(4, 4, 0))

  # con la soglia 2 la riga 5 resta fuori (distanza 0) e nulla cambia;
  # con minSegnali = 2 restano le righe 1 e 3
  r2 <- respquality(data = d, items = c("i1", "i2", "i3", "i4"),
                    pairs = list(list(i1 = "d17", i2 = "d43")), minSegnali = 2)
  expect_equal(as.data.frame(r2$rispondenti)$riga, c(1, 3))

  # nessuno con tre segnali: la tabella si nasconde e il riepilogo lo dice
  r3 <- respquality(data = d, items = c("i1", "i2", "i3", "i4"),
                    pairs = list(list(i1 = "d17", i2 = "d43")), minSegnali = 3)
  expect_false(r3$rispondenti$visible)
  expect_false(is.null(r3$riepilogo$notes[["nessuno"]]))
})

test_that("una soglia troppo alta per la coppia lo dice in una nota", {
  d <- data.frame(a = c(1, 2, 3, 2), b = c(3, 2, 1, 1))
  r <- respquality(data = d, pairs = list(list(i1 = "a", i2 = "b")), distMin = 3)
  expect_false(is.null(r$riepilogo$notes[["massimo1"]]))
})

test_that("un solo item nella batteria si ferma con un messaggio", {
  expect_error(respquality(data = data.frame(a = 1:3, b = 1:3), items = "a", pairs = NULL),
               "almeno due item|at least two items")
})
