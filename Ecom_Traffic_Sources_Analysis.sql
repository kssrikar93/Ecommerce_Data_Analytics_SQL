use mavenfuzzyfactory;
-- Real world Ecommerce data

select * from website_sessions;

-- Finding top traffic sources
SELECT
	utm_source,
	utm_campaign,
	http_referer,
COUNT(DISTINCT website_session_id) AS website_sessions
FROM 
	website_sessions
WHERE
	created_at <= '2012-04-12'
GROUP BY
	utm_source,
	utm_campaign,
	http_referer	
ORDER BY
	website_sessions DESC;
-- Gsearch nonbrand seems like the major traffic source for the company.


-- Calculating conversion rate from sessions to orders
SELECT 

	COUNT(DISTINCT ws.website_session_id) AS sessions,
	COUNT(DISTINCT o.order_id) AS orders,
	COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rate
FROM
	website_sessions ws
LEFT JOIN
	orders o
ON
	ws.website_session_id = o.website_session_id
WHERE
	ws.utm_source = 'gsearch' AND
    ws.utm_campaign = 'nonbrand' AND
    ws.created_at <='2012-04-14';
-- Actual 'session to order converison rate' is 2.8%


-- Calculating Session volume per week
SELECT  
	DATE(created_at) AS date_start,
	COUNT(DISTINCT website_session_id) AS sessions

FROM 
	website_sessions
WHERE 
	created_at < '2012-05-10' AND
	utm_source = 'gsearch' AND
	utm_campaign = 'nonbrand'
GROUP BY WEEK(created_at)
ORDER BY date_start ASC;


-- looking at sessions, orders and session_to_order conversion rate by device type
SELECT
	ws. device_type,
    COUNT(DISTINCT ws.website_session_id) AS sessions,
    COUNT(DISTINCT o.order_id) AS orders,
    COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) AS conv_rate
    
FROM
	website_sessions ws
LEFT JOIN
	orders o
ON
	ws.website_session_id = o.website_session_id
WHERE 
	ws.created_at < '2012-05-11'
	AND ws.utm_source = 'gsearch'
	AND ws.utm_campaign = 'nonbrand'
GROUP BY
	ws.device_type;
-- 3.7% of sessions on desktop converted to orders whereas a mere 0.96% of sessions on mobile converted to orders


-- Weekly trended sessison volume analysis by device type
SELECT 
	DATE(created_at) AS week_start_date,
	COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mob_sessions,
	COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS dtop_sessions

FROM 
	website_sessions

WHERE 
	created_at BETWEEN '2012-04-15' AND '2012-06-09'
	AND utm_source = 'gsearch'
	AND utm_campaign = 'nonbrand'
GROUP BY 
	WEEK(created_at)
ORDER BY 
	week_start_date ASC;

