# Test per le due analisi a estrazione su più livelli: campionamento a
# grappoli e campionamento a due stadi. Erano le uniche due analisi del
# modulo prive di copertura (samplecluster: nessuna chiamata; multistage:
# una sola), pur essendo quelle con la logica di estrazione più articolata.
#
# I test fissano soprattutto le PROPRIETÀ del disegno, non i numeri:
#  - a grappoli si prendono i grappoli INTERI, e solo quelli estratti;
#  - a due stadi si prendono b unità per PSU (tutte, se la PSU è più piccola);
#  - le etichette dei grappoli non vanno confuse con le loro posizioni
#    (è la stessa classe di errore del sample() scalare corretto in 2.0.3);
#  - un grappolo/PSU con una sola unità non manda in errore l'estrazione.

# ---------------------------------------------------------------- grappoli --

test_that("samplecluster estrae grappoli interi e nient'altro", {
  d <- data.frame(
    g  = rep(c("A", "B", "C", "D"), times = c(5, 3, 7, 4)),
    id = sprintf("u%02d", 1:19)
  )
  for (s in 1:20) {
    r <- samplecluster(data = d, cluster_var = "g", id_var = "id",
                       size_mode = "ng", ng = 2, seed = s)
    smry <- as.data.frame(r$summary)
    est  <- as.data.frame(r$clusters)
    ext  <- as.data.frame(r$extracted)

    expect_equal(smry$M, 4)
    expect_equal(smry$ng_estratto, 2)
    expect_equal(nrow(est), 2)

    # tutte e sole le unità dei grappoli estratti
    attesi <- d$id[d$g %in% est$grappolo]
    expect_setequal(ext$id_value, attesi)
    expect_equal(smry$n_unita, length(attesi))
    expect_equal(sum(est$dim), length(attesi))
    expect_equal(smry$frazione_unita, length(attesi) / nrow(d))
  }
})

test_that("samplecluster non confonde l'etichetta del grappolo con la sua posizione", {
  # etichette numeriche: se il codice campionasse gli indici invece dei
  # livelli, qui uscirebbero grappoli inesistenti (1, 2, 3) al posto di
  # quelli veri (10, 20, 30).
  d <- data.frame(
    g  = rep(c(10, 20, 30), each = 4),
    id = sprintf("u%02d", 1:12)
  )
  for (s in 1:15) {
    r <- samplecluster(data = d, cluster_var = "g", id_var = "id",
                       size_mode = "ng", ng = 1, seed = s)
    est <- as.data.frame(r$clusters)
    ext <- as.data.frame(r$extracted)
    expect_true(est$grappolo %in% c("10", "20", "30"))
    expect_equal(est$dim, 4)
    expect_setequal(ext$id_value, d$id[as.character(d$g) == est$grappolo])
  }
})

test_that("samplecluster: grappolo di una sola unità e grappoli mancanti", {
  d <- data.frame(
    g  = c(rep("A", 6), "B", rep("C", 5), NA, NA),
    id = sprintf("u%02d", 1:14)
  )
  visti <- character(0)
  for (s in 1:30) {
    r <- samplecluster(data = d, cluster_var = "g", id_var = "id",
                       size_mode = "ng", ng = 2, seed = s)
    smry <- as.data.frame(r$summary)
    ext  <- as.data.frame(r$extracted)
    # le righe con grappolo mancante non contano nella popolazione...
    expect_equal(smry$N, 12)
    expect_equal(smry$M, 3)
    # ...e non entrano mai nel campione
    expect_false(any(ext$id_value %in% c("u13", "u14")))
    visti <- union(visti, as.data.frame(r$clusters)$grappolo)
  }
  # il grappolo singoletto è estraibile come gli altri
  expect_setequal(visti, c("A", "B", "C"))
})

test_that("samplecluster: frazione di grappoli e limiti", {
  d <- data.frame(g = rep(letters[1:10], each = 3), id = 1:30)
  r <- samplecluster(data = d, cluster_var = "g", id_var = "id",
                     size_mode = "fg", fg = 0.4, seed = 2)
  expect_equal(as.data.frame(r$summary)$ng_estratto, 4)   # round(10 * 0.4)

  expect_error(samplecluster(data = d, cluster_var = "g", id_var = "id",
                             size_mode = "ng", ng = 11, seed = 1))
  # servono almeno 2 grappoli distinti
  d1 <- data.frame(g = rep("solo", 6), id = 1:6)
  expect_error(samplecluster(data = d1, cluster_var = "g", id_var = "id",
                             size_mode = "ng", ng = 1, seed = 1))
})

# ---------------------------------------------------------------- due stadi --

