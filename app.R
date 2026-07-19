# ==============================================================================
# 1. FICHIER : global.R (ou R/utils.R)
# Gère les dépendances et les fonctions "pures" indépendantes de Shiny
# ==============================================================================

packages_requis <- c(
  "shiny", "pROC", "shinythemes", "glmnet", "DT", 
  "ggplot2", "stats", "arm", "rmarkdown", "dplyr",
  "gridExtra", "PRROC", "readxl", "tools", "scales",
  "umap", "pheatmap", "cluster", "dbscan", "isotree",
  "tidyr", "caret" 
)
for (pkg in packages_requis) {
  suppressPackageStartupMessages(library(pkg, character.only = TRUE))
}

# Fonction pure pour la lecture des données
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

# Fonction pure pour rendre le nom des marqueurs lisibles (principe DRY)
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

# Fonction pour le popup premium
show_premium_popup <- function(title, text) {
  showModal(modalDialog(
    title = NULL, footer = NULL, easyClose = TRUE,
    div(div(class = "modal-success-icon", icon("check-circle")),
        div(class = "modal-premium-title", title),
        div(class = "modal-premium-body", text),
        tags$script(HTML("setTimeout(function() { $('.modal').modal('hide'); }, 2200);")))
  ))
}

# ==============================================================================
# 2. FICHIER : R/mod_modeling.R
# Module dédié à l'entraînement du modèle
# ==============================================================================

mod_modeling_ui <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      h4("Training Cohort", style="font-weight: 700; color: #0f172a;"),
      fileInput(ns("file_csv"), "Import CSV / Excel", accept = c(".csv", "text/csv", ".xlsx", ".xls")),
      
      h4("External Validation Cohort", style="font-weight: 700; color: #0f172a; margin-top:25px;"),
      fileInput(ns("file_ext"), "Import CSV / Excel", accept = c(".csv", "text/csv", ".xlsx", ".xls")),
      
      hr(),
      numericInput(ns("cv_repeats"), "Number of Nested-CV Repeats", value = 10, min = 1, max = 50),
      
      hr(),
      actionButton(ns("update_model"), "RUN MODELING",
                   class = "btn-success btn-lg btn-block", 
                   style = "font-weight: 700; border-radius: 10px;",
                   icon = icon("play-circle")),
      hr(),
      helpText("V2.4: Elastic-Net, HDBSCAN, Isolation Forest & Local Log-Odds Explainer. Fully automated unsupervised workflow with systematic combinatorial engineering.")
    ),
    mainPanel(
      tabsetPanel(
        tabPanel("Performances", 
                 br(),
                 uiOutput(ns("patient_count_ui")),
                 fluidRow(
                   column(6, div(class="modern-card", 
                                 h5("ROC Curve", style="font-weight:700;"),
                                 p("Evaluation of FP and FN.", style="font-size:0.85em; color:#64748b;"),
                                 plotOutput(ns("plot_roc")))),
                   column(6, div(class="modern-card", 
                                 h5("Calibration Curve", style="font-weight:700;"),
                                 p("Evaluation of diagnostic concordance.", style="font-size:0.85em; color:#64748b;"),
                                 plotOutput(ns("plot_calib"))))
                 ),
                 fluidRow(
                   column(6, div(class="modern-card",
                                 h5("PR-AUC", style="font-weight:700;"),
                                 p("Evaluation of FP and TP.", style="font-size:0.85em; color:#64748b;"),
                                 plotOutput(ns("plot_pr")))),
                   column(6, div(class="modern-card", 
                                 h5("Decision Curve Analysis", style="font-weight:700;"),
                                 p("Evaluation of the clinical utility of the model.", style="font-size:0.85em; color:#64748b;"),
                                 plotOutput(ns("plot_dca"))))
                 ),
                 br(),
                 h4("Performances: Training Cohort (Repeated Nested-CV / OOB)", style="font-weight:700; color:#0f172a; margin-top: 20px; margin-left: 5px;"),
                 uiOutput(ns("metrics_ui")),
                 uiOutput(ns("nature_metrics_ui")),
                 uiOutput(ns("ext_metrics_title_ui")),
                 uiOutput(ns("ext_metrics_ui")),
                 uiOutput(ns("agreement_ui"))
        ),
        tabPanel("Model Coefficients", 
                 br(),
                 uiOutput(ns("top_markers_ui")),
                 hr(),
                 div(class="modern-card", DTOutput(ns("coef_table")))
        ),
        tabPanel("Clusters & Atypia",
                 br(),
                 uiOutput(ns("matutes_reclass_ui")),
                 fluidRow(
                   column(12, div(class="modern-card", style="border-top: 5px solid #4c1d95;",
                                  h5("UMAP Projection & HDBSCAN Clustering", style="font-weight:700; color:#a855f7; margin-bottom:10px;"),
                                  p("'Atypical' patients (Purple) are detected via Isolation Forest. Click on a point to view characteristics.", style="font-size:0.85em; color:#64748b;"),
                                  plotOutput(ns("plot_atypical"), click = ns("plot_atypical_click")),
                                  uiOutput(ns("cluster_click_info")),
                                  br(),
                                  hr(style="border-top: 1px dashed #cbd5e1; margin-top: 15px; margin-bottom: 15px;"),
                                  h5("Atypical Patients (Summary)", style="font-weight:700; color:#e11d48; margin-top:10px;"),
                                  p("Selected by Isolation Forest or by prediction-diagnosis gap > 50%.", style="font-size:0.85em; color:#64748b;"),
                                  DTOutput(ns("table_recap_atypiques")),
                                  br(),
                                  h5("Details of all Patients", style="font-weight:700; color:#a855f7; margin-top:20px;"),
                                  p("Click on a row to locate the patient on the charts above.", style="font-size:0.85em; color:#64748b; font-style:italic;"),
                                  DTOutput(ns("table_atypical"))
                   ))
                 ),
                 uiOutput(ns("heatmap_matutes_ui"))
        )
      )
    )
  )
}

