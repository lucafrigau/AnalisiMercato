
# Duplicati: trova le righe uguali sulle variabili scelte. Con i moduli
# online capitano gli invii doppi, e fra le funzioni di Calcola di jamovi
# non ce n'è una per trovarli. Di ogni gruppo di righe uguali si tiene
# l'ultima, perché nel secondo invio il rispondente può aver corretto
# qualcosa; l'analisi non esclude nessuno da sola, ma crea la variabile
# «duplicato» da usare come filtro.

duplicatesClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "duplicatesClass",
    inherit = duplicatesBase,
    private = list(
      .init = function() {
        self$results$instructions$setContent(.tr(
          it = "<html>
            <head>
            </head>
            <body>
            <div class='justified-text'>
              <p> L'analisi trova le righe uguali sulle variabili scelte, come gli invii doppi
              di un modulo online. Le variabili si scelgono in due modi:
              <ul>
              <li> tutte quelle del questionario, tranne l'informazione cronologica, che cambia
              a ogni invio: si trovano gli invii identici; </li>
              <li> solo quelle che identificano il rispondente, come l'email o la matricola: si
              trova chi ha risposto più volte, anche con risposte diverse. </li>
              </ul>
              </p>

              <p> Due valori mancanti nella stessa variabile contano come uguali. Le righe in cui
              mancano tutte le variabili scelte, per esempio senza email, non si confrontano:
              altrimenti risulterebbero tutte duplicate.</p>

              <p> Di ogni gruppo di righe uguali si tiene l'ultima, perché nel secondo invio il
              rispondente può aver corretto qualcosa: nei file di Moduli Google, che sono in
              ordine di invio, è la più recente. Con <i>Crea la variabile «duplicato»</i> si
              aggiunge al dataset una variabile che vale 0 per le righe da tenere e 1 per le
              altre: le righe ripetute si escludono con un filtro <i>duplicato == 0</i>.</p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head>
            </head>
            <body>
            <div class='justified-text'>
              <p> The analysis finds the rows that are equal on the chosen variables, such as the
              double submissions of an online form. The variables are chosen in two ways:
              <ul>
              <li> all the variables of the questionnaire except the timestamp, which changes at
              every submission: identical submissions are found; </li>
              <li> only the variables that identify the respondent, such as the email or the
              student number: respondents who answered more than once are found, even with
              different answers. </li>
              </ul>
              </p>

              <p> Two missing values in the same variable count as equal. Rows where all the
              chosen variables are missing, for example without an email, are not compared:
              otherwise they would all be duplicates.</p>

              <p> Of each group of equal rows the last one is kept, because in the second
              submission the respondent may have corrected something: in Google Forms files,
              which are in submission order, it is the most recent one. <i>Create the «duplicato»
              variable</i> adds to the dataset a variable equal to 0 for the rows to keep and 1
              for the others: the repeated rows are excluded with a filter
              <i>duplicato == 0</i>.</p>
            </div>
            </body>
            </html>"
        ))

        vars <- as.character(unlist(self$options$vars))
        if (length(vars) > 0)
          self$results$gruppi$getColumn("valore")$setTitle(vars[1])
      },

      .run = function() {
        vars <- as.character(unlist(self$options$vars))
        if (is.null(self$data) || length(vars) == 0) return()

        dati <- self$data[, vars, drop = FALSE]
        ris <- .trova_duplicati(dati, isTRUE(self$options$ignoreCase))
        # i numeri di riga di jamovi, anche con un filtro attivo
        righe <- as.integer(rownames(self$data))

        riepilogo <- self$results$riepilogo
        riepilogo$setRow(rowNo = 1, values = list(
          righe = sum(!ris$vuota),
          gruppi = length(ris$gruppi),
          inpiu = sum(ris$duplicato),
          vuote = sum(ris$vuota)
        ))

        tabella <- self$results$gruppi
        primo <- as.character(dati[[1]])
        for (i in seq_along(ris$gruppi)) {
          g <- ris$gruppi[[i]]
          tabella$addRow(rowKey = i, values = list(
            gruppo = i,
            righe = paste(righe[g], collapse = ", "),
            tenuta = righe[g[length(g)]],
            valore = if (is.na(primo[g[1]])) "" else primo[g[1]]
          ))
        }
        # jamovi non mostra le note di una tabella senza righe: il messaggio
        # va nel riepilogo e la tabella vuota si nasconde
        tabella$setVisible(length(ris$gruppi) > 0)
        if (length(ris$gruppi) == 0)
          riepilogo$setNote("nessuno", .tr(
            it = "Nessuna riga ripetuta sulle variabili scelte.",
            en = "No repeated rows on the chosen variables."
          ))

        uscita <- self$results$duplicatoOV
        if (isTRUE(self$options$duplicatoOV) && uscita$isNotFilled()) {
          uscita$setRowNums(rownames(self$data))
          uscita$setValues(ris$duplicato)
        }
      }
    )
  )
}

# Righe uguali di un data frame. Restituisce i gruppi di righe uguali (gli
# indici, in ordine di riga), il vettore `duplicato` (1 per tutte le righe
# di un gruppo tranne l'ultima) e quali righe sono vuote, cioè senza alcun
# valore sulle variabili confrontate: quelle non si confrontano.
.trova_duplicati <- function(dati, ignora_maiuscole = TRUE) {
  normalizza <- function(x) {
    s <- as.character(x)
    if (!is.numeric(x) && ignora_maiuscole)
      s <- tolower(gsub("\\s+", " ", trimws(s)))
    s[!is.na(s) & !nzchar(trimws(s))] <- NA
    s
  }
  colonne <- lapply(dati, normalizza)
  vuota <- Reduce(`&`, lapply(colonne, is.na))
  # i mancanti diventano un segnaposto, così due NA contano come uguali
  chiave <- do.call(paste, c(
    lapply(colonne, function(s) ifelse(is.na(s), "\u001fNA", s)),
    sep = "\u001e"))
  chiave[vuota] <- NA
  indici <- split(seq_along(chiave),
                  factor(chiave, levels = unique(chiave[!is.na(chiave)])))
  gruppi <- unname(Filter(function(g) length(g) > 1, indici))
  duplicato <- integer(length(chiave))
  for (g in gruppi) duplicato[g[-length(g)]] <- 1L
  list(gruppi = gruppi, duplicato = duplicato, vuota = vuota)
}
