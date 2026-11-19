# Lingua dei testi generati in R: pannelli HTML di istruzioni, note, messaggi
# di errore, titoli impostati dal codice ed etichette dei grafici.
#
# I testi dei file yaml (menu, opzioni, titoli dei risultati) sono scritti in
# inglese, la lingua originale dei moduli per il client di jamovi, e jamovi li
# traduce con il catalogo jamovi/i18n/it.po. I testi costruiti in R non passano
# dal catalogo: sono scritti nelle due lingue direttamente nel codice, con
# .tr(it = ..., en = ...).
#
# La lingua è la stessa con cui jmvcore traduce i titoli dei risultati, quella
# conservata nell'oggetto delle opzioni (`.lang`): .tr la cerca risalendo le
# chiamate fino al metodo dell'analisi da cui parte. Così titoli e testi sono
# sempre nella stessa lingua: in italiano se il codice comincia con "it", in
# inglese altrimenti.
#
# - In jamovi `.lang` è la lingua di jamovi, che il client passa a ogni
#   analisi.
# - Fuori da jamovi (script R, test) jmvcore la ricava, alla prima traduzione,
#   dalla variabile d'ambiente LANGUAGE o, se è vuota, dalla lingua dei
#   messaggi del sistema (LC_MESSAGES). .tr fa lo stesso quando `.lang` è
#   ancora vuota o quando è chiamata fuori da un'analisi. Per avere il modulo
#   in inglese in uno script: Sys.setenv(LANGUAGE = "en") prima di creare le
#   opzioni dell'analisi.

.tr <- function(it, en) {
  if (.lingua_italiana()) it else en
}

.lingua_italiana <- function() {
  grepl("^it", .codice_lingua(), ignore.case = TRUE)
}

.codice_lingua <- function() {
  # dal più recente al più vecchio: il primo `self` che è un'analisi è
  # quella che sta calcolando o disegnando
  for (frame in rev(sys.frames())) {
    self <- get0("self", envir = frame, inherits = TRUE)
    if (inherits(self, "Analysis")) {
      lang <- tryCatch(self$options$.__enclos_env__$private$.lang,
                       error = function(e) NULL)
      if (is.character(lang) && length(lang) == 1 && !is.na(lang) &&
          nzchar(lang))
        return(lang)
      break
    }
  }
  # la stessa scelta di jmvcore (Options$translate)
  lang <- Sys.getenv("LANGUAGE", "")
  if (nzchar(lang)) return(lang)
  locale <- tryCatch(Sys.getlocale("LC_MESSAGES"), error = function(e) "")
  if (is.character(locale) && length(locale) == 1 && nzchar(locale))
    return(locale)
  "en"
}