mod_modeling_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    
    m_res <- reactiveValues()
    selected_patient <- reactiveVal(NULL) 
    
    observeEvent(input$file_csv, {
      req(input$file_csv)
      df_temp <- read_data_file(input$file_csv$datapath, input$file_csv$name)
      df_temp <- na.omit(df_temp)
      if(!"ID_Interne" %in% names(df_temp)) df_temp$ID_Interne <- paste0("Patient_", 1:nrow(df_temp))
      m_res$df_train <- df_temp
      show_premium_popup("Training Cohort Imported", "Training data successfully loaded.")
    })
    
    observeEvent(input$file_ext, {
      req(input$file_ext)
      show_premium_popup("Validation Cohort Imported", "External validation cohort successfully loaded.")
    })
    
    observeEvent(input$update_model, {
      req(m_res$df_train)
      set.seed(42)
      selected_patient(NULL) 
      
      use_weights <- TRUE
      do_simple_ratios <- TRUE
      do_all_ratios <- TRUE
      
      withProgress(message = 'TRIPOD-AI Modeling in progress...', value = 0, {
        
        incProgress(0.1, detail = "Cleaning data...")
        df <- m_res$df_train 
        target_col <- if("LLC_1" %in% names(df)) "LLC_1" else "LLC"
        
        df_numeric <- df[, sapply(df, is.numeric)]
        y <- as.numeric(df[[target_col]])
        
        matutes_cols <- grep("(?i)matutes", names(df_numeric), value = TRUE)
        x_raw_base <- as.matrix(df_numeric[, setdiff(names(df_numeric), c(target_col, matutes_cols))])
        
        m_res$marker_names <- colnames(x_raw_base)
        x_raw_base_expanded <- x_raw_base
        
        do_any_ratio <- do_all_ratios || do_simple_ratios
        
        if(do_any_ratio && ncol(x_raw_base) >= 2) {
          incProgress(0.2, detail = "Generating comprehensive combinatorial variables...")
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
            ratio_matrix[, idx] <- (A + eps) / (B + eps); ratio_names[idx] <- paste0(pairs[1, i], "_sur_", pairs[2, i]); idx <- idx + 1
            if(do_all_ratios) {
              ratio_matrix[, idx] <- A / (A + B + eps); ratio_names[idx] <- paste0(pairs[1, i], "_sursum_", pairs[2, i]); idx <- idx + 1
              ratio_matrix[, idx] <- log((A + eps) / (B + eps)); ratio_names[idx] <- paste0(pairs[1, i], "_logsur_", pairs[2, i]); idx <- idx + 1
              ratio_matrix[, idx] <- (A - B) / (A + B + eps); ratio_names[idx] <- paste0(pairs[1, i], "_diffsum_", pairs[2, i]); idx <- idx + 1
            }
          }
          colnames(ratio_matrix) <- ratio_names
          x_raw_all <- cbind(x_raw_base_expanded, ratio_matrix)
        } else {
          x_raw_all <- x_raw_base_expanded
        }
        
        incProgress(0.4, detail = paste0("Automated Caret Modeling (", input$cv_repeats, " Repeats)..."))
        
        y_factor <- factor(ifelse(y == 1, "CLL", "Other"), levels = c("Other", "CLL"))
        x_net_final <- x_raw_all
        
        w_full <- rep(1, length(y))
        if(use_weights) {
          w_full[y == 1] <- length(y) / (2 * sum(y == 1))
          w_full[y == 0] <- length(y) / (2 * sum(y == 0))
        }
        
        ctrl <- trainControl(method = "repeatedcv", number = 5, repeats = input$cv_repeats, savePredictions = "final", classProbs = TRUE, summaryFunction = twoClassSummary)
        tune_grid <- expand.grid(alpha = seq(0, 1, by = 0.05), lambda = 10^seq(-5, 1, length = 100))
        
        fit_caret <- suppressWarnings(train(x = x_net_final, y = y_factor, method = "glmnet", weights = w_full, trControl = ctrl, preProcess = c("center", "scale"), tuneGrid = tune_grid, metric = "ROC"))
        
        preds_oof <- fit_caret$pred
        preds_oof <- preds_oof[order(preds_oof$rowIndex), ]
        probs_cv <- preds_oof$CLL
        
        incProgress(0.6, detail = "Global model & OOB Calibration...")
        
        m_res$fit <- fit_caret$finalModel
        m_res$best_alpha <- fit_caret$bestTune$alpha
        m_res$best_lambda <- fit_caret$bestTune$lambda
        
        m_res$scale_center <- fit_caret$preProcess$mean
        m_res$scale_std <- fit_caret$preProcess$std
        m_res$scale_std[m_res$scale_std == 0] <- 1
        x_net_final_sc <- scale(x_net_final, center=m_res$scale_center, scale=m_res$scale_std)
        
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
          calib_intercept = coef(m_res$calib_model)[1], calib_slope = coef(m_res$calib_model)[2],
          ICI = mean(abs(probs_calib_finales - predict(suppressWarnings(loess(y ~ probs_calib_finales, degree=2)), probs_calib_finales)), na.rm=T),
          Emax = max(abs(probs_calib_finales - predict(suppressWarnings(loess(y ~ probs_calib_finales, degree=2)), probs_calib_finales)), na.rm=T)
        )
        
        pr_obj <- pr.curve(scores.class0 = probs_calib_finales, weights.class0 = y, curve=TRUE)
        m_res$pr_auc <- pr_obj$auc.integral
        
        m_res$coefs <- as.matrix(coef(m_res$fit, s = m_res$best_lambda))
        m_res$vars <- rownames(m_res$coefs)[m_res$coefs[,1] != 0][-1] 
        raw_v <- m_res$vars
        raw_v <- gsub("_sursum_", "_sur_", raw_v); raw_v <- gsub("_logsur_", "_sur_", raw_v); raw_v <- gsub("_diffsum_", "_sur_", raw_v)
        m_res$required_raw <- unique(unlist(strsplit(raw_v, "_sur_")))
        
        df_coef <- data.frame(Marker = rownames(m_res$coefs), Weight = round(m_res$coefs[,1], 4))
        df_coef$Marker <- sapply(df_coef$Marker, beautify_marker)
        m_res$df_coef_export <- subset(df_coef, Weight != 0)
        
        roc_list <- list("Training (OOB)" = m_res$roc_obj)
        df_pr_comb <- data.frame(Recall = pr_obj$curve[,1], Precision = pr_obj$curve[,2], Cohort = "Training (OOB)")
        df_calib_comb <- data.frame(p = probs_calib_finales, y = y, Cohort = "Training (OOB)")
        
        thresholds <- seq(0, 0.99, by=0.01)
        prev_int <- mean(y == 1)
        nb_model_int <- sapply(thresholds, function(pt) {
          sens <- sum(probs_calib_finales >= pt & y == 1) / max(1, sum(y == 1))
          spec <- sum(probs_calib_finales < pt & y == 0) / max(1, sum(y == 0))
          pt_ratio <- ifelse(pt == 1, 0, pt / (1 - pt))
          (sens * prev_int) - ((1 - spec) * (1 - prev_int)) * pt_ratio
        })
        nb_all_int <- sapply(thresholds, function(pt) { 
          pt_ratio <- ifelse(pt == 1, 0, pt / (1 - pt))
          prev_int - (1 - prev_int) * pt_ratio 
        })
        
        df_dca_comb <- data.frame(
          Threshold = rep(thresholds, 3), NB = c(nb_model_int, nb_all_int, rep(0, length(thresholds))),
          Type = rep(c("Model (Training)", "Treat all (Training)", "Treat none"), each=length(thresholds))
        )
        
        x_comb_sc <- x_net_final_sc
        y_comb <- y
        id_comb <- df$ID_Interne
        prob_comb <- probs_calib_finales
        cohorte_comb <- rep("Training", nrow(x_net_final_sc))
        
        if (!is.null(input$file_ext)) {
          df_ext <- read_data_file(input$file_ext$datapath, input$file_ext$name)
          df_ext <- na.omit(df_ext)
          if(target_col %in% names(df_ext)) {
            y_ext <- as.numeric(df_ext[[target_col]])
            
            x_ext_all_raw <- matrix(0, nrow = nrow(df_ext), ncol = length(m_res$scale_center))
            colnames(x_ext_all_raw) <- names(m_res$scale_center)
            
            for(v in colnames(x_ext_all_raw)) {
              if(grepl("_sursum_", v)) {
                parts <- strsplit(v, "_sursum_")[[1]]; if(all(parts %in% names(df_ext))) x_ext_all_raw[, v] <- df_ext[[parts[1]]] / (df_ext[[parts[1]]] + df_ext[[parts[2]]] + 1e-6)
              } else if(grepl("_logsur_", v)) {
                parts <- strsplit(v, "_logsur_")[[1]]; if(all(parts %in% names(df_ext))) x_ext_all_raw[, v] <- log((df_ext[[parts[1]]] + 1e-6) / (df_ext[[parts[2]]] + 1e-6))
              } else if(grepl("_diffsum_", v)) {
                parts <- strsplit(v, "_diffsum_")[[1]]; if(all(parts %in% names(df_ext))) x_ext_all_raw[, v] <- (df_ext[[parts[1]]] - df_ext[[parts[2]]]) / (df_ext[[parts[1]]] + df_ext[[parts[2]]] + 1e-6)
              } else if(grepl("_sur_", v)) {
                parts <- strsplit(v, "_sur_")[[1]]; if(all(parts %in% names(df_ext))) x_ext_all_raw[, v] <- (df_ext[[parts[1]]] + 1e-6) / (df_ext[[parts[2]]] + 1e-6)
              } else {
                if(v %in% names(df_ext)) x_ext_all_raw[, v] <- as.numeric(df_ext[[v]])
              }
            }
            
            x_ext_full_sc <- scale(x_ext_all_raw, center = m_res$scale_center, scale = m_res$scale_std)
            p_e_raw <- as.numeric(predict(m_res$fit, newx=x_ext_full_sc, s=m_res$best_lambda, type="response"))
            p_e_cal <- as.numeric(predict(m_res$calib_model, newdata=data.frame(logit_oof=log((p_e_raw+1e-2)/(1-p_e_raw+1e-2))), type="response"))
            
            roc_ext <- roc(y_ext, p_e_cal, quiet=TRUE)
            auc_ext_ci <- as.numeric(ci.auc(roc_ext))
            pr_obj_ext <- PRROC::pr.curve(scores.class0 = p_e_cal, weights.class0 = y_ext, curve=TRUE)
            
            tp_e <- sum(p_e_cal>=0.5 & y_ext==1); fn_e <- sum(p_e_cal<0.5 & y_ext==1)
            tn_e <- sum(p_e_cal<0.5 & y_ext==0); fp_e <- sum(p_e_cal>=0.5 & y_ext==0)
            
            sens_e_ci <- binom.test(tp_e, tp_e+fn_e)$conf.int
            spec_e_ci <- binom.test(tn_e, tn_e+fp_e)$conf.int
            
            m_res$ext_metrics <- list(
              auc_val = auc_ext_ci[2], auc_lower = auc_ext_ci[1], auc_upper = auc_ext_ci[3],
              pr_auc = pr_obj_ext$auc.integral, sens = tp_e/(tp_e+fn_e), sens_lower = sens_e_ci[1], sens_upper = sens_e_ci[2],
              spec = tn_e/(tn_e+fp_e), spec_lower = spec_e_ci[1], spec_upper = spec_e_ci[2], brier = mean((p_e_cal - y_ext)^2)
            )
            
            roc_list[["External Validation"]] <- roc_ext
            df_pr_comb <- rbind(df_pr_comb, data.frame(Recall = pr_obj_ext$curve[,1], Precision = pr_obj_ext$curve[,2], Cohort = "External Validation"))
            df_calib_comb <- rbind(df_calib_comb, data.frame(p = p_e_cal, y = y_ext, Cohort = "External Validation"))
            
            prev_ext <- mean(y_ext == 1)
            nb_model_ext <- sapply(thresholds, function(pt) {
              sens <- sum(p_e_cal >= pt & y_ext == 1) / max(1, sum(y_ext == 1))
              spec <- sum(p_e_cal < pt & y_ext == 0) / max(1, sum(y_ext == 0))
              pt_ratio <- ifelse(pt == 1, 0, pt / (1 - pt))
              (sens * prev_ext) - ((1 - spec) * (1 - prev_ext)) * pt_ratio
            })
            df_dca_comb <- rbind(df_dca_comb, data.frame(Threshold = rep(thresholds, 2), NB = c(nb_model_ext, sapply(thresholds, function(pt) { pt_ratio <- ifelse(pt == 1, 0, pt / (1 - pt)); prev_ext - (1 - prev_ext) * pt_ratio })), Type = rep(c("Model (External)", "Treat all (External)"), each=length(thresholds))))
            
            x_comb_sc <- rbind(x_comb_sc, x_ext_full_sc)
            y_comb <- c(y_comb, y_ext)
            id_ext <- if("ID_Interne" %in% names(df_ext)) df_ext$ID_Interne else paste0("Ext_", 1:nrow(x_ext_full_sc))
            id_comb <- c(id_comb, id_ext)
            prob_comb <- c(prob_comb, p_e_cal)
            cohorte_comb <- c(cohorte_comb, rep("External Validation", nrow(x_ext_full_sc)))
          }
        } else { m_res$ext_metrics <- NULL }
        
        m_res$plot_roc_ggplot <- ggroc(roc_list, linewidth = 1.2) + scale_color_manual(values = c("Training (OOB)" = "#10b981", "External Validation" = "#3b82f6")) + theme_minimal() + geom_abline(slope=1, intercept=1, linetype="dashed", color="#94a3b8") + labs(color = "Cohort")
        m_res$plot_pr_ggplot <- ggplot(df_pr_comb, aes(x=Recall, y=Precision, color=Cohort)) + geom_line(linewidth=1.2) + scale_color_manual(values = c("Training (OOB)" = "#10b981", "External Validation" = "#3b82f6")) + theme_minimal() + labs(x="Sensitivity (Recall)", y="PPV (Precision)", color = "Cohort")
        m_res$plot_calib_ggplot <- ggplot(df_calib_comb, aes(x = p, y = y, color = Cohort)) + geom_point(alpha = 0.2, size=1.5) + geom_smooth(method = "loess", se = FALSE, linewidth=1.2) + geom_abline(slope = 1, intercept = 0, linetype = "dashed", color="#94a3b8") + scale_color_manual(values = c("Training (OOB)" = "#10b981", "External Validation" = "#3b82f6")) + theme_minimal() + labs(x = "Predicted Probability", y = "Diagnosis")
        m_res$plot_dca_ggplot <- ggplot(df_dca_comb, aes(x=Threshold, y=NB, color=Type, linetype=Type, linewidth=Type)) + geom_line() + coord_cartesian(ylim=c(-0.05, max(nb_model_int, na.rm=T)+0.05)) + scale_color_manual(values=c("Model (Training)"="#10b981", "Treat all (Training)"="#a7f3d0", "Model (External)"="#3b82f6", "Treat all (External)"="#93c5fd", "Treat none"="#e2e8f0")) + scale_linetype_manual(values=c("Model (Training)"="solid", "Treat all (Training)"="dotted", "Model (External)"="solid", "Treat all (External)"="dotted", "Treat none"="solid")) + scale_linewidth_manual(values=c("Model (Training)"=1.5, "Treat all (Training)"=0.8, "Model (External)"=1.5, "Treat all (External)"=0.8, "Treat none"=0.8)) + theme_minimal() + labs(x="Probability Threshold", y="Net Benefit")
        
        probs_autre <- probs_calib_finales[y == 0]
        probs_llc <- probs_calib_finales[y == 1]
        seuil_bas <- quantile(probs_autre, 0.95, na.rm = TRUE)
        seuil_haut <- quantile(probs_llc, 0.05, na.rm = TRUE)
        if(seuil_bas >= seuil_haut) { seuil_bas <- 0.20; seuil_haut <- 0.80 }
        m_res$seuil_bas <- seuil_bas; m_res$seuil_haut <- seuil_haut
        
        set.seed(42)
        hdb_res <- dbscan::hdbscan(x_comb_sc, minPts = max(5, floor(nrow(x_comb_sc) * 0.05)))
        cluster_labels <- ifelse(hdb_res$cluster == 0, "Unclassified / Noise", paste("Cluster", hdb_res$cluster))
        
        umap_config <- umap.defaults; umap_config$random_state <- 42; umap_config$n_neighbors <- min(15, nrow(x_comb_sc) - 1)
        umap_res <- umap(x_comb_sc, config=umap_config)
        umap_coords <- umap_res$layout
        
        mat_comb <- rep(NA, length(y_comb))
        if("Matutes" %in% names(df)) mat_comb[1:length(y)] <- suppressWarnings(as.numeric(as.character(df$Matutes)))
        if (!is.null(input$file_ext) && exists("df_ext") && "Matutes" %in% names(df_ext)) mat_comb[(length(y)+1):length(y_comb)] <- suppressWarnings(as.numeric(as.character(df_ext$Matutes)))
        
        iso_model <- isolation.forest(x_net_final_sc, ntrees=500)
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
          RowIndex = 1:nrow(x_comb_sc), ID = id_comb, UMAP1 = umap_coords[,1], UMAP2 = umap_coords[,2], 
          Cluster = cluster_labels, Statut_Reel = as.factor(ifelse(y_comb == 1, "CLL", "Other")), Probabilite = prob_comb,
          Cohorte = factor(cohorte_comb, levels=c("Training", "External Validation")), Atypique = is_atypical, Matutes = mat_comb
        )
        m_res$df_plot_pca$Couleur_Groupe <- ifelse(!is.na(m_res$df_plot_pca$Matutes) & m_res$df_plot_pca$Matutes == 3, "Matutes 3 (Red)", ifelse(m_res$df_plot_pca$Atypique, "Atypical (Purple)", ifelse(m_res$df_plot_pca$Cohorte == "Training", "Training (Green)", "Validation (Blue)")))
        
        df_all_patients <- data.frame(
          Cohort = cohorte_comb, ID = id_comb, Diagnosis = ifelse(y_comb == 1, "CLL", "Other"),
          AI_Prob_Pct = paste0(round(prob_comb*100, 1), "%"), Diag_Gap = round(abs(prob_comb - y_comb), 3),
          Atypical_IF = ifelse(is_atypical, "Yes", "No"), Cluster = cluster_labels
        )
        m_res$df_all_export <- cbind(df_all_patients, as.data.frame(round(z_scores_intra, 2)))
        m_res$df_recap_export <- m_res$df_all_export[m_res$df_all_export$Atypical_IF == "Yes" | m_res$df_all_export$Diag_Gap > 0.5, ]
        
        if ("Matutes" %in% names(df)) {
          mat_raw <- df$Matutes; mat_clean <- suppressWarnings(as.numeric(as.character(mat_raw))); mat_clean[is.na(mat_clean)] <- 0
          grp <- dplyr::case_when(mat_clean <= 2 ~ "0, 1, 2 (Non-CLL)", mat_clean == 3 ~ "3 (Atypical)", mat_clean >= 4 ~ "4, 5 (CLL)", TRUE ~ "Unknown")
          
          df_reclass <- data.frame(
            Patient = 1:length(y), ID_Interne = df$ID_Interne, Matutes = mat_clean,
            Groupe = factor(grp, levels = c("0, 1, 2 (Non-CLL)", "3 (Atypical)", "4, 5 (CLL)")),
            Prob_AI = probs_calib_finales, Truth = factor(ifelse(y == 1, "CLL", "Other"), levels=c("CLL", "Other"))
          )
          
          df_reclass$Diag_Num <- ifelse(df_reclass$Truth == "CLL", 1, 0)
          df_reclass$Ecart_Pred <- abs(df_reclass$Prob_AI - df_reclass$Diag_Num)
          df_reclass$Atypique_Diag <- df_reclass$Ecart_Pred > 0.5
          df_reclass$X_jitter <- as.numeric(df_reclass$Groupe) + runif(nrow(df_reclass), -0.15, 0.15)
          m_res$df_reclass <- df_reclass
          
          mat3_idx <- which(df_reclass$Matutes == 3)
          if(length(mat3_idx) > 1) {
            x_mat3 <- x_net_final_sc[mat3_idx, , drop=FALSE]; mat3_annot <- data.frame(Diagnosis = ifelse(y[mat3_idx] == 1, "CLL", "Other")); rownames(mat3_annot) <- df$ID_Interne[mat3_idx]; rownames(x_mat3) <- df$ID_Interne[mat3_idx]
            m_res$plot_heatmap <- pheatmap::pheatmap(x_mat3, annotation_row = mat3_annot, color = colorRampPalette(c("#3b82f6", "white", "#ef4444"))(50), main = "", silent = TRUE)
            m_res$show_heatmap <- TRUE
          } else { m_res$show_heatmap <- FALSE }
          
          roc_matutes <- suppressWarnings(pROC::roc(y, mat_clean, direction = "<", quiet = TRUE))
          test_delong <- suppressWarnings(pROC::roc.test(m_res$roc_obj, roc_matutes, method = "delong"))
          pval_delong <- test_delong$p.value
          
          c_mat <- ifelse(mat_clean >= 4, 3, ifelse(mat_clean == 3, 2, 1)); c_per <- ifelse(probs_calib_finales > m_res$seuil_haut, 3, ifelse(probs_calib_finales < m_res$seuil_bas, 1, 2))
          up_llc <- sum(c_per > c_mat & y == 1) / max(1, sum(y == 1)); down_llc <- sum(c_per < c_mat & y == 1) / max(1, sum(y == 1)); nri_event <- up_llc - down_llc
          up_other <- sum(c_per > c_mat & y == 0) / max(1, sum(y == 0)); down_other <- sum(c_per < c_mat & y == 0) / max(1, sum(y == 0)); nri_nonevent <- down_other - up_other
          
          se_nri_e <- sqrt(max(0, up_llc + down_llc - (up_llc - down_llc)^2) / max(1, sum(y == 1))); se_nri_ne <- sqrt(max(0, up_other + down_other - (up_other - down_other)^2) / max(1, sum(y == 0))); se_nri <- sqrt(se_nri_e^2 + se_nri_ne^2)
          nri_total <- round((nri_event + nri_nonevent) * 100, 1); nri_lower <- round(((nri_event + nri_nonevent) - 1.96 * se_nri) * 100, 1); nri_upper <- round(((nri_event + nri_nonevent) + 1.96 * se_nri) * 100, 1)
          
          pval_str <- if(pval_delong < 0.05) paste0(format.pval(pval_delong, digits=3), " (Significant)") else paste0(format.pval(pval_delong, digits=3), " (Non-significant, ceiling effect on obvious cases)")
          m_res$matutes_stats_html <- paste0("<div style='background:#f5f3ff; border:1px solid #ddd6fe; padding:15px; border-radius:8px; margin-bottom:15px;'><h5 style='color:#7c3aed; font-weight:bold; margin-top:0;'>Statistical Superiority Analysis</h5><ul style='margin-bottom:0; color:#4c1d95; font-size:0.95em;'><li><b>Net Reclassification Improvement (NRI) : <span style='color:", ifelse(nri_total>0, "#10b981", "#ef4444"), "'>", ifelse(nri_total>0, "+", ""), nri_total, "%</span> <span style='font-size:0.85em;'>[95% CI : ", nri_lower, "% to ", nri_upper, "%]</span></b><br>Measures the net improvement in diagnostic classification compared to the initial Matutes score.</li><li style='margin-top:8px;'><b>DeLong Test (AUC Difference) : p-value = ", pval_str, "</b></li></ul></div>")
          
          t_html <- paste0("<table class='table table-hover reclass-table' style='background:white; font-size:0.9em; width:100%;'><thead><tr style='background:#f1f5f9;'><th style='width:20%; border-color:#e2e8f0;'>Matutes Score</th><th style='width:20%; border-color:#e2e8f0;'>True Diagnosis</th><th style='background:#fef2f2; width:20%; border-color:#e2e8f0;'>RED Zone (< ", round(m_res$seuil_bas*100, 1), "%)<br><small><i>CLL Exclusion</i></small></th><th style='background:#fffbeb; width:20%; border-color:#e2e8f0;'>YELLOW Zone (Uncertainty)<br></th><th style='background:#f0fdf4; width:20%; border-color:#e2e8f0;'>GREEN Zone (> ", round(m_res$seuil_haut*100, 1), "%)<br><small><i>CLL Diagnosis</i></small></th></tr></thead><tbody>")
          for (g in levels(df_reclass$Groupe)) {
            sub_df <- df_reclass[df_reclass$Groupe == g, ]; n_tot <- nrow(sub_df); if(n_tot == 0) next
            n_llc <- sum(sub_df$Truth == "CLL"); n_autre <- sum(sub_df$Truth == "Other"); diag_str <- paste0("<b>", n_llc, " CLL</b><br><b>", n_autre, " Others</b>")
            p_rouge <- round(sum(sub_df$Prob_AI < m_res$seuil_bas) / max(1, n_tot) * 100, 1); p_jaune <- round(sum(sub_df$Prob_AI >= m_res$seuil_bas & sub_df$Prob_AI <= m_res$seuil_haut) / max(1, n_tot) * 100, 1); p_vert <- round(sum(sub_df$Prob_AI > m_res$seuil_haut) / max(1, n_tot) * 100, 1)
            rouge_llc <- sum(sub_df$Prob_AI < m_res$seuil_bas & sub_df$Truth == "CLL"); rouge_autre <- sum(sub_df$Prob_AI < m_res$seuil_bas & sub_df$Truth == "Other"); jaune_llc <- sum(sub_df$Prob_AI >= m_res$seuil_bas & sub_df$Prob_AI <= m_res$seuil_haut & sub_df$Truth == "CLL"); jaune_autre <- sum(sub_df$Prob_AI >= m_res$seuil_bas & sub_df$Prob_AI <= m_res$seuil_haut & sub_df$Truth == "Other"); vert_llc <- sum(sub_df$Prob_AI > m_res$seuil_haut & sub_df$Truth == "CLL"); vert_autre <- sum(sub_df$Prob_AI > m_res$seuil_haut & sub_df$Truth == "Other")
            str_rouge <- paste0("<span style='font-size:1.2em; font-weight:bold;'>", p_rouge, "%</span><br><small>(", rouge_llc, " CLL, ", rouge_autre, " Other)</small>"); str_jaune <- paste0("<span style='font-size:1.2em; font-weight:bold;'>", p_jaune, "%</span><br><small>(", jaune_llc, " CLL, ", jaune_autre, " Other)</small>"); str_vert <- paste0("<span style='font-size:1.2em; font-weight:bold;'>", p_vert, "%</span><br><small>(", vert_llc, " CLL, ", vert_autre, " Other)</small>")
            t_html <- paste0(t_html, "<tr><td style='border-color:#e2e8f0;'><b>", g, "</b><br>N=", n_tot, "</td><td style='border-color:#e2e8f0;'>", diag_str, "</td><td style='background:#fef2f2; border-color:#e2e8f0;'>", str_rouge, "</td><td style='background:#fffbeb; border-color:#e2e8f0;'>", str_jaune, "</td><td style='background:#f0fdf4; border-color:#e2e8f0;'>", str_vert, "</td></tr>")
          }
          m_res$table_matutes_html <- paste0(t_html, "</tbody></table>")
        } else { m_res$table_matutes_html <- NULL }
        
        show_premium_popup("Modeling Complete", "Calculations performed successfully.")
      })
    })
    
    # Intéractions & Visualisations UI dynamiques (Outputs)
    observeEvent(input$plot_atypical_click, {
      clicked_pt <- nearPoints(m_res$df_plot_pca, input$plot_atypical_click, xvar = "UMAP1", yvar = "UMAP2", maxpoints = 1, threshold = 20)
      if (nrow(clicked_pt) > 0) selected_patient(clicked_pt$ID[1]) else selected_patient(NULL)
    })
    observeEvent(input$plot_matutes_click, {
      clicked_pt <- nearPoints(m_res$df_reclass, input$plot_matutes_click, xvar = "X_jitter", yvar = "Prob_AI", maxpoints = 1, threshold = 15)
      if (nrow(clicked_pt) > 0) selected_patient(clicked_pt$ID_Interne[1]) else selected_patient(NULL)
    })
    observeEvent(input$table_recap_atypiques_rows_selected, {
      idx <- input$table_recap_atypiques_rows_selected; if(length(idx) > 0) { id <- m_res$df_recap_export$ID[idx]; if(!identical(selected_patient(), id)) selected_patient(id) }
    }, ignoreNULL = FALSE, ignoreInit = TRUE)
    observeEvent(input$table_atypical_rows_selected, {
      idx <- input$table_atypical_rows_selected; if(length(idx) > 0) { id <- m_res$df_all_export$ID[idx]; if(!identical(selected_patient(), id)) selected_patient(id) }
    }, ignoreNULL = FALSE, ignoreInit = TRUE)
    observeEvent(selected_patient(), {
      id <- selected_patient(); proxy_recap <- dataTableProxy("table_recap_atypiques"); proxy_all <- dataTableProxy("table_atypical")
      if (is.null(id)) { selectRows(proxy_recap, NULL); selectRows(proxy_all, NULL) } else {
        if (!is.null(m_res$df_recap_export)) { idx_r <- which(m_res$df_recap_export$ID == id); if(length(idx_r) > 0) selectRows(proxy_recap, idx_r) else selectRows(proxy_recap, NULL) }
        if (!is.null(m_res$df_all_export)) { idx_a <- which(m_res$df_all_export$ID == id); if(length(idx_a) > 0) selectRows(proxy_all, idx_a) else selectRows(proxy_all, NULL) }
      }
    }, ignoreNULL = FALSE)
    
    output$patient_count_ui <- renderUI({ req(m_res$df_train); df <- m_res$df_train; target_col <- if("LLC_1" %in% names(df)) "LLC_1" else "LLC"; y <- as.numeric(df[[target_col]]); n_pat <- nrow(df); n_events <- min(sum(y == 1, na.rm=TRUE), sum(y == 0, na.rm=TRUE)); df_numeric <- df[, sapply(df, is.numeric)]; matutes_cols <- grep("(?i)matutes", names(df_numeric), value = TRUE); n_base_markers <- length(setdiff(names(df_numeric), c(target_col, matutes_cols))); div(class = "modern-card train-panel", h5("Training Cohort Properties", style="font-weight:700; color:#10b981; margin-bottom:15px;"), fluidRow(column(4, div(class='sub-metric', "Total Patients"), div(class='big-metric', n_pat)), column(4, div(class='sub-metric', "Min. Class Events"), div(class='big-metric', n_events)), column(4, div(class='sub-metric', "Base Markers"), div(class='big-metric', n_base_markers)))) })
    output$metrics_ui <- renderUI({ req(m_res$metrics); div(class = "modern-card train-panel", fluidRow(column(4, div(class='sub-metric', "AUC (Nested CV)"), div(class='big-metric', HTML(paste0(round(m_res$metrics$auc_val, 3), " <br><span style='font-size:0.45em; color:#64748b;'>[95% CI: ", round(m_res$metrics$auc_lower,2), "-", round(m_res$metrics$auc_upper,2), "]</span>")))), column(4, div(class='sub-metric', "Sensitivity / Specificity"), div(class='big-metric', HTML(paste0(round(m_res$metrics$sens*100,1), "% / ", round(m_res$metrics$spec*100,1), "% <br><span style='font-size:0.45em; color:#64748b;'>[95% CI: Sens ", round(m_res$metrics$sens_lower*100,1), "-", round(m_res$metrics$sens_upper*100,1), "% | Spec ", round(m_res$metrics$spec_lower*100,1), "-", round(m_res$metrics$spec_upper*100,1), "%]</span>")))), column(4, div(class='sub-metric', "Brier Score"), div(class='big-metric', round(m_res$metrics$brier, 3))))) })
    output$nature_metrics_ui <- renderUI({ req(m_res$metrics, m_res$pr_auc); div(class = "modern-card nature-panel", h5("ADVANCED OOB METRICS", style="font-weight:700; color:#8b5cf6; margin-bottom:15px;"), fluidRow(column(4, div(class='sub-metric', "PR-AUC", span(class='ideal-val', " (ideal ~1)")), div(class='big-metric', round(m_res$pr_auc, 3), style="font-size:1.6rem;")), column(4, div(class='sub-metric', "Calib Int | Slope", span(class='ideal-val', " (0 | 1)")), div(class='big-metric', paste0(round(m_res$metrics$calib_intercept, 2), " | ", round(m_res$metrics$calib_slope, 2)), style="font-size:1.6rem;")), column(4, div(class='sub-metric', "Emax | ICI", span(class='ideal-val', " (<0.05)")), div(class='big-metric', paste0(round(m_res$metrics$Emax, 3), " | ", round(m_res$metrics$ICI, 3)), style="font-size:1.6rem;")))) })
    output$ext_metrics_title_ui <- renderUI({ req(m_res$ext_metrics); h4("Performances : External Validation Cohort", style="font-weight:700; color:#0f172a; margin-top: 30px; margin-left: 5px;") })
    output$ext_metrics_ui <- renderUI({ req(m_res$ext_metrics); div(class = "modern-card ext-panel", fluidRow(column(3, div(class='sub-metric', "AUC"), div(class='big-metric', HTML(paste0(round(m_res$ext_metrics$auc_val, 3), " <br><span style='font-size:0.45em; color:#64748b;'>[95% CI: ", round(m_res$ext_metrics$auc_lower,2), "-", round(m_res$ext_metrics$auc_upper,2), "]</span>")))), column(3, div(class='sub-metric', "PR-AUC"), div(class='big-metric', round(m_res$ext_metrics$pr_auc, 3))), column(3, div(class='sub-metric', "Sens / Spec"), div(class='big-metric', HTML(paste0(round(m_res$ext_metrics$sens*100,1), "% / ", round(m_res$ext_metrics$spec*100,1), "% <br><span style='font-size:0.45em; color:#64748b;'>[CI Sens: ", round(m_res$ext_metrics$sens_lower*100,1), "-", round(m_res$ext_metrics$sens_upper*100,1), "% | Spec: ", round(m_res$ext_metrics$spec_lower*100,1), "-", round(m_res$ext_metrics$spec_upper*100,1), "%]</span>")))), column(3, div(class='sub-metric', "Brier Score"), div(class='big-metric', round(m_res$ext_metrics$brier, 3))))) })
    output$agreement_ui <- renderUI({ req(m_res$ext_metrics, m_res$roc_obj); diff_auc <- m_res$ext_metrics$auc_val - as.numeric(pROC::auc(m_res$roc_obj)); is_normal_gap <- (diff_auc >= -0.02 && diff_auc <= 0.12); div(class = "modern-card", style = if(is_normal_gap) "border-left: 5px solid #10b981; background-color: #f0fdf4;" else "border-left: 5px solid #f59e0b; background-color: #fffbeb;", h5("COHORT COMPARISON", style="font-weight:700;"), p(paste0("AUC Gap: ", round(diff_auc, 3))), if(is_normal_gap) p("✅ NORMAL GAP : The difference aligns with standard statistical optimism.", style="color:#166534; font-size:0.9em;") else p("⚠️ ATYPICAL GAP : The drift exceeds expected thresholds.", style="color:#92400e; font-size:0.9em;")) })
    output$plot_roc <- renderPlot({ req(m_res$plot_roc_ggplot); m_res$plot_roc_ggplot })
    output$plot_calib <- renderPlot({ req(m_res$plot_calib_ggplot); m_res$plot_calib_ggplot })
    output$plot_pr <- renderPlot({ req(m_res$plot_pr_ggplot); m_res$plot_pr_ggplot })
    output$plot_dca <- renderPlot({ req(m_res$plot_dca_ggplot); m_res$plot_dca_ggplot })
    output$coef_table <- renderDT({ datatable(m_res$df_coef_export, rownames = FALSE) })
    output$top_markers_ui <- renderUI({ req(m_res$df_coef_export); df <- subset(m_res$df_coef_export, Marker != "(Intercept)"); df_llc <- subset(df, Weight > 0); df_non_llc <- subset(df, Weight < 0); top_l <- head(df_llc[order(df_llc$Weight, decreasing = T), ], 5); top_n <- head(df_non_llc[order(df_non_llc$Weight, decreasing = F), ], 5); format_list <- function(d) { if(nrow(d)==0) return("<i>None</i>"); paste(sapply(1:nrow(d), function(i) paste0("<div style='background:#ffffff; border:1px solid #e2e8f0; border-radius:6px; padding:8px 12px; margin-bottom:6px; display:flex; justify-content:space-between; align-items:center;'><span style='font-family:monospace; font-weight:600; color:#334155; font-size:1.05em;'>", d$Marker[i], "</span><span style='background:white; border:1px solid ", ifelse(d$Weight[i]>0, "#10b981", "#ef4444") ,"; border-radius:4px; padding:2px 6px; font-size:0.85em; font-weight:700; color:", ifelse(d$Weight[i]>0, "#10b981", "#ef4444") ,"'>Weight: ", d$Weight[i], "</span></div>")), collapse="") }; fluidRow(column(6, div(class="modern-card", style="border-top:4px solid #10b981; background-color: #f0fdf4;", h4("Variables (Positive Impact)", style="margin-bottom:15px; font-weight:700;"), HTML(format_list(top_l)))), column(6, div(class="modern-card", style="border-top:4px solid #ef4444; background-color: #fef2f2;", h4("Variables (Negative Impact)", style="margin-bottom:15px; font-weight:700;"), HTML(format_list(top_n))))) })
    
    output$plot_atypical <- renderPlot({ req(m_res$df_plot_pca); p <- ggplot(m_res$df_plot_pca, aes(x = UMAP1, y = UMAP2)) + stat_ellipse(aes(group = Cluster, fill = Cluster), geom = "polygon", alpha = 0.15, color = NA, level = 0.8) + geom_point(aes(color = Couleur_Groupe, shape = Statut_Reel), size = 3.5, alpha = 0.85) + scale_color_manual(values = c("Training (Green)" = "#10b981", "Validation (Blue)" = "#3b82f6", "Atypical (Purple)" = "#9333ea", "Matutes 3 (Red)" = "#ef4444")) + scale_shape_manual(values = c("CLL" = 16, "Other" = 17)) + theme_minimal() + labs(x = "UMAP 1", y = "UMAP 2", title = "UMAP Projection & HDBSCAN Clustering", color = "Legend", shape = "True Diagnosis", fill = "Detected Clusters"); if(!is.null(selected_patient())) { highlight_data <- m_res$df_plot_pca[m_res$df_plot_pca$ID == selected_patient(), ]; if(nrow(highlight_data) > 0) { p <- p + geom_point(data = highlight_data, aes(x = UMAP1, y = UMAP2), color = "black", fill = "yellow", size = 6, shape = 21, stroke = 2) + geom_point(data = highlight_data, aes(x = UMAP1, y = UMAP2), color = "red", size = 10, shape = 1, stroke = 1.5) } }; return(p) })
    output$cluster_click_info <- renderUI({ req(selected_patient(), m_res$df_plot_pca, m_res$z_scores_intra); id <- selected_patient(); idx_row <- which(m_res$df_plot_pca$ID == id); if (length(idx_row) == 0) return(NULL); clicked_pt <- m_res$df_plot_pca[idx_row[1], ]; html_str <- paste0("<div style='background:#faf5ff; border-left:5px solid #4c1d95; padding:15px; border-radius:8px; margin-top:15px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);'><h5 style='color:#a855f7; font-weight:bold; margin-top:0;'> Selected Patient : ", clicked_pt$ID, "</h5><p style='color:#334155; font-size:0.95em;'><b>True Diagnosis:</b> ", as.character(clicked_pt$Statut_Reel), " | <b>Matutes Score:</b> ", ifelse(is.na(clicked_pt$Matutes), "ND", clicked_pt$Matutes), " | <b>AI Probability:</b> ", round(clicked_pt$Probabilite*100, 1), "% | <b>Isolation Forest Result:</b> ", ifelse(clicked_pt$Atypique, "Atypical", "Normal"), "</p><p style='margin-bottom:5px; color:#4c1d95; font-weight:bold;'>UMAP Profile (Z-scores) intra-group:</p><ul style='color:#334155; margin-bottom:0;'>"); z_scores_pat_intra <- m_res$z_scores_intra[clicked_pt$RowIndex, ]; top_vars_pat <- sort(abs(z_scores_pat_intra), decreasing = TRUE)[1:min(5, length(z_scores_pat_intra))]; for(v in names(top_vars_pat)) { html_str <- paste0(html_str, "<li><b>", beautify_marker(v), "</b> : ", ifelse(z_scores_pat_intra[v] > 0, "+", ""), round(z_scores_pat_intra[v], 2), " <i>standard deviations from the mean of their diagnostic group</i></li>") }; HTML(paste0(html_str, "</ul></div>")) })
    output$table_recap_atypiques <- renderDT({ req(m_res$df_recap_export); datatable(m_res$df_recap_export, selection = 'single', options = list(scrollX = TRUE, pageLength = 5), rownames = FALSE) })
    output$table_atypical <- renderDT({ req(m_res$df_all_export); datatable(m_res$df_all_export, selection = 'single', options = list(scrollX = TRUE, pageLength = 5), rownames = FALSE) })
    output$matutes_click_info <- renderUI({ req(selected_patient(), m_res$df_reclass, m_res$z_scores_intra); id <- selected_patient(); idx_row <- which(m_res$df_reclass$ID_Interne == id); if (length(idx_row) == 0) return(NULL); clicked_pt <- m_res$df_reclass[idx_row[1], ]; html_str <- paste0("<div style='background:#faf5ff; border-left:5px solid #4c1d95; padding:15px; border-radius:8px; margin-top:15px; box-shadow: 0 4px 6px rgba(0,0,0,0.05);'><h5 style='color:#a855f7; font-weight:bold; margin-top:0;'> Selected Patient : ", clicked_pt$ID_Interne, "</h5><p style='color:#475569; font-size:0.95em;'><b>True Diagnosis:</b> ", clicked_pt$Truth, " | <b>Matutes Score:</b> ", clicked_pt$Matutes, " | <b>AI Probability:</b> ", round(clicked_pt$Prob_AI*100,1), "% | <b>Diagnostic Gap:</b> ", round(clicked_pt$Ecart_Pred, 3), "</p><p style='margin-bottom:5px; color:#4c1d95; font-weight:bold;'>Most influential variables for this patient:</p><ul style='color:#475569;'>"); z_scores <- m_res$z_scores_intra[clicked_pt$Patient, ]; extreme_vars <- sort(abs(z_scores), decreasing = TRUE)[1:min(4, length(z_scores))]; for(v in names(extreme_vars)) { html_str <- paste0(html_str, "<li><b>", beautify_marker(v), "</b> : ", ifelse(z_scores[v] > 0, "+", ""), round(z_scores[v], 2), " <i>standard deviations from the mean of their diagnostic group</i></li>") }; HTML(paste0(html_str, "</ul></div>")) })
    output$matutes_reclass_ui <- renderUI({ req(m_res$table_matutes_html); div(class="modern-card", style="border-top: 5px solid #4c1d95;", h4("Diagnostic Classification (PERCYMAT vs Matutes)", style="font-weight:700; color:#a855f7; margin-bottom:10px;"), p("Patients designated as 'atypical' (Red borders) are detected by calculating the gap between computed probability and final diagnosis. Uncertainty zone thresholds are adaptively set based on the training cohort Out-Of-Bag results. Click on a point to view characteristics.", style="font-size:0.85em; color:#64748b;"), HTML(m_res$matutes_stats_html), fluidRow(column(12, plotOutput(ns("plot_matutes_jitter"), click = ns("plot_matutes_click")), uiOutput(ns("matutes_click_info")))), br(), h5("Distribution of Patients by Confidence Zones", style="font-weight:700; color:#a855f7; margin-top:20px;"), HTML(m_res$table_matutes_html)) })
    output$plot_matutes_jitter <- renderPlot({ req(m_res$df_reclass, m_res$seuil_bas, m_res$seuil_haut); p <- ggplot(m_res$df_reclass, aes(x = X_jitter, y = Prob_AI, shape = Truth, fill = Truth)) + annotate("rect", ymin = 0, ymax = m_res$seuil_bas, xmin = -Inf, xmax = Inf, fill = "#fef2f2", alpha = 0.9) + annotate("rect", ymin = m_res$seuil_bas, ymax = m_res$seuil_haut, xmin = -Inf, xmax = Inf, fill = "#fffbeb", alpha = 0.7) + annotate("rect", ymin = m_res$seuil_haut, ymax = 1.00, xmin = -Inf, xmax = Inf, fill = "#f0fdf4", alpha = 0.9) + geom_hline(yintercept = m_res$seuil_bas, linetype = "dashed", color = "#ef4444", linewidth=0.8) + geom_hline(yintercept = m_res$seuil_haut, linetype = "dashed", color = "#10b981", linewidth=0.8) + geom_point(aes(stroke = ifelse(Atypique_Diag, 1.5, 0.6), color = ifelse(Atypique_Diag, "#ef4444", "black")), size = 3.5, alpha = 0.85) + scale_shape_manual(values = c("CLL" = 21, "Other" = 24)) + scale_fill_manual(values = c("CLL" = "#1e293b", "Other" = "#cbd5e1")) + scale_color_identity() + scale_x_continuous(breaks = 1:3, labels = levels(m_res$df_reclass$Groupe)) + scale_y_continuous(labels = scales::percent_format(accuracy=1), limits = c(0, 1)) + theme_minimal(base_size=14) + labs(x = "Human Matutes Score", y = "Computed Probability", fill="True Diagnosis", shape="True Diagnosis", title="Patient Dispersion") + theme(legend.position="bottom", plot.title=element_text(face="bold", color="#0f172a"), panel.grid.major.x = element_blank(), panel.grid.minor.x = element_blank()); if(!is.null(selected_patient())) { highlight_data <- m_res$df_reclass[m_res$df_reclass$ID_Interne == selected_patient(), ]; if(nrow(highlight_data) > 0) { p <- p + geom_point(data = highlight_data, aes(x = X_jitter, y = Prob_AI), color = "black", fill = "yellow", size = 6, shape = 21, stroke = 2) + geom_point(data = highlight_data, aes(x = X_jitter, y = Prob_AI), color = "red", size = 10, shape = 1, stroke = 1.5) } }; return(p) })
    output$heatmap_matutes_ui <- renderUI({ req(m_res$show_heatmap); div(class="modern-card", style="border-top: 5px solid #4c1d95;", h5("Heatmap", style="font-weight:700; color:#a855f7;"), p("Unsupervised hierarchical clustering of Matutes 3 patients.", style="font-size:0.85em; color:#64748b;"), plotOutput(ns("plot_heatmap"), height = "500px")) })
    output$plot_heatmap <- renderPlot({ req(m_res$plot_heatmap); grid::grid.draw(m_res$plot_heatmap$gtable) })
    
    # On retourne m_res pour que le module de diagnostic puisse l'utiliser
    return(m_res)
  })
}

