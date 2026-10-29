# AnalisiMercato 2.1.4

## Titoli di tabelle e grafici in italiano con jamovi in italiano

Il modulo e' scritto in italiano e aveva un solo catalogo di traduzione,
quello inglese. jamovi pero' considera l'inglese la lingua di partenza di
ogni modulo: tra le lingue dichiarate trovava solo l'inglese e, con jamovi
in italiano, ripiegava su quello. Pannelli, istruzioni e note restavano in
italiano, ma i titoli di tabelle, colonne e grafici uscivano in inglese
("Survey parameters", "Sample size", "Dendrogram").

Ora c'e' anche il catalogo italiano (`jamovi/i18n/it.po`, compilato in
`inst/i18n/it.json`), vuoto di proposito: i testi sono gia' in italiano e
non vanno tradotti, il catalogo serve solo a dichiarare a jamovi che
l'italiano c'e'. Con jamovi in italiano tutto l'output e' in italiano; con
jamovi in un'altra lingua i titoli restano in inglese come prima. I calcoli
non cambiano.

## Le variabili di tipo ID si possono assegnare

Nei pannelli dei campionamenti, degli intervalli di confidenza e della PCA
le variabili di tipo ID (nei dataset della Data Library `id_cliente`,
`id_comune`, `id_rispondente` e `marca`) comparivano in grigio e non si
potevano spostare nelle caselle che pure le accettano, come quella della
variabile identificativa. Le opzioni ammettevano il tipo `id`, ma l'elenco
delle variabili del pannello no: se non lo si indica, jamovi vi ammette
solo variabili numeriche e categoriali. Ora l'elenco di quegli otto
pannelli dichiara `permitted: [factor, numeric, id]` (nei file `.u.yaml`);
ogni casella continua ad accettare solo i tipi previsti dalla propria
opzione.

Compilazione: i .jmo della 2.1.4 sono quelli della 2.1.3 con il catalogo
italiano, la lingua dichiarata in `jamovi-full.yaml`, la riga `permitted`
nei pannelli compilati (`ui/*.js`) e il numero di versione aggiornati. Il
codice R e le dipendenze compilate sono identici.

# AnalisiMercato 2.1.3

## Design Effect: niente piu' unita' spurie nell'arrotondamento

Le colonne *Numerosita' richiesta dal piano* e *Numerosita' efficace* si
ottengono arrotondando per eccesso Deff · n e n / Deff. Il calcolo in
virgola mobile, pero', a volte supera di pochissimo un risultato che
dovrebbe essere intero: con rho = 0,05 e 83 unita' per grappolo il Deff vale
5,1 e 200 · 5,1 = 1.020, ma il modulo mostrava 1.021. Succedeva in circa un
caso su otto fra quelli con risultato esatto intero (per esempio Deff 1,1 e
n = 100 dava 111). Ora l'arrotondamento ha la stessa tolleranza gia' usata
nel campionamento sistematico. I risultati che prima erano giusti non
cambiano.

## Design Effect: il numero di riferimento si legge in due modi

Il campo *Numerosita' SCR di riferimento* diventa *Numerosita' di riferimento
(n)*, la colonna che lo ripete diventa *n di riferimento* e quella della
numerosita' efficace *Numerosita' efficace di n unita' raccolte col piano*.
Lo stesso n serve a due domande diverse: se e' il casuale semplice da
eguagliare, si legge *Numerosita' richiesta dal piano* (Deff · n); se e' il
campione gia' raccolto col piano complesso, si legge *Numerosita' efficace*
(n / Deff). Descrizione dell'opzione e istruzioni ora lo dicono. I calcoli
non cambiano.

# AnalisiMercato 2.1.2

## Gower: la co-assenza delle binarie di presenza/assenza non conta piu'

Nella Cluster Analysis Gerarchica c'e' una nuova casella, *Binarie di
presenza/assenza*, accanto alla base della segmentazione. Le variabili che
vi si inseriscono (0 = assenza, 1 = presenza) entrano nella base e, con la
distanza di Gower, sono trattate come nel coefficiente originale: la
co-presenza (1-1) e' un accordo, la discordanza (1-0) un disaccordo, la
co-assenza (0-0) non entra nel confronto, come nell'indice di Jaccard. Fino
alla 2.1.1 il modulo chiamava `daisy()` senza dichiarare variabili
asimmetriche, quindi una co-assenza contava come un accordo e avvicinava le
unita'. Ora modulo, slide e dispense usano la stessa definizione.

Quali binarie siano di presenza/assenza non lo decide il modulo, ma chi fa
l'analisi: che due clienti non possiedano un'auto elettrica dice poco su
quanto si somiglino, che siano due donne dice qualcosa. Le variabili a due
modalita' entrambe informative, come il sesso, restano nella base della
segmentazione e sono trattate con il simple matching.

- Le binarie di presenza/assenza vanno codificate 0/1, come numeri o come
  fattori con livelli "0" e "1". Un fattore con due modalita' testuali e'
  codificato prendendo il primo livello come assenza, e la nota sulla
  codifica lo dichiara; con altri valori l'analisi si ferma e spiega perche'.
- Se la base contiene solo binarie di presenza/assenza, due unita' con 0 su
  tutte non hanno alcun confronto possibile: la loro distanza e' posta a 0,
  come nel Jaccard, e una nota lo segnala.
- Una binaria con lo stesso valore in tutte le osservazioni non distingue
  le unita' e resta fuori dal calcolo; la nota della tabella lo dice.
- Con le altre distanze le variabili della nuova casella entrano nella base
  come le altre, e una nota avverte che il trattamento asimmetrico vale solo
  con Gower.
- Senza variabili nella nuova casella i risultati sono identici a quelli
  della 2.1.1.

# AnalisiMercato 2.1.1

## Il dataset del progetto di esempio non viaggia piu' con il modulo

La Data Library conteneva i dati dell'indagine sul corso usata come esempio
di progetto: 102 rispondenti reali, con voto d'esame e giudizi sulla
didattica. Sono dati individuali e, pur senza nomi, buona parte dei
rispondenti resta riconoscibile da chi conosce la coorte. Il modulo lo
installa chiunque, e una eventuale pubblicazione nella library di jamovi lo
diffonderebbe ovunque: non e' la sede giusta per distribuirli.

I quattro dataset didattici sintetici restano dove erano — popolazione
clienti, comuni per strati, survey di segmentazione, panel di prodotti. I
dati dell'esempio si trovano ora solo nella guida del corso, insieme ai
capitoli che li commentano.

Chi aggiorna dalla 2.1.0 non vedra' piu' la voce *Valutazione del corso —
dati* in *Open → Data Library*. Nessuna analisi cambia comportamento.

# AnalisiMercato 2.1.0

- **Campionamento sistematico: nessuna unità resta più fuori dal
  disegno.** Fino alla 2.0.13 il passo era k = ⌊N/n⌋ e la partenza si
  estraeva fra 1 e k: quando N non era un multiplo di n, le ultime
  N − n·k unità della lista avevano probabilità di inclusione **zero** e
  il riepilogo si limitava a dichiararlo. Ora l'intervallo è k = N/n,
  anche non intero, la partenza r si estrae in (0, k] e le posizioni
  sono ⌈r⌉, ⌈r+k⌉, …, ⌈r+(n−1)k⌉. Il campione ha sempre esattamente n
  unità distinte e **ogni unità della popolazione ha probabilità di
  inclusione n/N**, multiplo o non multiplo che sia. Nel riepilogo le
  colonne "Passo k = ⌊N/n⌋" e "Punto di partenza t" diventano
  "Intervallo k = N/n" e "Partenza casuale r ∈ (0, k]", e la nota sulla
  coda esclusa è sostituita da quella sulla copertura del frame.
  **A parità di dati, n e seed il campione estratto è diverso da quello
  della serie 2.0.x**: per riprodurre analisi già svolte va usata la
  versione con cui erano state fatte.
