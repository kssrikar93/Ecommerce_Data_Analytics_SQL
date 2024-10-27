USE mavenfuzzyfactory;

-- select * from website_pageviews
-- limit 10;

-- Analysing website performance

-- Most viewed website pages ranked by session volume
SELECT 
	pageview_url,
    COUNT(DISTINCT website_pageview_id) AS views
    
FROM
	website_pageviews
WHERE
	created_at <= '2012-09-06'
GROUP BY 
	pageview_url
ORDER BY 
	views DESC;
    
-- Finding top entry pages
SELECT 
	website_sessions. website_session_id,
	MIN(website_pageviews.website_pageview_id) AS landing_page
FROM
	website_sessions
LEFT JOIN 
	website_pageviews
ON
	website_sessions.website_session_id = website_pageviews.website_session_id
WHERE 
	website_sessions.created_at < '2012-06-12'
GROUP BY
	website_sessions.website_session_id ;

-- Creating a temporary table that stores landing page ids per session
CREATE TEMPORARY TABLE landing_pages
SELECT 
	website_sessions. website_session_id,
	MIN(website_pageviews.website_pageview_id) as landing_page

FROM
	website_sessions
LEFT JOIN
	website_pageviews
ON
	website_sessions.website_session_id = website_pageviews.website_session_id
WHERE 
	website_sessions.created_at < '2012-06-12'
GROUP BY
	website_sessions.website_session_id ;
    
SELECT 
	website_pageviews.pageview_url,
	COUNT(DISTINCT landing_pages.website_session_id) AS sessions
-- landing_pages.landing_page,
FROM 
	landing_pages
LEFT JOIN
	website_pageviews
ON
	landing_pages.landing_page = website_pageviews.website_pageview_id
GROUP BY
	website_pageviews.pageview_url;
-- All the traffic has been landing on the '/home' page

-- Calculating bounce rates. Sessions bouncing off the home page
SELECT
	COUNT(website_session_id) AS sessions,
	COUNT(DISTINCT CASE WHEN pageviews = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
	COUNT(DISTINCT CASE WHEN pageviews = 1 then website_session_id ELSE NULL END) / COUNT(website_session_id) AS bounce_rate
FROM
(SELECT
website_sessions.website_session_id,
COUNT(DISTINCT website_pageviews.website_pageview_id) AS pageviews 
FROM 
	website_sessions
LEFT JOIN
	website_pageviews
ON
	website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_sessions.created_at < '2012-06-14'
GROUP BY website_sessions.website_session_id) A
;
-- 59% of sessions landing on '/home' page are bounced sessions


-- Comparing bounce rates for '/home' and '/lander-1' pages

-- Step 1: Identifying the first session landing on '/lander-1'
SELECT 
	MIN(website_sessions.website_session_id)
FROM
	website_sessions
LEFT JOIN
	website_pageviews
ON
	website_sessions.website_session_id = website_pageviews. website_session_id
WHERE 
	website_pageviews.pageview_url = '/lander-1';
-- 11683 is the first session landing on 'lander-1'

 -- select * from website_pageviews
 -- where website_session_id = 11683;

-- step 2: identifying the landing pageview id for the relevant sessions
SELECT 
	website_sessions.website_session_id,
	MIN(website_pageviews.website_pageview_id) AS landing_page
FROM
	website_sessions
LEFT JOIN
	website_pageviews
ON
	website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_sessions.website_session_id > 11683
	AND website_sessions.created_at < '2012-07-28'
GROUP BY
	1;

-- Step 3: creating temporary table 'landing_pageview_ids' using the above information
CREATE TEMPORARY TABLE landing_pageview_ids
	website_sessions.website_session_id,
	MIN(website_pageviews.website_pageview_id) AS landing_page
FROM 
	website_sessions
LEFT JOIN
	website_pageviews
ON
	website_sessions.website_session_id = website_pageviews.website_session_id
WHERE
	website_sessions.website_session_id > 11683
	AND website_sessions.created_at < '2012-07-28'
GROUP BY
	1;

-- select * from landing_pageview_ids;

-- Step 4: identifying sessions landed on home and lander

SELECT 
	landing_pageview_ids.website_session_id,
	landing_pageview_ids.landing_page,
	website_pageviews.pageview_url

FROM 
	landing_pageview_ids
LEFT JOIN 
	website_pageviews
ON
	landing_pageview_ids.landing_page = website_pageviews.website_pageview_id
WHERE 
	website_pageviews.pageview_url IN ('/home', '/lander-1');

-- Step 4: create temporary table home_lander_sessions
CREATE TEMPORARY TABLE h_l_sessions
SELECT
	landing_pageview_ids.website_session_id,
	landing_pageview_ids.landing_page,
	website_pageviews.pageview_url

FROM
	landing_pageview_ids
LEFT JOIN
	website_pageviews
ON
	landing_pageview_ids.landing_page = website_pageviews.website_pageview_id
WHERE
	website_pageviews.pageview_url IN ('/home', '/lander-1');


-- creating another temporary table Bounced_sessions
CREATE TEMPORARY TABLE bounced_sessions_1
SELECT
	h_l_sessions.website_session_id AS bounced_session,
	COUNT(DISTINCT website_pageviews.website_pageview_id) AS pages_viewed

FROM
	M h_l_sessions
LEFT JOIN
	website_pageviews
ON
	h_l_sessions.website_session_id = website_pageviews.website_session_id
GROUP BY
	1
HAVING
	pages_viewed = 1;

-- select * from h_l_sessions;


SELECT 
	pageview_url,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT bounced_session) AS bounced_sessions,
    COUNT(DISTINCT bounced_session) / COUNT(DISTINCT website_session_id) AS bounce_rate
