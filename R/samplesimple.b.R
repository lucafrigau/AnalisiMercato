# This file is a generated template, your changes will not be overwritten

samplesimpleClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "samplesimpleClass",
    inherit = samplesimpleBase,
    private = list(

      .init = function() {
        self$results$instructions$setContent(.tr(
          it = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Campionamento casuale semplice</h3>
              <p>
                Estrae un campione casuale semplice dall'insieme di righe del
                dataset corrente, considerato come popolazione finita di
                dimensione N. Ogni unità ha la stessa probabilità di
                inclusione.
              </p>
              <p>
                Due schemi possibili:
                <ul>
                  <li><b>Senza reinserimento (SSR)</b>: ciascuna unità può
                  comparire al più una volta nel campione. Richiede n ≤ N.</li>
                  <li><b>Con reinserimento (SCR)</b>: la stessa unità può
                  essere estratta più volte; n può superare N.</li>
                </ul>
              </p>
              <p>
                L'output è una nuova colonna iniettata nel dataset che riporta,
                per ciascuna unità, la <b>frequenza di estrazione</b>
                (0 = non estratta, 1 = estratta una volta, ≥ 2 possibile solo
                in SCR). Il <b>seed</b> garantisce la riproducibilità: a
                parità di seed e parametri il campione estratto sarà sempre lo
                stesso.
              </p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Simple random sampling</h3>
              <p>
                Draws a simple random sample from the rows of the current
                dataset, treated as a finite population of size N. Every
                unit has the same inclusion probability.
              </p>
              <p>
                Two possible schemes:
                <ul>
                  <li><b>Without replacement (SRS-WOR)</b>: each unit appears
                  at most once in the sample. Requires n ≤ N.</li>
                  <li><b>With replacement (SRS-WR)</b>: the same unit can be
                  drawn multiple times; n may exceed N.</li>
                </ul>
              </p>
              <p>
                The output is a new column injected into the dataset reporting,
                for each unit, the <b>draw frequency</b> (0 = not drawn,
                1 = drawn once, ≥ 2 possible only under WR). The <b>seed</b>
                ensures reproducibility: with the same seed and parameters the
                drawn sample is always the same.
              </p>
            </div>
            </body>
            </html>"
        ))
      },

      .run = function() {
        if (is.null(self$data)) return()

        N <- nrow(self$data)
        if (N < 2) {
          # Nessuna variabile selezionata su un dataset senza dati (tipico
          # di un file nuovo, ancora vuoto): l'analisi non è ancora
          # impostata e si esce in silenzio, come fa la cluster analysis,
          # invece di mostrare un errore rosso. Il messaggio resta quando
          # l'utente ha indicato una variabile. Con un dataset vero
          # l'estrazione funziona anche senza variabili: jamovi passa
          # comunque tutte le righe e la variabile identificativa è
          # davvero opzionale.
          id_name <- self$options$id_var
          if (is.null(id_name) || !nzchar(id_name)) return()
          jmvcore::reject(.tr(
            it = "Servono almeno 2 osservazioni per estrarre un campione.",
            en = "At least 2 observations are needed to draw a sample."
          ), code = "")
        }

        replacement <- isTRUE(self$options$replacement)
        size_mode   <- self$options$size_mode

        # Determina n richiesto a partire dalla modalità scelta
        if (size_mode == "n") {
          n <- self$options$n
        } else {
          f_target <- self$options$f
          if (is.null(f_target) || !is.finite(f_target) || f_target <= 0) {
            jmvcore::reject(.tr(
              it = "La frazione di campionamento deve essere strettamente positiva.",
              en = "The sampling fraction must be strictly positive."
            ), code = "")
          }
          n <- max(1L, round(N * f_target))
        }

        if (!replacement && n > N) {
          jmvcore::reject(
            sprintf(.tr(
              it = "Senza reinserimento la numerosità del campione (%d) non può superare la popolazione (%d). Riduci n o passa a schema con reinserimento.",
              en = "Without replacement the sample size (%d) cannot exceed the population (%d). Reduce n or switch to with-replacement sampling."
            ), n, N),
            code = ""
          )
        }

        # Seed per riproducibilità
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

        # Estrazione
        idx <- sample.int(N, size = n, replace = replacement)
        freq <- tabulate(idx, nbins = N)

        # Riepilogo
        tab <- self$results$summary
        # Con reinserimento n/N non è una frazione di campionamento (la
        # quota di popolazione inclusa nel campione): può superare 1
        # perché conta le estrazioni, non le unità distinte.
        # Entrambi i rami sono espliciti: setTitle() è persistente, quindi
        # senza il ramo "else" passando da SCR a SSR resterebbe il titolo
        # del rapporto al posto della frazione di campionamento.
        if (replacement) {
          tab$getColumn("frazione")$setTitle(.tr(
            it = "Rapporto estrazioni/popolazione n/N",
            en = "Draws-to-population ratio n/N"
          ))
        } else {
          tab$getColumn("frazione")$setTitle(.tr(
            it = "Frazione f = n/N",
            en = "Sampling fraction f = n/N"
          ))
        }
        tab$setRow(
          rowNo = 1,
          values = list(
            N            = N,
            n_richiesto  = n,
            n_distinti   = sum(freq > 0),
            n_totale     = sum(freq),
            frazione     = n / N,
            schema       = if (replacement)
                            .tr(it = "Con reinserimento (SCR)",
                              en = "With replacement (SRSWR)")
                          else
                            .tr(it = "Senza reinserimento (SSR)",
                                en = "Without replacement (SRSWOR)"),
            seed_used    = if (use_seed) as.integer(seed) else NA_integer_
          )
        )

        # Tabella delle unità estratte (solo se l'utente ha indicato la variabile ID)
        id_name <- self$options$id_var
        if (!is.null(id_name) && nzchar(id_name)) {
          id_values <- self$data[[id_name]]
          extr_pos <- which(freq > 0)
          tab_ex <- self$results$extracted
          for (i in seq_along(extr_pos)) {
            pos_i <- extr_pos[i]
            tab_ex$addRow(
              rowKey = i,
              values = list(
                pos      = pos_i,
                id_value = as.character(id_values[pos_i]),
                freq     = freq[pos_i]
              )
            )
          }
        }

        # Output: colonna iniettata nel dataset.
        # Il nome della colonna riflette lo schema scelto (SCR/SSR) così che
        # l'utente capisca a colpo d'occhio da quale analisi è stata generata.
        out_name <- if (replacement) "freq_SCR" else "freq_SSR"
        self$results$out_freq$setTitle(out_name)
        self$results$out_freq$setValues(freq)
        self$results$out_freq$setRowNums(rownames(self$data))
      }
    )
  )
}
