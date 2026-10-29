# Test di regressione per le 6 analisi di estrazione del campione.
# Coprono i bug corretti in 2.0.3:
#  - samplestrat: strato con una sola unità (trappola sample() scalare);
#  - samplesyst: sistematico a intervallo frazionario (k = N/n, partenza
#    in (0, k], nessuna unità esclusa a priori);
#  - determinismo del seed e ripristino del RNG globale;
#  - coerenza Σn_j = n nell'allocazione stratificata;
#  - sampleppv: pesi NA trattati come unità non campionabili.

test_that("samplestrat estrae sempre l'unica unità di uno strato singleton", {
  d <- data.frame(
    g  = c(rep("A", 8), "B"),
    id = letters[1:9]
  )
  for (s in c(1, 7, 42)) {
    r <- samplestrat(data = d, strat_var = "g", aux_var = NULL, id_var = "id",
                     size_mode = "n", n = 5, seed = s)
    ext <- as.data.frame(r$extracted)
    rowB <- ext[ext$livello == "B", , drop = FALSE]
    expect_equal(nrow(rowB), 1)
    expect_equal(rowB$pos, 9)
    expect_equal(rowB$id_value, "i")
  }
})

test_that("samplestrat: somma delle numerosità di strato = n richiesto", {
  set.seed(11)
  d <- data.frame(
    g = sample(c("A", "B", "C"), 60, replace = TRUE, prob = c(0.6, 0.3, 0.1)),
    x = rnorm(60)
  )
  for (met in c("proportional", "optimal")) {
    r <- samplestrat(data = d, strat_var = "g", aux_var = "x", id_var = NULL,
                     method = met, size_mode = "n", n = 20, seed = 3)
    strata <- as.data.frame(r$strata)
    smry <- as.data.frame(r$summary)
    expect_equal(sum(strata$nj), 20, info = met)
    expect_true(all(strata$nj <= strata$Nj), info = met)
    expect_equal(smry$n_estratto, 20, info = met)
  }
})

test_that("samplesyst: n unità e nessuna unità esclusa quando N non è multiplo di n", {
  # N = 10, n = 3 -> k = 10/3 = 3.333...: con l'intervallo frazionario
  # anche la decima unità è estraibile, cosa impossibile con k = 3.
  d <- data.frame(x = 1:10, id = letters[1:10])
  counts <- integer(10)
  for (s in 1:200) {
    r <- samplesyst(data = d, sort_var = NULL, id_var = "id",
                    size_mode = "n", n = 3, seed = s)
    smry <- as.data.frame(r$summary)
    expect_equal(smry$n_estratto, 3)
    expect_equal(smry$intervallo, 10 / 3)
    expect_true(smry$partenza > 0 && smry$partenza <= 10 / 3)
    ext <- as.data.frame(r$extracted)
    expect_equal(ext$pos, ceiling(smry$partenza + (10 / 3) * (0:2)))
    expect_true(all(ext$pos >= 1 & ext$pos <= 10))
    expect_equal(anyDuplicated(ext$pos), 0)
    counts[ext$pos_orig] <- counts[ext$pos_orig] + 1L
  }
  expect_true(all(counts > 0))   # nessuna unità ha probabilità nulla

  # quando N è multiplo di n l'intervallo è intero e vale lo stesso
  d2 <- data.frame(x = 1:12, id = 1:12)
  visti <- integer(12)
  for (s in 1:60) {
    r <- samplesyst(data = d2, sort_var = NULL, id_var = "id",
                    size_mode = "n", n = 4, seed = s)
    expect_equal(as.data.frame(r$summary)$intervallo, 3)
    ext <- as.data.frame(r$extracted)
    visti[ext$pos_orig] <- visti[ext$pos_orig] + 1L
  }
  expect_true(all(visti > 0))
})

test_that("samplesyst: l'ordinamento sposta le posizioni, non l'intervallo", {
  d <- data.frame(x = c(5, 1, 4, 2, 3, 6), id = letters[1:6])
  r <- samplesyst(data = d, sort_var = "x", id_var = "id",
                  size_mode = "n", n = 3, seed = 4)
  smry <- as.data.frame(r$summary)
  ext  <- as.data.frame(r$extracted)
  expect_equal(smry$intervallo, 2)
  expect_equal(ext$pos, ceiling(smry$partenza + 2 * (0:2)))
  # le posizioni sono nello spazio ordinato per x: i valori estratti di x
  # devono coincidere con quelli letti sull'ordinamento crescente
  expect_equal(d$x[ext$pos_orig], sort(d$x)[ext$pos])
})

