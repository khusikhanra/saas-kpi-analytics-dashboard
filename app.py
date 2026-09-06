import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as px_go

st.set_page_config(
    page_title="SaaS Executive KPI Dashboard",
    page_icon="📊",
    layout="wide"
)

# Load Cleaned Data
@st.cache_data
def load_data():
    df = pd.read_csv("Cleaned_SaaS_Metrics.csv")
    df['Date'] = pd.to_datetime(df['Date'])
    return df

df = load_data()

# Sidebar Filters
st.sidebar.header(" Filter Options")
years = sorted(df['Date'].dt.year.unique())
selected_year = st.sidebar.multiselect("Select Years", options=years, default=years)

# Filter Data
filtered_df = df[df['Date'].dt.year.isin(selected_year)]

st.title("📊 SaaS Revenue & Retention Executive Dashboard")
st.markdown("---")

# 1. KPI Cards Row
col1, col2, col3, col4 = st.columns(4)

mrr_df = filtered_df[filtered_df['Metric'] == 'MRR']
latest_mrr = mrr_df.iloc[-1]['Value'] if not mrr_df.empty else 0
latest_arr = latest_mrr * 12

subs_df = filtered_df[filtered_df['Metric'] == 'Total Active Subscribers']
latest_subs = subs_df.iloc[-1]['Value'] if not subs_df.empty else 0
arpu = (latest_mrr / latest_subs) if latest_subs > 0 else 0

col1.metric("Current MRR", f"${latest_mrr:,.0f}")
col2.metric("Current ARR", f"${latest_arr:,.0f}")
col3.metric("Active Subscribers", f"{int(latest_subs):,}")
col4.metric("ARPU (Avg Rev / User)", f"${arpu:,.2f}")

st.markdown("###")

# 2. Charts Row 1: MRR Growth & Revenue Breakdown
chart_col1, chart_col2 = st.columns([2, 1])

with chart_col1:
    st.subheader("Monthly Recurring Revenue (MRR) Trend")
    fig_mrr = px.line(mrr_df, x='Date', y='Value', markers=True, title="MRR Trajectory Over Time")
    fig_mrr.update_traces(line_color='#1f77b4', line_width=3)
    st.plotly_chart(fig_mrr, use_container_width=True)

with chart_col2:
    st.subheader("Revenue Split by Plan")
    rev_metrics = ['Monthly Plan Revenue', 'Annual Plan Monthly Revenue']
    plan_df = filtered_df[filtered_df['Metric'].isin(rev_metrics)].groupby('Metric')['Value'].sum().reset_index()
    fig_pie = px.pie(plan_df, values='Value', names='Metric', hole=0.4, color_discrete_sequence=px.colors.qualitative.Pastel)
    st.plotly_chart(fig_pie, use_container_width=True)

# 3. Charts Row 2: Customer Acquisition vs Churn
st.subheader("Customer Growth: New vs Churned Subscribers")
sub_metrics = ['(+) New Subscribers', '(–) Churned Subscribers']
sub_flow_df = filtered_df[filtered_df['Metric'].isin(sub_metrics)]
fig_bar = px.bar(sub_flow_df, x='Date', y='Value', color='Metric', barmode='group',
                 color_discrete_map={'(+) New Subscribers': '#2ca02c', '(–) Churned Subscribers': '#d62728'})
st.plotly_chart(fig_bar, use_container_width=True)

# 4. Raw Data Preview Table
with st.expander(" Data Explorer Table"):
    st.dataframe(filtered_df, use_container_width=True)
