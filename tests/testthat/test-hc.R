# Smoke test della Cluster Analysis Gerarchica.
# Verifica:
#  - l'analisi gira senza errori su un dataset standard;
#  - la tabella delle metriche contiene i 4 indicatori attesi;
#  - i valori sono finiti e coerenti con le soglie sensate.

test_that("hc gira su iris con Ward + Euclidea", {
  dati <- iris[, 1:4]
  results <- hc(
    data = dati,
    vars = names(dati),
    method = "ward.D2",
    dis = "euclidean",
    n_clusters = 3
  )

  expect_s3_class(results, "Group")

  metriche <- as.data.frame(results$metriche)
  expect_true(all(c("r2", "rmsstd", "ch_index", "deltaG") %in% names(metriche)))
  expect_true(nrow(metriche) >= 2)

  # R² deve crescere con k e stare in [0, 1]
  expect_true(all(metriche$r2 >= 0 & metriche$r2 <= 1, na.rm = TRUE))
  expect_true(is.finite(max(metriche$ch_index, na.rm = TRUE)))
})

test_that("hc produce 3 cluster non vuoti con k=3", {
  dati <- iris[, 1:4]
  results <- hc(
    data = dati,
    vars = names(dati),
    n_clusters = 3
  )
  gruppi <- as.data.frame(results$groups)
  expect_equal(nrow(gruppi), 3)
  expect_true(all(gruppi$freq > 0))
  expect_equal(sum(gruppi$freq), nrow(dati))
})

test_that("hc esce in silenzio con meno di 2 variabili (come la PCA)", {
  # Nessun messaggio di errore mentre l'analisi è ancora incompleta:
  # il pannello "Istruzioni" spiega già che cosa serve.
  expect_s3_class(hc(data = iris, vars = "Sepal.Length"), "Group")
  # e nessuna tabella risultato viene popolata
  expect_equal(nrow(as.data.frame(hc(data = iris, vars = "Sepal.Length")$groups)), 0)
})

test_that("hc rifiuta n_clusters maggiore o uguale a n_osservazioni", {
  piccolo <- iris[1:5, 1:4]
  expect_error(
    hc(data = piccolo, vars = names(piccolo), n_clusters = 10),
    "inferiore al numero di osservazioni|smaller than the number of valid"
  )
})

test_that("hc rifiuta variabili costanti quando la standardizzazione è attiva", {
  piccolo <- iris[1:5, 1:4]   # Petal.Width è costante nelle prime 5 righe
  expect_error(
    hc(data = piccolo, vars = names(piccolo), n_clusters = 2),
    "costanti|constant"
  )
  # senza standardizzazione la stessa chiamata deve funzionare
  expect_s3_class(
    hc(data = piccolo, vars = names(piccolo), n_clusters = 2, stdVars = FALSE),
    "Group"
  )
})

test_that("Sokal-Michener su dati binari produce distanze in [0, 1]", {
  set.seed(42)
  bin <- as.data.frame(matrix(rbinom(200, 1, 0.4), ncol = 5))
  names(bin) <- paste0("v", 1:5)
  results <- hc(
    data = bin,
    vars = names(bin),
    dis = "SokalMichener",
    method = "average",
    n_clusters = 2
  )
  expect_s3_class(results, "Group")
})

test_that("Mahalanobis a coppie funziona su dati continui", {
  results <- hc(
    data = iris,
    vars = names(iris)[1:4],
    dis = "mahalanobis",
    method = "complete",
    n_clusters = 3
  )
  expect_s3_class(results, "Group")
})

test_that("Jaccard politomico segue la definizione one-hot", {
  # Riferimento indipendente: espansione one-hot + Jaccard classico.
  jac_onehot <- function(df) {
    cols <- list()
    for (k in seq_len(ncol(df))) {
      v <- df[[k]]
      for (l in sort(unique(v[v != 0])))
        cols[[length(cols) + 1L]] <- as.integer(v == l)
    }
    M <- do.call(cbind, cols)
    n <- nrow(M)
    out <- matrix(0, n, n)
    for (i in seq_len(n)) for (j in seq_len(n)) {
      inter <- sum(M[i, ] & M[j, ]); uni <- sum(M[i, ] | M[j, ])
      out[i, j] <- if (uni == 0) 0 else 1 - inter / uni
    }
    stats::as.dist(out)
  }
  # Caso di riferimento: V1 uguale (A/A), V2 diverso (B/C).
  # Feature one-hot: V1_A condivisa, V2_B e V2_C distinte →
  # |∩| = 1, |∪| = 3, d = 1 − 1/3 = 0.667 (non 0.5).
  d_ref <- jac_onehot(data.frame(V1 = c(1, 1), V2 = c(1, 2)))
  expect_equal(as.numeric(d_ref), 2/3, tolerance = 1e-12)

  # L'analisi con questa metrica gira e produce cluster non vuoti
  set.seed(15)
  dati <- as.data.frame(matrix(sample(0:3, 30 * 5, TRUE), ncol = 5))
  res <- hc(data = dati, vars = names(dati), dis = "politomici",
            method = "average", n_clusters = 3, stdVars = FALSE)
  expect_s3_class(res, "Group")
  gruppi <- as.data.frame(res$groups)
  expect_equal(sum(gruppi$freq), nrow(dati))
})

