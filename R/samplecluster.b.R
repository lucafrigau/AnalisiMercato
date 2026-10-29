# This file is a generated template, your changes will not be overwritten

sampleclusterClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "sampleclusterClass",
    inherit = sampleclusterBase,
    private = list(

      .init = function() {
        self$results$instructions$setContent(.tr(
          it = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Campionamento a grappoli</h3>
              <p>
                La popolazione è suddivisa in M grappoli mutuamente esclusivi
                ed esaustivi (es. città, scuole, quartieri). La procedura:
                <ol>
                  <li>Si estrae un campione casuale semplice di n_g grappoli
                  (senza reinserimento) tra gli M totali.</li>
                  <li><b>Tutte</b> le unità appartenenti ai grappoli estratti
                  entrano nel campione.</li>
                </ol>
              </p>
              <p>
                Vantaggi: costi e tempi ridotti rispetto al casuale semplice
                quando le unità sono geograficamente disperse. Svantaggi:
                tendenzialmente maggiore varianza dello stimatore se le
                unità all'interno dei grappoli sono simili tra loro
                (coefficiente di correlazione intragrappoli ρ > 0).
              </p>
              <p>
                Differenza chiave rispetto allo stratificato: nello
                stratificato si estrae <i>dentro</i> ogni strato; nel grappoli
                si estraggono i grappoli <i>interi</i>.
              </p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Cluster sampling</h3>
              <p>
                The population is partitioned into M mutually exclusive and
                exhaustive clusters (e.g., cities, schools, neighbourhoods).
                Procedure:
                <ol>
                  <li>A simple random sample of n_g clusters is drawn (without
                  replacement) from the M total clusters.</li>
                  <li><b>All</b> units belonging to the selected clusters
                  enter the sample.</li>
                </ol>
              </p>
              <p>
                Advantages: lower costs and shorter fieldwork compared to
                simple random sampling when units are geographically dispersed.
                Drawbacks: typically larger estimator variance if units within
                clusters are similar (positive intra-cluster correlation ρ).
              </p>
              <p>
                Key difference vs stratified sampling: stratified draws
                <i>within</i> each stratum; cluster sampling draws <i>whole
                clusters</i>.
              </p>
            </div>
            </body>
            </html>"
        ))
      },

      .run = function() {
        if (is.null(self$data)) return()
        if (is.null(self$options$cluster_var)) return()

        dati <- self$data
        N <- nrow(dati)
        if (N < 2) {
          jmvcore::reject(.tr(
            it = "Servono almeno 2 osservazioni per estrarre un campione.",
            en = "At least 2 observations are needed to draw a sample."
          ), code = "")
        }

        # Variabile grappolo
        cl_name <- self$options$cluster_var
        clus <- as.factor(dati[[cl_name]])
        keep <- !is.na(clus)
        if (sum(keep) < 2) {
          jmvcore::reject(.tr(
            it = "Tutte (o quasi) le osservazioni hanno grappolo mancante.",
            en = "All (or nearly all) observations have a missing cluster value."
          ), code = "")
        }

        # Lista dei grappoli (con dimensioni)
        clus_clean <- droplevels(clus[keep])
        lev <- levels(clus_clean)
        M <- length(lev)
        if (M < 2) {
          jmvcore::reject(.tr(
            it = "Servono almeno 2 grappoli distinti.",
            en = "At least 2 distinct clusters are required."
          ), code = "")
        }

        # n_g richiesti
        size_mode <- self$options$size_mode
        if (size_mode == "ng") {
          ng_req <- self$options$ng
        } else {
          fg <- self$options$fg
          if (is.null(fg) || !is.finite(fg) || fg <= 0) {
            jmvcore::reject(.tr(
              it = "La frazione di grappoli deve essere strettamente positiva.",
              en = "The cluster fraction must be strictly positive."
            ), code = "")
          }
          ng_req <- max(1L, round(M * fg))
        }
        if (ng_req > M) {
          jmvcore::reject(
            sprintf(.tr(
              it = "Il numero di grappoli richiesti (%d) eccede i grappoli disponibili (%d).",
              en = "The number of requested clusters (%d) exceeds the available clusters (%d)."
            ), ng_req, M),
            code = ""
          )
        }

        # Seed e estrazione casuale semplice dei grappoli (senza reinserimento)
        seed <- self$options$seed
        use_seed <- !is.null(seed) && is.finite(seed)
        if (use_seed) {
          # Salviamo e ripristiniamo lo stato del RNG globale: set.seed()
          # senza ripristino lascerebbe il generatore della sessione jamovi
          # in uno stato deterministico condiviso fra analisi diverse.
          if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
            old_seed <- get(".Random.seed", envir = globalenv())
            on.exit(assign(".Random.seed", old_seed, envir = globalenv()),
                    add = TRUE)
          } else {
            # Se il RNG non era ancora stato inizializzato, set.seed()
            # crea .Random.seed: per lasciare la sessione esattamente
            # come l'abbiamo trovata va rimosso, non ripristinato.
            on.exit(suppressWarnings(rm(".Random.seed", envir = globalenv())),
                    add = TRUE)
          }
          set.seed(as.integer(seed))
        }
        chosen_lev <- sample(lev, size = ng_req, replace = FALSE)

        # Indicatore: TUTTE le unità nei grappoli scelti entrano nel campione
        in_sample <- keep & (clus %in% chosen_lev)
        freq <- as.integer(in_sample)

        # Dimensione di ciascun grappolo estratto
        dim_chosen <- as.integer(table(clus[keep & (clus %in% chosen_lev)])[chosen_lev])

        # Riepilogo
        tab <- self$results$summary
        tab$setRow(
          rowNo = 1,
          values = list(
            N             = sum(keep),
            M             = M,
            ng_richiesto  = ng_req,
            ng_estratto   = length(chosen_lev),
            n_unita       = sum(freq),
            frazione_unita = sum(freq) / sum(keep),
            seed_used     = if (use_seed) as.integer(seed) else NA_integer_
          )
        )

        # Tabella grappoli estratti
        tab_cl <- self$results$clusters
        ord <- order(chosen_lev)  # ordine alfabetico per leggibilità
        for (i in seq_along(chosen_lev)) {
          tab_cl$addRow(
            rowKey = i,
            values = list(
              grappolo = chosen_lev[ord[i]],
              dim      = dim_chosen[ord[i]]
            )
          )
        }

        # Tabella unità estratte (se id_var)
        id_name <- self$options$id_var
        if (!is.null(id_name) && nzchar(id_name)) {
          id_values <- dati[[id_name]]
          pos_extracted <- which(in_sample)
          tab_ex <- self$results$extracted
          for (i in seq_along(pos_extracted)) {
            p <- pos_extracted[i]
            tab_ex$addRow(
              rowKey = i,
              values = list(
                ord      = i,
                grappolo = as.character(clus[p]),
                pos      = p,
                id_value = as.character(id_values[p])
              )
            )
          }
        }

        # Output: colonna iniettata
        self$results$out_freq$setTitle("in_GR")
        self$results$out_freq$setValues(freq)
        self$results$out_freq$setRowNums(rownames(dati))
      }
    )
  )
}