- **Campionamento stratificato: ogni strato non vuoto è rappresentato.**
  L'allocazione proporzionale o di Neyman poteva assegnare 0 unità a uno
  strato molto piccolo o, sotto Neyman, a uno strato con variabilità
  nulla: quelle unità avevano probabilità di inclusione zero. Ora ogni
  strato riceve almeno 2 unità — la numerosità minima per stimare la
  variabilità interna — e 1 soltanto se in popolazione ne contiene una
  sola. Il vincolo interviene **solo quando serve**: se l'allocazione
  teorica rispetta già i minimi il risultato non cambia, e
  l'allocazione proporzionale resta autoponderata. Quando invece morde,
  gli strati sotto soglia vengono portati al minimo, le unità restanti
  sono allocate fra gli altri con il criterio scelto e il metodo è
  dichiarato "Proporzionale vincolata" o "Ottimale (Neyman) vincolata",
  con una nota che elenca gli strati interessati. Se n non basta a
  garantire i minimi (n < 2 × numero di strati, meno gli strati con una
  sola unità) l'analisi si ferma e chiede di aumentare n o di accorpare
  gli strati più piccoli.
- **CPV: la variabile di peso deve essere finita e strettamente
  positiva.** Prima un peso `NA` veniva trattato in silenzio come 0 e lo
  zero era ammesso come dichiarazione di "unità non campionabile": in
  entrambi i casi restavano nel frame unità con probabilità di selezione
  nulla. Ora valori mancanti, non finiti, negativi e nulli sono rifiutati
  con un messaggio che indica la via corretta: togliere dal frame, con un
  filtro, le unità che non appartengono alla popolazione da campionare.
- **Distanza di Mahalanobis: niente più regolarizzazione silenziosa.**
  Con variabili collineari o più numerose delle osservazioni la matrice
  di covarianza non è invertibile: il modulo aggiungeva 1e-8 alla
  diagonale e restituiva distanze prive di significato. Ora si ferma con
  un messaggio che indica le tre strade possibili (ridurre le variabili,
  togliere le dipendenze lineari, cambiare distanza).
- **Design Effect: il benchmark del sistematico solo dove è definito.**
  La formula (k+1)/(N+1) nasce per il sistematico classico con N = n·k e
  k intero. Applicarla a un k frazionario le avrebbe attribuito una
  validità mai dimostrata per l'algoritmo a intervallo frazionario della
  2.1.0: ora, quando N non è multiplo di n, il risultato resta vuoto con
  una nota che lo spiega.
- **PCA: con Varimax anche contributi e cos² delle osservazioni sono
  ruotati.** La rotazione ortogonale non cambia la distanza delle
  osservazioni dall'origine, quindi cos² e contributi si ridefiniscono
  sulle coordinate ruotate — normalizzando i contributi sulla somma dei
  quadrati del nuovo asse. Prima le coordinate erano ruotate e le altre
  due tabelle no, cioè parlavano di assi diversi. Con Promax gli assi
  obliqui non consentono le stesse formule: coordinate ruotate, mentre
  contributi e cos² restano dichiaratamente quelli della soluzione non
  ruotata.
- **Design Effect: due numerosità distinte.** La colonna "n equivalente
  nel piano complesso" diventa **"Numerosità richiesta dal piano"**
  (Deff × n), e accanto compare la **"Numerosità efficace"** (n / Deff),
  che è la lettura corretta per un campione già raccolto. Erano due
  concetti diversi sotto la stessa etichetta.
- **PCA con Promax: compare la matrice Φ.** Le correlazioni fra le
  componenti ruotate venivano calcolate internamente ma non mostrate, e
  senza di esse la correlazione fra componenti non era leggibile in
  nessun punto dell'output. Ora sono in una tabella dedicata, visibile
  solo quando la rotazione scelta è Promax.
- **Descrizione del modulo allineata.** Il modulo non copre "l'intero
  ciclo della ricerca di mercato quantitativa" ma strumenti per alcune
  delle principali fasi quantitative di una ricerca di mercato:
  `DESCRIPTION` e `jamovi/0000.yaml` lo dicono ora in questi termini.

# AnalisiMercato 2.0.13

- **Casuale semplice e sistematico non mostrano più un errore a vuoto.**
  Aperte su un file nuovo, ancora senza dati, le due analisi mostravano
  subito in rosso "Servono almeno 2 osservazioni per estrarre un
  campione". Ora, se non è selezionata nessuna variabile, restano vuote
  in silenzio, come già la cluster analysis e la PCA. Il messaggio resta
  quando è stata indicata una variabile (identificativa o di
  ordinamento) e il dataset ha meno di 2 righe. Con un dataset vero non
  cambia nulla: le variabili restano facoltative e il campione si
  estrae dall'intero dataset anche senza selezionarne nessuna.
- **Versioni per Mac Intel, Windows e Linux.** Finora il `.jmo`
  funzionava solo su Mac con processore Apple Silicon. Ora ogni build
  produce quattro file, con la piattaforma nel nome:
  `mac/…_mac-apple-silicon.jmo`, `mac/…_mac-intel.jmo`,
  `windows/…_windows.jmo` e `linux/…_linux.jmo` (x64). Le altre versioni
  si ricavano da quella per Apple Silicon con
  `tools/build-altre-piattaforme.R`, lanciato in automatico da
  `tools/build.R`. Cambiano solo due cose: la versione di R dichiarata e
  i pacchetti R con codice compilato, sostituiti dai binari ufficiali
  per quel sistema alla stessa versione. Per Mac Intel le loro librerie
  vengono anche ricollegate alla R contenuta in jamovi, come fa
  jmvtools. In `mac/` si trovano anche tutte le build precedenti, ora con
  il suffisso `_mac-apple-silicon`.
- **Compilato per jamovi 2.7 (R 4.5.0).** jamovi carica solo i moduli
  compilati per la propria versione di R: questi `.jmo` funzionano con
  jamovi 2.7 ma non con la 2.6. Per jamovi 2.6 (solo Mac Apple Silicon)
  resta disponibile `mac/AnalisiMercato_2.0.12_jamovi-2.6_mac-apple-silicon.jmo`. Il modulo si
  compila ora con jmvtools 2.7.26: la 2.6.17 rifiuta jamovi 2.7.
- I nuovi test riproducono il modo in cui jamovi passa i dati alle
  analisi: tutte le righe non filtrate anche quando nessuna colonna è
  richiesta. Chiamando le funzioni da R senza variabili questo non
  accade, e il caso reale non sarebbe verificabile.

# AnalisiMercato 2.0.12

- **Il modulo spedisce i dataset del corso.** Si aprono da *Open → Data
  Library → Tecniche di Analisi di Mercato*, senza doverli scaricare a
  parte: `Popolazione clienti` (5.000 unita, per tutti i disegni
  campionari), `Comuni per strati` (200 comuni, per allocazione e
  probabilita variabili), `Survey di segmentazione` (400 rispondenti, per
  cluster analysis e PCA) e `Panel di prodotti` (20 marche, per la mappa
  di posizionamento). C'e anche `Progetto ACE — dati`, l'indagine sulla
  popolazione studentesca di Economia Manageriale usata come esempio di
  progetto completo (102 rispondenti, 36 variabili). In questo dataset le
  variabili qualitative con un ordine naturale (grado di accordo sulle
  domande del progetto, fascia di frequenza, sessione d'esame, classe di
  eta) sono dichiarate ordinali con la sequenza corretta: in jamovi erano
  nominali e i livelli comparivano in ordine alfabetico, con "abbastanza"
  prima di "per nulla".
- **Formato .omv, non CSV.** Nel CSV la natura delle variabili non e
  scritta da nessuna parte e jamovi deve indovinarla: i dataset arrivano
  invece gia tipizzati, con le etichette dei livelli e una descrizione per
  ogni variabile (visibile nel pannello di impostazione delle variabili).
  Gli item su scala 1-7 sono dichiarati **continui** e non ordinali: jamovi
  passa a R le variabili ordinali come fattori, e la cluster analysis con
  distanza euclidea li rifiuterebbe.
- I dataset sono ricostruibili con `Rscript tools/genera-dataset-omv.R`, che
  parte dai CSV in `data-raw/` e verifica che i livelli dichiarati coprano
  tutti i valori osservati (altrimenti `factor()` li trasformerebbe in NA
  silenziosi).

# AnalisiMercato 2.0.11

