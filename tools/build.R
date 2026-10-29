# =============================================================================
# Compilazione e installazione del modulo.
#
# Perché non basta jmvtools::install(): jmvtools (la 2.6.17 come la 2.7.26
# oggi in uso) non copia `jamovi/refs.yaml` dentro il .jmo. Le analisi
# dichiarano le proprie fonti con delle CHIAVI (`refs: [cochran, lohr]`)
# che jamovi risolve leggendo il file `refs.yaml` nella radice del modulo
# — è la stessa struttura del modulo ufficiale jmv. Senza quel file le
# chiavi non hanno nulla su cui risolversi e i riferimenti non compaiono.
#
# Questo script fa quindi i tre passi in sequenza:
#   1. prepare  (rigenera .h.R, .src.js e 0000.yaml)
#   2. build    (compila il .jmo senza installarlo: lo installa il passo 4)
#   3. aggiunge al .jmo i file che jmvtools non copia: refs.yaml (le fonti
#      bibliografiche) e data/ (i dataset di esempio)
#   4. estrae il .jmo nella cartella dei moduli di jamovi
#   5. sposta il .jmo in mac/ con il suffisso della piattaforma: compilato
#      su questo Mac, funziona solo sui Mac Apple Silicon
#   6. ricava da quello le versioni per Mac Intel, Windows e Linux, in mac/,
#      windows/ e linux/ (tools/build-altre-piattaforme.R)
#
# Perche' non ci si fida dell'installazione di jmvtools: su questa macchina
# l'installatore di jamovi fallisce con un errore di architettura
# ("mach-o file, but is an incompatible architecture (have 'arm64', need
# 'x86_64')") ma jmvtools stampa ugualmente "Module installed successfully".
# Il risultato e' che il modulo installato resta alla versione precedente
# senza che nulla lo segnali. Lo script quindi installa da se' il .jmo
# scompattandolo, e alla fine verifica che la versione installata sia
# davvero quella appena compilata.
#
# Per lo stesso motivo non si chiama jmvtools::install(), ma la modalità
# --build del compilatore, identica tranne che per l'installazione. Con
# jamovi chiuso l'installatore avvia un'istanza di jamovi che non riesce a
# partire ma resta aperta, e la compilazione si blocca finché qualcuno non
# la termina.
#
# Uso:  Rscript tools/build.R
# =============================================================================

home <- "/Applications/jamovi.app"
pkg  <- normalizePath(".")
nome <- read.dcf("DESCRIPTION")[1, "Package"]
ver  <- read.dcf("DESCRIPTION")[1, "Version"]

jmvtools::prepare(pkg)
# Gli stessi argomenti che passa jmvtools::install() (--home, --rpath), con
# --build al posto di --install.
jmc <- system.file("node_modules", "jamovi-compiler", "index.js",
                   package = "jmvtools")
tra_virgolette <- function(x) paste0("\"", x, "\"")
esito <- system2(node::node(),
                 c(tra_virgolette(jmc), "--build", tra_virgolette(pkg),
                   "--home", tra_virgolette(home),
                   "--rpath", tra_virgolette(R.home("bin"))))
if (esito != 0) stop("Compilazione del modulo non riuscita")

jmo <- file.path(pkg, sprintf("%s_%s.jmo", nome, ver))
if (!file.exists(jmo)) stop("Non trovo il .jmo appena compilato: ", jmo)

# jamovi cerca i dataset di esempio in <modulo>/data/<file> e le fonti
# bibliografiche in <modulo>/refs.yaml: entrambi vanno aggiunti a mano.
aggiungi_al_jmo <- function(destinazione_zip, percorsi) {
  staging <- file.path(tempdir(), "jmo-extra")
  unlink(staging, recursive = TRUE)
  dir.create(file.path(staging, nome), recursive = TRUE)
  dentro <- character(0)
  for (p in percorsi) {
    if (!file.exists(p)) stop("File da includere non trovato: ", p)
    if (dir.exists(p)) {
      file.copy(p, file.path(staging, nome), recursive = TRUE)
      dentro <- c(dentro, file.path(nome, basename(p)))
    } else {
      file.copy(p, file.path(staging, nome, basename(p)))
      dentro <- c(dentro, file.path(nome, basename(p)))
    }
  }
  vecchia_dir <- setwd(staging)
  on.exit(setwd(vecchia_dir), add = TRUE)
  utils::zip(destinazione_zip, dentro, flags = "-qr")
}
aggiungi_al_jmo(jmo, c("jamovi/refs.yaml", "data"))

# installazione: si scompatta il .jmo sopra la cartella dei moduli
moduli    <- file.path(path.expand("~"), "Library/Application Support",
                       "jamovi/modules")
installato <- file.path(moduli, nome)
if (!dir.exists(moduli)) stop("Cartella dei moduli di jamovi non trovata: ", moduli)
unlink(installato, recursive = TRUE)
utils::unzip(jmo, exdir = moduli)

ver_installata <- yaml::read_yaml(file.path(installato, "jamovi.yaml"))$version
if (!identical(as.character(ver_installata), as.character(ver)))
  stop("Installazione non riuscita: in jamovi risulta la versione ",
       ver_installata, " invece della ", ver)

presenti <- utils::unzip(jmo, list = TRUE)$Name
cat("\n", nome, " ", ver, "\n",
    "  refs.yaml nel .jmo:        ", any(grepl("/refs[.]yaml$", presenti)), "\n",
    "  dataset .omv nel .jmo:     ", sum(grepl("/data/.+[.]omv$", presenti)), "\n",
    "  refs.yaml installato:      ", file.exists(file.path(installato, "refs.yaml")), "\n",
    "  dataset .omv installati:   ",
    length(list.files(file.path(installato, "data"), pattern = "omv$")), "\n",
    "  versione installata:       ", ver_installata, "\n",
    sep = "")

# Il suffisso distingue i file destinati a sistemi diversi quando vengono
# distribuiti fuori dalle cartelle. L'architettura si legge da rVersion.
rv <- grep("^rVersion: ", readLines(unz(jmo, file.path(nome, "jamovi.yaml")),
                                    encoding = "UTF-8", warn = FALSE),
           value = TRUE)
suffisso <- if (endsWith(rv, "-arm64")) "mac-apple-silicon" else "mac-intel"
jmo_mac <- sprintf("%s_%s_%s.jmo", nome, ver, suffisso)
dir.create(file.path(pkg, "mac"), showWarnings = FALSE)
if (!file.rename(jmo, file.path(pkg, "mac", jmo_mac)))
  stop("Non riesco a spostare ", basename(jmo), " in mac/")
cat("  .jmo per Mac:              mac/", jmo_mac, "\n\n", sep = "")

source(file.path(pkg, "tools", "build-altre-piattaforme.R"), local = new.env())
