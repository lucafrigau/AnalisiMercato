# Smoke test della Principal Component Analysis.
# Verifica:
#  - l'analisi gira con e senza rotazione (Varimax / Promax);
#  - i cos² delle variabili sono sempre nei limiti teorici [0, 1];
#  - i contributi sommano a 100 per ciascuna componente;
#  - le variabili supplementari (quanti/quali) vengono accettate;
#  - i casi degeneri (vars < 2) sono gestiti.

test_that("pca gira su iris (standardizzata, nessuna rotazione)", {
  results <- pca(
    data = iris,
    vars = names(iris)[1:4],
    supp_quant = NULL, supp_qual = NULL, supp_qual_map = NULL, id_var = NULL,
    ncp = 2,
    rotation = "none",
    plot_scree = FALSE, plot_circle = FALSE, plot_biplot = FALSE,
    plot_cos2 = FALSE, plot_map = FALSE
  )
  expect_s3_class(results, "Group")

  eig <- as.data.frame(results$eigenvalues)
  expect_true(all(c("eig", "var_pct", "cum_pct") %in% names(eig)))
  expect_equal(nrow(eig), 4)
  # Su iris standardizzata la prima componente spiega ~73% della varianza
  expect_true(eig$var_pct[1] > 60)
  # La cumulata finale deve essere ~100
  expect_equal(eig$cum_pct[nrow(eig)], 100, tolerance = 1e-6)
})

test_that("pca: cos² nei limiti teorici [0, 1] anche con Promax", {
  for (rot in c("none", "varimax", "promax")) {
    results <- pca(
      data = iris,
      vars = names(iris)[1:4],
      supp_quant = NULL, supp_qual = NULL, supp_qual_map = NULL, id_var = NULL,
      ncp = 2,
      rotation = rot,
      plot_scree = FALSE, plot_circle = FALSE, plot_biplot = FALSE,
      plot_cos2 = FALSE, plot_map = FALSE
    )
    cos2 <- as.matrix(as.data.frame(results$var_cos2)[, -1])
    expect_true(all(cos2 >= 0 & cos2 <= 1 + 1e-9, na.rm = TRUE),
                info = paste("rotation =", rot, "max cos² =", max(cos2)))
  }
})

test_that("pca: contributi % sommano a 100 per ciascuna componente", {
  results <- pca(
    data = iris,
    vars = names(iris)[1:4],
    supp_quant = NULL, supp_qual = NULL, supp_qual_map = NULL, id_var = NULL,
    ncp = 3,
    rotation = "none",
    plot_scree = FALSE, plot_circle = FALSE, plot_biplot = FALSE,
    plot_cos2 = FALSE, plot_map = FALSE
  )
  contrib <- as.matrix(as.data.frame(results$var_contrib)[, -1])
  sums <- unname(colSums(contrib))
  expect_equal(sums, rep(100, ncol(contrib)), tolerance = 1e-6)
})

test_that("pca con variabile qualitativa supplementare (biplot)", {
  results <- pca(
    data = iris,
    vars = names(iris)[1:4],
    supp_quant = NULL, supp_qual = "Species", supp_qual_map = NULL, id_var = NULL,
    ncp = 2,
    plot_scree = FALSE, plot_circle = FALSE, plot_biplot = FALSE,
    plot_cos2 = FALSE, plot_map = FALSE
  )
  expect_s3_class(results, "Group")
})

test_that("pca con variabile quantitativa supplementare", {
  df <- iris
  df$extra <- df$Sepal.Length * 2 + rnorm(nrow(df), sd = 0.5)
  results <- pca(
    data = df,
    vars = names(iris)[1:4],
    supp_quant = "extra", supp_qual = NULL, supp_qual_map = NULL, id_var = NULL,
    ncp = 2,
    plot_scree = FALSE, plot_circle = FALSE, plot_biplot = FALSE,
    plot_cos2 = FALSE, plot_map = FALSE
  )
  expect_s3_class(results, "Group")
})

test_that("pca con mappa di posizionamento (supp_qual_map)", {
  results <- pca(
    data = iris,
    vars = names(iris)[1:4],
    supp_quant = NULL, supp_qual = NULL,
    supp_qual_map = "Species", id_var = NULL,
    ncp = 2,
    plot_scree = FALSE, plot_circle = FALSE, plot_biplot = FALSE,
    plot_cos2 = FALSE, plot_map = TRUE
  )
  expect_s3_class(results, "Group")
})

test_that("pca con vars < 2 ritorna senza errore (no-op)", {
  results <- pca(
    data = iris,
    vars = "Sepal.Length",
    supp_quant = NULL, supp_qual = NULL, supp_qual_map = NULL, id_var = NULL,
    ncp = 2
  )
  expect_s3_class(results, "Group")
})