- **Riferimenti bibliografici in tutte le analisi.** Finora solo la PCA e
  la caratterizzazione dei cluster citavano le proprie fonti; ora ogni
  analisi mostra in fondo ai risultati i riferimenti del metodo che
  applica (Cochran, Kish, Lohr e Neyman per i disegni campionari,
  Hansen-Hurwitz per le probabilità variabili, Ward, Gower,
  Calinski-Harabasz ed Everitt per la cluster analysis, Hubert-Arabie
  per l'Adjusted Rand Index, Jolliffe, Kaiser e Hendrickson-White per la
  PCA e le rotazioni). Utile per citare correttamente il metodo nella
  relazione, non solo il software.
- **Copertura di test per il campionamento a grappoli e a due stadi.**
  Erano le uniche due analisi senza test dedicati, pur avendo la logica
  di estrazione più articolata. I nuovi test fissano le proprietà del
  disegno: a grappoli si prendono i grappoli interi e solo quelli
  estratti; a due stadi si prendono b unità per PSU e tutte le unità
  nelle PSU più piccole di b; le unità con grappolo mancante non entrano
  mai nel campione; un grappolo o una PSU di una sola unità non manda in
  errore l'estrazione; le etichette dei grappoli non vengono confuse con
  le loro posizioni. Verificato per mutazione che i test falliscono
  reintroducendo gli errori corrispondenti.
- **Nuovo script di compilazione `tools/build.R`.** La versione di
  `jmvtools` in uso non copia `jamovi/refs.yaml` dentro il `.jmo`, e senza
  quel file le chiavi dichiarate dalle analisi non hanno nulla su cui
  risolversi: i riferimenti non comparirebbero (è il motivo per cui non si
  vedevano nemmeno quelli già dichiarati da PCA e caratterizzazione). Lo
  script esegue prepare + install e poi inserisce `refs.yaml` nella radice
  del modulo, come nel modulo ufficiale jmv. Da qui in avanti il modulo va
  compilato con `Rscript tools/build.R`.
- **Contatto per le segnalazioni**: la descrizione del pacchetto (visibile in
  jamovi in *Modules → Manage installed*) e il campo `BugReports` indicano
  ora l'indirizzo a cui segnalare bug, errori di calcolo e suggerimenti:
  **frigau@unica.it**. Nella segnalazione conviene indicare versione del
  modulo, analisi coinvolta e passi per riprodurre il problema.

# AnalisiMercato 2.0.10

Allineamento del campionamento sistematico alla formulazione insegnata a
lezione.

## Modifica di comportamento

- **Campionamento sistematico: torna la formulazione classica.** Il punto
  di partenza `t` viene estratto entro `1..k` (unico numero casuale del
  disegno) e le unità estratte sono `t, t+k, …, t+(n−1)k`, senza chiudere
  la lista ad anello. Viene così rimosso il **sistematico circolare**
  (Lahiri) introdotto nella 2.0.3, in cui `t` era estratto entro `1..N` e
  la lista era percorsa modulo N.
- **La conseguenza è dichiarata, non nascosta.** Con la partenza entro
  `1..k`, se N non è multiplo di n le ultime `N − n·k` unità della lista
  hanno probabilità di inclusione **zero**. Il riepilogo riporta ora una
  nota che indica quante e quali posizioni restano fuori; quando invece N
  è multiplo di n la nota conferma che ogni unità ha probabilità `n/N`.
  Il pannello Istruzioni descrive la procedura effettivamente usata.
- La colonna del riepilogo si intitola ora *Punto di partenza t (1..k)*.

Il campione estratto cambia rispetto alla 2.0.9 a parità di seed: le
analisi salvate che usano il campionamento sistematico produrranno un
campione diverso alla riapertura.

# AnalisiMercato 2.0.9

Rilascio di rifinitura emerso durante l'allineamento della guida del
corso al comportamento del modulo.

- **PCA, scree plot**: titolo e didascalia dicevano ancora "autovalori
  ruotati (Varimax)" e "autovalori ridistribuiti dalla rotazione",
  mentre dalla 2.0.4 il grafico disegna — correttamente — gli autovalori
  della soluzione NON ruotata. Il grafico affermava quindi l'opposto di
  ciò che mostrava, in contraddizione con la tabella SS loadings e con il
  pannello Istruzioni. Ora il titolo è semplicemente "Scree plot" e la
  didascalia, quando una rotazione è attiva, chiarisce che gli autovalori
  sono quelli della soluzione originale e rimanda alla tabella SS
  loadings.
- **CPV, descrizione della variabile di peso**: diceva ancora "quantitativa
  positiva" e chiamava p_i "probabilità di inclusione". Allineata al
  comportamento reale: pesi non negativi (0 e NA identificano unità non
  campionabili), e p_i è la probabilità di SELEZIONE a singola estrazione.

# AnalisiMercato 2.0.8

Rilascio di correzione per un errore segnalato dall'uso reale del modulo.

## Correzione

- **PCA con rotazione: la heatmap dei cos² andava in errore.** Con una
  rotazione attiva l'analisi si interrompeva con
  *"gli argomenti implicano un numero differente di righe: 6, 0"*.
  Causa: le matrici ruotate sono ottenute per prodotto con la matrice di
  rotazione, che non ha `dimnames`; in R il prodotto matriciale eredita i
  nomi di colonna dall'operando di destra, quindi le matrici risultanti
  li perdevano. La heatmap costruisce il proprio data frame a partire da
  `colnames(cos2)` e riceveva un vettore vuoto. Le tabelle non erano
  interessate perché assegnano i nomi delle componenti esplicitamente.
  Ora tutte le matrici ruotate (loadings, cos², contributi, coordinate
  degli individui, correlazioni) ricevono esplicitamente nomi di riga e
  di colonna. Il difetto era presente dalla 2.0.4, cioè da quando i cos²
  hanno cominciato a essere calcolati dalle correlazioni ruotate.
- **Etichette uniformi delle componenti.** Anche senza rotazione le
  colonne provenienti da FactoMineR si chiamavano `Dim.1`, `Dim.2`: ora
  sono `PC1`, `PC2` … in ogni configurazione, coerentemente con le
  tabelle.

## Test

- **Nuovo file `test-plots-render.R`**: i grafici vengono ora
  effettivamente **disegnati** su un device nullo, non solo configurati.
  Era esattamente la lacuna che aveva lasciato passare questo bug: i
  test leggevano le tabelle (che usano nomi espliciti) senza mai
  renderizzare le immagini. I nuovi test coprono le cinque immagini
  della PCA per 3 rotazioni × 2 scale e per `ncp` = 1 e 3, la
  conservazione dei nomi delle componenti nelle matrici ruotate, e le
  cinque immagini della cluster analysis su quattro distanze.
  Verificato che falliscono (10 fallimenti) rimuovendo la correzione e
  passano ripristinandola.
- Suite complessiva a **372 test** (erano 350), verdi in italiano e in
  inglese.

# AnalisiMercato 2.0.7

Rilascio di correzione a valle della quarta revisione. Due correzioni
sostanziali e due allineamenti fra testo e comportamento.

## Correttezza statistica

- **Allocazione di Neyman: σ_j non stimabile non è σ_j nulla.** Quando in
  uno strato la variabile ausiliaria aveva meno di due valori validi, il
  codice poneva `σ_j = 0`. Ma non poter stimare la variabilità è cosa
  diversa dall'aver stimato variabilità nulla: il peso `N_j·σ_j`
  diventava 0 e lo strato poteva ricevere `n_j = 0`, uscendo dal
  campione come se fosse perfettamente omogeneo. Nello scenario tipico
  (strato di 50 unità con un solo valore ausiliario non mancante,
  contro uno strato completo di pari ampiezza) l'allocazione risultante
  era radicalmente sbagliata. Ora l'allocazione ottimale viene
  **rifiutata** con un messaggio che nomina gli strati problematici e
  indica le alternative (completare i dati ausiliari, cambiare
  variabile, oppure usare l'allocazione proporzionale, che non richiede
  σ_j). Restano legittimi e non bloccanti i due casi diversi:
  - strato con **una sola unità in popolazione** (`N_j = 1`): la
    variabilità interna è davvero nulla;
  - **σ_j stimata e pari a zero** (valori tutti identici): è
    un'informazione valida, non un dato mancante.
