# I grafici vanno DISEGNATI, non solo configurati.
#
# Un bug reale sfuggito fino alla 2.0.7: dopo la rotazione le matrici
# ruotate perdevano i nomi di colonna (il prodotto con la matrice di
# rotazione, priva di dimnames, li azzera) e la heatmap dei cos²
# falliva con "gli argomenti implicano un numero differente di righe".
# Le tabelle non se ne accorgevano perché usano nomi espliciti, e i
# test leggevano solo le tabelle: nessuna immagine veniva renderizzata.
# Questi test chiamano le funzioni di rendering su un device nullo.

.render_all <- function(analysis, plots) {
  priv <- analysis$.__enclos_env__$private
  errori <- character(0)
  for (nm in plots) {
    img <- analysis$results[[nm]]
    if (!isTRUE(img$visible)) next
    e <- tryCatch({
      res <- get(paste0(".", nm), envir = priv)(img)
      # Alcune funzioni stampano il grafico, altre restituiscono l'oggetto
      # ggplot lasciando a jamovi il compito di stamparlo. Senza questo
      # print() il grafico non verrebbe MAI disegnato e il test non
      # eserciterebbe davvero il rendering: gli errori dentro i geom
      # emergono solo al momento del disegno.
      if (inherits(res, "ggplot")) print(res)
      NA_character_
    }, error = function(x) paste0(nm, ": ", conditionMessage(x)))
    if (!is.na(e)) errori <- c(errori, e)
  }
  errori
}

.pca_plots <- c("plot_scree", "plot_circle", "plot_biplot", "plot_cos2", "plot_map")
.hc_plots  <- c("plot_dend", "plot_r2", "plot_rmsstd", "plot_deltaG", "plot_ch_index")

test_that("i grafici della PCA si disegnano con ogni rotazione e scala", {
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  for (rot in c("none", "varimax", "promax")) {
    for (std in c(TRUE, FALSE)) {
      o <- pcaOptions$new(vars = names(iris)[1:4], supp_qual_map = "Species",
                          ncp = 2, rotation = rot, standardize = std,
                          plot_scree = TRUE, plot_circle = TRUE,
                          plot_biplot = TRUE, plot_cos2 = TRUE,
                          plot_map = TRUE, map_show_active = TRUE)
      a <- pcaClass$new(options = o, data = iris)
      a$init(); a$run()
      expect_equal(.render_all(a, .pca_plots), character(0),
                   info = paste("rotazione", rot, "standardize", std))
    }
  }
})

test_that("i grafici della PCA si disegnano anche a ncp = 1 e ncp = 3", {
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  for (rot in c("none", "varimax", "promax")) {
    for (ncp in c(1, 3)) {
      o <- pcaOptions$new(vars = names(iris)[1:4], ncp = ncp, rotation = rot,
                          show_ind = TRUE, plot_scree = TRUE,
                          plot_circle = TRUE, plot_biplot = TRUE,
                          plot_cos2 = TRUE)
      a <- pcaClass$new(options = o, data = iris)
      a$init(); a$run()
      expect_equal(.render_all(a, .pca_plots), character(0),
                   info = paste("rotazione", rot, "ncp", ncp))
    }
  }
})

test_that("le matrici ruotate conservano i nomi delle componenti", {
  # è la causa diretta del bug della heatmap: senza colnames il
  # data.frame del grafico riceve un vettore vuoto
  for (rot in c("none", "varimax", "promax")) {
    o <- pcaOptions$new(vars = names(iris)[1:4], ncp = 2, rotation = rot,
                        plot_cos2 = TRUE, plot_circle = TRUE)
    a <- pcaClass$new(options = o, data = iris)
    a$init(); a$run()
    expect_identical(colnames(a$results$plot_cos2$state$cos2), c("PC1", "PC2"),
                     info = paste("rotazione", rot))
    expect_false(is.null(colnames(a$results$plot_circle$state$coord)))
  }
})

test_that("i grafici della cluster analysis si disegnano con ogni distanza", {
  grDevices::pdf(NULL); on.exit(grDevices::dev.off(), add = TRUE)
  for (dis in c("euclidean", "manhattan", "mahalanobis", "gower")) {
    o <- hcOptions$new(vars = names(iris)[1:4], dis = dis, n_clusters = 3,
                       dend = TRUE, r2 = TRUE, rmsstd = TRUE,
                       deltaG = TRUE, ch_index = TRUE)
    a <- hcClass$new(options = o, data = iris)
    a$init(); a$run()
    expect_equal(.render_all(a, .hc_plots), character(0), info = dis)
  }
})
