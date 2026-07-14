# --- INSTALLATION ET CHARGEMENT DES PACKAGES ---
packages_requis <- c(
  "shiny", "pROC",
  "shinythemes", "glmnet", "DT", 
  "ggplot2", "stats",
  "arm", "rmarkdown", "dplyr",
  "gridExtra", "PRROC",
  "readxl", "tools", "scales",
  "umap", "pheatmap",
  "cluster", 
  "dbscan", "isotree",
  "tidyr"
)

for (pkg in packages_requis) {
  if (!require(pkg, character.only = TRUE)) install.packages(pkg, dependencies = TRUE)
  library(pkg, character.only = TRUE)
}

# --- INTERFACE UTILISATEUR (UI) ---
ui <- navbarPage(
  title = "PERCYMAT v2.4",
  theme = shinytheme("flatly"),
  
  header = tags$head(
    tags$style(HTML("
      body { background-color: #f4f6f9; font-family: '-apple-system', BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; }
      .navbar { box-shadow: 0 4px 12px rgba(0,0,0,0.05); border: none; }
      .modern-card { background: white; border-radius: 14px; padding: 25px; box-shadow: 0 4px 18px rgba(26, 35, 126, 0.04); border: 1px solid #eef2f5; margin-bottom: 22px; }
      .sidebar-panel, .well { background: white !important; border: 1px solid #eef2f5 !important; border-radius: 14px !important; box-shadow: 0 4px 18px rgba(0,0,0,0.02) !important; }
      .big-metric { font-size: 2.2rem; font-weight: 700; color: #1e293b; margin: 4px 0; letter-spacing: -0.5px; line-height: 1.1; }
     .sub-metric { color: #64748b; font-size: 0.85rem; text-transform: uppercase; letter-spacing: 0.5px; font-weight: 600; }
      .ideal-val { color: #94a3b8; font-size: 0.75em; font-style: italic; margin-left: 3px; text-transform: none; }
      
      .ext-panel { border-left: 5px solid #3b82f6 !important; background-color: #ffffff !important; }
      .train-panel { border-left: 5px solid #10b981 !important; background-color: #ffffff !important; }
      .nature-panel { border-left: 5px solid #8b5cf6 !important; background-color: #faf5ff !important; }
      
      .modal-content { border-radius: 20px !important; border: none !important; padding: 35px 25px !important; text-align: center !important; box-shadow: 0 25px 60px rgba(0,0,0,0.15) !important; }
      .modal-header, .modal-footer { border: none !important; display: none !important; }
      .modal-success-icon { color: #10b981; font-size: 5.5rem; margin-bottom: 15px; display: inline-block; animation: popScale 0.45s cubic-bezier(0.175, 0.885, 0.32, 1.275); }
      @keyframes popScale { from { transform: scale(0); opacity: 0; } to { transform: scale(1); opacity: 1; } }
      .modal-premium-title { font-size: 1.6rem; font-weight: 700; color: #1e293b; margin-bottom: 8px; }
      .modal-premium-body { color: #64748b; font-size: 1.05rem; }
      
      .atypie-box { background-color: #fff1f2; border-left: 5px solid #e11d48; padding: 15px; border-radius: 8px; margin-top: 15px; }
      .reclass-table th { text-align: center; vertical-align: middle !important; padding: 12px; border: 1px solid #e2e8f0; }
      .reclass-table td { text-align: center; vertical-align: middle !important; padding: 12px; border: 1px solid #e2e8f0; }
      #plot_matutes_jitter { cursor: crosshair; }
      #plot_atypical { cursor: crosshair; }
      
      .flow-box { padding: 12px 20px; border-radius: 8px; font-weight: bold; color: white; display: inline-block; box-shadow: 0 4px 6px rgba(0,0,0,0.1); margin: 5px 0; font-size: 1.05em;}
      .flow-arrow { font-size: 24px; color: #94a3b8; line-height: 1; margin: 4px 0; }
      .flow-inner { background: #f8fafc; border: 2px dashed #cbd5e1; padding: 15px; border-radius: 8px; color: #334155; margin: 10px auto; width: 85%; font-size: 0.95em;}
    "))
  ),
  
  tabPanel("1. MODELISATION",
    sidebarLayout(
      sidebarPanel(
        h4("Cohorte d'Apprentissage", style="font-weight: 700; color: #0f172a;"),
        fileInput("file_csv", "Importer CSV / Excel", accept = c(".csv", "text/csv", ".xlsx", ".xls")),
        
        h4("Cohorte de Validation Externe", style="font-weight: 700; color: #0f172a; margin-top:25px;"),
        fileInput("file_ext", "Importer CSV / Excel", accept = c(".csv", "text/csv", ".xlsx", ".xls")),
        
        hr(),
        checkboxInput("use_weights", "Marqueurs", TRUE),
        checkboxInput("calc_ratios_simple", "Variables simples (A/B) + Marqueurs", FALSE),
        checkboxInput("calc_ratios_all", "Toutes combinaisons (A/B, Log, etc.) + Marqueurs", FALSE),
        checkboxInput("use_epv_filter", "Filtre Statistique (EPV)", FALSE),
        checkboxInput("auto_ml", "⚡Analyse non supervisée", FALSE),
        numericInput("cv_repeats", "Nombre de répétitions Nested-CV", value = 10, min = 1, max = 50),
       
        hr(),
        actionButton("update_model", "LANCER LA MODÉLISATION",
                     class = "btn-success btn-lg btn-block", 
                     style = "font-weight: 700; border-radius: 10px;",
                     icon = icon("play-circle")),
        hr(),
        helpText("V2.4: Elastic-Net, HDBSCAN, Isolation Forest & Local Log-Odds Explainer")
      ),
      mainPanel(
        tabsetPanel(
          tabPanel("Performances", 
            br(),
            uiOutput("patient_count_ui"),
            
            fluidRow(
              column(6, div(class="modern-card", 
                h5("Courbe ROC", style="font-weight:700;"),
                p("Evaluation des FP et FN.", style="font-size:0.85em; color:#64748b;"),
                plotOutput("plot_roc"))),
              column(6, div(class="modern-card", 
                h5("Courbe de Calibration", style="font-weight:700;"),
                p("Evaluation de la concordance avec le diagnostic.", style="font-size:0.85em; color:#64748b;"),
                plotOutput("plot_calib")))
            ),
            fluidRow(
              column(6, div(class="modern-card",
                h5("PR-AUC", style="font-weight:700;"),
                p("Evaluation des FP et VP.", style="font-size:0.85em; color:#64748b;"),
                plotOutput("plot_pr"))),
              column(6, div(class="modern-card", 
                h5("Decision Curve Analysis", style="font-weight:700;"),
                p("Evaluation de l’utilité clinique du modèle.", style="font-size:0.85em; color:#64748b;"),
                plotOutput("plot_dca")))
            ),
            br(),
            h4("Performances : Cohorte d'Apprentissage (Repeated Nested-CV)", style="font-weight:700; color:#0f172a; margin-top: 20px; margin-left: 5px;"),
            uiOutput("metrics_ui"),
            uiOutput("nature_metrics_ui"),
            uiOutput("ext_metrics_title_ui"),
            uiOutput("ext_metrics_ui"),
            uiOutput("agreement_ui")
          ),
          tabPanel("Odds ratio & Stabilité", 
            br(),
            uiOutput("top_markers_ui"),
            hr(),
            div(class="modern-card", DTOutput("coef_table"))
          ),
          tabPanel("Clusters & Atypies",
            br(),
            uiOutput("matutes_reclass_ui"),
            
            fluidRow(
              column(12, div(class="modern-card", style="border-top: 5px solid #4c1d95;",
                h5("UMAP & HDBSCAN Clustering", style="font-weight:700; color:#a855f7; margin-bottom:10px;"),
                p("Les patients dits 'atypiques' (Violet) sont détectés par Isolation Forest. Cliquez sur un point pour voir les caractéristiques.", style="font-size:0.85em; color:#64748b;"),
                plotOutput("plot_atypical", click = "plot_atypical_click"),
                uiOutput("cluster_click_info"),
                br(),
                hr(style="border-top: 1px dashed #cbd5e1; margin-top: 15px; margin-bottom: 15px;"),
                h5("Patients Atypiques (Récapitulatif)", style="font-weight:700; color:#e11d48; margin-top:10px;"),
                p("Sélectionnés par Isolation Forest ou par différence probabilité calculée vs diagnostique > 50%.", style="font-size:0.85em; color:#64748b;"),
                DTOutput("table_recap_atypiques"),
                br(),
                h5("Détails de tous les Patients", style="font-weight:700; color:#a855f7; margin-top:20px;"),
                p("Cliquez sur une ligne pour localiser le patient sur les graphiques ci-dessus.", style="font-size:0.85em; color:#64748b; font-style:italic;"),
                DTOutput("table_atypical")
              ))
            ),
            uiOutput("heatmap_matutes_ui")
          )
        )
      )
    )
  ),
  
  tabPanel("2. DIAGNOSTIC",
    sidebarLayout(
      sidebarPanel(
       h4("Saisie des Marqueurs (RFI)", style="font-weight: 700; color: #0f172a;"),
        hr(),
        uiOutput("dynamic_inputs"),
        hr(),
        actionButton("predict", " CALCULER PROBABILITÉ LLC", 
                     class = "btn-success btn-lg btn-block", 
                     style = "font-weight: 700; border-radius: 10px;",
                     icon = icon("stethoscope")),
        br(),
        uiOutput("download_btn_ui")
      ),
      mainPanel(
        uiOutput("result_box"),
        br(),
        uiOutput("patient_explain_ui")
      )
    )
  ),
  
  # --- ONGLET 3 : METHODOLOGY (MATHJAX INTEGRATION) ---
  tabPanel("3. METHODOLOGY",
    withMathJax(
      fluidPage(
        div(class="modern-card", style="border-top: 5px solid #1e293b;",
          h3(icon("shield-alt"), " Algorithmic Architecture (TRIPOD-AI Compliant)", style="font-weight:700; color:#0f172a; margin-bottom: 20px;"),
          p("This computational pipeline is specifically engineered to mitigate optimism bias (overfitting) and prevent data leakage in small clinical cohorts. The architecture strictly segregates feature engineering, selection, and optimization within an impermeable Repeated Nested Cross-Validation framework.", style="font-size: 1.1em; color:#475569;"),
          
          div(style="text-align:center; padding: 25px; background: #f8fafc; border-radius: 12px; margin: 30px 0; border: 1px solid #e2e8f0;",
             div(class="flow-box", style="background:#3b82f6;", "1. Data Input"),
             div(class="flow-arrow", "↓"),
             div(class="flow-box", style="background:#8b5cf6;", "2. Repeated Nested Cross-Validation (Outer Folds)"),
             div(class="flow-arrow", "↓"),
             div(class="flow-inner", HTML("<b>Inner Loop (Training Folds Only):</b><br>Ratio Combinatorics → EPV Univariate Filter → Z-Score Scaling → Elastic-Net Optimization")),
             div(class="flow-arrow", "↓"),
             div(class="flow-box", style="background:#f59e0b;", "3. Out-Of-Bag Prediction & Bayesian Platt Scaling"),
             div(class="flow-arrow", "↓"),
             div(class="flow-box", style="background:#10b981;", "4. Final Frozen Models on 100% Training Cohort"),
             div(class="flow-arrow", "↓"),
             div(class="flow-box", style="background:#ef4444;", "5. SHAP & Conformal Bounds, HDBSCAN & Isolation Forest")
          ),
          
          hr(),
          h4("1. Repeated Nested-CV & Elastic-Net Model", style="font-weight:600; color:#2563eb;"),
          p("The algorithm utilizes a 5-fold Nested Cross-Validation repeated multiple times. An extensive feature-engineering procedure generates biologically relevant candidate variables. The selected variables subsequently entered into an Elastic-Net model, which combines L1 and L2 regularization to identify the most predictive markers:"),
          p("$$ Penalty = \\lambda \\cdot \\left[ \\alpha ||\\beta||_1 + \\frac{1 - \\alpha}{2} ||\\beta||_2^2 \\right] $$"),
          br(),
 
          h4("2. Dimensionality Protection (EPV Filter)", style="font-weight:600; color:#2563eb;"),
         p("To minimize overfitting and prevent information leakage, a strict Events-Per-Variable (EPV) Filter is applied:"),
          p("$$ EPV = \\frac{N_{minority}}{N_{variables}} \\ge 5 $$"),
          p("To prevent data leakage, the EPV Filter is performed dynamically inside the training folds of the cross-validation loop. A strict minimum of 2 variables is enforced for multivariate suitability."),
          br(),
 
          h4("3. Z-score standardization", style="font-weight:600; color:#2563eb;"),
          p("The analytical pipeline begins by transforming each patient's raw cytometric measurements into standardized Z-score:"),
          p("$$ Z = \\frac{X - \\mu}{\\sigma} $$"),
          br(),
          
          h4("4. Out-Of-Bag Bayesian Calibration & Performance", style="font-weight:600; color:#2563eb;"),
          p("Every patient is assigned an averaged Out-Of-Bag (OOB) probability, subsequently smoothed via Bayesian logistic regression (Platt Scaling):"),
          p("$$ P(Y=1 | X) = \\frac{1}{1 + e^{-(A \\cdot \\text{logit}(P_{OOB}) + B)}} $$"),
          br(),
          
          h4("5. Independent External Validation", style="font-weight:600; color:#2563eb;"),
          p("External validation applies these exact frozen parameters as a rigid mathematical projector, unequivocally demonstrating trans-institutional comparability."),
          
          hr(),
          h3(icon("microchip"), " Version 2.4 Upgrades: Advanced XAI & Topography", style="font-weight:700; color:#0f172a; margin-top:30px; margin-bottom: 20px;"),
 
          h4("6. HDBSCAN Density-Based Clustering", style="font-weight:600; color:#8b5cf6;"),
          p("Hierarchical Density-Based Spatial Clustering of Applications with Noise (HDBSCAN) calculates clusters based on mutual reachability distance:"),
          p("$$ d_{mreach}(a,b) = \\max\\{core_k(a), core_k(b), d(a,b)\\} $$"),
          br(),
 
          h4("7. Isolation Forest", style="font-weight:600; color:#8b5cf6;"),
          p("Atypical patients are identified on UMAP using an Isolation Forest. It calculates an anomaly score based on the path length h(x) required to isolate a sample in random decision trees. An absolute anomaly threshold is defined using the 95th percentile of the training cohort and applied unconditionally to external validation:"),
          p("$$ s(x, n) = 2^{-\\frac{E(h(x))}{c(n)}} $$"),
          br(),
          
          h4("8. Local Log-Odds Explanations (XAI)", style="font-weight:600; color:#8b5cf6;"),
          p("Deconstructs the patient's predictive score by determining the exact linear contribution of each specific marker based on the final Elastic-Net coefficients:"),
          p("$$ Contribution_i = \\beta_i \\times Z_{x_i} $$"),
          br(),
 
          h4("9. Conformal Prediction", style="font-weight:600; color:#8b5cf6;"),
          p("Conformal prediction acts as a built-in safety mechanism for the AI. Instead of blindly trusting a single predictive score, it evaluates the model's certainty against a strict safety threshold that was calculated using the training cohort:"),
          p("$$ C(x_{n+1}) = \\{y \\in \\mathcal{Y} : \\hat{p}(y|x_{n+1}) \\ge 1 - \\hat{q}_{1-\\alpha}\\} $$")
        )
      )
    )
  )
)
 
# --- SERVEUR ---
server <- function(input, output, session) {
  
  m_res <- reactiveValues()
  diag_res <- reactiveValues()
  selected_patient <- reactiveVal(NULL) 
  
  show_premium_popup <- function(title, text) {
    showModal(modalDialog(
      title = NULL, footer = NULL, easyClose = TRUE,
      div(div(class = "modal-success-icon", icon("check-circle")),
          div(class = "modal-premium-title", title),
          div(class = "modal-premium-body", text),
     tags$script(HTML("setTimeout(function() { $('.modal').modal('hide'); }, 2200);")))
    ))
  }
  
  read_data_file <- function(datapath, filename) {
    ext <- tools::file_ext(filename)
    if(tolower(ext) %in% c("xls", "xlsx")) {
      df <- as.data.frame(readxl::read_excel(datapath))
    } else {
      df <- read.csv(datapath)
      if(ncol(df) == 1) df <- read.csv2(datapath) 
    }
    return(df)
  }
  
  observeEvent(input$file_csv, {
    req(input$file_csv)
    df_temp <- read_data_file(input$file_csv$datapath, input$file_csv$name)
    if(!"ID_Interne" %in% names(df_temp)) {
      df_temp$ID_Interne <- paste0("Patient_", 1:nrow(df_temp))
    }
    m_res$df_train <- df_temp
    show_premium_popup("Cohorte Importée", "Données d'apprentissage chargées avec succès.")
  })
  
  observeEvent(input$file_ext, {
   req(input$file_ext)
   show_premium_popup("Cohorte Importée ", "Cohorte de validation externe chargée avec succès.")
  })
  
  observeEvent(input$update_model, {
    req(m_res$df_train)
    set.seed(42)
    selected_patient(NULL) 
    
   withProgress(message = 'Modélisation TRIPOD-AI en cours...', value = 0, {
      
      incProgress(0.1, detail = "Nettoyage des données...")
      df <- m_res$df_train 
      target_col <- if("LLC_1" %in% names(df)) "LLC_1" else "LLC"
      
      df_numeric <- df[, sapply(df, is.numeric)]
      y <- as.numeric(df[[target_col]])
      
      matutes_cols <- grep("(?i)matutes", names(df_numeric), value = TRUE)
      x_raw_base <- as.matrix(df_numeric[, setdiff(names(df_numeric), c(target_col, matutes_cols))])
      
      m_res$marker_names <- colnames(x_raw_base)
      x_raw_base_expanded <- x_raw_base
      
      # --- DEBUT LOGIQUE AUTO-ML (GRID SEARCH VÉRITABLE) ---
      do_all_ratios <- input$calc_ratios_all
      do_simple_ratios <- input$calc_ratios_simple && !do_all_ratios
      do_epv <- input$use_epv_filter
      m_res$automl_msg <- NULL
      
      if(input$auto_ml) {
        incProgress(0.15, detail = "AutoML: Grid-Search d'optimisation en cours...")
        
        # Création d'une grille de paramètres explorant les configurations viables
        grid <- expand.grid(simple=c(FALSE,TRUE), all=c(FALSE,TRUE), epv=c(FALSE,TRUE))
        grid <- grid[!(grid$all == TRUE & grid$simple == TRUE), ] # Évite la redondance
        
        best_auc <- -1
        best_row <- 1
        
        # Validation Croisée rapide pour évaluer chaque configuration
        folds_fast <- sample(rep(1:5, length.out = length(y)))
        
        for(i in 1:nrow(grid)) {
          c_simp <- grid$simple[i]
          c_all <- grid$all[i]
          c_epv <- grid$epv[i]
          
          # Génération temporaire des features pour cette configuration
          x_temp <- x_raw_base_expanded
          if(c_simp || c_all) {
             pairs <- combn(m_res$marker_names, 2)
             nb_pairs <- ncol(pairs)
             num_trans <- if(c_all) 4 else 1
             ratio_matrix <- matrix(nrow = nrow(x_raw_base), ncol = nb_pairs * num_trans)
             idx <- 1
             for(j in 1:nb_pairs) {
                A <- x_raw_base[, pairs[1, j]]; B <- x_raw_base[, pairs[2, j]]
                ratio_matrix[, idx] <- (A + 1e-6) / (B + 1e-6); idx <- idx + 1
                if(c_all) {
                   ratio_matrix[, idx] <- A / (A + B + 1e-6); idx <- idx + 1
                   ratio_matrix[, idx] <- log((A + 1e-6) / (B + 1e-6)); idx <- idx + 1
                  ratio_matrix[, idx] <- (A - B) / (A + B + 1e-6); idx <- idx + 1
                }
             }
             x_temp <- cbind(x_raw_base_expanded, ratio_matrix)
          }
          
          # Simulation 5-fold rapide
          p_oof <- numeric(length(y))
          for(k in 1:5) {
             test_idx  <- which(folds_fast == k)
             train_idx <- which(folds_fast != k)
             x_tr <- x_temp[train_idx, , drop=FALSE]; y_tr <- y[train_idx]
             x_te <- x_temp[test_idx, , drop=FALSE]
             
             if(c_epv) {
                n_events <- min(sum(y_tr == 1), sum(y_tr == 0))
                max_vars <- max(2, floor(n_events / 5)) 
                abs_cor <- apply(x_tr, 2, function(col_vec) { if(sd(col_vec)==0) return(0); abs(cor(col_vec, y_tr)) })
                sel_cols <- order(abs_cor, decreasing = TRUE)[1:min(length(abs_cor), max_vars)]
             } else { sel_cols <- 1:ncol(x_tr) }
             
             x_tr <- x_tr[, sel_cols, drop=FALSE]; x_te <- x_te[, sel_cols, drop=FALSE]
             ctr <- colMeans(x_tr); sdt <- apply(x_tr, 2, sd); sdt[sdt==0] <- 1
             x_tr_sc <- scale(x_tr, center=ctr, scale=sdt)
             x_te_sc <- scale(x_te, center=ctr, scale=sdt)
             
             wtr <- rep(1, length(y_tr))
             if(input$use_weights) { wtr[y_tr == 1] <- length(y_tr)/(2*sum(y_tr==1)); wtr[y_tr == 0] <- length(y_tr)/(2*sum(y_tr==0)) }
             
             fit_fast <- suppressWarnings(cv.glmnet(x_tr_sc, y_tr, family="binomial", alpha=0.5, weights=wtr, nfolds=3))
             p_oof[test_idx] <- as.numeric(predict(fit_fast, newx=x_te_sc, s="lambda.min", type="response"))
          }
          
          roc_temp <- suppressWarnings(pROC::roc(y, p_oof, quiet=TRUE))
          auc_temp <- as.numeric(pROC::auc(roc_temp))
          
          if(auc_temp > best_auc) {
            best_auc <- auc_temp
            best_row <- i
          }
        }
        
        # Fixation des paramètres gagnants
        do_simple_ratios <- grid$simple[best_row]
        do_all_ratios <- grid$all[best_row]
        do_epv <- grid$epv[best_row]
        m_res$automl_msg <- paste0("⚡ Grid-Search Terminé : Configuration retenue [Variables Simples: ", do_simple_ratios, " | Toutes combinaisons: ", do_all_ratios, " | Filtre EPV: ", do_epv, "] (AUC Inner-Fold: ", round(best_auc,3), ")")
      }
      # --- FIN LOGIQUE AUTO-ML ---
      
      do_any_ratio <- do_all_ratios || do_simple_ratios
      
      # Génération finale des features selon les règles décidées
      if(do_any_ratio && ncol(x_raw_base) >= 2) {
        incProgress(0.2, detail = "Génération des variables finales...")
        pairs <- combn(m_res$marker_names, 2)
        nb_pairs <- ncol(pairs)
        num_trans <- if(do_all_ratios) 4 else 1
        
        ratio_matrix <- matrix(nrow = nrow(x_raw_base), ncol = nb_pairs * num_trans)
        ratio_names <- character(nb_pairs * num_trans)
        eps <- 1e-6
        
        idx <- 1
        for(i in 1:nb_pairs) {
          A <- x_raw_base[, pairs[1, i]]
          B <- x_raw_base[, pairs[2, i]]
          
          ratio_matrix[, idx] <- (A + eps) / (B + eps)
          ratio_names[idx] <- paste0(pairs[1, i], "_sur_", pairs[2, i])
         idx <- idx + 1
          
         if(do_all_ratios) {
            ratio_matrix[, idx] <- A / (A + B + eps)
            ratio_names[idx] <- paste0(pairs[1, i], "_sursum_", pairs[2, i])
            idx <- idx + 1
            
            ratio_matrix[, idx] <- log((A + eps) / (B + eps))
            ratio_names[idx] <- paste0(pairs[1, i], "_logsur_", pairs[2, i])
            idx <- idx + 1
            
            ratio_matrix[, idx] <- (A - B) / (A + B + eps)
            ratio_names[idx] <- paste0(pairs[1, i], "_diffsum_", pairs[2, i])
            idx <- idx + 1
          }
        }
      colnames(ratio_matrix) <- ratio_names
        x_raw_all <- cbind(x_raw_base_expanded, ratio_matrix)
      } else {
        x_raw_all <- x_raw_base_expanded
      }
      
      n <- length(y); K <- 5
      n_repeats <- input$cv_repeats
      probs_cv_matrix <- matrix(NA, nrow = n, ncol = n_repeats)
      
      cv_selected_features <- list()
      feature_list_idx <- 1
      
      incProgress(0.4, detail = paste0("Repeated Nested CV principale (", n_repeats, " itérations)..."))
      
      for(r in 1:n_repeats) {
        folds <- sample(rep(1:K, length.out = n))
        for(k in 1:K){
          test_idx  <- which(folds == k)
          train_full_idx <- which(folds != k)
          
          calib_inner_idx <- sample(train_full_idx, size = floor(0.25 * length(train_full_idx)))
          net_inner_idx   <- setdiff(train_full_idx, calib_inner_idx)
          
          y_net <- y[net_inner_idx]
          y_cal <- y[calib_inner_idx]
          
          x_net_full <- x_raw_all[net_inner_idx, , drop=F]
          x_cal_full <- x_raw_all[calib_inner_idx, , drop=F]
          x_te_full  <- x_raw_all[test_idx, , drop=F]
          
          if(do_epv) {
            n_events_min_fold <- min(sum(y_net == 1), sum(y_net == 0))
            max_allowed_vars_fold <- max(2, floor(n_events_min_fold / 5)) 
            
            abs_cor <- apply(x_net_full, 2, function(col_vec) {
              if(sd(col_vec) == 0) return(0)
              abs(cor(col_vec, y_net, use="complete.obs"))
            })
            selected_cols <- order(abs_cor, decreasing = TRUE)[1:min(length(abs_cor), max_allowed_vars_fold)]
          } else {
            selected_cols <- 1:ncol(x_net_full)
          }
          
          x_net <- x_net_full[, selected_cols, drop=F]
        x_cal <- x_cal_full[, selected_cols, drop=F]
          x_te <- x_te_full[, selected_cols, drop=F]
          
         ctr <- colMeans(x_net); sdt <- apply(x_net, 2, sd); sdt[sdt==0] <- 1
          x_net_sc <- scale(x_net, center=ctr, scale=sdt)
          x_cal_sc <- scale(x_cal, center=ctr, scale=sdt)
          x_te_sc  <- scale(x_te, center=ctr, scale=sdt)
         
          wtr <- rep(1, length(y_net))
          if(input$use_weights) {
            wtr[y_net == 1] <- length(y_net) / (2 * sum(y_net == 1))
            wtr[y_net == 0] <- length(y_net) / (2 * sum(y_net == 0))
          }
          
          alpha_grid <- c(0, 0.1, 0.25, 0.5)
          best_cvm <- Inf; cv_fit <- NULL
          for (a in alpha_grid) {
            temp_cv <- suppressWarnings(cv.glmnet(x_net_sc, y_net, family="binomial", alpha=a, weights=wtr, nfolds=min(5, length(y_net))))
            if (min(temp_cv$cvm) < best_cvm) {
              best_cvm <- min(temp_cv$cvm); cv_fit <- temp_cv
            }
          }
          
          fold_coefs <- as.matrix(coef(cv_fit, s="lambda.min"))
          nonzero_vars <- rownames(fold_coefs)[fold_coefs[,1] != 0]
       cv_selected_features[[feature_list_idx]] <- setdiff(nonzero_vars, "(Intercept)")
          feature_list_idx <- feature_list_idx + 1
          
          p_cal <- as.numeric(predict(cv_fit, newx=x_cal_sc, s="lambda.min", type="response"))
          logit_p_cal <- log((p_cal+1e-2)/(1-p_cal+1e-2))
          cal_model_inner <- suppressWarnings(bayesglm(y_cal ~ logit_p_cal, family=binomial))
          
          p_te_raw <- as.numeric(predict(cv_fit, newx=x_te_sc, s="lambda.min", type="response"))
          logit_p_te <- log((p_te_raw+1e-2)/(1-p_te_raw+1e-2))
          probs_cv_matrix[test_idx, r] <- as.numeric(predict(cal_model_inner, newdata=data.frame(logit_p_cal=logit_p_te), type="response"))
        }
      }
      
      probs_cv <- rowMeans(probs_cv_matrix)
      
      incProgress(0.6, detail = "Modèle global & Calibration OOB...")
     y_net_final <- y
      
      if(do_epv) {
        n_events_min_global <- min(sum(y_net_final == 1), sum(y_net_final == 0))
       max_allowed_vars_global <- max(2, floor(n_events_min_global / 5)) 
        
        abs_cor_global <- apply(x_raw_all, 2, function(col_vec) {
          if(sd(col_vec) == 0) return(0)
          abs(cor(col_vec, y_net_final, use="complete.obs"))
        })
        selected_cols_full <- order(abs_cor_global, decreasing = TRUE)[1:min(length(abs_cor_global), max_allowed_vars_global)]
      } else {
        selected_cols_full <- 1:ncol(x_raw_all)
      }
      
      x_net_final <- x_raw_all[, selected_cols_full, drop=F]
      
      m_res$scale_center <- colMeans(x_net_final) 
      m_res$scale_std <- apply(x_net_final, 2, sd); m_res$scale_std[m_res$scale_std==0] <- 1
      x_net_final_sc <- scale(x_net_final, center=m_res$scale_center, scale=m_res$scale_std)
      
      w_full <- rep(1, length(y_net_final))
      if(input$use_weights) {
        w_full[y_net_final == 1] <- length(y_net_final) / (2 * sum(y_net_final == 1))
        w_full[y_net_final == 0] <- length(y_net_final) / (2 * sum(y_net_final == 0))
      }
      
      alpha_grid <- c(0, 0.1, 0.25, 0.5)
      best_cvm_final <- Inf; cv_final <- NULL; best_alpha_final <- 0.5
      for (a in alpha_grid) {
        temp_cv_final <- suppressWarnings(cv.glmnet(x_net_final_sc, y_net_final, family="binomial", alpha=a, weights=w_full, nfolds=min(5, length(y_net_final))))
        if (min(temp_cv_final$cvm) < best_cvm_final) {
          best_cvm_final <- min(temp_cv_final$cvm); cv_final <- temp_cv_final; best_alpha_final <- a
        }
      }
      
      m_res$best_alpha <- best_alpha_final
      m_res$fit <- glmnet(x_net_final_sc, y_net_final, family="binomial", alpha=best_alpha_final, lambda=cv_final$lambda.min, weights=w_full)
      
      logit_oof <- log((probs_cv+1e-2)/(1-probs_cv+1e-2))
      m_res$calib_model <- suppressWarnings(bayesglm(y ~ logit_oof, family=binomial))
      probs_calib_finales <- as.numeric(fitted(m_res$calib_model))
      m_res$roc_obj <- roc(y, probs_calib_finales, quiet=TRUE)
      
      nc_scores <- 1 - ifelse(y == 1, probs_calib_finales, 1 - probs_calib_finales)
     m_res$q_conformal <- quantile(nc_scores, 0.95, na.rm=TRUE)
      
      auc_ci <- as.numeric(ci.auc(m_res$roc_obj))
      
      tp <- sum(probs_calib_finales>=0.5 & y==1)
      fn <- sum(probs_calib_finales<0.5 & y==1)
      tn <- sum(probs_calib_finales<0.5 & y==0)
      fp <- sum(probs_calib_finales>=0.5 & y==0)
      
      sens_ci <- binom.test(tp, tp+fn)$conf.int
      spec_ci <- binom.test(tn, tn+fp)$conf.int
      
      m_res$metrics <- list(
        auc_val = auc_ci[2], auc_lower = auc_ci[1], auc_upper = auc_ci[3],
        sens = tp/(tp+fn), sens_lower = sens_ci[1], sens_upper = sens_ci[2],
        spec = tn/(tn+fp), spec_lower = spec_ci[1], spec_upper = spec_ci[2],
        brier = mean((probs_calib_finales - y)^2), 
       calib_intercept = coef(m_res$calib_model)[1], 
        calib_slope = coef(m_res$calib_model)[2],
        ICI = mean(abs(probs_calib_finales - predict(suppressWarnings(loess(y ~ probs_calib_finales, degree=2)), probs_calib_finales)), na.rm=T),
        Emax = max(abs(probs_calib_finales - predict(suppressWarnings(loess(y ~ probs_calib_finales, degree=2)), probs_calib_finales)), na.rm=T)
      )
      
      pr_obj <- pr.curve(scores.class0 = probs_calib_finales, weights.class0 = y, curve=TRUE)
      m_res$pr_auc <- pr_obj$auc.integral
      
      m_res$coefs <- as.matrix(coef(m_res$fit))
      m_res$vars <- rownames(m_res$coefs)[m_res$coefs[,1] != 0][-1] 
      raw_v <- m_res$vars
      raw_v <- gsub("_sursum_", "_sur_", raw_v); raw_v <- gsub("_logsur_", "_sur_", raw_v); raw_v <- gsub("_diffsum_", "_sur_", raw_v)
      m_res$required_raw <- unique(unlist(strsplit(raw_v, "_sur_")))
      
      all_selected_cv <- unlist(cv_selected_features)
      stability_counts <- table(all_selected_cv)
      
      df_coef <- data.frame(Marqueur = rownames(m_res$coefs), Poids = round(m_res$coefs[,1], 4), OR = round(exp(m_res$coefs[,1]), 2))
      df_coef$Stabilité <- sapply(df_coef$Marqueur, function(m) {
        if(m == "(Intercept)") return("100%")
        count <- stability_counts[m]
        if(is.na(count)) count <- 0
        paste0(round((as.numeric(count) / (n_repeats * 5)) * 100), "%")
      })
      
      m_res$df_coef_export <- subset(df_coef, Poids != 0)
      
      roc_list <- list("Apprentissage (OOB)" = m_res$roc_obj)
     df_pr_comb <- data.frame(Recall = pr_obj$curve[,1], Precision = pr_obj$curve[,2], Cohorte = "Apprentissage (OOB)")
      df_calib_comb <- data.frame(p = probs_calib_finales, y = y, Cohorte = "Apprentissage (OOB)")
      
      thresholds <- seq(0, 0.99, by=0.01)
      prev_int <- mean(y == 1)
      nb_model_int <- sapply(thresholds, function(pt) {
        sens <- sum(probs_calib_finales >= pt & y == 1) / max(1, sum(y == 1))
        spec <- sum(probs_calib_finales < pt & y == 0) / max(1, sum(y == 0))
        (sens * prev_int) - ((1 - spec) * (1 - prev_int)) * (pt / (1 - pt))
      })
      nb_all_int <- sapply(thresholds, function(pt) { prev_int - (1 - prev_int) * (pt / (1 - pt)) })
      
      df_dca_comb <- data.frame(
        Threshold = rep(thresholds, 3),
        NB = c(nb_model_int, nb_all_int, rep(0, length(thresholds))),
        Type = rep(c("Modèle (Apprentissage)", "Treat all (Apprentissage)", "Treat none"), each=length(thresholds))
      )
      
      x_comb_sc <- x_net_final_sc
      y_comb <- y
      id_comb <- df$ID_Interne
      prob_comb <- probs_calib_finales
      cohorte_comb <- rep("Apprentissage", nrow(x_net_final_sc))
      
      if (!is.null(input$file_ext)) {
        df_ext <- read_data_file(input$file_ext$datapath, input$file_ext$name)
        if(target_col %in% names(df_ext)) {
          y_ext <- as.numeric(df_ext[[target_col]])
          
          x_ext_all_raw <- matrix(0, nrow = nrow(df_ext), ncol = length(m_res$scale_center))
         colnames(x_ext_all_raw) <- names(m_res$scale_center)
          
          for(v in colnames(x_ext_all_raw)) {
            if(grepl("_sursum_", v)) {
              parts <- strsplit(v, "_sursum_")[[1]]
              if(all(parts %in% names(df_ext))) x_ext_all_raw[, v] <- df_ext[[parts[1]]] / (df_ext[[parts[1]]] + df_ext[[parts[2]]] + 1e-6)
            } else if(grepl("_logsur_", v)) {
              parts <- strsplit(v, "_logsur_")[[1]]
              if(all(parts %in% names(df_ext))) x_ext_all_raw[, v] <- log((df_ext[[parts[1]]] + 1e-6) / (df_ext[[parts[2]]] + 1e-6))
            } else if(grepl("_diffsum_", v)) {
              parts <- strsplit(v, "_diffsum_")[[1]]
              if(all(parts %in% names(df_ext))) x_ext_all_raw[, v] <- (df_ext[[parts[1]]] - df_ext[[parts[2]]]) / (df_ext[[parts[1]]] + df_ext[[parts[2]]] + 1e-6)
            } else if(grepl("_sur_", v)) {
              parts <- strsplit(v, "_sur_")[[1]]
              if(all(parts %in% names(df_ext))) x_ext_all_raw[, v] <- (df_ext[[parts[1]]] + 1e-6) / (df_ext[[parts[2]]] + 1e-6)
            } else {
              if(v %in% names(df_ext)) x_ext_all_raw[, v] <- as.numeric(df_ext[[v]])
            }
         }
          
          x_ext_full_sc <- scale(x_ext_all_raw, center = m_res$scale_center, scale = m_res$scale_std)
          p_e_raw <- as.numeric(predict(m_res$fit, newx=x_ext_full_sc, type="response"))
          p_e_cal <- as.numeric(predict(m_res$calib_model, newdata=data.frame(logit_oof=log((p_e_raw+1e-2)/(1-p_e_raw+1e-2))), type="response"))
          
          roc_ext <- roc(y_ext, p_e_cal, quiet=TRUE)
          auc_ext_ci <- as.numeric(ci.auc(roc_ext))
          pr_obj_ext <- PRROC::pr.curve(scores.class0 = p_e_cal, weights.class0 = y_ext, curve=TRUE)
          
          tp_e <- sum(p_e_cal>=0.5 & y_ext==1)
          fn_e <- sum(p_e_cal<0.5 & y_ext==1)
          tn_e <- sum(p_e_cal<0.5 & y_ext==0)
          fp_e <- sum(p_e_cal>=0.5 & y_ext==0)
          
         sens_e_ci <- binom.test(tp_e, tp_e+fn_e)$conf.int
          spec_e_ci <- binom.test(tn_e, tn_e+fp_e)$conf.int
          
        m_res$ext_metrics <- list(
            auc_val = auc_ext_ci[2], auc_lower = auc_ext_ci[1], auc_upper = auc_ext_ci[3],
            pr_auc = pr_obj_ext$auc.integral,
            sens = tp_e/(tp_e+fn_e), sens_lower = sens_e_ci[1], sens_upper = sens_e_ci[2],
            spec = tn_e/(tn_e+fp_e), spec_lower = spec_e_ci[1], spec_upper = spec_e_ci[2],
            brier = mean((p_e_cal - y_ext)^2)
          )
          
        roc_list[["Validation Externe"]] <- roc_ext
          df_pr_comb <- rbind(df_pr_comb, data.frame(Recall = pr_obj_ext$curve[,1], Precision = pr_obj_ext$curve[,2], Cohorte = "Validation Externe"))
         df_calib_comb <- rbind(df_calib_comb, data.frame(p = p_e_cal, y = y_ext, Cohorte = "Validation Externe"))
          
          prev_ext <- mean(y_ext == 1)
          nb_model_ext <- sapply(thresholds, function(pt) {
            sens <- sum(p_e_cal >= pt & y_ext == 1) / max(1, sum(y_ext == 1))
            spec <- sum(p_e_cal < pt & y_ext == 0) / max(1, sum(y_ext == 0))
            (sens * prev_ext) - ((1 - spec) * (1 - prev_ext)) * (pt / (1 - pt))
          })
          df_dca_comb <- rbind(df_dca_comb, data.frame(Threshold = rep(thresholds, 2), NB = c(nb_model_ext, sapply(thresholds, function(pt) { prev_ext - (1 - prev_ext) * (pt / (1 - pt)) })), Type = rep(c("Modèle (Externe)", "Treat all (Externe)"), each=length(thresholds))))
          
         x_comb_sc <- rbind(x_comb_sc, x_ext_full_sc)
          y_comb <- c(y_comb, y_ext)
          id_ext <- if("ID_Interne" %in% names(df_ext)) df_ext$ID_Interne else paste0("Ext_", 1:nrow(x_ext_full_sc))
          id_comb <- c(id_comb, id_ext)
          prob_comb <- c(prob_comb, p_e_cal)
          cohorte_comb <- c(cohorte_comb, rep("Validation Externe", nrow(x_ext_full_sc)))
        }
      } else { m_res$ext_metrics <- NULL }
      
      m_res$plot_roc_ggplot <- ggroc(roc_list, linewidth = 1.2) +
        scale_color_manual(values = c("Apprentissage (OOB)" = "#10b981", "Validation Externe" = "#3b82f6")) +
        theme_minimal() + geom_abline(slope=1, intercept=1, linetype="dashed", color="#94a3b8") + 
        labs(color = "Cohorte")
      
      m_res$plot_pr_ggplot <- ggplot(df_pr_comb, aes(x=Recall, y=Precision, color=Cohorte)) + 
        geom_line(linewidth=1.2) + 
        scale_color_manual(values = c("Apprentissage (OOB)" = "#10b981", "Validation Externe" = "#3b82f6")) +
        theme_minimal() + 
        labs(x="Sensibilité (Recall)", y="VPP (Precision)", color = "Cohorte")
 
      m_res$plot_calib_ggplot <- ggplot(df_calib_comb, aes(x = p, y = y, color = Cohorte)) +
        geom_point(alpha = 0.2, size=1.5) + geom_smooth(method = "loess", se = FALSE, linewidth=1.2) + 
        geom_abline(slope = 1, intercept = 0, linetype = "dashed", color="#94a3b8") +
        scale_color_manual(values = c("Apprentissage (OOB)" = "#10b981", "Validation Externe" = "#3b82f6")) +
       theme_minimal() + labs(x = "Probabilité prédite", y = "Diagnostic")
        
      m_res$plot_dca_ggplot <- ggplot(df_dca_comb, aes(x=Threshold, y=NB, color=Type, linetype=Type, linewidth=Type)) +
        geom_line() + coord_cartesian(ylim=c(-0.05, max(nb_model_int, na.rm=T)+0.05)) +
       scale_color_manual(values=c("Modèle (Apprentissage)"="#10b981", "Treat all (Apprentissage)"="#a7f3d0", "Modèle (Externe)"="#3b82f6", "Treat all (Externe)"="#93c5fd", "Treat none"="#e2e8f0")) +
       scale_linetype_manual(values=c("Modèle (Apprentissage)"="solid", "Treat all (Apprentissage)"="dotted", "Modèle (Externe)"="solid", "Treat all (Externe)"="dotted", "Treat none"="solid")) +
    scale_linewidth_manual(values=c("Modèle (Apprentissage)"=1.5, "Treat all (Apprentissage)"=0.8, "Modèle (Externe)"=1.5, "Treat all (Externe)"=0.8, "Treat none"=0.8)) +
        theme_minimal() + labs(x="Seuil de Probabilité", y="Net Benefit")
      
      probs_autre <- probs_calib_finales[y == 0]
      probs_llc <- probs_calib_finales[y == 1]
      seuil_bas <- quantile(probs_autre, 0.95, na.rm = TRUE)
      seuil_haut <- quantile(probs_llc, 0.05, na.rm = TRUE)
      
      if(seuil_bas >= seuil_haut) { seuil_bas <- 0.20; seuil_haut <- 0.80 }
      m_res$seuil_bas <- seuil_bas
      m_res$seuil_haut <- seuil_haut
      
      set.seed(42)
      umap_config <- umap.defaults
      umap_config$n_neighbors <- min(15, nrow(x_comb_sc) - 1)
      umap_res <- umap(x_comb_sc, config=umap_config)
      umap_coords <- umap_res$layout
      
      hdb_res <- dbscan::hdbscan(umap_coords, minPts = max(5, floor(nrow(umap_coords) * 0.05)))
      cluster_labels <- ifelse(hdb_res$cluster == 0, "Non-classé / Bruit", paste("Cluster", hdb_res$cluster))
      
      mat_comb <- rep(NA, length(y_comb))
      if("Matutes" %in% names(df)) {
         mat_comb[1:length(y)] <- suppressWarnings(as.numeric(as.character(df$Matutes)))
      }
      if (!is.null(input$file_ext)) {
         if (exists("df_ext") && "Matutes" %in% names(df_ext)) {
          mat_comb[(length(y)+1):length(y_comb)] <- suppressWarnings(as.numeric(as.character(df_ext$Matutes)))
         }
      }
      
      # --- FIX ISOLATION FOREST : SEUIL ABSOLU ENTRAÎNEMENT ---
      iso_model <- isolation.forest(x_net_final_sc, ntrees=100)
      iso_scores_train <- predict(iso_model, x_net_final_sc)
      abs_anomaly_threshold <- quantile(iso_scores_train, 0.95, na.rm = TRUE)
      
      iso_scores_comb <- predict(iso_model, x_comb_sc)
      is_atypical <- iso_scores_comb > abs_anomaly_threshold
      
      z_scores_intra <- x_comb_sc 
      for(g_val in c(0, 1)) {
        idx_g <- which(y_comb == g_val)
        if(length(idx_g) > 0) {
          mat_g <- x_comb_sc[idx_g, , drop=FALSE]
          mu_g <- colMeans(mat_g)
          sd_g <- apply(mat_g, 2, sd); sd_g[sd_g == 0] <- 1
          z_scores_intra[idx_g, ] <- scale(mat_g, center=mu_g, scale=sd_g)
        }
      }
     m_res$z_scores_intra <- z_scores_intra
     m_res$x_std_matrix_comb <- x_comb_sc 
      
      m_res$df_plot_pca <- data.frame(
        RowIndex = 1:nrow(x_comb_sc), 
        ID = id_comb, 
        UMAP1 = umap_coords[,1], 
        UMAP2 = umap_coords[,2], 
        Cluster = cluster_labels,
        Statut_Reel = as.factor(ifelse(y_comb == 1, "LLC", "Autre")), 
        Probabilite = prob_comb,
        Cohorte = factor(cohorte_comb, levels=c("Apprentissage", "Validation Externe")),
        Atypique = is_atypical,
        Matutes = mat_comb
      )
      
      m_res$df_plot_pca$Couleur_Groupe <- ifelse(!is.na(m_res$df_plot_pca$Matutes) & m_res$df_plot_pca$Matutes == 3, "Matutes 3 (Rouge)", 
                                         ifelse(m_res$df_plot_pca$Atypique, "Atypique (Violet)", 
                                                ifelse(m_res$df_plot_pca$Cohorte == "Apprentissage", "Apprentissage (Vert)", "Validation (Bleu)")))
      
      df_all_patients <- data.frame(
        Cohorte = cohorte_comb,
        ID_Interne = id_comb,
        Diagnostic = ifelse(y_comb == 1, "LLC", "Autre"),
        Prob_AI_Pct = paste0(round(prob_comb*100, 1), "%"),
        Ecart_Diag = round(abs(prob_comb - y_comb), 3),
        Atypique_IF = ifelse(is_atypical, "Oui", "Non"),
        Cluster = cluster_labels
      )
      
      m_res$df_all_export <- cbind(df_all_patients, as.data.frame(round(z_scores_intra, 2)))
      m_res$df_recap_export <- m_res$df_all_export[m_res$df_all_export$Atypique_IF == "Oui" | m_res$df_all_export$Ecart_Diag > 0.5, ]
      
      if ("Matutes" %in% names(df)) {
        mat_raw <- df$Matutes
        mat_clean <- suppressWarnings(as.numeric(as.character(mat_raw)))
        mat_clean[is.na(mat_clean)] <- 0
        
        grp <- dplyr::case_when(
          mat_clean <= 2 ~ "0, 1, 2 (Non-LLC)",
          mat_clean == 3 ~ "3 (Atypique)",
          mat_clean >= 4 ~ "4, 5 (LLC)",
          TRUE ~ "Inconnu"
        )
        
        df_reclass <- data.frame(
          Patient = 1:length(y),
          ID_Interne = df$ID_Interne,
          Matutes = mat_clean,
          Groupe = factor(grp, levels = c("0, 1, 2 (Non-LLC)", "3 (Atypique)", "4, 5 (LLC)")),
          Prob_AI = probs_calib_finales,
          Truth = factor(ifelse(y == 1, "LLC", "Autre"), levels=c("LLC", "Autre"))
        )
        
        df_reclass$Diag_Num <- ifelse(df_reclass$Truth == "LLC", 1, 0)
        df_reclass$Ecart_Pred <- abs(df_reclass$Prob_AI - df_reclass$Diag_Num)
        df_reclass$Atypique_Diag <- df_reclass$Ecart_Pred > 0.5
        
        df_reclass$X_jitter <- as.numeric(df_reclass$Groupe) + runif(nrow(df_reclass), -0.15, 0.15)
        m_res$df_reclass <- df_reclass
        
        mat3_idx <- which(df_reclass$Matutes == 3)
        if(length(mat3_idx) > 1) {
            x_mat3 <- x_net_final_sc[mat3_idx, , drop=FALSE]
            mat3_annot <- data.frame(Diagnostic = ifelse(y[mat3_idx] == 1, "LLC", "Autre"))
            rownames(mat3_annot) <- df$ID_Interne[mat3_idx]
            rownames(x_mat3) <- df$ID_Interne[mat3_idx]
            
            m_res$plot_heatmap <- pheatmap::pheatmap(
                x_mat3,
                annotation_row = mat3_annot,
                color = colorRampPalette(c("#3b82f6", "white", "#ef4444"))(50),
                main = "",
                silent = TRUE
            )
            m_res$show_heatmap <- TRUE
        } else {
            m_res$show_heatmap <- FALSE
        }
        
        roc_matutes <- suppressWarnings(pROC::roc(y, mat_clean, direction = "<", quiet = TRUE))
        test_delong <- suppressWarnings(pROC::roc.test(m_res$roc_obj, roc_matutes, method = "delong"))
        pval_delong <- test_delong$p.value
        
        c_mat <- ifelse(mat_clean >= 4, 3, ifelse(mat_clean == 3, 2, 1))
        c_per <- ifelse(probs_calib_finales > m_res$seuil_haut, 3, ifelse(probs_calib_finales < m_res$seuil_bas, 1, 2))
        
        up_llc <- sum(c_per > c_mat & y == 1) / max(1, sum(y == 1))
        down_llc <- sum(c_per < c_mat & y == 1) / max(1, sum(y == 1))
        nri_event <- up_llc - down_llc
        
        up_other <- sum(c_per > c_mat & y == 0) / max(1, sum(y == 0))
        down_other <- sum(c_per < c_mat & y == 0) / max(1, sum(y == 0))
        nri_nonevent <- down_other - up_other
        
        se_nri_e <- sqrt(max(0, up_llc + down_llc - (up_llc - down_llc)^2) / max(1, sum(y == 1)))
        se_nri_ne <- sqrt(max(0, up_other + down_other - (up_other - down_other)^2) / max(1, sum(y == 0)))
        se_nri <- sqrt(se_nri_e^2 + se_nri_ne^2)
        
        nri_total <- round((nri_event + nri_nonevent) * 100, 1)
        nri_lower <- round(((nri_event + nri_nonevent) - 1.96 * se_nri) * 100, 1)
       nri_upper <- round(((nri_event + nri_nonevent) + 1.96 * se_nri) * 100, 1)
        
        pval_str <- if(pval_delong < 0.05) paste0(format.pval(pval_delong, digits=3), " (Significatif)") else paste0(format.pval(pval_delong, digits=3), " (Non significatif, effet plafond sur les cas évidents)")
        
        m_res$matutes_stats_html <- paste0(
          "<div style='background:#f5f3ff; border:1px solid #ddd6fe; padding:15px; border-radius:8px; margin-bottom:15px;'>",
          "<h5 style='color:#7c3aed; font-weight:bold; margin-top:0;'>Analyse Statistique de Supériorité</h5>",
          "<ul style='margin-bottom:0; color:#4c1d95; font-size:0.95em;'>",
          "<li><b>Net Reclassification Improvement (NRI) : <span style='color:", ifelse(nri_total>0, "#10b981", "#ef4444"), "'>", ifelse(nri_total>0, "+", ""), nri_total, "%</span> <span style='font-size:0.85em;'>[IC 95% : ", nri_lower, "% à ", nri_upper, "%]</span></b><br>Mesure l'amélioration nette du classement diagnostique par rapport au score de Matutes initial.</li>",
          "<li style='margin-top:8px;'><b>Test de DeLong (Différence d'AUC) : p-value = ", pval_str, "</b></li>",
      "</ul></div>"
        )
        
        t_html <- "<table class='table table-hover reclass-table' style='background:white; font-size:0.9em; width:100%;'>"
        t_html <- paste0(t_html, "<thead><tr style='background:#f1f5f9;'><th style='width:20%; border-color:#e2e8f0;'>Score Matutes</th><th style='width:20%; border-color:#e2e8f0;'>Diagnostic Réel</th><th style='background:#fef2f2; width:20%; border-color:#e2e8f0;'>Zone ROUGE (< ", round(m_res$seuil_bas*100, 1), "%)<br><small><i>Exclusion LLC</i></small></th><th style='background:#fffbeb; width:20%; border-color:#e2e8f0;'>Zone JAUNE (Incertitude)<br></th><th style='background:#f0fdf4; width:20%; border-color:#e2e8f0;'>Zone VERTE (> ", round(m_res$seuil_haut*100, 1), "%)<br><small><i>Diagnostic LLC</i></small></th></tr></thead><tbody>")
        
        for (g in levels(df_reclass$Groupe)) {
          sub_df <- df_reclass[df_reclass$Groupe == g, ]
          n_tot <- nrow(sub_df)
          if(n_tot == 0) next
          
          n_llc <- sum(sub_df$Truth == "LLC")
          n_autre <- sum(sub_df$Truth == "Autre")
          diag_str <- paste0("<b>", n_llc, " LLC</b><br><b>", n_autre, " Autres</b>")
          
          p_rouge <- round(sum(sub_df$Prob_AI < m_res$seuil_bas) / max(1, n_tot) * 100, 1)
          p_jaune <- round(sum(sub_df$Prob_AI >= m_res$seuil_bas & sub_df$Prob_AI <= m_res$seuil_haut) / max(1, n_tot) * 100, 1)
          p_vert <- round(sum(sub_df$Prob_AI > m_res$seuil_haut) / max(1, n_tot) * 100, 1)
          
          rouge_llc <- sum(sub_df$Prob_AI < m_res$seuil_bas & sub_df$Truth == "LLC")
          rouge_autre <- sum(sub_df$Prob_AI < m_res$seuil_bas & sub_df$Truth == "Autre")
         jaune_llc <- sum(sub_df$Prob_AI >= m_res$seuil_bas & sub_df$Prob_AI <= m_res$seuil_haut & sub_df$Truth == "LLC")
          jaune_autre <- sum(sub_df$Prob_AI >= m_res$seuil_bas & sub_df$Prob_AI <= m_res$seuil_haut & sub_df$Truth == "Autre")
          vert_llc <- sum(sub_df$Prob_AI > m_res$seuil_haut & sub_df$Truth == "LLC")
          vert_autre <- sum(sub_df$Prob_AI > m_res$seuil_haut & sub_df$Truth == "Autre")
          
          str_rouge <- paste0("<span style='font-size:1.2em; font-weight:bold;'>", p_rouge, "%</span><br><small>(", rouge_llc, " LLC, ", rouge_autre, " Autre)</small>")
          str_jaune <- paste0("<span style='font-size:1.2em; font-weight:bold;'>", p_jaune, "%</span><br><small>(", jaune_llc, " LLC, ", jaune_autre, " Autre)</small>")
          str_vert <- paste0("<span style='font-size:1.2em; font-weight:bold;'>", p_vert, "%</span><br><small>(", vert_llc, " LLC, ", vert_autre, " Autre)</small>")
          
          t_html <- paste0(t_html, "<tr><td style='border-color:#e2e8f0;'><b>", g, "</b><br>N=", n_tot, "</td><td style='border-color:#e2e8f0;'>", diag_str, "</td><td style='background:#fef2f2; border-color:#e2e8f0;'>", str_rouge, "</td><td style='background:#fffbeb; border-color:#e2e8f0;'>", str_jaune, "</td><td style='background:#f0fdf4; border-color:#e2e8f0;'>", str_vert, "</td></tr>")
        }
      t_html <- paste0(t_html, "</tbody></table>")
        m_res$table_matutes_html <- t_html
        
      } else {
        m_res$table_matutes_html <- NULL
      }
      
  show_premium_popup("Modélisation Terminée", "Calculs effectués avec succès.")
    })
  })
  
  # --- LOGIQUE DE SELECTION MUTUELLE ET GLOBALE ---
  
  # Depuis UMAP
  observeEvent(input$plot_atypical_click, {
    clicked_pt <- nearPoints(m_res$df_plot_pca, input$plot_atypical_click, xvar = "UMAP1", yvar = "UMAP2", maxpoints = 1, threshold = 20)
    if (nrow(clicked_pt) > 0) {
      selected_patient(clicked_pt$ID[1])
    } else {
      selected_patient(NULL)
    }
  })
 
  # Depuis Matutes
  observeEvent(input$plot_matutes_click, {
    clicked_pt <- nearPoints(m_res$df_reclass, input$plot_matutes_click, xvar = "X_jitter", yvar = "Prob_AI", maxpoints = 1, threshold = 15)
    if (nrow(clicked_pt) > 0) {
      selected_patient(clicked_pt$ID_Interne[1])
    } else {
      selected_patient(NULL)
    }
  })
 
  # Depuis Tableau Atypiques
 observeEvent(input$table_recap_atypiques_rows_selected, {
    idx <- input$table_recap_atypiques_rows_selected
    if(length(idx) > 0) {
      id <- m_res$df_recap_export$ID_Interne[idx]
      if(!identical(selected_patient(), id)) selected_patient(id)
    }
  }, ignoreNULL = FALSE, ignoreInit = TRUE)
 
  # Depuis Tableau Complet
  observeEvent(input$table_atypical_rows_selected, {
    idx <- input$table_atypical_rows_selected
    if(length(idx) > 0) {
      id <- m_res$df_all_export$ID_Interne[idx]
      if(!identical(selected_patient(), id)) selected_patient(id)
    }
  }, ignoreNULL = FALSE, ignoreInit = TRUE)
 
  # Propagation de la sélection dans les DataTables
  observeEvent(selected_patient(), {
    id <- selected_patient()
    
    proxy_recap <- dataTableProxy("table_recap_atypiques")
    proxy_all <- dataTableProxy("table_atypical")
    
    if (is.null(id)) {
      selectRows(proxy_recap, NULL)
      selectRows(proxy_all, NULL)
    } else {
      if (!is.null(m_res$df_recap_export)) {
        idx_r <- which(m_res$df_recap_export$ID_Interne == id)
        if(length(idx_r) > 0) selectRows(proxy_recap, idx_r) else selectRows(proxy_recap, NULL)
      }
      if (!is.null(m_res$df_all_export)) {
        idx_a <- which(m_res$df_all_export$ID_Interne == id)
        if(length(idx_a) > 0) selectRows(proxy_all, idx_a) else selectRows(proxy_all, NULL)
      }
    }
  }, ignoreNULL = FALSE)
 
 output$patient_count_ui <- renderUI({
   req(m_res$df_train)
    df <- m_res$df_train; target_col <- if("LLC_1" %in% names(df)) "LLC_1" else "LLC"
    y <- as.numeric(df[[target_col]]); n_pat <- nrow(df); n_events <- min(sum(y == 1, na.rm=TRUE), sum(y == 0, na.rm=TRUE))
    df_numeric <- df[, sapply(df, is.numeric)]
    
    matutes_cols <- grep("(?i)matutes", names(df_numeric), value = TRUE)
    n_base_markers <- length(setdiff(names(df_numeric), c(target_col, matutes_cols)))
    
    n_preds <- n_base_markers
    if(input$calc_ratios_all && n_base_markers >= 2) n_preds <- n_preds + (choose(n_base_markers, 2) * 4)
    else if(input$calc_ratios_simple && n_base_markers >= 2) n_preds <- n_preds + choose(n_base_markers, 2)
    
    epv <- n_events / max(1, n_preds)
    if(input$use_epv_filter) epv <- n_events / max(1, floor(n_events / 5))
    
    if(epv < 5) {
      status_color <- "#ef4444"; status_bg <- "#fef2f2"; status_text <- "Taille de cohorte INSUFFISANTE (Contrainte Événements)"
      advice <- paste0("Votre ratio Événements par Variable (EPV) calculé est de ", round(epv, 1), ". Un ratio d'au moins 5 (Vittinghoff & McCulloch) est requis pour assurer la stabilité.")
    } else {
      status_color <- "#10b981"; status_bg <- "#f0fdf4"; status_text <- "Taille de cohorte SATISFAISANTE (Critère Événements)"
      advice <- paste0("Votre ratio Événements par Variable (EPV) est sécurisé à ", round(epv, 1), " (Seuil cible >= 5).")
    }
    
    html_out <- div(class = "modern-card", style = paste0("border-left: 5px solid ", status_color, "; background-color: ", status_bg, "; padding: 18px; margin-bottom: 25px;"),
        h5(status_text, style=paste0("font-weight:800; color:", status_color, "; margin-top:0;")),
        p(HTML(paste0("Cohorte : <b>", n_pat, "</b> patients inclus, avec <b>", n_events, "</b> événements de la classe minoritaire pour <b>", n_preds, "</b> candidats prédicteurs. ", advice)), style="margin-bottom:0; color:#334155; font-size:1.05em;")
    )
    
    # Ajout du badge AutoML si activé
    if(!is.null(m_res$automl_msg)) {
      html_out <- tagList(html_out, div(class="modern-card", style="border-left: 5px solid #3b82f6; background-color: #eff6ff; padding: 15px; margin-bottom: 25px;", p(m_res$automl_msg, style="margin-bottom:0; color:#1e3a8a; font-weight:600;")))
    }
    
    return(html_out)
  })
 
  output$metrics_ui <- renderUI({
    req(m_res$metrics)
    div(class = "modern-card train-panel", fluidRow(
      column(4, div(class='sub-metric', "AUC (Nested CV)"), div(class='big-metric', HTML(paste0(round(m_res$metrics$auc_val, 3), " <br><span style='font-size:0.45em; color:#64748b;'>[IC 95%: ", round(m_res$metrics$auc_lower,2), "-", round(m_res$metrics$auc_upper,2), "]</span>")))),
      column(4, div(class='sub-metric', "Sensibilité / Spécificité"), div(class='big-metric', HTML(paste0(round(m_res$metrics$sens*100,1), "% / ", round(m_res$metrics$spec*100,1), "% <br><span style='font-size:0.45em; color:#64748b;'>[IC 95%: Sens ", round(m_res$metrics$sens_lower*100,1), "-", round(m_res$metrics$sens_upper*100,1), "% | Spéc ", round(m_res$metrics$spec_lower*100,1), "-", round(m_res$metrics$spec_upper*100,1), "%]</span>")))),
      column(4, div(class='sub-metric', "Brier Score"), div(class='big-metric', round(m_res$metrics$brier, 3)))
    ))
  })
  
 output$nature_metrics_ui <- renderUI({
    req(m_res$metrics, m_res$pr_auc)
    div(class = "modern-card nature-panel", h5("MÉTRIQUES AVANCÉES OOB", style="font-weight:700; color:#8b5cf6; margin-bottom:15px;"), fluidRow(
      column(4, div(class='sub-metric', "PR-AUC", span(class='ideal-val', " (idéal ~1)")), div(class='big-metric', round(m_res$pr_auc, 3), style="font-size:1.6rem;")),
      column(4, div(class='sub-metric', "Calib Int | Slope", span(class='ideal-val', " (0 | 1)")), div(class='big-metric', paste0(round(m_res$metrics$calib_intercept, 2), " | ", round(m_res$metrics$calib_slope, 2)), style="font-size:1.6rem;")),
      column(4, div(class='sub-metric', "Emax | ICI", span(class='ideal-val', " (<0.05)")), div(class='big-metric', paste0(round(m_res$metrics$Emax, 3), " | ", round(m_res$metrics$ICI, 3)), style="font-size:1.6rem;"))
    ))
  })
  
  output$ext_metrics_title_ui <- renderUI({ req(m_res$ext_metrics); h4("Performances : Cohorte de Validation Externe", style="font-weight:700; color:#0f172a; margin-top: 30px; margin-left: 5px;") })
  
  output$ext_metrics_ui <- renderUI({
    req(m_res$ext_metrics)
    div(class = "modern-card ext-panel", fluidRow(
      column(3, div(class='sub-metric', "AUC"), div(class='big-metric', HTML(paste0(round(m_res$ext_metrics$auc_val, 3), " <br><span style='font-size:0.45em; color:#64748b;'>[IC 95%: ", round(m_res$ext_metrics$auc_lower,2), "-", round(m_res$ext_metrics$auc_upper,2), "]</span>")))),
      column(3, div(class='sub-metric', "PR-AUC"), div(class='big-metric', round(m_res$ext_metrics$pr_auc, 3))),
      column(3, div(class='sub-metric', "Sens / Spéc"), div(class='big-metric', HTML(paste0(round(m_res$ext_metrics$sens*100,1), "% / ", round(m_res$ext_metrics$spec*100,1), "% <br><span style='font-size:0.45em; color:#64748b;'>[IC Sens: ", round(m_res$ext_metrics$sens_lower*100,1), "-", round(m_res$ext_metrics$sens_upper*100,1), "% | Spéc: ", round(m_res$ext_metrics$spec_lower*100,1), "-", round(m_res$ext_metrics$spec_upper*100,1), "%]</span>")))),
      column(3, div(class='sub-metric', "Brier Score"), div(class='big-metric', round(m_res$ext_metrics$brier, 3)))
    ))
  })
  
  output$agreement_ui <- renderUI({
    req(m_res$ext_metrics, m_res$roc_obj)
    diff_auc <- m_res$ext_metrics$auc_val - as.numeric(pROC::auc(m_res$roc_obj))
    is_normal_gap <- (diff_auc >= -0.02 && diff_auc <= 0.12)
   div(class = "modern-card", style = if(is_normal_gap) "border-left: 5px solid #10b981; background-color: #f0fdf4;" else "border-left: 5px solid #f59e0b; background-color: #fffbeb;", 
        h5("COMPARAISON DES COHORTES", style="font-weight:700;"), p(paste0("Écart d'AUC : ", round(diff_auc, 3))),
     if(is_normal_gap) p("✅ ÉCART NORMAL : L'écart est aligné avec l'optimisme statistique standard.", style="color:#166534; font-size:0.9em;")
        else p("⚠️ ÉCART ATYPIQUE : La dérive dépasse les seuils attendus.", style="color:#92400e; font-size:0.9em;")
    )
  })
  
  # Boîte de détails pour le Matutes (lié au patient sélectionné globalement)
  output$matutes_click_info <- renderUI({
    req(selected_patient(), m_res$df_reclass, m_res$z_scores_intra)
    
    id <- selected_patient()
    idx_row <- which(m_res$df_reclass$ID_Interne == id)
    if (length(idx_row) == 0) return(NULL)
    
    clicked_pt <- m_res$df_reclass[idx_row[1], ]
    
    idx <- clicked_pt$Patient
    id_interne <- clicked_pt$ID_Interne
    ecart_pred <- clicked_pt$Ecart_Pred
    
    z_scores <- m_res$z_scores_intra[idx, ]
    extreme_vars <- sort(abs(z_scores), decreasing = TRUE)[1:min(4, length(z_scores))]
    
    html_str <- paste0(
      "<div style='background:#faf5ff; border-left:5px solid #4c1d95; padding:15px; border-radius:8px; margin-top:15px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);'>",
      "<h5 style='color:#a855f7; font-weight:bold; margin-top:0;'> Patient Sélectionné : ", id_interne, "</h5>",
      "<p style='color:#475569; font-size:0.95em;'><b>Diagnostic Réel :</b> ", clicked_pt$Truth, " | <b>Score Matutes :</b> ", clicked_pt$Matutes, " | <b>Probabilité IA :</b> ", round(clicked_pt$Prob_AI*100,1), "% | <b>Ecart Diag-Prédiction :</b> ", round(ecart_pred, 3), "</p>",
      "<p style='margin-bottom:5px; color:#4c1d95; font-weight:bold;'>Variables ayant le plus influencé l'IA pour ce patient :</p><ul style='color:#475569;'>"
    )
    for(v in names(extreme_vars)) {
       val <- z_scores[v]
       signe <- ifelse(val > 0, "+", "")
       html_str <- paste0(html_str, "<li><b>", v, "</b> : ", signe, round(val, 2), " <i>écarts-types par rapport à la moyenne de son groupe diagnostique</i></li>")
    }
    html_str <- paste0(html_str, "</ul></div>")
    
    HTML(html_str)
  })
  
  output$matutes_reclass_ui <- renderUI({
    req(m_res$table_matutes_html)
    div(class="modern-card", style="border-top: 5px solid #4c1d95;",
        h4("Classification Diagnostique (PERCYMAT vs Matutes)", style="font-weight:700; color:#a855f7; margin-bottom:10px;"),
       p("Les patients dits 'atypiques' (Bords Rouge) sont détectés par calcul de la différence entre probabilité calculée et diagnostic final. Les seuils de la zone d’incertitude sont adaptés en fonction des résultats de la cohorte d’apprentissage sur le groupe Out-Of-Bag. Cliquez sur un point pour voir les caractéristiques.", style="font-size:0.85em; color:#64748b;"),
        
        HTML(m_res$matutes_stats_html),
        
        fluidRow(
          column(12, 
             plotOutput("plot_matutes_jitter", click = "plot_matutes_click"),
              uiOutput("matutes_click_info")
          )
        ),
        br(),
        h5("Répartition des Patients par Zones de Confiance", style="font-weight:700; color:#a855f7; margin-top:20px;"),
        HTML(m_res$table_matutes_html)
    )
  })
  
  output$plot_matutes_jitter <- renderPlot({
    req(m_res$df_reclass, m_res$seuil_bas, m_res$seuil_haut)
    
    p <- ggplot(m_res$df_reclass, aes(x = X_jitter, y = Prob_AI, shape = Truth, fill = Truth)) +
      annotate("rect", ymin = 0, ymax = m_res$seuil_bas, xmin = -Inf, xmax = Inf, fill = "#fef2f2", alpha = 0.9) +
      annotate("rect", ymin = m_res$seuil_bas, ymax = m_res$seuil_haut, xmin = -Inf, xmax = Inf, fill = "#fffbeb", alpha = 0.7) +
      annotate("rect", ymin = m_res$seuil_haut, ymax = 1.00, xmin = -Inf, xmax = Inf, fill = "#f0fdf4", alpha = 0.9) +
      geom_hline(yintercept = m_res$seuil_bas, linetype = "dashed", color = "#ef4444", linewidth=0.8) +
      geom_hline(yintercept = m_res$seuil_haut, linetype = "dashed", color = "#10b981", linewidth=0.8) +
      geom_point(aes(stroke = ifelse(Atypique_Diag, 1.5, 0.6), color = ifelse(Atypique_Diag, "#ef4444", "black")), size = 3.5, alpha = 0.85) +
      scale_shape_manual(values = c("LLC" = 21, "Autre" = 24)) +
      scale_fill_manual(values = c("LLC" = "#1e293b", "Autre" = "#cbd5e1")) +
      scale_color_identity() +
      scale_x_continuous(breaks = 1:3, labels = levels(m_res$df_reclass$Groupe)) +
      scale_y_continuous(labels = scales::percent_format(accuracy=1), limits = c(0, 1)) +
     theme_minimal(base_size=14) + labs(x = "Score de Matutes Humain", y = "Probabilité calculée", fill="Diagnostic Réel", shape="Diagnostic Réel", title="Dispersion des patients (Seuils adaptatifs OOB)") +
      theme(legend.position="bottom", plot.title=element_text(face="bold", color="#0f172a"), panel.grid.major.x = element_blank(), panel.grid.minor.x = element_blank())
      
      # Cross-highlight ciblé depuis le tableau ou l'UMAP
      if(!is.null(selected_patient())) {
         highlight_data <- m_res$df_reclass[m_res$df_reclass$ID_Interne == selected_patient(), ]
         if(nrow(highlight_data) > 0) {
            p <- p + geom_point(data = highlight_data, aes(x = X_jitter, y = Prob_AI), color = "black", fill = "yellow", size = 6, shape = 21, stroke = 2) +
                     geom_point(data = highlight_data, aes(x = X_jitter, y = Prob_AI), color = "red", size = 10, shape = 1, stroke = 1.5)
         }
      }
      return(p)
  })
  
  output$heatmap_matutes_ui <- renderUI({
    req(m_res$show_heatmap)
    div(class="modern-card", style="border-top: 5px solid #4c1d95;",
        h5("Heatmap", style="font-weight:700; color:#a855f7;"),
        p("Clustering hiérarchique non-supervisé des patients Matutes 3.", style="font-size:0.85em; color:#64748b;"),
        plotOutput("plot_heatmap", height = "500px")
    )
  })
 
  output$plot_heatmap <- renderPlot({
    req(m_res$plot_heatmap)
    grid::grid.draw(m_res$plot_heatmap$gtable)
  })
  
  output$top_markers_ui <- renderUI({
    req(m_res$df_coef_export)
    df <- subset(m_res$df_coef_export, Marqueur != "(Intercept)")
    beautify_marker <- function(m) {
      if(grepl("_sursum_", m)) {
        pts <- strsplit(m, "_sursum_")[[1]]
        return(paste0(pts[1], " / (", pts[1], " + ", pts[2], ")"))
      } else if(grepl("_logsur_", m)) {
        pts <- strsplit(m, "_logsur_")[[1]]
        return(paste0("log(", pts[1], " / ", pts[2], ")"))
      } else if(grepl("_diffsum_", m)) {
        pts <- strsplit(m, "_diffsum_")[[1]]
        return(paste0("(", pts[1], " - ", pts[2], ") / (", pts[1], " + ", pts[2], ")"))
      } else if(grepl("_sur_", m)) {
        pts <- strsplit(m, "_sur_")[[1]]
        return(paste0(pts[1], " / ", pts[2]))
      } else {
        return(m)
      }
    }
    df$Marqueur_Joli <- sapply(df$Marqueur, beautify_marker)
    df_llc <- subset(df, Poids > 0); df_non_llc <- subset(df, Poids < 0)
    top_l <- head(df_llc[order(df_llc$Poids, decreasing = T), ], 5)
    top_n <- head(df_non_llc[order(df_non_llc$Poids, decreasing = F), ], 5)
    
    format_list <- function(d) { 
      if(nrow(d)==0) return("<i>Aucun</i>")
      paste(sapply(1:nrow(d), function(i) paste0(
        "<div style='background:#ffffff; border:1px solid #e2e8f0; border-radius:6px; padding:8px 12px; margin-bottom:6px; display:flex; justify-content:space-between; align-items:center;'>",
        "<span style='font-family:monospace; font-weight:600; color:#334155; font-size:1.05em;'>", d$Marqueur_Joli[i], "</span>",
        "<span style='background:white; border:1px solid ", ifelse(d$Poids[i]>0, "#10b981", "#ef4444") ,"; border-radius:4px; padding:2px 6px; font-size:0.85em; font-weight:700; color:", ifelse(d$Poids[i]>0, "#10b981", "#ef4444") ,"'>Poids: ", d$Poids[i], " | OR: ", d$OR[i], " | Stabilité: ", d$Stabilité[i],"</span>",
        "</div>"
      )), collapse="") 
    }
    fluidRow(
     column(6, div(class="modern-card", style="border-top:4px solid #10b981; background-color: #f0fdf4;", h4("Variables (OR > 1)", style="margin-bottom:15px; font-weight:700;"), HTML(format_list(top_l)))),
      column(6, div(class="modern-card", style="border-top:4px solid #ef4444; background-color: #fef2f2;", h4("Variables (OR < 1)", style="margin-bottom:15px; font-weight:700;"), HTML(format_list(top_n))))
    )
  })
  
  output$plot_roc <- renderPlot({ req(m_res$plot_roc_ggplot); m_res$plot_roc_ggplot })
  output$plot_calib <- renderPlot({ req(m_res$plot_calib_ggplot); m_res$plot_calib_ggplot })
  output$plot_pr <- renderPlot({ req(m_res$plot_pr_ggplot); m_res$plot_pr_ggplot })
  output$plot_dca <- renderPlot({ req(m_res$plot_dca_ggplot); m_res$plot_dca_ggplot })
  output$coef_table <- renderDT({ datatable(m_res$df_coef_export, rownames = FALSE) })
  
  output$dynamic_inputs <- renderUI({ 
    req(m_res$marker_names)
    tagList(lapply(m_res$marker_names, function(v) numericInput(paste0("in_", v), label = v, value = NA))) 
  })
  
  output$plot_atypical <- renderPlot({ 
    req(m_res$df_plot_pca)
    
    p <- ggplot(m_res$df_plot_pca, aes(x = UMAP1, y = UMAP2)) +
      stat_ellipse(aes(group = Cluster, fill = Cluster), geom = "polygon", alpha = 0.15, color = NA, level = 0.8) +
      geom_point(aes(color = Couleur_Groupe, shape = Statut_Reel), size = 3.5, alpha = 0.85) + 
      
    scale_color_manual(values = c("Apprentissage (Vert)" = "#10b981", 
                                        "Validation (Bleu)" = "#3b82f6", 
                                          "Atypique (Violet)" = "#9333ea",
                                        "Matutes 3 (Rouge)" = "#ef4444")) +
  scale_shape_manual(values = c("LLC" = 16, "Autre" = 17)) +
      theme_minimal() + 
      labs(x = "UMAP 1", y = "UMAP 2", title = "UMAP & HDBSCAN Clustering", color = "Légende", shape = "Diagnostic Réel", fill = "Clusters Détectés")
      
    # Cross-highlight ciblé depuis le tableau ou Matutes
    if(!is.null(selected_patient())) {
        highlight_data <- m_res$df_plot_pca[m_res$df_plot_pca$ID == selected_patient(), ]
        if(nrow(highlight_data) > 0) {
            p <- p + geom_point(data = highlight_data, aes(x = UMAP1, y = UMAP2), color = "black", fill = "yellow", size = 6, shape = 21, stroke = 2) +
                     geom_point(data = highlight_data, aes(x = UMAP1, y = UMAP2), color = "red", size = 10, shape = 1, stroke = 1.5)
        }
    }
    return(p)
  })
  
  # Boîte de détails pour l'UMAP (lié au patient sélectionné globalement)
  output$cluster_click_info <- renderUI({
      req(selected_patient(), m_res$df_plot_pca, m_res$z_scores_intra)
 
      id <- selected_patient()
      idx_row <- which(m_res$df_plot_pca$ID == id)
      if (length(idx_row) == 0) return(NULL)
 
      clicked_pt <- m_res$df_plot_pca[idx_row[1], ]
 
      id_interne <- clicked_pt$ID
      idx_pat <- clicked_pt$RowIndex
      groupe_reel <- as.character(clicked_pt$Statut_Reel)
      prob_pat <- clicked_pt$Probabilite
      
      matutes_val <- clicked_pt$Matutes
      matutes_str <- ifelse(is.na(matutes_val), "ND", matutes_val)
      iso_forest <- ifelse(clicked_pt$Atypique, "Atypique", "Normal")
      
      z_scores_pat_intra <- m_res$z_scores_intra[idx_pat, ]
      top_vars_pat <- sort(abs(z_scores_pat_intra), decreasing = TRUE)[1:min(5, length(z_scores_pat_intra))]
 
      html_str <- paste0(
        "<div style='background:#faf5ff; border-left:5px solid #4c1d95; padding:15px; border-radius:8px; margin-top:15px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);'>",
        "<h5 style='color:#a855f7; font-weight:bold; margin-top:0;'> Patient Sélectionné : ", id_interne, "</h5>",
        "<p style='color:#334155; font-size:0.95em;'><b>Diagnostic Réel :</b> ", groupe_reel,
        " | <b>Score Matutes :</b> ", matutes_str,
        " | <b>Probabilité IA :</b> ", round(prob_pat*100, 1), "%",
        " | <b>Résultat Isolation Forest :</b> ", iso_forest, "</p>",
        "<p style='margin-bottom:5px; color:#4c1d95; font-weight:bold;'>Profil UMAP (Z-scores) intra-groupe :</p><ul style='color:#334155; margin-bottom:0;'>"
      )
      
      for(v in names(top_vars_pat)) {
         val <- z_scores_pat_intra[v]
         signe <- ifelse(val > 0, "+", "")
         html_str <- paste0(html_str, "<li><b>", v, "</b> : ", signe, round(val, 2), " <i>écarts-types par rapport à la moyenne de son groupe diagnostique</i></li>")
      }
      html_str <- paste0(html_str, "</ul></div>")
 
      HTML(html_str)
  })
  
  output$table_recap_atypiques <- renderDT({
    req(m_res$df_recap_export)
    datatable(m_res$df_recap_export, selection = 'single', options = list(scrollX = TRUE, pageLength = 5), rownames = FALSE) 
  })
  
  output$table_atypical <- renderDT({
    req(m_res$df_all_export)
    datatable(m_res$df_all_export, selection = 'single', options = list(scrollX = TRUE, pageLength = 5), rownames = FALSE) 
  })
  
  observeEvent(input$predict, {
    req(m_res$fit)
    p_f_raw <- matrix(0, 1, length(m_res$scale_center))
    colnames(p_f_raw) <- names(m_res$scale_center)
    
    for(col_name in m_res$marker_names) {
      input_val <- input[[paste0("in_", col_name)]]
      val_raw <- ifelse(is.na(input_val), 0, input_val)
      if(col_name %in% colnames(p_f_raw)) p_f_raw[1, col_name] <- val_raw
    }
    
    for(v in colnames(p_f_raw)) {
      if(grepl("_sursum_", v)) {
        parts <- strsplit(v, "_sursum_")[[1]]
        v1 <- ifelse(is.na(input[[paste0("in_", parts[1])]]), 0, input[[paste0("in_", parts[1])]])
        v2 <- ifelse(is.na(input[[paste0("in_", parts[2])]]), 0, input[[paste0("in_", parts[2])]])
        p_f_raw[1, v] <- v1 / (v1 + v2 + 1e-6)
      } else if(grepl("_logsur_", v)) {
        parts <- strsplit(v, "_logsur_")[[1]]
        v1 <- ifelse(is.na(input[[paste0("in_", parts[1])]]), 0, input[[paste0("in_", parts[1])]])
        v2 <- ifelse(is.na(input[[paste0("in_", parts[2])]]), 0, input[[paste0("in_", parts[2])]])
        p_f_raw[1, v] <- log((v1 + 1e-6) / (v2 + 1e-6))
      } else if(grepl("_diffsum_", v)) {
        parts <- strsplit(v, "_diffsum_")[[1]]
        v1 <- ifelse(is.na(input[[paste0("in_", parts[1])]]), 0, input[[paste0("in_", parts[1])]])
        v2 <- ifelse(is.na(input[[paste0("in_", parts[2])]]), 0, input[[paste0("in_", parts[2])]])
        p_f_raw[1, v] <- (v1 - v2) / (v1 + v2 + 1e-6)
      } else if(grepl("_sur_", v)) {
        parts <- strsplit(v, "_sur_")[[1]]
        v1 <- ifelse(is.na(input[[paste0("in_", parts[1])]]), 0, input[[paste0("in_", parts[1])]])
        v2 <- ifelse(is.na(input[[paste0("in_", parts[2])]]), 0, input[[paste0("in_", parts[2])]])
        p_f_raw[1, v] <- (v1 + 1e-6) / (v2 + 1e-6)
      }
    }
    
    p_f_sc <- (p_f_raw - m_res$scale_center) / m_res$scale_std
    diag_res$p_f_sc <- p_f_sc
    pr <- as.numeric(predict(m_res$fit, newx=p_f_sc, type="response"))
    diag_res$prob_calib <- as.numeric(predict(m_res$calib_model, newdata = data.frame(logit_oof = log((pr+1e-2)/(1-pr+1e-2))), type = "response"))
    
    output$result_box <- renderUI({
      res_c <- if(diag_res$prob_calib < m_res$seuil_bas) "#ef4444" else if(diag_res$prob_calib >= m_res$seuil_haut) "#10b981" else "#f59e0b"
      
      q_val <- m_res$q_conformal
      prob_val <- diag_res$prob_calib
      set_pred <- c()
      if (prob_val >= 1 - q_val) set_pred <- c(set_pred, "LLC")
      if ((1 - prob_val) >= 1 - q_val) set_pred <- c(set_pred, "Autre")
      conformal_text <- paste0(set_pred, collapse = " OU ")
      
      div(class="modern-card", style=paste0("background:", res_c, "; color:white; text-align:center; padding: 40px;"), 
          h4("Probabilité LLC"),
          h1(paste0(round(prob_val*100, 1), "%"), style="font-size: 5em; font-weight: 800; margin:0;"),
          hr(style="border-top: 1px dashed rgba(255,255,255,0.5);"),
          h5("Conformal Prediction (Garantie 95%) :"),
          h4(paste0("{ ", conformal_text, " }"), style="font-weight:700;")
      )
    })
    
    output$patient_explain_ui <- renderUI({
     div(class="modern-card",
        h4(icon("brain"), "Explication", style="font-weight:700; color:#0f172a; margin-bottom:15px;"),
        p("Ce graphique démontre l'impact mathématique (Poids × Z-score du patient) de chaque marqueur ou variable pour ce patient.", style="font-size:0.9em; color:#64748b;"),
        plotOutput("plot_shap", height="350px")
      )
    })
    
    output$plot_shap <- renderPlot({
      req(m_res$fit, diag_res$p_f_sc)
      
      patient_z_scores <- as.numeric(diag_res$p_f_sc)
      names(patient_z_scores) <- colnames(diag_res$p_f_sc)
      
      coefs <- m_res$coefs
      valid_vars <- rownames(coefs)[rownames(coefs) != "(Intercept)" & coefs[,1] != 0]
      
      contributions <- data.frame(
        Feature = valid_vars,
        Contribution = sapply(valid_vars, function(v) {
          if (v %in% names(patient_z_scores)) {
            return(patient_z_scores[v] * coefs[v, 1])
          } else { return(0) }
        })
      )
      
      contributions <- contributions[contributions$Contribution != 0, ]
      
     if(nrow(contributions) > 0) {
        
        # Fonction locale pour rendre les noms de variables plus lisibles (Ex: A_sursum_B devient A / (A + B))
        beautify_marker <- function(m) {
          if(grepl("_sursum_", m)) {
            pts <- strsplit(m, "_sursum_")[[1]]; return(paste0(pts[1], " / (", pts[1], " + ", pts[2], ")"))
          } else if(grepl("_logsur_", m)) {
            pts <- strsplit(m, "_logsur_")[[1]]; return(paste0("log(", pts[1], " / ", pts[2], ")"))
          } else if(grepl("_diffsum_", m)) {
            pts <- strsplit(m, "_diffsum_")[[1]]; return(paste0("(", pts[1], " - ", pts[2], ") / (", pts[1], " + ", pts[2], ")"))
          } else if(grepl("_sur_", m)) {
            pts <- strsplit(m, "_sur_")[[1]]; return(paste0(pts[1], " / ", pts[2]))
          } else {
            return(m)
          }
        }
        
        # Appliquer les jolis noms
        contributions$Feature_Joli <- sapply(contributions$Feature, beautify_marker)
        
        # Sélectionner les 12 plus fortes contributions absolues (pour éviter un graphique illisible)
        top_indices <- order(abs(contributions$Contribution), decreasing = TRUE)[1:min(12, nrow(contributions))]
        contributions <- contributions[top_indices, ]
        
        # Trier le "factor" selon la valeur RÉELLE pour séparer visuellement les positifs (en haut) des négatifs (en bas)
       contributions$Feature_Joli <- factor(contributions$Feature_Joli, levels = contributions$Feature_Joli[order(contributions$Contribution)])
        
        # Définir le sens et corriger la logique des couleurs
       contributions$Sign <- ifelse(contributions$Contribution > 0, "Oriente vers LLC (+)", "Oriente vers Autre (-)")
        
        ggplot(contributions, aes(x = Feature_Joli, y = Contribution, fill = Sign)) +
          geom_bar(stat = "identity", alpha = 0.9, width = 0.65, color = "white", linewidth = 0.5) +
          geom_text(aes(label = sprintf("%+0.2f", Contribution),
                        hjust = ifelse(Contribution > 0, -0.2, 1.2)),
                    size = 4, fontface = "bold", color = "#1e293b") +
          coord_flip() +
          theme_minimal(base_size = 14) +
          scale_fill_manual(values = c("Oriente vers LLC (+)" = "#ef4444", "Oriente vers Autre (-)" = "#3b82f6")) +
         scale_y_continuous(expand = expansion(mult = c(0.25, 0.25))) + # Marge pour que le texte ne soit pas coupé
          geom_hline(yintercept = 0, linetype = "solid", color = "#1e293b", linewidth = 1) +
          labs(x = "", y = "Contribution au Log-Odds (Poids du Modèle × Z-score du Patient)", fill = "Impact Prédictif :") +
          theme(legend.position = "top",
                legend.title = element_text(face="bold"),
                panel.grid.major.y = element_blank(), # Supprime les lignes horizontales gênantes derrière les barres
                axis.text.y = element_text(fontface = "bold", size = 11))
      } else {
        ggplot() + annotate("text", x=0, y=0, label="Aucune contribution significative", color="#64748b") + theme_void()
      }
    })
  })
}

shinyApp(ui, server)
