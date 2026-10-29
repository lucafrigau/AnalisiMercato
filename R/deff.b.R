# This file is a generated template, your changes will not be overwritten

deffClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "deffClass",
    inherit = deffBase,
    private = list(

      .init = function() {
        self$results$instructions$setContent(.tr(
          it = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Design Effect (Deff)</h3>
              <p>
                Il Design Effect, introdotto da Kish (1965), confronta la
                varianza dello stimatore in un piano complesso con quella
                che si avrebbe in un campione casuale semplice (SCR) di
                pari numerosità:
                <br>&emsp;Deff = Var(θ̂ | piano complesso) / Var(θ̂ | SCR)
              </p>
              <p>
                Interpretazione:
                <ul>
                  <li>Deff &lt; 1: il piano complesso è <b>più efficiente</b>
                  del SCR (tipico dello stratificato).</li>
                  <li>Deff = 1: equivalente al SCR.</li>
                  <li>Deff &gt; 1: il piano complesso è <b>meno efficiente</b>
                  (tipico di grappoli e multi-stadi con ρ &gt; 0).</li>
                </ul>
              </p>
              <p>
                Formule analitiche implementate (slide 39, coerenti con
                Cochran 1977):
                <ul>
                  <li><b>Sistematico</b>: Deff ≈ (k+1)/(N+1) con k = N/n.
                  Valida per popolazione ordinata con <i>trend lineare</i>
                  (Cochran Th. 8.6); per popolazione ordinata casualmente
                  Deff ≈ 1.</li>
                  <li><b>A più stadi / a grappoli</b>: Deff ≈ 1 + (n−1)·ρ
                  dove ρ è il coefficiente di correlazione intra (Kish 1965).</li>
                  <li><b>Stratificato</b> (allocazione proporzionale):
                  Deff ≈ 1 − R²·(L²−1)/L² (Cochran Eq. 5.51).
                  Stratificazione di una variabile continua X correlata a
                  Y in L classi equiampie; R² = ρ²(X,Y). Per L → ∞ la
                  formula tende all'ideale Deff = 1 − R².</li>
                </ul>
              </p>
              <p>
                La numerosità di riferimento n si legge in due modi: se è
                la numerosità del casuale semplice da eguagliare, il piano
                complesso ne richiede n_complex = Deff · n; se è un campione
                già raccolto col piano complesso, vale quanto
                n_eff = n / Deff unità di un casuale semplice.
              </p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Design Effect (Deff)</h3>
              <p>
                The Design Effect, introduced by Kish (1965), compares the
                variance of an estimator under a complex sampling design with
                the variance under a simple random sample (SRS) of the same
                size:
                <br>&emsp;Deff = Var(θ̂ | complex design) / Var(θ̂ | SRS)
              </p>
              <p>
                Interpretation:
                <ul>
                  <li>Deff &lt; 1: the complex design is <b>more efficient</b>
                  than SRS (typical of stratified sampling).</li>
                  <li>Deff = 1: equivalent to SRS.</li>
                  <li>Deff &gt; 1: the complex design is <b>less efficient</b>
                  (typical of cluster and multistage with ρ &gt; 0).</li>
                </ul>
              </p>
              <p>
                Analytical formulae implemented (slide 39, consistent with
                Cochran 1977):
                <ul>
                  <li><b>Systematic</b>: Deff ≈ (k+1)/(N+1) with k = N/n.
                  Valid for a population ordered along a <i>linear trend</i>
                  (Cochran Th. 8.6); for a randomly ordered population
                  Deff ≈ 1.</li>
                  <li><b>Multistage / clusters</b>: Deff ≈ 1 + (n−1)·ρ
                  where ρ is the intra-cluster correlation (Kish 1965).</li>
                  <li><b>Stratified</b> (proportional allocation):
                  Deff ≈ 1 − R²·(L²−1)/L² (Cochran Eq. 5.51).
                  Stratification of a continuous variable X correlated with Y
                  in L equal-width strata; R² = ρ²(X,Y). For L → ∞ the formula
                  tends to the ideal Deff = 1 − R².</li>
                </ul>
              </p>
              <p>
                The reference size n is read in two ways: if it is the size
                of the simple random sample to be matched, the complex design
                needs n_complex = Deff · n units; if it is a sample already
                collected with the complex design, it is worth
                n_eff = n / Deff units of a simple random sample.
              </p>
            </div>
            </body>
            </html>"
        ))
      },

      # ATTENZIONE: come samplesize, questa analisi non ha un'opzione di
      # tipo Data (`requiresData = FALSE`). Il wrapper R generato passa
      # `data = data` senza avere quell'argomento, quindi il nome si
      # risolve a `utils::data` e `self$data` contiene una FUNZIONE, non
      # NULL: non usarlo mai in questo file.
      .run = function() {
        mode <- self$options$mode
        n_srs <- self$options$n_srs

        formula_used <- ""
        plan_label <- ""

        if (mode == "variances") {
          # Calcolo come rapporto delle varianze
          vc <- self$options$var_complex
          vs <- self$options$var_srs
          if (!is.finite(vc) || !is.finite(vs) || vs <= 0) {
            jmvcore::reject(.tr(
              it = "Le varianze devono essere finite e positive (denominatore > 0).",
              en = "Variances must be finite and positive (denominator > 0)."
            ), code = "")
          }
          deff <- vc / vs
          formula_used <- .tr(it = "Deff = Var(complesso) / Var(SCR)",
                              en = "Deff = Var(complex) / Var(SRS)")
          plan_label <- "—"
        } else {
          plan <- self$options$plan
          if (plan == "systematic") {
            # Formula valida per popolazione con trend lineare (Cochran
            # 1977 Th. 8.6). In ordinamento casuale Deff ≈ 1; in
            # ordinamento periodico col passo k pari al periodo Deff
            # può essere molto > 1. Qui si fornisce il caso ideale
            # didattico (trend lineare → sistematico molto efficiente).
            N <- self$options$N
            n <- self$options$n_total
            if (n >= N) {
              jmvcore::reject(.tr(
                it = "Per il sistematico serve n < N.",
                en = "Systematic sampling requires n < N."
              ), code = "")
            }
            # La formula di Cochran nasce per il sistematico CLASSICO con
            # N = n·k e k intero. Il modulo estrae invece con intervallo
            # frazionario (v. samplesyst): applicare la stessa espressione
            # a un k non intero le attribuirebbe una validità mai
            # dimostrata per quell'algoritmo. Con N non multiplo di n il
            # benchmark quindi non si calcola.
            plan_label <- .tr(it = "Sistematico", en = "Systematic")
            benchmark_assente <- FALSE
            if (N %% n == 0) {
              k <- N / n
              deff <- (k + 1) / (N + 1)
              formula_used <- sprintf(.tr(
                it = "Benchmark teorico — trend lineare perfetto, N = n·k: Deff = (k+1)/(N+1) con k = %d",
                en = "Theoretical benchmark — perfect linear trend, N = n·k: Deff = (k+1)/(N+1) with k = %d"
              ), as.integer(k))
            } else {
              deff <- NA_real_
              benchmark_assente <- TRUE
              formula_used <- .tr(
                it = "Benchmark non calcolabile: definito solo per N = n·k con k intero",
                en = "Benchmark not available: defined only for N = n·k with integer k"
              )
              self$results$result$setNote("sys", .tr(
                it = "Il benchmark analitico implementato è definito per il sistematico classico con N = n·k e k intero. Con N non multiplo di n, AnalisiMercato estrae con il sistematico a intervallo frazionario e questo benchmark non viene calcolato.",
                en = "The implemented analytic benchmark is defined for classic systematic sampling with N = n·k and integer k. When N is not a multiple of n, AnalisiMercato draws with the fractional-interval systematic design and this benchmark is not computed."
              ))
            }
          } else if (plan == "multistage" || plan == "cluster") {
            rho <- self$options$rho
            nw <- self$options$n_within
            if (nw < 1) {
              jmvcore::reject(.tr(
                it = "La numerosità di gruppo / grappolo deve essere ≥ 1.",
                en = "Group / cluster size must be ≥ 1."
              ), code = "")
            }
            # Bound inferiore dell'ICC: ρ ≥ −1/(n−1). Valori sotto il
            # bound non sono coefficienti di correlazione intraclasse
            # ammissibili e darebbero Deff negativi senza spiegazione.
            if (nw >= 2 && rho < -1 / (nw - 1)) {
              jmvcore::reject(
                sprintf(.tr(
                  it = "ρ = %g è sotto il limite inferiore ammissibile per l'ICC con n = %d: ρ ≥ −1/(n−1) = %.4f.",
                  en = "ρ = %g is below the admissible lower bound of the ICC with n = %d: ρ ≥ −1/(n−1) = %.4f."
                ), rho, nw, -1 / (nw - 1)),
                code = ""
              )
            }
            deff <- 1 + (nw - 1) * rho
            formula_used <- sprintf(.tr(
              it = "Deff = 1 + (n−1)·ρ con n = %d e ρ = %g",
              en = "Deff = 1 + (n−1)·ρ with n = %d and ρ = %g"
            ), nw, rho)
            plan_label <- if (plan == "multistage")
              .tr(it = "A più stadi", en = "Multi-stage")
            else .tr(it = "A grappoli", en = "Cluster")
          } else {
            # Stratificato proporzionale, stratificazione di una
            # variabile continua X in L classi equiampie (Cochran 1977
            # Eq. 5.51). R² è il quadrato della correlazione fra Y e X
            # nella popolazione. Per L → ∞ tende all'ideale 1 − R².
            L <- self$options$L
            R2 <- self$options$R2
            if (L < 2) {
              jmvcore::reject(.tr(
                it = "Servono almeno 2 strati.",
                en = "At least 2 strata are required."
              ), code = "")
            }
            deff <- 1 - R2 * (L^2 - 1) / L^2
            formula_used <- sprintf(.tr(
              it = "Deff ≈ 1 − R²·(L²−1)/L² con L = %d e R² = %g (Cochran Eq. 5.51, allocazione proporzionale)",
              en = "Deff ≈ 1 − R²·(L²−1)/L² with L = %d and R² = %g (Cochran Eq. 5.51, proportional allocation)"
            ), L, R2)
            plan_label <- .tr(it = "Stratificato", en = "Stratified")
          }
        }

        # Deff = 0 passerebbe i controlli ma implicherebbe una varianza
        # nulla del piano complesso e n equivalente = 0: non è un
        # risultato interpretabile. Fa eccezione il caso dichiarato in cui
        # il benchmark del sistematico non è definito: lì il Deff manca
        # per costruzione e la tabella resta vuota, con la sua nota.
        if (!exists("benchmark_assente")) benchmark_assente <- FALSE
        if (!benchmark_assente && (!is.finite(deff) || deff <= 0)) {
          jmvcore::reject(
            sprintf(.tr(
              it = "Il Deff calcolato (%.4f) non è valido: deve essere strettamente positivo. Controllare i parametri inseriti.",
              en = "The computed Deff (%.4f) is not valid: it must be strictly positive. Check the input parameters."
            ), deff),
            code = ""
          )
        }

        # Con il benchmark non calcolabile il risultato resta vuoto invece
        # di mostrare numeri derivati da un Deff che non c'è.
        deff_noto <- is.finite(deff)
        # Arrotondamento per eccesso protetto dall'errore di virgola mobile:
        # 1 + 82 * 0.05 vale 5.1000000000000005 e 200 volte tanto supera di
        # poco 1020, quindi ceiling() da solo darebbe 1021 (come in samplesyst).
        ceil_tol  <- function(x) ceiling(round(x, 8))
        n_complex <- if (deff_noto) ceil_tol(deff * n_srs) else NA_integer_
        n_eff     <- if (deff_noto) max(1L, as.integer(ceil_tol(n_srs / deff))) else NA_integer_
        eff_label <- if (!deff_noto) {
          "—"
        } else if (deff < 1) {
          .tr(it = "Maggiore (Deff < 1)", en = "Higher (Deff < 1)")
        } else if (abs(deff - 1) < 1e-9) {
          .tr(it = "Uguale (Deff = 1)", en = "Equal (Deff = 1)")
        } else {
          .tr(it = "Minore (Deff > 1)", en = "Lower (Deff > 1)")
        }

        # Tabella parametri
        tab_in <- self$results$inputs
        tab_in$setRow(
          rowNo = 1,
          values = list(
            modalita = if (mode == "variances")
              .tr(it = "Da varianze", en = "From variances")
            else .tr(it = "Formula analitica", en = "Analytic formula"),
            piano    = plan_label,
            formula  = formula_used
          )
        )

        # Tabella risultato
        tab_out <- self$results$result
        tab_out$setRow(
          rowNo = 1,
          values = list(
            deff       = deff,
            efficienza = eff_label,
            n_srs      = n_srs,
            # Le due direzioni del Deff non vanno confuse: n_complex è la
            # numerosità che il piano richiede per eguagliare un SCR di
            # n_srs unità (progettazione); n_eff è l'informazione che
            # resterebbe se quelle n_srs unità fossero raccolte col piano
            # complesso (analisi di un campione già osservato).
            n_complex  = n_complex,
            n_eff      = n_eff
          )
        )
      }
    )
  )
}
