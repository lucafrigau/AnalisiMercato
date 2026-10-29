# This file is a generated template, your changes will not be overwritten

pcaClass <- if (requireNamespace('jmvcore', quietly = TRUE)) {
  R6::R6Class(
    "pcaClass",
    inherit = pcaBase,
    private = list(
      .pca_res = NULL,
      .ncp_used = NULL,
      .rot = NULL,
      .ind_coords = NULL,

      .init = function() {
        # Dimensioni custom della mappa di posizionamento.
        # Applicato qui (in .init) come fa hc.b.R per i suoi plot — è il
        # punto in cui jamovi crea il contenitore dell'immagine e applica
        # le dimensioni di rendering.
        if (isTRUE(self$options$plot_map)) {
          mw <- self$options$map_width
          mh <- self$options$map_height
          if (!is.null(mw) && !is.null(mh) &&
              is.finite(mw) && is.finite(mh) &&
              mw >= 100 && mh >= 100) {
            self$results$plot_map$setSize(mw, mh)
          }
        }

        self$results$instructions$setContent(.tr(
          it = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Analisi delle Componenti Principali (PCA)</h3>
              <p>
                Tecnica di riduzione della dimensionalità che trasforma le
                variabili originali in nuove variabili (le componenti
                principali) tra loro ortogonali. Le componenti sono ordinate
                per varianza spiegata decrescente. Obiettivi tipici:
                sintesi, visualizzazione, eliminazione della
                multicollinearità.
              </p>
              <p>
                <b>Standardizzazione</b>: raccomandata quando le variabili
                hanno unità di misura o varianze diverse; la PCA opera in
                tal caso sulla matrice di correlazione.
              </p>
              <p>
                <b>Numero di componenti</b>: scelta manuale (1–5). Per
                orientarsi nella scelta si possono consultare:
                <ul>
                  <li>la tabella degli <i>autovalori</i> (criterio di
                  Kaiser: ritenere le componenti con λ &gt; 1 quando la
                  PCA è standardizzata);</li>
                  <li>la percentuale di <i>varianza cumulata</i>
                  (soglie tipiche 70–80%);</li>
                  <li>lo <i>scree plot</i> (criterio del gomito).</li>
                </ul>
              </p>
              <p>
                <b>Output prodotto</b>:
                <ul>
                  <li>Autovalori, % varianza, scree plot.</li>
                  <li>Per ogni variabile: coordinate (loadings),
                  contributi %, coseni² (qualità di rappresentazione).</li>
                  <li>Cerchio delle correlazioni (proiezione delle variabili
                  nel piano delle prime due componenti).</li>
                  <li>Biplot delle osservazioni (eventualmente colorate da
                  una variabile categoriale supplementare).</li>
                  <li>Coordinate degli individui iniettate come nuove
                  colonne PC1, PC2, ... nel dataset.</li>
                </ul>
              </p>
              <p>
                <b>Rotazione</b>: opzionalmente i loadings delle componenti
                ritenute vengono ruotati per facilitare l'interpretazione.
              </p>
              <ul>
                <li><b>Varimax</b> (ortogonale): le componenti ruotate
                restano incorrelate. La varianza totale spiegata è
                preservata e viene <i>ridistribuita</i> fra le componenti.
                I coseni quadrati (cos²) si calcolano direttamente come
                quadrato dei loadings ruotati: rappresentano la quota di
                varianza di ciascuna variabile spiegata dalla componente.</li>
                <li><b>Promax</b> (obliqua): le componenti ruotate possono
                essere correlate. Il risultato è la <i>pattern matrix</i>
                (coefficienti di regressione delle variabili sulle
                componenti). Per cos² e contributi questo modulo usa la
                <i>structure matrix</i> S = P · Φ (dove Φ è la matrice di
                correlazione fra le componenti ruotate, calcolata
                analiticamente come (T'T)⁻¹ dalla matrice di rotazione T),
                che è l'analogo interpretabile dei loadings nel caso
                ortogonale.</li>
              </ul>
              <p>
                <b>Autovalori e rotazione.</b> La rotazione non modifica gli
                autovalori della PCA: la tabella degli autovalori, le
                percentuali di varianza e lo scree plot restano sempre
                quelli della soluzione originale, perché servono a
                <i>decidere</i> quante componenti ritenere, decisione che
                precede la rotazione. Le somme dei quadrati dei loadings
                dopo la rotazione (<i>SS loadings</i>) sono riportate in una
                tabella separata: con Varimax la varianza complessiva delle
                componenti ritenute è preservata e solo ridistribuita fra
                di esse; con Promax le componenti sono correlate, quindi le
                quote di varianza <i>non sono sommabili</i> e non vengono
                riportate.
              </p>
            </div>
            </body>
            </html>",
          en = "<html>
            <head></head>
            <body>
            <div class='justified-text'>
              <h3>Principal Component Analysis (PCA)</h3>
              <p>
                A dimensionality-reduction technique that transforms the original
                variables into new variables (principal components) that are mutually
                orthogonal. Components are ordered by decreasing explained variance.
                Typical goals: data summarisation, visualisation, and removal of
                multicollinearity.
              </p>
              <p>
                <b>Standardisation</b>: recommended when variables have different
                units or variances; in that case PCA operates on the correlation
                matrix.
              </p>
              <p>
                <b>Number of components</b>: chosen manually (1–5). To support the
                choice, consult:
                <ul>
                  <li>the <i>eigenvalues</i> table (Kaiser criterion: retain
                  components with λ &gt; 1 when PCA is standardised);</li>
                  <li>the <i>cumulative variance</i> percentage (typical thresholds
                  70–80%);</li>
                  <li>the <i>scree plot</i> (elbow criterion).</li>
                </ul>
              </p>
              <p>
                <b>Output produced</b>:
                <ul>
                  <li>Eigenvalues, % variance, scree plot.</li>
                  <li>For each variable: coordinates (loadings), contributions (%),
                  squared cosines (representation quality).</li>
                  <li>Correlation circle (projection of variables on the plane of the
                  first two components).</li>
                  <li>Observations biplot (optionally coloured by a supplementary
                  categorical variable).</li>
                  <li>Individual coordinates injected as new columns PC1, PC2, … in
                  the dataset.</li>
                </ul>
              </p>
              <p>
                <b>Rotation</b>: optionally the loadings of retained components are
                rotated to ease interpretation.
              </p>
              <ul>
                <li><b>Varimax</b> (orthogonal): rotated components remain
                uncorrelated. Total explained variance is preserved and
                <i>redistributed</i> among the components. Squared cosines (cos²)
                are simply the squared rotated loadings: they represent the share
                of each variable's variance explained by each component.</li>
                <li><b>Promax</b> (oblique): rotated components may be correlated.
                The result is the <i>pattern matrix</i> (regression coefficients of
                variables on components). For cos² and contributions this module
                uses the <i>structure matrix</i> S = P · Φ (where Φ is the
                correlation matrix among rotated components, computed analytically
                from the rotation matrix), the oblique analogue of the loadings in
                the orthogonal case.</li>
              </ul>
              <p>
                <b>Eigenvalues and rotation.</b> Rotation does not change the
                PCA eigenvalues: the eigenvalue table, the variance
                percentages and the scree plot always refer to the original
                solution, because they serve to <i>decide</i> how many
                components to retain — a decision that precedes rotation.
                The sums of squared loadings after rotation (<i>SS
                loadings</i>) are reported in a separate table: under
                Varimax the total variance of the retained components is
                preserved and merely redistributed among them; under Promax
                the components are correlated, so variance shares are
                <i>not additive</i> and are not reported.
              </p>
            </div>
            </body>
            </html>"
        ))
      },

      .run = function() {
        if (is.null(self$data)) return()
        vars <- self$options$vars
        if (is.null(vars) || length(vars) < 2) return()

        # Ripristino dello stato "senza rotazione" a ogni esecuzione.
        # setTitle() e setVisible() sopravvivono al ricalcolo dei
        # risultati: senza questo reset, tornando da Varimax/Promax a
        # "Nessuna" resterebbero i titoli "— ruotati (…)" e la tabella
        # delle SS loadings visibile ma vuota. Le modifiche vengono
        # riapplicate più sotto quando la rotazione è effettivamente
        # attiva.
        self$results$var_coord$setTitle(
          .tr(it = "Coordinate delle variabili (loadings)",
              en = "Variable coordinates (loadings)"))
        self$results$var_contrib$setTitle(
          .tr(it = "Contributi delle variabili (%)",
              en = "Variable contributions (%)"))
        self$results$var_cos2$setTitle(
          .tr(it = "Coseni quadrati delle variabili (cos²)",
              en = "Squared cosines of the variables (cos²)"))
        self$results$ind_group$ind_coord$setTitle(
          .tr(it = "Coordinate delle osservazioni",
              en = "Observation coordinates"))
        self$results$ind_group$ind_contrib$setTitle(
          .tr(it = "Contributi delle osservazioni (%)",
              en = "Observation contributions (%)"))
        self$results$ind_group$ind_cos2$setTitle(
          .tr(it = "Coseni quadrati delle osservazioni (cos²)",
              en = "Squared cosines of the observations (cos²)"))
        self$results$ss_loadings$setVisible(FALSE)

        if (!requireNamespace("FactoMineR", quietly = TRUE)) {
          jmvcore::reject(.tr(
            it = "Il pacchetto 'FactoMineR' non è disponibile nel runtime di jamovi.",
            en = "Package 'FactoMineR' is not available in the jamovi runtime."
          ), code = "")
        }

        # --- preparazione dati ---
        raw <- as.data.frame(self$data, stringsAsFactors = FALSE)
        # forziamo tutte le attive a numeric, filtriamo NA
        actives <- raw[, vars, drop = FALSE]
        actives <- as.data.frame(lapply(actives, function(x) as.numeric(x)))
        names(actives) <- vars

        supp_q   <- self$options$supp_quant
        supp_qul <- self$options$supp_qual
        supp_qul_map <- self$options$supp_qual_map
        id_name  <- self$options$id_var

        df_for_pca <- actives
        idx_supp_quant <- integer(0)
        idx_supp_qual  <- integer(0)

        # aggiungiamo eventuali variabili quantitative supplementari
        if (!is.null(supp_q) && length(supp_q) > 0) {
          sup_q_df <- as.data.frame(lapply(raw[, supp_q, drop = FALSE], as.numeric))
          names(sup_q_df) <- supp_q
          df_for_pca <- cbind(df_for_pca, sup_q_df)
          idx_supp_quant <- (ncol(actives) + 1):(ncol(actives) + length(supp_q))
        }
        # aggiungiamo le qualitative supplementari (unione di supp_qual + supp_qual_map)
        qual_names <- character(0)
        if (!is.null(supp_qul) && nzchar(supp_qul)) qual_names <- c(qual_names, supp_qul)
        if (!is.null(supp_qul_map) && length(supp_qul_map) > 0) {
          qual_names <- c(qual_names, setdiff(supp_qul_map, qual_names))
        }
        if (length(qual_names) > 0) {
          for (qn in qual_names) {
            df_for_pca[[qn]] <- as.factor(raw[[qn]])
          }
          idx_supp_qual <- seq(ncol(df_for_pca) - length(qual_names) + 1L, ncol(df_for_pca))
        }

        # rimuoviamo righe con NA in qualsiasi colonna attiva (FactoMineR
        # gestisce NA sulle supplementari, ma per semplicità eliminiamo solo
        # quelle dove le attive sono incomplete)
        keep <- stats::complete.cases(actives)
        df_for_pca <- df_for_pca[keep, , drop = FALSE]
        if (nrow(df_for_pca) < 3) {
          jmvcore::reject(.tr(
            it = "Servono almeno 3 osservazioni complete sulle variabili attive.",
            en = "At least 3 complete observations on the active variables are required."
          ), code = "")
        }

        # Variabili attive costanti: con la PCA standardizzata FactoMineR
        # produrrebbe una componente fantasma con autovalore esattamente 1
        # (che inquina proprio il criterio di Kaiser); senza
        # standardizzazione la variabile non porta comunque informazione.
        sds_act <- vapply(df_for_pca[, vars, drop = FALSE],
                          stats::sd, numeric(1))
        vars_costanti <- vars[!is.finite(sds_act) | sds_act == 0]
        if (length(vars_costanti) > 0) {
          jmvcore::reject(
            sprintf(.tr(
              it = "Le seguenti variabili attive sono costanti (deviazione standard nulla) sulle osservazioni valide: %s. Una variabile costante non porta informazione alla PCA: rimuoverla dall'analisi.",
              en = "The following active variables are constant (zero standard deviation) on the valid observations: %s. A constant variable carries no information for the PCA: remove it from the analysis."
            ), paste(vars_costanti, collapse = ", ")),
            code = ""
          )
        }

        # --- PCA con FactoMineR ---
        ncp_max <- min(ncol(actives), nrow(df_for_pca) - 1)
        scale_unit <- isTRUE(self$options$standardize)
        res <- FactoMineR::PCA(
          df_for_pca,
          scale.unit  = scale_unit,
          ncp         = ncp_max,
          quanti.sup  = if (length(idx_supp_quant) > 0) idx_supp_quant else NULL,
          quali.sup   = if (length(idx_supp_qual) > 0) idx_supp_qual else NULL,
          graph       = FALSE
        )
        private$.pca_res <- res

        # autovalori, % varianza
        eig <- res$eig
        n_total <- nrow(eig)

        # --- numero di componenti ritenute (manuale) ---
        ncp_used <- max(1L, min(self$options$ncp, n_total))
        private$.ncp_used <- ncp_used

        # --- ROTAZIONE (calcolata PRIMA delle tabelle/plot, così tutto
        # riflette i valori ruotati quando richiesto) ---
        rotation <- self$options$rotation
        comp_names <- sprintf("PC%d", seq_len(ncp_used))

        rot <- NULL
        if (rotation != "none" && ncp_used >= 2) {
          L_full <- as.matrix(res$var$coord[, seq_len(ncp_used), drop = FALSE])
          rot <- tryCatch({
            if (rotation == "varimax") {
              stats::varimax(L_full, normalize = TRUE)
            } else {
              stats::promax(L_full)
            }
          }, error = function(e) NULL)
          # stats::varimax/promax NON ordinano le componenti ruotate per
          # varianza decrescente (psych/SPSS invece sì): permutiamo le
          # colonne della matrice di rotazione, così tutte le quantità
          # derivate (loadings, scores, baricentri, supplementari) escono
          # già riordinate in modo coerente fra loro.
          if (!is.null(rot)) {
            ssl0 <- colSums(unclass(rot$loadings)^2)
            ord  <- order(ssl0, decreasing = TRUE)
            if (!identical(ord, seq_along(ssl0))) {
              rot$loadings <- rot$loadings[, ord, drop = FALSE]
              rot$rotmat   <- rot$rotmat[, ord, drop = FALSE]
            }
          }
        }

        # --- riempi tabella settings (DOPO il tentativo di rotazione:
        # l'etichetta deve riflettere ciò che è stato applicato davvero,
        # non ciò che è stato richiesto) ---
        std_lbl <- if (scale_unit)
          .tr(it = "Sì (matrice di correlazione)", en = "Yes (correlation matrix)")
        else
          .tr(it = "No (matrice di covarianza)", en = "No (covariance matrix)")
        rot_name <- switch(rotation,
                           varimax = "Varimax",
                           promax  = "Promax",
                           rotation)
        rot_lbl <- if (!is.null(rot)) {
          rot_name
        } else if (rotation != "none") {
          # richiesta ma non applicata (ncp < 2 oppure errore numerico)
          sprintf(.tr(it = "Nessuna (%s non applicata)",
                      en = "None (%s not applied)"), rot_name)
        } else {
          .tr(it = "Nessuna", en = "None")
        }
        self$results$settings$setRow(
          rowNo = 1,
          values = list(
            n_var       = ncol(actives),
            n_obs       = nrow(df_for_pca),
            standardize = std_lbl,
            ncp_used    = ncp_used,
            rotation    = rot_lbl
          )
        )

        # Trasparenza: FactoMineR imputa con la media gli NA delle
        # variabili quantitative supplementari (il suo warning viene
        # inghiottito dal runtime jamovi) — segnaliamolo all'utente.
        if (!is.null(supp_q) && length(supp_q) > 0 &&
            anyNA(raw[keep, supp_q, drop = FALSE])) {
          self$results$settings$setNote("na_sup", .tr(
            it = "Le variabili quantitative supplementari contengono valori mancanti: FactoMineR li imputa con la media della variabile prima della proiezione.",
            en = "The supplementary quantitative variables contain missing values: FactoMineR imputes them with the variable mean before projecting."
          ))
        }

        # --- Matrici "effettive" (ruotate se rot, originali altrimenti) ---
        # Per Varimax (ortogonale, T'T = I) pattern = structure: i cos²
        # classici `L²` sono validi e Φ = I.
        # Per Promax (obliqua, T'T ≠ I) `rot$loadings` è la *pattern
        # matrix* P = L·T, non la structure. Per i cos² e i contributi si
        # usa la structure matrix S = P·Φ con Φ = (T'T)^{-1}. Le
        # coordinate degli individui ruotati seguono la convenzione
        # obliqua F_new = F_orig · (T')^{-1} (per varimax coincide con
        # F·T essendo T ortogonale).
        # Correlazioni variabile–componente su TUTTE le componenti. Per la
        # PCA standardizzata coincidono con le coordinate; con
        # standardize = FALSE (matrice di covarianza) differiscono di un
        # fattore pari alla dev.std. della variabile, e sono la quantità
        # giusta per cos² e cerchio delle correlazioni.
        cor_active_all <- as.matrix(res$var$cor)

        cor_rot <- NULL
        Phi <- NULL          # definita anche senza rotazione: serve più sotto
        if (!is.null(rot)) {
          loadings_eff <- unclass(rot$loadings)   # pattern (= structure se varimax)
          rotmat       <- rot$rotmat
          ind_orig_k   <- as.matrix(res$ind$coord[, seq_len(ncp_used), drop = FALSE])

          # Correlazioni variabili–componenti ruotate: R_rot = R · (T')⁻¹
          # (structure in scala di correlazione). Per Varimax T è
          # ortogonale e (T')⁻¹ = T; nella PCA standardizzata questa è la
          # convenzione classica psych::principal / SPSS. I cos² sono i
          # quadrati di queste correlazioni: sempre in [0, 1], anche con
          # standardize = FALSE (dove i quadrati delle coordinate ruotate
          # sarebbero covarianze al quadrato, arbitrariamente grandi).
          cor_rot <- cor_active_all[, seq_len(ncp_used), drop = FALSE] %*%
            solve(t(rotmat))
          rownames(cor_rot) <- rownames(res$var$cor)
          cos2_eff <- cor_rot^2

          if (rotation == "promax") {
            # Matrice di correlazione fra le componenti ruotate
            Phi <- solve(t(rotmat) %*% rotmat)
            # Structure matrix (in scala coordinate): S = P·Φ = L·(T')⁻¹
            structure_mat <- loadings_eff %*% Phi
            ssl         <- colSums(structure_mat^2)
            contrib_eff <- sweep(structure_mat^2, 2, ssl, "/") * 100
            # Coordinate individui in convenzione obliqua
            ind_coord_eff <- ind_orig_k %*% solve(t(rotmat))
          } else {
            # Varimax: pattern = structure, Φ = I.
            ssl         <- colSums(loadings_eff^2)
            contrib_eff <- sweep(loadings_eff^2, 2, ssl, "/") * 100
            ind_coord_eff <- ind_orig_k %*% rotmat
          }

          # I prodotti matriciali con la matrice di rotazione (che non ha
          # dimnames) PERDONO i nomi di colonna: vanno riassegnati, altrimenti
          # il codice che li usa — per esempio la heatmap dei cos², che
          # costruisce il data.frame da colnames(cos2) — riceve un vettore
          # vuoto e fallisce. Impostiamo esplicitamente entrambe le
          # dimensioni su tutte le matrici ruotate.
          rownames(loadings_eff)  <- rownames(res$var$coord)
          rownames(cos2_eff)      <- rownames(res$var$cos2)
          rownames(contrib_eff)   <- rownames(res$var$contrib)
          rownames(ind_coord_eff) <- rownames(res$ind$coord)
          rownames(cor_rot)       <- rownames(res$var$cor)
          colnames(loadings_eff)  <- comp_names
          colnames(cos2_eff)      <- comp_names
          colnames(contrib_eff)   <- comp_names
          colnames(ind_coord_eff) <- comp_names
          colnames(cor_rot)       <- comp_names

          # Somme dei quadrati dei loadings dopo la rotazione. NON sono
          # autovalori: la rotazione ridistribuisce la varianza fra le
          # componenti ritenute e le componenti ruotate non sono più le
          # direzioni di massima varianza. Vengono riportate in una
          # tabella dedicata, mentre autovalori, % di varianza e scree
          # plot restano quelli della PCA originale.
          # Con Varimax (ortogonale) la somma totale è preservata e la
          # quota di varianza per componente resta additiva; con Promax
          # (obliqua) le componenti sono correlate e le quote NON sono
          # sommabili — come in SPSS si riporta allora la sola SS.
          ss_loadings <- colSums(loadings_eff^2)
          totvar      <- sum(eig[, 1])
          ss_pct      <- 100 * ss_loadings / totvar
        } else {
          loadings_eff   <- as.matrix(res$var$coord[, seq_len(ncp_used), drop = FALSE])
          cos2_eff       <- as.matrix(res$var$cos2[, seq_len(ncp_used), drop = FALSE])
          contrib_eff    <- as.matrix(res$var$contrib[, seq_len(ncp_used), drop = FALSE])
          ind_coord_eff  <- as.matrix(res$ind$coord[, seq_len(ncp_used), drop = FALSE])
          # Stessi nomi di componente usati nelle tabelle (FactoMineR le
          # chiama "Dim.1", "Dim.2"): così la heatmap dei cos² etichetta
          # le colonne come PC1, PC2 … in ogni configurazione.
          colnames(loadings_eff)  <- comp_names
          colnames(cos2_eff)      <- comp_names
          colnames(contrib_eff)   <- comp_names
          colnames(ind_coord_eff) <- comp_names
          ss_loadings    <- NULL
          ss_pct         <- NULL
        }

        # --- Aggiorna titoli delle tabelle se c'è rotazione ---
        if (!is.null(rot)) {
          suf <- sprintf(.tr(it = " — ruotati (%s)", en = " — rotated (%s)"),
                         rot_name)
          self$results$var_coord$setTitle(paste0(
            .tr(it = "Coordinate delle variabili (loadings)",
                en = "Variable coordinates (loadings)"), suf))
          self$results$var_contrib$setTitle(paste0(
            .tr(it = "Contributi delle variabili (%)",
                en = "Variable contributions (%)"), suf))
          self$results$var_cos2$setTitle(paste0(
            .tr(it = "Coseni quadrati delle variabili (cos²)",
                en = "Squared cosines of the variables (cos²)"), suf))
          # Varimax è ortogonale: contributi e cos² delle osservazioni si
          # ridefiniscono sugli assi ruotati (v. più sotto) e le tre
          # tabelle parlano quindi dello stesso sistema di riferimento.
          # Promax no: gli assi obliqui richiederebbero una convenzione
          # che il modulo non adotta, quindi contributi e cos² restano
          # quelli della soluzione non ruotata e il titolo lo dichiara,
          # per non affiancare quantità riferite ad assi diversi.
          self$results$ind_group$ind_coord$setTitle(paste0(
            .tr(it = "Coordinate delle osservazioni",
                en = "Observation coordinates"), suf))
          if (rotation == "varimax") {
            self$results$ind_group$ind_contrib$setTitle(paste0(
              .tr(it = "Contributi delle osservazioni (%)",
                  en = "Observation contributions (%)"), suf))
            self$results$ind_group$ind_cos2$setTitle(paste0(
              .tr(it = "Coseni quadrati delle osservazioni (cos²)",
                  en = "Squared cosines of the observations (cos²)"), suf))
          } else {
            self$results$ind_group$ind_contrib$setTitle(
              .tr(it = "Contributi delle osservazioni (%) — soluzione PCA non ruotata",
                  en = "Observation contributions (%) — unrotated PCA solution"))
            self$results$ind_group$ind_cos2$setTitle(
              .tr(it = "Coseni quadrati delle osservazioni (cos²) — soluzione PCA non ruotata",
                  en = "Squared cosines of the observations (cos²) — unrotated PCA solution"))
          }
        }

        # --- Tabella autovalori: SEMPRE quelli della PCA originale ---
        # La rotazione non cambia gli autovalori della matrice di
        # correlazione/covarianza: sostituirli con le SS loadings (e
        # cumularle) darebbe una "varianza spiegata" che con le rotazioni
        # oblique non è nemmeno additiva.
        tab_eig <- self$results$eigenvalues
        for (i in seq_len(n_total)) {
          tab_eig$addRow(rowKey = i, values = list(
            comp    = sprintf("PC%d", i),
            eig     = eig[i, 1],
            var_pct = eig[i, 2],
            cum_pct = eig[i, 3]
          ))
        }

        # --- Tabella separata: SS loadings dopo la rotazione ---
        if (!is.null(ss_loadings)) {
          tab_ss <- self$results$ss_loadings
          tab_ss$setVisible(TRUE)
          obliqua <- identical(rotation, "promax")
          for (i in seq_len(ncp_used)) {
            tab_ss$addRow(rowKey = i, values = list(
              comp   = sprintf("PC%d", i),
              ss     = ss_loadings[i],
              # Con rotazione obliqua le quote di varianza non sono
              # sommabili: lasciamo vuote le due colonne percentuali
              # anziché riportare numeri non interpretabili (stessa
              # scelta di SPSS).
              ss_pct = if (obliqua) NA_real_ else ss_pct[i],
              ss_cum = if (obliqua) NA_real_ else cumsum(ss_pct)[i]
            ))
          }
          tab_ss$setNote("ss", if (obliqua)
            .tr(
              it = "Rotazione obliqua (Promax): le componenti ruotate sono correlate fra loro, quindi le somme dei quadrati dei loadings NON sono sommabili e le quote di varianza non vengono riportate. Gli autovalori e la varianza spiegata della tabella precedente restano quelli della PCA originale.",
              en = "Oblique rotation (Promax): the rotated components are correlated, so the sums of squared loadings are NOT additive and variance shares are not reported. The eigenvalues and explained variance in the previous table remain those of the original PCA."
            )
          else
            .tr(
              it = "Rotazione ortogonale (Varimax): la varianza totale spiegata dalle componenti ritenute è preservata, ma viene ridistribuita fra di esse. Gli autovalori della tabella precedente restano quelli della PCA originale.",
              en = "Orthogonal rotation (Varimax): the total variance explained by the retained components is preserved but redistributed among them. The eigenvalues in the previous table remain those of the original PCA."
            ))
        }

        # --- Matrice Phi (solo Promax): correlazioni fra componenti ruotate ---
        # Phi era già calcolata per ricavare la structure matrix, ma non
        # veniva mostrata: senza di lei la correlazione fra componenti non
        # è leggibile da nessuna parte dell'output.
        if (!is.null(Phi)) {
          # Phi è in scala di covarianza fra componenti ruotate: si
          # normalizza a matrice di correlazione (1 sulla diagonale).
          d <- sqrt(diag(Phi))
          Phi_cor <- Phi / outer(d, d)
          for (cn in comp_names)
            self$results$phi$addColumn(name = cn, title = cn, type = "number")
          for (i in seq_len(nrow(Phi_cor))) {
            riga <- as.list(Phi_cor[i, ])
            names(riga) <- comp_names
            self$results$phi$addRow(
              rowKey = i,
              values = c(list(componente = comp_names[i]), riga)
            )
          }
          self$results$phi$setNote("phi", .tr(
            it = "Con Promax le componenti ruotate possono essere correlate: valori fuori diagonale vicini a zero indicano componenti quasi ortogonali, valori più alti in valore assoluto indicano che la rotazione obliqua sta cogliendo relazioni sostanziali fra gli assi.",
            en = "Under Promax the rotated components may be correlated: off-diagonal values close to zero indicate nearly orthogonal components, larger absolute values indicate that the oblique rotation is capturing substantial relations between the axes."
          ))
        }

        # --- Tabelle variabili: aggiungi colonne PC1..PCk e popola con valori effettivi ---
        for (cn in comp_names) {
          self$results$var_coord$addColumn(name = cn, title = cn, type = "number")
          self$results$var_contrib$addColumn(name = cn, title = cn, type = "number")
          self$results$var_cos2$addColumn(name = cn, title = cn, type = "number")
        }
        for (i in seq_len(nrow(loadings_eff))) {
          row_coord <- as.list(loadings_eff[i, ])
          names(row_coord) <- comp_names
          self$results$var_coord$addRow(
            rowKey = i,
            values = c(list(variabile = rownames(loadings_eff)[i]), row_coord)
          )
          row_ctr <- as.list(contrib_eff[i, ])
          names(row_ctr) <- comp_names
          self$results$var_contrib$addRow(
            rowKey = i,
            values = c(list(variabile = rownames(contrib_eff)[i]), row_ctr)
          )
          row_cos <- as.list(cos2_eff[i, ])
          names(row_cos) <- comp_names
          self$results$var_cos2$addRow(
            rowKey = i,
            values = c(list(variabile = rownames(cos2_eff)[i]), row_cos)
          )
        }

        # --- tabella osservazioni (opzionale) ---
        if (isTRUE(self$options$show_ind)) {
          top_k <- min(self$options$top_ind, nrow(ind_coord_eff))

          # Contributi e cos² delle osservazioni.
          #
          # FactoMineR definisce cos²_ik = coord_ik² / d_i², con d_i
          # distanza dell'osservazione dall'origine nello spazio completo,
          # e contrib_ik = 100 · coord_ik² / Σ_i coord_ik².
          #
          # Con Varimax la rotazione è ortogonale e agisce dentro il
          # sottospazio delle componenti ritenute: d_i non cambia, quindi
          # le due definizioni si applicano tali e quali alle coordinate
          # ruotate. I contributi si normalizzano sulla somma dei quadrati
          # del NUOVO asse, perché la rotazione ridistribuisce la varianza
          # fra le componenti (è la stessa logica delle SS loadings).
          #
          # Con Promax gli assi non sono ortogonali: le stesse formule
          # non sono più giustificate e le quantità restano quelle della
          # soluzione non ruotata, dichiarate nel titolo della tabella.
          if (!is.null(rot) && rotation == "varimax") {
            dist2 <- res$ind$dist^2
            ind_cos2_eff    <- sweep(ind_coord_eff^2, 1, dist2, "/")
            ss_axis         <- colSums(ind_coord_eff^2)
            ind_contrib_eff <- sweep(ind_coord_eff^2, 2, ss_axis, "/") * 100
          } else {
            ind_contrib_eff <- as.matrix(res$ind$contrib[, seq_len(ncp_used), drop = FALSE])
            ind_cos2_eff    <- as.matrix(res$ind$cos2[, seq_len(ncp_used), drop = FALSE])
          }
          rownames(ind_contrib_eff) <- rownames(res$ind$contrib)
          rownames(ind_cos2_eff)    <- rownames(res$ind$cos2)

          # ordina per contributo medio sulle prime componenti ritenute
          mean_ctr <- rowMeans(ind_contrib_eff)
          ord <- order(mean_ctr, decreasing = TRUE)[seq_len(top_k)]

          for (cn in comp_names) {
            self$results$ind_group$ind_coord$addColumn(name = cn, title = cn, type = "number")
            self$results$ind_group$ind_contrib$addColumn(name = cn, title = cn, type = "number")
            self$results$ind_group$ind_cos2$addColumn(name = cn, title = cn, type = "number")
          }

          # ID per le osservazioni
          if (!is.null(id_name) && nzchar(id_name)) {
            id_full <- as.character(raw[[id_name]])[keep]
          } else {
            id_full <- as.character(seq_len(nrow(df_for_pca)))
          }

          for (i in seq_along(ord)) {
            idx <- ord[i]
            row_co <- as.list(ind_coord_eff[idx, ])
            names(row_co) <- comp_names
            self$results$ind_group$ind_coord$addRow(
              rowKey = i,
              values = c(list(id = id_full[idx]), row_co)
            )
            row_ct <- as.list(ind_contrib_eff[idx, ])
            names(row_ct) <- comp_names
            self$results$ind_group$ind_contrib$addRow(
              rowKey = i,
              values = c(list(id = id_full[idx]), row_ct)
            )
            row_cs <- as.list(ind_cos2_eff[idx, ])
            names(row_cs) <- comp_names
            self$results$ind_group$ind_cos2$addRow(
              rowKey = i,
              values = c(list(id = id_full[idx]), row_cs)
            )
          }
        }

        # --- assi scelti dall'utente per cerchio / biplot ---
        # Quando c'è rotazione gli assi disponibili sono limitati a ncp_used.
        n_axes_max <- if (!is.null(rot)) ncp_used else n_total
        ax_x <- max(1L, min(self$options$axis_x, n_axes_max))
        ax_y <- max(1L, min(self$options$axis_y, n_axes_max))
        if (ax_x == ax_y) {
          ax_y <- if (ax_x < n_axes_max) ax_x + 1L else max(1L, ax_x - 1L)
        }
        axes <- c(ax_x, ax_y)

        # --- prepara state per i plot ---
        # Nome leggibile della rotazione per le caption dei grafici.
        rot_label <- if (!is.null(rot)) {
          switch(rotation,
                 varimax = "Varimax",
                 promax  = "Promax",
                 rotation)
        } else NULL

        # Lo scree plot mostra SEMPRE gli autovalori della PCA originale:
        # è lo strumento per DECIDERE quante componenti ritenere, quindi
        # deve restare indipendente dalla rotazione (che agisce solo
        # sulle componenti già ritenute).
        eig_for_scree <- eig
        eig_for_lab   <- eig

        # Etichette degli assi. Senza rotazione: la quota di varianza
        # della componente. Con Varimax (ortogonale): la quota ruotata,
        # ancora additiva e interpretabile. Con Promax (obliqua): nessuna
        # percentuale, perché le quote non sono sommabili.
        axis_labels <- vapply(axes, function(ax) {
          if (is.null(rot))
            sprintf(.tr(it = "PC%d (%.1f%%)", en = "PC%d (%.1f%%)"),
                    ax, eig[ax, 2])
          else if (identical(rotation, "promax"))
            sprintf(.tr(it = "PC%d (ruotata)", en = "PC%d (rotated)"), ax)
          else
            sprintf(.tr(it = "PC%d (%.1f%% ruotata)",
                        en = "PC%d (%.1f%% rotated)"),
                    ax, ss_pct[ax])
        }, character(1))

        # Baricentri delle modalità qualitative supplementari (se presenti).
        # Vanno ruotati con la stessa rotmat per coerenza nel piano.
        quali_centroid_full <- NULL
        quali_centroid_group <- NULL
        if (!is.null(res$quali.sup)) {
          # Con rotazione servono esattamente ncp_used colonne (conformi a
          # rotmat); senza rotazione teniamo tutte le componenti, così gli
          # assi scelti dall'utente (fino a n_total) restano indicizzabili.
          qc <- if (!is.null(rot))
            as.matrix(res$quali.sup$coord[, seq_len(ncp_used), drop = FALSE])
          else
            as.matrix(res$quali.sup$coord)
          # I baricentri sono medie di individui: devono subire la stessa
          # trasformazione delle coordinate degli individui — convenzione
          # obliqua (T')^{-1} per promax, T per varimax (dove coincidono
          # essendo T ortogonale).
          if (!is.null(rot)) {
            qc <- if (rotation == "promax")
              qc %*% solve(t(rotmat))
            else
              qc %*% rotmat
          }
          rownames(qc) <- rownames(res$quali.sup$coord)
          quali_centroid_full <- qc
          # Costruisce la mappa modalità → nome variabile, per colorare
          # i baricentri nel plot di posizionamento. FactoMineR usa come
          # rowname il livello "nudo" quando è unico fra le variabili
          # supplementari, ma lo PREFISSA con "variabile_" quando due
          # variabili condividono un livello: copriamo entrambe le forme,
          # senza mai introdurre nomi estranei ai rownames reali.
          quali_centroid_group <- character(nrow(qc))
          names(quali_centroid_group) <- rownames(qc)
          for (qn in qual_names) {
            lvls <- levels(droplevels(as.factor(raw[[qn]])))
            cand <- c(lvls,
                      paste0(qn, "_", lvls),
                      paste0(qn, ".", lvls))
            hit <- cand[cand %in% rownames(qc)]
            if (length(hit) > 0) quali_centroid_group[hit] <- qn
          }
          # Se per qualche motivo non sono stati assegnati, fallback a "—"
          quali_centroid_group[is.na(quali_centroid_group) |
                               !nzchar(quali_centroid_group)] <- "—"
        }

        # Variabili supplementari quantitative ruotate (se rotation).
        quanti_sup_full <- NULL
        if (!is.null(res$quanti.sup)) {
          # Stessa logica dei baricentri: taglio a ncp_used solo con
          # rotazione, altrimenti tutte le componenti restano disponibili.
          qs <- if (!is.null(rot))
            as.matrix(res$quanti.sup$coord[, seq_len(ncp_used), drop = FALSE])
          else
            as.matrix(res$quanti.sup$coord)
          if (!is.null(rot)) qs <- qs %*% rotmat
          rownames(qs) <- rownames(res$quanti.sup$coord)
          quanti_sup_full <- qs
        }

        # Versione in scala di CORRELAZIONE delle supplementari
        # quantitative, per il cerchio delle correlazioni (le coordinate
        # coincidono con le correlazioni solo nella PCA standardizzata).
        quanti_sup_cor <- NULL
        if (!is.null(res$quanti.sup)) {
          qs_cor <- as.matrix(res$quanti.sup$cor)
          if (!is.null(rot)) {
            qs_cor <- qs_cor[, seq_len(ncp_used), drop = FALSE] %*%
              solve(t(rotmat))
          }
          rownames(qs_cor) <- rownames(res$quanti.sup$cor)
          quanti_sup_cor <- qs_cor
        }

        # Helper per estrarre le 2 colonne degli assi scelti
        sub_axes <- function(M) if (is.null(M)) NULL else M[, axes, drop = FALSE]

        if (isTRUE(self$options$plot_scree)) {
          self$results$plot_scree$setState(list(
            eig       = eig_for_scree,
            ncp       = ncp_used,
            rot_label = rot_label
          ))
        }
        if (isTRUE(self$options$plot_circle)) {
          # Il cerchio unitario richiede CORRELAZIONI variabile–componente:
          # con standardize = FALSE le coordinate sono covarianze e le
          # frecce uscirebbero (clippate) dal cerchio di raggio 1.
          coord_for_plot <- if (!is.null(rot)) {
            cor_rot[, axes, drop = FALSE]
          } else {
            cor_active_all[, axes, drop = FALSE]
          }
          self$results$plot_circle$setState(list(
            coord       = coord_for_plot,
            quanti_sup  = sub_axes(quanti_sup_cor),
            eig_for_lab = eig_for_lab,
            axis_labels = axis_labels,
            axes        = axes,
            rot_label   = rot_label
          ))
        }
        if (isTRUE(self$options$plot_biplot)) {
          quali <- if (!is.null(supp_qul) && nzchar(supp_qul)) df_for_pca[[supp_qul]] else NULL
          ind_for_plot <- if (!is.null(rot)) {
            ind_coord_eff[, axes, drop = FALSE]
          } else {
            res$ind$coord[, axes, drop = FALSE]
          }
          var_for_plot <- if (!is.null(rot)) {
            loadings_eff[, axes, drop = FALSE]
          } else {
            res$var$coord[, axes, drop = FALSE]
          }
          # NB: i baricentri qualitativi NON sono inclusi nel biplot
          # (vivono nel plot di posizionamento).
          self$results$plot_biplot$setState(list(
            ind_coord  = ind_for_plot,
            var_coord  = var_for_plot,
            group      = quali,
            group_name = if (!is.null(supp_qul) && nzchar(supp_qul))
              supp_qul else NULL,
            eig        = eig_for_lab,
            axis_labels = axis_labels,
            axes       = axes,
            rot_label  = rot_label
          ))
        }
        if (isTRUE(self$options$plot_cos2)) {
          self$results$plot_cos2$setState(list(
            cos2      = cos2_eff,
            rot_label = rot_label
          ))
        }
        if (isTRUE(self$options$plot_map)) {
          var_for_plot <- if (!is.null(rot)) {
            loadings_eff[, axes, drop = FALSE]
          } else {
            res$var$coord[, axes, drop = FALSE]
          }
          self$results$plot_map$setState(list(
            var_coord            = var_for_plot,
            quanti_sup           = sub_axes(quanti_sup_full),
            quali_centroid       = sub_axes(quali_centroid_full),
            quali_centroid_group = quali_centroid_group,
            eig                  = eig_for_lab,
            axis_labels          = axis_labels,
            axes                 = axes,
            rot_label            = rot_label
          ))
        }

        # --- Output: 5 slot di coordinate (PC1..PC5), ruotate se rotation ---
        # jmvcore 2.6 NON supporta più colonne in un singolo Output (no
        # setKeys): serve un Output per ciascuna colonna iniettata, come
        # fanno anche i moduli ufficiali (jmv linreg → predicted + residuals
        # + cooks + mahal). Gli slot oltre ncp_used vengono nascosti via
        # setVisible(FALSE).
        coords <- ind_coord_eff
        nc_out <- ncol(coords)
        row_ids <- rownames(raw)

        fill_pc <- function(slot, j) {
          if (j > nc_out) {
            slot$setVisible(FALSE)
            return()
          }
          slot$setVisible(TRUE)
          v <- rep(NA_real_, nrow(raw))
          v[keep] <- coords[, j]
          slot$setValues(v)
          slot$setRowNums(row_ids)
        }
        fill_pc(self$results$out_PC1, 1)
        fill_pc(self$results$out_PC2, 2)
        fill_pc(self$results$out_PC3, 3)
        fill_pc(self$results$out_PC4, 4)
        fill_pc(self$results$out_PC5, 5)

        private$.ind_coords <- coords
      },

      .plot_scree = function(image, ...) {
        if (!isTRUE(self$options$plot_scree)) return()
        st <- image$state
        if (is.null(st)) return()
        eig <- as.data.frame(st$eig)
        eig$comp <- seq_len(nrow(eig))
        names(eig)[1:3] <- c("eig", "var_pct", "cum_pct")

        rot_lbl <- st$rot_label
        # La soglia di Kaiser (λ = 1) ha senso solo per la PCA sulla
        # matrice di correlazione: con la covarianza la scala degli
        # autovalori è arbitraria e la linea sarebbe fuorviante.
        std <- isTRUE(self$options$standardize)
        # Lo scree plot mostra SEMPRE gli autovalori della soluzione
        # originale (`eig_for_scree <- eig`), anche quando è attiva una
        # rotazione: serve a decidere quante componenti ritenere, scelta
        # che precede la rotazione. Titolo e didascalia devono dirlo,
        # non il contrario — fino alla 2.0.8 erano rimasti quelli di
        # quando il grafico veniva davvero ridisegnato sui valori ruotati.
        title_txt <- .tr(it = "Scree plot", en = "Scree plot")
        cap <- sprintf(
          .tr(it = "Linea verde: %d componenti ritenute.%s%s",
              en = "Green line: %d retained components.%s%s"),
          st$ncp,
          if (std)
            .tr(it = " Linea grigia: soglia Kaiser λ=1.",
                en = " Grey line: Kaiser threshold λ=1.")
          else "",
          if (!is.null(rot_lbl))
            .tr(it = " Autovalori della soluzione non ruotata: la rotazione ridistribuisce la varianza fra le componenti già ritenute (vedi tabella SS loadings).",
                en = " Eigenvalues of the unrotated solution: the rotation redistributes variance among the already-retained components (see the SS loadings table).")
          else ""
        )

        p <- ggplot2::ggplot(eig, ggplot2::aes(x = comp, y = eig)) +
          ggplot2::geom_col(fill = "#1F77B4", alpha = 0.6) +
          ggplot2::geom_line(color = "#D62728", linewidth = 0.8) +
          ggplot2::geom_point(color = "#D62728", size = 2) +
          ggplot2::geom_vline(xintercept = st$ncp + 0.5, linetype = "dotted", color = "#2CA02C") +
          ggplot2::scale_x_continuous(breaks = eig$comp) +
          ggplot2::labs(title = title_txt,
                        x = .tr(it = "Componente", en = "Component"),
                        y = .tr(it = "Autovalore", en = "Eigenvalue"),
                        caption = cap) +
          ggplot2::theme_bw()
        if (std)
          p <- p + ggplot2::geom_hline(yintercept = 1, linetype = "dashed",
                                       color = "darkgray")
        print(p)
        TRUE
      },

      .plot_circle = function(image, ...) {
        if (!isTRUE(self$options$plot_circle)) return()
        st <- image$state
        if (is.null(st)) return()
        coord <- as.data.frame(st$coord)
        names(coord)[1:2] <- c("X", "Y")
        coord$var <- rownames(coord)
        eig <- if (!is.null(st$eig_for_lab)) st$eig_for_lab else st$eig
        ax  <- st$axes
        lab_x <- if (!is.null(st$axis_labels)) st$axis_labels[1] else sprintf("PC%d (%.1f%%)", ax[1], eig[ax[1], 2])
        lab_y <- if (!is.null(st$axis_labels)) st$axis_labels[2] else sprintf("PC%d (%.1f%%)", ax[2], eig[ax[2], 2])
        rot_lbl <- st$rot_label
        title_txt <- if (!is.null(rot_lbl))
          sprintf(.tr(it = "Cerchio delle correlazioni — ruotato (%s)",
                      en = "Correlation circle — rotated (%s)"), rot_lbl)
        else
          .tr(it = "Cerchio delle correlazioni", en = "Correlation circle")

        theta <- seq(0, 2 * pi, length.out = 100)
        circle <- data.frame(x = cos(theta), y = sin(theta))

        p <- ggplot2::ggplot() +
          ggplot2::geom_path(data = circle, ggplot2::aes(x = x, y = y), color = "black") +
          ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
          ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "gray60") +
          ggplot2::geom_segment(
            data = coord,
            ggplot2::aes(x = 0, y = 0, xend = X, yend = Y),
            arrow = grid::arrow(length = grid::unit(0.15, "cm")),
            color = "#1F77B4"
          ) +
          ggplot2::geom_text(
            data = coord,
            ggplot2::aes(x = X * 1.08, y = Y * 1.08, label = var),
            size = 3.5
          ) +
          ggplot2::coord_fixed(xlim = c(-1.15, 1.15), ylim = c(-1.15, 1.15)) +
          ggplot2::labs(title = title_txt, x = lab_x, y = lab_y) +
          ggplot2::theme_bw()

        # variabili supplementari quantitative
        if (!is.null(st$quanti_sup)) {
          sup <- as.data.frame(st$quanti_sup)
          names(sup)[1:2] <- c("X", "Y")
          sup$var <- rownames(sup)
          p <- p +
            ggplot2::geom_segment(
              data = sup,
              ggplot2::aes(x = 0, y = 0, xend = X, yend = Y),
              arrow = grid::arrow(length = grid::unit(0.15, "cm")),
              color = "#FF7F0E", linetype = "dashed"
            ) +
            ggplot2::geom_text(
              data = sup,
              ggplot2::aes(x = X * 1.08, y = Y * 1.08, label = var),
              size = 3.5, color = "#FF7F0E"
            )
        }
        print(p)
        TRUE
      },

      .plot_biplot = function(image, ...) {
        if (!isTRUE(self$options$plot_biplot)) return()
        st <- image$state
        if (is.null(st)) return()
        ind <- as.data.frame(st$ind_coord)
        names(ind)[1:2] <- c("X", "Y")
        if (!is.null(st$group)) ind$group <- st$group

        var_c <- as.data.frame(st$var_coord)
        names(var_c)[1:2] <- c("X", "Y")
        var_c$var <- rownames(var_c)
        # scaliamo le frecce delle variabili per visualizzazione
        scale_f <- 0.9 * max(abs(c(ind$X, ind$Y))) /
                   max(abs(c(var_c$X, var_c$Y)))
        var_c$Xs <- var_c$X * scale_f
        var_c$Ys <- var_c$Y * scale_f

        eig <- st$eig
        ax  <- st$axes
        lab_x <- if (!is.null(st$axis_labels)) st$axis_labels[1] else sprintf("PC%d (%.1f%%)", ax[1], eig[ax[1], 2])
        lab_y <- if (!is.null(st$axis_labels)) st$axis_labels[2] else sprintf("PC%d (%.1f%%)", ax[2], eig[ax[2], 2])
        rot_lbl <- st$rot_label
        title_txt <- if (!is.null(rot_lbl))
          sprintf(.tr(it = "Biplot delle osservazioni — ruotato (%s)",
                      en = "Observation biplot — rotated (%s)"), rot_lbl)
        else
          .tr(it = "Biplot delle osservazioni", en = "Observation biplot")

        p <- ggplot2::ggplot()
        if (!is.null(ind$group)) {
          p <- p + ggplot2::geom_point(
            data = ind,
            ggplot2::aes(x = X, y = Y, color = group),
            alpha = 0.7, size = 2
          )
        } else {
          p <- p + ggplot2::geom_point(
            data = ind,
            ggplot2::aes(x = X, y = Y),
            color = "#1F77B4", alpha = 0.6, size = 2
          )
        }
        p <- p +
          ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
          ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "gray60") +
          ggplot2::geom_segment(
            data = var_c,
            ggplot2::aes(x = 0, y = 0, xend = Xs, yend = Ys),
            arrow = grid::arrow(length = grid::unit(0.15, "cm")),
            color = "#D62728", alpha = 0.8
          ) +
          ggplot2::geom_text(
            data = var_c,
            ggplot2::aes(x = Xs * 1.08, y = Ys * 1.08, label = var),
            color = "#D62728", size = 3.5
          ) +
          ggplot2::labs(title = title_txt, x = lab_x, y = lab_y,
                        color = if (!is.null(st$group_name)) st$group_name
                                else .tr(it = "Gruppo", en = "Group")) +
          ggplot2::theme_bw()
        print(p)
        TRUE
      },

      .plot_cos2 = function(image, ...) {
        if (!isTRUE(self$options$plot_cos2)) return()
        st <- image$state
        if (is.null(st)) return()
        cos2 <- st$cos2
        df <- data.frame(
          variabile = rep(rownames(cos2), ncol(cos2)),
          componente = rep(colnames(cos2), each = nrow(cos2)),
          cos2 = as.vector(cos2)
        )
        df$variabile <- factor(df$variabile, levels = rev(rownames(cos2)))
        df$componente <- factor(df$componente, levels = colnames(cos2))

        rot_lbl <- st$rot_label
        title_txt <- if (!is.null(rot_lbl))
          sprintf(.tr(it = "Qualità di rappresentazione (cos²) — ruotata (%s)",
                      en = "Quality of representation (cos²) — rotated (%s)"),
                  rot_lbl)
        else
          .tr(it = "Qualità di rappresentazione (cos²)",
              en = "Quality of representation (cos²)")

        p <- ggplot2::ggplot(df, ggplot2::aes(x = componente, y = variabile, fill = cos2)) +
          ggplot2::geom_tile(color = "white", linewidth = 0.5) +
          ggplot2::geom_text(
            ggplot2::aes(label = sprintf("%.2f", cos2)),
            color = ifelse(df$cos2 > 0.5, "white", "black"),
            size = 3.5
          ) +
          ggplot2::scale_fill_gradient(
            low = "#FFFFFF", high = "#1F77B4",
            limits = c(0, 1), name = "cos²"
          ) +
          ggplot2::labs(title = title_txt, x = NULL, y = NULL,
                        caption = .tr(
                          it = "Valori vicini a 1: variabile ben rappresentata dalla componente.",
                          en = "Values close to 1: variable well represented by the component.")) +
          ggplot2::theme_minimal() +
          ggplot2::theme(
            panel.grid = ggplot2::element_blank(),
            axis.ticks = ggplot2::element_blank()
          )
        print(p)
        TRUE
      },

      .plot_map = function(image, ...) {
        if (!isTRUE(self$options$plot_map)) return()
        st <- image$state
        if (is.null(st)) return()

        show_active     <- isTRUE(self$options$map_show_active)
        show_supp_quant <- isTRUE(self$options$map_show_supp_quant)

        var_c <- as.data.frame(st$var_coord)
        names(var_c)[1:2] <- c("X", "Y")
        var_c$var <- rownames(var_c)

        eig <- st$eig
        ax  <- st$axes
        lab_x <- if (!is.null(st$axis_labels)) st$axis_labels[1] else sprintf("PC%d (%.1f%%)", ax[1], eig[ax[1], 2])
        lab_y <- if (!is.null(st$axis_labels)) st$axis_labels[2] else sprintf("PC%d (%.1f%%)", ax[2], eig[ax[2], 2])
        rot_lbl <- st$rot_label
        title_txt <- if (!is.null(rot_lbl))
          sprintf(.tr(it = "Mappa di posizionamento — ruotata (%s)",
                      en = "Positioning map — rotated (%s)"), rot_lbl)
        else
          .tr(it = "Mappa di posizionamento", en = "Positioning map")

        # Calcolo dimensione plot solo sugli elementi effettivamente disegnati
        all_coords <- list()
        if (show_active) all_coords[[length(all_coords) + 1L]] <- var_c[, c("X", "Y")]
        if (show_supp_quant && !is.null(st$quanti_sup))
          all_coords[[length(all_coords) + 1L]] <- as.data.frame(st$quanti_sup)[, 1:2]
        if (!is.null(st$quali_centroid))
          all_coords[[length(all_coords) + 1L]] <- as.data.frame(st$quali_centroid)[, 1:2]
        if (length(all_coords) == 0) {
          # nessun elemento da disegnare: fallback per evitare errori
          all_coords[[1L]] <- data.frame(X = c(-1, 1), Y = c(-1, 1))
        }
        mx <- max(abs(unlist(all_coords)), 0.1) * 1.30

        has_repel <- requireNamespace("ggrepel", quietly = TRUE)
        text_geom <- function(data, mapping, color, size = 3.8, fontface = "plain") {
          if (has_repel) {
            ggrepel::geom_text_repel(
              data = data, mapping = mapping,
              color = color, size = size, fontface = fontface,
              max.overlaps = 60, segment.alpha = 0.3, min.segment.length = 0.2,
              box.padding = 0.30, point.padding = 0.20, show.legend = FALSE
            )
          } else {
            ggplot2::geom_text(
              data = data, mapping = mapping,
              color = color, size = size, fontface = fontface,
              vjust = -0.4, show.legend = FALSE
            )
          }
        }

        p <- ggplot2::ggplot() +
          ggplot2::geom_hline(yintercept = 0, linetype = "dashed", color = "gray60") +
          ggplot2::geom_vline(xintercept = 0, linetype = "dashed", color = "gray60")

        # variabili attive (vettori) — solo se richiesto
        if (show_active) {
          p <- p +
            ggplot2::geom_segment(
              data = var_c,
              ggplot2::aes(x = 0, y = 0, xend = X, yend = Y),
              arrow = grid::arrow(length = grid::unit(0.15, "cm")),
              color = "#1F77B4", linewidth = 0.7, alpha = 0.8
            ) +
            text_geom(
              data = var_c,
              mapping = ggplot2::aes(x = X, y = Y, label = var),
              color = "#1F77B4", size = 3.8, fontface = "bold"
            )
        }

        # variabili supplementari quantitative — solo se richiesto
        if (show_supp_quant && !is.null(st$quanti_sup)) {
          qs <- as.data.frame(st$quanti_sup)
          names(qs)[1:2] <- c("X", "Y")
          qs$var <- rownames(qs)
          p <- p +
            ggplot2::geom_segment(
              data = qs,
              ggplot2::aes(x = 0, y = 0, xend = X, yend = Y),
              arrow = grid::arrow(length = grid::unit(0.15, "cm")),
              color = "#FF7F0E", linetype = "dashed", linewidth = 0.7, alpha = 0.85
            ) +
            text_geom(
              data = qs,
              mapping = ggplot2::aes(x = X, y = Y, label = var),
              color = "#FF7F0E", size = 3.8
            )
        }

        # baricentri qualitative supplementari, colorati per variabile
        if (!is.null(st$quali_centroid)) {
          qc <- as.data.frame(st$quali_centroid)
          names(qc)[1:2] <- c("X", "Y")
          qc$lbl <- rownames(qc)
          grp <- st$quali_centroid_group
          if (is.null(grp)) {
            qc$group <- .tr(it = "Modalità", en = "Category")
          } else {
            qc$group <- as.character(grp[qc$lbl])
            qc$group[is.na(qc$group) | !nzchar(qc$group)] <- .tr(it = "Modalità", en = "Category")
          }
          # Palette qualitativa stabile (oltre 8 gruppi cicla)
          pal <- c("#2CA02C", "#9467BD", "#17BECF", "#E377C2", "#8C564B",
                   "#BCBD22", "#7F7F7F", "#1A9988")
          uniq_groups <- unique(qc$group)
          color_map <- setNames(pal[((seq_along(uniq_groups) - 1L) %% length(pal)) + 1L],
                                uniq_groups)

          p <- p +
            ggplot2::geom_point(
              data = qc,
              ggplot2::aes(x = X, y = Y, color = group),
              shape = 17, size = 4.5
            ) +
            ggplot2::scale_color_manual(values = color_map, name = .tr(it = "Var. qualitativa", en = "Qualitative var."))

          # Etichetta usando il colore del gruppo
          if (has_repel) {
            p <- p + ggrepel::geom_text_repel(
              data = qc,
              ggplot2::aes(x = X, y = Y, label = lbl, color = group),
              size = 4.2, fontface = "bold",
              max.overlaps = 50, segment.alpha = 0.3, min.segment.length = 0.2,
              box.padding = 0.30, point.padding = 0.20, show.legend = FALSE
            )
          } else {
            p <- p + ggplot2::geom_text(
              data = qc,
              ggplot2::aes(x = X, y = Y, label = lbl, color = group),
              size = 4.2, fontface = "bold", vjust = -1, show.legend = FALSE
            )
          }
        }

        cap_parts <- c(.tr(
          it = "Triangoli colorati: baricentri delle modalità (un colore per variabile qualitativa).",
          en = "Coloured triangles: category barycentres (one colour per qualitative variable)."))
        if (show_active)
          cap_parts <- c(.tr(it = "Frecce blu: variabili attive.",
                             en = "Blue arrows: active variables."), cap_parts)
        if (show_supp_quant && !is.null(st$quanti_sup))
          cap_parts <- c(cap_parts,
                         .tr(it = "Frecce arancio: quantitative supplementari.",
                             en = "Orange arrows: supplementary quantitative variables."))
        cap <- paste(cap_parts, collapse = " ")

        # Niente coord_fixed: il grafico riempie l'intero canvas richiesto
        # dall'utente (i rapporti reali fra le componenti restano leggibili
        # dalle percentuali di varianza riportate sugli assi).
        p <- p +
          ggplot2::coord_cartesian(xlim = c(-mx, mx), ylim = c(-mx, mx)) +
          ggplot2::labs(title = title_txt, x = lab_x, y = lab_y, caption = cap) +
          ggplot2::theme_bw() +
          ggplot2::theme(legend.position = "bottom")
        print(p)
        TRUE
      }
    )
  )
}
