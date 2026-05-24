# Craftiverse — Advanced DAX Measures (Power BI)

**Target file:** `C:/Users/danie/Desktop/Data and Financel Analysis/PowerBI/CustomerBehaviour.pbip`
**Semantic model:** `CustomerBehaviour.SemanticModel/definition/model.tmdl`

> **Why a `.md` and not direct TMDL injection?**
> The current `model.tmdl` is an empty shell — no tables are declared yet, so writing measures into it would produce references to columns that don't exist and Power BI would refuse to open the model. Load your three sources first, then paste these in via the Power BI Desktop **Modeling → New measure** dialog (recommended) or by adding a `measure ...` block to the relevant table inside `model.tmdl` once tables exist.

---

## 0. Prerequisite: Load these tables into the model

| Table name (use exactly) | Source                                                                                  | Storage mode |
|---|---|---|
| `dim_players`            | `C:/Users/danie/PycharmProjects/CustomerBehaviour/dim_players.csv`                       | Import       |
| `fact_purchases`         | `C:/Users/danie/PycharmProjects/CustomerBehaviour/fact_purchases.csv`                    | Import       |
| `fact_abandoned_carts`   | `C:/Users/danie/PycharmProjects/CustomerBehaviour/fact_abandoned_carts.csv`              | Import       |

**Relationships (single direction, 1→*):**
- `dim_players[player_id]`  →  `fact_purchases[player_id]`
- `dim_players[player_id]`  →  `fact_abandoned_carts[player_id]`

**Recommended measure home:** create a blank table called `_Measures` (Modeling → New table → `_Measures = {BLANK()}`, then hide the column). Drop every measure below into it so KPIs aren't scattered across fact tables.

---

## 1. Total Revenue

```DAX
Total Revenue =
SUM ( fact_purchases[price] )
```

**Format:** Currency, 2 decimals, `$` symbol.

---

## 2. ARPU (Average Revenue Per User)

Two flavors — pick the one that matches the story you're telling. **Use ARPPU for monetization talk; use ARPU for whole-base talk.**

```DAX
ARPU (All Players) =
DIVIDE (
    [Total Revenue],
    DISTINCTCOUNT ( dim_players[player_id] )
)
```

```DAX
ARPPU (Paying Players Only) =
VAR PayingPlayers =
    CALCULATE (
        DISTINCTCOUNT ( dim_players[player_id] ),
        dim_players[is_payer] = TRUE ()
    )
RETURN
    DIVIDE ( [Total Revenue], PayingPlayers )
```

**Format:** Currency, 2 decimals.

---

## 3. Cart Abandonment Rate %

A cart is "abandoned" if it appears in `fact_abandoned_carts` and that item never appears in `fact_purchases` for the same player. We approximate with row-count ratio (matches the SQL cheatsheet in `kpi_cheatsheet.sql`).

```DAX
Cart Items Abandoned =
COUNTROWS ( fact_abandoned_carts )
```

```DAX
Cart Items Total =
[Cart Items Abandoned] + COUNTROWS ( fact_purchases )
```

```DAX
Cart Abandonment Rate % =
DIVIDE (
    [Cart Items Abandoned],
    [Cart Items Total],
    0
)
```

**Format:** Percentage, 1 decimal.

> **Conversation tip:** when a stakeholder asks "but why so high?" you can drop the same measure into a matrix sliced by `rank` — Default-rank players drive most abandonment, which is the seed of the Lost Revenue page.

---

## 4. Revenue by Product Category

This is the workhorse for the Product/Category bar charts. The measure is just `[Total Revenue]` filtered by `fact_purchases[category]` in the visual, but the explicit variants below are useful for cards and tooltips.

```DAX
Revenue — Crate Keys =
CALCULATE ( [Total Revenue], fact_purchases[category] = "Crate keys" )
```

```DAX
Revenue — Ranks =
CALCULATE ( [Total Revenue], fact_purchases[category] = "Ranks" )
```

```DAX
Revenue — Perks =
CALCULATE ( [Total Revenue], fact_purchases[category] = "Perks" )
```

```DAX
Revenue — Sellwands =
CALCULATE ( [Total Revenue], fact_purchases[category] = "Sellwands" )
```

**Dynamic top-category label** (great as a card on the Executive Summary):

```DAX
Top Category by Revenue =
VAR Ranked =
    ADDCOLUMNS (
        VALUES ( fact_purchases[category] ),
        "@Rev", [Total Revenue]
    )
VAR TopRow =
    TOPN ( 1, Ranked, [@Rev], DESC )
RETURN
    CONCATENATEX ( TopRow, fact_purchases[category] & " ($" & FORMAT ( [@Rev], "#,0" ) & ")" )
```

---

## 5. First-Purchase Conversion Rate (Default-rank players)

The funnel: **Default-rank players who have visited the webstore** → **Default-rank players with ≥ 1 purchase**.

```DAX
Default Players (Visited Store) =
CALCULATE (
    DISTINCTCOUNT ( dim_players[player_id] ),
    dim_players[rank] = "Default",
    dim_players[webstore_visits] > 0
)
```

