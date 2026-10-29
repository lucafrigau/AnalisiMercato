# This file is a generated template, your changes will not be overwritten

ariClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "ariClass",
    inherit = ariBase,
    private = list(
      .init = function() {
        # `self$data` contains the data
        # `self$options` contains the options
        # `self$results` contains the results object (to populate)

        if (is.null(self$data) | is.null(self$options$vars)) {
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
              <p> L'Adjusted Rand Index (ARI) e' una misura utilizzata per valutare la concordanza
              tra due partizioni. L'ARI tiene conto del caso in cui l'accordo tra le partizioni
              potrebbe verificarsi per puro caso, correggendo il Rand Index non corretto.</p>

              <p> Questa metrica calcola la somiglianza tra le due partizioni considerando sia i
              dati assegnati correttamente allo stesso cluster sia quelli assegnati correttamente
              a cluster diversi. L'ARI e' normalizzato per avere un valore compreso tra -1 e 1:
              <ul>
              <li> Un valore vicino a 1 indica una corrispondenza quasi perfetta tra le partizioni. </li>
              <li> Un valore pari a 0 indica che le partizioni concordano quanto ci si aspetterebbe per caso. </li>
              <li> Valori negativi segnalano una discordanza peggiore di quanto ci si aspetterebbe per caso. </li>
              </ul>
              </p>

            </div>
            </body>
            </html>",
          en = "<html>
            <head>
            </head>
            <body>
            <div class='justified-text'>
              <p> The Adjusted Rand Index (ARI) measures the agreement between two
              partitions of the same observations. The ARI corrects the standard
              Rand Index for the agreement that would be expected by chance alone.</p>

              <p> The index combines both observations assigned to the same cluster
              in both partitions and observations assigned to different clusters in
              both partitions. The ARI is normalised to lie between −1 and 1:
              <ul>
              <li> Values close to 1 indicate near-perfect agreement between the two partitions. </li>
              <li> A value of 0 means that the partitions agree only as much as expected by chance. </li>
              <li> Negative values indicate disagreement worse than chance. </li>
              </ul>
              </p>

            </div>
            </body>
            </html>"
        ))

        matrix <- self$results$matrix
        vars <- self$options$vars
        nVars <- length(vars)

        for (i in seq_along(vars)) {
          var <- vars[[i]]

          matrix$addColumn(
            name = paste0(var, '[r]'),
            title = var,
            type = 'number',
            format = 'zto'
          )
        }

        # Inizializza le celle del triangolo superiore (vuote) e la diagonale.
        # Le colonne sono di tipo number: usiamo NA_real_ per le celle vuote
        # \u2014 jmvcore le renderizza come vuote senza generare warning di
        # coercion (che invece scatta con stringhe vuote).
        for (i in seq_along(vars)) {
          var <- vars[[i]]
          values <- list()

          for (j in seq(i, nVars)) {
            v <- vars[[j]]
            # La diagonale è ARI(partizione, se stessa) = 1 per definizione:
            # mostrarla esplicitamente aiuta la lettura della matrice.
            values[[paste0(v, '[r]')]] <- if (j == i) 1 else NA_real_
          }

          matrix$setRow(rowKey = var, values)
        }
      },
      .run = function() {
        matrix <- self$results$matrix
        vars <- self$options$vars
        nVars <- length(vars)

        if (nVars < 2) return()

        for (i in 2:nVars) {
          rowVarName <- vars[[i]]
          rowVar <- as.character(self$data[[rowVarName]])
          for (j in seq_len(i - 1)) {
            colVarName <- vars[[j]]
            colVar <- as.character(self$data[[colVarName]])

            result <- private$.test(rowVar, colVar)

            values <- list()
            values[[paste0(colVarName, '[r]')]] <- result$r
            matrix$setRow(rowNo = i, values)
          }
        }
      },
      .test = function(var1, var2) {
        # Adjusted Rand Index (Hubert & Arabie, 1985).
        # Le osservazioni con NA in almeno una delle due partizioni vengono escluse.
        adjustedRandIndex <- function(x, y) {
          if (length(x) != length(y)) {
            stop(.tr(
              it = "le partizioni devono avere la stessa lunghezza",
              en = "partitions must have the same length"
            ))
          }
          keep <- !(is.na(x) | is.na(y))
          x <- x[keep]
          y <- y[keep]
          if (length(x) < 2) return(NaN)
          tab <- table(x, y)
          # Livelli dichiarati ma non osservati (tipici dopo un filtro
          # jamovi) lascerebbero righe/colonne interamente nulle: il test
          # di equivalenza qui sotto fallirebbe e partizioni identiche
          # tornerebbero NaN. Li eliminiamo dai margini.
          tab <- tab[rowSums(tab) > 0, colSums(tab) > 0, drop = FALSE]
          if (nrow(tab) == 0 || ncol(tab) == 0) return(NaN)
          # Due partizioni che inducono la STESSA relazione di equivalenza
          # (a meno della rietichettatura dei gruppi) hanno per
          # definizione concordanza perfetta: ARI = 1. La formula di
          # Hubert-Arabie però degenera in 0/0 proprio nei casi limite in
          # cui non esiste variabilità di coppie, cioè quando entrambe le
          # partizioni mettono tutte le unità in un unico gruppo oppure
          # quando entrambe sono fatte di soli singoletti (1 2 3 4 contro
          # 1 2 3 4). Riconosciamo il caso guardando la tabella di
          # contingenza: i cluster si corrispondono uno-a-uno se e solo se
          # essa ha esattamente una cella non nulla per riga e per colonna.
          if (all(rowSums(tab > 0) == 1) && all(colSums(tab > 0) == 1))
            return(1)
          a <- sum(choose(tab, 2))
          b <- sum(choose(rowSums(tab), 2)) - a
          c <- sum(choose(colSums(tab), 2)) - a
          d <- choose(sum(tab), 2) - a - b - c
          num <- a - ((a + b) * (a + c)) / (a + b + c + d)
          den <- ((a + b) + (a + c)) / 2 - ((a + b) * (a + c)) / (a + b + c + d)
          if (den == 0) return(NaN)
          num / den
        }

        res <- suppressWarnings(try(adjustedRandIndex(var1, var2), silent = TRUE))
        list(r = if (inherits(res, "try-error")) NaN else res)
      }
    )
  )
}
