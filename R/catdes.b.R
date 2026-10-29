# This file is a generated template, your changes will not be overwritten

catdesClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "catdesClass",
    inherit = catdesBase,
    active = list(
      dataProcessed = function() {
        if (is.null(private$.dataProcessed)) {
          private$.dataProcessed <- private$.buildData()
        }

        return(private$.dataProcessed)
      },
      condesResult = function() {
        if (is.null(private$.condesResult)) {
          private$.condesResult <- private$.getcondesResult()
        }

        return(private$.condesResult)
      },
      catdesResult = function() {
        if (is.null(private$.catdesResult)) {
          private$.catdesResult <- private$.getcatdesResult()
        }

        return(private$.catdesResult)
      },
      catdesCategoryResult = function() {
        if (is.null(private$.catdesCategoryResult)) {
          private$.catdesCategoryResult <- private$.getcatdesCategoryResult()
        }

        return(private$.catdesCategoryResult)
      },
      catdesCategoryQuantiResult = function() {
        if (is.null(private$.catdesCategoryQuantiResult)) {
          private$.catdesCategoryQuantiResult <- private$.getcatdesCategoryQuantiResult()
        }

        return(private$.catdesCategoryQuantiResult)
      }
    ),
    private = list(
      .dataProcessed = NULL,
      .catdesResult = NULL,
      .condesResult = NULL,
      .catdesCategoryResult = NULL,
      .catdesCategoryQuantiResult = NULL,

      #---------------------------------------------
      #### Init + run functions ----

      .init = function() {
        if (is.null(self$options$descbyvar)) {
          if (self$options$tuto == TRUE) {
            self$results$instructions$setVisible(visible = TRUE)
          }
        }

        self$results$instructions$setContent(.tr(
          it = "<html>
            <head>
            </head>
            <body>
            <div class='justified-text'>
              <h3>Caratterizzazione dei Cluster (catdes)</h3>
              <p>
                Questo modulo serve a <b>interpretare</b> una soluzione di clustering, cioè a capire
                <b>quali variabili distinguono davvero i gruppi</b>.
              </p>
                <p> La funzione Caratterizzazione consente appunto la caratterizzazione sia di
                    variabili quantitative che qualitative (i.e. la variabile con le etichette della Cluster)
                    in base alle loro relazioni con tutte le
                    altre variabili nel dataset. Caratterizzazione utilizza test statistici specifici
                    per scenari diversi. Ad esempio, per due variabili quantitative, utilizza il
                    coefficiente di correlazione; per due variabili qualitative, utilizza il test
                    Chi-quadro di indipendenza. Inoltre, quando una variabile e' quantitativa e
                    l'altra qualitativa, il modulo utilizza il coefficiente di determinazione per
                    stabilire la loro relazione. Questo approccio garantisce un'analisi approfondita
                    del dataset e una comprensione completa delle relazioni tra le variabili.</p>

                    <p> A un livello piu' dettagliato, Caratterizzazione esegue test di associazione
                    specificamente per le variabili qualitative. Nel caso di due variabili qualitative,
                    Caratterizzazione analizza l'eventuale sovra- o sotto-rappresentazione di una
                    categoria all'interno di un'altra rispetto alla popolazione totale. Quando una
                    variabile e' quantitativa e l'altra qualitativa, Caratterizzazione esamina se
                    il valore medio della variabile quantitativa all'interno di un sottogruppo definito
                    da una determinata categoria e' superiore o inferiore al valore medio della
                    popolazione generale.</p>
              <h4>Da dove deriva la metodologia</h4>
              <p>
                Le funzioni principali utilizzate sono <code>FactoMineR::catdes()</code> e <code>FactoMineR::condes()</code>,
                quindi il cuore metodologico riprende il pacchetto <b>FactoMineR</b>.
                L'impostazione delle tabelle e la logica di presentazione dei risultati sono ispirate al modulo
                <b>MEDA</b>, da cui questa implementazione deriva e viene adattata in chiave didattica.
              </p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head>
            </head>
            <body>
            <div class='justified-text'>
              <h3>Cluster description (catdes)</h3>
              <p>
                This module helps you <b>interpret</b> a clustering solution by identifying
                <b>which variables truly distinguish the groups</b>.
              </p>
                <p> The Cluster description function characterises both quantitative and
                    qualitative variables (typically the cluster-label variable) on the basis
                    of their relationships with all the other variables in the dataset. It
                    uses test statistics tailored to each scenario: the correlation coefficient
                    for two quantitative variables, the Chi-squared test of independence for two
                    qualitative variables, and the coefficient of determination when one variable
                    is quantitative and the other qualitative. This produces a thorough analysis
                    of the dataset and a clear picture of variable relationships.</p>

                    <p> At a more detailed level, Cluster description runs association tests for
                    qualitative variables. For two qualitative variables it analyses over- or
                    under-representation of one category within another with respect to the overall
                    population. When one variable is quantitative and the other qualitative, it
                    checks whether the mean of the quantitative variable within the subgroup
                    defined by a given category is higher or lower than the overall mean.</p>
              <h4>Methodological references</h4>
              <p>
                The core engine is <code>FactoMineR::catdes()</code> and <code>FactoMineR::condes()</code>,
                so the methodology builds on the <b>FactoMineR</b> package.
                Tables and the presentation logic are inspired by the <b>MEDA</b> module, from
                which this implementation derives, adapted for didactic use.
              </p>
            </div>
            </body>
            </html>"
        ))
      },

      .run = function() {
        # --- guard-rail dipendenze ---
        if (!requireNamespace("FactoMineR", quietly = TRUE)) {
          stop(.tr(
            it = "Il pacchetto 'FactoMineR' non è disponibile nel runtime di jamovi.\nL'analisi di caratterizzazione non può essere eseguita.",
            en = "Package 'FactoMineR' is not available in the jamovi runtime.\nThe cluster description analysis cannot be run."
          ), call. = FALSE)
        }

        if (
          is.null(self$options$vartochar) || is.null(self$options$descbyvar)
        ) {
          return()
        } else {
          # Guard: il ramo catdes (target categoriale) richiede ≥2 livelli;
          # senza questo FactoMineR esplode con "contrasts can be applied
          # only to factors with 2 or more levels".
          if (!is.numeric(self$dataProcessed[, 1])) {
            target <- self$dataProcessed[, 1]
            if (!is.factor(target)) target <- as.factor(target)
            n_liv <- nlevels(droplevels(target))
            if (n_liv < 2) {
              jmvcore::reject(.tr(
                it = "La variabile 'Cluster' deve avere almeno 2 livelli (categorie) per la caratterizzazione.",
                en = "The 'Cluster' variable must have at least 2 levels (categories) for the description analysis."
              ), code = "")
            }
          }

          if (is.numeric(self$dataProcessed[, 1]) == TRUE) {
            # Hide the output tables of the catdes
            self$results$chigroup$setVisible(visible = FALSE)
            self$results$categgroup$categquali$setVisible(visible = FALSE)
            self$results$qtvargroup$setVisible(visible = FALSE)
            self$results$qtgroup$qt$setVisible(visible = FALSE)

            if (identical(names(self$condesResult), "call")) {
              return()
            }

            if (any(grepl("quanti", names(self$condesResult))) == TRUE) {
              private$.printCondesCorTable()
            } else {
              self$results$qtgroup$qtcor$setVisible(visible = FALSE)
            }

            if (any(grepl("quali", names(self$condesResult))) == TRUE) {
              private$.printCondesR2Table()
            } else {
              self$results$categgroup$qualir2$setVisible(visible = FALSE)
            }

            if (any(grepl("category", names(self$condesResult))) == TRUE) {
              private$.printCondesCategTable()
            } else {
              self$results$categgroup$categquanti$setVisible(visible = FALSE)
            }
          } else {
            # Hide the output tables of the condes
            self$results$categgroup$categquanti$setVisible(visible = FALSE)
            self$results$qtgroup$qtcor$setVisible(visible = FALSE)
            self$results$categgroup$qualir2$setVisible(visible = FALSE)

            if (identical(names(self$catdesResult), "call")) {
              return()
            }

            if (any(grepl("test.chi2", names(self$catdesResult))) == TRUE) {
              private$.chiTable()
            } else {
              self$results$chigroup$setVisible(visible = FALSE)
            }

            if (any(grepl("category", names(self$catdesResult))) == TRUE) {
              private$.categoryTable()
            } else {
              self$results$categgroup$setVisible(visible = FALSE)
            }

            if (any(grepl("quanti.var", names(self$catdesResult))) == TRUE) {
              private$.qtvarTable()
            } else {
              self$results$qtvargroup$setVisible(visible = FALSE)
            }

            # Match esatto: grepl("quanti", ...) intercetterebbe anche
            # "quanti.var", presente pure quando il componente per-cluster
            # "quanti" non esiste (Eta² significativo ma nessun v-test).
            if ("quanti" %in% names(self$catdesResult)) {
              private$.qtTable()
            } else {
              self$results$qtgroup$setVisible(visible = FALSE)
            }
          }
        }
      },

      #Fonction

      .getcatdesResult = function() {
        threshold = self$options$threshold / 100
        r <- FactoMineR::catdes(
          self$dataProcessed,
          num.var = 1,
          proba = threshold
        )

        private$.catdesResult <- r
        return(private$.catdesResult)
      },

      .getcondesResult = function() {
        threshold = self$options$threshold / 100
        r <- FactoMineR::condes(
          self$dataProcessed,
          num.var = 1,
          proba = threshold
        )

        private$.condesResult <- r
        return(private$.condesResult)
      },

      # Helper: unifica i risultati per-livello (res[[component]][[i]]) in un'unica
      # tabella long con colonne Level/Category. Gestisce i casi: nessun livello
      # significativo, un solo livello, più livelli.
      .flattenCatdesByLevel = function(component) {
        res <- self$catdesResult
        comp <- res[[component]]
        if (is.null(comp)) return(NULL)
        # FactoMineR::catdes applica droplevels() internamente: la lista
        # può contenere meno elementi dei livelli dichiarati del fattore
        # (es. livello svuotato da un filtro jamovi). Iteriamo sui NOMI
        # della lista — i livelli effettivamente presenti — mai per
        # posizione, altrimenti "subscript out of bounds"/disallineamenti.
        lev_names <- names(comp)
        if (is.null(lev_names)) lev_names <- as.character(seq_along(comp))
        sig <- lev_names[vapply(comp, function(x) !is.null(dim(x)), logical(1))]
        if (length(sig) == 0) return(NULL)

        do.call(rbind, lapply(sig, function(nm) {
          tab <- comp[[nm]]
          data.frame(
            Level = rep(nm, nrow(tab)),
            Category = rownames(tab),
            tab,
            row.names = NULL,
            stringsAsFactors = FALSE,
            check.names = FALSE
          )
        }))
      },

      .getcatdesCategoryResult = function() {
        private$.catdesCategoryResult <- private$.flattenCatdesByLevel("category")
        return(private$.catdesCategoryResult)
      },

      .getcatdesCategoryQuantiResult = function() {
        private$.catdesCategoryQuantiResult <- private$.flattenCatdesByLevel("quanti")
        return(private$.catdesCategoryQuantiResult)
      },

      ### Table populating functions ----
      # Pattern: tutte le tabelle vengono popolate con un singolo addRow per riga,
      # passando l'intera lista di valori. Evita il doppio passaggio addRow+setRow
      # presente nella versione precedente.

      .chiTable = function() {
        tab <- self$catdesResult[["test.chi2"]]
        if (is.null(tab) || nrow(tab) == 0) return()
        for (i in seq_len(nrow(tab))) {
          self$results$chigroup$chi$addRow(
            rowKey = i,
            values = list(
              varchi = as.character(rownames(tab)[i]),
              chipv = tab[i, 1],
              df = tab[i, 2]
            )
          )
        }
      },

      .categoryTable = function() {
        tab <- self$catdesCategoryResult
        # NULL quando nessuna categoria supera la soglia: senza guard,
        # nrow(NULL) manda in errore seq_len(). Meglio una nota esplicita
        # di una tabella vuota senza spiegazioni.
        if (is.null(tab) || nrow(tab) == 0) {
          self$results$categgroup$categquali$setNote("empty", .tr(
            it = "Nessuna categoria risulta significativa alla soglia scelta.",
            en = "No category is significant at the chosen threshold."
          ))
          return()
        }
        for (i in seq_len(nrow(tab))) {
          self$results$categgroup$categquali$addRow(
            rowKey = i,
            values = list(
              varcateg = as.character(tab[i, 1]),
              vardesccateg = as.character(tab[i, 2]),
              clamod = tab[i, 3],
              modcla = tab[i, 4],
              global = tab[i, 5],
              categpv = tab[i, 6],
              vtest = tab[i, 7]
            )
          )
        }
      },

      .printCondesCategTable = function() {
        tab <- self$condesResult$category
        if (is.null(tab) || nrow(tab) == 0) return()
        splitnames <- strsplit(rownames(tab), "=")
        for (i in seq_len(nrow(tab))) {
          self$results$categgroup$categquanti$addRow(
            rowKey = i,
            values = list(
              varcateg = splitnames[[i]][1],
              vardesccateg = splitnames[[i]][2],
              estimate = tab[i, 1],
              categpv = tab[i, 2]
            )
          )
        }
      },

      .printCondesCorTable = function() {
        tab <- self$condesResult$quanti
        if (is.null(tab) || nrow(tab) == 0) return()
        for (i in seq_len(nrow(tab))) {
          self$results$qtgroup$qtcor$addRow(
            rowKey = i,
            values = list(
              varcor = rownames(tab)[i],
              cor = tab[i, 1],
              corpvalue = tab[i, 2]
            )
          )
        }
      },

      .printCondesR2Table = function() {
        tab <- self$condesResult$quali
        if (is.null(tab) || nrow(tab) == 0) return()
        for (i in seq_len(nrow(tab))) {
          self$results$categgroup$qualir2$addRow(
            rowKey = i,
            values = list(
              varr2 = rownames(tab)[i],
              r2 = tab[i, 1],
              r2pvalue = tab[i, 2]
            )
          )
        }
      },

      .qtvarTable = function() {
        tab <- self$catdesResult$quanti.var
        if (is.null(tab) || nrow(tab) == 0) return()
        for (i in seq_len(nrow(tab))) {
          self$results$qtvargroup$qtvar$addRow(
            rowKey = i,
            values = list(
              varqtvar = as.character(rownames(tab)[i]),
              scc = tab[i, 1],
              qtvarpv = tab[i, 2]
            )
          )
        }
      },

      .qtTable = function() {
        tabqt <- self$catdesCategoryQuantiResult
        # NULL quando l'Eta² globale è significativo ma nessun v-test
        # per-cluster lo è: FactoMineR crea res$quanti con soli NULL.
        if (is.null(tabqt) || nrow(tabqt) == 0) {
          self$results$qtgroup$qt$setNote("empty", .tr(
            it = "Nessun v-test per singolo cluster risulta significativo alla soglia scelta.",
            en = "No per-cluster v-test is significant at the chosen threshold."
          ))
          return()
        }
        for (i in seq_len(nrow(tabqt))) {
          self$results$qtgroup$qt$addRow(
            rowKey = i,
            values = list(
              varqt = as.character(tabqt[i, 1]),
              vardescqt = as.character(tabqt[i, 2]),
              vtestqt = tabqt[i, 3],
              meancateg = tabqt[i, 4],
              overallmean = tabqt[i, 5],
              sdcateg = tabqt[i, 6],
              overallsd = tabqt[i, 7],
              qtpv = tabqt[i, 8]
            )
          )
        }
      },

      .buildData = function() {
        # Forziamo data.frame "base" (non tibble) per garantire che [, 1]
        # restituisca un vettore. Versioni recenti di jamovi possono passare
        # i dati come tibble, dove [, 1] ritorna ancora una tibble 1-colonna.
        raw <- as.data.frame(self$data, stringsAsFactors = FALSE)
        target_name <- self$options$vartochar
        desc_names <- self$options$descbyvar

        data1 <- raw[, target_name, drop = FALSE]
        colnames(data1) <- target_name
        # Un target character (possibile dall'interfaccia R) va forzato a
        # fattore — levels() su un character restituisce NULL — e i
        # livelli inutilizzati vanno eliminati per allinearsi al
        # droplevels() interno di FactoMineR.
        if (!is.numeric(data1[[1]]))
          data1[[1]] <- droplevels(as.factor(data1[[1]]))
        data2 <- raw[, desc_names, drop = FALSE]
        colnames(data2) <- desc_names

        out <- cbind(data1, data2)
        out
      }
    )
  )
}
