-- Six KPI queries for craftiverse.db.
-- purchased_items_list and cart_items_list are JSON arrays of {"item", "price"}.
-- Pull product names with json_extract(je.value, '$.item').


-- 1. Product popularity (units sold)
SELECT
    json_extract(je.value, '$.item')    AS product_name,
    COUNT(*)                            AS total_units_sold
FROM players_data pd,
     json_each(pd.purchased_items_list) AS je
WHERE pd.purchased_items_list IS NOT NULL
GROUP BY json_extract(je.value, '$.item')
ORDER BY total_units_sold DESC;


-- 2. Category revenue
SELECT
    sp.category,
    COUNT(*)                            AS units_sold,
    ROUND(SUM(sp.price), 2)             AS total_revenue_dollars
FROM players_data pd,
     json_each(pd.purchased_items_list) AS je
JOIN store_products sp
    ON sp.product_name = json_extract(je.value, '$.item')
WHERE pd.purchased_items_list IS NOT NULL
GROUP BY sp.category
ORDER BY total_revenue_dollars DESC;


-- 3. Top 5 abandoned items
SELECT
    json_extract(je.value, '$.item')    AS abandoned_product,
    COUNT(*)                            AS times_abandoned
FROM players_data pd,
     json_each(pd.cart_items_list) AS je
WHERE pd.cart_items_list IS NOT NULL
GROUP BY json_extract(je.value, '$.item')
ORDER BY times_abandoned DESC
LIMIT 5;


-- 4. Paying vs non-paying split
SELECT
    CASE WHEN total_spent_dollars > 0 THEN 'Paying' ELSE 'Non-Paying' END AS user_segment,
    COUNT(*)                                                              AS player_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)                    AS pct_of_total
FROM players_data
GROUP BY user_segment
ORDER BY player_count DESC;


-- 5. Top 10 spenders
SELECT
    ROW_NUMBER() OVER (ORDER BY total_spent_dollars DESC)  AS rank_position,
    username,
    rank,
    ROUND(total_spent_dollars, 2)                          AS total_spent_dollars,
    total_playtime_hours,
    total_votes,
    total_transactions,
    last_purchase_date
FROM players_data
ORDER BY total_spent_dollars DESC
LIMIT 10;


-- 6. Spend by rank
SELECT
    rank,
    COUNT(*)                            AS player_count,
    ROUND(AVG(total_spent_dollars), 2)  AS avg_spent_dollars,
    ROUND(MIN(total_spent_dollars), 2)  AS min_spent_dollars,
    ROUND(MAX(total_spent_dollars), 2)  AS max_spent_dollars,
    ROUND(SUM(total_spent_dollars), 2)  AS total_revenue_from_rank
FROM players_data
GROUP BY rank
ORDER BY avg_spent_dollars DESC;
