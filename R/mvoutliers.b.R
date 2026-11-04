
# Outlier multivariati: la distanza di Mahalanobis di ogni osservazione dal
# centro dei dati, che tiene conto delle correlazioni fra le variabili. In
# jamovi la si trova solo fra i salvataggi della regressione lineare, che
# richiede una variabile dipendente. È il controllo naturale prima della
# cluster analysis, dove pochi punti anomali possono formare gruppi a sé.
# L'analisi segnala gli outlier, non li esclude.

mvoutliersClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "mvoutliersClass",
    inherit = mvoutliersBase,
    private = list(
      .init = function() {
        .controlla_limiti("mvoutliers", self$options)
        self$results$instructions$setContent(.tr(
          it = "<html>
            <head>
            </head>
            <body>
            <div class='justified-text'>
              <p> La distanza di Mahalanobis misura quanto ogni osservazione è lontana dal centro
              dei dati, tenendo conto delle correlazioni fra le variabili: una combinazione
              insolita di valori, ciascuno normale da solo, dà una distanza grande. Un cliente
              con un reddito alto e una spesa molto bassa, per esempio, può non essere estremo né
              per il reddito né per la spesa, ma esserlo per la combinazione dei due.</p>

              <p> Servono almeno due variabili quantitative. Un'osservazione è un outlier quando
              la sua distanza al quadrato (D²) supera il valore critico del chi-quadrato con
              tanti gradi di libertà quante sono le variabili, alla soglia scelta (0,001 di
              solito). Le righe con valori mancanti non hanno distanza.</p>

              <p> Gli outlier gonfiano la covarianza da cui si calcola la distanza: se sono molti,
              possono nascondersi a vicenda. Ogni outlier va verificato, perché può essere un
              errore o un caso raro ma reale; l'analisi lo segnala e non lo esclude. La distanza
              e un indicatore 0/1 si possono aggiungere al dataset.</p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head>
            </head>
            <body>
            <div class='justified-text'>
              <p> The Mahalanobis distance measures how far each observation is from the centre
              of the data, taking the correlations between the variables into account: an
              unusual combination of values, each normal on its own, gives a large distance. A
              customer with a high income and a very low spending, for example, may be extreme
              neither for income nor for spending, but be extreme for their combination.</p>

              <p> At least two quantitative variables are needed. An observation is an outlier
              when its squared distance (D²) exceeds the critical value of the chi-square with
              as many degrees of freedom as variables, at the chosen threshold (usually 0.001).
              Rows with missing values have no distance.</p>

              <p> Outliers inflate the covariance from which the distance is computed: if there
              are many, they can mask each other. Each outlier has to be checked, because it may
              be an error or a rare but real case; the analysis flags it and does not exclude
              it. The distance and a 0/1 indicator can be added to the dataset.</p>
            </div>
            </body>
            </html>"
        ))

        tabella <- self$results$outlier
        for (v in as.character(unlist(self$options$vars)))
          tabella$addColumn(name = paste0("v_", v), title = v, type = "number")
      },

      .run = function() {
        vars <- as.character(unlist(self$options$vars))
        # con meno di due variabili l'analisi non è ancora impostata
        if (is.null(self$data) || length(vars) < 2) return()

        dati <- as.data.frame(lapply(self$data[, vars, drop = FALSE], jmvcore::toNumeric))
        completi <- stats::complete.cases(dati)
        if (sum(completi) <= length(vars)) {
          jmvcore::reject(sprintf(.tr(
            it = "Le osservazioni senza mancanti sono %d: per la distanza di Mahalanobis su %d variabili ne servono più delle variabili.",
            en = "There are %d observations without missing values: the Mahalanobis distance on %d variables needs more observations than variables."
          ), sum(completi), length(vars)), code = "")
        }

        d2 <- rep(NA_real_, nrow(dati))
        d2[completi] <- .distanze_mahalanobis(dati[completi, , drop = FALSE])
        p <- length(vars)
        alpha <- self$options$alpha
        soglia <- stats::qchisq(1 - alpha, df = p)
        pval <- stats::pchisq(d2, df = p, lower.tail = FALSE)
        fuori <- !is.na(d2) & d2 > soglia

        self$results$riepilogo$setRow(rowNo = 1, values = list(
          n = sum(completi), p = p, soglia = soglia,
          nout = sum(fuori), escluse = sum(!completi)))
        self$results$riepilogo$setNote("soglia", sprintf(.tr(
          it = "Outlier: osservazioni con D² maggiore del valore critico del chi-quadrato con %d gradi di libertà, cioè con p minore di %s.",
          en = "Outliers: observations with D² larger than the critical value of the chi-square with %d degrees of freedom, that is with p smaller than %s."
        ), p, format(alpha)))

        righe <- as.integer(rownames(self$data))
        tabella <- self$results$outlier
        for (j in which(fuori)[order(-d2[fuori])]) {
          valori <- list(riga = righe[j], d2 = d2[j], pval = pval[j])
          for (v in vars) valori[[paste0("v_", v)]] <- dati[[v]][j]
          tabella$addRow(rowKey = j, values = valori)
        }
        # jamovi non mostra le note di una tabella senza righe: i messaggi
        # vanno nel riepilogo e la tabella vuota si nasconde
        tabella$setVisible(any(fuori))
        if (!any(fuori))
          self$results$riepilogo$setNote("nessuno", .tr(
            it = "Nessuna osservazione oltre la soglia.",
            en = "No observation beyond the threshold."
          ))
        self$results$riepilogo$setNote("mascheramento", .tr(
          it = "Gli outlier gonfiano la covarianza da cui si calcola la distanza: se sono molti, possono nascondersi a vicenda. Ogni outlier va verificato prima di decidere se escluderlo.",
          en = "Outliers inflate the covariance from which the distance is computed: if there are many, they can mask each other. Each outlier has to be checked before deciding whether to exclude it."
        ))

        uscita <- self$results$distOV
        if (isTRUE(self$options$distOV) && uscita$isNotFilled()) {
          uscita$setRowNums(rownames(self$data))
          uscita$setValues(d2)
        }
        uscita <- self$results$outlierOV
        if (isTRUE(self$options$outlierOV) && uscita$isNotFilled()) {
          uscita$setRowNums(rownames(self$data))
          uscita$setValues(ifelse(is.na(d2), NA_integer_, as.integer(fuori)))
        }
      }
    )
  )
}

# Distanza di Mahalanobis al quadrato di ogni riga dal vettore delle medie.
# Con covarianza singolare o quasi l'inversa non esiste: ci si ferma con lo
# stesso messaggio della cluster gerarchica con la distanza di Mahalanobis.
.distanze_mahalanobis <- function(dati) {
  x <- as.matrix(dati)
  S <- stats::cov(x)
  cond <- tryCatch(rcond(S), error = function(e) 0)
  if (!is.finite(cond) || cond < 1e-10) {
    jmvcore::reject(.tr(
      it = "La matrice di covarianza delle variabili scelte non è invertibile o è numericamente instabile, quindi la distanza di Mahalanobis non è calcolabile: succede quando le variabili sono (quasi) collineari, per esempio con tutte le dummy di una stessa variabile, o quando sono più numerose delle osservazioni. Ridurre il numero di variabili o eliminare le dipendenze lineari.",
      en = "The covariance matrix of the selected variables is not invertible or is numerically unstable, so the Mahalanobis distance cannot be computed: this happens when variables are (nearly) collinear, for example with all the dummies of one variable, or outnumber the observations. Reduce the number of variables or remove linear dependencies."
    ), code = "")
  }
  stats::mahalanobis(x, colMeans(x), S)
}