# ==============================================================================
# 3. FICHIER : R/mod_diagnosis.R
# Module dédié à la prédiction d'un nouveau patient
# ==============================================================================

mod_diagnosis_ui <- function(id) {
  ns <- NS(id)
  sidebarLayout(
    sidebarPanel(
      h4("Biomarker Input (MFI)", style="font-weight: 700; color: #0f172a;"),
      hr(),
      uiOutput(ns("dynamic_inputs")),
      hr(),
      actionButton(ns("predict"), " CALCULATE CLL PROBABILITY", 
                   class = "btn-success btn-lg btn-block", 
                   style = "font-weight: 700; border-radius: 10px;",
                   icon = icon("stethoscope")),
      br(),
      uiOutput(ns("download_btn_ui"))
    ),
    mainPanel(
      uiOutput(ns("result_box")),
      br(),
      uiOutput(ns("patient_explain_ui"))
    )
  )
}

mod_diagnosis_server <- function(id, m_res) {
  moduleServer(id, function(input, output, session) {
    ns <- session$ns
    diag_res <- reactiveValues()
    
    output$dynamic_inputs <- renderUI({ 
      # CORRECTION : m_res$ au lieu de m_res()$
      req(m_res$marker_names)
      tagList(lapply(m_res$marker_names, function(v) numericInput(ns(paste0("in_", v)), label = v, value = NA))) 
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
          parts <- strsplit(v, "_sursum_")[[1]]; v1 <- ifelse(is.na(input[[paste0("in_", parts[1])]]), 0, input[[paste0("in_", parts[1])]]); v2 <- ifelse(is.na(input[[paste0("in_", parts[2])]]), 0, input[[paste0("in_", parts[2])]]); p_f_raw[1, v] <- v1 / (v1 + v2 + 1e-6)
        } else if(grepl("_logsur_", v)) {
          parts <- strsplit(v, "_logsur_")[[1]]; v1 <- ifelse(is.na(input[[paste0("in_", parts[1])]]), 0, input[[paste0("in_", parts[1])]]); v2 <- ifelse(is.na(input[[paste0("in_", parts[2])]]), 0, input[[paste0("in_", parts[2])]]); p_f_raw[1, v] <- log((v1 + 1e-6) / (v2 + 1e-6))
        } else if(grepl("_diffsum_", v)) {
          parts <- strsplit(v, "_diffsum_")[[1]]; v1 <- ifelse(is.na(input[[paste0("in_", parts[1])]]), 0, input[[paste0("in_", parts[1])]]); v2 <- ifelse(is.na(input[[paste0("in_", parts[2])]]), 0, input[[paste0("in_", parts[2])]]); p_f_raw[1, v] <- (v1 - v2) / (v1 + v2 + 1e-6)
        } else if(grepl("_sur_", v)) {
          parts <- strsplit(v, "_sur_")[[1]]; v1 <- ifelse(is.na(input[[paste0("in_", parts[1])]]), 0, input[[paste0("in_", parts[1])]]); v2 <- ifelse(is.na(input[[paste0("in_", parts[2])]]), 0, input[[paste0("in_", parts[2])]]); p_f_raw[1, v] <- (v1 + 1e-6) / (v2 + 1e-6)
        }
      }
      
      p_f_sc <- (p_f_raw - m_res$scale_center) / m_res$scale_std
      diag_res$p_f_sc <- p_f_sc
      
      pr <- as.numeric(predict(m_res$fit, newx=p_f_sc, s=m_res$best_lambda, type="response"))
      diag_res$prob_calib <- as.numeric(predict(m_res$calib_model, newdata = data.frame(logit_oof = log((pr+1e-2)/(1-pr+1e-2))), type = "response"))
      
      output$result_box <- renderUI({
        res_c <- if(diag_res$prob_calib < m_res$seuil_bas) "#ef4444" else if(diag_res$prob_calib >= m_res$seuil_haut) "#10b981" else "#f59e0b"
        q_val <- m_res$q_conformal; prob_val <- diag_res$prob_calib; set_pred <- c()
        if (prob_val >= 1 - q_val) set_pred <- c(set_pred, "CLL")
        if ((1 - prob_val) >= 1 - q_val) set_pred <- c(set_pred, "Other")
        conformal_text <- paste0(set_pred, collapse = " OR ")
        
        div(class="modern-card", style=paste0("background:", res_c, "; color:white; text-align:center; padding: 40px;"), 
            h4("CLL Probability"), h1(paste0(round(prob_val*100, 1), "%"), style="font-size: 5em; font-weight: 800; margin:0;"),
            hr(style="border-top: 1px dashed rgba(255,255,255,0.5);"), h5("Conformal Prediction (95% Guarantee) :"), h4(paste0("{ ", conformal_text, " }"), style="font-weight:700;")
        )
      })
      
      output$patient_explain_ui <- renderUI({
        div(class="modern-card",
            h4(icon("brain"), "Explanation", style="font-weight:700; color:#0f172a; margin-bottom:15px;"),
            p("This graph breaks down the mathematical impact (Model Weight × Patient Z-score) of each variable for this patient.", style="font-size:0.9em; color:#64748b;"),
            plotOutput(ns("plot_shap"), height="350px")
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
          Contribution = sapply(valid_vars, function(v) { if (v %in% names(patient_z_scores)) { return(patient_z_scores[v] * coefs[v, 1]) } else { return(0) } })
        )
        contributions <- contributions[contributions$Contribution != 0, ]
        
        if(nrow(contributions) > 0) {
          contributions$Feature_Joli <- sapply(contributions$Feature, beautify_marker)
          top_indices <- order(abs(contributions$Contribution), decreasing = TRUE)[1:min(12, nrow(contributions))]
          contributions <- contributions[top_indices, ]
          
          ordered_levels <- unique(contributions$Feature_Joli[order(contributions$Contribution)])
          contributions$Feature_Joli <- factor(contributions$Feature_Joli, levels = ordered_levels)
          
          contributions$Sign <- ifelse(contributions$Contribution > 0, "Points to CLL (+)", "Points to Other (-)")
          
          ggplot(contributions, aes(x = Feature_Joli, y = Contribution, fill = Sign)) +
            geom_bar(stat = "identity", alpha = 0.9, width = 0.65, color = "white", linewidth = 0.5) +
            geom_text(aes(label = sprintf("%+0.2f", Contribution), hjust = ifelse(Contribution > 0, -0.2, 1.2)), size = 4, fontface = "bold", color = "#1e293b") +
            coord_flip() + theme_minimal(base_size = 14) + scale_fill_manual(values = c("Points to CLL (+)" = "#ef4444", "Points to Other (-)" = "#3b82f6")) +
            scale_y_continuous(expand = expansion(mult = c(0.25, 0.25))) + geom_hline(yintercept = 0, linetype = "solid", color = "#1e293b", linewidth = 1) +
            labs(x = "", y = "Log-Odds Contribution (Model Weight × Patient Z-score)", fill = "Predictive Impact :") +
            theme(legend.position = "top", legend.title = element_text(face="bold"), panel.grid.major.y = element_blank(), axis.text.y = element_text(fontface = "bold", size = 11))
        } else {
          ggplot() + annotate("text", x=0, y=0, label="No significant contribution", color="#64748b") + theme_void()
        }
      })
    })
  })
}

