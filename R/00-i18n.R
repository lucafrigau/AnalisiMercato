# Helper minimale per testi bilingui (it/en) nei pannelli HTML di
# istruzioni e nei messaggi di rifiuto del modulo AnalisiMercato.
#
# I .yaml e i title delle tabelle passano dal sistema i18n nativo di
# jamovi (cataloghi .po in jamovi/i18n/) e non hanno bisogno di questa
# funzione. Le stringhe lunghe definite *dentro* il codice R (HTML in
# setContent, messaggi reject) non vengono estratte automaticamente
# dal i18nUpdate e qui forniamo una versione bilingue inline.
#
# LINGUA DI DEFAULT: ITALIANO. Il modulo nasce per il corso di Analisi
# di Mercato e i suoi utenti sono italiani anche quando il sistema
# operativo è configurato in inglese — caso molto comune su macOS.
# Legare la lingua alla locale di sistema faceva comparire messaggi
# inglesi a studenti italiani: si parte quindi dall'italiano e
# l'inglese va richiesto esplicitamente.
#
# Per ottenere l'inglese impostare, prima di avviare jamovi, la
# variabile d'ambiente ANALISIMERCATO_LANG=en (qualsiasi altro valore,
# o la sua assenza, significa italiano).

.tr <- function(it, en) {
  lang <- tryCatch(Sys.getenv("ANALISIMERCATO_LANG", ""),
                   error = function(e) "")
  if (grepl("^en", lang, ignore.case = TRUE)) en else it
}
