<img width="2800" height="680" alt="1" src="https://github.com/user-attachments/assets/6b63c20a-24fe-46c1-869d-ec474b5459c3" />


<div align="center">

![Excel](https://img.shields.io/badge/Excel-Financial%20Model-217346?style=flat-square&logo=microsoft-excel&logoColor=white)
![Python](https://img.shields.io/badge/Python-pandas%20ETL-3776AB?style=flat-square&logo=python&logoColor=white)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-F37626?style=flat-square&logo=jupyter&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-KPI%20Views-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Executive%20Dashboard-F2C811?style=flat-square&logo=powerbi&logoColor=black)
![Status](https://img.shields.io/badge/status-portfolio%20project-34D399?style=flat-square)
![License](https://img.shields.io/badge/license-MIT-9CA3AF?style=flat-square)

**A full analytics-engineering pipeline for a simulated SaaS business — from a first-principles financial model in Excel, through a reproducible Python cleaning layer and a PostgreSQL analytics schema, to a 5-page executive Power BI report with 49 DAX measures.**

</div>

---

## Table of contents

- [What this is](#what-this-is)
- [Why it's worth a look](#why-its-worth-a-look)
- [Architecture](#architecture)
- [Repository structure](#repository-structure)
- [The dashboard (live screenshots)](#the-dashboard-live-screenshots)
- [The dataset](#the-dataset)
- [KPI glossary & formulas](#kpi-glossary--formulas)
- [Dashboard QA notes: what a careful review found](#dashboard-qa-notes-what-a-careful-review-found)
- [Appendix: what the raw dataset alone says](#appendix-what-the-raw-dataset-alone-says)
- [Getting started](#getting-started)
- [⚠️ Security note (please read before reusing the notebook)](#️-security-note-please-read-before-reusing-the-notebook)
- [Assumptions & limitations](#assumptions--limitations)
- [Roadmap](#roadmap)
- [Author & credits](#author--credits)
- [License](#license)

---

## What this is

This repository is an end-to-end **SaaS metrics analytics pipeline**, built on a *simulated* 5-year (60-month) financial model rather than a live production system. It demonstrates the full toolchain an analytics engineer uses to turn a hand-built spreadsheet into a governed, queryable, and visualized metrics layer:

```
Excel financial model  →  Python/pandas cleaning  →  tidy CSV  →  PostgreSQL schema  →  Power BI executive report
```

## Why it's worth a look

- **A real ETL problem, not a toy dataset.** The source Excel model stores metrics in a wide, human-readable layout (years across columns, forward-filled category labels, mixed header rows). The notebook documents the actual parsing work needed to reshape it, not a pre-cleaned CSV handed to you.
- **A proper semantic layer, not just charts.** The Power BI report sits on top of **49 explicit DAX measures** across 5 pages — including composite scores (`Business Health Score`), MoM growth measures, and dynamic narrative measures that generate the on-page insight text.
- **A SQL layer that goes beyond `SELECT *`.** `saas_kpi_analytics.sql` includes staging DDL, multiple analytical views, a window-function MoM growth query, a parameterized stored procedure, and an audit trigger.
- **Honest about its own rough edges.** See [Dashboard QA notes](#dashboard-qa-notes-what-a-careful-review-found) — a side-by-side read of the live dashboard against the underlying data surfaced a few concrete aggregation bugs worth fixing before this goes in front of an executive audience. Calling those out here, with the exact numbers that prove them, is more useful than pretending the dashboard is flawless.

## Architecture

<img width="2600" height="1120" alt="2" src="https://github.com/user-attachments/assets/7ba1db2f-464f-48f5-aa4a-575f8c6b0223" />


| Stage | Tool | What happens |
|---|---|---|
| 1. Model | Excel (`SaaS Model vCurrent.xlsx`) | Assumptions-driven 5-year model: subscriber growth, pricing, CAC, payroll, COGS, taxes, and a full 3-statement build |
| 2. Clean | Jupyter / pandas (`saas_data_cleaning.ipynb`) | Parses each sheet's date row and metric-name column, un-pivots wide → long, concatenates three sheets, de-duplicates |
| 3. Store | CSV → PostgreSQL (`Cleaned_SaaS_Metrics.csv`, `saas_kpi_analytics.sql`) | Loads into a narrow fact table (`date`, `sheet_source`, `metric_name`, `metric_value`); views pivot it back into wide, analysis-ready shapes |
| 4. Visualize | Power BI (`SaaS_Executive_KPI_Dashboard.pbix`) | Semantic model with 49 DAX measures across 5 report pages |

> **Note on scope:** the live report also displays several supplemental, illustrative dimensions — customer segments (Enterprise/Mid-Market/Prosumer/SMB/etc.), a lead-to-paid funnel, monthly cohort retention, CAC by acquisition channel, and plan tiers (Enterprise/Professional/Starter/Custom) — that do **not** appear anywhere in `Cleaned_SaaS_Metrics.csv`, the SQL script, or the Excel model's `Assumptions` sheet. They were evidently added directly inside the Power BI file for presentation depth. That's a completely normal thing to do in a portfolio piece, but it means the `.pbix` is a superset of the ETL pipeline's output, not a pure 1:1 visualization of it — worth knowing if you're trying to trace a number on the report back to a row in the CSV.

## Repository structure

```
SaaS-KPI-Analytics/
├── README.md
├── data/
│   ├── SaaS Model vCurrent.xlsx        # Source 8-sheet financial model
│   └── Cleaned_SaaS_Metrics.csv        # Tidy long-format output (7,315 rows)
├── notebooks/
│   └── saas_data_cleaning.ipynb        # pandas ETL: wide Excel → long CSV
├── sql/
│   └── saas_kpi_analytics.sql          # Staging table, KPI views, procedure, audit trigger
├── pbix/
│   └── SaaS_Executive_KPI_Dashboard.pbix  # 5-page Power BI executive report
└── docs/
    └── images/                         # Screenshots & charts used in this README
```

## The dashboard (live screenshots)

Five pages, captured directly from Power BI Desktop.

### 1 · Executive Summary
One-screen health check: headline KPI cards, MRR and subscriber trends, a Revenue vs. Expenses combo chart, a revenue-composition donut, a `Business Health Score` gauge, and auto-generated key-insight callouts.

![Executive Summary](docs/images/02_dashboard_executive_summary.png)

### 2 · Revenue & Subscribers
Plan revenue mix over time, a monthly-cohort retention heatmap, a plan/region revenue treemap, and a detailed insights table (CAC, churn risk, expansion MRR, LTV:CAC, and more).

![Revenue & Subscribers](docs/images/03_dashboard_revenue_subscribers.png)

### 3 · Unit Economics & Efficiency
LTV/CAC trend over a trailing 12 months, a lead-to-paid funnel, CAC breakdown by acquisition channel, and a per-segment unit-economics table.

![Unit Economics](docs/images/04_dashboard_unit_economics.png)

### 4 · Financials & Cash Flow
Gross/net margin, OpEx, monthly burn rate and cash runway cards; a 12-month revenue-vs-expenses-vs-burn chart; and a QTD cash-position waterfall bridge.

![Financials & Cash Flow](docs/images/05_dashboard_financials_cashflow.png)

### 5 · About / Info
A documentation-in-product page: what the report answers, how to use it, metric-definition notes, and developer credit.

![About / Info](docs/images/06_dashboard_about_info.png)

## The dataset

`Cleaned_SaaS_Metrics.csv` is a single tidy fact table:

| Date | Sheet_Source | Metric | Value |
|---|---|---|---|
| 2024-01-01 | Subscribers & Revenue | New Monthly Subscribers | 90 |
| 2024-01-01 | Subscribers & Revenue | MRR | 4212.5 |
| … | … | … | … |

- **7,315 rows** · **102 distinct metric names** · **60 monthly periods** (Jan 2024 – Dec 2028)

| `Sheet_Source` | Focus | Example metrics |
|---|---|---|
| `Subscribers & Revenue` | Top-line growth | New/Active/Churned Subscribers, MRR, ARR, Bookings |
| `Detailed Metrics` | Unit economics | CAC, LTV, ARPU, Payback Period, LTV:CAC, Burn Multiple |
| `Summary Financials` | 3-statement financials | Revenue, COGS, OPEX, Net Income, Balance Sheet, Cash Flow |

This long/narrow shape is a deliberate design choice: one fact table supports arbitrarily many metrics without schema changes, at the cost of needing `PIVOT`-style views (see `saas_kpi_analytics.sql`) to get back to an analysis-friendly wide shape.

## KPI glossary & formulas

| KPI | Formula | Why it matters |
|---|---|---|
| **MRR** | Sum of monthly-plan revenue + amortized annual-plan revenue | The core recurring-revenue pulse of the business |
| **ARR** | MRR × 12 | Annualized run-rate, used for board/investor reporting |
| **Churn rate** | Churned subscribers ÷ active subscribers (start of period) | How fast the bucket is leaking |
| **ARPU** | MRR ÷ active subscribers | Monetization per account |
| **CAC** | Total sales & marketing spend ÷ new subscribers acquired | Cost to add one customer |
| **LTV** | ARPU ÷ monthly churn rate | Expected revenue per customer over their lifetime |
| **LTV : CAC** | LTV ÷ CAC (blended, i.e. revenue-weighted across segments) | Unit-economics efficiency; **>3× is the common SaaS bar for healthy** |
| **CAC payback period** | CAC ÷ (ARPU × gross margin %) | Months to recover acquisition cost; **<12 months is generally considered efficient** |
| **Burn Multiple** | Net cash burned ÷ net new ARR | Capital efficiency of growth; **Bessemer's benchmark: <1× is exceptional, 1–1.5× good, >2× needs work** |
| **Gross margin** | (Revenue − COGS) ÷ Revenue | Underlying product economics before OPEX |
| **Net margin** | Net income ÷ Revenue | Bottom-line profitability |
| **Runway** | Cash balance ÷ monthly net burn | Months until cash runs out at current burn |

## Dashboard QA notes: what a careful review found

Reading the report's own numbers against each other (not against any external benchmark) surfaces a few concrete issues. These are the kind of thing a technical reviewer or hiring manager will spot in about thirty seconds, so it's better addressed here directly than left for someone else to discover.

**1. The Unit Economics headline cards are an unweighted SUM across six customer segments, not a blended average — and this is provable by exact arithmetic.** The page's "Detailed Unit Economics by Segment" table gives per-segment figures for six segments (Enterprise, Mid-Market, Prosumer, SMB, Startup/Growth, VSMB/Micro). Adding them up by hand reproduces the headline cards exactly:

| Headline card | Reported value | Sum of the 6 segment rows | Match? |
|---|---:|---:|---|
| Blended CAC | ₹8.5K | 3,200 + 1,850 + 150 + 1,250 + 1,600 + 450 = **8,500** | ✅ exact |
| SaaS LTV | ₹57.01K | 25,770 + 15,290 + 900 + 5,250 + 8,000 + 1,800 = **57,010** | ✅ exact |
| LTV to CAC Ratio | 35.40 | 8.00 + 8.20 + 6.00 + 4.20 + 5.00 + 4.00 = **35.40** | ✅ exact |
| Payback Period | 33.40 | 5.20 + 6.50 + 3.00 + 7.20 + 6.00 + 5.50 = **33.40** | ✅ exact |

A **35.4× LTV:CAC ratio** and a **33.4-month payback period** are both far outside plausible SaaS ranges (industry-healthy is roughly 3–5× and under 12 months respectively) — the individual segment rows (4×–8.2× LTV:CAC, 3–7.2 month payback) are perfectly reasonable on their own. The fix is straightforward: the card measures should use a weighted average (e.g. `SUMX` over segments divided by total customers, or `DIVIDE(SUM(LTV), SUM(CAC))`) instead of `SUM` over the segment table.

**2. Two "Fin_" measures on the Financials & Cash Flow page don't appear to respond to the monthly date filter.** In the "Monthly Revenue vs Expenses & Cash Burn (Last 12 Mos)" chart, the `Monthly Plan Revenue` series grows naturally from $1.2M to $3.3M across the 12 months — but the `Fin_Total OpEx` series prints the identical value ($15.2M) at every single month, and the `Operating Expenses (OpEx)` card at the top of the page shows that same static $15.2M. That's consistent with a measure that isn't using the visual's date context (e.g., missing a `CALCULATE`/date-table relationship, or an accidental `ALL()`).

**3. The same page's "Monthly Burn Rate" card and its own chart series disagree by roughly 10×.** The card reads **$1.8M**, while the `Fin_Monthly Burn Rate` line in the chart directly below it is labeled **$18.2M–$20.3M** across the same 12 months. Both can't be right for the same measure — this looks like a scale or format-string mismatch between the two visuals rather than two different underlying calculations.

**4. The Executive Summary's "Total MRR" ($197.38M) and "Active Subscribers" (6.99M) cards are far larger than the trend charts on the same page** (MRR trend tops out at $16.8M; Active Subscribers trend tops out at 591K). The magnitude is consistent with a `SUM(MRR)` computed across all 60 months of history rather than the latest month's value — a geometric-series estimate using the visible growth rate and the chart's final value lands within ~2% of the card's reported total, which supports this read, though the underlying DAX wasn't directly inspectable (Power BI stores compiled measure logic in a compressed binary model, not in the human-readable report file). Worth confirming directly in Power BI Desktop by checking whether the measure uses `CALCULATE(SUM(...), LASTDATE(...))` or a plain `SUM`.

**5. Currency formatting is inconsistent across pages.** The Unit Economics page formats every figure with a ₹ (INR) prefix, while the Executive Summary, Revenue & Subscribers, and Financials pages show no currency symbol at all on the same kinds of dollar-value cards. Worth picking one currency and one format string and applying it model-wide.

None of this undermines the project as a portfolio piece — if anything, a report detailed enough to cross-check against itself this way is a sign of real depth. But if this dashboard is headed in front of an actual audience, items 1–3 should be fixed before that happens, since a 35× LTV:CAC or a $1.8M-vs-$18M burn-rate mismatch is the kind of thing that costs credibility fast in a room full of finance people.

## Appendix: what the raw dataset alone says

For comparison, here's what you get computing metrics directly from `Cleaned_SaaS_Metrics.csv` with pandas — no Power BI involved. These numbers describe the base financial model, not the dashboard's supplemental segment/cohort/funnel data, so they won't match the live report's cards (see QA notes above) — they're included as an independently reproducible ground truth.

| Metric | Month 1 (Jan-2024) | Month 60 (Dec-2028) |
|---|---:|---:|
| MRR | $4,213 | **$4,192,220** |
| ARR | — | **$50,306,640** |
| Active subscribers | 145 | **147,786** |
| Blended CAC | — | **$45.67** |
| Blended LTV | — | **$356.94** |
| Blended LTV : CAC | — | **7.8×** |
| Blended payback period | — | **1.6 months** |
| Gross margin | — | **86.0%** |
| Net margin | −2,015% | **−31.0%** |
| Burn Multiple | — | **2.34×** (avg. across all 59 months: 11.5×) |
| Cash & equivalents | — | **$1,000,000** (modeled floor) |
| Modeled capital required | — | **$21,399,064** (per `Funds to Raise`, triggered around month 11) |

**The honest read of these numbers:** unit economics are genuinely strong (7.8× LTV:CAC, 1.6-month payback, 86% gross margin), but the model **never reaches profitability inside its own 5-year window** — net margin improves from −2,015% to −31%, a real trajectory, but still a loss at the end. The Burn Multiple (~11.5× average, ~2.3× by year 5) says the same thing from a capital-efficiency angle: cheap customer acquisition is being offset by a cost base that scales ahead of revenue in the model's assumptions. Subscriber growth is also a fixed 10%/7% monthly compounding rate with no saturation curve, so treat the 147,786-subscriber endpoint as "what the input growth rate implies," not a market-sized forecast. The $1,000,000 ending cash balance is a modeling assumption (it matches the `Assumptions` sheet input exactly), not a derived result — the model assumes a ~$21.4M raise happens rather than testing whether it's earned.

| MRR / ARR growth | Subscriber mix |
|---|---|
| ![MRR ARR](docs/images/07_csv_mrr_arr_growth.png) | ![Subscriber mix](docs/images/08_csv_subscriber_mix.png) |

| LTV vs. CAC by segment (base model) | Burn vs. cash balance |
|---|---|
| ![LTV CAC](docs/images/09_csv_ltv_cac.png) | ![Burn vs cash](docs/images/10_csv_burn_vs_cash.png) |

## Getting started

### 1. Regenerate the cleaned dataset (optional — it's already committed)

```bash
cd notebooks
pip install pandas numpy openpyxl
jupyter nbconvert --to notebook --execute saas_data_cleaning.ipynb
```

### 2. Load into PostgreSQL

```bash
createdb saas_kpi_dashboard
psql -d saas_kpi_dashboard -f sql/saas_kpi_analytics.sql
```

Then load the CSV, e.g. with `psql`'s `\copy`:

```sql
\copy public.saas_metrics (date, sheet_source, metric_name, metric_value)
FROM 'data/Cleaned_SaaS_Metrics.csv' WITH (FORMAT csv, HEADER true);
```

or from Python, using environment variables rather than hardcoded credentials (see the security note below):

```python
import os
from urllib.parse import quote_plus
from sqlalchemy import create_engine
import pandas as pd

user = os.environ["PGUSER"]
password = quote_plus(os.environ["PGPASSWORD"])
host = os.environ.get("PGHOST", "localhost")
port = os.environ.get("PGPORT", "5432")
db = os.environ["PGDATABASE"]

engine = create_engine(f"postgresql://{user}:{password}@{host}:{port}/{db}")
pd.read_csv("data/Cleaned_SaaS_Metrics.csv").to_sql(
    "saas_metrics", engine, if_exists="replace", index=False
)
```

### 3. Explore the KPI views

```sql
SELECT * FROM view_executive_kpis ORDER BY date DESC LIMIT 12;
SELECT * FROM view_unit_economics ORDER BY date DESC LIMIT 12;
SELECT * FROM view_financial_pnl ORDER BY date DESC LIMIT 12;
```

### 4. Open the dashboard

Open `pbix/SaaS_Executive_KPI_Dashboard.pbix` in **Power BI Desktop** and point the semantic model at your PostgreSQL instance (or the CSV directly) via *Transform data → Data source settings*. Before publishing, see the [QA notes](#dashboard-qa-notes-what-a-careful-review-found) above for three measure-definition issues worth fixing first.

## ⚠️ Security note (please read before reusing the notebook)

`saas_data_cleaning.ipynb` (final cell) currently contains a **hardcoded, plaintext PostgreSQL password** used to build the SQLAlchemy connection string. Before pushing this repo anywhere public:

- [ ] Remove the hardcoded credential and rotate the corresponding PostgreSQL password immediately, since it's no longer safe to use even privately.
- [ ] Replace it with an environment variable (`os.environ[...]`) or a `.env` file loaded via `python-dotenv`, and add `.env` to `.gitignore`.
- [ ] Check the notebook's Git history — if it was ever committed with the password inline, it's compromised even after the file is edited, and needs rotating rather than just fixing the file going forward.

## Assumptions & limitations

- **This is a simulated financial model, not real company data.** Every figure in the base CSV traces back to hand-set assumptions (retention rates, pricing, hiring plan, CAC) in the Excel `Assumptions` sheet.
- **The live dashboard is a superset of the ETL pipeline's data** (see the [Architecture](#architecture) note) — several visuals draw on supplemental segment/cohort/funnel/channel data not present in `Cleaned_SaaS_Metrics.csv`, so not every number on the report is traceable to the committed CSV.
- **Three measure-definition issues are documented, not fixed** (see [QA notes](#dashboard-qa-notes-what-a-careful-review-found)) — the `.pbix` in this repo is exactly as captured, warts included, rather than silently patched behind the scenes.
- **Growth in the base model is a fixed compounding rate, not a fitted or capped forecast** — see the Appendix.
- **Currency, locale, and tax assumptions are mixed** — the base Excel model uses USD, while the Unit Economics dashboard page displays ₹ (INR); pick one before treating this as a template for a real company.

## Roadmap

- [ ] Fix the three measure-definition issues in [QA notes](#dashboard-qa-notes-what-a-careful-review-found) (weighted-average unit economics, date-context on `Fin_Total OpEx`, burn-rate scale mismatch)
- [ ] Standardize currency formatting across all five report pages
- [ ] Parameterize the Excel model's key assumptions (growth rate, retention, CAC) for scenario/sensitivity analysis
- [ ] Add a `dbt` layer between PostgreSQL and Power BI for tested, version-controlled transformations in place of the current SQL views
- [ ] Add automated data-quality checks (e.g., `great_expectations` or pandas assertions) to catch parsing regressions if the Excel layout changes
- [ ] Document the supplemental segment/cohort/funnel tables' source so the full data model is reproducible, not just the base financial model

## Author & credits

Built by **Khusi Khanra** — [github.com/khusikhanra](https://github.com/khusikhanra) (credit as shown on the dashboard's *About* page).

## License

This project is provided under the [MIT License](https://opensource.org/licenses/MIT) — feel free to fork, adapt, and reuse the pipeline structure for your own portfolio or teaching purposes. The underlying financial figures are entirely synthetic.
