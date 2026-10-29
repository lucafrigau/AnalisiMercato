# =============================================================================
# Versioni per Mac Intel, Windows e Linux, costruite su questo Mac.
#
# jmvtools compila il modulo solo per il sistema su cui gira: il .jmo di
# tools/build.R funziona soltanto sui Mac Apple Silicon. Rifarlo altrove
# richiederebbe un computer per ciascun sistema, ma non serve: in un .jmo le
# parti legate alla piattaforma sono solo due.
#   1. Il campo rVersion. jamovi carica solo i moduli compilati per la
#      propria R: 4.5.0-arm64 sui Mac Apple Silicon, 4.5.0-x64 su Mac Intel,
#      Windows e Linux.
#   2. I pacchetti R di dipendenza con codice compilato (FactoMineR,
#      flashClust, leaps, httpuv, later, lazyeval, promises).
# Tutto il resto è identico: interfaccia, definizioni delle analisi, dataset,
# riferimenti e il pacchetto AnalisiMercato, che è puro R. R carica un
# pacchetto puro R installato su un altro sistema: library() rifiuta solo i
# pacchetti con il campo Platform valorizzato e diverso, e per un pacchetto
# senza codice compilato quel campo è vuoto.
#
# Lo script prende quindi il .jmo per Apple Silicon da mac/, sostituisce le
# dipendenze con i binari ufficiali dell'altro sistema, alla stessa versione,
# e cambia rVersion:
#   - Mac Intel e Windows: binari CRAN per R 4.5 da Posit Package Manager;
#   - Linux: binari compilati da jamovi per il suo runtime Flatpak, dallo
#     stesso repository che jmvtools usa su Linux.
# Per Mac Intel serve un passo in più, lo stesso di jmvtools: le librerie
# compilate cercano le librerie di R (libgfortran, libquadmath...) nella R
# installata in /Library/Frameworks, e vanno ricollegate a quella contenuta
# in jamovi (@executable_path/../Frameworks/...).
#
# La data dello snapshot si legge da jmvtools (snapshots.js), così è quella
# con cui sono state installate le dipendenze per Apple Silicon. Lo script
# verifica comunque che le versioni coincidano.
#
# I pacchetti scaricati restano in build/R<versione>-x64-<sistema>, come fa
# jmvtools per il Mac, e si riscaricano solo quando cambia la versione
# richiesta.
#
# Limite: qui non si può avviare jamovi per Mac Intel, Windows o Linux. Lo
# script controlla la struttura del .jmo (architettura di ogni libreria,
# collegamenti alle librerie di R, contenuto identico a quello per Apple
# Silicon), ma la prova finale va fatta installando il modulo su quei
# sistemi.
#
# Uso:  Rscript tools/build-altre-piattaforme.R   (lo lancia tools/build.R)
# =============================================================================

if (!file.exists("DESCRIPTION") || !file.exists(file.path("jamovi", "0000.yaml")))
  stop("Eseguire lo script dalla cartella principale del modulo.")

options(timeout = max(600, getOption("timeout")))

nome     <- read.dcf("DESCRIPTION")[1, "Package"]
ver      <- read.dcf("DESCRIPTION")[1, "Version"]
nome_jmo <- function(suffisso) sprintf("%s_%s_%s.jmo", nome, ver, suffisso)
jmo_base <- normalizePath(file.path("mac", nome_jmo("mac-apple-silicon")),
                          mustWork = FALSE)
if (!file.exists(jmo_base))
  stop("Non trovo la build per Mac Apple Silicon ", jmo_base,
       ": eseguire prima Rscript tools/build.R su un Mac Apple Silicon")

cartella_vuota <- function(percorso) {
  unlink(percorso, recursive = TRUE)
  dir.create(percorso, recursive = TRUE)
  percorso
}

leggi_righe <- function(f) readLines(f, encoding = "UTF-8", warn = FALSE)

# --- il .jmo per Apple Silicon: versione di R e dipendenze -------------------

base <- cartella_vuota(file.path(tempdir(), "jmo-base"))
utils::unzip(jmo_base, exdir = base)

riga_rv  <- grep("^rVersion: ", leggi_righe(file.path(base, nome, "jamovi.yaml")),
                 value = TRUE)
