# Key Findings: D2C Electronics E-Commerce Analysis

**Project:** Customer Churn & Delivery Performance Analysis
**Tools:** SQL Server (data cleaning & analysis) → Power BI (visualization)
**Dataset:** 1,200 customers, 6,000 orders, 5,363 deliveries, 722 support tickets, 3,240 days of marketing spend

---

## Headline Metrics

| Metric | Value |
|---|---|
| Total Revenue | ₹69.89M |
| Profit | ₹20.23M |
| Profit Margin | 29% |
| Total Customers | 1,200 |
| On-Time Delivery Rate | 56% |
| Average Delay (when late) | 1.24 days |

---

## Finding 1: Delivery delays are systemic, not partner-specific
Every delivery partner showed a late rate between 36–38% — a narrow gap between the best (Shadowfax) and worst (BlueDart) performer. This points to a broader fulfillment or SLA-setting issue across the business rather than one underperforming courier. However, when late, delays are typically mild (avg. 1.24 days) — the problem is frequency, not severity.

## Finding 2: Late delivery does not meaningfully predict churn
Customers with late deliveries showed a churn rate of 38.6%, compared to 41.5% for on-time deliveries — a negligible difference. This is a genuine, useful finding: the data does not support the common assumption that delivery speed is a primary driver of customer retention in this business.

## Finding 3: Organic Search and Referral are the most efficient acquisition channels
Organic Search has the lowest Customer Acquisition Cost (₹18,652) combined with strong revenue per customer. Referral shows the highest revenue per customer (₹64,208) at a reasonable CAC. Email is the weakest channel — comparable spend to other channels, but the lowest revenue per customer (₹47,874) — a strong candidate for budget reallocation.

## Finding 4: Support resolution speed has minimal impact on repeat purchases
Customers with fast (<24h) ticket resolution averaged 6.04 orders versus 5.99 for slow (>24h) resolution — a negligible difference, suggesting resolution speed alone isn't a strong retention lever in this dataset.

## Finding 5: Revenue is evenly distributed across gender, including "Unknown"
Revenue per gender group ranged narrowly between ₹2.08–2.41 Cr, with "Unknown" (customers who didn't disclose gender) still contributing a meaningful share of revenue — showing that demographic-based personalization would miss a real segment of paying customers.

## Finding 6: Clear revenue seasonality
Revenue peaks between April–September and drops significantly in the October–March window, suggesting a seasonal buying pattern worth investigating further (e.g. festival timing, product launch cycles, or weather-driven demand for certain categories).

---

## Data Quality Notes
- `order_value` does not always exactly equal `price × quantity`; the dataset does not include a discount/coupon field to explain the small variance. `order_value` was treated as the source of truth for actual revenue.
- `age` (~55%), `gender` (small %), and `satisfaction_score` (~18%) contain intentional missing values, reflecting realistic optional-field non-response common in real customer data.
- `actual_delivery_date` is blank for orders still in transit or lost — these were excluded from on-time/late percentage calculations to avoid skewing results.

---

## Recommendations
1. Investigate root cause of the ~44% late delivery rate across all partners — likely an internal fulfillment/SLA issue rather than a single courier problem.
2. Reallocate a portion of Email marketing budget toward Organic Search and Referral programs.
3. Do not prioritize delivery speed improvements as a churn-reduction strategy based on this data alone — investigate other churn drivers (e.g. price sensitivity, product category, competitor activity).
4. Consider building a discount/coupon tracking field into future data collection to fully explain revenue variances.
