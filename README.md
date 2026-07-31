# PERCYMAT v2.4 🧬

**PERCYMAT** is an interactive web application developed in R (Shiny) designed for predictive modeling and Artificial Intelligence (AI) assisted diagnosis in the context of **Chronic Lymphocytic Leukemia (CLL)**. 

The computational pipeline is strictly engineered to comply with **TRIPOD-AI** guidelines, mitigating optimism bias (overfitting) and preventing data leakage in small clinical cohorts.

---

## ⚖️ Citation & Attribution Clause

If you use this application, its source code, the underlying algorithmic architecture, or any generated results for clinical practice, research, academic publications, or commercial purposes, **you must explicitly cite and credit the author:**

> **Dr. Quentin AMIOT**[cite: 3]
> *Author and Principal Developer of PERCYMAT v2.4*[cite: 3]

**Recommended Citation Format for Publications:**[cite: 3]
> *Amiot, Q. (2026). PERCYMAT v2.4: Advanced AI-driven pipeline for Chronic Lymphocytic Leukemia cytometric modeling and diagnosis. GitHub Repository.*[cite: 3]

---

## 📑 Table of Contents
1. [Core Features](#-core-features)
2. [Prerequisites & Installation](#%EF%B8%8F-prerequisites--installation)
3. [Specific Data Format](#-specific-data-format)
4. [User Guide](#-user-guide)
5. [Algorithmic Architecture](#-algorithmic-architecture)

---

## 🚀 Core Features

The application is divided into 3 specialized tabs:

| Tab | Description |
| :--- | :--- |
| **1. MODELING** | Import training and external validation cohorts. Automate feature engineering with systematic combinatorial engineering. Run an automated Caret modeling with Elastic-Net. Evaluate performances using interactive curves (ROC, PR-AUC, Calibration, DCA). Detect atypical profiles using UMAP, HDBSCAN, and Isolation Forest. |
| **2. DIAGNOSIS** | Manually input a patient's cytometric markers (MFI). Compute the probability of CLL backed by Conformal Prediction (95% Guarantee). Visualize a local Explainable AI (XAI) contribution plot detailing Model Weight × Patient Z-score. |
| **3. METHODOLOGY** | Built-in technical documentation detailing the mathematical equations and rigorous validation steps (Nested-CV, Z-score, Platt Scaling, HDBSCAN, Isolation forest, etc.). |

---

## ⚙️ Prerequisites & Installation

To run this application locally, you need **R** installed on your system (and ideally RStudio)[cite: 3].

### 1. Clone the Repository
```bash
git clone [https://github.com/YOUR_USERNAME/PERCYMAT.git](https://github.com/YOUR_USERNAME/PERCYMAT.git)
cd PERCYMAT
2. Install DependenciesThe application automatically checks for and installs missing packages upon startup. You can also install them manually by running the following command in your R console:[cite: 3]  Rrequired_packages <- c(
  "shiny", "pROC", "shinythemes", "glmnet", "DT", 
  "ggplot2", "stats", "arm", "rmarkdown", "dplyr",
  "gridExtra", "PRROC", "readxl", "tools", "scales",
  "umap", "pheatmap", "cluster", "dbscan", "isotree",
  "tidyr", "caret" 
)
install.packages(required_packages)
3. Launch the ApplicationOpen the app.R file (or main script) in RStudio and click "Run App", or execute the following command in R:[cite: 3]Rshiny::runApp()
📊 Specific Data FormatThe application accepts CSV (.csv, text/csv) or Excel (.xls, .xlsx) files. To ensure proper processing, your data file must strictly follow this nomenclature:[cite: 3]  LLC (or LLC_1) Column: The target column containing the final diagnosis (coded in binary format: 1 for CLL, 0 for another pathology / alternative diagnosis).  Marker Columns: All numeric columns corresponding to biological markers. These variables are automatically detected, standardized (Z-score), and used to generate comprehensive combinatorial variables (ratios, log-ratios, differences, etc.).  Matutes Column: The column containing the human Matutes score (optional). If provided, the app automatically generates reclassification tables (PERCYMAT vs Matutes) and a hierarchical clustering Heatmap for Matutes 3 patients.  Identifier: An ID_Interne column (optional; automatically generated as Patient_X if missing).  📖 User GuideStep 1: Model TrainingNavigate to the 1. MODELING tab.  Upload your Training Cohort data file.  (Optional) Upload an External Validation Cohort file.  Define the Number of Nested-CV Repeats.  Click "RUN MODELING" to launch the automated modeling process.  Step 2: Performance & Topography AnalysisMetrics: Review the performances on the Training Cohort (Repeated Nested-CV / OOB) and Advanced OOB Metrics (PR-AUC, Calib Int/Slope, Emax, ICI).  Model Coefficients: Check the Elastic-Net coefficients table to identify variables with positive and negative impacts.  Clusters & Atypia: Click on individual points in the interactive UMAP & HDBSCAN Clustering chart to view characteristics of atypical patients detected via Isolation Forest.  Step 3: Patient DiagnosisSwitch to the 2. DIAGNOSIS tab.  Fill in the Biomarker Input (MFI) values for the new patient.  Click "CALCULATE CLL PROBABILITY"[cite: 2].Review the computed probability, the Conformal Prediction guarantee, and the explanation graph breaking down the mathematical impact[cite: 2].🧠 Algorithmic ArchitecturePERCYMAT v2.4 implements high-tier statistical learning concepts:[cite: 2, 3]Repeated Nested Cross-Validation: An automated Caret modeling framework using a 5-fold inner loop for tuning[cite: 2].Elastic-Net Regularization: Combines L1 and L2 penalties via grid search (Alpha 0 to 1, Lambda 10^-5 to 10) to identify predictive markers[cite: 2].Z-score Standardization: Transforms raw measurements into standardized Z-scores to align marker magnitudes[cite: 2].Bayesian Platt Scaling: Calibrates raw log-odds predictions using an out-of-bag Bayesian logistic regression model[cite: 2].HDBSCAN Clustering & Isolation Forest: Unsupervised topographic workflows and absolute anomaly thresholds for atypical profile detection[cite: 2].Local Log-Odds Explanations (XAI): Deconstructs the patient's predictive score by evaluating Model Weight × Patient Z-score[cite: 2].Heuristic Uncertainty Bounds / Conformal Prediction: Evaluates certainty against a safety threshold to ensure reliable outputs[cite: 2].