test_that("Gower accetta dataset misti quantitativi + qualitativi", {
  set.seed(3)
  n <- 40
  d_mix <- data.frame(
    eta     = rnorm(n, 45, 12),
    reddito = rlnorm(n, 10, 0.4),
    sesso   = factor(sample(c("M", "F"), n, TRUE)),
    area    = factor(sample(c("Nord", "Centro", "Sud"), n, TRUE))
  )
  res <- hc(data = d_mix, vars = names(d_mix), dis = "gower",
            method = "average", n_clusters = 3)
  expect_s3_class(res, "Group")

  # le dimensioni dei cluster coincidono con daisy() applicata al
  # data.frame misto originale (i fattori sono usati davvero)
  ref <- cutree(hclust(cluster::daisy(d_mix, metric = "gower"),
                       method = "average"), 3)
  gruppi <- as.data.frame(res$groups)
  expect_equal(sort(as.integer(gruppi$freq)), sort(as.integer(table(ref))))

  # R²/RMSSTD/CH non sono definite su dati non quantitativi
  mt <- as.data.frame(res$metriche)
  expect_true(all(is.na(mt$r2)))
  expect_true(all(is.na(mt$ch_index)))
  # Delta G dipende solo dalle altezze di fusione e resta disponibile
  expect_true(all(is.finite(mt$deltaG)))
})

test_that("le distanze quantitative rifiutano variabili categoriali", {
  d_mix <- data.frame(x = rnorm(20), g = factor(sample(c("a", "b"), 20, TRUE)))
  expect_error(
    hc(data = d_mix, vars = c("x", "g"), dis = "euclidean", n_clusters = 2),
    "categorial|Gower"
  )
})

test_that("il Jaccard binario richiede una codifica realmente 0/1", {
  # dist(method = "binary") interpreta ogni valore non-zero come
  # "presenza": con i codici 1..L di un fattore ogni cella risulterebbe
  # presente e tutte le distanze verrebbero 0.
  d_mf <- data.frame(sesso = factor(c("M","F","M","F","M","F")),
                     area  = factor(c("N","N","S","S","N","S")))
  res <- hc(data = d_mf, vars = names(d_mf), dis = "binary",
            method = "average", n_clusters = 2, stdVars = FALSE)
  gruppi <- as.data.frame(res$groups)
  expect_equal(nrow(gruppi), 2)
  expect_true(all(gruppi$freq > 0))       # non degenere
  expect_equal(sum(gruppi$freq), 6)

  # un fattore con livelli "0"/"1" deve dare lo stesso risultato dei
  # corrispondenti valori numerici
  gr <- function(dd) as.data.frame(
    hc(data = dd, vars = names(dd), dis = "binary", method = "average",
       n_clusters = 2, stdVars = FALSE)$groups)$freq
  expect_identical(
    gr(data.frame(v1 = factor(c("0","1","1","0")), v2 = factor(c("1","1","0","0")))),
    gr(data.frame(v1 = c(0,1,1,0), v2 = c(1,1,0,0))))

  # più di due modalità: rifiutato, con rimando al Jaccard politomico
  expect_error(
    hc(data = data.frame(v = factor(c("a","b","c","a")),
                         w = factor(c("a","a","b","b"))),
       vars = c("v","w"), dis = "binary", n_clusters = 2, stdVars = FALSE),
    "politomic|polytomous")

  # valori numerici diversi da 0/1: rifiutati invece di calcolare
  # silenziosamente qualcosa di diverso da un Jaccard
  expect_error(
    hc(data = data.frame(a = c(0,1,2,1), b = c(1,0,2,0)),
       vars = c("a","b"), dis = "binary", n_clusters = 2, stdVars = FALSE),
    "0/1")
})

