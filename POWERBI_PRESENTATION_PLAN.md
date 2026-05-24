# Craftiverse — Power BI Presentation Blueprint

A 3-page dashboard designed to *carry a live presentation*, not just sit on a wall. Each page has a single thesis, a single hero visual, and supporting evidence to its right.

---

## 1. Theme & Visual System

### 1.1 Aesthetic direction — "Server Console at Night"
The palette pulls from Minecraft Factions/Skyblock UI: deep navy/charcoal canvas, glowing neon accents for KPIs, restrained use of warm tones for negative signals (lost revenue, abandonment).

### 1.2 Color tokens

| Role                  | Hex        | Usage                                                     |
|-----------------------|------------|-----------------------------------------------------------|
| Canvas (page bg)      | `#0D1117`  | Every page background                                     |
| Surface (card bg)     | `#161B22`  | KPI cards, chart frames                                   |
| Border / hairline     | `#2A2F3A`  | Card outlines, axis lines                                 |
| Text primary          | `#F0F6FC`  | Titles, KPI numbers                                       |
| Text secondary        | `#9DA7B3`  | Captions, axis labels                                     |
| Accent — cyan         | `#00D4FF`  | Primary KPI ("Total Revenue"), bar chart default          |
| Accent — lime         | `#A6FF00`  | Conversion/positive signals ("First-Purchase Conversion") |
| Accent — magenta      | `#FF3DCB`  | Whales, premium ranks                                     |
| Warning — amber       | `#FF8A00`  | Cart abandonment, caution                                 |
| Negative — coral red  | `#FF4D4D`  | Lost revenue, churn risk                                  |
| Neutral grays         | `#3C4452` → `#7A8696` | Funnels, ordinal categories                    |

### 1.3 Apply the theme in one shot
**View → Themes → Browse for themes → New theme** with this JSON (save as `craftiverse-dark.json` and import):

```json
{
  "name": "Craftiverse Dark",
  "background": "#0D1117",
  "foreground": "#F0F6FC",
  "tableAccent": "#00D4FF",
  "dataColors": [
    "#00D4FF", "#A6FF00", "#FF3DCB", "#FF8A00",
    "#FF4D4D", "#7A8696", "#5EE6FF", "#C8FF6B"
  ],
  "good": "#A6FF00",
  "neutral": "#FF8A00",
  "bad": "#FF4D4D",
  "visualStyles": {
    "*": {
      "*": {
        "background": [{ "color": { "solid": { "color": "#161B22" } }, "transparency": 0 }],
        "border":     [{ "color": { "solid": { "color": "#2A2F3A" } }, "show": true, "radius": 8 }],
        "title":      [{ "fontColor": { "solid": { "color": "#F0F6FC" } }, "fontSize": 14, "bold": true, "alignment": "left" }],
        "labels":     [{ "color": { "solid": { "color": "#9DA7B3" } }, "fontSize": 10 }]
      }
    }
  }
}
```

### 1.4 Typography
- **Display / KPI numbers:** Segoe UI Semibold, 36–48 pt, color `#F0F6FC`
- **Chart titles:** Segoe UI Bold, 14 pt, color `#F0F6FC`, left aligned
- **Axis & captions:** Segoe UI Regular, 10 pt, color `#9DA7B3`
- **Avoid** Calibri (looks corporate, breaks the gaming vibe). Avoid italics entirely.

### 1.5 Spacing & layout rules
- **8-pt grid:** every element snaps to multiples of 8 px.
- **Card padding:** 16 px inner.
- **Card radius:** 8 px (set in theme above).
- **Page margin:** 24 px from canvas edge.
- **Never** place two visuals less than 12 px apart — give the eye air.

---

## 2. Page Layout (1280 × 720, 16:9)

Each page is a strip of header → KPI band → hero visual → evidence column.