if (length(riga_rv) != 1) stop("rVersion non trovato nel .jmo per Apple Silicon")
r_base   <- sub("^rVersion: *", "", riga_rv)            # es. 4.5.0-arm64
r_ver    <- sub("-.*$", "", r_base)                     # es. 4.5.0
r_minore <- sub("^([0-9]+\\.[0-9]+).*$", "\\1", r_ver)  # es. 4.5
r_x64    <- paste0(r_ver, "-x64")

dir_r_base <- file.path(base, nome, "R")
dipendenze <- setdiff(list.files(dir_r_base), nome)
dipendenze <- dipendenze[dir.exists(file.path(dir_r_base, dipendenze)) &
                         !startsWith(dipendenze, "00LOCK")]
versioni <- vapply(dipendenze, function(d)
  read.dcf(file.path(dir_r_base, d, "DESCRIPTION"))[1, "Version"], "")

# --- snapshot dei pacchetti usato da jmvtools per questa R -------------------

snapshots_js <- file.path(find.package("jmvtools"), "node_modules",
                          "jamovi-compiler", "snapshots.js")
testo <- paste(leggi_righe(snapshots_js), collapse = "\n")
blocco <- regmatches(testo, regexpr(
  sprintf("'%s'\\s*:\\s*\\{[^}]*", gsub(".", "\\.", r_ver, fixed = TRUE)),
  testo, perl = TRUE))
snapshot <- regmatches(blocco, regexpr("[0-9]{4}-[0-9]{2}-[0-9]{2}", blocco))
if (length(snapshot) != 1)
  stop("jmvtools non ha uno snapshot dei pacchetti per R ", r_ver)

posit <- sprintf("https://packagemanager.posit.co/cran/%s/bin", snapshot)
piattaforme <- list(
  list(
    etichetta  = "Mac Intel",
    cartella   = "mac",
    suffisso   = "mac-intel",
    build      = file.path("build", sprintf("R%s-macos", r_x64)),
    repo       = sprintf("%s/macosx/big-sur-x86_64/contrib/%s", posit, r_minore),
    estensione = ".tgz",
    libreria   = "\\.so$",
    formato    = "Mach-O x86-64",
    built      = "x86_64-apple-darwin",
    ricollega  = sprintf("%s-x86_64", r_minore)  # R.framework/Versions/<...>
  ),
  list(
    etichetta  = "Windows x64",
    cartella   = "windows",
    suffisso   = "windows",
    build      = file.path("build", sprintf("R%s-win64", r_x64)),
    repo       = sprintf("%s/windows/contrib/%s", posit, r_minore),
    estensione = ".zip",
    libreria   = "\\.dll$",
    formato    = "PE x86-64",
    built      = "mingw",
    ricollega  = NULL
  ),
  list(
    etichetta  = "Linux x64",
    cartella   = "linux",
    suffisso   = "linux",
    build      = file.path("build", sprintf("R%s-linux", r_x64)),
    repo       = sprintf("https://repo.jamovi.org/cran-linux/%s/x64/src/contrib",
                         snapshot),
    estensione = ".tar.gz",
    libreria   = "\\.so$",
    formato    = "ELF x86-64",
    built      = "linux-gnu",
    ricollega  = NULL
  )
)

# --- formato delle librerie compilate ----------------------------------------

formato_binario <- function(f) {
  b <- readBin(f, "raw", n = 4096)
  if (length(b) >= 20 && identical(b[1:4], as.raw(c(0x7f, 0x45, 0x4c, 0x46)))) {
    macchina <- readBin(b[19:20], "integer", size = 2, signed = FALSE,
                        endian = "little")
    return(if (b[5] == as.raw(2) && macchina == 62) "ELF x86-64" else "ELF altro")
  }
  if (length(b) >= 64 && identical(b[1:2], charToRaw("MZ"))) {
    pe <- readBin(b[61:64], "integer", size = 4, endian = "little")
    if (pe + 6 <= length(b) &&
        identical(b[(pe + 1):(pe + 4)], as.raw(c(0x50, 0x45, 0, 0)))) {
      macchina <- readBin(b[(pe + 5):(pe + 6)], "integer", size = 2,
                          signed = FALSE, endian = "little")
      return(if (macchina == 0x8664) "PE x86-64" else "PE altro")
    }
    return("PE altro")
  }
  if (length(b) >= 8 && identical(b[1:4], as.raw(c(0xcf, 0xfa, 0xed, 0xfe)))) {
    cpu <- readBin(b[5:8], "integer", size = 4, endian = "little")
    return(switch(as.character(cpu),
                  "16777223" = "Mach-O x86-64",   # CPU_TYPE_X86_64
                  "16777228" = "Mach-O arm64",    # CPU_TYPE_ARM64
                  "Mach-O altro"))
  }
  if (length(b) >= 4 && identical(b[1:4], as.raw(c(0xca, 0xfe, 0xba, 0xbe))))
    return("Mach-O universale")
  "altro"
}

