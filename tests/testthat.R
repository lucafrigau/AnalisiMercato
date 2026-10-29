library(testthat)
library(AnalisiMercato)

# I messaggi del modulo sono bilingui via .tr() in R/00-i18n.R, con
# l'italiano come default e l'inglese attivabile con
# ANALISIMERCATO_LANG=en. I match di expect_error nei test accettano
# entrambe le lingue, quindi la suite passa in ogni configurazione.

test_check("AnalisiMercato")
