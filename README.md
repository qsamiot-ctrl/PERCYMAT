# PERCYMAT v2.4 🧬

**PERCYMAT** is an interactive web application developed in R (Shiny) designed for predictive modeling and Artificial Intelligence (AI) assisted diagnosis in the context of **Chronic Lymphocytic Leukemia (CLL)**. 

The computational pipeline is strictly engineered to comply with **TRIPOD-AI** guidelines, mitigating optimism bias (overfitting) and preventing data leakage in small clinical cohorts.

---

## ⚖️ Citation & Attribution Clause

If you use this application, its source code, the underlying algorithmic architecture, or any generated results for clinical practice, research, academic publications, or commercial purposes, **you must explicitly cite and credit the author:**

> **Dr. Quentin AMIOT**
> *Author and Principal Developer of PERCYMAT v2.4*

**Recommended Citation Format for Publications:**
> *Amiot, Q. (2026). PERCYMAT v2.4: Advanced AI-driven pipeline for Chronic Lymphocytic Leukemia cytometric modeling and diagnosis. GitHub Repository.*

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
| **1. MODELIZATION** | Import training and external validation cohorts. Automate feature engineering (ratios combinatorics, markers), apply an EPV filter, and run an AutoML Grid Search. Evaluate performances using interactive curves (ROC, PR-AUC, Calibration, DCA). Detect atypical profiles using UMAP, HDBSCAN, and Isolation Forest. |
| **2. DIAGNOSTIC** | Manually input a patient's cytometric markers. Compute the real-time probability of CLL, backed by *Conformal Prediction* safety bounds, and visualize a local Explainable AI (XAI) contribution plot (Log-Odds breakdown). |
| **3. METHODOLOGY** | Built-in technical documentation detailing the mathematical equations and rigorous validation steps (Nested-CV, Z-score, Platt Scaling). |

---

## ⚙️ Prerequisites & Installation

To run this application locally, you need **R** installed on your system (and ideally RStudio).

### 1. Clone the Repository
```bash
git clone [https://github.com/YOUR_USERNAME/PERCYMAT.git](https://github.com/YOUR_USERNAME/PERCYMAT.git)
cd PERCYMAT

```

### 2. Install Dependencies

The application automatically checks for and installs missing packages upon startup. You can also install them manually by running the following command in your R console:

```R
required_packages <- c(
  "shiny", "pROC", "shinythemes", "glmnet", "DT", 
  "ggplot2", "stats", "arm", "rmarkdown", "dplyr",
  "gridExtra", "PRROC", "readxl", "tools", "scales",
  "umap", "pheatmap", "cluster", "dbscan", "isotree", "tidyr"
)
install.packages(required_packages)

```

### 3. Launch the Application

Open the `app.R` file (or main script) in RStudio and click **"Run App"**, or execute the following command in R:

```R
shiny::runApp()

```

---

## 📊 Specific Data Format

The application accepts **CSV** (`.csv`) or **Excel** (`.xls`, `.xlsx`) files. To ensure proper processing, your data file must strictly follow this nomenclature:

* **`LLC` (or `LLC_1`) Column:** The target column containing the final diagnosis (coded in binary format: `1` for CLL, `0` for another pathology / alternative diagnosis).
* **Marker Columns (RFI):** All numeric columns corresponding to biological markers expressed as **RFI** (computed as the ratio: *MFI of the CD19+ lymphocyte population / MFI of non-CD19 lymphocytes*). These variables are automatically detected, standardized (Z-score), and used as candidate predictors (e.g., *CD5, CD23, etc.*).
* **`Matutes` Column:** The column containing the human Matutes score (optional). If provided, the app automatically generates reclassification tables (Matutes vs. AI) and a hierarchical clustering Heatmap for in-depth analysis of borderline cases (Matutes = 3).
* **Identifier:** An `ID_Interne` column (optional; automatically generated as *Patient_X* if missing).

---

## 📖 User Guide

### Step 1: Model Training

1. Navigate to the **1. MODELISATION** tab.
2. Upload your **Training Cohort** data file.
3. (Optional) Upload an **External Validation Cohort** file to test institutional generalizability.
4. Select your feature engineering rules (Simple ratios, Full combinations, EPV Filter).
5. Toggle **⚡ Performance IA (Automated Grid Search)** to let the system automatically optimize the hyperparameter matrix.
6. Click **"LANCER LA MODÉLISATION"** (Run Modeling).

### Step 2: Performance & Topography Analysis

* **Metrics:** Review the *Out-Of-Bag* validation parameters (AUC, PR-AUC, Brier Score, Emax, ICI).
* **Odds Ratios:** Check the Elastic-Net coefficients table to identify the most discriminative RFIs.
* **Topography:** Click on individual points in the interactive UMAP/HDBSCAN chart to deeply explore intra-group Z-scores and analyze patients isolated by the *Isolation Forest*.

### Step 3: Patient Diagnosis

1. Switch to the **2. DIAGNOSTIC** tab.
2. Fill in the RFI values for the new patient (input fields dynamically adapt to the markers included in your model).
3. Click **"CALCULER PROBABILITÉ LLC"** to receive a calibrated risk score, a 95% Conformal Prediction certainty set, and a local explanation chart (XAI).

---

## 🧠 Algorithmic Architecture

PERCYMAT v2.4 implements high-tier statistical learning concepts to neutralize small-sample bias:

* **Repeated Nested Cross-Validation:** Impermeable outer/inner loop segregation preventing data leakage during feature optimization.
* **Dynamic EPV Filter:** Maintains the Events-Per-Variable ratio ($\ge 5$) directly inside the CV training folds.
* **Elastic-Net Regularization:** Combines L1 (Lasso) and L2 (Ridge) penalties to select robust predictors and handle the inherent collinearity of cytometric markers.
* **Bayesian Platt Scaling:** Calibrates raw log-odds predictions using an out-of-bag Bayesian logistic regression model.
* **Conformal Prediction:** Wraps predictions with rigorous mathematical certainty bounds (95% coverage) based on non-conformity scores computed on the training cohort.
* **Topographical Anomaly Detection:** Applies an absolute Isolation Forest threshold (calibrated on the 95th percentile of the training cohort) to unconditionally flag atypical expressions across both internal and external datasets.

---

*Developed for clinical research and cytometric diagnostic optimization. Distributed under academic attribution guidelines.*

```

Vous pouvez copier et coller directement ce bloc de code dans le fichier `README.md` sur votre dépôt GitHub.

```
