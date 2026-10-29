# This file is a generated template, your changes will not be overwritten

samplesystClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "samplesystClass",
    inherit = samplesystBase,
    private = list(

      .init = function() {
        self$results$instructions$setContent(.tr(
          it = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Campionamento sistematico</h3>
              <p>
                Procedura di estrazione:
                <ol>
                  <li>Le N unità della popolazione vengono ordinate (per ordine
                  del dataset o secondo la variabile di ordinamento scelta).</li>
                  <li>Si calcola l'<b>intervallo di campionamento</b> k = N/n,
                  che non deve essere intero.</li>
                  <li>Si estrae casualmente una partenza r nell'intervallo
                  (0, k] (unico numero casuale del disegno).</li>
                  <li>Le n unità del campione occupano le posizioni
                  ⌈r⌉, ⌈r+k⌉, ⌈r+2k⌉, …, ⌈r+(n−1)k⌉.</li>
                </ol>
              </p>
              <p>
                Con l'intervallo frazionario ogni unità della lista ha
                probabilità di inclusione <b>n/N</b>, anche quando N non è un
                multiplo di n: nessuna unità resta esclusa a priori dal
                disegno, e le unità estratte sono sempre esattamente n.
              </p>
              <p>
                L'efficienza del sistematico rispetto al casuale semplice dipende
                dall'<b>ordinamento</b> della popolazione (slide 25):
                <ul>
                  <li><b>Inferiore</b> se il carattere d'interesse ha un
                  andamento ciclico col periodo coincidente all'intervallo k.</li>
                  <li><b>Uguale</b> se le unità sono ordinate casualmente.</li>
                  <li><b>Superiore</b> se le unità sono ordinate monotonicamente
                  rispetto alla variabile di interesse.</li>
                </ul>
              </p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Systematic sampling</h3>
              <p>
                Sampling procedure:
                <ol>
                  <li>The N units in the population are ordered (by dataset
                  order or by the chosen sorting variable).</li>
                  <li>The <b>sampling interval</b> k = N/n is computed; it need
                  not be an integer.</li>
                  <li>A random start r is drawn in (0, k] (the only random
                  number of the design).</li>
                  <li>The n sample units sit at positions
                  ⌈r⌉, ⌈r+k⌉, ⌈r+2k⌉, …, ⌈r+(n−1)k⌉.</li>
                </ol>
              </p>
              <p>
                With a fractional interval every unit of the list has inclusion
                probability <b>n/N</b>, even when N is not a multiple of n: no
                unit is structurally excluded from the design, and exactly n
                units are always drawn.
              </p>
              <p>
                The efficiency of systematic sampling relative to simple
                random sampling depends on the population <b>ordering</b>:
                <ul>
                  <li><b>Worse</b> if the variable of interest follows a
                  cyclical pattern whose period equals the interval k.</li>
                  <li><b>Equal</b> if units are ordered randomly.</li>
                  <li><b>Better</b> if units are ordered monotonically with
                  respect to the variable of interest.</li>
                </ul>
              </p>
            </div>
            </body>
            </html>"
        ))
      },

      .run = function() {
        if (is.null(self$data)) return()

        dati <- self$data
        N <- nrow(dati)
        if (N < 2) {
          # Nessuna variabile selezionata su un dataset senza dati: si esce
          # in silenzio invece di mostrare un errore rosso, come nel
          # campionamento casuale semplice. Il messaggio resta quando
          # l'utente ha indicato la variabile identificativa o quella di
          # ordinamento. Con un dataset vero l'estrazione funziona anche
          # senza variabili, perché jamovi passa comunque tutte le righe.
          scelta <- function(v) !is.null(v) && nzchar(v)
          if (!scelta(self$options$id_var) && !scelta(self$options$sort_var))
            return()
          jmvcore::reject(.tr(
            it = "Servono almeno 2 osservazioni per estrarre un campione.",
            en = "At least 2 observations are needed to draw a sample."
          ), code = "")
        }

        # n richiesto
        size_mode <- self$options$size_mode
        if (size_mode == "n") {
          n_req <- self$options$n
        } else {
          f_target <- self$options$f
          if (is.null(f_target) || !is.finite(f_target) || f_target <= 0) {
            jmvcore::reject(.tr(
              it = "La frazione di campionamento deve essere strettamente positiva.",
              en = "The sampling fraction must be strictly positive."
            ), code = "")
          }
          n_req <- max(1L, round(N * f_target))
        }
        if (n_req > N) {
          jmvcore::reject(
            sprintf(.tr(
              it = "La numerosità richiesta (%d) eccede la popolazione (%d).",
              en = "The requested sample size (%d) exceeds the population (%d)."
            ), n_req, N),
            code = ""
          )
        }

        # Ordinamento opzionale
        sort_name <- self$options$sort_var
        order_idx <- seq_len(N)
        ordinato_per <- .tr(it = "Ordine originale del dataset",
                            en = "Original dataset order")
        if (!is.null(sort_name) && nzchar(sort_name)) {
          sort_vals <- dati[[sort_name]]
          order_idx <- order(sort_vals, na.last = TRUE)
          ordinato_per <- sort_name
        }

        # Intervallo di campionamento e partenza casuale
        k <- N / n_req
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
        # Sistematico a intervallo frazionario: k = N/n non deve essere
        # intero e la partenza r si estrae in (0, k]. Le posizioni sono
        # ceil(r + (j-1)k), j = 1..n.
        #
        # Proprietà, tutte verificate in test-sampling-systematic.R:
        #  - 1 <= ceil(r) e ceil(r + (n-1)k) <= ceil(n*k) = N, perché r <= k:
        #    le posizioni non escono mai dalla lista;
        #  - k = N/n >= 1 (n <= N), quindi ceil(x + k) > ceil(x): le n
        #    posizioni sono strettamente crescenti, cioè distinte;
        #  - l'unità in posizione i è estratta se e solo se r cade in uno
        #    degli intervalli (i-1-(j-1)k, i-(j-1)k], che sono traslati di k
        #    l'uno dall'altro: ridotti modulo k coprono una lunghezza
        #    complessiva pari a 1, quindi pi_i = 1/k = n/N per OGNI unità,
        #    anche quando N non è multiplo di n.
        r_start <- stats::runif(1L, min = 0, max = k)
        # runif() estrae in [0, k): lo 0 ha probabilità nulla ma non è
        # ammesso dal disegno (darebbe posizione 0), quindi si esclude.
        if (r_start <= 0) r_start <- .Machine$double.eps
        # La tolleranza protegge dall'arrotondamento in virgola mobile
        # quando r + (j-1)k cade (quasi) esattamente su un intero.
        positions_sorted <- as.integer(
          ceiling(r_start + k * (seq_len(n_req) - 1L) - 1e-9))
        positions_sorted <- pmin(pmax(positions_sorted, 1L), N)

        # Indici nello spazio originale del dataset
        positions_orig <- order_idx[positions_sorted]

        # Indicatore di campione 0/1
        freq <- integer(N)
        freq[positions_orig] <- 1L

        # Riepilogo
        tab <- self$results$summary
        tab$setRow(
          rowNo = 1,
          values = list(
            N            = N,
            n_richiesto  = n_req,
            n_estratto   = sum(freq),
            intervallo   = k,
            partenza     = r_start,
            ordinato_per = ordinato_per,
            seed_used    = if (use_seed) as.integer(seed) else NA_integer_
          )
        )

        # Copertura del frame: con l'intervallo frazionario la probabilità di
        # inclusione vale n/N per tutte le unità, anche quando N non è
        # multiplo di n. La nota lo dichiara sempre, così il caso "k non
        # intero" non sembra un'anomalia.
        tab$setNote("copertura", sprintf(.tr(
          it = paste("Intervallo di campionamento k = N/n = %.4f e partenza",
                     "casuale r = %.4f in (0, k]: le posizioni estratte sono",
                     "⌈r⌉, ⌈r+k⌉, …, ⌈r+(n−1)k⌉. Ogni unità della lista ha",
                     "probabilità di inclusione n/N, anche quando N non è un",
                     "multiplo di n."),
          en = paste("Sampling interval k = N/n = %.4f and random start",
                     "r = %.4f in (0, k]: the drawn positions are",
                     "⌈r⌉, ⌈r+k⌉, …, ⌈r+(n−1)k⌉. Every unit of the list has",
                     "inclusion probability n/N, even when N is not a multiple",
                     "of n.")
        ), k, r_start))

        # Tabella delle unità estratte (solo se id_var)
        id_name <- self$options$id_var
        if (!is.null(id_name) && nzchar(id_name)) {
          id_values <- dati[[id_name]]
          tab_ex <- self$results$extracted
          for (i in seq_along(positions_sorted)) {
            ps <- positions_sorted[i]
            po <- positions_orig[i]
            tab_ex$addRow(
              rowKey = i,
              values = list(
                ord      = i,
                pos      = ps,
                pos_orig = po,
                id_value = as.character(id_values[po])
              )
            )
          }
        }

        # Output: colonna iniettata (nome esplicito: in_SM = sistematico)
        self$results$out_freq$setTitle("in_SM")
        self$results$out_freq$setValues(freq)
        self$results$out_freq$setRowNums(rownames(dati))
      }
    )
  )
}
