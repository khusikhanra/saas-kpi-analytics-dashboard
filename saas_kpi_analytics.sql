DROP TABLE IF EXISTS public.saas_metrics;


CREATE TABLE public.saas_metrics (
    date DATE,
    sheet_source VARCHAR(100),
    metric_name VARCHAR(255),
    metric_value NUMERIC(15, 4)
);


CREATE VIEW view_monthly_revenue AS
SELECT 
    "Date",
    MAX(CASE WHEN "Metric" = 'MRR' THEN "Value" ELSE 0 END) AS mrr,
    MAX(CASE WHEN "Metric" = 'Monthly Plan Revenue' THEN "Value" ELSE 0 END) AS monthly_plan_rev,
    MAX(CASE WHEN "Metric" = 'Annual Plan Monthly Revenue' THEN "Value" ELSE 0 END) AS annual_plan_rev
FROM saas_metrics
GROUP BY "Date";


CREATE VIEW view_subscriber_health AS
SELECT 
    "Date",
    MAX(CASE WHEN "Metric" = 'Total Active Subscribers' THEN "Value" ELSE 0 END) AS active_subscribers,
    MAX(CASE WHEN "Metric" = '(+) New Subscribers' THEN "Value" ELSE 0 END) AS new_subscribers,
    MAX(CASE WHEN "Metric" = '(–) Churned Subscribers' THEN "Value" ELSE 0 END) AS churned_subscribers
FROM saas_metrics
GROUP BY "Date";


ALTER TABLE saas_metrics RENAME COLUMN "Date" TO date;
ALTER TABLE saas_metrics RENAME COLUMN "Sheet_Source" TO sheet_source;
ALTER TABLE saas_metrics RENAME COLUMN "Metric" TO metric_name;
ALTER TABLE saas_metrics RENAME COLUMN "Value" TO metric_value;



DROP VIEW IF EXISTS view_executive_kpis;


CREATE VIEW view_executive_kpis AS
SELECT 
    date,
    MAX(CASE WHEN metric_name = 'MRR' THEN metric_value ELSE 0 END) AS mrr,
    MAX(CASE WHEN metric_name = 'MRR' THEN metric_value ELSE 0 END) * 12 AS arr,
    MAX(CASE WHEN metric_name = 'Total Active Subscribers' THEN metric_value ELSE 0 END) AS active_subscribers,
    MAX(CASE WHEN metric_name = '(+) New Subscribers' THEN metric_value ELSE 0 END) AS new_subscribers,
    MAX(CASE WHEN metric_name = '(–) Churned Subscribers' THEN metric_value ELSE 0 END) AS churned_subscribers,
    ROUND(
        (
            (MAX(CASE WHEN metric_name = '(–) Churned Subscribers' THEN metric_value ELSE 0 END) / 
            NULLIF(MAX(CASE WHEN metric_name = 'Total Active Subscribers' THEN metric_value ELSE 0 END), 0)) * 100
        )::numeric, 
        2
    ) AS churn_rate_pct,
    ROUND(
        (
            MAX(CASE WHEN metric_name = 'MRR' THEN metric_value ELSE 0 END) / 
            NULLIF(MAX(CASE WHEN metric_name = 'Total Active Subscribers' THEN metric_value ELSE 0 END), 0)
        )::numeric, 
        2
    ) AS arpu
FROM saas_metrics
GROUP BY date;


SELECT * FROM view_executive_kpis ORDER BY date DESC LIMIT 5;


WITH mrr_lag AS (
    SELECT 
        date,
        metric_value AS current_mrr,
        LAG(metric_value, 1) OVER (ORDER BY date) AS prev_mrr
    FROM saas_metrics
    WHERE metric_name = 'MRR'
)
SELECT 
    date,
    current_mrr,
    prev_mrr,
    ROUND(((current_mrr - prev_mrr) / NULLIF(prev_mrr, 0) * 100)::numeric, 2) AS mom_growth_pct
FROM mrr_lag;