# --- collegamenti delle librerie macOS alla R contenuta in jamovi -----------

dipendenze_dinamiche <- function(so) {
  righe <- system2("/usr/bin/otool", c("-L", shQuote(so)), stdout = TRUE)
  trimws(sub(" \\(compatibility version.*$", "", righe[-1]))
}

# Stesse sostituzioni di jmvtools (compilerr.js).
ricollega_librerie <- function(cartella_pkg, rv) {
  librerie <- c("libR.dylib", "libRlapack.dylib", "libRblas.dylib",
                "libgfortran.5.dylib", "libquadmath.0.dylib",
                "libXrender.1.dylib", "libomp.dylib", "libc++.1.dylib",
                "libc++abi.1.dylib")
  origini <- c(sprintf("/Library/Frameworks/R.framework/Versions/%s/Resources/lib", rv),
               "/usr/local/lib", "/usr/local/gfortran/lib", "/opt/X11/lib")
  jamovi <- sprintf("@executable_path/../Frameworks/R.framework/Versions/%s/Resources/lib",
                    rv)
  libs <- file.path(cartella_pkg, "libs")
  unlink(list.files(libs, pattern = "\\.dSYM$", full.names = TRUE,
                    include.dirs = TRUE), recursive = TRUE)
  for (so in list.files(libs, pattern = "\\.so$", full.names = TRUE)) {
    for (dip in dipendenze_dinamiche(so)) {
      if (!basename(dip) %in% librerie || !dirname(dip) %in% origini) next
      esito <- system2("/usr/bin/install_name_tool",
                       c("-change", shQuote(dip),
                         shQuote(file.path(jamovi, basename(dip))), shQuote(so)),
                       stdout = FALSE, stderr = FALSE)
      if (esito != 0) stop("install_name_tool non riuscito su ", so)
    }
  }
}

# --- dipendenze: download con verifica MD5, oppure dalla cache ---------------

gia_installato <- function(percorso, versione) {
  desc <- file.path(percorso, "DESCRIPTION")
  if (!file.exists(desc)) return(FALSE)
  d <- read.dcf(desc)
  "Built" %in% colnames(d) && identical(unname(d[1, "Version"]), versione)
}

prepara_dipendenze <- function(p) {
  dir.create(p$build, recursive = TRUE, showWarnings = FALSE)
  indice <- NULL
  for (d in dipendenze) {
    destinazione <- file.path(p$build, d)
    if (!gia_installato(destinazione, versioni[[d]])) {
      if (is.null(indice))
        indice <- utils::available.packages(contriburl = p$repo, filters = list(),
                                            fields = "Hash")
      scarica(p, d, destinazione, indice)
    }
    # Anche sui pacchetti già in cache, nel caso un'esecuzione precedente si
    # sia interrotta a metà: su quelli già ricollegati non cambia nulla.
    if (!is.null(p$ricollega)) ricollega_librerie(destinazione, p$ricollega)
  }
}

