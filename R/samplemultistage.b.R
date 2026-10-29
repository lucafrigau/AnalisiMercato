# This file is a generated template, your changes will not be overwritten

samplemultistageClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "samplemultistageClass",
    inherit = samplemultistageBase,
    private = list(

      .init = function() {
        self$results$instructions$setContent(.tr(
          it = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Campionamento a due stadi</h3>
              <p>
                La popolazione è suddivisa in M unità primarie (PSU =
                Primary Sampling Units), tipicamente città, scuole,
                quartieri. La procedura:
                <ol>
                  <li><b>Primo stadio</b>: si estrae un campione casuale
                  semplice di n_g PSU (senza reinserimento) tra le M
                  totali.</li>
                  <li><b>Secondo stadio</b>: in ogni PSU selezionata si
                  estrae un campione casuale semplice di unità (SSU =
                  Secondary Sampling Units).</li>
                </ol>
              </p>
              <p>
                Allocazione del secondo stadio:
                <ul>
                  <li><b>Numero fisso</b> b: stessa numerosità in ogni PSU
                  (disegno autoponderato se le PSU sono di pari ampiezza).</li>
                  <li><b>Frazione</b> f_b: ogni PSU contribuisce con una
                  frazione f_b della propria numerosità.</li>
                  <li><b>Tutte le unità</b>: si prendono tutte le SSU delle
                  PSU estratte — equivale al campionamento a grappoli.</li>
                </ul>
              </p>
              <p>
                Riduce i costi rispetto al casuale semplice (visite limitate
                a poche PSU) ma può perdere efficienza se le SSU all'interno
                della stessa PSU sono simili tra loro (ρ &gt; 0).
                Coerente con le slide 31-33.
              </p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Two-stage sampling</h3>
              <p>
                The population is partitioned into M Primary Sampling Units
                (PSUs), typically cities, schools or neighbourhoods. The
                procedure:
                <ol>
                  <li><b>First stage</b>: a simple random sample of n_g PSUs
                  is drawn (without replacement) from the M total PSUs.</li>
                  <li><b>Second stage</b>: within each selected PSU, a simple
                  random sample of Secondary Sampling Units (SSUs) is drawn.</li>
                </ol>
              </p>
              <p>
                Second-stage allocation:
                <ul>
                  <li><b>Fixed number</b> b: the same sample size in every PSU
                  (self-weighting design when PSUs are of equal size).</li>
                  <li><b>Fraction</b> f_b: each PSU contributes a fraction
                  f_b of its own size.</li>
                  <li><b>All units</b>: all SSUs of the selected PSUs are
                  taken — equivalent to cluster sampling.</li>
                </ul>
              </p>
              <p>
                Reduces costs relative to simple random sampling (fieldwork
                concentrated on a few PSUs) but may lose efficiency when SSUs
                within the same PSU are similar to each other (ρ &gt; 0).
              </p>
            </div>
            </body>
            </html>"
        ))
      },

      .run = function() {
        if (is.null(self$data)) return()
        if (is.null(self$options$psu_var)) return()

        dati <- self$data
        N <- nrow(dati)
        if (N < 2) {
          jmvcore::reject(.tr(
            it = "Servono almeno 2 osservazioni per estrarre un campione.",
            en = "At least 2 observations are needed to draw a sample."
          ), code = "")
        }

        # PSU
        psu_name <- self$options$psu_var
        psu <- as.factor(dati[[psu_name]])
        keep <- !is.na(psu)
        if (sum(keep) < 2) {
          jmvcore::reject(.tr(
            it = "Tutte (o quasi) le osservazioni hanno PSU mancante.",
            en = "All (or nearly all) observations have a missing PSU value."
          ), code = "")
        }

        psu_clean <- droplevels(psu[keep])
        lev <- levels(psu_clean)
        M <- length(lev)
        if (M < 2) {
          jmvcore::reject(.tr(
            it = "Servono almeno 2 PSU distinte.",
            en = "At least 2 distinct PSUs are required."
          ), code = "")
        }

        # n_g (primo stadio)
        psu_mode <- self$options$psu_mode
        if (psu_mode == "ng") {
          ng_req <- self$options$ng
        } else {
          fg <- self$options$fg
          if (is.null(fg) || !is.finite(fg) || fg <= 0) {
            jmvcore::reject(.tr(
              it = "La frazione di PSU deve essere strettamente positiva.",
              en = "The PSU fraction must be strictly positive."
            ), code = "")
          }
          ng_req <- max(1L, round(M * fg))
        }
        if (ng_req > M) {
          jmvcore::reject(
            sprintf(.tr(
              it = "Il numero di PSU richieste (%d) eccede quelle disponibili (%d).",
              en = "The number of requested PSUs (%d) exceeds the available PSUs (%d)."
            ), ng_req, M),
            code = ""
          )
        }

        # Seed
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

        # Estrazione PSU
        chosen_psu <- sample(lev, size = ng_req, replace = FALSE)

        # Secondo stadio: per ciascuna PSU estratta sub-campiona le SSU
        ssu_mode <- self$options$ssu_mode
        b <- self$options$b
        fb <- self$options$fb

        freq <- integer(N)
        sampled_pos <- integer(0)
        sampled_psu <- character(0)
        psu_dim <- integer(length(chosen_psu))
        psu_extracted_n <- integer(length(chosen_psu))

        all_idx <- seq_len(N)
        for (i in seq_along(chosen_psu)) {
          p <- chosen_psu[i]
          pool <- all_idx[keep & psu == p]
          nj <- length(pool)
          psu_dim[i] <- nj

          n_sec <- switch(
            ssu_mode,
            fixed = min(b, nj),
            frac  = max(1L, round(nj * fb)),
            all   = nj
          )

          if (n_sec > 0 && nj > 0) {
            chosen <- if (n_sec == nj) pool else sample(pool, size = n_sec, replace = FALSE)
            freq[chosen] <- 1L
            sampled_pos <- c(sampled_pos, chosen)
            sampled_psu <- c(sampled_psu, rep(p, length(chosen)))
            psu_extracted_n[i] <- n_sec
          }
        }

        # Riepilogo
        ssu_label <- switch(
          ssu_mode,
          # `min(b, nj)`: nelle PSU con meno di b unità vengono prese
          # tutte, quindi la dicitura corretta è "fino a b".
          fixed = sprintf(.tr(
            it = "fino a b = %d per PSU (nelle PSU più piccole tutte le unità)",
            en = "up to b = %d per PSU (in smaller PSUs, all units)"
          ), b),
          frac  = sprintf(.tr(it = "f_b = %g per PSU", en = "f_b = %g per PSU"), fb),
          all   = .tr(it = "Tutte le SSU (= grappoli)", en = "All SSUs (= cluster sampling)")
        )

        tab <- self$results$summary
        tab$setRow(
          rowNo = 1,
          values = list(
            N            = sum(keep),
            M            = M,
            ng_richiesto = ng_req,
            ng_estratto  = length(chosen_psu),
            ssu_label    = ssu_label,
            n_unita      = sum(freq),
            frazione     = sum(freq) / sum(keep),
            seed_used    = if (use_seed) as.integer(seed) else NA_integer_
          )
        )

        # Tabella PSU estratte
        tab_psu <- self$results$psu_table
        ord <- order(chosen_psu)
        for (i in seq_along(chosen_psu)) {
          j <- ord[i]
          tab_psu$addRow(
            rowKey = i,
            values = list(
              psu        = chosen_psu[j],
              dim_psu    = psu_dim[j],
              n_estratte = psu_extracted_n[j],
              f_psu      = if (psu_dim[j] > 0) psu_extracted_n[j] / psu_dim[j] else 0
            )
          )
        }

        # Tabella unità estratte (se id_var)
        id_name <- self$options$id_var
        if (!is.null(id_name) && nzchar(id_name)) {
          id_values <- dati[[id_name]]
          tab_ex <- self$results$extracted
          for (i in seq_along(sampled_pos)) {
            tab_ex$addRow(
              rowKey = i,
              values = list(
                ord      = i,
                psu      = sampled_psu[i],
                pos      = sampled_pos[i],
                id_value = as.character(id_values[sampled_pos[i]])
              )
            )
          }
        }

        # Output: colonna iniettata
        self$results$out_freq$setTitle("in_2STG")
        self$results$out_freq$setValues(freq)
        self$results$out_freq$setRowNums(rownames(dati))
      }
    )
  )
}
