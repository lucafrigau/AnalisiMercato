# This file is a generated template, your changes will not be overwritten

samplesizeClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "samplesizeClass",
    inherit = samplesizeBase,
    private = list(

      .init = function() {
        self$results$instructions$setContent(.tr(
          it = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Numerosità campionaria</h3>
              <p>
                Calcola la dimensione campionaria <i>n</i> necessaria per stimare
                un parametro della popolazione (proporzione o media) con un
                margine di errore Δ prefissato a un determinato livello di
                confidenza 1−α.
              </p>
              <p>
                Per la <b>proporzione</b> si usa
                <br>
                &emsp;n = z²·P(1−P)·N / [(N−1)Δ² + z²·P(1−P)]
                <br>
                nel caso senza reinserimento (SSR), oppure
                <br>
                &emsp;n = z²·P(1−P) / Δ²
                <br>
                nel caso con reinserimento (SCR, popolazione infinita).
              </p>
              <p>
                Per la <b>media</b> le formule sono analoghe sostituendo
                P(1−P) con σ². Se non si dispone di una stima pilota di P,
                fissare P = 0.5 (varianza massima) restituisce una stima
                cautelativa di n.
              </p>
              <p>
                L'output mostra l'<i>n</i> teorico (continuo) e l'<i>n</i>
                consigliato (arrotondato per eccesso), oltre alla frazione di
                campionamento f = n/N e all'errore standard atteso dello
                stimatore al livello n scelto.
              </p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Sample size</h3>
              <p>
                Computes the sample size <i>n</i> needed to estimate a
                population parameter (proportion or mean) with a fixed
                margin of error Δ at a given confidence level 1−α.
              </p>
              <p>
                For a <b>proportion</b>:
                <br>
                &emsp;n = z²·P(1−P)·N / [(N−1)Δ² + z²·P(1−P)]
                <br>
                without replacement (SRS-WOR), or
                <br>
                &emsp;n = z²·P(1−P) / Δ²
                <br>
                with replacement (SRS-WR, infinite population).
              </p>
              <p>
                For a <b>mean</b> the formulae are analogous, replacing
                P(1−P) with σ². If no pilot estimate of P is available,
                setting P = 0.5 (maximum variance) gives a conservative n.
              </p>
              <p>
                The output reports the theoretical (continuous) <i>n</i>,
                the recommended (ceiling) <i>n</i>, the sampling fraction
                f = n/N, and the expected standard error of the estimator
                at the chosen sample size.
              </p>
            </div>
            </body>
            </html>"
        ))
      },

      # ATTENZIONE: questa analisi non ha un'opzione di tipo Data
      # (`requiresData = FALSE`: è un calcolatore, non richiede dataset).
      # Il wrapper R generato da jmvtools passa comunque `data = data`
      # senza avere un argomento `data`, quindi il nome si risolve a
      # `utils::data` e `self$data` contiene una FUNZIONE, non NULL.
      # Non usare mai `self$data` qui dentro (in particolare non scrivere
      # `if (is.null(self$data)) return()`: non sarebbe mai vero).
      .run = function() {
        # --- raccolta opzioni ---
        param       <- self$options$param
        replacement <- isTRUE(self$options$replacement)
        N           <- self$options$N
        delta       <- self$options$delta
        confidence  <- self$options$confidence
        P           <- self$options$prop_P
        sigma       <- self$options$mean_sigma

        # --- validazione ---
        if (delta <= 0) {
          jmvcore::reject(.tr(
            it = "Il margine di errore Δ deve essere strettamente positivo.",
            en = "The margin of error Δ must be strictly positive."
          ), code = "")
        }
        if (param == "proportion" && delta >= 1) {
          jmvcore::reject(.tr(
            it = "Per una proporzione il margine di errore Δ deve essere minore di 1 (es. 0.05 = 5%).",
            en = "For a proportion the margin of error Δ must be smaller than 1 (e.g., 0.05 = 5%)."
          ), code = "")
        }
        if (confidence <= 0 || confidence >= 100) {
          jmvcore::reject(.tr(
            it = "Il livello di confidenza deve essere compreso (esclusi) tra 0 e 100.",
            en = "The confidence level must be strictly between 0 and 100."
          ), code = "")
        }
        if (param == "proportion" && (P <= 0 || P >= 1)) {
          # P = 0 o P = 1 darebbero varianza nulla: n = 0 e SE = NaN.
          jmvcore::reject(.tr(
            it = "P deve essere strettamente compreso tra 0 e 1 (con P = 0 o P = 1 la varianza è nulla e la numerosità non è definita). In assenza di informazioni usare il caso più sfavorevole P = 0.5.",
            en = "P must be strictly between 0 and 1 (with P = 0 or P = 1 the variance is zero and the sample size is undefined). With no prior information use the most conservative case P = 0.5."
          ), code = "")
        }
        if (param == "mean" && sigma <= 0) {
          jmvcore::reject(.tr(
            it = "σ deve essere strettamente positivo.",
            en = "σ must be strictly positive."
          ), code = "")
        }

        # --- quantile normale ---
        alpha <- 1 - confidence / 100
        z <- stats::qnorm(1 - alpha / 2)

        # --- calcolo n e varianza attesa ---
        # variance_term è P(1-P) per la proporzione, σ^2 per la media
        variance_term <- if (param == "proportion") P * (1 - P) else sigma^2

        if (replacement) {
          # popolazione infinita o con reinserimento (SCR)
          n_th <- z^2 * variance_term / delta^2
          n_eff <- ceiling(n_th)
          f <- NA_real_
          var_attesa <- variance_term / n_eff
        } else {
          # senza reinserimento (SSR), fattore correttivo per popolazione finita
          n_th <- (z^2 * variance_term * N) /
                  ((N - 1) * delta^2 + z^2 * variance_term)
          n_eff <- ceiling(n_th)
          if (n_eff > N) {
            jmvcore::reject(
              sprintf(.tr(
                it = "La numerosità richiesta (%d) supera la popolazione (%d). Riduci il margine di errore o aumenta N.",
                en = "The required sample size (%d) exceeds the population (%d). Reduce the margin of error or increase N."
              ), n_eff, N),
              code = ""
            )
          }
          f <- n_eff / N
          # La varianza attesa deve usare LA STESSA formula da cui è
          # ricavata n, cioè quella con denominatore (N−1):
          #   Var = (V/n)·(N−n)/(N−1),
          # che invertita dà n = z²VN / [(N−1)Δ² + z²V].
          # Usare (1−f) = (N−n)/N sarebbe incoerente con la formula di n
          # (equivale a interpretare V con divisore N−1 anziché N).
          var_attesa <- ((N - n_eff) / (N - 1)) * variance_term / n_eff
        }

        se_attesa <- sqrt(var_attesa)

        # --- tabella inputs (riepilogo) ---
        tab_in <- self$results$inputs
        tab_in$setRow(
          rowNo = 1,
          values = list(
            parametro  = if (param == "proportion")
              .tr(it = "Proporzione", en = "Proportion")
            else .tr(it = "Media", en = "Mean"),
            N          = if (replacement)
              .tr(it = "∞ (o con reinserimento)", en = "∞ (or with replacement)")
            else format(N, big.mark = ".", decimal.mark = ","),
            delta      = delta,
            conf       = sprintf("%g%%", confidence),
            z          = z,
            input_stat = if (param == "proportion") P else sigma,
            schema     = if (replacement)
              .tr(it = "Con reinserimento (SCR)", en = "With replacement (SRSWR)")
            else .tr(it = "Senza reinserimento (SSR)", en = "Without replacement (SRSWOR)")
          )
        )

        # --- tabella risultato ---
        tab_out <- self$results$result
        tab_out$setRow(
          rowNo = 1,
          values = list(
            n_teorico     = n_th,
            n_consigliato = n_eff,
            frazione      = f,
            var_attesa    = var_attesa,
            se_attesa     = se_attesa
          )
        )
      }
    )
  )
}