test_that("stesso seed → stesso campione (determinismo)", {
  d <- data.frame(x = 1:40, id = sprintf("u%02d", 1:40))
  r1 <- samplesimple(data = d, id_var = "id", size_mode = "n", n = 10, seed = 99)
  r2 <- samplesimple(data = d, id_var = "id", size_mode = "n", n = 10, seed = 99)
  expect_identical(as.data.frame(r1$extracted)$id_value,
                   as.data.frame(r2$extracted)$id_value)

  r3 <- samplesyst(data = d, sort_var = NULL, id_var = "id",
                   size_mode = "n", n = 8, seed = 5)
  r4 <- samplesyst(data = d, sort_var = NULL, id_var = "id",
                   size_mode = "n", n = 8, seed = 5)
  expect_identical(as.data.frame(r3$summary)$partenza,
                   as.data.frame(r4$summary)$partenza)
})

test_that("le estrazioni non alterano lo stato del RNG globale", {
  set.seed(2024)
  stato_prima <- .Random.seed
  invisible(samplesimple(data = data.frame(x = 1:30, id = letters[1:26][c(1:26, 1:4)]),
                         id_var = "id", size_mode = "n", n = 5, seed = 1))
  # id_var va indicata: chiamando le analisi dall'API R senza alcuna
  # variabile selezionata, jmvcore::select() riceve un vettore di nomi
  # vuoto e va in errore prima di entrare nel modulo. Dentro jamovi il
  # percorso è un altro (i dati arrivano dall'app) e l'analisi funziona
  # anche senza variabili.
  invisible(samplesyst(data = data.frame(x = 1:30, id = 1:30), sort_var = NULL,
                       id_var = "id", size_mode = "n", n = 5, seed = 1))
  expect_identical(stato_prima, .Random.seed)
})

test_that("sampleppv esige pesi finiti e strettamente positivi", {
  base <- data.frame(w = c(10, 20, 30, 40, 50, 60), id = letters[1:6])
  esegui <- function(w) {
    d <- base; d$w <- w
    sampleppv(data = d, weight_var = "w", id_var = "id",
              size_mode = "n", n = 3, replacement = FALSE, seed = 5)
  }
  # pesi validi: nessun errore
  expect_error(esegui(base$w), NA)
  # ogni forma di peso non ammesso viene rifiutata, zero compreso
  for (w in list(c(10, 20, NA, 30, 40, 50),
                 c(10, 20, NaN, 30, 40, 50),
                 c(10, 20, Inf, 30, 40, 50),
                 c(10, 20, -5, 30, 40, 50),
                 c(10, 20, 0, 30, 40, 50))) {
    expect_error(esegui(w), "finiti e strettamente positivi|finite and strictly positive")
  }
})

test_that("CPV distingue probabilità di selezione e di inclusione", {
  d <- data.frame(w = c(10, 20, 30, 40, 50), id = LETTERS[1:5])
  n_req <- 3
  p <- d$w / sum(d$w)

  # con reinserimento: π_i = 1 − (1 − p_i)^n, in forma chiusa
  r <- sampleppv(data = d, weight_var = "w", id_var = "id",
                 size_mode = "n", n = n_req, replacement = TRUE, seed = 1)
  ext <- as.data.frame(r$extracted)
  idx <- match(ext$id_value, d$id)
  expect_equal(ext$prob, p[idx], tolerance = 1e-12)
  expect_equal(ext$pi_incl, (1 - (1 - p)^n_req)[idx], tolerance = 1e-12)

  # senza reinserimento le π_i non hanno forma chiusa: non riportate
  r2 <- sampleppv(data = d, weight_var = "w", id_var = "id",
                  size_mode = "n", n = n_req, replacement = FALSE, seed = 1)
  ext2 <- as.data.frame(r2$extracted)
  expect_true(all(is.na(ext2$pi_incl)))
  expect_true(all(is.finite(ext2$prob)))
})

test_that("le estrazioni lasciano intatto lo stato del RNG globale", {
  d <- data.frame(x = 1:100, id = sprintf("u%03d", 1:100))

  # (a) se il RNG non era inizializzato, non deve restare inizializzato
  if (exists(".Random.seed", envir = globalenv(), inherits = FALSE))
    rm(".Random.seed", envir = globalenv())
  invisible(samplesimple(data = d, id_var = "id", size_mode = "n",
                         n = 10, seed = 1))
  expect_false(exists(".Random.seed", envir = globalenv(), inherits = FALSE))

  # (b) se era inizializzato, deve tornare identico
  set.seed(12345)
  before <- get(".Random.seed", envir = globalenv())
  invisible(samplesimple(data = d, id_var = "id", size_mode = "n",
                         n = 10, seed = 7))
  expect_identical(get(".Random.seed", envir = globalenv()), before)
})

