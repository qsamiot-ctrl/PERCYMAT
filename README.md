# PERCYMAT v2.4 🧬

**PERCYMAT** is an interactive web application developed in R (Shiny) designed for predictive modeling and Artificial Intelligence (AI) assisted diagnosis in the context of **Chronic Lymphocytic Leukemia (CLL)**. 

The computational pipeline is strictly engineered to comply with the **TRIPOD-AI** guidelines, mitigating optimism bias (overfitting) and preventing data leakage in small clinical cohorts.

---

## ⚖️ Citation & Attribution Clause

If you use this application, its source code, the underlying algorithmic architecture, or any generated results for clinical practice, research, academic publications, or commercial purposes, **you must explicitly cite and credit the author**:

> **Dr. Quentin AMIOT** > *Author and Principal Developer of PERCYMAT v2.4*

**Recommended Citation Format for Publications:**
> *Amiot, Q. (2026). PERCYMAT v2.4: Advanced AI-driven pipeline for Chronic Lymphocytic Leukemia cytometric modeling and diagnosis. GitHub Repository.*

---

## 📑 Table of Contents
1. [Core Features](#-core-features)
2. [Prerequisites & Installation](#%EF%B8%8F-prerequisites--installation)
3. [Data Format Requirements](#-data-format-requirements)
4. [User Guide](#-user-guide)
5. [Algorithmic Architecture](#-algorithmic-architecture)

---

## 🚀 Core Features

The application is divided into 3 specialized tabs:

| Tab | Description |
| :--- | :--- |
| **1. MODELIZATION** | Import training and external validation cohorts. Automate feature engineering (ratios, markers combinatorics), apply an EPV filter, and run an AutoML Grid Search. Evaluate performances using interactive ROC, PR-AUC, Calibration, and DCA curves. Detect atypical profiles using UMAP, HDBSCAN, and Isolation Forest. |
| **2. DIAGNOSTIC** | Manually input a patient's cytometric markers. Compute the real-time probability of CLL, backed by *Conformal Prediction* safety bounds, and visualize a local Explainable AI (XAI) contribution plot. |
| **3. METHODOLOGY** | Built-in technical documentation detailing the mathematical equations and rigorous validation steps (Nested-CV, Z-score, Platt Scaling). |

---

## ⚙️ Prerequisites & Installation

To run this application locally, you need **R** installed on your system (and ideally RStudio).

### 1. Clone the Repository
```bash
git clone [https://github.com/YOUR_USERNAME/PERCYMAT.git](https://github.com/YOUR_USERNAME/PERCYMAT.git)
cd PERCYMAT
