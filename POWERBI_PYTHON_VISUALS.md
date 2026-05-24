# Craftiverse — Power BI Python Visuals

Two presentation-grade scripts targeted at the **Python Visual** component in Power BI Desktop. Both assume the visual receives the auto-injected `dataset` DataFrame (Power BI's wrapper around whichever fields you drag into the visual's *Values* well).

---

## Global setup — required once per visual

Power BI's Python environment must contain `matplotlib`, `seaborn`, `pandas`, `numpy`. Verify under **File → Options → Python scripting**.

> **Important — `dataset` quirks Power BI users get bitten by:**
> 1. Power BI **deduplicates rows** before passing data to the script. Always pull at least one high-cardinality field (e.g. `player_id`) into the *Values* well so the data isn't collapsed.
> 2. Numeric fields arrive as `object` if any null leaks through — cast explicitly with `pd.to_numeric(..., errors="coerce")`.
> 3. The script must call `plt.show()` at the end. Power BI captures the active figure.
> 4. Do **not** call `plt.savefig` — Power BI handles the canvas.

---

## Visual 1 — Advanced Correlation Heatmap

**Story:** Does playing more (or voting more) actually translate to spending? Triangular heatmap with annotated coefficients and a diverging colormap that pops on a dark background.

**Fields to drag into the visual's *Values* well (in this exact order is fine, names are what matter):**
`player_id`, `total_playtime_hours`, `total_votes`, `total_spent_dollars`, `webstore_visits`, `cart_abandonments`

```python
# === Craftiverse · Engagement vs. Spend Correlation Heatmap ===
# Paste into a Power BI Python visual after dragging the listed fields above.

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# --- 1. Defensive prep: Power BI hands us `dataset` (a pandas DataFrame). ---
df = dataset.copy()

numeric_cols = [
    "total_playtime_hours",
    "total_votes",
    "total_spent_dollars",
    "webstore_visits",
    "cart_abandonments",
]
for col in numeric_cols:
    df[col] = pd.to_numeric(df[col], errors="coerce")

df = df.dropna(subset=numeric_cols)

# --- 2. Pretty labels for the axes. ---
rename = {
    "total_playtime_hours": "Playtime (h)",
    "total_votes":          "Votes",
    "total_spent_dollars":  "Spend ($)",
    "webstore_visits":      "Store Visits",
    "cart_abandonments":    "Cart Drops",
}
corr = df[numeric_cols].rename(columns=rename).corr(method="pearson")

# --- 3. Styling: dark theme that matches the gaming dashboard. ---
plt.style.use("dark_background")
plt.rcParams.update({
    "font.family":      "DejaVu Sans",
    "axes.edgecolor":   "#2a2f3a",
    "axes.labelcolor":  "#e6e6e6",
    "xtick.color":      "#c8c8c8",
    "ytick.color":      "#c8c8c8",
    "axes.titlecolor":  "#ffffff",
})

# Mask upper triangle so the eye reads only the unique pairs.
mask = np.triu(np.ones_like(corr, dtype=bool))

fig, ax = plt.subplots(figsize=(9, 7), facecolor="#0d1117")
ax.set_facecolor("#0d1117")

sns.heatmap(
    corr,
    mask=mask,
    cmap="mako_r",         # premium blue→teal→lime; reads well in dark mode
    vmin=-1, vmax=1, center=0,
    annot=True, fmt=".2f",
    annot_kws={"size": 11, "weight": "bold", "color": "#ffffff"},
    linewidths=0.6, linecolor="#0d1117",
    square=True,
    cbar_kws={"shrink": 0.75, "label": "Pearson r"},
    ax=ax,
)

ax.set_title(
    "Engagement vs. Monetization — Correlation Matrix",
    fontsize=15, weight="bold", pad=16,
)
ax.tick_params(axis="x", rotation=30)
ax.tick_params(axis="y", rotation=0)

plt.tight_layout()
plt.show()
```

---

## Visual 2 — Cart Abandonment Funnel, Segmented by Rank

**Story:** How wide is the gap between "added to cart" and "actually purchased" for each player rank? Horizontal funnel bars with stage-to-stage retention labels.

**Fields to drag into the visual's *Values* well:**
`rank`, `webstore_visits` (sum), `cart_total_value` (count > 0), `total_transactions` (sum)

Because Power BI deduplicates, the cleanest pattern is to **bring `player_id` into the visual as well** and aggregate inside the script. That gives us truthful per-player counts no matter what the host page is filtered to.

**Required fields:** `player_id`, `rank`, `webstore_visits`, `cart_abandonments`, `total_transactions`