test_that("con reinserimento n/N non è etichettato come frazione di campionamento", {
  d <- data.frame(x = 1:100, id = sprintf("u%03d", 1:100))
  titolo <- function(r) r$summary$getColumn("frazione")$.__enclos_env__$private$.title
  r_scr <- samplesimple(data = d, id_var = "id", size_mode = "n", n = 200,
                        replacement = TRUE, seed = 1)
  r_ssr <- samplesimple(data = d, id_var = "id", size_mode = "n", n = 10,
                        replacement = FALSE, seed = 1)
  expect_match(titolo(r_scr), "Rapporto|ratio")
  expect_match(titolo(r_ssr), "Frazione|Sampling fraction")
  # con reinserimento il rapporto può superare 1: non è una frazione
  expect_equal(as.data.frame(r_scr$summary)$frazione, 2)
})

test_that("il campionamento a due stadi dichiara 'fino a b' unità per PSU", {
  d <- data.frame(g = rep(letters[1:5], each = 20),
                  id = sprintf("u%03d", 1:100))
  r <- samplemultistage(data = d, psu_var = "g", id_var = "id",
                        psu_mode = "ng", ng = 2, ssu_mode = "fixed",
                        b = 3, seed = 1)
  expect_match(as.data.frame(r$summary)$ssu_label, "fino a|up to")
})

test_that("l'allocazione stratificata usa il metodo dei resti maggiori", {
  alloc <- function(Nj, n, method = "proportional") {
    d <- data.frame(g = factor(rep(seq_along(Nj), times = Nj)),
                    id = seq_len(sum(Nj)),
                    aux = rnorm(sum(Nj)))
    as.data.frame(samplestrat(data = d, strat_var = "g", aux_var = "aux",
                              id_var = "id", method = method,
                              size_mode = "n", n = n, seed = 1)$strata)$nj
  }
  # Allocazione teorica (2.3, 3.4, 4.3): l'unità mancante spetta allo
  # strato con il resto decimale maggiore (il secondo), non a quello con
  # più capacità residua (il terzo, che darebbe 2-3-5).
  expect_identical(as.integer(alloc(c(23, 34, 43), 10)), c(2L, 4L, 4L))
  # allocazione già intera: invariata
  expect_identical(as.integer(alloc(c(20, 30, 50), 10)), c(2L, 3L, 5L))

  # invarianti su casi casuali: somma esatta e capacità rispettate
  set.seed(7)
  for (i in 1:25) {
    Nj <- sample(3:60, sample(2:5, 1), replace = TRUE)
    # n non può scendere sotto i minimi di strato (2 per strato)
    n <- sample(seq(2 * length(Nj), min(sum(Nj), 30)), 1)
    a <- alloc(Nj, n)
    expect_equal(sum(a), n)
    expect_true(all(a >= 0 & a <= Nj))
  }
})

test_that("gli strati saturati riallocano secondo i pesi, non la capacità", {
  # Strato 1 piccolo ma molto variabile: con Neyman verrebbe saturato e
  # il residuo va ripartito fra gli altri due in proporzione a Nj*sigma_j
  # (50 contro 150, cioè 1:3), non in base alla loro capacità (50 = 50).
  Nj <- c(4, 50, 50); sg <- c(10, 1, 3)
  set.seed(99)
  x <- unlist(lapply(seq_along(Nj), function(j) {
    v <- rnorm(Nj[j]); v / sd(v) * sg[j]
  }))
  d <- data.frame(g = factor(rep(seq_along(Nj), times = Nj)),
                  id = seq_len(sum(Nj)), aux = x)
  a <- as.data.frame(samplestrat(data = d, strat_var = "g", aux_var = "aux",
                                 id_var = "id", method = "optimal",
                                 size_mode = "n", n = 30, seed = 1)$strata)$nj
  expect_equal(a[1], 4)              # saturato alla propria ampiezza
  expect_equal(sum(a), 30)
  expect_true(all(a <= Nj))
  expect_lt(abs(a[3] / a[2] - 3), 0.35)   # rapporto ~ 150/50
})

