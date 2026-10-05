CREATE DATABASE Final_project;
UPDATE customers SET Gender = NULL WHERE Gender='';
UPDATE customers SET Age = NULL WHERE Age='';
ALTER TABLE Customers MODIFY AGE INT NULL;

SELECT * FROM transactions;

CREATE TABLE Transactions
(date_new DATE,
Id_check INT,
Id_client INT,
Count_products DECIMAL(10,3),
Sum_payment DECIMAL(10,2));


LOAD DATA INFILE "C:\\ProgramData\\MySQL\\MySQL Server 9.7\\Uploads\\transactions.final.csv"
INTO TABLE Transactions
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(date_new, id_check, ID_client, Count_products, Sum_payment);

SHOW VARIABLES LIKE 'secure_file_priv';

#список клиентов с непрерывной историей за год
#Средний чек за год;
#Средняя сумма покупок в месяц;
#Общее количество операций за период.

SELECT Id_client,
    SUM(Sum_payment) / COUNT(DISTINCT Id_check) AS avg_receipt,
    SUM(Sum_payment) / 12.0 AS avg_monthly_spend,
    COUNT(DISTINCT Id_check) AS total_transactions
FROM Transactions
WHERE date_new >= '2015-06-01' 
  AND date_new < '2016-06-01'
GROUP BY ID_client
HAVING COUNT(DISTINCT DATE_FORMAT(date_new, '%Y-%m')) = 12;

#средняя сумма чека в месяц;
SELECT LAST_DAY(date_new) AS month_end,
    SUM(Sum_payment) / COUNT(DISTINCT Id_check) AS avg_check_monthly
FROM Transactions
WHERE date_new >= '2015-06-01' 
  AND date_new < '2016-06-01'
GROUP BY LAST_DAY(date_new)
ORDER BY month_end;

#среднее количество операций в месяц
SELECT COUNT(DISTINCT Id_check) / 12.0 AS avg_operations_per_month
FROM Transactions
WHERE date_new >= '2015-06-01' 
  AND date_new < '2016-06-01';
  
  #среднее количество клиентов, которые совершали операции
  SELECT YEAR(date_new) AS tran_year,
  MONTH(date_new) AS tran_month,
    COUNT(DISTINCT ID_client) AS active_clients_count
FROM Transactions
WHERE date_new >= '2015-06-01' 
  AND date_new < '2016-06-01'
GROUP BY YEAR(date_new), MONTH(date_new)
ORDER BY tran_year, tran_month;

#доля от общего количества операций за год
SELECT YEAR(date_new) AS tran_year,
MONTH(date_new) AS tran_month,
    COUNT(DISTINCT Id_check) * 100.0 / SUM(COUNT(DISTINCT Id_check)) OVER() AS ops_share_pct
FROM Transactions
WHERE date_new >= '2015-06-01' 
  AND date_new < '2016-06-01'
GROUP BY YEAR(date_new), MONTH(date_new)
ORDER BY tran_year, tran_month;

#доля в месяц от общей суммы операций
SELECT YEAR(date_new) AS tran_year,
MONTH(date_new) AS tran_month,
    SUM(Sum_payment) * 100.0 / (
	SELECT SUM(Sum_payment) 
	FROM Transactions 
	WHERE date_new >= '2015-06-01'
    AND date_new < '2016-06-01'
    ) AS sum_share_pct
FROM Transactions
WHERE date_new >= '2015-06-01' 
AND date_new < '2016-06-01'
GROUP BY YEAR(date_new), MONTH(date_new)
ORDER BY tran_year, tran_month;

