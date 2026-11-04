
# Variabili dummy: una variabile 0/1 per ciascuna modalità di una variabile
# categoriale, oppure per ciascuna opzione di una domanda a risposta
# multipla. Le dummy entrano nel dataset con l'output dummiesOV, di tipo
# continuo: così vanno direttamente nella casella delle binarie di
# presenza/assenza della cluster gerarchica e funzionano con ogni distanza.

dummiesClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "dummiesClass",
    inherit = dummiesBase,
    private = list(
      .init = function() {
        .controlla_limiti("dummies", self$options)
        self$results$instructions$setContent(.tr(
          it = "<html>
            <head>
            </head>
            <body>
            <div class='justified-text'>
              <p> L'analisi crea le variabili dummy di una o più variabili categoriali: una
              variabile per ciascuna modalità, che vale 1 se l'osservazione ha quella modalità e
              0 altrimenti. Si chiamano <i>variabile_modalità</i> e sono di tipo continuo, quindi
              possono entrare nella cluster gerarchica con qualunque distanza.</p>

              <p> Si creano tutte le modalità, non una in meno come nei modelli di regressione:
              nelle analisi del modulo ogni modalità va rappresentata. Dove manca la variabile
              originale mancano anche le sue dummy, invece di valere 0.</p>

              <p> Con <i>Risposta multipla</i> ogni cella può contenere più opzioni separate dal
              separatore, come nelle domande di Moduli Google che ammettono più risposte
              (<i>Instagram, TikTok</i>), e si crea una dummy per ciascuna opzione. Le opzioni
              scelte da pochissimi rispondenti, come le risposte libere della voce Altro, si
              possono riunire in un'unica dummy <i>altro</i>. Un'opzione che contiene a sua volta
              il separatore viene spezzata in due.</p>

              <p> Per aggiungere le dummy al dataset si attiva <i>Crea le variabili dummy</i>.</p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head>
            </head>
            <body>
            <div class='justified-text'>
              <p> The analysis creates the dummy variables of one or more categorical variables:
              one variable for each category, equal to 1 if the observation has that category
              and 0 otherwise. They are named <i>variable_category</i> and are continuous, so they
              can enter the hierarchical cluster analysis with any distance.</p>

              <p> All categories are created, not one fewer as in regression models: in the
              analyses of the module every category has to be represented. Where the original
              variable is missing its dummies are missing too, instead of being 0.</p>

              <p> With <i>Multiple response</i> each cell may contain several options separated by
              the separator, as in Google Forms questions that allow several answers
              (<i>Instagram, TikTok</i>), and a dummy is created for each option. Options chosen
              by very few respondents, such as the free answers of the Other option, can be
              grouped into a single <i>altro</i> dummy. An option that itself contains the
              separator is split in two.</p>

              <p> To add the dummies to the dataset, tick <i>Create the dummy variables</i>.</p>
            </div>
            </body>
            </html>"
        ))
      },

      .run = function() {
        vars <- as.character(unlist(self$options$vars))
        if (is.null(self$data) || length(vars) == 0) return()

        multi <- isTRUE(self$options$multi)
        sep <- self$options$sep
        if (multi && (is.null(sep) || !nzchar(sep))) {
          jmvcore::reject(.tr(
            it = "Indicare il separatore delle opzioni, per esempio la virgola usata da Moduli Google.",
            en = "Enter the separator of the options, for example the comma used by Google Forms."
          ), code = "")
        }
        min_altro <- self$options$minAltro

        tabella <- self$results$dummies
        dummy <- list()
        descrizioni <- character(0)

        for (v in vars) {
          dv <- .dummy_di(self$data[[v]], multi, sep, min_altro)

          if (length(dv$rare) > 0) {
            elenco <- paste(head(dv$rare, 20), collapse = ", ")
            if (length(dv$rare) > 20) elenco <- paste0(elenco, ", ...")
            tabella$setNote(paste0("altro_", v), sprintf(.tr(
              it = "%s: in «%s» sono riunite %d opzioni scelte meno di %d volte: %s.",
              en = "%s: «%s» groups %d options chosen fewer than %d times: %s."
            ), v, dv$nome_altro, length(dv$rare), min_altro, elenco))
          }
          if (length(dv$livelli) > 50) {
            jmvcore::reject(sprintf(.tr(
              it = "La variabile '%s' darebbe %d dummy: con così tante colonne il dataset diventa ingestibile. Accorpare le modalità rare prima di creare le dummy; se è una domanda a risposta multipla, attivare Risposta multipla.",
              en = "The variable '%s' would give %d dummies: with so many columns the dataset becomes unmanageable. Merge the rare categories before creating the dummies; if it is a multiple-response question, tick Multiple response."
            ), v, length(dv$livelli)), code = "")
          }

          n_validi <- sum(!dv$manca)
          for (i in seq_along(dv$livelli)) {
            lv <- dv$livelli[i]
            d <- dv$valori[[i]]
            nome <- paste0(v, "_", .nome_modalita(lv))
            nome <- utils::tail(make.unique(c(names(dummy), nome), sep = "_"), 1)
            dummy[[nome]] <- d
            descrizioni <- c(descrizioni, sprintf(.tr(
              it = "%s: %s (1 = sì, 0 = no)",
              en = "%s: %s (1 = yes, 0 = no)"
            ), v, lv))
            n1 <- sum(d, na.rm = TRUE)
            tabella$addRow(rowKey = nome, values = list(
              var = v,
              level = lv,
              name = nome,
              n1 = n1,
              perc1 = if (n_validi > 0) n1 / n_validi else NaN,
              nmiss = sum(dv$manca)
            ))
          }
        }

        uscita <- self$results$dummiesOV
        if (isTRUE(self$options$dummiesOV) && uscita$isNotFilled() && length(dummy) > 0) {
          nomi <- names(dummy)
          uscita$set(keys = nomi, titles = nomi, descriptions = descrizioni,
                     measureTypes = rep("continuous", length(nomi)))
          uscita$setRowNums(rownames(self$data))
          for (i in seq_along(nomi))
            uscita$setValues(index = i, dummy[[i]])
        }
      }
    )
  )
}

