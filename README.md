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

2. Install Dependencies
The application automatically checks for and installs missing packages upon startup. You can also install them manually by running the following command in your R console:[cite: 3] 
R
required_packages <- c(
  "shiny", "pROC", "shinythemes", "glmnet", "DT", 
  "ggplot2", "stats", "arm", "rmarkdown", "dplyr",
  "gridExtra", "PRROC", "readxl", "tools", "scales",
  "umap", "pheatmap", "cluster", "dbscan", "isotree",
  "tidyr", "caret" 
)
install.packages(required_packages)
3. Launch the Application
Open the app.R file (or main script) in RStudio and click "Run App", or execute the following command in R:[cite: 3]
R
shiny::runApp()

📊 Specific Data Format
The application accepts CSV (.csv, text/csv) or Excel (.xls, .xlsx) files. To ensure proper processing, your data file must strictly follow this nomenclature:[cite: 3] 
•	LLC (or LLC_1) Column: The target column containing the final diagnosis (coded in binary format: 1 for CLL, 0 for another pathology / alternative diagnosis). 
•	Marker Columns: All numeric columns corresponding to biological markers. These variables are automatically detected, standardized (Z-score), and used to generate comprehensive combinatorial variables (ratios, log-ratios, differences, etc.). 
•	Matutes Column: The column containing the human Matutes score (optional). If provided, the app automatically generates reclassification tables (PERCYMAT vs Matutes) and a hierarchical clustering Heatmap for Matutes 3 patients. 
•	Identifier: An ID_Interne column (optional; automatically generated as Patient_X if missing). 
📖 User Guide
Step 1: Model Training
1.	Navigate to the 1. MODELING tab. 
2.	Upload your Training Cohort data file. 
3.	(Optional) Upload an External Validation Cohort file. 
4.	Define the Number of Nested-CV Repeats. 
5.	Click "RUN MODELING" to launch the automated modeling process. 
Step 2: Performance & Topography Analysis
•	Metrics: Review the performances on the Training Cohort (Repeated Nested-CV / OOB) and Advanced OOB Metrics (PR-AUC, Calib Int/Slope, Emax, ICI). 
•	Model Coefficients: Check the Elastic-Net coefficients table to identify variables with positive and negative impacts. 
•	Clusters & Atypia: Click on individual points in the interactive UMAP & HDBSCAN Clustering chart to view characteristics of atypical patients detected via Isolation Forest. 
Step 3: Patient Diagnosis
1.	Switch to the 2. DIAGNOSIS tab. 
2.	Fill in the Biomarker Input (MFI) values for the new patient. 
3.	Click "CALCULATE CLL PROBABILITY"[cite: 2].
4.	Review the computed probability, the Conformal Prediction guarantee, and the explanation graph breaking down the mathematical impact[cite: 2].
🧠 Algorithmic Architecture
PERCYMAT v2.4 implements high-tier statistical learning concepts to ensure robust and interpretable results:[cite: 2, 3]
🔁 Repeated Nested Cross-Validation: An automated Caret modeling framework using a 5-fold inner loop for hyperparameter tuning, preventing data leakage[cite: 2].
⚖️ Elastic-Net Regularization: Combines L1 (Lasso) and L2 (Ridge) penalties via an extensive grid search (Alpha 0 to 1, Lambda $10^{-5}$ to 10) to select the most predictive markers[cite: 2].
📏 Z-score Standardization: Automatically transforms raw biological measurements into standardized Z-scores to perfectly align marker magnitudes[cite: 2].
📊 Bayesian Platt Scaling: Calibrates raw log-odds predictions using an out-of-bag Bayesian logistic regression model to reflect true clinical probabilities[cite: 2].
🗺️ HDBSCAN & Isolation Forest: Utilizes unsupervised topographic clustering and applies absolute anomaly thresholds to flag atypical patient profiles[cite: 2].
💡 Local Log-Odds Explanations (XAI): Deconstructs the patient's predictive score by evaluating the exact contribution of each feature (Model Weight × Patient Z-score)[cite: 2].
🛡️ Conformal Prediction: Wraps the final output in heuristic uncertainty bounds, evaluating model certainty against strict safety thresholds to ensure reliable diagnostic outputs[cite: 2].
