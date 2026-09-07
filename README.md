# RFM Customer Segmentation with SQL Server

A portfolio project that analyzes customer purchasing behavior in the **AdventureWorks2022** database using the **RFM (Recency, Frequency, Monetary)** framework and SQL Server.

The goal is to transform transactional sales data into actionable customer segments that can support retention, re-engagement, and targeted marketing decisions.

---

## Project Overview

This project builds an end-to-end RFM customer segmentation workflow in **Microsoft SQL Server**.

For each customer, the analysis calculates:

- **Recency** — number of days since the customer's most recent purchase
- **Frequency** — number of distinct orders placed by the customer
- **Monetary** — total purchase value based on `SalesOrderDetail.LineTotal`

The raw RFM values are then converted into 1–5 scores using the SQL Server `NTILE(5)` window function and combined to classify customers into four business-oriented segments:

- **High Value**
- **Medium Value**
- **Low Value**
- **At Risk**

---

## Business Question

How can transactional sales data be used to identify:

- the most valuable customers,
- customers with growth potential,
- low-value customers,
- and historically valuable customers who may be at risk of churn?

The final segmentation is designed to help prioritize marketing and customer-retention efforts.

---

## Dataset

**Database:** AdventureWorks2022  
**Platform:** Microsoft SQL Server

The analysis primarily uses two sales tables:

| Table | Main Columns Used | Purpose |
|---|---|---|
| `Sales.SalesOrderHeader` | `SalesOrderID`, `OrderDate`, `CustomerID` | Recency, Frequency, customer/order information |
| `Sales.SalesOrderDetail` | `SalesOrderID`, `LineTotal` | Monetary value calculation |

The two tables are joined using `SalesOrderID`.

---

## RFM Methodology

### Recency

Recency is calculated as the number of days between the customer's latest order and a reference date.

Because AdventureWorks is a historical dataset, the reference date is defined dynamically as:

```sql
DATEADD(DAY, 1, MAX(OrderDate))
```

For this dataset, the latest order date is **2014-06-30**, so the effective reference date is **2014-07-01**.

Lower Recency values are better.

### Frequency

Frequency is calculated as the number of distinct orders placed by each customer:

```sql
COUNT(DISTINCT SalesOrderID)
```

Using `DISTINCT` prevents order counts from being inflated when an order contains multiple detail rows.

Higher Frequency values are better.

### Monetary

Monetary value is calculated as the sum of product line values for each customer:

```sql
SUM(LineTotal)
```

Higher Monetary values are better.

---

## RFM Scoring with Window Functions

The project uses `NTILE(5)` to assign scores from 1 to 5.

```sql
NTILE(5) OVER (
    ORDER BY Recency DESC, CustomerID
) AS R_Score,

NTILE(5) OVER (
    ORDER BY Frequency ASC, CustomerID
) AS F_Score,

NTILE(5) OVER (
    ORDER BY Monetary ASC, CustomerID
) AS M_Score
```

### Scoring Direction

| Metric | Better Value | Score Direction |
|---|---|---|
| Recency | Lower | Lower Recency → Higher score |
| Frequency | Higher | Higher Frequency → Higher score |
| Monetary | Higher | Higher Monetary → Higher score |

`CustomerID` is included as a secondary sort key to keep the results deterministic when customers have identical RFM values.

---

## Customer Segmentation Logic

The three RFM scores are combined into:

- **RFM Code** — example: `543`
- **RFM Total Score** — sum of the three scores, ranging from 3 to 15

The project applies the following segmentation rules:

| Segment | Rule | Interpretation |
|---|---|---|
| **At Risk** | `R_Score <= 2 AND F_Score >= 4 AND M_Score >= 4` | Historically valuable customers who have not purchased recently |
| **High Value** | `RFM_TotalScore >= 12` | Strong overall customer value |
| **Medium Value** | `RFM_TotalScore >= 8` | Moderate value with growth potential |
| **Low Value** | Otherwise | Lower engagement and purchase value |

The **At Risk** condition is evaluated first so that valuable but inactive customers are not incorrectly classified as High Value or Medium Value.

