<div align="center">
  <h1>🧬 PERCYMAT v2.4</h1>
  <p><i>Interactive AI-Driven Pipeline for Chronic Lymphocytic Leukemia (CLL)</i></p>
</div>

---

**PERCYMAT** is an interactive web application developed in R (Shiny) designed for predictive modeling and Artificial Intelligence (AI) assisted diagnosis in the context of **Chronic Lymphocytic Leukemia (CLL)**. 

The computational pipeline is strictly engineered to comply with **TRIPOD-AI** guidelines, mitigating optimism bias (overfitting) and preventing data leakage in small clinical cohorts.

---

## ⚖️ Citation & Attribution Clause

> ⚠️ **IMPORTANT**
> If you use this application, its source code, the underlying algorithmic architecture, or any generated results for clinical practice, research, academic publications, or commercial purposes, **you must explicitly cite and credit the author**.

**Author and Principal Developer:**
* Dr. Quentin AMIOT, PERCYMAT v2.4[cite: 3]

**Recommended Citation Format for Publications:**
* *Amiot, Q. (2026). PERCYMAT v2.4: Advanced AI-driven pipeline for Chronic Lymphocytic Leukemia cytometric modeling and diagnosis. GitHub Repository.*[cite: 3]

---

## 🚀 Core Features

The application is divided into 3 specialized tabs:

### 📊 1. MODELING
* **Data Import:** Import training and external validation cohorts.
* **Feature Engineering:** Automate feature engineering with systematic combinatorial engineering.
* **Machine Learning:** Run an automated Caret modeling with Elastic-Net.
* **Metrics:** Evaluate performances using interactive curves (ROC, PR-AUC, Calibration, DCA).
* **Topography:** Detect atypical profiles using UMAP, HDBSCAN, and Isolation Forest.

### 🔬 2. DIAGNOSIS
* **Patient Input:** Manually input a patient's cytometric markers (MFI).
* **Safety Bounds:** Compute the probability of CLL backed by Conformal Prediction (95% Guarantee).
* **Interpretability:** Visualize a local Explainable AI (XAI) contribution plot detailing Model Weight × Patient Z-score.

### 📖 3. METHODOLOGY
* **Documentation:** Built-in technical documentation detailing the mathematical equations and rigorous validation steps (Nested-CV, Z-score, Platt Scaling, HDBSCAN, Isolation forest, etc.).

---

## ⚙️ Prerequisites & Installation

To run this application locally, you need **R** installed on your system (and ideally RStudio)[cite: 3].

<details>
<summary><b>Click to view installation instructions</b></summary>

**1. Clone the Repository**
```bash
git clone [https://github.com/YOUR_USERNAME/PERCYMAT.git](https://github.com/YOUR_USERNAME/PERCYMAT.git)
cd PERCYMAT
2. Install Dependencies The application automatically checks for and installs missing packages upon startup. You can also install them manually by running the following command in your R console[cite: 3]: 
R
required_packages <- c(
  "shiny", "pROC", "shinythemes", "glmnet", "DT", 
  "ggplot2", "stats", "arm", "rmarkdown", "dplyr",
  "gridExtra", "PRROC", "readxl", "tools", "scales",
  "umap", "pheatmap", "cluster", "dbscan", "isotree",
  "tidyr", "caret" 
)
install.packages(required_packages)
3. Launch the Application Open the app.R file (or main script) in RStudio and click "Run App", or execute the following command in R[cite: 3]:
R
shiny::runApp()
📁 Specific Data Format
The application accepts CSV (.csv, text/csv) or Excel (.xls, .xlsx) files. To ensure proper processing, your data file must strictly follow this nomenclature[cite: 3]: 
Column Name	Description	Requirement
LLC (or LLC_1)	The target column containing the final diagnosis (coded in binary format: 1 for CLL, 0 for another pathology / alternative diagnosis). 	Mandatory
Marker Columns	All numeric columns corresponding to biological markers. These variables are automatically detected, standardized (Z-score), and used to generate comprehensive combinatorial variables (ratios, log-ratios, differences, etc.). 	Mandatory
Matutes	The column containing the human Matutes score. If provided, the app automatically generates reclassification tables (PERCYMAT vs Matutes) and a hierarchical clustering Heatmap for Matutes 3 patients[cite: 2]. 	Optional
ID_Interne	Patient identifier (automatically generated as Patient_X if missing)[cite: 2].	Optional
🧠 Algorithmic Architecture
PERCYMAT v2.4 implements high-tier statistical learning concepts to ensure robust and interpretable results[cite: 2, 3]:
•	🔁 Repeated Nested Cross-Validation: An automated Caret modeling framework using a 5-fold inner loop for tuning[cite: 2].
•	⚖️ Elastic-Net Regularization: Combines L1 and L2 penalties via grid search (Alpha 0 to 1, Lambda 10^-5 to 10) to identify predictive markers[cite: 2].
•	📏 Z-score Standardization: Transforms raw measurements into standardized Z-scores to align marker magnitudes[cite: 2].
•	📊 Bayesian Platt Scaling: Calibrates raw log-odds predictions using an out-of-bag Bayesian logistic regression model[cite: 2].
•	🗺️ HDBSCAN Clustering & Isolation Forest: Unsupervised topographic workflows and absolute anomaly thresholds for atypical profile detection[cite: 2].
•	💡 Local Log-Odds Explanations (XAI): Deconstructs the patient's predictive score by evaluating Model Weight × Patient Z-score[cite: 2].
•	🛡️ Heuristic Uncertainty Bounds: Evaluates certainty against a safety threshold to ensure reliable outputs (Conformal Prediction)[cite: 2].