test_that("pca con ncp > min(p, n-1) viene clampato", {
  results <- pca(
    data = iris,
    vars = names(iris)[1:3],
    supp_quant = NULL, supp_qual = NULL, supp_qual_map = NULL, id_var = NULL,
    ncp = 5,
    plot_scree = FALSE, plot_circle = FALSE, plot_biplot = FALSE,
    plot_cos2 = FALSE, plot_map = FALSE
  )
  expect_s3_class(results, "Group")
  settings <- as.data.frame(results$settings)
  # Con 3 variabili max ncp utilizzabili è 3
  expect_true(as.integer(settings$ncp_used) <= 3)
})

# --- Regressioni 2.0.3 ---

test_that("pca: asse oltre ncp con variabili supplementari non crasha (reg. 2.0.3)", {
  # In 2.0.2 le matrici supplementari erano tagliate a ncp colonne anche
  # senza rotazione: axis_y = 3 con ncp = 2 -> "subscript out of bounds".
  expect_s3_class(
    pca(
      data = iris,
      vars = names(iris)[1:3],
      supp_quant = "Petal.Width", supp_qual = NULL,
      supp_qual_map = "Species", id_var = NULL,
      ncp = 2, axis_x = 1, axis_y = 3,
      plot_circle = TRUE, plot_map = TRUE
    ),
    "Group"
  )
})

test_that("pca: cos² in [0, 1] anche senza standardizzazione + rotazione (reg. 2.0.3)", {
  # In 2.0.2 con standardize = FALSE i cos² ruotati erano covarianze al
  # quadrato (anche > 10000 su mtcars).
  for (rot in c("varimax", "promax")) {
    results <- pca(
      data = mtcars,
      vars = c("mpg", "disp", "hp", "drat", "wt"),
      supp_quant = NULL, supp_qual = NULL, supp_qual_map = NULL, id_var = NULL,
      standardize = FALSE, ncp = 2, rotation = rot,
      plot_scree = FALSE, plot_circle = FALSE, plot_biplot = FALSE,
      plot_cos2 = FALSE, plot_map = FALSE
    )
    cos2 <- as.matrix(as.data.frame(results$var_cos2)[, -1])
    expect_true(all(cos2 >= 0 & cos2 <= 1 + 1e-9, na.rm = TRUE),
                info = paste("standardize=FALSE, rotation =", rot,
                             "max cos² =", max(cos2)))
  }
})

test_that("pca: autovalori ruotati in ordine decrescente (reg. 2.0.3)", {
  results <- pca(
    data = iris,
    vars = names(iris)[1:4],
    supp_quant = NULL, supp_qual = NULL, supp_qual_map = NULL, id_var = NULL,
    ncp = 3, rotation = "varimax",
    plot_scree = FALSE, plot_circle = FALSE, plot_biplot = FALSE,
    plot_cos2 = FALSE, plot_map = FALSE
  )
  eig <- as.data.frame(results$eigenvalues)
  er <- suppressWarnings(as.numeric(eig$eig_rot))
  er <- er[is.finite(er)]
  expect_true(all(diff(er) <= 1e-9))
})

test_that("pca: variabile attiva costante -> reject esplicito (reg. 2.0.3)", {
  d <- iris[, 1:3]
  d$cost <- 1
  expect_error(
    pca(
      data = d, vars = names(d),
      supp_quant = NULL, supp_qual = NULL, supp_qual_map = NULL, id_var = NULL,
      ncp = 2
    ),
    "costanti|constant"
  )
})

test_that("la rotazione non altera autovalori, varianza spiegata e scree plot", {
  P <- function(rot) pca(data = iris, vars = names(iris)[1:4],
                         supp_quant = NULL, supp_qual = NULL,
                         supp_qual_map = NULL, id_var = NULL,
                         ncp = 2, rotation = rot, plot_scree = TRUE)
  e_none <- as.data.frame(P("none")$eigenvalues)
  e_vari <- as.data.frame(P("varimax")$eigenvalues)
  e_prom <- as.data.frame(P("promax")$eigenvalues)
  expect_equal(e_none$eig, e_vari$eig)
  expect_equal(e_none$eig, e_prom$eig)
  expect_equal(e_none$cum_pct, e_prom$cum_pct)
  # niente più colonne "ruotate" nella tabella degli autovalori
  expect_false(any(grepl("rot", names(e_vari))))
  # e lo scree plot resta quello della soluzione originale
  expect_equal(P("none")$plot_scree$state$eig, P("promax")$plot_scree$state$eig)
})

