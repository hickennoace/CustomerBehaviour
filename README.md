# Craftiverse Customer Behaviour

I pulled the player data from a Minecraft network (Craftiverse - Factions and Skyblock) and dug into where the money actually comes from and, more interestingly, where it leaks out. The dataset is 580 players in a SQLite DB plus a webstore product table.

Stack: Python, SQLite, pandas, matplotlib/seaborn, Power BI.

## The headline numbers

| | |
|---|---:|
| Players | 580 |
| Paying players | 407 (70.2%) |
| Actual revenue | $9,912.50 |
| Abandoned cart value | $13,125.00 |
| Revenue capture rate | 43.1% |

So the abandoned-cart pile is bigger than the revenue pile. That single fact ended up driving most of the analysis - if I could recover even a third of the abandoned carts, that's a ~40% revenue lift with zero new players acquired.

## What's in here

- `behaviour.ipynb` - main analysis notebook. Runs end to end: connects to `craftiverse.db`, parses out the JSON purchase/cart columns into flat fact tables, runs the SQL KPIs, generates the five Part A-E charts, and exports the CSVs that feed Power BI.
- `kpi_cheatsheet.sql` - the six KPIs as plain SQL if you'd rather skip the notebook.
- `craftiverse.db` - the SQLite source (two tables: `players_data` and `store_products`).
- `dim_players.csv`, `fact_purchases.csv`, `fact_abandoned_carts.csv` - the exports that Power BI consumes.
- `Customer Behaviour PowerBI/` - the 3-page Power BI dashboard built on those CSVs.
- `part_a_player_psychology.png` ... `part_e_growth.png` - the chart outputs.

## The 6 KPIs

| # | KPI | Result |
|---|---|---|
| 1 | Top product (units) | Fix all - 40 units |
| 2 | Top category (revenue) | Perks - $3,355 |
| 3 | Most abandoned item | Tier4 Sellwand - 66 times |
| 4 | Conversion rate | 70.2% (industry avg is 20-30%) |
| 5 | Top spenders | UltraBane and FireMaster at $100 each |
| 6 | Top revenue rank | Default - $6,072.50 |

The conversion rate jumped out at me. 70% is well above the typical 20-30% e-commerce range, which means the players who reach the cart at all are already pre-sold. The problem isn't interest - it's the checkout itself.

## The five parts of the analysis

**A. Player psychology.** When does a new player first buy? Same-day converters are the biggest single group, and ~70% of all eventual buyers convert inside 30 days. After 90 days it tails off hard. So the obvious play is a Day 0-7 welcome discount and a Day 28 nudge for store-visitors with zero purchases.

**B. Targeted segments.** Two sub-segments worth treating separately:
- Sleeper VIPs - Default-rank players in the top 30% for both votes and playtime but who've never spent a dollar. They love the server but never opened the wallet.
- Cart abandoners - Default players generate the most abandonments in absolute terms; Legend players abandon the most per player. Different problems, different fixes (broad nudges for Default, exclusivity messaging for Legend).

**C. Server hype.** Pearson correlation: votes correlate positively with revenue (and it's significant). Playtime correlates too but weaker - heavy grinders prefer earning over buying. The actionable read: vote-drive weekends are cheap and they pay back.

**D. Financials.** The cart-recovery math. A 30% cart-recovery rate is worth about $3,937/year on top of existing revenue. The notebook lays out a 3-step drip (info -> FOMO -> discount only as a last resort).

**E. Growth.** Where do the product gaps sit? Perks generate the highest revenue per buyer but there are very few of them. The Sellwand ladder dead-ends at Tier 4 even though 38 players already own it. Adding a Tier 5 (a natural upsell), an Elite rank above Legend, and a recurring XP booster are the obvious additions.

## How to run

```bash
pip install -r requirements.txt
```

Then open `behaviour.ipynb` in Jupyter and run top to bottom. It writes the PNGs and CSVs into the project root.

For the Power BI report: install Power BI Desktop (June 2025 or later), open `Customer Behaviour PowerBI/CustomerBehaviour.pbip`. Two of the visuals (the correlation heatmap and the abandonment funnel) run Python inside Power BI, so you also need `matplotlib seaborn pandas numpy` installed and the Python interpreter pointed at it in Power BI Options.

## Screenshots

| | |
|:---:|:---:|
| ![Player Psychology](part_a_player_psychology.png) | ![Targeted Segments](part_b_targeted_segments.png) |
| ![Server Hype](part_c_server_hype.png) | ![Financials](part_d_financials.png) |
| ![Growth](part_e_growth.png) | |