test_that("lo zero significa assenza sia per i numeri sia per i fattori", {
  # La stessa variabile non deve dare distanze diverse a seconda che sia
  # dichiarata quantitativa o nominale.
  gr <- function(dd) as.data.frame(
    hc(data = dd, vars = names(dd), dis = "politomici", method = "average",
       n_clusters = 2, stdVars = FALSE)$groups)$freq
  set.seed(9)
  num <- data.frame(a = sample(0:2, 30, TRUE), b = sample(0:2, 30, TRUE))
  fac <- data.frame(a = factor(num$a), b = factor(num$b))
  expect_identical(gr(num), gr(fac))

  # fattori con modalità testuali: non esiste "assenza", ogni modalità
  # è una presenza e l'analisi gira comunque
  expect_length(gr(data.frame(a = factor(c("rosso","verde","rosso")),
                              b = factor(c("si","si","no")))), 2)
})

test_that("hc non produce errori quando l'analisi non è ancora impostata", {
  # come la PCA: con meno di 2 variabili si esce in silenzio, senza
  # messaggio rosso mentre l'utente sta ancora componendo l'analisi
  expect_s3_class(hc(data = iris, vars = "Sepal.Length"), "Group")
})

test_that("le distanze quantitative accettano modalità numeriche ma non testuali", {
  # lo studente deve poter applicare (sbagliando) una distanza
  # quantitativa a una categoriale codificata con numeri...
  d_codici <- data.frame(x = rnorm(20),
                         g = factor(sample(c("1","2","3"), 20, TRUE)))
  expect_s3_class(
    hc(data = d_codici, vars = c("x","g"), dis = "euclidean", n_clusters = 2),
    "Group")
  # ...ma su modalità testuali il calcolo è impossibile
  d_testo <- data.frame(x = rnorm(20),
                        g = factor(sample(c("M","F"), 20, TRUE)))
  expect_error(
    hc(data = d_testo, vars = c("x","g"), dis = "euclidean", n_clusters = 2),
    "testual|textual")
})

test_that("la visibilità dei grafici segue la checkbox in entrambi i sensi", {
  vis <- function(...) {
    r <- hc(data = iris[, 1:4], vars = names(iris)[1:4], n_clusters = 3, ...)
    unname(c(r$plot_dend$visible, r$plot_r2$visible, r$plot_rmsstd$visible,
             r$plot_deltaG$visible, r$plot_ch_index$visible))
  }
  expect_true(all(vis(dend = TRUE, r2 = TRUE, rmsstd = TRUE,
                      deltaG = TRUE, ch_index = TRUE)))
  # deselezionando, i grafici NON devono restare visibili con il
  # contenuto della precedente esecuzione
  expect_false(any(vis(dend = FALSE, r2 = FALSE, rmsstd = FALSE,
                       deltaG = FALSE, ch_index = FALSE)))
  expect_identical(vis(dend = TRUE, r2 = FALSE, rmsstd = TRUE,
                       deltaG = FALSE, ch_index = TRUE),
                   c(TRUE, FALSE, TRUE, FALSE, TRUE))
})

# --- 2.1.2: binarie di presenza/assenza con Gower ---------------------------
altezze_hc <- function(...) {
  hc(n_clusters = 2, dend = TRUE, ...)$plot_dend$state[[1]]$height
}

test_that("con Gower la co-assenza delle binarie di presenza/assenza non conta", {
  # Calcolo a mano. x ha campo di variazione 10; a e' di presenza/assenza.
  #   asimmetrica: d(1,2) = 10/10 = 1 (co-assenza esclusa),
  #     d(1,3) = (0,4 + 1)/2 = 0,7, d(2,3) = (0,6 + 1)/2 = 0,8
  #   simmetrica:  d(1,2) = (1 + 0)/2 = 0,5, le altre uguali
  # Legame singolo: fusioni a 0,7 e 0,8 contro 0,5 e 0,7.
  d <- data.frame(x = c(0, 10, 4), a = c(0, 0, 1))
  expect_equal(altezze_hc(data = d, vars = "x", asimm = "a", dis = "gower",
                          method = "single"), c(0.7, 0.8))
  expect_equal(altezze_hc(data = d, vars = c("x", "a"), dis = "gower",
                          method = "single"), c(0.5, 0.7))

  # Coincide con daisy(type = list(asymm = ...)) sull'esempio delle dispense
  clienti <- data.frame(
    eta            = c(28, 45, 33, 52, 27, 39),
    reddito        = c(1800, 3200, 2100, 4500, 1700, 2600),
    sesso          = factor(c("F", "M", "F", "M", "F", "M")),
    auto_elettrica = c(1, 0, 0, 1, 0, 1))
  rif <- function(tipo) hclust(cluster::daisy(clienti, metric = "gower", type = tipo),
                               method = "average")$height
  expect_equal(altezze_hc(data = clienti, vars = c("eta", "reddito", "sesso"),
                          asimm = "auto_elettrica", dis = "gower", method = "average"),
               rif(list(asymm = "auto_elettrica")))
  # nella base la stessa variabile resta simmetrica, come fino alla 2.1.1
  expect_equal(altezze_hc(data = clienti, vars = names(clienti), dis = "gower",
                          method = "average"),
               rif(list()))
})

