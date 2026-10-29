# =============================================================================
# Costruisce i dataset di esempio del modulo in formato .omv.
#
# Perché non i CSV: nel CSV la NATURA delle variabili non è scritta da
# nessuna parte, e jamovi deve indovinarla. I codici numerici (i punteggi
# Likert, gli anni di fedeltà) verrebbero letti come continui o nominali a
# seconda del caso, e lo studente si troverebbe a sistemare i tipi a mano
# prima di ogni esercizio. Il formato .omv porta con sé tipo di misura,
# tipo di dato, etichette dei livelli e descrizione di ciascuna variabile.
#
# Scelta deliberata: gli item Likert sono dichiarati CONTINUI, non ordinali.
# jamovi passa a R le variabili ordinali come fattori, e la cluster analysis
# e la PCA della guida li usano come quantitativi (distanza euclidea su
# punteggi 1-7): dichiararli ordinali farebbe rifiutare l'analisi.
#
# Sorgente: data-raw/*.csv   ->   destinazione: data/*.omv
# Uso: Rscript tools/genera-dataset-omv.R
# =============================================================================

if (!requireNamespace("jmvReadWrite", quietly = TRUE))
  stop("Serve il pacchetto jmvReadWrite: install.packages('jmvReadWrite')")

in_dir  <- "data-raw"
out_dir <- "data"
dir.create(out_dir, showWarnings = FALSE)

# I livelli dichiarati devono coprire TUTTI i valori presenti: se non lo
# fanno, factor() trasformerebbe silenziosamente i valori non elencati in
# NA. Meglio fermarsi qui che spedire un dataset con dei buchi.
fattore <- function(v, nm, livelli, ordinato) {
  osservati <- sort(unique(v[!is.na(v)]))
  if (is.null(livelli)) livelli <- osservati
  fuori <- setdiff(osservati, livelli)
  if (length(fuori))
    stop(sprintf("%s: valori non previsti fra i livelli dichiarati (%s)",
                 nm, paste(fuori, collapse = ", ")))
  factor(v, levels = livelli, ordered = ordinato)
}

# tipo = "ID" | "nominale" | "ordinale" | "continua"
prepara <- function(df, tipi, descrizioni, livelli = list()) {
  mancanti <- setdiff(names(df), names(tipi))
  if (length(mancanti))
    stop("Variabili senza tipo dichiarato: ", paste(mancanti, collapse = ", "))

  for (nm in names(df)) {
    v <- df[[nm]]
    tipo <- tipi[[nm]]
    df[[nm]] <- switch(
      tipo,
      "ID"        = { x <- as.character(v); attr(x, "measureType") <- "ID"; x },
      "nominale"  = fattore(v, nm, livelli[[nm]], ordinato = FALSE),
      "ordinale"  = fattore(v, nm, livelli[[nm]], ordinato = TRUE),
      "continua"  = if (is.integer(v) || all(v == round(v), na.rm = TRUE))
                      as.integer(v) else as.numeric(v),
      stop("Tipo sconosciuto: ", tipo)
    )
    if (!is.null(descrizioni[[nm]]))
      attr(df[[nm]], "jmv-desc") <- descrizioni[[nm]]
  }
  df
}

scrivi <- function(df, nome) {
  path <- file.path(out_dir, paste0(nome, ".omv"))
  jmvReadWrite::write_omv(df, path, frcWrt = TRUE)
  cat(sprintf("  %-26s %4d righe x %2d variabili  (%d KB)\n",
              basename(path), nrow(df), ncol(df),
              round(file.info(path)$size / 1024)))
}

leggi <- function(nome)
  utils::read.csv(file.path(in_dir, paste0(nome, ".csv")),
                  stringsAsFactors = FALSE, fileEncoding = "UTF-8")

aree <- c("Nord-Ovest", "Nord-Est", "Centro", "Sud", "Isole")