scarica <- function(p, d, destinazione, indice) {
  riga <- indice[indice[, "Package"] == d & indice[, "Version"] == versioni[[d]], ,
                 drop = FALSE]
  if (nrow(riga) == 0)
    stop(sprintf("%s %s (la versione per Apple Silicon) non è disponibile per %s in %s",
                 d, versioni[[d]], p$etichetta, p$repo))
  # Posit Package Manager riporta l'MD5 dei binari nel campo Hash, non in
  # MD5sum come i repository CRAN classici.
  atteso <- unname(riga[1, "MD5sum"])
  if (is.na(atteso)) atteso <- unname(riga[1, "Hash"])
  if (is.na(atteso))
    stop("L'indice di ", p$repo, " non riporta l'MD5 di ", d)
  file_remoto <- sprintf("%s/%s_%s%s", p$repo, d, versioni[[d]], p$estensione)
  archivio <- file.path(tempdir(), basename(file_remoto))
  cat(sprintf("  scarico %s\n", basename(file_remoto)))
  # download.file() della R di sistema si pianta su alcuni file di
  # repo.jamovi.org: scarica i primi 32 KB e resta appeso fino al timeout
  # (visto su multcompView_0.1-10.tar.gz). curl prende lo stesso file in
  # pochi secondi, quindi quando c'è si usa quello. L'integrità è garantita
  # comunque dal confronto dell'MD5 subito sotto.
  if (nzchar(Sys.which("curl"))) {
    # --http1.1: su HTTP/2 repo.jamovi.org chiude lo stream a meta' file
    # (curl 92, INTERNAL_ERROR). --retry copre le cadute occasionali.
    esito <- system2("curl", c("-sS", "-L", "--fail", "--http1.1",
                               "--retry", "5", "--retry-all-errors",
                               "--retry-delay", "2", "--max-time", "600",
                               "-o", shQuote(archivio), shQuote(file_remoto)))
    if (esito != 0)
      stop("Scaricamento non riuscito (curl, codice ", esito, "): ", file_remoto)
  } else {
    utils::download.file(file_remoto, archivio, mode = "wb", quiet = TRUE)
  }
  if (!identical(unname(tools::md5sum(archivio)), atteso))
    stop("MD5 non corrispondente per ", basename(file_remoto))
  unlink(destinazione, recursive = TRUE)
  if (p$estensione == ".zip") utils::unzip(archivio, exdir = p$build)
  else utils::untar(archivio, exdir = p$build)
  unlink(archivio)
  if (!gia_installato(destinazione, versioni[[d]]))
    stop(basename(file_remoto), " non è un pacchetto binario già compilato")
}

# --- assemblaggio del .jmo ---------------------------------------------------

sostituisci_rversion <- function(f, nuova) {
  righe <- leggi_righe(f)
  i <- grep("^rVersion: ", righe)
  if (length(i) != 1) stop("rVersion non trovato in ", f)
  righe[i] <- paste0("rVersion: ", nuova)
  writeLines(righe, f, useBytes = TRUE)
}

costruisci <- function(p) {
  cat(sprintf("\n%s\n", p$etichetta))
  prepara_dipendenze(p)

  stage <- cartella_vuota(file.path(tempdir(), paste0("jmo-", p$suffisso)))
  file.copy(file.path(base, nome), stage, recursive = TRUE)
  dir_r <- file.path(stage, nome, "R")
  unlink(file.path(dir_r, dipendenze), recursive = TRUE)

  # Stesso filtro di jmvtools: la documentazione dei pacchetti non entra nel
  # .jmo.
  for (d in dipendenze) {
    rel <- file.path(d, list.files(file.path(p$build, d), recursive = TRUE,
                                   all.files = TRUE))
    rel <- rel[!grepl("/(help|html|doc)/", rel)]
    for (f in rel) {
      dir.create(dirname(file.path(dir_r, f)), recursive = TRUE,
                 showWarnings = FALSE)
      file.copy(file.path(p$build, f), file.path(dir_r, f))
    }
  }
  unlink(list.files(stage, pattern = "^\\.DS_Store$", recursive = TRUE,
                    all.files = TRUE, full.names = TRUE))
  sostituisci_rversion(file.path(stage, nome, "jamovi.yaml"), r_x64)
  sostituisci_rversion(file.path(stage, nome, "jamovi-full.yaml"), r_x64)

  dir.create(p$cartella, showWarnings = FALSE)
  jmo <- file.path(normalizePath(p$cartella), nome_jmo(p$suffisso))
  unlink(jmo)  # zip aggiungerebbe i file a un archivio già esistente
  vecchia <- setwd(stage)
  on.exit(setwd(vecchia), add = TRUE)
  utils::zip(jmo, nome, flags = "-qr9X")
  setwd(vecchia)
  jmo
}

# --- verifica del .jmo prodotto ----------------------------------------------

impronte <- function(radice, escludi) {
  f <- list.files(radice, recursive = TRUE, all.files = TRUE)
  dip <- paste(gsub(".", "\\.", dipendenze, fixed = TRUE), collapse = "|")
  f <- sort(f[!grepl("(^|/)\\.DS_Store$", f) & !f %in% escludi &
              !grepl(sprintf("^R/(%s)/", dip), f)])
  stats::setNames(unname(tools::md5sum(file.path(radice, f))), f)
}