test_that("Neyman distingue sigma non stimabile da sigma nulla", {
  # Strato A: 50 unità ma un solo valore ausiliario valido. sd() non è
  # stimabile: trattarla come 0 darebbe peso nullo allo strato e lo
  # escluderebbe dal campione come se fosse omogeneo.
  set.seed(1)
  d <- data.frame(g = factor(rep(c("A", "B"), each = 50)),
                  aux = c(3.5, rep(NA_real_, 49), rnorm(50)),
                  id = 1:100)
  expect_error(
    samplestrat(data = d, strat_var = "g", aux_var = "aux", id_var = "id",
                method = "optimal", size_mode = "n", n = 20, seed = 1),
    "stimabile|estimated")
  # la proporzionale non richiede sigma e deve funzionare
  a <- as.data.frame(
    samplestrat(data = d, strat_var = "g", aux_var = "aux", id_var = "id",
                method = "proportional", size_mode = "n", n = 20,
                seed = 1)$strata)
  expect_identical(as.integer(a$nj), c(10L, 10L))

  # uno strato con una sola unità IN POPOLAZIONE ha variabilità
  # realmente nulla: non deve bloccare l'analisi
  d2 <- data.frame(g = factor(c(rep("A", 30), rep("B", 30), "C")),
                   aux = c(rnorm(60), 5), id = 1:61)
  a2 <- as.data.frame(
    samplestrat(data = d2, strat_var = "g", aux_var = "aux", id_var = "id",
                method = "optimal", size_mode = "n", n = 12, seed = 1)$strata)
  expect_equal(sum(a2$nj), 12)

  # sigma stimata e pari a zero (valori tutti identici) è un'informazione
  # valida, non un dato mancante: l'analisi prosegue
  d3 <- data.frame(g = factor(rep(c("A", "B"), each = 20)),
                   aux = c(rep(7, 20), rnorm(20)), id = 1:40)
  a3 <- as.data.frame(
    samplestrat(data = d3, strat_var = "g", aux_var = "aux", id_var = "id",
                method = "optimal", size_mode = "n", n = 10, seed = 1)$strata)
  # sigma_j = 0 darebbe peso nullo e quindi n_j = 0: il vincolo di
  # rappresentanza minima porta comunque lo strato a 2 unità
  expect_equal(a3$nj[1], 2)
  expect_equal(sum(a3$nj), 10)
})

# Casuale semplice e sistematico non hanno variabili obbligatorie: la
# popolazione sono le righe del dataset. Chiamando le funzioni da R senza
# variabili, jmvcore::select() ricostruisce i dati da zero colonne e non
# conserva le righe. In jamovi invece il motore passa sempre tutte le righe
# non filtrate, anche senza colonne richieste. Questo helper riproduce il
# percorso di jamovi: intestazione in init(), dati completi in run().
.come_in_jamovi <- function(classe, opzioni, dati) {
  analisi <- classe$new(options = opzioni)
  leggi <- function(vars) dati[, unlist(vars), drop = FALSE]
  analisi$.setReadDatasetHeaderSource(function(vars) leggi(vars)[0, , drop = FALSE])
  analisi$.setReadDatasetSource(leggi)
  analisi$run()
  analisi$results
}

test_that("senza variabili e senza dati non compare nessun errore (2.0.13)", {
  # Il caso di un file nuovo, ancora vuoto: fino alla 2.0.12 appena aperta
  # l'analisi mostrava "Servono almeno 2 osservazioni" in rosso.
  for (dati in list(data.frame(id = integer(0)), data.frame(id = 1L))) {
    r <- .come_in_jamovi(samplesimpleClass,
                         samplesimpleOptions$new(id_var = NULL), dati)
    expect_false(r$summary$isFilled())
    r <- .come_in_jamovi(samplesystClass,
                         samplesystOptions$new(id_var = NULL, sort_var = NULL),
                         dati)
    expect_false(r$summary$isFilled())
  }
})

test_that("con una variabile scelta e meno di 2 osservazioni il messaggio resta", {
  una <- data.frame(id = 1L)
  msg <- "almeno 2 osservazioni|At least 2 observations"
  expect_error(.come_in_jamovi(samplesimpleClass,
                               samplesimpleOptions$new(id_var = "id"), una),
               msg)
  expect_error(.come_in_jamovi(samplesystClass,
                               samplesystOptions$new(id_var = "id",
                                                     sort_var = NULL), una),
               msg)
  expect_error(.come_in_jamovi(samplesystClass,
                               samplesystOptions$new(id_var = NULL,
                                                     sort_var = "id"), una),
               msg)
})

test_that("senza variabili l'estrazione usa tutte le righe del dataset", {
  # L'uscita silenziosa vale solo per N < 2: con dati veri le variabili
  # restano facoltative e il campione si estrae comunque.
  d <- data.frame(id = 1:50)
  s <- as.data.frame(.come_in_jamovi(
    samplesimpleClass,
    samplesimpleOptions$new(id_var = NULL, size_mode = "n", n = 10, seed = 1),
    d)$summary)
  expect_equal(s$N, 50)
  expect_equal(s$n_totale, 10)
  s <- as.data.frame(.come_in_jamovi(
    samplesystClass,
    samplesystOptions$new(id_var = NULL, sort_var = NULL, size_mode = "n",
                          n = 10, seed = 1),
    d)$summary)
  expect_equal(s$N, 50)
  expect_equal(s$n_estratto, 10)
})
