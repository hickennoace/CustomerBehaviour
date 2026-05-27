# Craftiverse Customer Behaviour

I pulled the player data from a Minecraft network called Craftiverse (Factions and Skyblock) and dug into where revenue actually comes from, and more importantly, where it leaks. 580 players, 19 store products, one SQLite DB. The headline finding ended up being that the abandoned-cart pile is larger than the revenue pile, which set the direction for most of the analysis.

Stack: Python, SQLite, pandas, matplotlib + seaborn for charts, Power BI for the dashboard.

## The headline numbers

| | |
|---|---:|
| Players | 580 |
| Paying players | 407 (70.2%) |
| Non-paying players | 173 (29.8%) |
| Actual revenue | $9,912.50 |
| Abandoned cart value | $13,125.00 |
| Revenue capture rate | 43.1% |
| Avg spend per payer | $24.36 |
| Store products | 19 |

So the abandoned-cart pile ($13k) is bigger than the revenue pile ($10k). If even 30% of those carts converted, that's a ~40% revenue lift with zero new players acquired. That single number drove the rest of the analysis.

The 70.2% conversion rate also jumped out at me. The typical e-commerce range is 20-30%, so the people who reach the cart are pre-sold. The problem isn't interest, it's the checkout itself.

## Files

| File | What it is |
|---|---|
| `behaviour.ipynb` | Main analysis notebook. Runs top to bottom: load DB, parse the JSON columns into fact tables, run the SQL KPIs, generate the Part A-E charts, export CSVs for Power BI. |
| `kpi_cheatsheet.sql` | The six KPIs as plain SQL if you'd rather skip the notebook. |
| `craftiverse.db` | The SQLite source. Two tables: `players_data` (580 rows) and `store_products` (19 rows). |
| `dim_players.csv` | One row per player. Power BI loads this. |
| `fact_purchases.csv` | One row per purchased item, exploded out of the JSON column. |
| `fact_abandoned_carts.csv` | One row per abandoned cart item, same shape as purchases. |
| `Customer Behaviour PowerBI/` | The 3-page Power BI dashboard. |
| `part_a_...png` through `part_e_...png` | Chart exports from the notebook. |

## Database schema

`players_data`:

| Column | Type | Notes |
|---|---|---|
| id | INTEGER | Primary key |
| username | TEXT | In-game name |
| rank | TEXT | Default / VIP / MVP / Legend |
| first_join_date | DATE | First login |
| total_playtime_hours | REAL | Cumulative hours |
| total_spent_dollars | REAL | Lifetime spend USD |
| total_votes | INTEGER | Server-listing votes |
| webstore_visits | INTEGER | Visits to the store |
| last_purchase_date | DATE | Most recent purchase |
| total_transactions | INTEGER | Completed orders |
| cart_abandonments | INTEGER | Abandoned sessions |
| purchased_items_list | JSON | Array of `{item, price}` |
| cart_items_list | JSON | Array of `{item, price}` currently in cart |

`store_products`:

| Column | Type | Notes |
|---|---|---|
| id | INTEGER | Primary key |
| category | TEXT | Ranks / Perks / Crate keys / Sellwands / Gkits / Tags |
| product_name | TEXT | Display name |
| price | REAL | USD |

The two JSON columns are the awkward bit. I unnest them once at the top of the notebook into two flat fact tables and never look at the raw JSON again.

## The 6 KPIs

| # | KPI | Result |
|---|---|---|
| 1 | Top product by units | Fix all - 40 units |
| 2 | Top category by revenue | Perks - $3,355 |
| 3 | Most abandoned item | Tier4 Sellwand - abandoned 66 times |
| 4 | Conversion rate (paying vs not) | 70.2% (industry avg 20-30%) |
| 5 | Top spenders | UltraBane and FireMaster, $100 each |
| 6 | Top revenue rank | Default - $6,072.50 total |

KPI #6 looks weird at first - Default rank brings in the most total revenue. But that's volume: there are way more Default-rank players (482 of them) than any other rank. Per player, Legend wins easily.