FROM
(SELECT 
	h_l_sessions.pageview_url,
    h_l_sessions.website_session_id,
	bounced_sessions_1.bounced_session
FROM
	h_l_sessions
LEFT JOIN
	bounced_sessions_1
ON
	h_l_sessions.website_session_id = bounced_sessions_1.bounced_session) B
GROUP BY 
	pageview_url;
-- Bounce rates for both landing pages is rouhly the same around 53%


-- BUILDING CONVERSION FUNNEL
SELECT DISTINCT pageview_url FROM website_pageviews;

-- Identifying the funnel after landing on products page :  /the-original-mr-fuzzy, /cart, /shipping, /billing,  /thank-you-for-your-order

SELECT
	website_sessions.website_session_id,
    website_pageviews.website_pageview_id,
    website_pageviews.pageview_url,
	CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS to_products,
    CASE WHEN website_pageviews.pageview_url = 'the-original-mr-fuzzy' THEN 1 ELSE 0 END AS to_fuzzy,
    CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS to_cart,
    CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS to_shipping,
    CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS to_billing,
    CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS to_thankyou
FROM
	website_sessions
LEFT JOIN
    website_pageviews
ON
    website_sessions.website_session_id = website_pageviews.website_session_id
WHERE 
	website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
    AND website_sessions.created_at BETWEEN '2012-09-15' AND '2012-10-15'
ORDER BY
	website_sessions.website_session_id,
    website_pageviews.website_pageview_id;


SELECT 
	website_session_id,
    MAX(to_products) AS made_it_products,
    MAX(to_fuzzy) AS made_it_fuzzy,
    MAX(to_cart) AS made_it_cart,
    MAX(to_shipping) AS made_it_shipping,
    MAX(to_billing) AS made_it_billing,
    MAX(to_thankyou) AS made_it_thankyou
FROM
(SELECT
	website_sessions.website_session_id,
    website_pageviews.website_pageview_id,
    website_pageviews.pageview_url,
	CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS to_products,
    CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS to_fuzzy,
	CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS to_cart,
    CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS to_shipping,
    CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS to_billing,
    CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS to_thankyou
FROM
	website_sessions
LEFT JOIN
    website_pageviews
ON
    website_sessions.website_session_id = website_pageviews.website_session_id
WHERE 
	website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
    AND website_sessions.created_at BETWEEN '2012-09-15' AND '2012-10-15'
ORDER BY
	website_sessions.website_session_id,
    website_pageviews.website_pageview_id) AS A
GROUP BY
	website_session_id
    ;

CREATE TEMPORARY TABLE conversion_sessions_1
SELECT 
	website_session_id,
    MAX(to_products) AS made_it_products,
    MAX(to_fuzzy) AS made_it_fuzzy,
    MAX(to_cart) AS made_it_cart,
    MAX(to_shipping) AS made_it_shipping,
    MAX(to_billing) AS made_it_billing,
    MAX(to_thankyou) AS made_it_thankyou
FROM
(SELECT
	website_sessions.website_session_id,
    website_pageviews.website_pageview_id,
    website_pageviews.pageview_url,
	CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS to_products,
    CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS to_fuzzy,
     CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS to_cart,
    CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS to_shipping,
    CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS to_billing,
    CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS to_thankyou
FROM
	website_sessions
LEFT JOIN
    website_pageviews
ON
    website_sessions.website_session_id = website_pageviews.website_session_id
WHERE 
	website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
    AND website_sessions.created_at BETWEEN '2012-09-15' AND '2012-10-15'
ORDER BY
	website_sessions.website_session_id,
    website_pageviews.website_pageview_id) AS A
GROUP BY
	website_session_id
    ;
    
SELECT * FROM conversion_sessions_1; -- QA

SELECT 
	COUNT(DISTINCT website_session_id) as sessions,
	COUNT(DISTINCT CASE WHEN made_it_products = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(DISTINCT CASE WHEN made_it_fuzzy = 1 THEN website_session_id ELSE NULL END) AS to_fuzzy,
    COUNT(DISTINCT CASE WHEN made_it_cart = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN made_it_shipping = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN made_it_billing = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN made_it_thankyou = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM
	conversion_sessions_1;






