test_that("samplemultistage estrae b unità per PSU (tutte nelle PSU piccole)", {
  d <- data.frame(
    p  = rep(c("P1", "P2", "P3", "P4"), times = c(10, 10, 2, 10)),
    id = sprintf("u%02d", 1:32)
  )
  for (s in 1:20) {
    r <- samplemultistage(data = d, psu_var = "p", id_var = "id",
                          psu_mode = "ng", ng = 3,
                          ssu_mode = "fixed", b = 4, seed = s)
    psu <- as.data.frame(r$psu_table)
    ext <- as.data.frame(r$extracted)

    expect_equal(nrow(psu), 3)
    # in ogni PSU estratta: min(b, dimensione)
    expect_equal(psu$n_estratte, pmin(4, psu$dim_psu))
    expect_equal(psu$f_psu, pmin(4, psu$dim_psu) / psu$dim_psu)
    expect_equal(as.data.frame(r$summary)$n_unita, sum(pmin(4, psu$dim_psu)))
    # nessuna unità proviene da una PSU non estratta
    expect_true(all(ext$psu %in% psu$psu))
    expect_true(all(!duplicated(ext$id_value)))
    # se P3 (2 unità) è estratta, entrambe le sue unità sono nel campione
    if ("P3" %in% psu$psu)
      expect_setequal(ext$id_value[ext$psu == "P3"], c("u21", "u22"))
  }
})

test_that("samplemultistage: PSU con una sola unità non fa saltare l'estrazione", {
  # è il caso che nello stratificato aveva rivelato la trappola di sample()
  # con pool di lunghezza 1: qui deve semplicemente prendere quell'unità.
  d <- data.frame(
    p  = c(rep("P1", 8), "P2", rep("P3", 8)),
    id = sprintf("u%02d", 1:17)
  )
  for (s in 1:25) {
    for (mode in c("fixed", "frac", "all")) {
      r <- samplemultistage(data = d, psu_var = "p", id_var = "id",
                            psu_mode = "ng", ng = 3,
                            ssu_mode = mode, b = 3, fb = 0.5, seed = s)
      psu <- as.data.frame(r$psu_table)
      ext <- as.data.frame(r$extracted)
      riga <- psu[psu$psu == "P2", , drop = FALSE]
      expect_equal(nrow(riga), 1, info = mode)
      expect_equal(riga$dim_psu, 1, info = mode)
      expect_equal(riga$n_estratte, 1, info = mode)
      expect_equal(ext$id_value[ext$psu == "P2"], "u09", info = mode)
    }
  }
})

test_that("samplemultistage: le tre modalità di secondo stadio", {
  d <- data.frame(p = rep(c("P1", "P2"), each = 10), id = sprintf("u%02d", 1:20))

  # frazionaria: round(n_j * f_b), con almeno un'unità
  r <- samplemultistage(data = d, psu_var = "p", id_var = "id",
                        psu_mode = "ng", ng = 2,
                        ssu_mode = "frac", fb = 0.3, seed = 7)
  expect_equal(as.data.frame(r$psu_table)$n_estratte, c(3, 3))

  r <- samplemultistage(data = d, psu_var = "p", id_var = "id",
                        psu_mode = "ng", ng = 2,
                        ssu_mode = "frac", fb = 0.0001, seed = 7)
  expect_equal(as.data.frame(r$psu_table)$n_estratte, c(1, 1))

  # "tutte le SSU": il due stadi degenera nel campionamento a grappoli
  r_all <- samplemultistage(data = d, psu_var = "p", id_var = "id",
                            psu_mode = "ng", ng = 1, ssu_mode = "all", seed = 3)
  psu <- as.data.frame(r_all$psu_table)
  expect_equal(psu$n_estratte, psu$dim_psu)
  r_cl <- samplecluster(data = d, cluster_var = "p", id_var = "id",
                        size_mode = "ng", ng = 1, seed = 3)
  expect_setequal(as.data.frame(r_all$extracted)$id_value,
                  as.data.frame(r_cl$extracted)$id_value)

  expect_error(samplemultistage(data = d, psu_var = "p", id_var = "id",
                                psu_mode = "ng", ng = 3, seed = 1))
})

# ------------------------------------------------- determinismo e stato RNG --

test_that("grappoli e due stadi: stesso seed, stesso campione", {
  d <- data.frame(g = rep(letters[1:6], each = 5), id = sprintf("u%02d", 1:30))
  a1 <- samplecluster(data = d, cluster_var = "g", id_var = "id",
                      size_mode = "ng", ng = 2, seed = 42)
  a2 <- samplecluster(data = d, cluster_var = "g", id_var = "id",
                      size_mode = "ng", ng = 2, seed = 42)
  expect_identical(as.data.frame(a1$extracted)$id_value,
                   as.data.frame(a2$extracted)$id_value)

  b1 <- samplemultistage(data = d, psu_var = "g", id_var = "id",
                         psu_mode = "ng", ng = 3, ssu_mode = "fixed", b = 2, seed = 42)
  b2 <- samplemultistage(data = d, psu_var = "g", id_var = "id",
                         psu_mode = "ng", ng = 3, ssu_mode = "fixed", b = 2, seed = 42)
  expect_identical(as.data.frame(b1$extracted)$id_value,
                   as.data.frame(b2$extracted)$id_value)
})

test_that("grappoli e due stadi non alterano lo stato del RNG globale", {
  d <- data.frame(g = rep(letters[1:6], each = 5), id = sprintf("u%02d", 1:30))
  set.seed(2024)
  stato_prima <- .Random.seed
  invisible(samplecluster(data = d, cluster_var = "g", id_var = "id",
                          size_mode = "ng", ng = 2, seed = 5))
  invisible(samplemultistage(data = d, psu_var = "g", id_var = "id",
                             psu_mode = "ng", ng = 2, ssu_mode = "fixed", b = 3, seed = 5))
  expect_identical(stato_prima, .Random.seed)
})
