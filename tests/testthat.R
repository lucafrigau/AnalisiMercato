library(testthat)
library(AnalisiMercato)

# I messaggi del modulo sono bilingui via .tr() in R/00-i18n.R. Fuori da
# jamovi la lingua viene dalla variabile LANGUAGE e, se è vuota, dal
# sistema, come per i titoli tradotti da jmvcore. I match di expect_error
# nei test accettano entrambe le lingue, quindi la suite passa in ogni
# configurazione.

test_check("AnalisiMercato")