### Page 1 — Executive Summary
**Thesis:** "Craftiverse converts the players that arrive, but most arrive and never convert."

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  [CRAFTIVERSE LOGO]   Executive Summary           [Date range slicer ▼]      │
├──────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  ┌──────────┐  ┌──────────┐    │
│  │ TOTAL    │  │ PAYING   │  │ ARPPU        │  │ CONV %   │  │ CART     │    │
│  │ REVENUE  │  │ PLAYERS  │  │ (per payer)  │  │ (1st pur)│  │ ABAND %  │    │
│  └──────────┘  └──────────┘  └──────────────┘  └──────────┘  └──────────┘    │
├──────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐  ┌───────────────────────────┐  │
│  │ Revenue by Category (horizontal bars)   │  │ Top 10 Whales (table)     │  │
│  │ — cyan bars, value labels at bar end    │  │ rank · username · spend   │  │
│  │ — sorted desc                           │  │ — magenta accent on rank  │  │
│  └─────────────────────────────────────────┘  └───────────────────────────┘  │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │ Daily / Weekly Revenue Trend (line, cyan, area fill)                    │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Measures used:** `Total Revenue`, `Paying Players`, `ARPPU (Paying Players Only)`, `First-Purchase Conversion Rate %`, `Cart Abandonment Rate %`, `Revenue by Category` family, `Top Category by Revenue`.

### Page 2 — Player Psychology
**Thesis:** "Engagement (playtime, votes) only weakly predicts spend — Default-rank players behave fundamentally differently."

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  Player Psychology         [Rank ▼] [Payer/Non ▼] [Playtime bucket ▼]        │
├──────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐  ┌───────────────────────────┐  │
│  │ HERO: Correlation Heatmap (Python)      │  │ Avg Spend by Rank (bar)   │  │
│  │ Playtime · Votes · Spend · Visits · Drop│  │ — sorted asc → desc        │  │
│  │  (see POWERBI_PYTHON_VISUALS.md §1)     │  │ — annotated values         │  │
│  └─────────────────────────────────────────┘  └───────────────────────────┘  │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │ Scatter: Playtime (x) vs. Spend (y), bubble = Votes, color = Rank      │  │
│  │ — log scale on x, trendline ON, tooltip shows username                 │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Visuals:**
- Hero is the **Python correlation heatmap** from `POWERBI_PYTHON_VISUALS.md` §1.
- Bar chart of `Avg Spend by Rank` using `AVERAGE ( dim_players[total_spent_dollars] )` grouped by `rank`.
- Scatter with the Analytics pane's *Trend line* turned on.

