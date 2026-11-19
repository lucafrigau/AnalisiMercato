# Limiti delle opzioni numeriche delle analisi, controllati dal modulo.
#
# Nei .a.yaml le opzioni non hanno `min` e `max`: con quelli jmvcore
# controllerebbe da sé i valori e, se fuori, risponderebbe in inglese e con
# il nome interno dell'opzione («distMin must be between 1 and Inf (is
# 0)»). Qui il messaggio è nella lingua di jamovi (italiano o inglese) e
# nomina l'opzione come la vede lo studente nel pannello. Ogni analisi chiama .controlla_limiti() all'inizio
# di .init.
#
# Per ogni opzione: `min` e `max` (assenti = nessun limite), `aperto = TRUE`
# se il minimo è escluso, e il soggetto della frase in italiano e in inglese.
# Le soglie sono quelle che stavano nei .a.yaml; i minimi minuscoli che
# servivano solo a escludere lo zero (1e-06) sono diventati `aperto`.

.limiti_opzioni <- list(
  catdes = list(
    threshold = list(min = 0, max = 100, it = "La soglia di significatività",
                     en = "The significance threshold")),
  confint = list(
    n_manual = list(min = 2, it = "La numerosità campionaria n", en = "The sample size n"),
    p_manual = list(min = 0, max = 1, it = "La proporzione campionaria", en = "The sample proportion"),
    sd_manual = list(min = 0, it = "Lo scarto quadratico medio campionario s",
                     en = "The sample standard deviation s"),
    N = list(min = 2, it = "La dimensione della popolazione N", en = "The population size N"),
    confidence = list(min = 50, max = 99.99, it = "Il livello di confidenza",
                      en = "The confidence level")),
  deff = list(
    var_complex = list(min = 0, it = "La varianza nel piano complesso",
                       en = "The variance under the complex design"),
    var_srs = list(min = 0, aperto = TRUE, it = "La varianza nel SCR di riferimento",
                   en = "The variance under the reference SRS"),
    N = list(min = 2, it = "La popolazione N", en = "The population N"),
    n_total = list(min = 1, it = "La numerosità del campione n", en = "The sample size n"),
    rho = list(min = -1, max = 1, it = "Il coefficiente di correlazione intra",
               en = "The intra-class correlation coefficient"),
    n_within = list(min = 1, it = "Il numero di unità per gruppo",
                    en = "The number of units per group"),
    L = list(min = 2, it = "Il numero di strati L", en = "The number of strata L"),
    R2 = list(min = 0, max = 1, it = "L'R²", en = "The R²"),
    n_srs = list(min = 1, it = "La numerosità di riferimento n",
                 en = "The reference sample size n")),
  dummies = list(
    minAltro = list(min = 1, it = "Il numero di volte sotto cui un'opzione va in «altro»",
                    en = "The number of times below which an option goes into “altro”")),
  hc = list(
    n_clusters = list(min = 2, it = "Il numero di gruppi", en = "The number of groups")),
  mvoutliers = list(
    alpha = list(min = 0, max = 0.5, aperto = TRUE, it = "La soglia di probabilità",
                 en = "The probability threshold")),
  pca = list(
    ncp = list(min = 1, max = 5, it = "Il numero di componenti da ritenere",
               en = "The number of components to retain"),
    top_ind = list(min = 1, max = 1000, it = "Il numero massimo di osservazioni da mostrare",
                   en = "The maximum number of observations to show"),
    axis_x = list(min = 1, it = "La componente sull'asse X", en = "The component on the X axis"),
    axis_y = list(min = 1, it = "La componente sull'asse Y", en = "The component on the Y axis"),
    map_width = list(min = 300, max = 1600, it = "La larghezza della mappa",
                     en = "The map width"),
    map_height = list(min = 300, max = 1600, it = "L'altezza della mappa",
                      en = "The map height")),
  respquality = list(
    seqPerc = list(min = 1, max = 100,
                   it = "La percentuale di item con la stessa risposta di fila",
                   en = "The percentage of items with the same answer in a row"),
    missPerc = list(min = 1, max = 100, it = "La percentuale di risposte mancanti",
                    en = "The percentage of missing answers"),
    distMin = list(min = 1, it = "La distanza dalla diagonale che conta come segnale",
                   en = "The distance from the diagonal counted as a signal"),
    minSegnali = list(min = 1, it = "Il numero di segnali per elencare un rispondente",
                      en = "The number of signals for listing a respondent")),
  samplecluster = list(
    ng = list(min = 1, it = "Il numero di grappoli da estrarre",
              en = "The number of clusters to draw"),
    fg = list(min = 0.0001, max = 1, it = "La frazione di grappoli f_g",
              en = "The fraction of clusters f_g")),
  samplemultistage = list(
    ng = list(min = 1, it = "Il numero di PSU da estrarre", en = "The number of PSUs to draw"),
    fg = list(min = 0.0001, max = 1, it = "La frazione di PSU f_g", en = "The fraction of PSUs f_g"),
    b = list(min = 1, it = "Il numero di unità per PSU b",
             en = "The number of units per PSU b"),
    fb = list(min = 0.0001, max = 1, it = "La frazione di unità per PSU f_b",
              en = "The fraction of units per PSU f_b")),
  sampleppv = list(
    n = list(min = 1, it = "La numerosità campionaria n", en = "The sample size n"),
    f = list(min = 0.0001, max = 1, it = "La frazione di campionamento f",
             en = "The sampling fraction f")),
  samplesimple = list(
    n = list(min = 1, it = "La numerosità campionaria n", en = "The sample size n"),
    f = list(min = 0.0001, max = 1, it = "La frazione di campionamento f",
             en = "The sampling fraction f")),
  samplesize = list(
    N = list(min = 2, it = "La dimensione della popolazione N", en = "The population size N"),
    delta = list(min = 0, aperto = TRUE, it = "Il margine di errore Δ",
                 en = "The margin of error Δ"),
    confidence = list(min = 50, max = 99.99, it = "Il livello di confidenza",
                      en = "The confidence level"),
    prop_P = list(min = 0, max = 1, it = "La stima della proporzione P",
                  en = "The estimate of the proportion P"),
    mean_sigma = list(min = 0, aperto = TRUE, it = "Lo scarto quadratico medio σ",
                      en = "The standard deviation σ")),
  samplestrat = list(
    n = list(min = 1, it = "La numerosità campionaria totale n", en = "The total sample size n"),
    f = list(min = 0.0001, max = 1, it = "La frazione di campionamento f",
             en = "The sampling fraction f")),
  samplesyst = list(
    n = list(min = 1, it = "La numerosità campionaria n", en = "The sample size n"),
    f = list(min = 0.0001, max = 1, it = "La frazione di campionamento f",
             en = "The sampling fraction f"))
)