# % соотношение M/F/NA в каждом месяце с их долей затрат
SELECT YEAR(t.date_new) AS tran_year,
MONTH(t.date_new) AS tran_month,
    COUNT(DISTINCT CASE WHEN c.Gender = 'M' 
    THEN t.ID_client END) * 100.0 
    / COUNT(DISTINCT t.ID_client) AS male_client_pct,
    COUNT(DISTINCT CASE WHEN c.Gender = 'F' 
    THEN t.ID_client END) * 100.0 
    / COUNT(DISTINCT t.ID_client) AS female_client_pct,
    COUNT(DISTINCT CASE WHEN c.Gender IS NULL OR c.Gender NOT IN ('M', 'F') 
    THEN t.ID_client END) * 100.0 
    / COUNT(DISTINCT t.ID_client) AS na_client_pct,

    SUM(CASE WHEN c.Gender = 'M' 
    THEN t.Sum_payment ELSE 0 END) * 100.0 / SUM(t.Sum_payment) AS male_spend_pct,
    SUM(CASE WHEN c.Gender = 'F' 
    THEN t.Sum_payment ELSE 0 END) * 100.0 / SUM(t.Sum_payment) AS female_spend_pct,
    SUM(CASE WHEN c.Gender IS NULL OR c.Gender NOT IN ('M', 'F') 
    THEN t.Sum_payment ELSE 0 END) * 100.0 / SUM(t.Sum_payment) AS na_spend_pct

FROM Transactions t
LEFT JOIN Customers c 
ON t.ID_client = c.Id_client
WHERE t.date_new >= '2015-06-01' 
AND t.date_new < '2016-06-01'
GROUP BY YEAR(t.date_new), MONTH(t.date_new)
ORDER BY tran_year, tran_month;


SELECT * FROM customers;

#озрастные группы клиентов с шагом 10 лет
#с параметрами сумма и количество операций за весь период
SELECT 
	CASE 
        WHEN c.Age < 20 THEN '<20'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
        WHEN c.Age >= 60 THEN '60+'
        ELSE 'NA'
    END AS age_group,
    COUNT(t.Id_check) AS total_operations,
    SUM(t.Sum_payment) AS total_sum,
    
    COUNT(t.Id_check) * 100.0 / (
        SELECT COUNT(Id_check) 
        FROM Transactions 
        WHERE date_new >= '2015-06-01' 
        AND date_new < '2016-06-01'
    ) AS ops_share_pct,
    
    SUM(t.Sum_payment) * 100.0 / (
        SELECT SUM(Sum_payment) 
        FROM Transactions 
        WHERE date_new >= '2015-06-01' 
        AND date_new < '2016-06-01'
    ) AS sum_share_pct

FROM Transactions t
LEFT JOIN Customers c 
ON t.ID_client = c.Id_client
WHERE t.date_new >= '2015-06-01' 
  AND t.date_new < '2016-06-01'
GROUP BY age_group
ORDER BY age_group;

#поквартально - средние показатели и %
SELECT YEAR(t.date_new) AS tran_year,
QUARTER(t.date_new) AS tran_quarter,
    CASE 
        WHEN c.Age < 20 THEN '<20'
        WHEN c.Age BETWEEN 20 AND 29 THEN '20-29'
        WHEN c.Age BETWEEN 30 AND 39 THEN '30-39'
        WHEN c.Age BETWEEN 40 AND 49 THEN '40-49'
        WHEN c.Age BETWEEN 50 AND 59 THEN '50-59'
        WHEN c.Age >= 60 THEN '60+'
        ELSE 'NA'
    END AS age_group,
    COUNT(t.Id_check) * 100.0 / SUM(COUNT(t.Id_check)) 
    OVER(PARTITION BY YEAR(t.date_new), QUARTER(t.date_new)) AS ops_share_pct,
    SUM(t.Sum_payment) * 100.0 / SUM(SUM(t.Sum_payment)) 
    OVER(PARTITION BY YEAR(t.date_new), QUARTER(t.date_new)) AS sum_share_pct,
    
    AVG(t.Sum_payment) AS avg_check

FROM Transactions t
LEFT JOIN Customers c 
ON t.ID_client = c.Id_client
WHERE t.date_new >= '2015-06-01' 
  AND t.date_new < '2016-06-01'
GROUP BY YEAR(t.date_new), QUARTER(t.date_new), age_group
ORDER BY tran_year, tran_quarter, age_group;