test_that("titolo e didascalia dello scree plot non annunciano autovalori ruotati", {
  # Il grafico disegna SEMPRE `eig_for_scree <- eig`, cioè gli autovalori
  # della soluzione originale (è l'invariante del test qui sopra). Fino
  # alla 2.0.8 titolo e didascalia dicevano l'opposto — "Scree plot —
  # autovalori ruotati (Varimax)", "Autovalori delle prime componenti
  # ridistribuiti dalla rotazione" — retaggio di quando il grafico veniva
  # davvero ridisegnato sui valori ruotati: lo studente leggeva il
  # contrario di ciò che vedeva, in contraddizione con il pannello di
  # istruzioni e con la tabella delle SS loadings. Il test controlla ciò
  # che l'immagine dichiara, non il suo stato, perché il difetto stava
  # tutto nelle etichette costruite dentro `.plot_scree`.
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)

  scree <- function(rot, lang) {
    old <- Sys.getenv("ANALISIMERCATO_LANG", unset = NA_character_)
    on.exit(if (is.na(old)) Sys.unsetenv("ANALISIMERCATO_LANG")
            else Sys.setenv(ANALISIMERCATO_LANG = old), add = TRUE)
    Sys.setenv(ANALISIMERCATO_LANG = lang)
    o <- pcaOptions$new(vars = names(iris)[1:4], ncp = 2, rotation = rot,
                        plot_scree = TRUE)
    a <- pcaClass$new(options = o, data = iris)
    a$init(); a$run()
    a$.__enclos_env__$private$.plot_scree(a$results$plot_scree)
    p <- ggplot2::last_plot()
    list(title = p$labels$title, caption = p$labels$caption, eig = p$data$eig)
  }

  # Affermazioni false: nessuna descrive ciò che il grafico contiene.
  falso <- paste("autovalori\\s+ruotati", "rotated\\s+eigenvalues",
                 "ridistribuiti\\s+dalla\\s+rotazione",
                 "redistributed\\s+by\\s+the\\s+rotation", sep = "|")

  for (lang in c("", "en")) {
    for (rot in c("none", "varimax", "promax")) {
      s <- scree(rot, lang)
      nota <- paste("lang =", if (nzchar(lang)) lang else "it",
                    "| rotazione =", rot)
      # il titolo resta neutro: non promette una soluzione ruotata
      expect_false(grepl("ruotat|rotated|rotazione|rotation|varimax|promax",
                         s$title, ignore.case = TRUE), info = nota)
      expect_false(grepl(falso, s$caption, ignore.case = TRUE), info = nota)
    }
  }

  # Togliere la frase sbagliata non basta: con la rotazione attiva la
  # didascalia deve dire di quali autovalori si tratta e dove trovare le
  # somme dei quadrati dei loadings ruotati.
  it <- scree("varimax", "")
  expect_match(it$caption, "non ruotat|originale")
  expect_match(it$caption, "SS loadings|somme dei quadrati|tabella dedicata")
  en <- scree("promax", "en")
  expect_match(en$caption, "unrotated|original")
  expect_match(en$caption, "SS loadings|sums of squares|dedicated table")

  # Senza rotazione la didascalia non parla affatto di rotazione...
  expect_false(grepl("rotazione", scree("none", "")$caption))
  # ...e ciò che viene disegnato sono davvero gli autovalori originali.
  expect_equal(it$eig, scree("none", "")$eig)
})

test_that("le SS loadings stanno in una tabella separata, additive solo se ortogonali", {
  P <- function(rot) pca(data = iris, vars = names(iris)[1:4],
                         supp_quant = NULL, supp_qual = NULL,
                         supp_qual_map = NULL, id_var = NULL,
                         ncp = 2, rotation = rot)
  # senza rotazione la tabella è vuota
  expect_equal(nrow(as.data.frame(P("none")$ss_loadings)), 0)

  ss_v <- as.data.frame(P("varimax")$ss_loadings)
  expect_equal(nrow(ss_v), 2)
  # Varimax (ortogonale) preserva la varianza totale delle componenti
  ref <- FactoMineR::PCA(iris[, 1:4], scale.unit = TRUE, ncp = 4, graph = FALSE)
  expect_equal(sum(ss_v$ss), sum(ref$eig[1:2, 1]), tolerance = 1e-10)
  expect_true(all(is.finite(ss_v$ss_pct)))

  # Promax (obliqua): SS riportate, quote di varianza NO (non sommabili)
  ss_p <- as.data.frame(P("promax")$ss_loadings)
  expect_true(all(is.finite(ss_p$ss)))
  expect_true(all(is.na(ss_p$ss_pct)))
  expect_true(all(is.na(ss_p$ss_cum)))
})

test_that("titoli e SS loadings si ripristinano tornando a nessuna rotazione", {
  P <- function(rot) pca(data = iris, vars = names(iris)[1:4],
                         supp_quant = NULL, supp_qual = NULL,
                         supp_qual_map = NULL, id_var = NULL,
                         ncp = 2, rotation = rot, show_ind = TRUE)
  expect_match(P("varimax")$var_coord$title, "ruotat|rotated")
  r_none <- P("none")
  expect_false(grepl("ruotat|rotated", r_none$var_coord$title))
  expect_false(grepl("ruotat|rotated", r_none$ind_group$ind_coord$title))
  expect_false(r_none$ss_loadings$visible)
})