- **Nota sugli strati non rappresentati.** L'allocazione pura può
  legittimamente assegnare `n_j = 0` a uno strato molto piccolo, o con
  variabilità nulla sotto Neyman. Il comportamento resta invariato —
  imporre d'ufficio un minimo per strato produrrebbe un'allocazione che
  non è più quella dichiarata — ma ora una nota sotto la tabella degli
  strati segnala quali strati non entrano nel campione e spiega come
  intervenire.

## Interfaccia

- **Cluster analysis, visibilità dei grafici.** I cinque grafici
  (dendrogramma, R², RMSSTD, Delta G, indice CH) venivano resi visibili
  solo nel ramo "checkbox selezionata": poiché `setVisible()` è
  persistente e le checkbox non compaiono nei `clearWith` delle
  immagini, deselezionare un grafico (per esempio R² ON → OFF) poteva
  lasciarlo visibile con il contenuto della precedente esecuzione. La
  visibilità è ora impostata sempre in entrambi i sensi, come già fatto
  in PCA per titoli e tabella delle SS loadings.

## Documentazione allineata al comportamento

- **Campionamento con probabilità variabili**: le istruzioni chiedevano
  pesi "strettamente positivi", mentre il codice ammette correttamente
  peso 0 e valori mancanti (unità non campionabili) e rifiuta soltanto
  pesi negativi o infiniti. Il testo ora dice esattamente questo.
- **Campionamento stratificato**: la spiegazione dell'allocazione
  proporzionale affermava che la frazione di campionamento è uguale in
  ogni strato (`f_j = f`). È vero per le quote **teoriche**; poiché gli
  `n_j` devono essere interi, dopo l'arrotondamento le frazioni
  realizzate possono differire leggermente. Il testo lo precisa.

## Test

- Suite estesa a **350 test** (erano 342), verdi in italiano e in
  inglese. Nuove regressioni per: rifiuto di Neyman con σ_j non
  stimabile e funzionamento della proporzionale sugli stessi dati,
  strato con `N_j = 1` e σ_j stimata pari a zero, visibilità dei cinque
  grafici in entrambi i sensi e in configurazione mista.

# AnalisiMercato 2.0.6

Rilascio di correzione a valle della terza revisione. Un solo problema
sostanziale — l'arrotondamento dell'allocazione stratificata — più due
allineamenti fra codice e documentazione.

## Correttezza statistica

- **Allocazione stratificata: metodo dei resti maggiori.** L'allocazione
  teorica (proporzionale o di Neyman) veniva arrotondata con `round()` e
  le unità mancanti erano poi assegnate agli strati con maggiore
  **capacità residua** (`N_j − n_j`), cioè ai più grandi, invece che a
  quelli con la maggiore **parte decimale**. Con `N_j = (23, 34, 43)` e
  `n = 10` l'allocazione proporzionale teorica è `(2.3, 3.4, 4.3)`:
  l'unità mancante finiva al terzo strato dando `(2, 3, 5)` anziché il
  corretto `(2, 4, 4)`. Il campione estratto era quindi diverso da
  quello che l'analisi dichiarava di applicare. Ora si usa il metodo dei
  resti maggiori (Hamilton).
- **Riallocazione dopo la saturazione di uno strato.** Quando uno strato
  raggiunge la propria ampiezza `N_j`, le unità che restano da collocare
  vengono ora ridistribuite fra gli strati **non saturi in proporzione
  ai loro pesi teorici** (`N_j` per l'allocazione proporzionale,
  `N_j·σ_j` per Neyman), iterando finché nessuno strato eccede la
  capacità. In precedenza il residuo seguiva la capacità residua, che
  con Neyman può essere molto lontana dai pesi: nel test di regressione
  (`N_j = (4, 50, 50)`, `σ = (10, 1, 3)`, `n = 30`) i due strati non
  saturi devono ricevere unità in rapporto 1:3 come i loro pesi
  `N_j·σ_j`, non 1:1 come le loro ampiezze.

## Documentazione allineata al codice

- **Campionamento sistematico**: la descrizione dell'opzione *seed*
  affermava ancora che il punto di partenza è estratto entro `1..k`,
  mentre dalla 2.0.3 il modulo usa il sistematico circolare con partenza
  in `1..N`. Il calcolo era corretto: era sbagliata la frase.
- **Numerosità campionaria e Design Effect**: annotato nel codice il
  comportamento del wrapper R generato da jmvtools. Queste due analisi
  non hanno un'opzione di tipo `Data` (`requiresData = FALSE`: sono
  calcolatori e non richiedono un dataset), ma il template del
  compilatore emette comunque `data = data` senza generare l'argomento
  corrispondente: il nome si risolve così a `utils::data` e `self$data`
  contiene una *funzione*, non `NULL`. Oggi è innocuo perché nessuno dei
  due file usa `self$data`; il commento serve a impedire che una
  modifica futura vi si appoggi (un `if (is.null(self$data)) return()`
  non sarebbe mai vero). Aggiungere un'opzione `Data` risolverebbe il
  wrapper ma renderebbe `requiresData = TRUE`, obbligando a un dataset
  aperto per due analisi che non ne hanno bisogno: la cura sarebbe
  peggiore del male.

## Test

- Suite estesa a **342 test** (erano 286), verdi in italiano e in
  inglese. Nuove regressioni sull'allocazione stratificata: caso
  `(23, 34, 43)` con `n = 10`, invarianza dell'allocazione già intera,
  somma esatta e vincolo `0 ≤ n_j ≤ N_j` su casi casuali, e
  riallocazione secondo i pesi `N_j·σ_j` dopo la saturazione di uno
  strato.

# AnalisiMercato 2.0.5

Rilascio di correzione a valle della seconda revisione didattica. Il
criterio resta quello concordato: il modulo **consente** scelte
metodologicamente discutibili (ha valore didattico poterle eseguire e
poi discuterle), ma non deve **calcolare una cosa diversa da quella
dichiarata** né cambiare comportamento in modo incoerente.

## Correttezza statistica

- **Jaccard binario con variabili categoriali** — bug grave. La 2.0.4
  convertiva i fattori nei codici di livello `1..L` e li passava a
  `stats::dist(method = "binary")`, che interpreta *qualunque* valore
  diverso da zero come "presenza": un fattore Sesso M/F diventava 1/2,
  entrambi "presenti", e **tutte le distanze risultavano 0** (verificato:
  matrice di distanze identicamente nulla). Ora il Jaccard binario
  pretende una codifica realmente 0/1:
  - livelli numerici (`"0"`, `"1"`) → si usano i **valori**;
  - due modalità testuali → si applica la convenzione "primo livello =
    assenza", **dichiarata in una nota** sotto la tabella, perché il
    Jaccard è asimmetrico (le coppie 0-0 non contano) e la scelta cambia
    il risultato;
  - più di due modalità, o valori numerici diversi da 0/1 → rifiuto con
    rimando al Jaccard politomico, invece di calcolare in silenzio
    qualcosa che non è un Jaccard.
- **Semantica unica dello zero nelle metriche di matching.** La stessa
  variabile dava distanze diverse a seconda che fosse dichiarata
  quantitativa o nominale: con codifica numerica lo 0 era "assenza",
  mentre un fattore con livelli `"0"`, `"1"`, `"2"` veniva convertito in
  `1, 2, 3` e il livello `"0"` diventava una modalità ordinaria (su un
  caso minimo: distanza 1.000 contro 0.667). Ora vale una regola sola —
  **il valore 0 significa sempre assenza** — ottenuta convertendo i
  fattori con livelli numerici nei valori dei livelli; i fattori con
  modalità testuali non hanno alcuna nozione di assenza e usano i codici
  `1..L`, dove ogni modalità è una presenza. La codifica applicata è
  riportata in nota.
- **Adjusted Rand Index, livelli non osservati.** Un fattore che
  conserva livelli dichiarati ma vuoti (tipico dopo un filtro jamovi)
  produceva righe e colonne interamente nulle nella tabella di
  contingenza: il test di equivalenza fra partizioni falliva e due
  partizioni identiche tornavano `NaN`. I margini nulli vengono ora
  eliminati prima del test.

## Stato dell'interfaccia fra un'esecuzione e l'altra