```DAX
Default Players (Converted) =
CALCULATE (
    DISTINCTCOUNT ( dim_players[player_id] ),
    dim_players[rank] = "Default",
    dim_players[total_transactions] >= 1
)
```

```DAX
First-Purchase Conversion Rate % =
DIVIDE (
    [Default Players (Converted)],
    [Default Players (Visited Store)],
    0
)
```

**Format:** Percentage, 1 decimal.

> If the model later gains a date column for first purchase, swap `total_transactions >= 1` for `NOT ISBLANK ( dim_players[last_purchase_date] )` to make it strictly "ever bought."

---

## 6. Bonus measures worth pasting in too

These power the presentation pages without adding noise to the four core KPIs.

```DAX
Paying Players = CALCULATE ( DISTINCTCOUNT ( dim_players[player_id] ), dim_players[is_payer] = TRUE () )
```

```DAX
Total Players = DISTINCTCOUNT ( dim_players[player_id] )
```

```DAX
Paying Rate % = DIVIDE ( [Paying Players], [Total Players], 0 )
```

```DAX
Lost Revenue (Abandoned $) = SUM ( fact_abandoned_carts[price] )
```

```DAX
Avg Playtime (Hours) = AVERAGE ( dim_players[total_playtime_hours] )
```

```DAX
Whale Threshold ($) = PERCENTILEX.INC ( FILTER ( dim_players, dim_players[is_payer] = TRUE () ), dim_players[total_spent_dollars], 0.9 )
```

```DAX
Whale Revenue Share % =
VAR Threshold = [Whale Threshold ($)]
VAR WhaleRev =
    CALCULATE (
        [Total Revenue],
        FILTER ( dim_players, dim_players[total_spent_dollars] >= Threshold )
    )
RETURN DIVIDE ( WhaleRev, [Total Revenue], 0 )
```

---

## 7. (Optional) Direct TMDL injection — only after tables exist

If you prefer to commit measures to source control rather than clicking through the UI, after the three tables are loaded open `CustomerBehaviour.SemanticModel/definition/tables/dim_players.tmdl` (or the `_Measures` table file Power BI generates) and append blocks like:

```tmdl
measure 'Total Revenue' = SUM ( fact_purchases[price] )
    formatString: \$#,0.00
    displayFolder: KPIs

measure 'ARPU (All Players)' = DIVIDE ( [Total Revenue], DISTINCTCOUNT ( dim_players[player_id] ) )
    formatString: \$#,0.00
    displayFolder: KPIs
```

Save, reopen the `.pbip`, and Power BI will validate the references. **Do not** add these blocks to `model.tmdl` itself — they belong on a table file.

---

## 8. Per-Person Averages (Presentation KPI Cards)

Three slicer-aware averages for the Executive Summary page. All three read directly from `dim_players` — no join to `fact_purchases` needed — because `total_votes`, `total_spent_dollars`, and `total_transactions` are already pre-aggregated per player in that table.

**Verified baseline (580 players, no slicers applied):**

| Measure | Raw value |
|---|---|
| Avg Votes Per Person | 58.02 |
| Avg Spend Per Person (ARPU) | $17.09 |
| Avg Transactions Per Person | 1.16 |

### 8.1 Average Votes Per Person

```DAX
Avg Votes Per Person =
-- SUM ÷ DISTINCTCOUNT makes the denominator explicit: "unique players in current filter context."
-- DIVIDE(..., 0) returns 0 instead of crashing when a slicer produces an empty selection.
DIVIDE(
    SUM( dim_players[total_votes] ),
    DISTINCTCOUNT( dim_players[player_id] ),
    0
)
```

**Format:** Whole number, 2 decimals. **Card label:** "Avg Votes / Player"

### 8.2 Average Dollars Spent Per Person (ARPU — All Players)

```DAX
Avg Spend Per Person (ARPU) =
-- AVERAGE iterates every row of dim_players visible in the current filter context.
-- Players with $0 spend are included in the denominator, giving true population ARPU
-- (not ARPPU). Slicers on rank or date shrink the visible rows automatically.
AVERAGE( dim_players[total_spent_dollars] )
```

**Format:** Currency, 2 decimals, `$` symbol. **Card label:** "ARPU (All Players)"

> **Relationship to existing measures:** `[Avg Spend Per Person (ARPU)]` and `[ARPU (All Players)]` (§2) produce the same number globally — both equal `Total Revenue ÷ Total Players`. Prefer this measure on KPI cards (one column, no cross-table dependency); prefer the §2 version when you need it alongside `[ARPPU (Paying Players Only)]` for side-by-side comparison.

### 8.3 Average Transactions Per Person

```DAX
Avg Transactions Per Person =
-- Same pattern as §8.1: SUM ÷ DISTINCTCOUNT keeps the denominator transparent.
-- When filtered to rank = "Default", this drops to ~1.03 vs ~1.77–1.82 for paid ranks,
-- making it a strong supporting card for the Player Psychology page narrative.
DIVIDE(
    SUM( dim_players[total_transactions] ),
    DISTINCTCOUNT( dim_players[player_id] ),
    0
)
```

**Format:** Decimal, 2 places. **Card label:** "Avg Transactions / Player"
