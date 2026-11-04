# Duplicati: gruppi di righe uguali, ultima riga tenuta, mancanti.

test_that("si tiene l'ultima riga di ogni gruppo", {
  d <- data.frame(email = c("a@x.it", "b@x.it", "A@x.it ", "c@x.it", "b@x.it"),
                  voto = c(7, 5, 8, 6, 5))
  ris <- .trova_duplicati(d["email"])
  expect_equal(ris$gruppi, list(c(1L, 3L), c(2L, 5L)))
  expect_equal(ris$duplicato, c(1L, 1L, 0L, 0L, 0L))

  # senza ignorare maiuscole e spazi la riga 3 e' un'altra email
  expect_equal(.trova_duplicati(d["email"], FALSE)$gruppi, list(c(2L, 5L)))

  # su tutte le variabili le righe 1 e 3 differiscono nel voto
  expect_equal(.trova_duplicati(d)$gruppi, list(c(2L, 5L)))
})

test_that("i mancanti: uguali fra loro, ma le righe vuote non si confrontano", {
  d <- data.frame(email = c(NA, "a@x.it", NA, "a@x.it", ""),
                  eta = c(NA, 20, NA, NA, NA))
  # sull'email le righe senza email (1, 3 e la stringa vuota) restano fuori
  ris <- .trova_duplicati(d["email"])
  expect_equal(ris$gruppi, list(c(2L, 4L)))
  expect_equal(ris$vuota, c(TRUE, FALSE, TRUE, FALSE, TRUE))

  # su entrambe: la riga 4 ha l'eta' mancante e la 2 no, quindi sono
  # diverse; le righe 1, 3 e 5 sono vuote
  ris2 <- .trova_duplicati(d)
  expect_length(ris2$gruppi, 0)
  expect_equal(sum(ris2$vuota), 3)

  # due NA nella stessa colonna contano come uguali
  d3 <- data.frame(email = c("a", "a"), eta = c(NA, NA))
  expect_equal(.trova_duplicati(d3)$gruppi, list(c(1L, 2L)))
})

test_that("l'analisi riassume i gruppi con i numeri di riga", {
  d <- data.frame(email = c("a@x.it", "b@x.it", "a@x.it", "a@x.it"))
  r <- duplicates(data = d, vars = "email")
  riep <- as.data.frame(r$riepilogo)
  expect_equal(c(riep$righe, riep$gruppi, riep$inpiu, riep$vuote), c(4, 1, 2, 0))
  gr <- as.data.frame(r$gruppi)
  expect_equal(gr$righe, "1, 3, 4")
  expect_equal(gr$tenuta, 4)
  expect_equal(gr$valore, "a@x.it")

  r0 <- duplicates(data = data.frame(email = c("a", "b")), vars = "email")
  expect_false(is.null(r0$riepilogo$notes[["nessuno"]]))
  expect_false(r0$gruppi$visible)
})