## Part A - player psychology

How long does it take a new player to make their first purchase?

Approach: filter to paying users with a `last_purchase_date`, compute `days_to_purchase = last_purchase_date - first_join_date`, bucket into segments. One caveat: the schema stores `last_purchase_date`, not `first_purchase_date`. So for single-transaction users the gap is exact, for multi-transaction users it's an upper bound. The fast-converters bucket is therefore more reliable than the slow tail.

Findings:

- Same-day converters are the largest single group. Excitement is highest on Day 0.
- ~70% of all eventual buyers convert inside 30 days. After 90 days it drops off a cliff.
- Legend-rank players have the shortest median time to first purchase, which reads to me as them already knowing what they want before they even join.
- A small "more than 1 year" tail still exists but is hard to monetise organically.

What to do about it:
- 15% Welcome Bonus, expires 48h after account creation, catches the same-day group.
- Auto nudge at Day 7 and Day 28 for store-visitors with zero purchases.
- Tease Legend-rank content early since Legend players convert fastest.
- One annual "Comeback Event" (double-vote rewards + discounted ranks) is enough to monetise the dormant tail.

## Part B - targeted segments

Two segments I can move with one well-aimed action:

**Sleeper VIPs.** Default-rank players in the top 30% for both votes AND playtime but with zero spend. They love the server, they vote, they grind, but they've never opened the wallet.

Identified by: `rank = 'Default' AND total_spent = 0 AND votes >= P70 AND playtime >= P70`.

Action: personalised Discord DM with a "Loyal Player Bundle" (VIP Rank + Legendary Crate Key) at 40% off, valid 72 hours. Personalisation and exclusivity beat broadcast discounts for this group.

**Cart abandoners.** Players who repeatedly add to cart and don't check out:

| Rank | Total abandonments | Avg per player |
|---|---:|---:|
| Default | 1,061 | 2.20 |
| Legend | (highest avg) | 2.44 |
| MVP | - | - |
| VIP | - | - |

Default players generate the most total abandonments because of sheer volume. Legend players have the highest per-player rate.

Action: Default players get a broad "you left X behind" nudge 24h after abandonment. Legend players get exclusivity framing instead ("Only 3 left at this price" or "Legend-exclusive bundle"). Repeat abandoners (4+ events) are a micro-segment small enough for individual staff outreach.

## Part C - server hype

Do votes and playtime correlate with spending?

Method: Pearson correlation plus an OLS regression for `total_votes` and `total_playtime_hours` against `total_spent_dollars`, paying players only.

| Metric | Direction | p-value | Significant? |
|---|---|---|---|
| Total votes -> revenue | positive | < 0.05 | Yes |
| Total playtime -> revenue | weaker positive | < 0.05 | Yes |

So both correlate, but votes correlate harder. The way I read this is that voting is a proxy for being invested in the server's success, and that mindset overlaps with willingness to spend. Playtime is also positive but weaker because heavy grinders prefer earning over buying.

The actionable takeaways:
- Vote drive weekends are cheap (1-2 staff hours) and they pay back.
- Sweet-spot is mid-range playtime (50-300 hrs). The very-high playtime grinders aren't great targets.
- Top 10 Legend spenders are obvious brand-ambassador candidates: custom tag, private Discord, done.

## Part D - financials

The scale of the cart-abandonment leak.

- Actual revenue = `SUM(total_spent_dollars)` = $9,912.50.
- Abandoned cart value = sum of every `price` in every `cart_items_list` = $13,125.00.
- Revenue capture rate = Actual / (Actual + Lost) = 43.1%.

Recovery math at different conversion rates:

| Cart recovery rate | Annual lift |
|---:|---:|
| 30% | +$3,937 |
| 50% | +$6,562 |

The 3-step recovery drip I propose in the notebook:

