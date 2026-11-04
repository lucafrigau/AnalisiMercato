
# Qualità delle risposte: per ogni rispondente conta i segnali di risposte
# date con poca attenzione (fasi 3, 7 e 9 della preparazione dei dati):
#   - nella batteria di item, una lunga sequenza di risposte uguali e
#     molte risposte mancanti;
#   - nelle coppie di domande di controllo, una distanza grande dalla
#     diagonale della matrice di coerenza.
# Un segnale da solo non basta per escludere qualcuno: l'analisi conta i
# segnali e non esclude nessuno.

respqualityClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "respqualityClass",
    inherit = respqualityBase,
    private = list(
      .init = function() {
        .controlla_limiti("respquality", self$options)
        self$results$instructions$setContent(.tr(
          it = "<html>
            <head>
            </head>
            <body>
            <div class='justified-text'>
              <p> L'analisi cerca i rispondenti che hanno compilato il questionario con poca
              attenzione. Ha due parti, che si usano insieme o da sole.</p>

              <p> <b>Batteria di item.</b> Sono le domande con la stessa scala di risposta poste
              una dopo l'altra, per esempio gli otto item da 1 a 7 di una scala Likert: vanno
              nella casella nell'ordine del questionario. Per ogni rispondente l'analisi conta:
              <ul>
              <li> quante volte di fila dà la stessa risposta. Chi risponde 4, 4, 4, 4, 4, 4, 4,
              4 dà la stessa risposta a 8 item su 8, cioè al 100%; chi risponde 4, 4, 4, 2, 5,
              4, 4, 3 al massimo a 3 di fila, cioè al 38%; </li>
              <li> quante risposte mancano. </li>
              </ul>
              Con la soglia del 100% il segnale scatta solo per chi dà la stessa risposta a
              tutti gli item. Da solo non basta, perché un cliente molto soddisfatto può dare 7 a
              tutto; diventa serio se nella batteria ci sono item formulati al contrario.</p>

              <p> <b>Domande di controllo.</b> Sono coppie di domande che chiedono la stessa
              informazione, con le modalità nello stesso ordine. Per ogni rispondente si misura
              quanto la coppia di risposte è lontana dalla diagonale della matrice di coerenza:
              0 sulla diagonale, 1 sulle celle adiacenti, 2 a due passi, 3 o più per le
              contraddizioni forti. Nella matrice sono rosse le celle che contano come segnale,
              a partire dalla distanza scelta, e gialle quelle da esaminare: con la soglia
              predefinita, 3, il rosso corrisponde alle contraddizioni forti.</p>

              <p> Le soglie oltre cui scatta un segnale si fissano prima di guardare i dati.
              L'analisi non esclude nessuno: di solito un rispondente si esclude solo con più
              segnali insieme, con criteri dichiarati. Il numero di segnali e i singoli
              indicatori si possono aggiungere al dataset.</p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head>
            </head>
            <body>
            <div class='justified-text'>
              <p> The analysis looks for respondents who filled in the questionnaire with little
              attention. It has two parts, used together or on their own.</p>

              <p> <b>Battery of items.</b> These are questions with the same answer scale asked
              one after the other, for example the eight 1-to-7 items of a Likert scale: they go
              in the box in questionnaire order. For each respondent the analysis counts:
              <ul>
              <li> how many times in a row the same answer is given. Answering 4, 4, 4, 4, 4,
              4, 4, 4 gives the same answer to 8 items out of 8, that is 100%; answering 4, 4,
              4, 2, 5, 4, 4, 3 gives it to at most 3 in a row, that is 38%; </li>
              <li> how many answers are missing. </li>
              </ul>
              With the 100% threshold the signal is raised only for respondents who give the
              same answer to every item. On its own it is not enough, because a very satisfied
              customer may give 7 to everything; it becomes serious if the battery contains
              reverse-worded items.</p>

              <p> <b>Control questions.</b> These are pairs of questions asking for the same
              information, with the categories in the same order. For each respondent the
              analysis measures how far the pair of answers is from the diagonal of the
              consistency matrix: 0 on the diagonal, 1 on adjacent cells, 2 two steps away, 3 or
              more for strong contradictions. In the matrix the cells counted as a signal, from
              the chosen distance on, are red and those to examine are yellow: with the default
              threshold, 3, red corresponds to strong contradictions.</p>

              <p> The thresholds beyond which a signal is raised are fixed before looking at the
              data. The analysis excludes nobody: a respondent is usually excluded only with
              several signals together, with declared criteria. The number of signals and the
              single indicators can be added to the dataset.</p>
            </div>
            </body>
            </html>"
        ))

        tabella <- self$results$rispondenti
        coppie <- self$options$pairs
        for (i in seq_along(coppie)) {
          p <- coppie[[i]]
          if (is.null(p$i1) || is.null(p$i2)) next
          tabella$addColumn(name = paste0("d", i), type = "integer",
                            title = sprintf(.tr(it = "Distanza %s – %s",
                                                en = "Distance %s – %s"), p$i1, p$i2))
          self$results$matrici$get(key = p)$setTitle(sprintf(.tr(
            it = "Matrice di coerenza: %s – %s",
            en = "Consistency matrix: %s – %s"
          ), p$i1, p$i2))
        }
      },

      .run = function() {
        items <- as.character(unlist(self$options$items))
        coppie <- Filter(function(p) !is.null(p$i1) && !is.null(p$i2),
                         self$options$pairs)
        if (is.null(self$data) || (length(items) == 0 && length(coppie) == 0))
          return()
        if (length(items) == 1) {
          jmvcore::reject(.tr(
            it = "La batteria deve contenere almeno due item: con uno solo non ci sono sequenze di risposte uguali.",
            en = "The battery must contain at least two items: with only one there are no sequences of equal answers."
          ), code = "")
        }

        n <- nrow(self$data)
        segnali <- integer(n)
        seqmax <- rep(NA_integer_, n)
        mancanti <- rep(NA_integer_, n)
        riepilogo <- self$results$riepilogo

        if (length(items) >= 2) {
          m <- .matrice_risposte(self$data[, items, drop = FALSE])
          k <- ncol(m)
          seqmax <- .sequenza_piu_lunga(m)
          mancanti <- as.integer(rowSums(is.na(m)))
          # soglie in numero di item: la percentuale scelta, arrotondata
          # per eccesso
          soglia_seq <- ceiling(self$options$seqPerc * k / 100)
          soglia_miss <- ceiling(self$options$missPerc * k / 100)
          s_seq <- seqmax >= soglia_seq
          s_miss <- mancanti >= soglia_miss
          segnali <- segnali + s_seq + s_miss
          riepilogo$addRow(rowKey = "seq", values = list(
            segnale = .tr(it = "Stessa risposta di fila", en = "Same answer in a row"),
            criterio = sprintf(.tr(it = "almeno %d item di fila su %d", en = "at least %d items in a row out of %d"),
                               soglia_seq, k),
            n = sum(s_seq), perc = mean(s_seq)))
          riepilogo$addRow(rowKey = "miss", values = list(
            segnale = .tr(it = "Risposte mancanti", en = "Missing answers"),
            criterio = sprintf(.tr(it = "almeno %d item su %d", en = "at least %d items out of %d"),
                               soglia_miss, k),
            n = sum(s_miss), perc = mean(s_miss)))
        }

        dist_min <- self$options$distMin
        distanze <- list()
        for (i in seq_along(coppie)) {
          p <- coppie[[i]]
          dc <- .distanza_coppia(self$data[[p$i1]], self$data[[p$i2]], p$i1, p$i2)
          s <- !is.na(dc$d) & dc$d >= dist_min
          segnali <- segnali + s
          distanze[[i]] <- dc$d
          validi <- sum(!is.na(dc$d))
          riepilogo$addRow(rowKey = paste0("coppia", i), values = list(
            segnale = sprintf(.tr(it = "Coppia %s – %s", en = "Pair %s – %s"), p$i1, p$i2),
            criterio = sprintf(.tr(it = "distanza dalla diagonale almeno %d",
                                   en = "distance from the diagonal at least %d"), dist_min),
            n = sum(s), perc = if (validi > 0) sum(s) / validi else NaN))
          if (dc$massimo < dist_min)
            riepilogo$setNote(paste0("massimo", i), sprintf(.tr(
              it = "Nella coppia %s – %s la distanza dalla diagonale arriva al massimo a %s: con la soglia %d non può dare segnali.",
              en = "In the pair %s – %s the distance from the diagonal is at most %s: with the threshold %d it cannot raise signals."
            ), p$i1, p$i2, format(dc$massimo), dist_min))

          self$results$matrici$get(key = p)$setState(list(
            tab = dc$tabella, nome1 = p$i1, nome2 = p$i2, dist_min = dist_min))
        }

        riepilogo$setNote("segnali", .tr(
          it = "Un segnale da solo non basta per escludere un rispondente: l'esclusione va decisa con criteri fissati prima di guardare i dati, di solito in presenza di più segnali insieme.",
          en = "A single signal is not enough to exclude a respondent: exclusion has to be decided with criteria fixed before looking at the data, usually when several signals occur together."
        ))

        # elenco dei rispondenti con più segnali, dai più segnalati
        righe <- as.integer(rownames(self$data))
        tabella <- self$results$rispondenti
        min_segnali <- self$options$minSegnali
        sel <- which(segnali >= min_segnali)
        sel <- sel[order(-segnali[sel], righe[sel])]
        for (j in sel) {
          valori <- list(riga = righe[j], segnali = segnali[j],
                         seqmax = seqmax[j], mancanti = mancanti[j])
          for (i in seq_along(distanze))
            valori[[paste0("d", i)]] <- distanze[[i]][j]
          tabella$addRow(rowKey = j, values = valori)
        }
        # jamovi non mostra le note di una tabella senza righe: il messaggio
        # va nel riepilogo e la tabella vuota si nasconde
        tabella$setVisible(length(sel) > 0)
        if (length(sel) == 0)
          riepilogo$setNote("nessuno", sprintf(.tr(
            it = "Nessun rispondente con almeno %d segnali.",
            en = "No respondent with at least %d signals."
          ), min_segnali))

        uscita <- self$results$segnaliOV
        if (isTRUE(self$options$segnaliOV) && uscita$isNotFilled()) {
          uscita$setRowNums(rownames(self$data))
          uscita$setValues(segnali)
        }

        uscita <- self$results$indicatoriOV
        if (isTRUE(self$options$indicatoriOV) && uscita$isNotFilled()) {
          chiavi <- character(0)
          titoli <- character(0)
          descrizioni <- character(0)
          valori <- list()
          if (length(items) >= 2) {
            chiavi <- c("seqmax", "mancanti")
            titoli <- c("di_fila", "mancanti")
            descrizioni <- c(
              .tr(it = "Massimo numero di item di fila con la stessa risposta nella batteria",
                  en = "Largest number of items in a row with the same answer in the battery"),
              .tr(it = "Risposte mancanti nella batteria",
                  en = "Missing answers in the battery"))
            valori <- list(seqmax, mancanti)
          }
          for (i in seq_along(coppie)) {
            p <- coppie[[i]]
            chiavi <- c(chiavi, paste0("d", i))
            titoli <- c(titoli, paste0("dist_", p$i1, "_", p$i2))
            descrizioni <- c(descrizioni, sprintf(.tr(
              it = "Distanza dalla diagonale nella coppia %s – %s",
              en = "Distance from the diagonal in the pair %s – %s"), p$i1, p$i2))
            valori <- c(valori, list(distanze[[i]]))
          }
          if (length(chiavi) > 0) {
            uscita$set(keys = chiavi, titles = titoli, descriptions = descrizioni,
                       measureTypes = rep("continuous", length(chiavi)))
            uscita$setRowNums(rownames(self$data))
            for (i in seq_along(chiavi))
              uscita$setValues(index = i, valori[[i]])
          }
        }
      },

      .plotMatrice = function(image, ...) {
        st <- image$state
        if (is.null(st)) return(FALSE)
        tab <- st$tab
        # I colori seguono la soglia scelta: rosso per le celle che contano
        # come segnale, giallo per quelle fra 2 e la soglia, da esaminare.
        # Con la soglia predefinita, 3, sono i colori della matrice di
        # coerenza della dispensa.
        soglia <- st$dist_min
        etichette <- c(
          coerente    = .tr(it = "0: coerente", en = "0: consistent"),
          accettabile = .tr(it = "1: accettabile", en = "1: acceptable"),
          esaminare   = if (soglia - 1 == 2) .tr(it = "2: da esaminare", en = "2: to examine")
                        else sprintf(.tr(it = "da 2 a %d: da esaminare", en = "2 to %d: to examine"),
                                     soglia - 1),
          segnale     = sprintf(.tr(it = "%d o più: segnale", en = "%d or more: signal"), soglia))
        colori <- c(coerente = "#5B9BD5", accettabile = "#BDD7EE",
                    esaminare = "#FFD966", segnale = "#F4A6A6")
        presenti <- c("coerente", if (soglia > 1) "accettabile",
                      if (soglia > 2) "esaminare", "segnale")
        classe <- ifelse(tab$dist == 0, "coerente",
                  ifelse(tab$dist >= soglia, "segnale",
                  ifelse(tab$dist < 2, "accettabile", "esaminare")))
        tab$classe <- factor(etichette[classe], levels = etichette[presenti])
        a_capo <- function(s) vapply(s, function(x) paste(strwrap(x, 14), collapse = "\n"), "")
        # le modalità lunghe si scrivono in obliquo, i codici numerici no
        obliquo <- max(nchar(tab$x)) > 3
        tab$x <- factor(a_capo(tab$x), levels = unique(a_capo(tab$x)))
        tab$y <- factor(a_capo(tab$y), levels = rev(unique(a_capo(tab$y))))
        ggplot2::ggplot(tab, ggplot2::aes(x = x, y = y)) +
          ggplot2::geom_tile(ggplot2::aes(fill = classe), colour = "white", linewidth = 0.8) +
          ggplot2::geom_text(ggplot2::aes(label = n), size = 4.5) +
          ggplot2::scale_fill_manual(
            values = stats::setNames(colori[presenti], etichette[presenti]),
            drop = FALSE, name = NULL) +
          ggplot2::labs(x = st$nome1, y = st$nome2) +
          ggplot2::theme_minimal(base_size = 12) +
          ggplot2::theme(panel.grid = ggplot2::element_blank(),
                         legend.position = "bottom",
                         axis.text.x = if (obliquo) ggplot2::element_text(angle = 30, hjust = 1)
                                       else ggplot2::element_text())
      }
    )
  )
}