# Ferma l'analisi, con un messaggio nella lingua di jamovi, se un'opzione
# numerica è fuori dai suoi limiti.
.controlla_limiti <- function(analisi, options) {
  numero <- function(x) format(x, scientific = FALSE, drop0trailing = TRUE, trim = TRUE,
                               decimal.mark = .tr(it = ",", en = "."))
  for (nome in names(.limiti_opzioni[[analisi]])) {
    l <- .limiti_opzioni[[analisi]][[nome]]
    v <- options[[nome]]
    if (is.null(v) || length(v) != 1 || is.na(v)) next
    aperto <- isTRUE(l$aperto)
    sotto <- !is.null(l$min) && (if (aperto) v <= l$min else v < l$min)
    sopra <- !is.null(l$max) && v > l$max
    if (!sotto && !sopra) next
    regola <- if (!is.null(l$min) && !is.null(l$max)) {
      if (aperto) sprintf(.tr(it = "maggiore di %s e al massimo %s",
                              en = "greater than %s and at most %s"), numero(l$min), numero(l$max))
      else sprintf(.tr(it = "compreso fra %s e %s", en = "between %s and %s"),
                   numero(l$min), numero(l$max))
    } else if (!is.null(l$min)) {
      if (aperto) sprintf(.tr(it = "maggiore di %s", en = "greater than %s"), numero(l$min))
      else sprintf(.tr(it = "almeno %s", en = "at least %s"), numero(l$min))
    } else {
      sprintf(.tr(it = "al massimo %s", en = "at most %s"), numero(l$max))
    }
    jmvcore::reject(sprintf(.tr(
      it = "%s deve essere %s: %s non è un valore ammesso.",
      en = "%s must be %s: %s is not an allowed value."
    ), .tr(it = l$it, en = l$en), regola, numero(v)), code = "")
  }
}
