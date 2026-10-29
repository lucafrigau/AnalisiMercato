# This file is a generated template, your changes will not be overwritten

hcClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "hcClass",
    inherit = hcBase,
    private = list(
      .htmlwidget = NULL,

      # Base della segmentazione: le variabili di `vars` più le binarie di
      # presenza/assenza, che hanno una casella a parte perché con Gower
      # sono asimmetriche (la co-assenza non entra nel confronto).
      .base = function() unique(c(private$.nomi(self$options$vars),
                                  private$.nomi(self$options$asimm))),
      # un'opzione Variables vuota può arrivare come NULL o come list()
      .nomi = function(x) as.character(unlist(x)),

      .init = function() {
        # private$.htmlwidget <- HTMLWidget$new()

        if (is.null(self$data) || length(private$.base()) == 0) {
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
              <p> La Cluster Analysis Gerarchica consente di partizionare lo spazio delle osservazioni
              mediante cinque metodi di agglomerazione e calcolando la matrice delle distanze con sette
              criteri diversi.</p>

              <p> Le partizioni possono essere valutate attraverso il dendrogramma e quattro metriche
              specifiche:
              <ul>
              <li> R quadro (proporzione di devianza between spiegata) </li>
              <li> RMSSTD (Root-Mean-Square Standard Deviation) </li>
              <li> Delta G (dissomiglianza a passi successivi) </li>
              <li> L'Indice CH (Indice F di Calinski-Harabasz) </li>
              </ul>
              </p>

              <p> I valori delle metriche sono riportati in una tabella, e in un apposito grafico.</p>

              <p> Con la distanza di Gower le variabili binarie di presenza/assenza (0 = assenza,
              1 = presenza) vanno nella casella <i>Binarie di presenza/assenza</i>: quando due unità
              hanno entrambe 0 (co-assenza) la variabile non entra nel loro confronto, come
              nell'indice di Jaccard. Una variabile a due modalità entrambe informative, come il
              sesso, va invece nella base della segmentazione.</p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head>
            </head>
            <body>
            <div class='justified-text'>
              <p> Hierarchical Cluster Analysis partitions the observation space using
              five agglomeration methods and seven different distance metrics for the
              dissimilarity matrix.</p>

              <p> Partitions can be evaluated through the dendrogram and four metrics:
              <ul>
              <li> R-squared (proportion of between-group variance explained) </li>
              <li> RMSSTD (Root-Mean-Square Standard Deviation) </li>
              <li> Delta G (dissimilarity at successive merge steps) </li>
              <li> CH Index (Calinski–Harabasz pseudo-F index) </li>
              </ul>
              </p>

              <p> Metric values are shown both as a table and as dedicated plots.</p>

              <p> With the Gower distance, presence/absence binary variables (0 = absence,
              1 = presence) go in the <i>Presence/absence binaries</i> box: when two units both
              have 0 (co-absence) the variable is left out of their comparison, as in the Jaccard
              index. A two-category variable whose categories are both informative, such as sex,
              goes in the segmentation base instead.</p>
            </div>
            </body>
            </html>"
        ))

        # Visibilità dei grafici impostata SEMPRE in entrambi i sensi.
        # setVisible() è persistente e le checkbox non compaiono nei
        # clearWith delle immagini: impostando solo il ramo TRUE, un
        # grafico deselezionato (es. R² ON → OFF) resterebbe visibile con
        # il contenuto della precedente esecuzione. Stessa logica del
        # ripristino già adottato in pca.b.R.
        self$results$plot_dend$setVisible(isTRUE(self$options$dend))
        self$results$plot_r2$setVisible(isTRUE(self$options$r2))
        self$results$plot_rmsstd$setVisible(isTRUE(self$options$rmsstd))
        self$results$plot_deltaG$setVisible(isTRUE(self$options$deltaG))
        self$results$plot_ch_index$setVisible(isTRUE(self$options$ch_index))

        if (isTRUE(self$options$dend)) {
          self$results$plot_dend$setSize(
            self$options$width_dend,
            self$options$height_dend
          )
        }

        if (isTRUE(self$options$r2)) {
          self$results$plot_r2$setSize(
            self$options$width_r2,
            self$options$height_r2
          )
        }

        if (isTRUE(self$options$rmsstd)) {
          self$results$plot_rmsstd$setSize(
            self$options$width_rmsstd,
            self$options$height_rmsstd
          )
        }

        if (isTRUE(self$options$deltaG)) {
          self$results$plot_deltaG$setSize(
            self$options$width_deltaG,
            self$options$height_deltaG
          )
        }

        if (isTRUE(self$options$ch_index)) {
          self$results$plot_ch_index$setSize(
            self$options$width_ch,
            self$options$height_ch
          )
        }
      },

      .run = function() {
        if (!requireNamespace("ggplot2", quietly = TRUE)) {
          stop(.tr(
            it = "Dipendenza mancante: il pacchetto 'ggplot2' non è disponibile nel runtime di jamovi.",
            en = "Missing dependency: package 'ggplot2' is not available in the jamovi runtime."
          ), call. = FALSE)
        }

        # Heuristica: dati interpretabili come 0/1 (caso prevalente nei moduli di
        # marketing analytics con scale dummy/multi-response).
        is_binary_matrix <- function(M) {
          vals <- unique(as.vector(M))
          vals <- vals[!is.na(vals)]
          all(vals %in% c(0, 1))
        }

        # Distanza di Sokal-Michener / Simple Matching:
        # d(i,j) = quota di variabili con valore diverso fra le due osservazioni.
        # Per dati 0/1 si calcola in O(n^2 p) usando BLAS (tcrossprod), per dati
        # politomici (interi) si ricade sulla forma generale per colonna.
        create_distance_matrix_SokalMichener <- function(data) {
          data <- as.matrix(data)
          n <- nrow(data)
          p <- ncol(data)
          if (is_binary_matrix(data)) {
            # matches = (1,1) + (0,0); mismatch = p - matches
            matches <- tcrossprod(data) + tcrossprod(1 - data)
            mismatch <- p - matches
          } else {
            mismatch <- matrix(0, n, n)
            for (k in seq_len(p)) {
              col <- data[, k]
              mismatch <- mismatch + outer(col, col, FUN = "!=")
            }
          }
          stats::as.dist(mismatch / p)
        }

        # Distanza di Jaccard per variabili politomiche.
        # Codifica di riferimento: ogni coppia (variabile, livello) è una
        # feature binaria one-hot e lo "0" rappresenta l'assenza. Quindi
        #   |A|      = numero di variabili con valore ≠ 0 nella riga;
        #   |A ∩ B|  = numero di variabili con lo STESSO livello ≠ 0;
        #   |A ∪ B|  = |A| + |B| − |A ∩ B|.
        # Il punto delicato è l'unione: due individui con livelli DIVERSI
        # sulla stessa variabile attivano due feature one-hot distinte e
        # contribuiscono 2 all'unione, non 1. Esempio: V1 = A per
        # entrambi, V2 = B contro C → |A∩B| = 1, |A∪B| = 3 e
        # d = 1 − 1/3 = 0.667 (non 0.5).
        # Per dati 0/1 ogni variabile ha un solo livello "presente", le
        # due definizioni coincidono e l'intersezione si calcola in BLAS.
        create_distance_matrix_JaccardPoli <- function(data) {
          data <- as.matrix(data)
          n <- nrow(data)
          p <- ncol(data)
          # numero di feature one-hot attive per riga
          nz <- rowSums(data != 0)
          if (is_binary_matrix(data)) {
            inter <- tcrossprod(data)
          } else {
            inter <- matrix(0, n, n)
            for (k in seq_len(p)) {
              col <- data[, k]
              inter <- inter + outer(col, col, FUN = function(a, b) (a == b) & (a != 0))
            }
          }
          uni <- outer(nz, nz, FUN = "+") - inter
          d <- 1 - inter / uni
          # se entrambe le righe hanno tutti zeri, definiamo la distanza pari a 0
          d[!is.finite(d)] <- 0
          stats::as.dist(d)
        }

        # Calcolo delle metriche di partizionamento. Riceve in input i cluster
        # già calcolati e i precomputati invarianti (total_ss, overall_mean,
        # dati_mat, n) per evitare di ricalcolarli a ogni k.
        # Sfrutta l'identità TSS = BSS + WSS (Huygens):
        #   - centroidi via rowsum() (single C call, niente loop sui cluster);
        #   - between_ss come somma pesata di scarti dei centroidi;
        #   - within_ss = total_ss - between_ss (no doppio passaggio sui dati).
        calc_metrics <- function(clusters, dati_mat, n, total_ss, overall_mean) {
          k <- max(clusters)
          cluster_sizes <- as.integer(table(clusters))
          cluster_sums <- rowsum(dati_mat, group = clusters, reorder = TRUE)
          cluster_means <- cluster_sums / cluster_sizes

          diff_means <- sweep(cluster_means, 2, overall_mean, FUN = "-")
          between_ss <- sum(cluster_sizes * rowSums(diff_means^2))
          wss <- max(total_ss - between_ss, 0)  # protezione da roundoff

          r2 <- if (total_ss > 0) between_ss / total_ss else NA_real_
          # RMSSTD nella definizione pooled standard (SAS PROC CLUSTER,
          # Sharma 1996): la devianza within è divisa anche per il numero
          # di variabili p, non solo per (n - k).
          p <- ncol(dati_mat)
          rmsstd <- if (n > k && p > 0) sqrt(wss / (p * (n - k))) else NA_real_
          ch_index <- if (wss > 0 && n > k) {
            (between_ss / (k - 1)) / (wss / (n - k))
          } else NA_real_

          c(R2 = r2, RMSSTD = rmsstd, CH_Index = ch_index)
        }

        etichette_distanze <- setNames(
          c(
            "euclidean",
            "manhattan",
            "mahalanobis",
            "SokalMichener",
            "gower",
            "binary",
            "politomici"
          ),
          c(
            .tr(it = "Euclidea", en = "Euclidean"),
            "Manhattan",
            "Mahalanobis",
            "Sokal-Michener",
            "Gower",
            "Jaccard",
            .tr(it = "Jaccard (politomici)", en = "Jaccard (polytomous)")
          )
        )
        etichette_metodi <- setNames(
          c("ward.D2", "single", "complete", "average", "centroid"),
          c(
            "Ward",
            .tr(it = "Legame singolo", en = "Single linkage"),
            .tr(it = "Legame completo", en = "Complete linkage"),
            .tr(it = "Legame medio", en = "Average linkage"),
            .tr(it = "Centroide", en = "Centroid")
          )
        )

        # Analisi non ancora impostata: si esce in silenzio, come fa la
        # PCA. Un messaggio di errore rosso mentre l'utente sta ancora
        # trascinando le variabili nella casella è rumore, non
        # informazione: il pannello "Istruzioni" spiega già cosa serve.
        base <- private$.base()
        if (is.null(self$data) || length(base) < 2) return()
        asimm <- unique(private$.nomi(self$options$asimm))

        dis <- self$options$dis
        method <- self$options$method
        stdVars <- self$options$stdVars
        dend <- self$options$dend
        r2 <- self$options$r2
        rmsstd <- self$options$rmsstd
        deltaG <- self$options$deltaG
        ch_index <- self$options$ch_index
        n_clusters <- self$options$n_clusters

        dati <- self$data[, base, drop = FALSE]
        # I rownames di self$data veicolano gli indici di riga originali del
        # dataset jamovi (necessari a setRowNums quando ci sono filtri attivi):
        # vanno preservati nella ricostruzione del data.frame.
        # I TIPI vanno preservati: Gower lavora su dataset misti e il
        # Jaccard politomico su variabili categoriali, quindi una
        # conversione indiscriminata a numerico distruggerebbe proprio i
        # dati che quelle metriche sono fatte per trattare. La conversione
        # avviene più avanti, solo dove la metrica la richiede.
        dati <- as.data.frame(dati, row.names = rownames(dati),
                              stringsAsFactors = FALSE)
        for (nm in names(dati)) {
          if (is.character(dati[[nm]])) dati[[nm]] <- as.factor(dati[[nm]])
        }
        dati <- na.omit(dati)
        # droplevels dopo na.omit: livelli rimasti vuoti falserebbero
        # il conteggio delle modalità nelle distanze categoriche.
        dati <- droplevels(dati)

        # Quali variabili sono categoriali? Determina cosa è ammesso.
        is_cat <- vapply(dati, function(x) is.factor(x) || is.character(x),
                         logical(1))
        n_cat <- sum(is_cat)

        if (nrow(dati) < 3) {
          jmvcore::reject(.tr(
            it = "Il dataset contiene meno di 3 osservazioni valide (dopo la rimozione dei valori mancanti). Sono necessarie almeno 3 osservazioni per eseguire la cluster analysis.",
            en = "The dataset has fewer than 3 valid observations (after dropping missing values). At least 3 observations are required to run the cluster analysis."
          ), code = "")
        }

        # k = n produrrebbe una partizione degenere (ogni punto un cluster)
        # e rect.hclust richiede 2 <= k <= n-1: rifiutiamo k >= n.
        if (nrow(dati) <= n_clusters) {
          jmvcore::reject(
            sprintf(.tr(
              it = "Il numero di gruppi richiesto (%d) deve essere inferiore al numero di osservazioni valide (%d).",
              en = "The requested number of groups (%d) must be smaller than the number of valid observations (%d)."
            ), n_clusters, nrow(dati)),
            code = ""
          )
        }

        # Memory guard: la matrice delle distanze occupa ~n^2 * 8 byte.
        # Sopra ~10000 osservazioni la cluster gerarchica diventa impraticabile
        # in jamovi sia per la memoria sia per il costo O(n^3) di hclust.
        n_obs <- nrow(dati)
        mb_richiesti <- (n_obs^2 * 8) / 1024^2
        if (mb_richiesti > 1024) {
          jmvcore::reject(
            sprintf(.tr(
              it = "Il dataset contiene %d osservazioni: la matrice delle distanze richiederebbe circa %.0f MB. La cluster analysis gerarchica non è praticabile su questa scala — considera un sotto-campionamento o un metodo non gerarchico (es. k-means).",
              en = "The dataset has %d observations: the distance matrix would require about %.0f MB. Hierarchical cluster analysis is not feasible at this scale — consider sub-sampling or a non-hierarchical method (e.g., k-means)."
            ), n_obs, mb_richiesti),
            code = ""
          )
        } else if (mb_richiesti > 200) {
          warning(
            sprintf(.tr(
              it = "Il dataset contiene %d osservazioni: la matrice delle distanze richiederà circa %.0f MB. L'esecuzione potrebbe essere lenta.",
              en = "The dataset has %d observations: the distance matrix will require about %.0f MB. Execution may be slow."
            ), n_obs, mb_richiesti),
            call. = FALSE
          )
        }

        # --- compatibilità fra tipi delle variabili e metrica scelta ---
        # Le distanze quantitative su una variabile categoriale sono una
        # scelta metodologicamente discutibile, ma NON impossibile quando
        # le modalità sono codificate con numeri: il modulo la consente
        # (l'utente deve poter sbagliare e discuterne), limitandosi a
        # segnalarlo. È invece impossibile calcolarle su modalità
        # testuali (M/F): in quel caso si rifiuta indicando le
        # alternative appropriate.
        if (n_cat > 0 && dis %in% c("euclidean", "manhattan", "mahalanobis")) {
          lv_non_num <- names(dati)[is_cat][vapply(
            names(dati)[is_cat],
            function(nm) {
              num <- suppressWarnings(as.numeric(levels(dati[[nm]])))
              any(is.na(num))
            }, logical(1))]

          if (length(lv_non_num) > 0) {
            jmvcore::reject(
              sprintf(.tr(
                it = "La distanza scelta richiede valori numerici, ma le variabili categoriali %s hanno modalità testuali che non possono essere trattate come quantità. Per dati misti quantitativi + qualitativi usare la distanza di Gower; per soli dati categoriali Sokal-Michener o Jaccard (politomici).",
                en = "The chosen distance requires numeric values, but the categorical variables %s have textual categories that cannot be treated as quantities. For mixed quantitative + qualitative data use the Gower distance; for purely categorical data use Sokal-Michener or Jaccard (polytomous)."
              ), paste(lv_non_num, collapse = ", ")),
              code = ""
            )
          }

          # Modalità numeriche: si usano i valori dei livelli, avvisando
          # che i codici vengono trattati come quantità.
          for (nm in names(dati)[is_cat]) {
            dati[[nm]] <- as.numeric(levels(dati[[nm]]))[as.integer(dati[[nm]])]
          }
          self$results$izpis$setNote("num_su_cat", sprintf(.tr(
            it = "Le variabili categoriali %s sono trattate come quantitative: i codici delle modalità entrano nel calcolo come numeri, con le distanze che ne derivano (es. la modalità 3 dista dalla 1 il doppio della 2). Per variabili nominali sono più appropriate Gower, Sokal-Michener o Jaccard.",
            en = "The categorical variables %s are treated as quantitative: category codes enter the computation as numbers, with the resulting distances (e.g. category 3 is twice as far from 1 as from 2). For nominal variables Gower, Sokal-Michener or Jaccard are more appropriate."
          ), paste(names(dati)[is_cat], collapse = ", ")))
          # da qui in poi sono a tutti gli effetti quantitative
          is_cat <- vapply(dati, function(x) is.factor(x) || is.character(x),
                           logical(1))
          n_cat <- sum(is_cat)
        }

        # --- ricodifica dei fattori per le metriche di matching ---
        # SEMANTICA UNICA: il VALORE 0 significa sempre "assenza", per
        # qualunque metrica di matching e indipendentemente dal fatto che
        # la variabile sia memorizzata come numerica o come fattore.
        # Perciò un fattore i cui livelli sono etichette numeriche viene
        # convertito nei VALORI dei livelli (il livello "0" resta 0 =
        # assenza, esattamente come lo 0 numerico); un fattore con livelli
        # non numerici (M/F, Nord/Sud) non ha alcuna nozione di assenza e
        # usa i codici 1..L, dove ogni modalità è una "presenza".
        # Senza questa regola la stessa variabile dava distanze diverse a
        # seconda che fosse dichiarata continua o nominale.
        codifica_note <- character(0)
        fattore_in_valori <- function(f) {
          lv <- levels(f)
          num <- suppressWarnings(as.numeric(lv))
          if (!any(is.na(num))) num[as.integer(f)] else as.integer(f)
        }

        if (n_cat > 0 && dis %in% c("SokalMichener", "politomici")) {
          for (nm in names(dati)[is_cat]) {
            f <- dati[[nm]]
            lv <- levels(f)
            num <- suppressWarnings(as.numeric(lv))
            dati[[nm]] <- fattore_in_valori(f)
            if (any(is.na(num)))
              codifica_note <- c(codifica_note, sprintf(
                "%s: %s", nm,
                paste(sprintf("%s=%d", lv, seq_along(lv)), collapse = ", ")))
          }
        }

        if (dis == "binary") {
          # Il Jaccard binario passa da stats::dist(method = "binary"),
          # che interpreta QUALUNQUE valore diverso da zero come
          # "presenza": con i codici 1..L di un fattore ogni cella
          # risulterebbe presente e tutte le distanze verrebbero 0.
          # Serve quindi una codifica realmente 0/1.
          if (n_cat > 0) {
            for (nm in names(dati)[is_cat]) {
              f <- dati[[nm]]
              lv <- levels(f)
              num <- suppressWarnings(as.numeric(lv))
              if (!any(is.na(num)) && all(num %in% c(0, 1))) {
                # livelli già 0/1: si usano i valori
                dati[[nm]] <- num[as.integer(f)]
              } else if (nlevels(f) == 2) {
                # due modalità non numeriche: si adotta la convenzione
                # "primo livello = assenza", dichiarandola apertamente
                # perché il Jaccard è asimmetrico (le coppie 0-0 non
                # contano) e la scelta cambia il risultato.
                dati[[nm]] <- as.integer(f) - 1L
                codifica_note <- c(codifica_note, sprintf(
                  "%s: %s=0, %s=1", nm, lv[1], lv[2]))
              } else {
                jmvcore::reject(
                  sprintf(.tr(
                    it = "Il Jaccard binario richiede variabili a due modalità codificate 0/1 (0 = assenza), ma '%s' ha %d modalità (%s). Usare il Jaccard (politomici), che gestisce più modalità, oppure ricodificare la variabile in 0/1.",
                    en = "The binary Jaccard requires two-category variables coded 0/1 (0 = absence), but '%s' has %d categories (%s). Use the polytomous Jaccard, which handles several categories, or recode the variable to 0/1."
                  ), nm, nlevels(f), paste(lv, collapse = ", ")),
                  code = ""
                )
              }
            }
          }
          # Anche i valori numerici devono essere 0/1: con altri valori
          # dist(binary) calcolerebbe in silenzio qualcosa di diverso da
          # ciò che l'analisi dichiara.
          num_cols <- names(dati)[!is_cat]
          if (length(num_cols) > 0) {
            valori <- unique(as.vector(as.matrix(dati[, num_cols, drop = FALSE])))
            valori <- valori[!is.na(valori)]
            if (!all(valori %in% c(0, 1))) {
              jmvcore::reject(.tr(
                it = "Il Jaccard binario è definito su dati 0/1 (0 = assenza, 1 = presenza), ma le variabili quantitative selezionate contengono altri valori. Ricodificare in 0/1 oppure usare il Jaccard (politomici), che ammette più modalità.",
                en = "The binary Jaccard is defined on 0/1 data (0 = absence, 1 = presence), but the selected quantitative variables contain other values. Recode to 0/1 or use the polytomous Jaccard, which allows several categories."
              ), code = "")
            }
          }
        }

        # Sokal-Michener si generalizza al Simple Matching su dati
        # politomici: nessun vincolo 0/1, solo una nota informativa.
        if (dis == "SokalMichener") {
          valori <- unique(as.vector(as.matrix(dati)))
          valori <- valori[!is.na(valori)]
          if (!all(valori %in% c(0, 1))) {
            self$results$izpis$setNote("sm", .tr(
              it = "I dati non sono binari 0/1: la distanza è calcolata come Simple Matching (quota di variabili con modalità diversa), generalizzazione naturale di Sokal-Michener ai dati politomici.",
              en = "The data are not binary 0/1: the distance is computed as Simple Matching (share of variables with differing categories), the natural generalisation of Sokal-Michener to polytomous data."
            ))
          }
        }

        # --- binarie di presenza/assenza ---
        # Nel coefficiente di Gower una variabile di presenza/assenza è
        # asimmetrica: la co-presenza (1-1) è un accordo, la discordanza
        # (1-0) un disaccordo e la co-assenza (0-0) non entra nel
        # confronto (peso 0), come nell'indice di Jaccard. daisy() la
        # tratta così solo se è codificata 0/1 e dichiarata in type$asymm.
        if (dis == "gower" && length(asimm) > 0) {
          for (nm in asimm) {
            v <- dati[[nm]]
            if (is.factor(v)) {
              lv <- levels(v)
              num <- suppressWarnings(as.numeric(lv))
              if (!any(is.na(num)) && all(num %in% c(0, 1))) {
                dati[[nm]] <- num[as.integer(v)]
              } else if (any(is.na(num)) && nlevels(v) <= 2) {
                # modalità testuali: il primo livello è l'assenza, come
                # nel Jaccard binario, e la scelta è dichiarata in nota
                dati[[nm]] <- as.integer(v) - 1L
                codifica_note <- c(codifica_note, sprintf(
                  "%s: %s", nm,
                  paste(sprintf("%s=%d", lv, seq_along(lv) - 1L), collapse = ", ")))
              } else {
                jmvcore::reject(
                  sprintf(.tr(
                    it = "Le binarie di presenza/assenza devono avere due modalità codificate 0/1 (0 = assenza, 1 = presenza), ma '%s' ha le modalità %s. Spostare la variabile nella base della segmentazione oppure ricodificarla in 0/1.",
                    en = "Presence/absence binaries must have two categories coded 0/1 (0 = absence, 1 = presence), but '%s' has the categories %s. Move the variable to the segmentation base or recode it to 0/1."
                  ), nm, paste(lv, collapse = ", ")),
                  code = ""
                )
              }
            } else if (!all(v %in% c(0, 1))) {
              jmvcore::reject(
                sprintf(.tr(
                  it = "Le binarie di presenza/assenza devono essere codificate 0/1 (0 = assenza, 1 = presenza), ma '%s' contiene altri valori. Spostare la variabile nella base della segmentazione oppure ricodificarla in 0/1.",
                  en = "Presence/absence binaries must be coded 0/1 (0 = absence, 1 = presence), but '%s' contains other values. Move the variable to the segmentation base or recode it to 0/1."
                ), nm),
                code = ""
              )
            }
          }
          # una binaria costante non distingue le unità: daisy() la
          # lascia fuori dal calcolo, e la nota lo dice
          costanti <- asimm[vapply(asimm, function(nm) length(unique(dati[[nm]])) < 2,
                                   logical(1))]
          self$results$izpis$setNote("asimm", paste0(
            sprintf(.tr(
              it = "Binarie di presenza/assenza: %s. Quando due unità hanno entrambe 0 (co-assenza) la variabile non entra nel loro confronto, e la distanza di Gower è la media sulle variabili restanti.",
              en = "Presence/absence binaries: %s. When two units both have 0 (co-absence) the variable is left out of their comparison, and the Gower distance is the mean over the remaining variables."
            ), paste(asimm, collapse = ", ")),
            if (length(costanti) > 0) sprintf(.tr(
              it = " Restano fuori dal calcolo, perché hanno lo stesso valore in tutte le osservazioni: %s.",
              en = " Left out of the computation because they take the same value in every observation: %s."
            ), paste(costanti, collapse = ", ")) else ""))
        } else if (length(asimm) > 0) {
          self$results$izpis$setNote("asimm", sprintf(.tr(
            it = "Le binarie di presenza/assenza (%s) sono trattate in modo asimmetrico solo con la distanza di Gower: con la distanza scelta entrano nella base come le altre variabili.",
            en = "The presence/absence binaries (%s) are treated asymmetrically only with the Gower distance: with the chosen distance they enter the base like the other variables."
          ), paste(asimm, collapse = ", ")))
        }

        # Nota sulla codifica applicata ai fattori (trasparenza: con
        # Jaccard la scelta di quale modalità sia "assenza" cambia il
        # risultato).
        if (length(codifica_note) > 0) {
          self$results$izpis$setNote("codifica", sprintf(.tr(
            it = "Codifica applicata alle variabili categoriali — %s. Il valore 0 è trattato come assenza; i fattori con livelli numerici mantengono il valore del livello.",
            en = "Coding applied to the categorical variables — %s. The value 0 is treated as absence; factors with numeric levels keep their level value."
          ), paste(codifica_note, collapse = "; ")))
        }

        # distanza
        # La standardizzazione ha senso solo per distanze metriche su dati
        # quantitativi; per le distanze binarie/categoriche (Sokal-Michener,
        # Jaccard, Jaccard politomico) viene ignorata. Per Gower non ha
        # effetto per costruzione: daisy() normalizza sempre ogni variabile
        # per il proprio range, qualunque sia il valore di `stand`.
        numeric_distances <- c("euclidean", "manhattan", "mahalanobis")
        if (isTRUE(stdVars) && dis %in% numeric_distances) {
          # Una variabile costante ha sd = 0: scale() la trasformerebbe in
          # NaN, mandando in errore metriche e (per Mahalanobis) Cholesky.
          # Meglio un messaggio chiaro che un errore grezzo di R.
          sds <- vapply(as.data.frame(dati), stats::sd, numeric(1))
          costanti <- names(sds)[!is.finite(sds) | sds == 0]
          if (length(costanti) > 0) {
            jmvcore::reject(
              sprintf(.tr(
                it = "Le seguenti variabili sono costanti (deviazione standard nulla) sulle osservazioni valide e non possono essere standardizzate: %s. Rimuoverle dall'analisi oppure disattivare la standardizzazione.",
                en = "The following variables are constant (zero standard deviation) on the valid observations and cannot be standardized: %s. Remove them from the analysis or disable standardization."
              ), paste(costanti, collapse = ", ")),
              code = ""
            )
          }
          dati <- scale(dati)
        }

        if (dis == "gower") {
          # `stand` è irrilevante con metric = "gower" (range-scaling
          # sempre attivo): non lo passiamo per non suggerire il contrario.
          tipo <- if (length(asimm) > 0) list(asymm = asimm) else list()
          mat_dist <- withCallingHandlers(
            cluster::daisy(dati, metric = "gower", type = tipo),
            # l'avviso di daisy() su una binaria costante è sostituito
            # dalla nota della tabella, più chiara per chi usa il modulo
            warning = function(w) {
              if (grepl("binar", conditionMessage(w)))
                invokeRestart("muffleWarning")
            }
          )
          # Due unità con co-assenza su tutte le variabili (base fatta di
          # sole binarie di presenza/assenza) non hanno alcun confronto
          # possibile e daisy() lascia NA: la distanza si pone a 0, come
          # nel Jaccard politomico per due righe tutte nulle.
          if (anyNA(mat_dist)) {
            mat_dist[is.na(mat_dist)] <- 0
            self$results$izpis$setNote("coassenza_totale", .tr(
              it = "Alcune coppie di unità hanno 0 su tutte le binarie di presenza/assenza e nessun'altra variabile da confrontare: la loro distanza di Gower non è definita ed è posta a 0, come nel Jaccard.",
              en = "Some pairs of units have 0 on every presence/absence binary and no other variable to compare: their Gower distance is undefined and is set to 0, as in the Jaccard."
            ))
          }
        } else if (dis == "SokalMichener") {
          mat_dist <- create_distance_matrix_SokalMichener(dati)
        } else if (dis == "politomici") {
          mat_dist <- create_distance_matrix_JaccardPoli(dati)
        } else if (dis == "mahalanobis") {
          # Distanza di Mahalanobis a coppie:
          #   d(x_i, x_j) = sqrt( (x_i - x_j)' S^{-1} (x_i - x_j) )
          # Si trasformano i dati con L (Cholesky di S^{-1}) in modo che la distanza
          # euclidea nello spazio trasformato coincida con quella di Mahalanobis.
          S <- stats::cov(dati)
          # Con covarianza singolare o quasi singolare (p >= n, variabili
          # collineari) l'inversa non esiste: regolarizzare in silenzio
          # produceva distanze dominate dalle direzioni degeneri, senza
          # che nulla lo segnalasse. Meglio fermarsi e dirlo.
          cond <- tryCatch(rcond(S), error = function(e) 0)
          if (!is.finite(cond) || cond < 1e-10) {
            jmvcore::reject(.tr(
              it = "La matrice di covarianza delle variabili scelte non è invertibile o è numericamente instabile, quindi la distanza di Mahalanobis non è calcolabile: succede quando le variabili sono (quasi) collineari o quando sono più numerose delle osservazioni. Ridurre il numero di variabili, eliminare le dipendenze lineari oppure scegliere un'altra distanza.",
              en = "The covariance matrix of the selected variables is not invertible or is numerically unstable, so the Mahalanobis distance cannot be computed: this happens when variables are (nearly) collinear or outnumber the observations. Reduce the number of variables, remove linear dependencies, or choose another distance."
            ), code = "")
          }
          S_inv <- chol2inv(chol(S))
          L <- chol(S_inv)
          mat_dist <- stats::dist(as.matrix(dati) %*% t(L))
        } else {
          mat_dist <- stats::dist(dati, method = dis)
        }

        # clustering
        # Il metodo del centroide è definito sulle distanze euclidee AL
        # QUADRATO (cfr. ?hclust): passiamo d² e riportiamo le altezze
        # sulla scala originale con la radice. Le inversioni restano
        # possibili (proprietà intrinseca del centroid linkage), ma ora
        # sono quelle "vere" della definizione, non artefatti di scala.
        if (method == "centroid") {
          klastri <- stats::hclust(
            d = jmvcore::toNumeric(mat_dist)^2,
            method = "centroid"
          )
          klastri$height <- sqrt(pmax(klastri$height, 0))
        } else {
          klastri <- stats::hclust(
            d = jmvcore::toNumeric(mat_dist),
            method = method
          )
        }

        # populate the table izpis
        table <- self$results$izpis
        table$setRow(
          rowNo = 1,
          values = list(
            var = ncol(dati),
            dist = names(etichette_distanze)[etichette_distanze == dis],
            method = names(etichette_metodi)[etichette_metodi == method]
          )
        )

        # populate the table Group membership
        table2 <- self$results$groups

        etichette <- cutree(klastri, k = n_clusters)

        tab <- as.data.frame(table(etichette))

        for (i in 1:nrow(tab)) {
          table2$addRow(
            rowKey = i,
            values = list(
              cluster = as.numeric(as.character(tab[i, 1])),
              freq = tab[i, 2]
            )
          )
        }

        #############################################
        # Cluster membership-------------

        m <- as.data.frame(etichette)
        mem <- m[, 1]

        # Permette all'utente di scegliere il nome della colonna che verrà
        # iniettata nel dataset jamovi. Fallback a "Cluster" se vuoto.
        out_name <- self$options$outputName
        if (is.null(out_name) || !nzchar(out_name)) out_name <- "Cluster"
        self$results$label_cluster$setTitle(out_name)

        self$results$label_cluster$setValues(mem)
        self$results$label_cluster$setRowNums(rownames(dati))
        #############################

        max_g <- min(c(16, nrow(dati))) - 1

        # Cutree singolo per tutti i k: ritorna una matrice n × (max_g - 1)
        k_seq <- 2:max_g
        cuts <- cutree(klastri, k = k_seq)
        if (length(k_seq) == 1) cuts <- matrix(cuts, ncol = 1)

        # R², RMSSTD e indice CH sono definiti sulla devianza (somme di
        # quadrati attorno ai centroidi) e richiedono quindi variabili
        # tutte quantitative: con una base mista (caso Gower) non sono
        # calcolabili. Delta G dipende solo dalle altezze di fusione del
        # dendrogramma ed è invece valido per qualunque metrica.
        metriche_ss <- (n_cat == 0)
        if (metriche_ss) {
          # Precomputazione invarianti rispetto a k
          dati_mat <- as.matrix(dati)
          n_dati <- nrow(dati_mat)
          col_means <- colMeans(dati_mat)
          total_ss <- sum((dati_mat - rep(col_means, each = n_dati))^2)

          metriche <- as.data.frame(t(vapply(
            seq_along(k_seq),
            function(j) calc_metrics(cuts[, j], dati_mat, n_dati, total_ss, col_means),
            numeric(3)
          )))
          names(metriche) <- c("r2", "rmsstd", "ch_index")
        } else {
          metriche <- data.frame(
            r2       = rep(NA_real_, length(k_seq)),
            rmsstd   = rep(NA_real_, length(k_seq)),
            ch_index = rep(NA_real_, length(k_seq))
          )
        }
        metriche$deltaG <- rev(tail(diff(klastri$height), max_g - 1))
        metriche$g <- k_seq

        table_metriche <- self$results$metriche
        if (!metriche_ss) {
          table_metriche$setNote("ss", .tr(
            it = "La base della segmentazione contiene variabili categoriali: R², RMSSTD e indice CH sono definiti sulla devianza rispetto ai centroidi e non sono calcolabili su dati non quantitativi. Resta disponibile Delta G, che dipende solo dalle altezze di fusione del dendrogramma.",
            en = "The segmentation base contains categorical variables: R², RMSSTD and the CH index are based on the deviance around centroids and cannot be computed on non-quantitative data. Delta G, which depends only on the merge heights of the dendrogram, remains available."
          ))
          # I grafici delle tre metriche non calcolabili resterebbero vuoti
          self$results$plot_r2$setVisible(FALSE)
          self$results$plot_rmsstd$setVisible(FALSE)
          self$results$plot_ch_index$setVisible(FALSE)
        }

        for (i in 1:nrow(metriche)) {
          table_metriche$addRow(
            rowKey = i,
            values = list(
              g = metriche[i, "g"],
              r2 = metriche[i, "r2"],
              rmsstd = metriche[i, "rmsstd"],
              ch_index = metriche[i, "ch_index"],
              deltaG = metriche[i, "deltaG"]
            )
          )
        }

        #providing plot_dend
        if (dend == TRUE) {
          image <- self$results$plot_dend
          image$setState(list(klastri, etichette))
        }

        #providing plot_r2
        if (r2 == TRUE && metriche_ss) {
          image1 <- self$results$plot_r2
          image1$setState(metriche)
        }

        #providing plot_rmsstd
        if (rmsstd == TRUE && metriche_ss) {
          image2 <- self$results$plot_rmsstd
          image2$setState(metriche)
        }

        #providing plot_deltaG
        if (deltaG == TRUE) {
          image3 <- self$results$plot_deltaG
          image3$setState(metriche)
        }

        #providing plot_ch_index
        if (ch_index == TRUE && metriche_ss) {
          image4 <- self$results$plot_ch_index
          image4$setState(metriche)
        }
      },

      .plot_dend = function(image, ...) {
        if ((length(private$.base()) < 2) || (self$options$dend == FALSE)) {
          return()
        }

        hc_obj <- image$state[[1]]
        etichette <- image$state[[2]]
        k <- self$options$n_clusters

        dend <- stats::as.dendrogram(hc_obj)
        # Rami colorati per cluster con dendextend; se non disponibile fallback
        # al plot base R per non far fallire l'analisi.
        if (requireNamespace("dendextend", quietly = TRUE)) {
          dend <- dendextend::color_branches(dend, k = k)
          dend <- dendextend::set(
            dend, "labels_cex", 0.6
          )
        }

        # Altezza di taglio che produce k cluster: media tra le altezze (k-1)
        # e k-esima dalla coda; per k = 1 non disegniamo la linea.
        heights <- sort(hc_obj$height, decreasing = TRUE)
        cut_h <- if (k >= 2 && length(heights) >= k - 1) {
          if (length(heights) >= k) {
            (heights[k - 1] + heights[k]) / 2
          } else {
            heights[k - 1] * 0.99
          }
        } else NA_real_

        op <- graphics::par(mar = c(5, 4, 1, 2) + 0.1)
        on.exit(graphics::par(op), add = TRUE)
        # Oltre ~100 foglie le etichette diventano illeggibili (e lente da
        # disegnare): le sopprimiamo, restano i rami colorati per cluster.
        leaflab_mode <- if (length(hc_obj$order) > 100) "none" else "perpendicular"
        plot(dend, ylab = .tr(it = "Distanza", en = "Distance"), main = NULL,
             cex = 0.6, leaflab = leaflab_mode)
        if (is.finite(cut_h)) {
          graphics::abline(h = cut_h, col = "#D62728", lty = 2, lwd = 1.2)
        }
        stats::rect.hclust(
          hc_obj,
          k = k,
          cluster = etichette,
          border = "darkgray"
        )

        TRUE
      },

      .plot_r2 = function(image1, ...) {
        if ((length(private$.base()) < 2) || (self$options$r2 == FALSE)) {
          return()
        }

        ggplot2::ggplot(
          image1$state[, c("r2", "g")],
          ggplot2::aes(x = g, y = r2)
        ) +
          ggplot2::geom_line() +
          ggplot2::ylab("R^2") +
          ggplot2::geom_point() +
          ggplot2::theme_bw()
      },

      .plot_rmsstd = function(image2, ...) {
        if ((length(private$.base()) < 2) || (self$options$rmsstd == FALSE)) {
          return()
        }

        ggplot2::ggplot(
          image2$state[, c("rmsstd", "g")],
          ggplot2::aes(x = g, y = rmsstd)
        ) +
          ggplot2::geom_line() +
          ggplot2::ylab("RMSSTD") +
          ggplot2::geom_point() +
          ggplot2::theme_bw()
      },

      .plot_deltaG = function(image3, ...) {
        if ((length(private$.base()) < 2) || (self$options$deltaG == FALSE)) {
          return()
        }

        ggplot2::ggplot(
          image3$state[, c("deltaG", "g")],
          ggplot2::aes(x = g, y = deltaG)
        ) +
          ggplot2::geom_line() +
          ggplot2::ylab("Delta G") +
          ggplot2::geom_point() +
          ggplot2::theme_bw()
      },

      .plot_ch_index = function(image4, ...) {
        if (
          (length(private$.base()) < 2) || (self$options$ch_index == FALSE)
        ) {
          return()
        }

        ggplot2::ggplot(
          image4$state[, c("ch_index", "g")],
          ggplot2::aes(x = g, y = ch_index)
        ) +
          ggplot2::geom_line() +
          ggplot2::ylab(.tr(it = "Indice CH", en = "CH index")) +
          ggplot2::geom_point() +
          ggplot2::theme_bw()
      }
    )
  )
}