# Le risposte della batteria come matrice di testo (righe = rispondenti),
# con NA per le risposte mancanti o vuote: per contare risposte uguali e
# mancanti basta confrontare i valori, qualunque sia il tipo della variabile.
.matrice_risposte <- function(dati) {
  m <- vapply(dati, function(x) {
    s <- as.character(x)
    s[!is.na(s) & !nzchar(trimws(s))] <- NA
    s
  }, character(nrow(dati)))
  matrix(m, nrow = nrow(dati))
}

# La sequenza più lunga di risposte uguali consecutive in ogni riga; una
# risposta mancante interrompe la sequenza.
.sequenza_piu_lunga <- function(m) {
  as.integer(apply(m, 1, function(r) {
    corse <- rle(r)
    l <- corse$lengths[!is.na(corse$values)]
    if (length(l) == 0) 0L else max(l)
  }))
}

# Distanza dalla diagonale della matrice di coerenza di due domande di
# controllo: la differenza in valore assoluto fra i codici delle risposte.
# I codici sono i valori per le variabili numeriche e per i fattori con
# modalità numeriche, la posizione della modalità per quelli con modalità
# testuali, che devono quindi avere lo stesso numero di modalità.
.distanza_coppia <- function(x1, x2, nome1 = "x1", nome2 = "x2") {
  codifica <- function(x) {
    if (is.factor(x)) {
      num <- suppressWarnings(as.numeric(levels(x)))
      if (!anyNA(num))
        return(list(codici = num[as.integer(x)], livelli = num,
                    etichette = levels(x), testo = FALSE))
      return(list(codici = as.integer(x), livelli = seq_len(nlevels(x)),
                  etichette = levels(x), testo = TRUE))
    }
    v <- sort(unique(x[!is.na(x)]))
    list(codici = as.numeric(x), livelli = v, etichette = format(v), testo = FALSE)
  }
  c1 <- codifica(x1)
  c2 <- codifica(x2)
  if (c1$testo != c2$testo) {
    jmvcore::reject(sprintf(.tr(
      it = "Le domande di controllo %s e %s devono avere modalità dello stesso tipo: entrambe numeriche o entrambe testuali.",
      en = "The control questions %s and %s must have categories of the same type: both numeric or both text."
    ), nome1, nome2), code = "")
  }
  if (c1$testo && length(c1$livelli) != length(c2$livelli)) {
    jmvcore::reject(sprintf(.tr(
      it = "Le domande di controllo %s e %s hanno un numero diverso di modalità (%d e %d): la distanza dalla diagonale si calcola fra domande con lo stesso numero di modalità, nello stesso ordine.",
      en = "The control questions %s and %s have a different number of categories (%d and %d): the distance from the diagonal is computed between questions with the same number of categories, in the same order."
    ), nome1, nome2, length(c1$livelli), length(c2$livelli)), code = "")
  }
  if (!c1$testo) {
    # stessi valori su entrambi gli assi, così la matrice è quadrata
    tutti <- sort(unique(c(c1$livelli, c2$livelli)))
    c1$livelli <- c2$livelli <- tutti
    c1$etichette <- c2$etichette <- format(tutti)
  }
  d <- abs(c1$codici - c2$codici)
  griglia <- expand.grid(i = seq_along(c1$livelli), j = seq_along(c2$livelli))
  griglia$n <- mapply(function(i, j) sum(c1$codici == c1$livelli[i] &
                                           c2$codici == c2$livelli[j], na.rm = TRUE),
                      griglia$i, griglia$j)
  tabella <- data.frame(x = c1$etichette[griglia$i], y = c2$etichette[griglia$j],
                        dist = abs(c1$livelli[griglia$i] - c2$livelli[griglia$j]),
                        n = griglia$n, stringsAsFactors = FALSE)
  massimo <- if (length(c1$livelli) > 0) max(tabella$dist) else 0
  list(d = d, massimo = massimo, tabella = tabella)
}
