# This file is a generated template, your changes will not be overwritten

samplestratClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "samplestratClass",
    inherit = samplestratBase,
    private = list(

      .init = function() {
        self$results$instructions$setContent(.tr(
          it = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Campionamento stratificato</h3>
              <p>
                La popolazione viene suddivisa in M strati sulla base di una
                variabile ausiliaria correlata al fenomeno di interesse.
                All'interno di ciascuno strato si estrae un campione casuale
                senza reinserimento. L'obiettivo è ridurre la varianza degli
                stimatori sfruttando l'omogeneità interna agli strati.
              </p>
              <p>
                Due metodi di allocazione della numerosità n fra strati:
                <ul>
                  <li><b>Proporzionale</b>: n_j = N_j · n/N. Nell'allocazione
                  <i>teorica</i> la frazione di campionamento è uguale in ogni
                  strato (f_j = f); poiché gli n_j devono essere interi, dopo
                  l'arrotondamento le frazioni effettivamente realizzate
                  possono differire leggermente fra strati. Coerente con la
                  slide 28.</li>
                  <li><b>Ottimale di Neyman</b>: n_j = n · (N_j · σ_j) /
                  Σ_j(N_j · σ_j). Alloca più unità agli strati più ampi
                  e/o più variabili rispetto alla variabile ausiliaria.
                  Coerente con la slide 30.</li>
                </ul>
              </p>
              <p>
                <b>Rappresentanza minima</b>: ogni strato non vuoto riceve
                almeno 2 unità (1 se in popolazione ne contiene una sola), così
                che nessuna unità abbia probabilità di inclusione nulla e la
                variabilità interna resti stimabile. Il vincolo interviene solo
                quando l'allocazione teorica lascerebbe uno strato sotto il
                minimo: quegli strati vengono portati al minimo, le unità
                restanti sono allocate fra gli altri con il criterio scelto e
                il risultato è dichiarato <i>vincolato</i>. Se n non basta a
                garantire i minimi, l'analisi si ferma e chiede di aumentare n
                o di accorpare gli strati più piccoli.
              </p>
              <p>
                La <b>variabile ausiliaria</b> è obbligatoria per il metodo
                ottimale (serve a stimare σ_j); ignorata per il proporzionale.
              </p>
              <p>
                <b>Più variabili di stratificazione</b>: se si selezionano
                più variabili, gli strati sono dati dall'<i>incrocio</i> (joint
                control) dei livelli effettivamente presenti nei dati
                (combinazioni vuote escluse). Esempio: Sesso (M, F) × Età
                (&lt;30, 30-50, &gt;50) → fino a 6 strati. Lo schema
                <i>marginale</i> (quote indipendenti sulle variabili senza
                incrocio) richiede iterative proportional fitting e non è
                implementato in questa versione.
              </p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Stratified sampling</h3>
              <p>
                The population is partitioned into M strata using an auxiliary
                variable correlated with the variable of interest. Within each
                stratum a simple random sample is drawn without replacement.
                The aim is to reduce estimator variance by leveraging the
                within-stratum homogeneity.
              </p>
              <p>
                Two allocation methods for the total sample size n across strata:
                <ul>
                  <li><b>Proportional</b>: n_j = N_j · n/N. In the
                  <i>theoretical</i> allocation the sampling fraction is
                  identical in every stratum (f_j = f); since the n_j must be
                  integers, after rounding the realised fractions may differ
                  slightly across strata.</li>
                  <li><b>Neyman optimal</b>: n_j = n · (N_j · σ_j) /
                  Σ_j(N_j · σ_j). More units are allocated to larger and/or
                  more variable strata (measured on the auxiliary variable).</li>
                </ul>
              </p>
              <p>
                <b>Minimum representation</b>: every non-empty stratum receives
                at least 2 units (1 if it holds a single unit in the
                population), so that no unit has zero inclusion probability and
                the within-stratum variability stays estimable. The constraint
                only kicks in when the theoretical allocation would leave a
                stratum below the minimum: those strata are raised to the
                minimum, the remaining units are allocated among the others
                with the chosen criterion, and the result is reported as
                <i>constrained</i>. If n cannot cover the minima the analysis
                stops and asks to increase n or to merge the smallest strata.
              </p>
              <p>
                The <b>auxiliary variable</b> is required for the optimal method
                (it is used to estimate σ_j); ignored under proportional
                allocation.
              </p>
              <p>
                <b>Multiple stratification variables</b>: if several variables
                are selected, strata are formed by the <i>cross</i> (joint
                control) of the levels actually present in the data (empty
                combinations are dropped). Example: Sex (M, F) × Age
                (&lt;30, 30-50, &gt;50) → up to 6 strata. The <i>marginal</i>
                scheme (independent quotas without crossing) requires iterative
                proportional fitting and is not implemented in this version.
              </p>
            </div>
            </body>
            </html>"
        ))
      },

      .run = function() {
        if (is.null(self$data)) return()
        strat_names <- self$options$strat_var
        if (is.null(strat_names) || length(strat_names) == 0) return()

        dati <- self$data
        N <- nrow(dati)
        if (N < 2) {
          jmvcore::reject(.tr(
            it = "Servono almeno 2 osservazioni per estrarre un campione.",
            en = "At least 2 observations are needed to draw a sample."
          ), code = "")
        }

        # Una o più variabili di stratificazione → factor incrociato.
        # Con n variabili gli strati sono il prodotto cartesiano dei livelli
        # effettivamente presenti (drop = TRUE elimina le combinazioni vuote).
        if (length(strat_names) == 1L) {
          strat <- as.factor(dati[[strat_names]])
        } else {
          factor_list <- lapply(strat_names, function(nm) as.factor(dati[[nm]]))
          names(factor_list) <- strat_names
          strat <- interaction(factor_list, drop = TRUE, sep = " × ")
        }

        # Rimuoviamo righe con strato NA (NA in qualsiasi variabile di strato)
        keep <- !is.na(strat)
        if (sum(keep) < 2) {
          jmvcore::reject(.tr(
            it = "Tutte (o quasi) le osservazioni hanno strato mancante (NA in almeno una variabile di stratificazione).",
            en = "All (or nearly all) observations have a missing stratum value (NA in at least one stratification variable)."
          ), code = "")
        }

        lev <- levels(droplevels(strat[keep]))
        M <- length(lev)
        if (M < 2) {
          jmvcore::reject(.tr(
            it = "Lo schema di stratificazione deve dare almeno 2 strati non vuoti.",
            en = "The stratification scheme must produce at least 2 non-empty strata."
          ), code = "")
        }

        # N_j per ogni strato (solo righe valide)
        Nj <- as.integer(table(strat[keep])[lev])
        N_eff <- sum(Nj)
        Wj <- Nj / N_eff

        # n totale richiesto
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
          n_req <- max(1L, round(N_eff * f_target))
        }
        if (n_req > N_eff) {
          jmvcore::reject(
            sprintf(.tr(
              it = "La numerosità richiesta (%d) eccede la popolazione effettiva (%d, escluse righe con strato NA).",
              en = "The requested sample size (%d) exceeds the effective population (%d, after dropping rows with NA strata)."
            ), n_req, N_eff),
            code = ""
          )
        }

        # Calcolo sigma_j (solo se metodo ottimale) e n_j
        method <- self$options$method
        sigma_j <- rep(NA_real_, M)
        if (method == "optimal") {
          aux_name <- self$options$aux_var
          if (is.null(aux_name)) {
            jmvcore::reject(.tr(
              it = "Il metodo ottimale richiede una variabile ausiliaria quantitativa.",
              en = "The optimal method requires a quantitative auxiliary variable."
            ), code = "")
          }
          aux <- as.numeric(dati[[aux_name]])
          # σ_j NON stimabile ≠ σ_j nulla. Con meno di due valori finiti
          # dell'ausiliaria non sappiamo nulla della variabilità dello
          # strato: porre σ_j = 0 gli assegnerebbe peso nullo e quindi
          # n_j = 0, escludendolo dal campione come se fosse omogeneo.
          # L'unico caso in cui la varianza è davvero nulla è lo strato
          # con una sola unità in popolazione (N_j = 1).
          non_stimabili <- character(0)
          for (j in seq_len(M)) {
            sub <- aux[keep & strat == lev[j]]
            sub <- sub[is.finite(sub)]
            if (length(sub) >= 2) {
              sigma_j[j] <- stats::sd(sub)
            } else if (Nj[j] <= 1) {
              # strato di una sola unità: variabilità interna nulla
              sigma_j[j] <- 0
            } else {
              sigma_j[j] <- NA_real_
              non_stimabili <- c(non_stimabili, lev[j])
            }
          }
          if (length(non_stimabili) > 0) {
            jmvcore::reject(
              sprintf(.tr(
                it = "L'allocazione ottimale di Neyman richiede di stimare la variabilità σ_j dentro ogni strato, ma negli strati %s la variabile ausiliaria ha meno di due valori validi: σ_j non è stimabile (il che è diverso dall'essere nulla). Completare i dati ausiliari in quegli strati, scegliere un'altra variabile ausiliaria, oppure usare l'allocazione proporzionale, che non richiede σ_j.",
                en = "Neyman optimal allocation requires estimating the within-stratum variability σ_j, but in strata %s the auxiliary variable has fewer than two valid values: σ_j cannot be estimated (which is not the same as being zero). Complete the auxiliary data in those strata, choose another auxiliary variable, or use proportional allocation, which does not require σ_j."
              ), paste(non_stimabili, collapse = ", ")),
              code = ""
            )
          }
          weights <- Nj * sigma_j
          if (sum(weights, na.rm = TRUE) <= 0) {
            jmvcore::reject(.tr(
              it = "La variabile ausiliaria ha varianza nulla in tutti gli strati: l'allocazione ottimale non è applicabile.",
              en = "The auxiliary variable has zero variance in every stratum: optimal allocation is not applicable."
            ), code = "")
          }
          pesi <- weights
        } else {
          # proporzionale: i pesi sono le ampiezze degli strati
          pesi <- Nj
        }

        # --- Allocazione della numerosità fra gli strati ---
        #
        # 1) Allocazione teorica (reale) con vincolo di capacità n_j ≤ N_j.
        #    Quando uno strato viene saturato, le unità che restano da
        #    collocare vanno ridistribuite fra gli strati NON saturi in
        #    proporzione ai LORO PESI teorici (N_j per l'allocazione
        #    proporzionale, N_j·σ_j per Neyman), non in base alla loro
        #    capacità residua: altrimenti l'allocazione effettiva non è
        #    più quella che l'analisi dichiara di applicare.
        alloca_reale <- function(n_tot, w, Nj) {
          M <- length(Nj)
          out <- rep(NA_real_, M)
          attivi <- rep(TRUE, M)
          residuo <- n_tot
          repeat {
            w_att <- ifelse(attivi, w, 0)
            if (!any(attivi) || residuo <= 0) break
            # pesi tutti nulli fra gli strati attivi: si ripiega su una
            # ripartizione uniforme, l'unica neutrale possibile
            if (sum(w_att) <= 0) w_att <- ifelse(attivi, 1, 0)
            target <- residuo * w_att / sum(w_att)
            satura <- attivi & (target > Nj)
            if (!any(satura)) {
              out[attivi] <- target[attivi]
              break
            }
            out[satura] <- Nj[satura]
            residuo <- residuo - sum(Nj[satura])
            attivi[satura] <- FALSE
          }
          out[is.na(out)] <- 0
          out
        }

        # 2) Arrotondamento con il METODO DEI RESTI MAGGIORI (Hamilton):
        #    si parte dalla parte intera e le unità mancanti vanno agli
        #    strati con la parte decimale più grande, cioè quelli più
        #    penalizzati dal troncamento. Ordinare per capacità residua
        #    (come faceva la versione precedente) sposterebbe le unità
        #    verso gli strati più grandi: con N_j = (23, 34, 43) e n = 10
        #    l'allocazione proporzionale (2.3, 3.4, 4.3) dava (2, 3, 5)
        #    invece del corretto (2, 4, 4).
        arrotonda <- function(target, capacita, n_tot) {
          out <- as.integer(pmin(floor(target), capacita))
          frazionaria <- target - floor(target)
          mancanti <- n_tot - sum(out)
          while (mancanti > 0) {
            cand <- which(out < capacita)
            if (length(cand) == 0) break
            ord <- cand[order(frazionaria[cand], pesi[cand], decreasing = TRUE)]
            quante <- min(mancanti, length(ord))
            idx <- ord[seq_len(quante)]
            out[idx] <- out[idx] + 1L
            mancanti <- mancanti - quante
          }
          as.integer(pmin(pmax(out, 0L), capacita))
        }

        # 3) Rappresentanza minima di ogni strato non vuoto.
        #    Uno strato con n_j = 0 darebbe probabilità di inclusione nulla
        #    alle sue unità: il disegno non sarebbe più probabilistico su
        #    tutta la popolazione. Il minimo è 2 unità, la numerosità più
        #    piccola che consente di stimare la variabilità dentro lo
        #    strato; per uno strato che in popolazione ha una sola unità il
        #    minimo è necessariamente 1.
        min_j <- pmin(2L, Nj)
        if (n_req < sum(min_j)) {
          jmvcore::reject(
            sprintf(.tr(
              it = "La numerosità richiesta (%d) non basta a rappresentare i %d strati: ne servono almeno %d, cioè 2 per strato (1 per gli strati che contengono una sola unità). Aumentare n oppure accorpare gli strati più piccoli.",
              en = "The requested sample size (%d) cannot represent the %d strata: at least %d units are needed, i.e. 2 per stratum (1 for strata holding a single unit). Increase n or merge the smallest strata."
            ), n_req, M, sum(min_j)),
            code = ""
          )
        }

        # Allocazione teorica non vincolata: è quella che si applica quando
        # rispetta già i minimi, ed è il termine di confronto per dire se
        # il vincolo ha cambiato qualcosa.
        nj_puro <- arrotonda(alloca_reale(n_req, pesi, Nj), Nj, n_req)

        # Allocazione vincolata: SOLO gli strati che resterebbero sotto il
        # minimo vengono portati al minimo; le unità che restano sono
        # allocate fra gli altri con il criterio scelto. Si ripete finché
        # nessuno strato libero scende sotto il proprio minimo.
        #
        # Riservare i minimi a tutti gli strati *prima* di allocare sarebbe
        # più semplice, ma distruggerebbe la proporzionalità anche quando
        # non serve: l'allocazione proporzionale smetterebbe di essere
        # autoponderata (f_j costante) in ogni esecuzione, non solo in
        # quelle in cui il vincolo morde davvero.
        alloca_vincolata <- function(n_tot, pesi, Nj, min_j) {
          fissi <- rep(FALSE, length(Nj))
          repeat {
            liberi  <- !fissi
            residuo <- n_tot - sum(min_j[fissi])
            cap     <- ifelse(liberi, Nj, 0L)
            nj      <- arrotonda(alloca_reale(residuo, ifelse(liberi, pesi, 0), cap),
                                 cap, residuo)
            nj[fissi] <- min_j[fissi]
            sotto <- liberi & (nj < min_j)
            if (!any(sotto)) return(as.integer(nj))
            fissi[sotto] <- TRUE
          }
        }

        nj <- alloca_vincolata(n_req, pesi, Nj, min_j)
        vincolata <- !identical(nj, nj_puro)
        fj <- ifelse(Nj > 0, nj / Nj, 0)

        if (vincolata) {
          portati <- lev[nj == min_j & nj_puro < min_j]
          self$results$strata$setNote("minimi", sprintf(.tr(
            it = "Allocazione vincolata: l'allocazione teorica lascerebbe gli strati %s sotto il minimo di 2 unità (1 per gli strati che in popolazione ne hanno una sola). Quegli strati sono stati portati al minimo e le unità restanti sono state allocate fra gli altri con il criterio scelto. La somma resta n = %d.",
            en = "Constrained allocation: the theoretical allocation would leave strata %s below the minimum of 2 units (1 for strata holding a single unit in the population). Those strata were raised to the minimum and the remaining units were allocated among the others with the chosen criterion. The total is still n = %d."
          ), paste(portati, collapse = ", "), n_req))
        }

        # Seed e estrazione per strato
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

        # Indicatore di campione 0/1 in spazio "dati"
        freq <- integer(N)
        # Lista delle posizioni estratte per la tabella unità estratte
        sampled_pos <- integer(0)
        sampled_lev <- character(0)

        all_idx <- seq_len(N)
        for (j in seq_len(M)) {
          if (nj[j] <= 0) next
          pool <- all_idx[keep & strat == lev[j]]
          # sample() su un pool di lunghezza 1 campionerebbe da 1:pool:
          # indicizziamo via sample.int per estrarre sempre dal pool reale.
          chosen <- pool[sample.int(length(pool), size = nj[j])]
          freq[chosen] <- 1L
          sampled_pos <- c(sampled_pos, chosen)
          sampled_lev <- c(sampled_lev, rep(lev[j], length(chosen)))
        }

        # Riepilogo
        method_label <- if (method == "optimal")
          .tr(it = "Ottimale (Neyman)", en = "Optimal (Neyman)")
        else
          .tr(it = "Proporzionale", en = "Proportional")
        # Quando i minimi per strato modificano il risultato, l'allocazione
        # non è più quella teorica pura e va chiamata con il suo nome.
        if (vincolata)
          method_label <- paste0(method_label,
                                 .tr(it = " vincolata", en = " (constrained)"))
        tab <- self$results$summary
        tab$setRow(
          rowNo = 1,
          values = list(
            N            = N_eff,
            M            = M,
            n_richiesto  = n_req,
            n_estratto   = sum(freq),
            frazione     = n_req / N_eff,
            metodo       = method_label,
            seed_used    = if (use_seed) as.integer(seed) else NA_integer_
          )
        )

        # Tabella allocazione per strato
        tab_str <- self$results$strata
        for (j in seq_len(M)) {
          tab_str$addRow(
            rowKey = j,
            values = list(
              livello  = lev[j],
              Nj       = Nj[j],
              Wj       = Wj[j],
              sigma_j  = sigma_j[j],
              nj       = nj[j],
              fj       = fj[j]
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
                livello  = sampled_lev[i],
                pos      = sampled_pos[i],
                id_value = as.character(id_values[sampled_pos[i]])
              )
            )
          }
        }

        # Output: colonna iniettata con nome esplicito sul metodo usato
        out_name <- if (method == "optimal") "in_STott" else "in_STpr"
        self$results$out_freq$setTitle(out_name)
        self$results$out_freq$setValues(freq)
        self$results$out_freq$setRowNums(rownames(dati))
      }
    )
  )
}