---

## Final Results

The analysis segmented **19,119 customers**.

| Segment | Customers | Avg Recency | Avg Frequency | Avg Monetary | Total Monetary | Monetary Share |
|---|---:|---:|---:|---:|---:|---:|
| **High Value** | 4,006 | 93.57 | 3.02 | 20,242.22 | 81,090,325.66 | **73.82%** |
| **At Risk** | 2,003 | 310.19 | 2.26 | 10,615.06 | 21,261,961.92 | **19.36%** |
| **Medium Value** | 6,557 | 164.13 | 1.26 | 902.43 | 5,917,246.74 | **5.39%** |
| **Low Value** | 6,553 | 241.80 | 1.01 | 240.63 | 1,576,847.08 | **1.44%** |

> Percentages sum to 100.01% because of rounding.

---

## Key Business Insights

- **High Value customers represent about 20.95% of customers but generate 73.82% of total monetary value.**
- **At Risk customers represent about 10.48% of customers and still account for 19.36% of historical monetary value.**
- **High Value + At Risk customers together account for 93.18% of total monetary value.**
- Medium Value and Low Value customers represent a large share of the customer base but contribute a much smaller share of total monetary value.
- The results suggest that retention and re-engagement strategies should focus primarily on High Value and At Risk customers.

---

## Recommended Marketing Actions

### High Value

- Loyalty programs
- VIP or exclusive offers
- Cross-selling and up-selling
- Personalized retention campaigns

### At Risk

- Win-back campaigns
- Personalized re-engagement offers
- Targeted discounts
- Investigation of possible churn drivers

### Medium Value

- Encourage repeat purchases
- Cross-sell related products
- Use staged promotions
- Increase purchase frequency

### Low Value

- Use low-cost automated campaigns
- Promote simple repeat-purchase offers
- Avoid excessive acquisition or retention spending per customer

---

## SQL Techniques Demonstrated

This project demonstrates practical use of:

- Common Table Expressions (`CTE`)
- `INNER JOIN`
- `GROUP BY`
- `COUNT(DISTINCT ...)`
- `SUM`
- `AVG`
- `MAX`
- `DATEDIFF`
- `DATEADD`
- Window Functions
- `NTILE`
- `CASE`
- Temporary Tables
- Customer-level aggregation
- Business-oriented SQL analysis

---

## Project Structure

```text
rfm-customer-segmentation-sql-server/
│
├── README.md
├── sql/
│   └── rfm_customer_segmentation.sql
│
└── report/
    └── RFM_Customer_Segmentation_Portfolio_Report.pdf
```

---

## How to Run

1. Install or restore the **AdventureWorks2022** sample database in SQL Server.
2. Open the SQL script in **SQL Server Management Studio (SSMS)**.
3. Make sure the active database is `AdventureWorks2022`.
4. Execute the script located at:

```text
sql/rfm_customer_segmentation.sql
```

The script returns:

1. customer-level RFM scores and assigned segment,
2. segment-level summary statistics and monetary contribution.

---

## Portfolio Report

A polished English portfolio report with methodology, results, interpretation, and business recommendations is included here:

**[View the Portfolio Report](report/RFM_Customer_Segmentation_Portfolio_Report.pdf)**

---

## Limitations

- RFM focuses only on historical purchasing behavior.
- It does not include product profitability, customer acquisition cost, demographics, satisfaction, or product category behavior.
- `NTILE` can split identical metric values across adjacent groups at bucket boundaries.
- Segment thresholds are analytical rules defined for this project and can be adjusted based on business objectives.

---

## Conclusion

This project demonstrates how SQL Server can be used to transform transactional sales data into meaningful customer segments.

By combining RFM analysis, window functions, customer-level aggregation, and business interpretation, the project identifies both the most valuable customers and historically valuable customers who may require re-engagement.

The analysis shows that a relatively small portion of customers generates the majority of monetary value, making targeted retention and reactivation strategies more effective than treating all customers equally.

---

## Author

**Aref Navabi**

Data Science & AI Learner  
SQL Server | Data Analysis | Customer Analytics
