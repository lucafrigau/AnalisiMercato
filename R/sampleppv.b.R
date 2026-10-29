# This file is a generated template, your changes will not be overwritten

sampleppvClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "sampleppvClass",
    inherit = sampleppvBase,
    private = list(

      .init = function() {
        self$results$instructions$setContent(.tr(
          it = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Campionamento con probabilità variabili (CPV)</h3>
              <p>
                Ciascuna unità della popolazione viene selezionata con
                probabilità proporzionale al proprio peso w_i (es. fatturato,
                numero di addetti, dimensione del comune). Le unità più
                grandi hanno più probabilità di entrare nel campione:
                particolarmente utile quando l'obiettivo è stimare un
                <i>totale</i> di popolazione anziché una media.
              </p>
              <p>
                Probabilità di <b>selezione</b> a ogni singola estrazione:
                <br>&emsp;p_i = w_i / Σ_i w_i
              </p>
              <p>
                Da non confondere con la probabilità di <b>inclusione</b>
                π_i, cioè la probabilità che l'unità entri nel campione:
                con reinserimento e n estrazioni indipendenti
                <br>&emsp;π_i = 1 − (1 − p_i)^n,
                <br>che tende a n·p_i solo quando p_i è molto piccola.
                Senza reinserimento le π_i non hanno forma chiusa
                elementare e non vengono riportate.
              </p>
              <p>
                Schema con reinserimento (default): la stessa unità può
                essere estratta più volte; lo stimatore corretto del totale
                è quello di Hansen-Hurwitz. Schema senza reinserimento:
                approssimazione πps via sample(..., replace = FALSE,
                prob = w); per stime non distorte servirebbe un disegno
                πps esatto (qui non implementato).
              </p>
              <p>
                La variabile di peso deve essere <b>finita e strettamente
                positiva</b> per tutte le unità: sono rifiutati i valori
                mancanti, non finiti, negativi o nulli. Le unità che non
                appartengono alla popolazione da campionare vanno tolte dal
                frame con un filtro, non azzerate.
              </p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Probability-proportional-to-size sampling (PPS)</h3>
              <p>
                Each unit in the population is selected with probability
                proportional to its weight w_i (e.g., turnover, number of
                employees, municipality size). Larger units are more likely
                to enter the sample: particularly useful when the goal is to
                estimate a population <i>total</i> rather than a mean.
              </p>
              <p>
                <b>Selection</b> probability at each single draw:
                <br>&emsp;p_i = w_i / Σ_i w_i
              </p>
              <p>
                Not to be confused with the <b>inclusion</b> probability
                π_i, i.e. the probability that the unit enters the
                sample: with replacement and n independent draws
                <br>&emsp;π_i = 1 − (1 − p_i)^n,
                <br>which approaches n·p_i only when p_i is very small.
                Without replacement the π_i have no elementary closed
                form and are not reported.
              </p>
              <p>
                With-replacement scheme (default): the same unit may be drawn
                multiple times; the unbiased estimator of the total is the
                Hansen-Hurwitz estimator. Without-replacement scheme:
                πps approximation via sample(..., replace = FALSE,
                prob = w); for unbiased estimation an exact πps design is
                needed (not implemented here).
              </p>
              <p>
                The weight variable must be <b>finite and strictly
                positive</b> for every unit: missing, non-finite, negative and
                zero values are rejected. Units that do not belong to the
                population being sampled must be filtered out of the frame,
                not given a zero weight.
              </p>
            </div>
            </body>
            </html>"
        ))
      },

      .run = function() {
        if (is.null(self$data)) return()
        if (is.null(self$options$weight_var)) return()

        dati <- self$data
        N <- nrow(dati)
        if (N < 2) {
          jmvcore::reject(.tr(
            it = "Servono almeno 2 osservazioni per estrarre un campione.",
            en = "At least 2 observations are needed to draw a sample."
          ), code = "")
        }

        # Variabile peso. Un peso mancante NON è una dichiarazione di
        # non campionabilità: è un dato che manca. Trattarlo in silenzio
        # come 0 escludeva l'unità dal disegno senza dirlo, quindi ora
        # blocca l'analisi come i pesi negativi o infiniti. Lo zero
        # esplicito resta ammesso (unità fuori dalla popolazione
        # obiettivo) ma viene dichiarato nel riepilogo.
        w_name <- self$options$weight_var
        pesi <- as.numeric(dati[[w_name]])
        # Nel frame usato dal CPV ogni unità deve avere 0 < w_i < Inf: un
        # peso nullo, mancante o non finito significa probabilità di
        # selezione nulla o indefinita per un'unità che è comunque nella
        # popolazione da campionare. Le unità estranee alla popolazione
        # obiettivo vanno tolte dal frame con un filtro, non azzerate.
        non_validi <- sum(!is.finite(pesi) | pesi <= 0)
        if (non_validi > 0) {
          jmvcore::reject(
            sprintf(.tr(
              it = "La variabile di peso deve assumere valori finiti e strettamente positivi per tutte le unità della popolazione obiettivo: %d unità non lo rispettano (valori mancanti, non finiti, negativi o nulli). Se alcune unità non appartengono alla popolazione da campionare, escluderle dal frame con un filtro prima di eseguire il CPV.",
              en = "The weight variable must be finite and strictly positive for every unit of the target population: %d units do not comply (missing, non-finite, negative or zero values). If some units do not belong to the population being sampled, filter them out of the frame before running PPS."
            ), non_validi),
            code = ""
          )
        }
        if (sum(pesi, na.rm = TRUE) <= 0) {
          jmvcore::reject(.tr(
            it = "La somma dei pesi è nulla o non valida.",
            en = "The sum of the weights is zero or invalid."
          ), code = "")
        }
        pesi_safe <- pesi

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

        replacement <- isTRUE(self$options$replacement)

        # Senza reinserimento serve almeno n unità con peso > 0
        n_eligible <- sum(pesi_safe > 0)
        if (!replacement && n_req > n_eligible) {
          jmvcore::reject(
            sprintf(.tr(
              it = "Senza reinserimento la numerosità richiesta (%d) supera il numero di unità campionabili (con peso > 0): %d.",
              en = "Without replacement the requested sample size (%d) exceeds the number of eligible units (with weight > 0): %d."
            ), n_req, n_eligible),
            code = ""
          )
        }

        # Seed e estrazione
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
        idx <- sample.int(N, size = n_req, replace = replacement, prob = pesi_safe)
        freq <- tabulate(idx, nbins = N)

        # p_i è la probabilità di selezione a UNA singola estrazione,
        # non la probabilità che l'unità entri nel campione.
        p_i <- pesi_safe / sum(pesi_safe)

        # Probabilità di inclusione π_i (prob. che l'unità compaia almeno
        # una volta nel campione di n estrazioni):
        #   - con reinserimento le estrazioni sono indipendenti e
        #     π_i = 1 − (1 − p_i)^n, in forma chiusa;
        #   - senza reinserimento sample(prob = w) realizza il
        #     campionamento sequenziale (successive sampling), le cui
        #     probabilità di inclusione NON sono n·p_i e non hanno forma
        #     chiusa elementare: le lasciamo indefinite anziché
        #     riportare un valore sbagliato.
        pi_incl <- if (replacement) 1 - (1 - p_i)^n_req else rep(NA_real_, N)

        # Riepilogo
        tab <- self$results$summary
        tab$setRow(
          rowNo = 1,
          values = list(
            N            = N,
            n_richiesto  = n_req,
            n_distinti   = sum(freq > 0),
            n_totale     = sum(freq),
            peso_totale  = sum(pesi_safe),
            schema       = if (replacement)
                            .tr(it = "Con reinserimento (Hansen-Hurwitz)",
                                en = "With replacement (Hansen-Hurwitz)")
                          else
                            .tr(it = "Senza reinserimento (πps approx.)",
                                en = "Without replacement (πps approx.)"),
            seed_used    = if (use_seed) as.integer(seed) else NA_integer_
          )
        )

        # Tabella unità estratte (se id_var)
        id_name <- self$options$id_var
        if (!is.null(id_name) && nzchar(id_name)) {
          id_values <- dati[[id_name]]
          extr_pos <- which(freq > 0)
          tab_ex <- self$results$extracted
          tab_ex$setNote("pi", if (replacement)
            .tr(
              it = "p_i è la probabilità di selezione a ogni singola estrazione; π_i = 1 − (1 − p_i)^n è la probabilità che l'unità entri nel campione in almeno una delle n estrazioni.",
              en = "p_i is the selection probability at each single draw; π_i = 1 − (1 − p_i)^n is the probability that the unit enters the sample in at least one of the n draws."
            )
          else
            .tr(
              it = "p_i è la probabilità di selezione alla prima estrazione. Senza reinserimento le probabilità di inclusione π_i non hanno forma chiusa elementare (campionamento sequenziale) e non vengono riportate: per un disegno πps esatto servirebbe un algoritmo dedicato.",
              en = "p_i is the selection probability at the first draw. Without replacement the inclusion probabilities π_i have no elementary closed form (successive sampling) and are not reported: an exact πps design would require a dedicated algorithm."
            ))
          for (i in seq_along(extr_pos)) {
            p_idx <- extr_pos[i]
            tab_ex$addRow(
              rowKey = i,
              values = list(
                pos      = p_idx,
                id_value = as.character(id_values[p_idx]),
                peso     = pesi_safe[p_idx],
                prob     = p_i[p_idx],
                pi_incl  = pi_incl[p_idx],
                freq     = freq[p_idx]
              )
            )
          }
        }

        # Output: colonna iniettata
        self$results$out_freq$setTitle("freq_CPV")
        self$results$out_freq$setValues(freq)
        self$results$out_freq$setRowNums(rownames(dati))
      }
    )
  )
}