# Le dummy di una variabile: per ciascuna modalità, o per ciascuna opzione
# con la risposta multipla, un vettore 0/1 con NA dove la variabile manca.
# Con la risposta multipla le opzioni scelte meno di `min_altro` volte
# finiscono in «altro», o nell'opzione che si chiama già così.
.dummy_di <- function(x, multi = FALSE, sep = ",", min_altro = 2) {
  valori <- as.character(x)
  valori[!is.na(valori) & !nzchar(trimws(valori))] <- NA
  manca <- is.na(valori)
  rare <- character(0)
  nome_altro <- NA_character_

  if (multi) {
    scelte <- lapply(strsplit(valori, sep, fixed = TRUE), function(p) {
      p <- trimws(p[!is.na(p)])
      unique(p[nzchar(p)])
    })
    conta <- table(unlist(scelte))
    # le opzioni più scelte per prime; a parità, in ordine alfabetico
    conta <- conta[order(-as.vector(conta), names(conta))]
    rare <- names(conta)[conta < min_altro]
    livelli <- setdiff(names(conta), rare)
    gia_altro <- livelli[tolower(livelli) == "altro"]
    nome_altro <- if (length(gia_altro) > 0) gia_altro[1] else "altro"
    if (length(rare) > 0 && length(gia_altro) == 0)
      livelli <- c(livelli, nome_altro)
    presente <- function(lv) {
      cerca <- if (length(rare) > 0 && lv == nome_altro) c(lv, rare) else lv
      vapply(scelte, function(p) any(p %in% cerca), logical(1))
    }
  } else {
    livelli <- if (is.factor(x)) levels(droplevels(x)) else sort(unique(valori[!manca]))
    livelli <- livelli[nzchar(trimws(livelli))]
    presente <- function(lv) !is.na(valori) & valori == lv
  }

  valori_dummy <- lapply(livelli, function(lv) {
    d <- as.integer(presente(lv))
    d[manca] <- NA
    d
  })
  list(livelli = livelli, valori = valori_dummy, manca = manca,
       rare = rare, nome_altro = nome_altro)
}

# La parte del nome di una dummy che viene dalla modalità: lettere e cifre,
# con un trattino basso al posto di spazi, virgole e altri simboli.
.nome_modalita <- function(lv) {
  n <- gsub("[^[:alnum:]]+", "_", trimws(lv))
  n <- gsub("^_+|_+$", "", n)
  if (nzchar(n)) n else "modalita"
}
