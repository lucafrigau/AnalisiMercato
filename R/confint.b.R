# This file is a generated template, your changes will not be overwritten

confintClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "confintClass",
    inherit = confintBase,
    private = list(

      .init = function() {
        self$results$instructions$setContent(.tr(
          it = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Intervalli di confidenza</h3>
              <p>
                Calcola l'intervallo di confidenza per una proporzione o
                una media a partire (a) da un campione presente nel dataset
                attivo, oppure (b) da statistiche campionarie fornite a mano.
              </p>
              <p>
                <b>Modalità da dataset</b>: trascina una variabile nella
                casella in alto. Se è numerica viene calcolato l'IC della
                media; se è categoriale viene calcolato l'IC della
                proporzione del livello scelto come 'successo'.
              </p>
              <p>
                <b>Modalità manuale</b> (nessuna variabile selezionata):
                inserisci n, p_c (per proporzione) oppure x̄ e s (per media).
              </p>
              <p>
                Formule (Cochran 1977):
                <br>&emsp;IC(P) = p̂ ∓ z·√[(1−f)·p̂(1−p̂)/(n−1)]
                <br>&emsp;IC(μ) = x̄ ∓ z·(s/√n)·√(1−f)
                <br>
                con s deviazione standard campionaria (denominatore n−1).
                Le due formule sono in realtà <b>la stessa formula</b>: per
                una variabile 0/1 si ha s² = n·p̂(1−p̂)/(n−1), quindi l'IC
                della proporzione è l'IC della media applicato alla
                variabile indicatrice del successo.
              </p>
              <p>
                Il fattore correttivo per popolazioni finite (1−f), con
                f = n/N, <b>non è attivo per default</b>: va abilitato
                consapevolmente quando si sa di campionare senza
                reinserimento da una popolazione finita di ampiezza nota N.
                Attenzione al caso limite f = 1 (n = N, censimento), in cui
                l'errore standard si annulla.
              </p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Confidence intervals</h3>
              <p>
                Compute a confidence interval for a proportion or a mean,
                either (a) from a sample variable in the active dataset, or
                (b) from sample statistics provided manually.
              </p>
              <p>
                <b>Dataset mode</b>: drop a variable in the top box. If
                numeric, the CI for the mean is computed; if categorical,
                the CI for the proportion of the chosen 'success' level.
              </p>
              <p>
                <b>Manual mode</b> (no variable selected): enter n, p̂ (for
                a proportion) or x̄ and s (for a mean).
              </p>
              <p>
                Formulae (Cochran 1977):
                <br>&emsp;CI(P) = p̂ ∓ z·√[(1−f)·p̂(1−p̂)/(n−1)]
                <br>&emsp;CI(μ) = x̄ ∓ z·(s/√n)·√(1−f)
                <br>
                with s the sample standard deviation (denominator n−1).
                The two formulae are in fact <b>the same formula</b>: for a
                0/1 variable s² = n·p̂(1−p̂)/(n−1), so the CI for a
                proportion is the CI for the mean of the success indicator.
              </p>
              <p>
                The finite population correction (1−f), with f = n/N, is
                <b>off by default</b>: enable it deliberately when you know
                you are sampling without replacement from a finite
                population of known size N. Mind the limiting case f = 1
                (n = N, census), where the standard error vanishes.
              </p>
            </div>
            </body>
            </html>"
        ))
      },

      .run = function() {
        # --- parametri comuni ---
        conf <- self$options$confidence
        alpha <- 1 - conf / 100
        z <- stats::qnorm(1 - alpha / 2)
        N <- self$options$N
        use_fpc <- isTRUE(self$options$use_fpc)

        # --- decide modalità: data se variabile selezionata, manuale altrimenti ---
        data_var <- self$options$data_var
        modalita <- .tr(it = "Manuale", en = "Manual")
        parametro <- ""
        is_prop <- FALSE   # logica separata dall'etichetta tradotta
        stima <- NA_real_
        s_camp <- NA_real_
        n <- NA_integer_

        if (!is.null(data_var) && !is.null(self$data)) {
          # modalità da dataset
          modalita <- .tr(it = "Da dataset", en = "From dataset")
          x <- self$data[[data_var]]
          x <- x[!is.na(x)]
          n <- length(x)
          if (n < 2) {
            jmvcore::reject(.tr(
              it = "La variabile selezionata ha meno di 2 osservazioni valide.",
              en = "The selected variable has fewer than 2 valid observations."
            ), code = "")
          }

          if (is.numeric(x)) {
            parametro <- .tr(it = "Media", en = "Mean")
            stima <- mean(x)
            s_camp <- stats::sd(x)
          } else {
            # variabile categoriale → proporzione
            parametro <- .tr(it = "Proporzione", en = "Proportion")
            is_prop <- TRUE
            xf <- as.factor(x)
            lev <- levels(xf)
            success <- self$options$success_level
            if (is.null(success) || !nzchar(success)) success <- lev[1]
            if (!success %in% lev) {
              jmvcore::reject(
                sprintf(.tr(
                  it = "Il livello di successo '%s' non è presente fra i livelli della variabile: %s.",
                  en = "The success level '%s' is not present among the variable levels: %s."
                ), success, paste(lev, collapse = ", ")),
                code = ""
              )
            }
            stima <- mean(xf == success)
            s_camp <- NA_real_  # non usato per la proporzione
          }
        } else {
          # modalità manuale
          n <- self$options$n_manual
          if (self$options$param == "proportion") {
            parametro <- .tr(it = "Proporzione", en = "Proportion")
            is_prop <- TRUE
            stima <- self$options$p_manual
            s_camp <- NA_real_
          } else {
            parametro <- .tr(it = "Media", en = "Mean")
            stima <- self$options$mean_manual
            s_camp <- self$options$sd_manual
          }
        }

        # --- fattore correttivo per popolazione finita ---
        # n > N è impossibile in un campionamento senza reinserimento:
        # meglio un messaggio esplicito che ignorare l'FPC in silenzio
        # (capita facilmente in modalità dataset, dove n arriva dai dati
        # mentre N resta al valore di default).
        if (use_fpc && !is.null(N) && is.finite(N) && N < n) {
          jmvcore::reject(
            sprintf(.tr(
              it = "La numerosità campionaria (n = %d) supera la popolazione dichiarata (N = %g). Correggere N oppure disattivare il fattore correttivo per popolazioni finite.",
              en = "The sample size (n = %d) exceeds the declared population (N = %g). Fix N or disable the finite population correction."
            ), n, N),
            code = ""
          )
        }
        apply_fpc <- use_fpc && !is.null(N) && is.finite(N) && N >= n
        f_frac <- if (apply_fpc) n / N else 0
        fpc <- 1 - f_frac
        fpc_label <- if (apply_fpc)
          sprintf(.tr(it = "Sì (f = %.4f)", en = "Yes (f = %.4f)"), f_frac)
        else .tr(it = "No", en = "No")

        # --- errore standard e ampiezza ---
        if (is_prop) {
          # Cochran (1977, eq. 3.13): v(p̂) = (1−f)·p̂q̂/(n−1).
          # Il denominatore n−1 non è un dettaglio: rende la proporzione
          # esattamente il caso particolare della media applicata a una
          # variabile 0/1. Per una 0/1 infatti s² = n·p̂q̂/(n−1), quindi
          #   (s/√n)·√(1−f) = √[(1−f)·p̂q̂/(n−1)].
          # Così le due formule di questa analisi sono la stessa formula,
          # e sono coerenti con la varianza usata da "Numerosità
          # campionaria" per ricavare n (là espressa in parametri di
          # popolazione, qui nella sua stima corretta).
          if (n < 2) {
            jmvcore::reject(.tr(
              it = "Per la proporzione servono almeno 2 osservazioni.",
              en = "At least 2 observations are needed for the proportion."
            ), code = "")
          }
          se <- sqrt(fpc * stima * (1 - stima) / (n - 1))
        } else {
          # media (Cochran 1977, eq. 2.20): v(ȳ) = (1-f) · s² / n, con s
          # deviazione standard campionaria corretta (denominatore n-1).
          # Equivalente alla forma didattica s'/√(n-1) quando s' usa il
          # denominatore n: le due scritture coincidono numericamente.
          if (!is.finite(s_camp) || s_camp < 0) {
            jmvcore::reject(.tr(
              it = "Per la media è richiesto uno scarto quadratico medio s ≥ 0.",
              en = "For the mean a non-negative standard deviation s is required."
            ), code = "")
          }
          if (n < 2) {
            jmvcore::reject(.tr(
              it = "Per la media servono almeno 2 osservazioni.",
              en = "At least 2 observations are needed for the mean."
            ), code = "")
          }
          se <- (s_camp / sqrt(n)) * sqrt(fpc)
        }
        halfwidth <- z * se
        lb <- stima - halfwidth
        ub <- stima + halfwidth

        # --- tabella parametri ---
        tab_in <- self$results$inputs
        tab_in$setRow(
          rowNo = 1,
          values = list(
            modalita  = modalita,
            parametro = parametro,
            n         = n,
            N         = if (apply_fpc)
              format(N, big.mark = ".", decimal.mark = ",")
            else .tr(it = "∞ (FPC ignorato)", en = "∞ (FPC ignored)"),
            stima     = stima,
            s         = s_camp,
            z         = z,
            fpc       = fpc_label
          )
        )

        # --- tabella risultato ---
        tab_out <- self$results$result
        tab_out$setRow(
          rowNo = 1,
          values = list(
            confidence = sprintf("%g%%", conf),
            stima      = stima,
            se         = se,
            halfwidth  = halfwidth,
            lower      = lb,
            upper      = ub
          )
        )
      }
    )
  )
}