# ==============================================================================
# 4. FICHIER : R/mod_methodology.R
# Module dédié à la documentation (UI uniquement)
# ==============================================================================

mod_methodology_ui <- function(id) {
  ns <- NS(id)
  withMathJax(
    fluidPage(
      div(class="modern-card", style="border-top: 5px solid #1e293b;",
          h3(icon("shield-alt"), " Algorithmic Architecture (TRIPOD-AI Compliant)", style="font-weight:700; color:#0f172a; margin-bottom: 20px;"),
          p("This computational pipeline is specifically engineered to reduce optimism bias (overfitting) and minimize data leakage in small clinical cohorts. The architecture rigorously segregates feature engineering, selection, and optimization within a Repeated Nested Cross-Validation framework.", style="font-size: 1.1em; color:#475569;"),
          
          div(style="text-align:center; padding: 25px; background: #f8fafc; border-radius: 12px; margin: 30px 0; border: 1px solid #e2e8f0;",
              div(class="flow-box", style="background:#3b82f6;", "1. Data Input"),
              div(class="flow-arrow", "↓"),
              div(class="flow-box", style="background:#8b5cf6;", "2. Repeated Nested Cross-Validation"),
              div(class="flow-arrow", "↓"),
              div(class="flow-inner", HTML("<b>Inner Loop (Training Folds Only):</b><br>Ratio Combinatorics → Dynamic In-Fold Z-Score Scaling → Alpha (0 to 1) & Lambda Grid Search")),
              div(class="flow-arrow", "↓"),
              div(class="flow-box", style="background:#10b981;", "3. Global Weight Calculation"),
              div(class="flow-arrow", "↓"),
              div(class="flow-box", style="background:#f59e0b;", "4. Out-Of-Bag Bayesian Platt Scaling & Performance Graphics"),
              div(class="flow-arrow", "↓"),
              div(class="flow-box", style="background:#ef4444;", "5. Local Log-Odds Bounds, HDBSCAN & Isolation Forest")
          ),
          hr(),
          h4("1. Repeated Nested-CV & Elastic-Net Model", style="font-weight:600; color:#2563eb;"),
          p("The algorithm utilizes a 5-fold Nested Cross-Validation repeated multiple times. An extensive feature-engineering procedure generates biologically relevant candidate variables. The selected variables subsequently enter into an Elastic-Net model, which combines L1 and L2 regularization to identify the most predictive markers:"),
          p("$$ Penalty = \\lambda \\cdot \\left[ \\alpha ||\\beta||_1 + \\frac{1 - \\alpha}{2} ||\\beta||_2^2 \\right] $$"),
          br(),
          h4("2. Z-score standardization", style="font-weight:600; color:#2563eb;"),
          p("The analytical pipeline transforms each patient's raw cytometric measurements into a standardized Z-score to align the magnitudes of distinct markers:"),
          p("$$ Z = \\frac{X - \\mu}{\\sigma} $$"),
          br(),
          h4("3. Out-Of-Bag Bayesian Calibration & Performance", style="font-weight:600; color:#2563eb;"),
          p("Every patient is assigned an averaged Out-Of-Bag (OOB) probability, which represents the model's prediction for that patient when they were excluded from the training fold. These strictly cross-validated probabilities are used to generate all performance graphics (ROC, PR, DCA) to avoid optimism, and are subsequently smoothed via Bayesian logistic regression (Platt Scaling) to calibrate future predictions:"),
          p("$$ P(Y=1 | X) = \\frac{1}{1 + e^{-(A \\cdot \\text{logit}(P_{OOB}) + B)}} $$"),
          br(),
          h4("4. Independent External Validation", style="font-weight:600; color:#2563eb;"),
          p("External validation applies these exact frozen parameters as a rigid mathematical projector, demonstrating trans-institutional comparability."),
          hr(),
          h3(icon("microchip"), " Version 2.4 Upgrades: Advanced XAI & Topography", style="font-weight:700; color:#0f172a; margin-top:30px; margin-bottom: 20px;"),
          h4("5. HDBSCAN Density-Based Clustering", style="font-weight:600; color:#8b5cf6;"),
          p("Hierarchical Density-Based Spatial Clustering of Applications with Noise (HDBSCAN) calculates clusters on the high-dimensional scaled data based on mutual reachability distance:"),
          p("$$ d_{mreach}(a,b) = \\max\\{core_k(a), core_k(b), d(a,b)\\} $$"),
          br(),
          h4("6. Isolation Forest", style="font-weight:600; color:#8b5cf6;"),
          p("Atypical patients are identified using an Isolation Forest. It calculates an anomaly score based on the path length h(x) required to isolate a sample in 500 random decision trees. An absolute anomaly threshold is defined using the 95th percentile of the training cohort and applied unconditionally to external validation:"),
          p("$$ s(x, n) = 2^{-\\frac{E(h(x))}{c(n)}} $$"),
          br(),
          h4("7. Local Log-Odds Explanations (XAI)", style="font-weight:600; color:#8b5cf6;"),
          p("Deconstructs the patient's predictive score by determining the exact linear contribution of each specific marker based on the final penalized Elastic-Net coefficients:"),
          p("$$ Contribution_i = \\beta_i \\times Z_{x_i} $$"),
          br(),
          h4("9. Heuristic Uncertainty Bounds", style="font-weight:600; color:#8b5cf6;"),
          p("A built-in safety mechanism evaluates the model's certainty against a strict safety threshold calculated on the Out-Of-Bag errors, ensuring reliable algorithmic outputs even in ambiguous scenarios:")
      )
    )
  )
}

# ==============================================================================
# 5. FICHIER : app.R
# Assemble les modules et lance l'application
# ==============================================================================

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
  
  tabPanel("1. MODELING", mod_modeling_ui("modeling_tab")),
  tabPanel("2. DIAGNOSIS", mod_diagnosis_ui("diagnosis_tab")),
  tabPanel("3. METHODOLOGY", mod_methodology_ui("method_tab"))
)

server <- function(input, output, session) {
  # Le module 'modeling' retourne les résultats d'entraînement (reactiveValues)
  m_res_reactive <- mod_modeling_server("modeling_tab")
  
  # On transmet ces résultats au module 'diagnosis'
  mod_diagnosis_server("diagnosis_tab", m_res_reactive)
}

shinyApp(ui, server)
