# Variabili dummy: tabella dell'analisi e valori calcolati da .dummy_di(),
# che l'analisi passa all'output dummiesOV.

test_that("una dummy per modalita', con NA dove la variabile manca", {
  area <- factor(c("Nord", "Sud", NA, "Centro", "Nord"),
                 levels = c("Nord", "Centro", "Sud", "Isole"))
  dv <- .dummy_di(area)
  # l'ordine e' quello dei livelli; la modalita' senza osservazioni non
  # da' una dummy fatta di soli zeri
  expect_equal(dv$livelli, c("Nord", "Centro", "Sud"))
  expect_equal(dv$valori[[1]], c(1L, 0L, NA, 0L, 1L))
  expect_equal(dv$valori[[3]], c(0L, 1L, NA, 0L, 0L))

  r <- dummies(data = data.frame(area = area), vars = "area")
  tab <- as.data.frame(r$dummies)
  expect_equal(tab$name, c("area_Nord", "area_Centro", "area_Sud"))
  expect_equal(tab$n1, c(2, 1, 1))
  expect_equal(tab$perc1, c(0.5, 0.25, 0.25))
  expect_equal(tab$nmiss, c(1, 1, 1))
})

test_that("risposta multipla: una dummy per opzione e le rare in «altro»", {
  social <- c("Instagram, TikTok", "TikTok", NA, "Instagram, il mio blog",
              "Facebook", "")
  dv <- .dummy_di(social, multi = TRUE, sep = ",", min_altro = 2)
  expect_equal(dv$livelli, c("Instagram", "TikTok", "altro"))
  expect_setequal(dv$rare, c("Facebook", "il mio blog"))
  expect_equal(dv$valori[[1]], c(1L, 0L, NA, 1L, 0L, NA))
  expect_equal(dv$valori[[2]], c(1L, 1L, NA, 0L, 0L, NA))
  expect_equal(dv$valori[[3]], c(0L, 0L, NA, 1L, 1L, NA))

  # con min_altro = 1 non si riunisce nulla
  expect_equal(.dummy_di(social, multi = TRUE, min_altro = 1)$livelli,
               c("Instagram", "TikTok", "Facebook", "il mio blog"))

  # un'opzione che si chiama gia' «Altro» raccoglie le rare
  dv2 <- .dummy_di(c("Altro, Radio", "Altro", "Tv", "Tv"), multi = TRUE,
                  min_altro = 2)
  expect_equal(dv2$livelli, c("Altro", "Tv"))
  expect_equal(dv2$valori[[1]], c(1L, 1L, 0L, 0L))

  r <- dummies(data = data.frame(social = social), vars = "social",
               multi = TRUE, minAltro = 2)
  tab <- as.data.frame(r$dummies)
  expect_equal(tab$name, c("social_Instagram", "social_TikTok", "social_altro"))
  expect_match(r$dummies$notes[["altro_social"]]$note, "Facebook")
})

test_that("i nomi delle dummy hanno solo lettere, cifre e trattini bassi", {
  expect_equal(.nome_modalita("1–3 volte al mese"), "1_3_volte_al_mese")
  expect_equal(.nome_modalita(" Sì, spesso "), "Sì_spesso")
  expect_equal(.nome_modalita("?"), "modalita")
})

test_that("senza separatore la risposta multipla si ferma con un messaggio", {
  expect_error(dummies(data = data.frame(s = c("a, b", "a")), vars = "s",
                       multi = TRUE, sep = ""),
               "separatore|separator")
})