### Page 3 — Lost Revenue Analysis
**Thesis:** "We're losing $X to abandoned carts, and 80% of it sits in two categories among Default-rank players."

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  Lost Revenue Analysis     [Rank ▼] [Category ▼] [Cart value bucket ▼]       │
├──────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────────────────────────┐    │
│  │ LOST $   │  │ ABAND RATE % │  │ RECOVERABLE $ (Lost × Conv %)        │    │
│  └──────────┘  └──────────────┘  └──────────────────────────────────────┘    │
├──────────────────────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │ HERO: Funnel by Rank (Python)                                          │  │
│  │ Visited → Carted → Purchased   (see POWERBI_PYTHON_VISUALS.md §2)      │  │
│  └────────────────────────────────────────────────────────────────────────┘  │
│  ┌─────────────────────────────────────────┐  ┌───────────────────────────┐  │
│  │ Top 5 Abandoned Items (horizontal bars) │  │ Abandonment by Category   │  │
│  │ — amber color                           │  │ (treemap, amber→coral)    │  │
│  └─────────────────────────────────────────┘  └───────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────────────┘
```

**Measures used:** `Lost Revenue (Abandoned $)`, `Cart Abandonment Rate %`, `Total Revenue`, and a derived "Recoverable" card:

```DAX
Recoverable Revenue ($) = [Lost Revenue (Abandoned $)] * [First-Purchase Conversion Rate %]
```

---

## 3. Slicers & Filters — exactly what goes where

The rule: **only put slicers on a page that visibly change ≥ 3 visuals on that page.** Anything else goes in a hidden filter pane.

### 3.1 Page-level slicers (visible, top-right of each page)

| Page                  | Slicer                       | Field                                        | Style              |
|-----------------------|------------------------------|----------------------------------------------|--------------------|
| **Executive Summary** | Date range                   | `dim_players[last_purchase_date]`            | Between slider     |
| **Executive Summary** | Rank                         | `dim_players[rank]`                          | Tile / horizontal  |
| **Player Psychology** | Rank                         | `dim_players[rank]`                          | Tile / horizontal  |
| **Player Psychology** | Payer status                 | `dim_players[is_payer]`                      | Toggle (2 buttons) |
| **Player Psychology** | Playtime bucket *(see §3.3)* | calculated column                            | Dropdown           |
| **Lost Revenue**      | Rank                         | `dim_players[rank]`                          | Tile / horizontal  |
| **Lost Revenue**      | Category                     | `fact_abandoned_carts[category]`             | Dropdown (multi)   |
| **Lost Revenue**      | Cart value bucket *(§3.3)*   | calculated column                            | Dropdown           |

### 3.2 Sync slicers across pages
For **Rank**: View → Sync slicers → tick all three pages so the audience sees state persist as you move forward. **Do not** sync the Date range — Page 2 (Psychology) should always show the full distribution; date-filtering it makes correlations noisy.

### 3.3 Two calculated columns to add to `dim_players`

```DAX
Playtime Bucket =
SWITCH (
    TRUE (),
    dim_players[total_playtime_hours] < 10,   "0–10 h (Tourist)",
    dim_players[total_playtime_hours] < 50,   "10–50 h (Casual)",
    dim_players[total_playtime_hours] < 200,  "50–200 h (Regular)",
    dim_players[total_playtime_hours] < 500,  "200–500 h (Core)",
    "500 h+ (Hardcore)"
)
```

```DAX
Cart Value Bucket =
SWITCH (
    TRUE (),
    dim_players[cart_total_value] = 0,    "Empty",
    dim_players[cart_total_value] < 10,   "Under $10",
    dim_players[cart_total_value] < 25,   "$10–25",
    dim_players[cart_total_value] < 50,   "$25–50",
    "$50+"
)
```

Set their *Sort by column* to a hidden integer column (`Playtime Bucket Sort`, `Cart Value Bucket Sort`) so the dropdown isn't alphabetical.

### 3.4 Hidden filter pane (advanced filters, off by default during presentation)
- `dim_players[first_join_date]` — for cohort drill-downs in Q&A
- `fact_purchases[item]` — when an exec asks "what about Mythical specifically?"
- `dim_players[total_transactions] > 0` — quick "paying base only" toggle

### 3.5 Cross-filtering behavior
- Set every chart's *Edit interactions* so that **slicers filter** but bar/line charts only **highlight** each other (not full filter). Highlighting preserves context; full filtering during a live demo causes empty charts and a frozen presenter.
- The Top Whales table on Page 1 should be set to **No interaction** from the Revenue by Category chart — the table is a "list of who," not "who in this category."

---

## 4. Presentation Choreography (script for the live demo)

1. **Open on Page 1.** Lead with the **Total Revenue** card → pivot immediately to **Cart Abandonment %** — establish that the headline number hides a problem.
2. **Use the Rank slicer**, click `Default` → ARPPU collapses, abandonment spikes. This is the moment that sells the next page.
3. **Move to Page 2.** Show the heatmap: "Playtime barely correlates with spend (r ≈ 0.1) — engagement isn't the lever." Pull the Payer toggle to contrast.
4. **Move to Page 3.** Show the funnel hero. Land the "Recoverable Revenue" card as the call-to-action ("if we recover 20% of this, that's $X next quarter").
5. **Return to Page 1** with Rank still filtered to `Default` to close the loop visually.

---

## 5. File output checklist

| Artifact                              | Location                                                                                       |
|---------------------------------------|------------------------------------------------------------------------------------------------|
| `DAX_MEASURES.md`                     | `C:/Users/danie/PycharmProjects/CustomerBehaviour/`                                            |
| `POWERBI_PYTHON_VISUALS.md`           | `C:/Users/danie/PycharmProjects/CustomerBehaviour/`                                            |
| `POWERBI_PRESENTATION_PLAN.md`        | `C:/Users/danie/PycharmProjects/CustomerBehaviour/`                                            |
| `craftiverse-dark.json` (theme)       | save next to `CustomerBehaviour.pbip`, then import via View → Themes → Browse                  |
| Power BI model — tables loaded        | `dim_players`, `fact_purchases`, `fact_abandoned_carts` per §0 of `DAX_MEASURES.md`            |
| Power BI model — measures pasted      | into `_Measures` table (see §0 of `DAX_MEASURES.md`)                                           |
| Two Python visuals placed             | Pages 2 and 3 per the layouts in §2                                                            |