# --- 1. popolazione_clienti: la lista da cui si estraggono i campioni -------
d <- leggi("popolazione_clienti")
scrivi(prepara(
  d,
  tipi = list(id_cliente = "ID", area = "nominale", eta = "continua",
              sesso = "nominale", reddito_k = "continua",
              spesa_annua = "continua", punto_vendita = "nominale",
              fedelta_anni = "continua"),
  descrizioni = list(
    id_cliente    = "Identificativo del cliente: la variabile da indicare come Variabile identificativa nelle analisi di campionamento",
    area          = "Area geografica: variabile di stratificazione",
    eta           = "Eta in anni compiuti",
    sesso         = "Sesso del cliente",
    reddito_k     = "Reddito annuo in migliaia di euro: possibile variabile ausiliaria per l'allocazione di Neyman",
    spesa_annua   = "Spesa annua in euro: la variabile di interesse y",
    punto_vendita = "Punto vendita di riferimento: il grappolo (PSU) nei disegni a grappoli e a due stadi",
    fedelta_anni  = "Anni di iscrizione al programma fedelta: utile come variabile di ordinamento nel sistematico"),
  livelli = list(area = aree)
), "popolazione_clienti")

# --- 2. comuni_strati: unita di secondo livello per strati e grappoli -------
d <- leggi("comuni_strati")
scrivi(prepara(
  d,
  tipi = list(id_comune = "ID", area = "nominale", popolazione = "continua",
              reddito_medio_k = "continua", num_punti_vendita = "continua"),
  descrizioni = list(
    id_comune         = "Identificativo del comune",
    area              = "Area geografica: la variabile di strato",
    popolazione       = "Abitanti del comune: misura di dimensione per il campionamento con probabilita variabili",
    reddito_medio_k   = "Reddito medio in migliaia di euro: variabile ausiliaria per l'allocazione di Neyman",
    num_punti_vendita = "Numero di punti vendita nel comune"),
  livelli = list(area = aree)
), "comuni_strati")

# --- 3. survey_segmentazione: base per cluster analysis e PCA --------------
d <- leggi("survey_segmentazione")
item <- c("qualita_prima_di_prezzo", "marca_conta_molto", "made_in_italy_importante",
          "compro_online_spesso", "consegna_a_casa_essenziale", "fedele_alle_marche",
          "preferisco_negozio_fisico", "cerco_sempre_le_offerte")
tipi <- c(list(id_rispondente = "ID", eta = "continua", sesso = "nominale",
               reddito_k = "continua", area = "nominale", segmento_vero = "nominale"),
          setNames(as.list(rep("continua", length(item))), item))
descr <- c(list(
  id_rispondente = "Identificativo del rispondente",
  eta            = "Eta in anni compiuti",
  sesso          = "Sesso del rispondente",
  reddito_k      = "Reddito annuo in migliaia di euro",
  area           = "Area geografica: variabile qualitativa supplementare nella PCA",
  segmento_vero  = "Segmento di appartenenza noto per costruzione: serve come termine di confronto per l'Adjusted Rand Index"),
  setNames(lapply(item, function(x)
    "Punteggio su scala 1-7 (1 = per niente d'accordo, 7 = completamente d'accordo)"), item))
scrivi(prepara(d, tipi, descr,
               livelli = list(area = aree)),
       "survey_segmentazione")

# --- 4. panel_prodotti: mappa di posizionamento (PCA) ----------------------
d <- leggi("panel_prodotti")
attributi <- setdiff(names(d), c("marca", "posizionamento"))
tipi <- c(list(marca = "ID", posizionamento = "nominale"),
          setNames(as.list(rep("continua", length(attributi))), attributi))
descr <- c(list(
  marca          = "Marca del prodotto: da indicare come Variabile identificativa per etichettare i punti nel biplot",
  posizionamento = "Fascia di posizionamento dichiarata: variabile qualitativa supplementare"),
  setNames(lapply(attributi, function(x)
    "Punteggio medio attribuito dai consumatori alla marca su questo attributo"), attributi))
scrivi(prepara(d, tipi, descr,
               livelli = list(posizionamento = c("Mass", "Bio", "Funzionale", "Premium"))),
       "panel_prodotti")

cat("\nFatto. I file .omv sono in", normalizePath(out_dir), "\n")