`setTitle()` e `setVisible()` sopravvivono al ricalcolo dei risultati,
quindi ogni modifica dinamica va sempre accompagnata dal ramo opposto.

- **PCA**: a ogni esecuzione i titoli delle tabelle e la visibilità
  della tabella SS loadings vengono riportati ai valori di default
  *prima* di applicare le modifiche dovute alla rotazione. Senza questo
  ripristino, tornando da Varimax/Promax a "Nessuna rotazione"
  restavano i titoli "— ruotati (…)" e la tabella delle SS loadings
  visibile ma vuota.
- **Campionamento casuale semplice**: aggiunto il ramo mancante che
  riporta il titolo a "Frazione f = n/N" quando si torna al
  campionamento senza reinserimento (passando SSR → SCR → SSR restava
  "Rapporto estrazioni/popolazione").

## Interfaccia

- **Cluster analysis senza variabili**: con meno di due variabili
  selezionate l'analisi ora **esce in silenzio**, come già faceva la
  PCA, invece di mostrare un errore rosso mentre l'utente sta ancora
  componendo l'analisi. Il pannello "Istruzioni" spiega già che cosa
  serve.
- **Distanze quantitative su variabili categoriali**: coerentemente con
  il criterio didattico adottato, applicare Euclidea/Manhattan/
  Mahalanobis a una variabile categoriale **codificata con numeri** è
  ora consentito (lo studente deve poter fare la scelta discutibile e
  poi discuterla), con una nota che avverte che i codici entrano nel
  calcolo come quantità. Resta rifiutato il solo caso in cui il calcolo
  è impossibile, cioè modalità testuali (M/F).
- **Intervalli di confidenza**: il minimo di `n` in modalità manuale
  passa da 1 a 2, allineando l'opzione al backend (con n = 1 la varianza
  campionaria non è definita e il calcolo veniva comunque rifiutato).

## Test

- Suite estesa a **286 test** (erano 268), verdi in italiano e in
  inglese. Nuove regressioni per: distanze non degeneri del Jaccard
  binario sui fattori ed equivalenza fra livelli `"0"/"1"` e valori 0/1,
  rifiuto delle codifiche non binarie, identità numerico/fattore nel
  Jaccard politomico, uscita silenziosa di `hc`, ripristino di titoli e
  visibilità in PCA e nel campionamento semplice, ARI con livelli non
  osservati, minimo di `n_manual`.

# AnalisiMercato 2.0.4

Rilascio di correzione statistica a valle della revisione didattica dei
risultati dell'audit. Il criterio adottato è quello indicato dal docente:
il modulo **non impedisce** allo studente scelte metodologicamente
discutibili (per esempio Ward con Manhattan o con Jaccard) — poterle
eseguire e poi discutere perché non siano appropriate ha valore
didattico; vengono corrette solo le quantità *sbagliate* e le
*etichette fuorvianti*.

## Lingua dell'interfaccia

- **L'italiano è ora la lingua di default** dei testi generati dal codice
  R (pannelli "Istruzioni", messaggi di errore, etichette calcolate).
  In precedenza la lingua veniva dedotta dalla locale di sistema: su un
  Mac configurato in inglese uno studente italiano vedeva messaggi come
  *"Select at least 2 variables to run the cluster analysis"*. Ora si
  parte sempre dall'italiano; l'inglese si ottiene impostando la
  variabile d'ambiente `ANALISIMERCATO_LANG=en` prima di avviare jamovi.

## Correttezza statistica

- **Jaccard politomico**: corretto il calcolo dell'unione. Il codice
  dichiarava di trattare ogni coppia (variabile, livello) come una
  feature one-hot, ma contava 1 sola feature per variabile anche quando
  i due individui presentavano livelli *diversi*. Esempio: V1 = A per
  entrambi, V2 = B contro C dava `1 − 1/2 = 0.5` invece del corretto
  `1 − 1/3 = 0.667`. Ora l'unione è calcolata come
  `|A| + |B| − |A ∩ B|` ed è stata verificata contro un'espansione
  one-hot esplicita; il percorso veloce BLAS per dati 0/1 resta
  identico a `dist(method = "binary")`.
- **CPV, probabilità di selezione e di inclusione**: `p_i = w_i/Σw` era
  presentata come "probabilità di inclusione" mentre è la probabilità di
  selezione a *una singola estrazione*. La colonna è stata rinominata e
  affiancata dalla probabilità di inclusione vera e propria: con
  reinserimento `π_i = 1 − (1 − p_i)^n` (verificata per simulazione);
  senza reinserimento le π_i non hanno forma chiusa elementare
  (campionamento sequenziale) e vengono lasciate indefinite anziché
  riportare `n·p_i`, che è sensibilmente diverso. Istruzioni aggiornate
  di conseguenza.
- **Numerosità campionaria, coerenza della FPC**: la varianza attesa
  usava `(1−f) = (N−n)/N` mentre la formula da cui si ricava n discende
  da `(N−n)/(N−1)`. Ora entrambe usano `(N−n)/(N−1)`: invertendo il SE
  riportato si riottiene esattamente il margine di errore richiesto.
- **Intervalli di confidenza, proporzione**: l'errore standard passa da
  `√[(1−f)·p̂q̂/n]` a `√[(1−f)·p̂q̂/(n−1)]` (Cochran 1977, eq. 3.13).
  Il denominatore `n−1` rende la proporzione **esattamente** il caso
  particolare della media applicata alla variabile indicatrice 0/1:
  la stessa variabile letta come 0/1 numerica o come fattore produce
  ora intervalli identici, e la convenzione coincide con quella usata
  da "Numerosità campionaria".
- **Adjusted Rand Index**: due partizioni identiche fatte di soli
  singoletti (1 2 3 4 contro 1 2 3 4) restituivano `NaN` invece di 1,
  perché la formula di Hubert-Arabie degenera in 0/0 quando non c'è
  variabilità di coppie. Ora si verifica preliminarmente se le due
  partizioni inducono la stessa relazione di equivalenza (tabella di
  contingenza con una sola cella non nulla per riga e per colonna),
  nel qual caso l'indice vale 1 per definizione. I casi non degeneri
  sono invariati (verificati su 60 confronti casuali e contro
  `mclust::adjustedRandIndex`).

## Presentazione dei risultati

- **PCA, autovalori e rotazione**: la tabella degli autovalori, le
  percentuali di varianza e lo scree plot tornano a riferirsi **sempre**
  alla soluzione originale. In precedenza, con la rotazione attiva, le
  prime componenti venivano sovrascritte con le somme dei quadrati dei
  loadings e la colonna cumulata veniva ricalcolata su di esse: con
  Promax (rotazione obliqua) quella "varianza cumulata" non ha
  significato, perché le componenti correlate non ammettono una
  decomposizione additiva della varianza. Le SS loadings sono ora in una
  **tabella separata**, con le quote di varianza riportate solo per
  Varimax (ortogonale, additive) e omesse per Promax, con nota
  esplicativa — la stessa convenzione di SPSS. Anche le etichette degli
  assi dei grafici sono state rese oneste: `PC1 (73.0%)` senza
  rotazione, `PC1 (67.6% ruotata)` con Varimax, `PC1 (ruotata)` con
  Promax.
- **Campionamento a due stadi**: il riepilogo dichiarava "b = 10 per
  PSU" anche quando le PSU più piccole ne contenevano meno e venivano
  prese tutte; ora riporta "fino a b = 10 per PSU (nelle PSU più piccole
  tutte le unità)".
- **Campionamento casuale semplice**: con reinserimento `n/N` non è una
  frazione di campionamento (può superare 1, perché conta le estrazioni
  e non le unità distinte); in quello schema la colonna si intitola ora
  "Rapporto estrazioni/popolazione n/N".

## Nuove possibilità didattiche