```python
# === Craftiverse · Cart Abandonment Funnel by Rank ===
# Paste into a Power BI Python visual.

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

df = dataset.copy()

for c in ["webstore_visits", "cart_abandonments", "total_transactions"]:
    df[c] = pd.to_numeric(df[c], errors="coerce").fillna(0)

# --- 1. Per-rank funnel stages (player-level counts, not row counts). ---
# Stage 1: visited the store at least once
# Stage 2: built a cart (cart_abandonments > 0 OR total_transactions > 0 implies cart existed)
# Stage 3: completed >=1 purchase
agg = (
    df.groupby("rank")
      .agg(
          visited   = ("webstore_visits",   lambda s: (s > 0).sum()),
          carted    = ("cart_abandonments", lambda s: (s > 0).sum()),
          purchased = ("total_transactions", lambda s: (s > 0).sum()),
      )
      .reset_index()
)

# Re-baseline `carted` so it can never exceed `visited` (data hygiene).
agg["carted"]    = np.minimum(agg["carted"]    + agg["purchased"], agg["visited"])
agg["purchased"] = np.minimum(agg["purchased"], agg["carted"])

# Sort ranks so Default appears at the top (it's the conversion story).
rank_order = ["Default", "VIP", "MVP", "Elite", "Legend", "Mythic"]
agg["rank"] = pd.Categorical(agg["rank"], categories=rank_order, ordered=True)
agg = agg.sort_values("rank").dropna(subset=["rank"]).reset_index(drop=True)

# --- 2. Styling. ---
plt.style.use("dark_background")
plt.rcParams.update({
    "font.family": "DejaVu Sans",
    "axes.edgecolor": "#2a2f3a",
})

stage_colors = {
    "visited":   "#00d4ff",   # neon cyan
    "carted":    "#ff8a00",   # amber
    "purchased": "#a6ff00",   # neon lime (conversion = win)
}

fig, ax = plt.subplots(figsize=(11, 0.9 * max(len(agg), 3) + 2), facecolor="#0d1117")
ax.set_facecolor("#0d1117")

y_positions = np.arange(len(agg))
bar_h = 0.22

# Plot each stage as its own horizontal bar group.
for i, stage in enumerate(["visited", "carted", "purchased"]):
    offset = (i - 1) * bar_h
    ax.barh(
        y_positions + offset,
        agg[stage],
        height=bar_h,
        color=stage_colors[stage],
        edgecolor="#0d1117",
        linewidth=1.2,
        label=stage.capitalize(),
    )
    # Annotate counts at bar end.
    for y, v in zip(y_positions + offset, agg[stage]):
        ax.text(v, y, f"  {int(v):,}", va="center", ha="left",
                color="#e6e6e6", fontsize=9, weight="bold")

# Stage-to-stage retention % labels at the right.
xmax = agg[["visited", "carted", "purchased"]].values.max() * 1.25
for i, row in agg.iterrows():
    v, c, p = row["visited"], row["carted"], row["purchased"]
    cr_v_c = (c / v * 100) if v else 0
    cr_c_p = (p / c * 100) if c else 0
    cr_v_p = (p / v * 100) if v else 0
    ax.text(
        xmax, i,
        f"V→C {cr_v_c:5.1f}%   C→P {cr_c_p:5.1f}%   V→P {cr_v_p:5.1f}%",
        va="center", ha="right",
        color="#c8c8c8", fontsize=9, family="monospace",
    )

ax.set_yticks(y_positions)
ax.set_yticklabels(agg["rank"].astype(str), color="#e6e6e6", fontsize=11, weight="bold")
ax.invert_yaxis()
ax.set_xlim(0, xmax)
ax.set_xlabel("Players", color="#c8c8c8")
ax.set_title("Cart Abandonment Funnel — by Rank", fontsize=15, weight="bold", color="#ffffff", pad=16)

# Clean spines.
for side in ["top", "right"]:
    ax.spines[side].set_visible(False)
ax.spines["left"].set_color("#2a2f3a")
ax.spines["bottom"].set_color("#2a2f3a")
ax.grid(axis="x", color="#1c2230", linewidth=0.6)

# Legend.
handles = [mpatches.Patch(color=stage_colors[s], label=s.capitalize())
           for s in ["visited", "carted", "purchased"]]
ax.legend(handles=handles, loc="lower right", frameon=False, labelcolor="#e6e6e6")

plt.tight_layout()
plt.show()
```

---

## Troubleshooting cheat sheet

| Symptom in Power BI                                 | Fix                                                                                       |
|-----------------------------------------------------|-------------------------------------------------------------------------------------------|
| "Can't display this visual" (no error text)         | Add `player_id` (or any unique ID) to *Values* so Power BI stops deduplicating.           |
| Chart renders but axes show fewer rows than expected | A page-level filter is hiding data — disable it temporarily to confirm.                   |
| Korean/empty boxes for labels                        | Change `font.family` to `Segoe UI` (installed by default on Windows).                     |
| Heatmap is solid one color                           | A column is non-numeric — the `pd.to_numeric(..., errors="coerce")` line is silently nulling it; check spelling. |
| Funnel bars look stretched                          | Pin the visual to a 16:9 area; the script auto-sizes height based on rank count.          |
