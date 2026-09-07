/*
===============================================================
Project: RFM Customer Segmentation
Database: AdventureWorks2022
Platform: Microsoft SQL Server

Objective:
Analyze customer purchasing behavior using Recency, Frequency,
and Monetary (RFM) metrics and segment customers into:
- High Value
- Medium Value
- Low Value
- At Risk

Techniques Used:
- CTEs
- INNER JOIN
- Aggregate Functions
- DATEDIFF
- Window Functions
- NTILE
- CASE Expressions
===============================================================
*/

USE AdventureWorks2022;
GO

SET NOCOUNT ON;

/*--------------------------------------------------------------
    1. Remove temporary table if it already exists
--------------------------------------------------------------*/

IF OBJECT_ID('tempdb..#CustomerSegments') IS NOT NULL
    DROP TABLE #CustomerSegments;


/*--------------------------------------------------------------
    2. Define the reference date

    Reference Date = One day after the latest order date
--------------------------------------------------------------*/

DECLARE @ReferenceDate DATE;

SELECT
    @ReferenceDate = DATEADD(DAY, 1, MAX(OrderDate))
FROM Sales.SalesOrderHeader;


/*--------------------------------------------------------------
    3. Calculate Recency and Frequency
--------------------------------------------------------------*/

;WITH RF AS
(
    SELECT
        CustomerID,

        DATEDIFF(
            DAY,
            MAX(OrderDate),
            @ReferenceDate
        ) AS Recency,

        COUNT(DISTINCT SalesOrderID) AS Frequency

    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
),


/*--------------------------------------------------------------
    4. Calculate Monetary Value
--------------------------------------------------------------*/

M AS
(
    SELECT
        h.CustomerID,
        SUM(d.LineTotal) AS Monetary

    FROM Sales.SalesOrderHeader AS h

    INNER JOIN Sales.SalesOrderDetail AS d
        ON h.SalesOrderID = d.SalesOrderID

    GROUP BY h.CustomerID
),


/*--------------------------------------------------------------
    5. Combine R, F and M values
--------------------------------------------------------------*/

RFM AS
(
    SELECT
        RF.CustomerID,
        RF.Recency,
        RF.Frequency,
        M.Monetary

    FROM RF

    INNER JOIN M
        ON RF.CustomerID = M.CustomerID
),


/*--------------------------------------------------------------
    6. RFM Scoring using NTILE
--------------------------------------------------------------*/

RFM_Scores AS
(
    SELECT
        CustomerID,
        Recency,
        Frequency,
        Monetary,

        NTILE(5) OVER
        (
            ORDER BY Recency DESC, CustomerID
        ) AS R_Score,

        NTILE(5) OVER
        (
            ORDER BY Frequency ASC, CustomerID
        ) AS F_Score,

        NTILE(5) OVER
        (
            ORDER BY Monetary ASC, CustomerID
        ) AS M_Score

    FROM RFM
),


/*--------------------------------------------------------------
    7. Calculate combined RFM scores
--------------------------------------------------------------*/

RFM_Final AS
(
    SELECT
        CustomerID,
        Recency,
        Frequency,
        Monetary,

        R_Score,
        F_Score,
        M_Score,

        CONCAT(
            R_Score,
            F_Score,
            M_Score
        ) AS RFM_Code,

        R_Score
        + F_Score
        + M_Score AS RFM_TotalScore

    FROM RFM_Scores
)


/*--------------------------------------------------------------
    8. Customer Segmentation
--------------------------------------------------------------*/

SELECT
    CustomerID,
    Recency,
    Frequency,
    Monetary,

    R_Score,
    F_Score,
    M_Score,

    RFM_Code,
    RFM_TotalScore,

    CASE

        WHEN R_Score <= 2
             AND F_Score >= 4
             AND M_Score >= 4
            THEN 'At Risk'

        WHEN RFM_TotalScore >= 12
            THEN 'High Value'

        WHEN RFM_TotalScore >= 8
            THEN 'Medium Value'

        ELSE 'Low Value'

    END AS CustomerSegment

INTO #CustomerSegments

FROM RFM_Final;


/*--------------------------------------------------------------
    9. Detailed RFM result for each customer
--------------------------------------------------------------*/

SELECT
    CustomerID,
    Recency,
    Frequency,
    Monetary,
    R_Score,
    F_Score,
    M_Score,
    RFM_Code,
    RFM_TotalScore,
    CustomerSegment

FROM #CustomerSegments

ORDER BY CustomerID;


/*--------------------------------------------------------------
    10. Segment-level analysis
--------------------------------------------------------------*/

SELECT
    CustomerSegment,

    COUNT(*) AS CustomerCount,

    AVG(
        CAST(Recency AS DECIMAL(10,2))
    ) AS AvgRecency,

    AVG(
        CAST(Frequency AS DECIMAL(10,2))
    ) AS AvgFrequency,

    AVG(Monetary) AS AvgMonetary,

    SUM(Monetary) AS TotalMonetary,

    CAST(
        100.0 * SUM(Monetary)
        /
        (SELECT SUM(Monetary)
         FROM #CustomerSegments)

        AS DECIMAL(6,2)
    ) AS MonetarySharePercent

FROM #CustomerSegments

GROUP BY CustomerSegment

ORDER BY TotalMonetary DESC;

/*--------------------------------------------------------------
    11. Clean up temporary table
--------------------------------------------------------------*/

DROP TABLE #CustomerSegments;