test_that("le binarie di presenza/assenza ammettono 0/1 numerici, fattori 0/1 e due modalita' testuali", {
  d <- data.frame(x = c(0, 10, 4, 7), a = c(0, 0, 1, 1))
  atteso <- altezze_hc(data = d, vars = "x", asimm = "a", dis = "gower",
                       method = "average")
  d_f <- data.frame(x = d$x, a = factor(c("0", "0", "1", "1")))
  expect_equal(altezze_hc(data = d_f, vars = "x", asimm = "a", dis = "gower",
                          method = "average"), atteso)
  # due modalita' testuali: il primo livello e' l'assenza, e la nota lo dice
  d_t <- data.frame(x = d$x, a = factor(c("no", "no", "si", "si"), levels = c("no", "si")))
  r <- hc(data = d_t, vars = "x", asimm = "a", dis = "gower", method = "average",
          n_clusters = 2, dend = TRUE)
  expect_equal(r$plot_dend$state[[1]]$height, atteso)
  expect_match(r$izpis$notes[["codifica"]]$note, "no=0, si=1", fixed = TRUE)
  expect_match(r$izpis$notes[["asimm"]]$note, "co-assenza|co-absence")
})

test_that("le binarie di presenza/assenza rifiutano codifiche diverse da 0/1", {
  expect_error(
    hc(data = data.frame(x = c(0, 10, 4, 7), a = factor(c("a", "b", "c", "a"))),
       vars = "x", asimm = "a", dis = "gower", n_clusters = 2),
    "presenza/assenza|Presence/absence")
  expect_error(
    hc(data = data.frame(x = c(0, 10, 4, 7), a = c(0, 1, 2, 1)),
       vars = "x", asimm = "a", dis = "gower", n_clusters = 2),
    "presenza/assenza|Presence/absence")
})

test_that("base di sole binarie di presenza/assenza: la co-assenza totale vale 0", {
  # le unita' 2 e 3 hanno 0 su tutte le variabili: nessun confronto possibile
  solo <- data.frame(a = c(1, 0, 0, 1, 0), b = c(0, 0, 0, 1, 1))
  r <- hc(data = solo, vars = NULL, asimm = c("a", "b"), dis = "gower", method = "average",
          n_clusters = 2, dend = TRUE)
  expect_true(all(is.finite(r$plot_dend$state[[1]]$height)))
  expect_false(is.null(r$izpis$notes[["coassenza_totale"]]))
})

test_that("una binaria costante resta fuori dal calcolo senza avvisi di daisy", {
  d <- data.frame(x = c(1, 5, 3, 9), a = c(0, 0, 0, 0))
  expect_no_warning(
    r <- hc(data = d, vars = "x", asimm = "a", dis = "gower", n_clusters = 2))
  expect_match(r$izpis$notes[["asimm"]]$note, "Restano fuori|Left out")
})

test_that("con le altre distanze le binarie di presenza/assenza entrano nella base", {
  d <- data.frame(x = rnorm(10), y = rnorm(10), a = rep(c(0, 1), 5))
  r <- hc(data = d, vars = c("x", "y"), asimm = "a", dis = "euclidean",
          n_clusters = 2)
  expect_equal(as.data.frame(r$izpis)$var, 3)
  expect_match(r$izpis$notes[["asimm"]]$note, "solo con la distanza di Gower|only with the Gower distance")
})

test_that("la base conta le variabili di entrambe le caselle", {
  d <- data.frame(x = c(0, 10, 4, 7), a = c(0, 0, 1, 1))
  # una variabile per casella: la base ne ha due e l'analisi parte
  r <- hc(data = d, vars = "x", asimm = "a", dis = "gower", n_clusters = 2)
  expect_equal(sum(as.data.frame(r$groups)$freq), 4)
  # una sola variabile in tutto: si esce in silenzio, come con vars
  expect_equal(nrow(as.data.frame(hc(data = d, vars = NULL, asimm = "a", dis = "gower")$groups)), 0)
})