| Day | Message | Goal |
|---|---|---|
| 1 | "You left [Tier4 Sellwand] behind. It boosts income 40% automatically." | Re-engage with value |
| 3 | "Only 5 slots at this price. 67 players bought this week." | Scarcity before any discount |
| 7 | "One-time 10% off. Code COMEBACK10, expires in 24h." | Close with an incentive |

Iron rule: never lead with the discount. Players who respond to scarcity don't need one, and early discounts train players to wait for a deal every time.

## Part E - growth and new products

Where should new SKUs go to maximise ARPU?

Method: explode `purchased_items_list` into a flat fact table, join with `store_products`, get category-level revenue, units, unique-buyer counts. Revenue per unique buyer is my ARPU proxy.

Category performance:

| Category | Revenue | Units | Revenue per buyer |
|---|---:|---:|---|
| Perks | $3,355 | 145 | highest ARPU |
| Ranks | $2,830 | 99 | high |
| Sellwands | $1,235 | 150 | mid |
| Crate keys | $1,212.50 | 134 | mid |
| Gkits | $1,110 | 111 | mid |
| Tags | $170 | 34 | lowest |

Gaps I'd fill:

| Category | New product | Price | Why |
|---|---|---:|---|
| Ranks | Elite Rank (above Legend) | $80 | Raises the ceiling, pulls Legend buyers up |
| Perks | XP Booster (2x XP, 7 days) | $12 | Weekly repurchase, recurring |
| Gkits | Skyblock / Factions Starter Kit | $8-12 | Game-mode specificity lifts conversion |
| Crate keys | Seasonal Key (Summer/Halloween) | $7.50 | Fills the $5 to $10 gap |
| Tags | Custom Tag (staff-reviewed) | $15 | Near-zero cost, high perceived value |
| Sellwands | Tier5 Sellwand (1.5x bonus) | $25 | Natural upsell for 38 Tier4 owners |

## Revenue potential summary

If most of the above lands, the revenue picture roughly doubles:

| Strategy | Annual uplift |
|---|---:|
| Cart recovery (30% conversion) | +$3,937 |
| Sleeper VIP activation | +$800 - $1,500 |
| Welcome flow | +$800 - $1,200 |
| Bundle strategy (AOV x1.5) | +$1,500 - $2,500 |
| Elite Rank (15 sales x $80) | +$1,200 |
| Seasonal Keys + new products | +$700 - $1,000 |
| Total potential | +$8,937 - $11,337 |
| Current revenue | $9,912.50 |
| Full potential (~2x) | ~$19,000 - $21,000 |

## Running it

```bash
pip install -r requirements.txt
```

Then open `behaviour.ipynb` in Jupyter and run top to bottom. The notebook:

1. Connects to `craftiverse.db` and loads both tables.
2. Parses both JSON columns into flat fact tables.
3. Runs all six KPI queries from `kpi_cheatsheet.sql`.
4. Generates the Part A-E charts and saves them as PNGs.
5. Exports `dim_players.csv`, `fact_purchases.csv`, `fact_abandoned_carts.csv` for Power BI.

For the Power BI side: install Power BI Desktop (June 2025 or later), open `Customer Behaviour PowerBI/CustomerBehaviour.pbip`. Two visuals (the correlation heatmap and the abandonment funnel) run Python inside Power BI, so you also need `matplotlib seaborn pandas numpy` installed and the interpreter set in File -> Options -> Python scripting.

The Power BI report has three pages:

| Page | Thesis | Key visual |
|---|---|---|
| Executive Summary | Revenue vs abandonment gap | Revenue-by-category bars, whale table, trend line |
| Player Psychology | Engagement weakly predicts spend | Python correlation heatmap, playtime-vs-spend scatter |
| Lost Revenue Analysis | $13k sits in abandoned carts | Python funnel by rank, top abandoned items |

## Screenshots

| | |
|:---:|:---:|
| ![Player Psychology](part_a_player_psychology.png) | ![Targeted Segments](part_b_targeted_segments.png) |
| ![Server Hype](part_c_server_hype.png) | ![Financials](part_d_financials.png) |
| ![Growth](part_e_growth.png) | |
