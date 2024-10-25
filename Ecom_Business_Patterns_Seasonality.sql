USE mavenfuzzyfactory;


-- Business patterns using yearly and monthly sessions and orders volumes
SELECT 
	YEAR(website_sessions.created_at) AS YEAR,
	MONTH(website_sessions.created_at) AS MONTH,
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
	COUNT(DISTINCT orders.order_id) AS orders,
	COUNT(DISTINCT orders.order_id) / COUNT(DISTINCT website_sessions.website_session_id) AS sess_ord_conv_rt
FROM
	website_sessions
LEFT JOIN
	orders
ON
	website_sessions.website_session_id = orders.website_session_id
WHERE
	website_sessions.created_at <= '2012-12-31'
GROUP BY
	year, month
ORDER BY
	year, month ASC;

-- Weekly trending sessions and order volumes
SELECT  
	MIN(DATE(website_sessions.created_at)) as week_start_date,
	COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
	COUNT(DISTINCT orders.order_id) AS orders
FROM
	website_sessions
LEFT JOIN
	orders
ON
	website_sessions.website_session_id = orders.website_session_id
WHERE
	website_sessions.created_at <= '2012-12-31'
GROUP BY
	WEEK(website_sessions.created_at)
ORDER BY 
	1 ASC;


-- Day of week and hour of day website session volume
select 
	hour_of_day,
	ROUND(AVG(sessions),2) AS avg_session_volume,
	AVG(CASE WHEN Day_of_week = 0 THEN sessions ELSE NULL END) AS mon,
	AVG(CASE WHEN Day_of_week = 1 THEN sessions ELSE NULL END) AS Tue,
	AVG(CASE WHEN Day_of_week = 2 THEN sessions ELSE NULL END) AS Wed,
    AVG(CASE WHEN Day_of_week = 3 THEN sessions ELSE NULL END) AS Thu,
    AVG(CASE WHEN Day_of_week = 4 THEN sessions ELSE NULL END) AS  Fri,
    AVG(CASE WHEN Day_of_week = 5 THEN sessions ELSE NULL END) AS Sat,
    AVG(CASE WHEN Day_of_week = 6 THEN sessions ELSE NULL END) AS Sun
FROM
(SELECT 
	DATE(created_at) AS DATE,
	WEEKDAY(created_at) AS Day_of_week,
	HOUR(created_at) AS hour_of_day,
	COUNT(website_session_id) AS sessions

FROM 
	website_sessions
WHERE 
	created_at > '2012-09-15' AND created_at < '2012-10-15'
GROUP BY
	1,2,3) AS daily_hourly_sessions
GROUP BY
	hour_of_day;

SELECT 
	DATE (created_at) AS DATE,
	WEEKDAY(created_at) AS Day_of_week,
	HOUR(created_at) AS hour_of_day,
	COUNT(website_session_id) AS sessions

FROM 
	website_sessions
WHERE 
	created_at > '2012-09-15' AND created_at < '2012-10-15'
GROUP BY
	1,2,3;