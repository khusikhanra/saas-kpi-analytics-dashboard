<img width="2800" height="680" alt="1" src="https://github.com/user-attachments/assets/d46ff7d1-da32-4184-bd1d-1f61c90a44de" />


<div align="center">

![Excel](https://img.shields.io/badge/Excel-Financial%20Model-217346?style=flat-square&logo=microsoft-excel&logoColor=white)
![Python](https://img.shields.io/badge/Python-pandas%20ETL-3776AB?style=flat-square&logo=python&logoColor=white)
![Jupyter](https://img.shields.io/badge/Jupyter-Notebook-F37626?style=flat-square&logo=jupyter&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-KPI%20Views-4169E1?style=flat-square&logo=postgresql&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-Executive%20Dashboard-F2C811?style=flat-square&logo=powerbi&logoColor=black)
![License](https://img.shields.io/badge/license-MIT-9CA3AF?style=flat-square)

**A full analytics-engineering pipeline for a simulated SaaS business — from a first-principles financial model in Excel, through a reproducible Python cleaning layer and a PostgreSQL analytics schema, to a 5-page executive Power BI report with 49 DAX measures.**

</div>

---

## Table of contents

- [What this is](#what-this-is)
- [Why it's worth a look](#why-its-worth-a-look)
- [Architecture](#architecture)
- [Repository structure](#repository-structure)
- [The dataset](#the-dataset)
- [The dashboard](#the-dashboard)
- [KPI snapshot (month 60 / Dec‑2028)](#kpi-snapshot-month-60--dec-2028)
- [KPI glossary & formulas](#kpi-glossary--formulas)
- [Analyst's take: what the numbers actually say](#analysts-take-what-the-numbers-actually-say)
- [Getting started](#getting-started)
- [⚠️ Security note (please read before reusing the notebook)](#️-security-note-please-read-before-reusing-the-notebook)
- [Assumptions & limitations](#assumptions--limitations)
- [Roadmap](#roadmap)
- [Author & credits](#author--credits)
- [License](#license)

---

## What this is

This repository is an end-to-end **SaaS metrics analytics pipeline**, built entirely on a *simulated* 5-year (60‑month) financial model rather than a live production system. It exists to demonstrate the full toolchain a data/analytics engineer uses to turn a messy, human-built spreadsheet into a governed, queryable, and visualized metrics layer:

```
Excel financial model  →  Python/pandas cleaning  →  tidy CSV  →  PostgreSQL schema  →  Power BI executive report
```

Every number on every dashboard page traces back to one auditable source: `data/Cleaned_SaaS_Metrics.csv`.

## Why it's worth a look

- **A real ETL problem, not a toy dataset.** The source Excel model stores metrics in a wide, human-readable layout (years across columns, forward-filled category labels, mixed header rows). The notebook documents the actual trial-and-error of parsing it — including two failed parsing attempts before landing on the working row/column offsets — rather than presenting a sanitized final version only.
- **A proper semantic layer, not just charts.** The Power BI report isn't built by dragging raw columns onto visuals — it sits on top of **49 explicit DAX measures**, including derived analytical measures (`Business Health Score`, `Net New MRR Growth %`, `MoM ARR Growth %`) and dynamic narrative measures that generate the on-page insight text.
- **A SQL layer that goes beyond `SELECT *`.** `saas_kpi_analytics.sql` includes staging DDL, multiple analytical views (`view_executive_kpis`, `view_unit_economics`, `view_financial_pnl`), a window-function MoM growth query, a parameterized stored procedure, and an audit trigger — a realistic slice of what a KPI warehouse layer looks like.
- **Honest about its own limitations.** See [Analyst's take](#analysts-take-what-the-numbers-actually-say) — this README does not just report the headline growth numbers; it also surfaces the tension between the model's excellent unit economics and its very weak cash efficiency, because a dashboard that only shows the flattering numbers isn't actually useful to a decision-maker.

## Architecture

![Architecture](docs/images/05_architecture.png)

| Stage | Tool | What happens |
|---|---|---|
| 1. Model | Excel (`SaaS Model vCurrent.xlsx`) | Assumptions-driven 5-year model: subscriber growth, pricing, CAC, payroll, COGS, taxes, and a full 3-statement build (P&L, balance sheet, cash flow) |
| 2. Clean | Jupyter / pandas (`saas_data_cleaning.ipynb`) | Parses each sheet's date row and metric-name column, un-pivots wide → long, concatenates three sheets, de-duplicates |
| 3. Store | CSV → PostgreSQL (`Cleaned_SaaS_Metrics.csv`, `saas_kpi_analytics.sql`) | Loads into a single narrow fact table (`date`, `sheet_source`, `metric_name`, `metric_value`); views pivot it back into wide, analysis-ready shapes |
| 4. Visualize | Power BI (`SaaS_Executive_KPI_Dashboard.pbix`) | Semantic model with 49 DAX measures across 5 report pages, built for a monthly leadership review cadence |

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
    └── images/                         # Charts & diagrams used in this README
```

## The dataset

`Cleaned_SaaS_Metrics.csv` is a single tidy fact table:

| Date | Sheet_Source | Metric | Value |
|---|---|---|---|
| 2024-01-01 | Subscribers & Revenue | New Monthly Subscribers | 90 |
| 2024-01-01 | Subscribers & Revenue | MRR | 4212.5 |
| … | … | … | … |

- **7,315 rows** · **102 distinct metric names** · **60 monthly periods** (Jan 2024 – Dec 2028)
- Sourced from three Excel sheets, each covering a different lens on the business:

| `Sheet_Source` | Focus | Example metrics |
|---|---|---|
| `Subscribers & Revenue` | Top-line growth | New/Active/Churned Subscribers, MRR, ARR, Bookings |
| `Detailed Metrics` | Unit economics | CAC, LTV, ARPU, Payback Period, LTV:CAC, Burn Multiple |
| `Summary Financials` | 3-statement financials | Revenue, COGS, OPEX, Net Income, Balance Sheet, Cash Flow |

This long/narrow shape is a deliberate design choice: it lets one fact table support arbitrarily many metrics without schema changes, at the cost of needing `PIVOT`-style views (see `saas_kpi_analytics.sql`) to get back to an analysis-friendly wide shape — a standard trade-off in metric-warehouse design.

## The dashboard

`SaaS_Executive_KPI_Dashboard.pbix` is a 5-page report (111 visuals total: cards, line/area/column charts, a treemap, a funnel, a waterfall, a pivot table, and navigation buttons) built on Power BI's newer project-based (PBIR) file format:

| Page | Purpose | Notable visuals |
|---|---|---|
| **Executive Summary** | One-screen health check | Gauge (`Business Health Score`), MRR trend, subscriber donut, KPI cards |
| **Revenue & Subscribers** | Growth drivers | Stacked area (plan mix), treemap (revenue by plan), pivot table |
| **Unit Economics** | Acquisition efficiency | CAC/LTV clustered columns, funnel, payback-period area chart |
| **Financials & Cash Flow** | P&L and liquidity | Stacked area (P&L build), **cash-bridge waterfall chart** |
| **About / Info** | Documentation-in-product | Usage guide, metric-definition notes, developer credit |

**On screenshots:** this .pbix uses Power BI's JSON-based report definition, which made it possible to programmatically inventory every page, visual, and the full list of 49 DAX measures without opening the file — but actually **rendering** pixel-accurate screenshots requires Power BI Desktop, which isn't available in this environment. Rather than fabricate a screenshot, the charts below are built directly from the real `Cleaned_SaaS_Metrics.csv` data and styled to match the report's dark theme:

| MRR / ARR growth | Subscriber mix |
|---|---|
| ![MRR ARR](docs/images/01_mrr_arr_growth.png) | ![Subscriber mix](docs/images/02_subscriber_mix.png) |

| LTV vs. CAC by segment | Burn vs. cash balance |
|---|---|
| ![LTV CAC](docs/images/03_ltv_cac.png) | ![Burn vs cash](docs/images/04_profitability.png) |

> 💡 **Recommended:** open the `.pbix` in Power BI Desktop, use *File → Export → PDF* (or a screenshot tool) on each page, and drop the images into `docs/images/` to replace or supplement the ones above with the real report chrome.

### The DAX measure library

A non-exhaustive sample of the 49 measures backing the report (grouped by what they're for):

<details>
<summary><strong>Click to expand the measure inventory</strong></summary>

| Category | Measures |
|---|---|
| Headline KPIs | `Total MRR`, `Total ARR`, `Total Active Subscribers`, `Total Revenue`, `Total Net Income`, `Total OPEX` |
| Growth & momentum | `MoM MRR Growth %`, `MoM ARR Growth %`, `New MRR`, `Churned MRR`, `Net New MRR`, `Net New MRR Growth %`, `New MRR Growth %`, `Churned MRR Growth %` |
| Unit economics | `Blended CAC`, `Blended ARPU`, `SaaS LTV`, `Retention %`, `ARPU` |
| Financial health | `Fin_Gross Margin %`, `Fin_Net Margin %`, `Fin_Monthly Burn Rate`, `Fin_Cash Runway Mos`, `Fin_Total OpEx`, `Net Margin %`, `Gross Profit` |
| Composite / narrative | `Business Health Score`, `Insight 1–4 Text` (dynamic on-page commentary), `*_MoM Label` helper measures for trend arrows |
| Structural | `Plan Revenue Distribution`, `Monthly Plan Revenue`, `Annual Plan Revenue`, `ARR Sublabel`, `MRR Sublabel`, `Net Income Sublabel`, `Subs Sublabel` |

</details>

The cash-flow waterfall page also carries its own small disconnected table (`Cash_Bridge_Table`, defined via `DATATABLE()` in a saved DAX query) — a common technique for waterfall visuals whose steps don't map cleanly onto the main fact table.

## KPI snapshot (month 60 / Dec‑2028)

All figures below are computed directly from `Cleaned_SaaS_Metrics.csv` (not eyeballed from the dashboard), so they're reproducible with a five-line pandas snippet:

| Metric | Month 1 (Jan‑2024) | Month 60 (Dec‑2028) |
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
| Burn Multiple | — | **2.34×** (avg. across all 59 months: **11.5×**) |
| Cash & equivalents | — | **$1,000,000** (modeled floor) |
| Modeled capital required | — | **$21,399,064** (per `Funds to Raise`, triggered around month 11) |

## KPI glossary & formulas

| KPI | Formula | Why it matters |
|---|---|---|
| **MRR** | Sum of monthly-plan revenue + amortized annual-plan revenue | The core recurring-revenue pulse of the business |
| **ARR** | MRR × 12 | Annualized run-rate, used for board/investor reporting |
| **Churn rate** | Churned subscribers ÷ active subscribers (start of period) | How fast the bucket is leaking |
| **ARPU** | MRR ÷ active subscribers | Monetization per account |
| **CAC** | Total sales & marketing spend ÷ new subscribers acquired | Cost to add one customer |
| **LTV** | ARPU ÷ monthly churn rate | Expected revenue per customer over their lifetime |
| **LTV : CAC** | LTV ÷ CAC | Unit-economics efficiency; **>3× is the common SaaS bar for healthy**, this model's blended figure is ~7.8× |
| **CAC payback period** | CAC ÷ (ARPU × gross margin %) | Months to recover acquisition cost; **<12 months is generally considered efficient** |
| **Burn Multiple** | Net cash burned ÷ net new ARR | Capital efficiency of growth; **Bessemer's benchmark: <1× is exceptional, 1–1.5× good, >2× needs work** |
| **Gross margin** | (Revenue − COGS) ÷ Revenue | Underlying product economics before OPEX |
| **Net margin** | Net income ÷ Revenue | Bottom-line profitability |
| **Runway** | Cash balance ÷ monthly net burn | Months until cash runs out at current burn |

## Analyst's take: what the numbers actually say

It would be easy to headline this project with "$4.2M MRR, $50M ARR, 7.8× LTV:CAC" and stop there. That would also be an incomplete — and slightly misleading — read of the model. A few things worth being direct about:

1. **The unit economics are genuinely excellent, and the overall business is not yet efficient.** A 7.8× blended LTV:CAC and a 1.6-month payback period are strong by any SaaS benchmark. But the **Burn Multiple averages ~11.5× across the model's life** (only converging to a still-elevated ~2.3× by month 60). That combination is realistic and common: acquiring customers cheaply doesn't offset a cost base (payroll, facilities, G&A) that's scaling ahead of revenue in the assumptions.
2. **The model never reaches profitability inside its own 5-year window.** Net margin improves from roughly −2,015% in month 1 to −31% in month 60 — a real and steep improvement — but it is still burning cash at the end of the projection, not breaking even. Any narrative built on top of this dataset should say "on a clear path to breakeven," not "profitable."
3. **The ending cash balance ($1,000,000) is a modeling assumption, not an emergent result.** It matches the `Assumptions` sheet's `End of Period Cash Balance` input exactly, and the model separately computes `Funds to Raise` (~$21.4M) to plug the gap. In other words, the model **assumes** a capital raise happens rather than deriving whether one is affordable — worth knowing before quoting the fundraise figure as a forecast.
4. **Subscriber growth is uncapped compounding, not an S-curve.** Monthly-plan subscribers grow at a constant 10% and annual-plan at 7% every month for 60 months with no saturation, competitive response, or market-size ceiling modeled. That's a completely normal simplification for a template financial model, but it means the later-period numbers (e.g., 147,786 active subscribers) describe "what happens if the input growth rate never decays," not a market-sized forecast.

None of this makes the project less useful — if anything, it's a better analytics-engineering showcase *because* the dashboard is built to surface these tensions (the Unit Economics and Financials & Cash Flow pages are separate for exactly this reason) rather than blending everything into one deceptively rosy headline number.

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

Open `pbix/SaaS_Executive_KPI_Dashboard.pbix` in **Power BI Desktop** and point the semantic model at your PostgreSQL instance (or the CSV directly) via *Transform data → Data source settings*.

## ⚠️ Security note (please read before reusing the notebook)

`saas_data_cleaning.ipynb` (final cell) currently contains a **hardcoded, plaintext PostgreSQL password** used to build the SQLAlchemy connection string. Before pushing this repo anywhere public:

- [ ] Remove the hardcoded credential and rotate the corresponding PostgreSQL password immediately, since it's no longer safe to use even privately.
- [ ] Replace it with an environment variable (`os.environ[...]`) or a `.env` file loaded via `python-dotenv`, and add `.env` to `.gitignore`.
- [ ] Double-check the notebook's Git history — if it was ever committed with the password inline, the password is compromised even after the file is edited, and needs rotating rather than just fixing the file going forward.

This is a common and easy-to-miss mistake in notebook-driven workflows (cells get re-run and re-saved with output/state baked in), which is exactly why it's called out explicitly here rather than silently fixed.

## Assumptions & limitations

- **This is a simulated financial model, not real company data.** Every figure traces back to hand-set assumptions (retention rates, pricing, hiring plan, CAC) in the Excel `Assumptions` sheet — useful for demonstrating the analytics pipeline, not for benchmarking an actual business.
- **Growth is a fixed compounding rate, not a fitted or capped forecast** (see point 4 in the [Analyst's take](#analysts-take-what-the-numbers-actually-say)).
- **The Power BI semantic model's exact data source wasn't recoverable from static inspection** — the `.pbix` stores its connection details inside a compressed VertiPaq data model rather than plain text, so this README documents the *measures and structure* (extracted from the human-readable report JSON) but can't confirm at a glance whether the live report points at the CSV, PostgreSQL, or the Excel workbook. Check *Transform data → Data source settings* in Power BI Desktop to confirm before pointing it at a new environment.
- **Currency, locale, and tax assumptions are US-centric defaults** (21% effective tax rate, USD pricing) and aren't parameterized per region.

## Roadmap

- [ ] Parameterize the Excel model's key assumptions (growth rate, retention, CAC) so scenario/sensitivity analysis doesn't require editing formulas directly
- [ ] Add a `dbt` layer between PostgreSQL and Power BI for tested, version-controlled transformations in place of the current SQL views
- [ ] Add automated data-quality checks (e.g., `great_expectations` or simple pandas assertions) to the notebook to catch parsing regressions if the Excel layout changes
- [ ] Replace the notebook's manual re-run steps with a small CLI/script entry point (`python -m etl.clean`) for repeatable execution outside Jupyter
- [ ] Add real exported Power BI screenshots to `docs/images/` alongside the reconstructed charts

## Author & credits

Built by **Khusi Khanra** — [github.com/khusikhanra](https://github.com/khusikhanra) (credit as embedded in the dashboard's *About* page; update this section if that attribution needs to change).

## License

This project is provided under the [MIT License](https://opensource.org/licenses/MIT) — feel free to fork, adapt, and reuse the pipeline structure for your own portfolio or teaching purposes. The underlying financial figures are entirely synthetic.
