# AnalisiMercato

Modulo [jamovi](https://www.jamovi.org) per il corso di Analisi di Mercato dell'Università degli Studi di Cagliari. Raccoglie strumenti per le principali fasi quantitative di una ricerca di mercato, con pannelli e risultati in italiano.

## Analisi

- **Campionamento**: numerosità campionaria per proporzioni e medie; estrazione del campione con casuale semplice (con e senza reinserimento), sistematico, stratificato (allocazione proporzionale e di Neyman), a grappoli, a due stadi e con probabilità variabili; intervalli di confidenza; Design Effect.
- **Cluster Analysis**: clustering gerarchico con sette distanze e cinque metodi di agglomerazione, indici per la scelta del numero di gruppi (R², RMSSTD, Delta G, indice CH) e dendrogramma colorato per gruppo; caratterizzazione dei gruppi; confronto fra partizioni con l'Adjusted Rand Index.
- **PCA**: analisi delle componenti principali con coordinate, contributi e coseni quadrati, cerchio delle correlazioni, biplot, variabili supplementari quantitative e qualitative, rotazioni Varimax e Promax.

Il modulo include quattro dataset didattici, che in jamovi si aprono da *Menu ≡ → Apri → Libreria Dati → Tecniche di Analisi di Mercato*.

## Installazione

Serve jamovi 2.7.x, la versione *Solid*.

1. Dalla pagina [Releases](https://github.com/lucafrigau/AnalisiMercato/releases) scaricare il file `.jmo` del proprio sistema:
   - macOS con chip Apple: `AnalisiMercato_x.x.x_mac-apple-silicon.jmo`
   - macOS con processore Intel: `AnalisiMercato_x.x.x_mac-intel.jmo`
   - Windows: `AnalisiMercato_x.x.x_windows.jmo`
   - Linux: `AnalisiMercato_x.x.x_linux.jmo`
2. In jamovi: pulsante `+` **Moduli** in alto a destra → **libreria jamovi** → scheda **Caricamento Ausiliario Moduli** (*Sideload*), poi selezionare il file scaricato.

Al termine, nella scheda **Analisi** compare la voce **AnalisiMercato**.

## Licenza

AnalisiMercato è software libero, distribuito con licenza GNU GPL versione 3 (vedi [LICENSE.md](LICENSE.md)). © 2024–2026 Luca Frigau.

I file `.jmo` includono FactoMineR, dendextend e le loro dipendenze che jamovi non fornisce, ciascuna con la propria licenza (GPL o MIT). Ogni release contiene, accanto ai `.jmo`, l'archivio `AnalisiMercato_x.x.x_sorgenti.zip` con il codice sorgente di quei pacchetti e i testi delle licenze.

## Riconoscimenti

- L'Analisi delle Componenti Principali e la Caratterizzazione usano [FactoMineR](https://CRAN.R-project.org/package=FactoMineR): Lê S., Josse J., Husson F. (2008). FactoMineR: An R Package for Multivariate Analysis. *Journal of Statistical Software*, 25(1), 1–18.
- L'analisi Caratterizzazione deriva dal modulo jamovi [MEDA](https://github.com/Sebastien-Le/MEDA) di Thomas Leblay, Fiona Tuffin, Maxime Saland, Maïwen Faure e Sébastien Lê, distribuito con licenza GPL: da MEDA vengono la struttura delle tabelle dei risultati e parte del codice che le compila.
- Il dendrogramma usa [dendextend](https://CRAN.R-project.org/package=dendextend): Galili T. (2015). dendextend: An R Package for Visualizing, Adjusting and Comparing Trees of Hierarchical Clustering. *Bioinformatics*, 31(22), 3718–3720.

## Compilare il modulo

`tools/build.R` prepara, compila e installa il modulo e ricava i `.jmo` per tutti i sistemi; passi e motivi sono descritti nell'intestazione dello script. Richiede jamovi 2.7.x e jmvtools 2.7.

## Contatti

Luca Frigau, Università degli Studi di Cagliari, [frigau@unica.it](mailto:frigau@unica.it). Nelle segnalazioni di errori indicare la versione del modulo, l'analisi coinvolta e i passi per riprodurre il problema.