- **Cluster analysis su dati misti**: la base della segmentazione accetta
  ora anche variabili **categoriali** (`permitted: [numeric, factor]`) e
  i tipi vengono preservati lungo tutta la preparazione dei dati. In
  precedenza tutto veniva forzato a numerico, il che rendeva
  irraggiungibile proprio il caso d'uso principale della distanza di
  Gower (dataset misti quantitativi + qualitativi) e obbligava a
  ricodificare a mano i fattori per il Jaccard politomico. I cluster
  ottenuti coincidono con `cluster::daisy()` applicata direttamente al
  data frame misto.
  - Le distanze quantitative (Euclidea, Manhattan, Mahalanobis) con
    variabili categoriali in input vengono rifiutate con un messaggio
    che indirizza a Gower.
  - R², RMSSTD e indice CH sono definiti sulla devianza rispetto ai
    centroidi e non sono calcolabili su basi non quantitative: con dati
    misti restano vuoti, con una nota in tabella. **Delta G**, che
    dipende solo dalle altezze di fusione, resta disponibile.

## Robustezza

- **Stato del generatore casuale**: le sei analisi di estrazione
  ripristinavano `.Random.seed` solo se esisteva già; se il generatore
  non era ancora stato inizializzato, `set.seed()` lo creava e restava
  nella sessione. Ora in quel caso viene rimosso, lasciando la sessione
  esattamente come era.
- **Numerosità campionaria**: `P = 0` e `P = 1` sono rifiutati con un
  messaggio che suggerisce il caso più sfavorevole `P = 0.5` (davano
  varianza nulla, n = 0 e SE indefinito).
- **Intervalli di confidenza**: `n > N` con correzione attiva viene
  rifiutato invece di essere ignorato in silenzio.
- **Design Effect**: ρ sotto il limite inferiore ammissibile per l'ICC
  (`ρ ≥ −1/(n−1)`) viene rifiutato con un messaggio che esplicita il
  vincolo; Deff = 0 non è più accettato come risultato valido.

## Impostazioni predefinite

- **Intervalli di confidenza**: il fattore correttivo per popolazioni
  finite è ora **disattivato di default** (era attivo con `N = 1000`).
  Con il default precedente uno studente otteneva un intervallo corretto
  per una popolazione di 1000 unità senza averlo mai dichiarato, e con
  n = 1000 l'errore standard si annullava producendo un risultato
  apparentemente perfetto ma dovuto interamente al valore di default.
  La correzione va ora attivata consapevolmente, dichiarando la N reale.

## Test

- Suite estesa a **268 test** (erano 221), tutti verdi sia in italiano
  sia in inglese. Nuove regressioni per: definizione one-hot del Jaccard
  politomico, ARI sui casi degeneri e confronto con la formula di
  Hubert-Arabie, probabilità di selezione/inclusione nel CPV, invarianza
  di autovalori e scree plot alla rotazione, additività delle SS
  loadings solo sotto Varimax, Gower su dati misti confrontato con
  `daisy()`, coerenza fra i moduli sulla FPC, ripristino del RNG,
  etichette di due stadi e reinserimento.

# AnalisiMercato 2.0.3

Rilascio di correzione a valle della revisione completa del codice
(audit multi-agente su tutte le 13 analisi).

## Correzioni critiche

- **Campionamento stratificato**: uno strato con una sola unità faceva
  scattare la trappola di `sample()` su input scalare — `sample(pool, 1)`
  con `pool = 47` estrae da `1:47`, non la riga 47. Veniva marcata come
  campionata una riga a caso del dataset (nell'88% dei casi sbagliata,
  potenzialmente di un altro strato). Ora `pool[sample.int(length(pool), ...)]`.
- **Cluster gerarchico, colonna iniettata**: la ricostruzione del
  data.frame distruggeva i rownames di `self$data`, che in jamovi
  veicolano gli indici di riga originali. Con un filtro attivo le
  etichette cluster finivano silenziosamente sulle righe sbagliate
  (incluse quelle filtrate). I rownames ora vengono preservati.
- **PCA**: con variabili supplementari e un asse del grafico oltre
  `ncp` (senza rotazione) l'intera analisi moriva con "subscript out of
  bounds", tabelle comprese. Le matrici supplementari vengono tagliate
  a `ncp` solo quando serve (rotazione attiva).
- **catdes**: `catdes.r.yaml` dichiarava `visible: false` su tutti e 4 i
  gruppi di risultati ma il codice non li rendeva mai visibili; il
  modulo funzionava solo perché i `.h.R` erano rimasti alla 2.0.1.
  La rigenerazione (necessaria per il rilascio) avrebbe reso l'intero
  output permanentemente invisibile. Rimossi i `visible: false`.

## Correzioni maggiori

- **Campionamento sistematico** ora **circolare** (Lahiri): partenza
  casuale in 1..N anziché 1..k. Prima le ultime N − k·n unità avevano
  probabilità di inclusione **zero** (con N=100, n=30: 10 unità mai
  campionabili); ora ogni unità ha probabilità esattamente n/N, come
  già promesso (ma non mantenuto) dalle istruzioni.
- **PCA + Promax**: i baricentri delle qualitative supplementari erano
  ruotati con `T` invece della convenzione obliqua `(T')⁻¹` usata per
  gli individui: nel piano ruotato finivano staccati dalla nuvola che
  riassumono (errore fino a 1.2 su iris). Ora coincidono col baricentro
  degli individui ruotati (diff < 1e-14).
