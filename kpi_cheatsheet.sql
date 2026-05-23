-- ============================================================
-- Craftiverse KPI Cheat Sheet
-- Database: craftiverse.db
-- NOTE: purchased_items_list and cart_items_list are JSON arrays
-- of objects shaped {"item": "...", "price": ...}.
-- Use json_extract(je.value, '$.item') to pull the product name.
-- ============================================================


-- 1. PRODUCT POPULARITY (SALES VOLUME)
-- Counts how many times each specific product was purchased
-- across all players by unnesting their purchased_items_list.
SELECT
    json_extract(je.value, '$.item')    AS product_name,
    COUNT(*)                            AS total_units_sold
FROM players_data pd,
     json_each(pd.purchased_items_list) AS je
WHERE pd.purchased_items_list IS NOT NULL
GROUP BY json_extract(je.value, '$.item')
ORDER BY total_units_sold DESC;


-- 2. CATEGORY REVENUE
-- Unnests purchased_items_list, joins each item name to
-- store_products to resolve its category and price, then
-- aggregates total revenue and units sold per category.
SELECT
    sp.category,
    COUNT(*)                            AS units_sold,
    ROUND(SUM(sp.price), 2)            AS total_revenue_dollars
FROM players_data pd,
     json_each(pd.purchased_items_list) AS je
JOIN store_products sp
    ON sp.product_name = json_extract(je.value, '$.item')
WHERE pd.purchased_items_list IS NOT NULL
GROUP BY sp.category
ORDER BY total_revenue_dollars DESC;


-- 3. CART ABANDONMENT LEADERBOARD (TOP 5)
-- Counts how many times each product appears across all
-- players' cart_items_list without a corresponding purchase.
SELECT
    json_extract(je.value, '$.item')    AS abandoned_product,
    COUNT(*)                            AS times_abandoned
FROM players_data pd,
     json_each(pd.cart_items_list) AS je
WHERE pd.cart_items_list IS NOT NULL
GROUP BY json_extract(je.value, '$.item')
ORDER BY times_abandoned DESC
LIMIT 5;


-- 4. USER CONVERSION OVERVIEW
-- Splits the player base into paying (spend > 0) vs.
-- non-paying and shows count and percentage of each segment.
SELECT
    CASE
        WHEN total_spent_dollars > 0 THEN 'Paying'
        ELSE 'Non-Paying'
    END                                                         AS user_segment,
    COUNT(*)                                                    AS player_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)         AS pct_of_total
FROM players_data
GROUP BY user_segment
ORDER BY player_count DESC;


-- 5. TOP 10 SPENDERS ("WHALES")
-- Ranks all players by lifetime spend, surfacing playtime
-- and vote count as engagement quality signals alongside spend.
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


-- 6. RANK VALUE (AVG SPEND PER RANK)
-- Groups players by their current server rank and computes
-- spend statistics per tier to evaluate rank upgrade incentives.
SELECT
    rank,
    COUNT(*)                            AS player_count,
    ROUND(AVG(total_spent_dollars), 2) AS avg_spent_dollars,
    ROUND(MIN(total_spent_dollars), 2) AS min_spent_dollars,
    ROUND(MAX(total_spent_dollars), 2) AS max_spent_dollars,
    ROUND(SUM(total_spent_dollars), 2) AS total_revenue_from_rank
FROM players_data
GROUP BY rank
ORDER BY avg_spent_dollars DESC;