SELECT 
    date,
    metric_value AS mrr,
    SUM(metric_value) OVER (ORDER BY date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_mrr
FROM saas_metrics
WHERE metric_name = 'MRR';


CREATE INDEX idx_saas_metric_date ON saas_metrics (metric_name, date);
CREATE INDEX idx_saas_date ON saas_metrics (date);



SELECT 
    metric_name, 
    COUNT(*) AS total_records, 
    COUNT(metric_value) AS non_null_records,
    MIN(date) AS start_date,
    MAX(date) AS end_date
FROM saas_metrics
GROUP BY metric_name
ORDER BY total_records DESC;


CREATE OR REPLACE PROCEDURE sp_get_yearly_kpi_summary(p_year INT)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT 
        EXTRACT(YEAR FROM date) AS year,
        ROUND(AVG(CASE WHEN metric_name = 'MRR' THEN metric_value END)::numeric, 2) AS avg_monthly_mrr,
        MAX(CASE WHEN metric_name = 'MRR' THEN metric_value END) * 12 AS ending_arr,
        SUM(CASE WHEN metric_name = '(+) New Subscribers' THEN metric_value ELSE 0 END) AS total_new_subscribers,
        SUM(CASE WHEN metric_name = '(–) Churned Subscribers' THEN metric_value ELSE 0 END) AS total_churned_subscribers
    FROM saas_metrics
    WHERE EXTRACT(YEAR FROM date) = p_year
    GROUP BY EXTRACT(YEAR FROM date);
END;
$$;


CREATE OR REPLACE VIEW view_unit_economics AS
WITH monthly_stats AS (
    SELECT 
        date,
        MAX(CASE WHEN metric_name = 'MRR' THEN metric_value ELSE 0 END) AS mrr,
        MAX(CASE WHEN metric_name = 'Total Active Subscribers' THEN metric_value ELSE 0 END) AS active_subs,
        MAX(CASE WHEN metric_name = '(–) Churned Subscribers' THEN metric_value ELSE 0 END) AS churned_subs
    FROM saas_metrics
    GROUP BY date
),
metrics_calculated AS (
    SELECT 
        date,
        mrr,
        active_subs,
        (mrr / NULLIF(active_subs, 0)) AS arpu,
        ((churned_subs / NULLIF(active_subs, 0))) AS churn_rate
    FROM monthly_stats
)
SELECT 
    date,
    ROUND(arpu::numeric, 2) AS arpu,
    ROUND((churn_rate * 100)::numeric, 2) AS churn_rate_pct,
    -- LTV Formula = ARPU / Monthly Churn Rate
    ROUND((arpu / NULLIF(churn_rate, 0))::numeric, 2) AS estimated_ltv_usd
FROM metrics_calculated
ORDER BY date ASC;


CREATE OR REPLACE VIEW view_financial_pnl AS
SELECT 
    date,
    MAX(CASE WHEN metric_name = 'Revenue (MRR)' THEN metric_value ELSE 0 END) AS revenue,
    MAX(CASE WHEN metric_name = 'COGS' THEN metric_value ELSE 0 END) AS cogs,
    MAX(CASE WHEN metric_name = 'Gross Profit' THEN metric_value ELSE 0 END) AS gross_profit,
    MAX(CASE WHEN metric_name = 'OPEX' THEN metric_value ELSE 0 END) AS opex,
    MAX(CASE WHEN metric_name = 'Net Income' THEN metric_value ELSE 0 END) AS net_income
FROM saas_metrics
WHERE sheet_source = 'Summary Financials'
GROUP BY date
ORDER BY date ASC;



CREATE TABLE saas_metrics_audit (
    log_id SERIAL PRIMARY KEY,
    action_type VARCHAR(20),
    changed_by VARCHAR(50),
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metric_name VARCHAR(255),
    old_value NUMERIC(15, 4),
    new_value NUMERIC(15, 4)
);


CREATE OR REPLACE FUNCTION fn_audit_saas_metrics()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO saas_metrics_audit(action_type, changed_by, metric_name, old_value, new_value)
    VALUES (TG_OP, CURRENT_USER, NEW.metric_name, OLD.metric_value, NEW.metric_value);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_saas_metrics_audit
AFTER UPDATE ON saas_metrics
FOR EACH ROW EXECUTE FUNCTION fn_audit_saas_metrics();