- **PCA non standardizzata + rotazione**: i cos² erano quadrati di
  covarianze (valori fino a ~10⁴, heatmap fuori scala). Ora i cos² sono
  i quadrati delle **correlazioni** con le componenti ruotate
  (R·(T')⁻¹): sempre in [0,1]; nel caso standardizzato il risultato è
  identico a prima (convenzione psych/SPSS).
- **PCA, cerchio delle correlazioni**: con `standardize = FALSE`
  disegnava covarianze sul cerchio unitario (frecce clippate fuori
  scala). Ora usa sempre correlazioni (`res$var$cor` /
  `res$quanti.sup$cor`, ruotate coerentemente).
- **PCA**: una variabile attiva costante generava una componente
  fantasma con autovalore esattamente 1 che inquinava il criterio di
  Kaiser; ora viene rifiutata con un messaggio esplicito. Stesso guard
  in **HC** per la standardizzazione (prima: errore grezzo
  "missing value where TRUE/FALSE needed", riproducibile perfino con
  `iris[1:5, ]`).
- **HC**: `k = n` veniva accettato ma `rect.hclust` falliva
  (immagine del dendrogramma in errore): ora rifiutato con messaggio.
- **PCA, plot stantii**: aggiunte le opzioni mancanti nei `clearWith`
  delle immagini (`supp_quant` e `ncp` per il cerchio; `ncp` per biplot
  e mappa). Prima jamovi riusava il PNG obsoleto.
- **catdes, due crash riproducibili**: livello del fattore Cluster
  inutilizzato (raggiungibile coi filtri jamovi: indicizzazione
  posizionale vs `droplevels()` interno di FactoMineR) e descrittore
  quantitativo con Eta² significativo ma nessun v-test per-cluster.
  Iterazione per nomi, guard sui NULL e match esatto di "quanti".

## Correzioni minori

- `format(N, big.mark = ".")` senza `decimal.mark` emetteva un warning R
  a ogni esecuzione con FPC (confint, samplesize).
- samplesize: P = 0 e P = 1 producevano n = 0 e SE = NaN; ora rifiutati
  con suggerimento del caso conservativo P = 0.5.
- confint: n > N con FPC attivo veniva ignorato in silenzio; ora
  rifiutato con spiegazione (tipico della modalità dataset con N al
  default).
- deff: ρ sotto il bound ICC −1/(m−1) ora rifiutato con messaggio
  didattico; Deff = 0 non passa più i controlli.
- sampleppv: un NA nei pesi bloccava l'intera analisi (rendendo
  irraggiungibile il fallback documentato "NA = peso 0"); ora l'unità
  con peso NA è semplicemente non campionabile, come nelle altre
  estrazioni.
- Tutte e 6 le estrazioni: `set.seed()` ora salva e **ripristina** lo
  stato del RNG globale della sessione jamovi (prima ogni run lasciava
  il generatore in uno stato deterministico condiviso); guard sul seed
  uniformato fra estrazione e tabella riepilogo.
- HC: RMSSTD riportato alla definizione pooled standard con il fattore
  1/p (SAS PROC CLUSTER, Sharma 1996) — prima i valori erano √p volte
  quelli dei libri di testo; centroid linkage ora calcolato su d² con
  altezze riportate in scala (√), come da definizione; per Gower
  documentato che la standardizzazione esplicita non ha effetto
  (daisy() normalizza sempre per range) e descrizione corretta
  (niente più promessa di "dataset misti" con variabili solo numeriche).
- PCA: autovalori ruotati ora **riordinati** in modo decrescente
  permutando la matrice di rotazione (prima lo scree ruotato poteva
  essere non monotono, es. PC3 > PC2); la tabella Impostazioni dichiara
  "Nessuna (Varimax non applicata)" quando la rotazione richiesta non
  è applicabile (prima dichiarava la rotazione anche quando saltata);
  la colorazione dei baricentri regge la collisione di nomi di livello
  fra due qualitative (prefisso FactoMineR "variabile_livello"); nota
  esplicita quando FactoMineR imputa con la media gli NA delle
  supplementari; i titoli di contributi/cos² delle osservazioni
  dichiarano "non ruotati" sotto rotazione; soglia di Kaiser nello
  scree solo per PCA standardizzata; istruzioni italiane allineate al
  calcolo analitico di Φ = (T'T)⁻¹ (descrivevano l'implementazione
  pre-2.0.1).
- samplecluster: il riepilogo riporta il numero di grappoli
  effettivamente estratti anziché ripetere quello richiesto.

## Interfaccia utente

- **Enable-bindings** su tutti i campi ad attivazione condizionata
  (33 binding): n/f secondo `size_mode` nelle 6 estrazioni, b/f_b
  secondo `ssu_mode`, parametri per piano in deff, campi manuali di
  confint disattivati in modalità dataset, variabile ausiliaria attiva
  solo con allocazione ottimale, P/σ secondo il parametro in
  samplesize. Prima i campi inattivi restavano modificabili senza
  effetto.
- ARI: la diagonale della matrice mostra 1 (per definizione) invece di
  cella vuota; catdes: nota "nessun risultato significativo alla
  soglia" al posto di tabelle vuote; HC: etichette delle foglie del
  dendrogramma soppresse sopra le 100 osservazioni.

## Internazionalizzazione

- Completati i `.tr()` mancanti sulle stringhe generate in R: etichette
  di distanze/metodi e assi (HC), titoli/caption/legende dei 5 grafici
  PCA e colonne dinamiche "Autovalore (rot)", etichette di cella in
  confint/deff/samplesize e nelle estrazioni ("Proporzionale",
  "Ottimale (Neyman)", "Con reinserimento", ...). La legenda del biplot
  mostra il nome della variabile invece di "group".
- `.tr()`: la locale `C.UTF-8` (comune su Linux) è ora trattata come
  locale non impostata (fallback su LC_ALL).

## Test

- Suite estesa da 70 a **221 expectations**, 0 warning (prima 11):
  nuovo `test-sampling-extraction.R` (strato singleton, copertura del
  sistematico circolare, determinismo del seed, Σn_j = n, ripristino
  RNG, pesi NA in CPV) e regressioni per tutti i crash corretti (PCA
  assi>ncp, cos² non standardizzati, autovalori ruotati ordinati,
  variabile costante, catdes livelli inutilizzati / Eta² senza v-test /
  target character).
- Pattern bilingui negli `expect_error`: la suite passa sia in locale
  italiana sia inglese (prima 3 test fallivano con LC_MESSAGES=en).

# AnalisiMercato 2.0.2

Bilinguismo completo italiano / inglese e tour finale prima della
submission al Jamovi Library.

## Internazionalizzazione

- **Catalogo `en.po` completato**: tutte le 369 stringhe estratte da
  `R/` e da `jamovi/*.yaml` ora hanno traduzione inglese (in 2.0.1
  ne erano tradotte 289 / 369).
- **Pannelli HTML "Istruzioni"**: i 13 blocchi `setContent("<html>…</html>")`
  in cima a ogni analisi sono ora bilingui. Un helper minimale
  `R/00-i18n.R` definisce `.tr(it, en)` che restituisce la versione
  inglese quando `LC_MESSAGES` inizia con "en"; per ogni altra locale
  ritorna l'originale italiano. Estesa la stessa logica a tutti i
  messaggi `jmvcore::reject()`, `stop()` e `warning()` del modulo
  (~55 messaggi).
- Risultato: con jamovi in inglese, l'utente vede UI, opzioni, tabelle,
  plot, istruzioni e messaggi di errore tutti in inglese; con jamovi
  in italiano, tutto in italiano.

# AnalisiMercato 2.0.1

Rilascio di correzione per i problemi emersi nell'audit post-2.0.0.

## Correttezza statistica

- **PCA, rotazione Promax**: corretto il calcolo della matrice di
  correlazione fra componenti ruotate (Φ) e della *structure matrix*.
  La versione 2.0.0 stimava Φ dalle coordinate degli individui ruotati
  via `cor()`, ottenendo valori sistematicamente sbagliati: in alcuni
  casi i `cos²` superavano 1, valore impossibile per definizione. Φ è
  ora calcolata analiticamente come `(T'T)^{-1}` dove T è la `rotmat`
  di `stats::promax`. Anche le coordinate degli individui ruotati sotto
  Promax usano ora la convenzione obliqua corretta `F · (T')^{-1}` (per
  Varimax non cambia nulla, essendo T ortogonale).
- **Intervalli di confidenza per la media**: errore standard riportato
  alla forma standard di Cochran `SE = s/√n · √(1−f)` con `s` la
  deviazione standard campionaria corretta (denominatore n−1). La
  versione precedente usava `s/√(n−1) · √(1−f)`, sovrastimando il SE
  di un fattore √(n/(n−1)) (≈ +5% per n=10, +0.5% per n=100). I due
  testi sono equivalenti se `s` è definita con denominatore n, ma in
  R `stats::sd` usa n−1.

## Interfaccia utente

- **PCA, pannello istruzioni**: rimosso il riferimento ai criteri
  Kaiser e Varianza cumulata come opzioni selezionabili; in 2.0.0 la
  UI esponeva solo la scelta manuale di `ncp`. Il testo ora descrive
  Kaiser, varianza cumulata e gomito come *criteri di lettura* di
  tabella autovalori e scree plot.
- **HC, nome variabile output**: `outputName` ora compare nel
  `clearWith` di `label_cluster`. Cambiare il nome della colonna
  iniettata aggiorna correttamente l'output.
- **Samplesize, Δ per la media**: rimosso il vincolo `max: 1` sul
  margine di errore. In 2.0.0 era impossibile chiedere il calcolo
  della numerosità per una media con margine superiore a 1 (es. ±2
  punti); il vincolo `Δ < 1` ora si applica solo alla proporzione.
- **Confint, formula nelle istruzioni**: aggiornata coerentemente
  alla nuova forma standard `s/√n`.

## Coerenza interna

- `catdes.b.R`: aggiunto `quietly = TRUE` a `requireNamespace('jmvcore')`
  per uniformità con tutti gli altri moduli.
- `0000.yaml`: aggiunto `languages: [it, en]` (era dichiarato in
  NEWS.md di 2.0.0 ma mancante nel file).

## Documentazione e test

- Rigenerati i file di help `.Rd` (`devtools::document()`) per tutti
  e 13 i moduli; in 2.0.0 erano presenti solo `ari.Rd`, `catdes.Rd`,
  `hc.Rd` (risalenti al 2024).
- Creato il catalogo i18n inglese in `jamovi/i18n/en.po` con 369
  stringhe estratte automaticamente da `R/` e `jamovi/*.yaml`; **289
  stringhe tradotte** (titoli analisi, menu, opzioni, plot, colonne
  tabelle, livelli enumerati). Le 80 stringhe rimanenti sono
  descrizioni lunghe da tooltip — da rifinire alla bisogna.
- Rimossa la cartella vuota `inst/i18n/` (in 2.0.0 era nella
  posizione sbagliata: jamovi cerca i cataloghi in `jamovi/i18n/`).
- Estesa la suite di test `testthat`: aggiunti **51 nuovi smoke test**
  per i 4 moduli che ne erano sprovvisti in 2.0.0:
  - `test-pca.R` (15 test): rotazioni Varimax/Promax, cos² ≤ 1,
    contributi sommano a 100, supplementari quanti/quali, edge case.
  - `test-confint.R` (12 test): modalità manuale + dataset,
    SE Cochran, FPC, rifiuto success level inesistente.
  - `test-deff.R` (11 test): tutte le formule analitiche + rifiuti.
  - `test-samplesize.R` (13 test): proporzione/media in SSR/SCR
    confrontati con formule di riferimento. Totale suite: **73 test**.
- **Deff**, formule analitiche meglio documentate nelle istruzioni HTML
  e nei commenti del codice. Le formule restano invariate, ma è ora
  esplicito il *contesto di validità*:
  - Sistematico `(k+1)/(N+1)`: caso di popolazione con trend lineare
    perfetto (Cochran 1977, Theorem 8.6). Per ordinamento casuale
    Deff ≈ 1; per ordinamento periodico col passo k pari al periodo
    Deff > 1.
  - Stratificato `1 − R²·(L²−1)/L²`: stratificazione di una variabile
    continua X in L classi equiampie, R² = ρ²(X,Y) (Cochran 1977
    Eq. 5.51). Per L → ∞ tende all'ideale 1 − R².

## Note su distribuzione cross-platform

- Il `.jmo` viene generato da `jmvtools::install()` per l'architettura
  di chi lo costruisce: macOS-Apple-Silicon (arm64) nel build di
  riferimento. **Su Windows e Linux il file non funziona** perché le
  librerie native delle dipendenze (FactoMineR, flashClust, httpuv,
  later, lazyeval, leaps, promises) sono `.so` macOS e mancano i
  rispettivi `.dll`/`.so` Linux.
- Soluzioni per la distribuzione su più piattaforme:
  1. Pubblicare il modulo sul **Jamovi Library**
     (https://library.jamovi.org), che effettua il build automatico
     per Windows/macOS/Linux a partire dal sorgente.
  2. Compilare un `.jmo` separato su ogni piattaforma target
     (con `jmvtools::install()` su una macchina Windows e una Linux).
- Il **codice R del modulo è già completamente portabile**: nessun
  path hardcoded, nessuna chiamata OS-specifica, file UTF-8 con
  line ending LF, nessun codice C/C++ da compilare nel modulo stesso.
- Se un utente Windows riceve il `.jmo` rinominato in `.zip` (effetto
  di alcuni client di posta/antivirus che riconoscono il container ZIP
  e cambiano l'estensione), il file *non funziona comunque* su Windows
  per il punto precedente: serve un `.jmo` buildato per Windows, non
  basta rinominare.

# AnalisiMercato 2.0.0

Rilascio di consolidamento. Refactor profondo del calcolo statistico, della
performance e della UI, allineamento agli standard jamovi attuali.

## Correzioni di correttezza statistica

- **Distanza di Mahalanobis a coppie** ora calcolata correttamente come
  `sqrt((xᵢ−xⱼ)ᵀ S⁻¹ (xᵢ−xⱼ))` via trasformazione di Cholesky. La versione
  precedente calcolava distanze 1-D fra outlier-scores dei singoli punti dal
  centroide, non distanze fra coppie.
- **Sokal-Michener** vettorializzato e generalizzato al Simple Matching per
  dati politomici; identico al classico SM per dati 0/1.
- **Jaccard politomico** rivisto con denominatore corretto (unione di
  variabili "presenti" anziché numero totale di variabili).
- **Standardizzazione**: ora applicata solo alle distanze numeriche
  (Euclidea, Manhattan, Mahalanobis); ignorata per distanze
  binarie/categoriche/Gower.
- **Adjusted Rand Index**: gestione robusta dei valori mancanti (esclusione
  pairwise), guard sul denominatore degenere.
- **Metriche di partizionamento (R², RMSSTD, CH)**: gestione corretta di
  cluster con singola osservazione, varianza totale nulla, e n = k.

## Robustezza

- Guard espliciti su input insufficienti (`vars < 2`, `nrow < n_clusters`).
- Memory guard sulla matrice n × n: warning oltre ~200 MB, rifiuto oltre
  ~1 GB con suggerimento metodologico.
- Validazione binaria su SM/Jaccard con warning informativo se i dati non
  sono 0/1.
- In catdes: fix dei loop `for (i in 2:nlev)` che esplodevano con un solo
  livello; sostituzione di `names(x) == "call"` con `identical(...)`; guard
  sul caso "nessuna categoria significativa".
- `dataProcessed` forzato a `data.frame` base in catdes per evitare
  comportamenti diversi se jamovi passa tibble.

## Performance

- **Fast path BLAS** per SM e Jaccard su dati 0/1 via `tcrossprod`:
  **~250× più veloce** a n=1000 rispetto alla versione precedente con
  `Vectorize` + `outer`.
- **Loop delle metriche** rifattorizzato: `total_ss` e `overall_mean`
  calcolati una sola volta, `cutree(hc, k = 2:max_g)` in una singola
  chiamata, centroidi via `rowsum`, identità di Huygens
  `WSS = TSS − BSS`. **~50× più veloce** sul blocco metriche.
- Popolamento tabelle jamovi in singola passata (eliminato
  anti-pattern `addRow` parziale + `setRow`).

## Interfaccia utente

- **Opzioni dimensioni grafici rinominate** con nomi parlanti:
  `width_dend`, `height_dend`, `width_r2`, `height_r2`, `width_rmsstd`,
  `height_rmsstd`, `width_deltaG`, `height_deltaG`, `width_ch`, `height_ch`
  (in precedenza `width1`...`width4`).
- I controlli larghezza/altezza **compaiono solo quando** la rispettiva
  checkbox del grafico è spuntata (`visible: (option)`).
- Nuova opzione **`outputName`** per scegliere il nome della colonna di
  output del clustering (default "Cluster").
- **Dendrogramma migliorato**: rami colorati per cluster, linea
  orizzontale di taglio al k scelto, asse y "Distanza".
- Refusi corretti nelle istruzioni: *dedrogramma* → dendrogramma,
  *quttro* → quattro, *Caliníksi* → Calinski, "valutazioni valutate" →
  "partizioni valutate".
- `stage: 0` → `stage: 1` (modulo production-ready).

## Compatibilità jamovi

- Creato `jamovi/refs.yaml` con definizioni `factominer` e `explo`,
  che mancavano e da jamovi 2.4 in poi bloccavano `jmvtools::prepare()`.
- `minApp: 1.0.8` → `2.3.0` (allineamento al floor moderno).
- `jmvcore (>= 0.8.5)` → `(>= 2.4.0)` in `DESCRIPTION`.
- Verificate tutte le API jmvcore usate su jamovi 2.6.x.
- Versioni allineate a `2.0.0` in tutti i `.yaml` e nel `DESCRIPTION`.

## Internazionalizzazione

- Nuovo `inst/i18n/catalog.pot` (template gettext) con ~80 stringhe.
- Nuovo `inst/i18n/en.po` con traduzione inglese completa.
- `defaultLanguage: it`, `languages: [it, en]` in `0000.yaml`.

## Documentazione e sostenibilità

- **`NEWS.md`** (questo file).
- **Descrizioni dei parametri** popolate via campo `description: R: ...`
  nei `.a.yaml`; quando `jmvtools::prepare()` rigenera i `.h.R`, i
  `@param` roxygen vengono valorizzati di conseguenza.
- **Smoke tests** con `testthat` in `tests/testthat/`:
  - `test-hc.R`: HC su iris con Ward + Euclidea, Mahalanobis, Sokal-Michener,
    guard su input insufficiente, k > n.
  - `test-ari.R`: ARI=1 con partizione vs se stessa, ARI≈0 con partizioni
    random, gestione NA.
  - `test-catdes.R`: catdes/condes su iris, gestione cluster a livello unico.
- Campo `text` non usato rimosso da `hc.r.yaml`.
- `DESCRIPTION` modernizzato: `Authors@R`, rimosso `LazyData: true` e la
  dipendenza non usata `factoextra`.

## Dipendenze

- Aggiunta **`dendextend`** per la colorazione del dendrogramma.
- Rimossa `factoextra` (mai usata nel codice).
- `testthat` aggiunto in `Suggests`.

# AnalisiMercato 1.0.2 e precedenti

Versioni didattiche iniziali. Vedere repository per dettagli.