verifica <- function(jmo, p) {
  primo <- utils::unzip(jmo, list = TRUE)$Name[1]
  if (!startsWith(primo, paste0(nome, "/")))
    stop("Il .jmo deve iniziare con la cartella ", nome, "/, trovato ", primo)

  dir_x <- cartella_vuota(file.path(tempdir(), "jmo-verifica"))
  utils::unzip(jmo, exdir = dir_x)
  radice <- file.path(dir_x, nome)

  for (f in c("jamovi.yaml", "jamovi-full.yaml")) {
    rv <- grep("^rVersion: ", leggi_righe(file.path(radice, f)), value = TRUE)
    if (!identical(rv, paste0("rVersion: ", r_x64)))
      stop(f, ": atteso rVersion ", r_x64)
  }

  presenti <- setdiff(list.files(file.path(radice, "R")), nome)
  if (!setequal(presenti, dipendenze))
    stop("Dipendenze diverse da quelle per Apple Silicon: ",
         paste(sort(presenti), collapse = ", "))
  compilati <- 0
  for (d in dipendenze) {
    desc <- read.dcf(file.path(radice, "R", d, "DESCRIPTION"))
    if (!identical(unname(desc[1, "Version"]), versioni[[d]]))
      stop(d, ": versione diversa da quella per Apple Silicon")
    if (dir.exists(file.path(radice, "R", d, "libs"))) {
      compilati <- compilati + 1
      if (!grepl(p$built, desc[1, "Built"]))
        stop(d, " non è compilato per ", p$etichetta, ": ", desc[1, "Built"])
    }
  }

  tutti <- list.files(radice, recursive = TRUE, all.files = TRUE, full.names = TRUE)
  formati <- vapply(tutti, formato_binario, "")
  estranee <- startsWith(formati, "Mach-O") & formati != p$formato
  if (any(estranee))
    stop("Librerie di un'altra architettura nel .jmo: ",
         paste(basename(tutti[estranee]), collapse = ", "))
  librerie <- grepl(p$libreria, tutti) & grepl("/libs/", tutti)
  if (any(formati[librerie] != p$formato))
    stop("Librerie non ", p$formato, ": ",
         paste(basename(tutti[librerie & formati != p$formato]), collapse = ", "))

  # Sul Mac ogni libreria esterna deve essere di sistema o della R contenuta
  # in jamovi: un percorso verso /Library/Frameworks o /usr/local non
  # esisterebbe sul computer dello studente.
  ricollegate <- 0
  if (!is.null(p$ricollega)) {
    jamovi <- sprintf("@executable_path/../Frameworks/R.framework/Versions/%s/Resources/lib/",
                      p$ricollega)
    for (so in tutti[librerie]) {
      dip <- dipendenze_dinamiche(so)
      esterne <- dip[grepl("/", dip) & !startsWith(dip, "/usr/lib/") &
                     !startsWith(dip, "/System/") & !startsWith(dip, jamovi)]
      if (length(esterne))
        stop(basename(so), " usa librerie che in jamovi non ci sono: ",
             paste(esterne, collapse = ", "))
      ricollegate <- ricollegate + sum(startsWith(dip, jamovi))
    }
  }

  # Tutto ciò che non è una dipendenza deve coincidere con il .jmo per Apple
  # Silicon; i due yaml differiscono solo per la riga rVersion.
  yaml <- c("jamovi.yaml", "jamovi-full.yaml")
  if (!identical(impronte(radice, yaml), impronte(file.path(base, nome), yaml)))
    stop("Il contenuto non legato alla piattaforma differisce dal .jmo per Apple Silicon")
  for (f in yaml) {
    a <- leggi_righe(file.path(radice, f))
    b <- leggi_righe(file.path(base, nome, f))
    if (length(a) != length(b) || sum(a != b) != 1)
      stop(f, " differisce da quello per Apple Silicon oltre alla riga rVersion")
  }

  cat(sprintf(paste0("  %s (%.1f MB)\n",
                     "  rVersion %s | %d dipendenze, stesse versioni | ",
                     "%d compilate per %s, %d librerie %s%s | ",
                     "nessuna libreria di altri sistemi\n"),
              file.path(p$cartella, basename(jmo)), file.size(jmo) / 1e6,
              r_x64, length(dipendenze), compilati, p$etichetta, sum(librerie),
              p$formato,
              if (ricollegate > 0)
                sprintf(" (%d collegamenti alla R di jamovi)", ricollegate)
              else ""))
}

cat(sprintf("%s %s: dal .jmo per Mac Apple Silicon (rVersion %s, snapshot pacchetti %s)\n",
            nome, ver, r_base, snapshot))
for (p in piattaforme) verifica(costruisci(p), p)
