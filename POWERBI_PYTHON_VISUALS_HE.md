# Craftiverse — ויזואלים Python ב-Power BI

שני סקריפטים ברמת מצגת המיועדים לרכיב **Python Visual** ב-Power BI Desktop. שניהם מניחים שהויזואל מקבל את ה-DataFrame המוזרק אוטומטית `dataset` (עטיפת Power BI סביב השדות שגוררים לתא *Values* של הויזואל).

---

## הגדרה גלובלית — נדרשת פעם אחת לכל ויזואל

סביבת Python של Power BI חייבת להכיל את `matplotlib`, `seaborn`, `pandas`, `numpy`. בדוק תחת **קובץ → אפשרויות → Python scripting**.

> **חשוב — בעיות `dataset` שמפתיעות משתמשי Power BI:**
> 1. Power BI **מסיר כפילויות שורות** לפני העברת נתונים לסקריפט. תמיד הכנס לפחות שדה בעל קרדינליות גבוהה (למשל `player_id`) לתא *Values* כדי שהנתונים לא יתמוטטו.
> 2. שדות מספריים מגיעים כ-`object` אם איזשהו null חודר — ביצע cast מפורש עם `pd.to_numeric(..., errors="coerce")`.
> 3. הסקריפט חייב לקרוא ל-`plt.show()` בסוף. Power BI לוכד את הפיגורה הפעילה.
> 4. **אל** תקרא ל-`plt.savefig` — Power BI מטפל בבד.

---

## ויזואל 1 — מפת חום מתאמים מתקדמת

**סיפור:** האם משחק יותר (או הצבעה יותר) אכן מתורגם להוצאה? מפת חום משולשת עם מקדמים מסומנים ומפת צבעים דיפרנציאלית הבולטת על רקע כהה.

**שדות לגרור לתא *Values* של הויזואל (הסדר בסדר, השמות הם שחשובים):**
`player_id`, `total_playtime_hours`, `total_votes`, `total_spent_dollars`, `webstore_visits`, `cart_abandonments`

```python
# === Craftiverse · מפת חום מתאמים מעורבות מול הוצאה ===
# הדבק לתוך ויזואל Python ב-Power BI לאחר גרירת השדות הנ"ל.

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# --- 1. הכנה הגנתית: Power BI מעביר לנו `dataset` (DataFrame של pandas). ---
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

# --- 2. תוויות יפות לצירים. ---
rename = {
    "total_playtime_hours": "זמן משחק (ש')",
    "total_votes":          "הצבעות",
    "total_spent_dollars":  "הוצאה ($)",
    "webstore_visits":      "ביקורי חנות",
    "cart_abandonments":    "נטישות עגלה",
}
corr = df[numeric_cols].rename(columns=rename).corr(method="pearson")

# --- 3. עיצוב: ערכת נושא כהה התואמת את לוח המחוונים של המשחק. ---
plt.style.use("dark_background")
plt.rcParams.update({
    "font.family":      "DejaVu Sans",
    "axes.edgecolor":   "#2a2f3a",
    "axes.labelcolor":  "#e6e6e6",
    "xtick.color":      "#c8c8c8",
    "ytick.color":      "#c8c8c8",
    "axes.titlecolor":  "#ffffff",
})

# הסתר את המשולש העליון כדי שהעין תקרא רק את הזוגות הייחודיים.
mask = np.triu(np.ones_like(corr, dtype=bool))

fig, ax = plt.subplots(figsize=(9, 7), facecolor="#0d1117")
ax.set_facecolor("#0d1117")

sns.heatmap(
    corr,
    mask=mask,
    cmap="mako_r",         # כחול→טורקיז→ליים פרמיום; נקרא היטב במצב כהה
    vmin=-1, vmax=1, center=0,
    annot=True, fmt=".2f",
    annot_kws={"size": 11, "weight": "bold", "color": "#ffffff"},
    linewidths=0.6, linecolor="#0d1117",
    square=True,
    cbar_kws={"shrink": 0.75, "label": "Pearson r"},
    ax=ax,
)

ax.set_title(
    "מעורבות מול מונטיזציה — מטריצת מתאמים",
    fontsize=15, weight="bold", pad=16,
)
ax.tick_params(axis="x", rotation=30)
ax.tick_params(axis="y", rotation=0)

plt.tight_layout()
plt.show()
```

---

## ויזואל 2 — משפך נטישת עגלה, מפולח לפי דרגה

**סיפור:** עד כמה גדול הפער בין "הוסיף לעגלה" ל-"אכן רכש" עבור כל דרגת שחקן? עמודות משפך אופקיות עם תוויות שימור בין שלב לשלב.

**שדות לגרור לתא *Values* של הויזואל:**
`rank`, `webstore_visits` (סכום), `cart_total_value` (ספירה > 0), `total_transactions` (סכום)

מכיוון ש-Power BI מסיר כפילויות, הדפוס הנקי ביותר הוא **להכניס גם `player_id` לויזואל** ולצבור בתוך הסקריפט. זה נותן לנו ספירות מהימנות לכל שחקן ללא קשר לסינון העמוד המארח.

**שדות נדרשים:** `player_id`, `rank`, `webstore_visits`, `cart_abandonments`, `total_transactions`

```python
# === Craftiverse · משפך נטישת עגלה לפי דרגה ===
# הדבק לתוך ויזואל Python ב-Power BI.

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches

df = dataset.copy()

for c in ["webstore_visits", "cart_abandonments", "total_transactions"]:
    df[c] = pd.to_numeric(df[c], errors="coerce").fillna(0)

# --- 1. שלבי משפך לפי דרגה (ספירות ברמת שחקן, לא ספירות שורות). ---
# שלב 1: ביקר בחנות לפחות פעם אחת
# שלב 2: בנה עגלה (cart_abandonments > 0 או total_transactions > 0 מרמז שעגלה הייתה קיימת)
# שלב 3: השלים ≥1 רכישה
agg = (
    df.groupby("rank")
      .agg(
          visited   = ("webstore_visits",   lambda s: (s > 0).sum()),
          carted    = ("cart_abandonments", lambda s: (s > 0).sum()),
          purchased = ("total_transactions", lambda s: (s > 0).sum()),
      )
      .reset_index()
)

# בסס מחדש `carted` כך שלעולם לא יחרוג מ-`visited` (ניקוי נתונים).
agg["carted"]    = np.minimum(agg["carted"]    + agg["purchased"], agg["visited"])
agg["purchased"] = np.minimum(agg["purchased"], agg["carted"])

# מיין דרגות כך ש-Default יופיע בראש (זו סיפור ההמרה).
rank_order = ["Default", "VIP", "MVP", "Elite", "Legend", "Mythic"]
agg["rank"] = pd.Categorical(agg["rank"], categories=rank_order, ordered=True)
agg = agg.sort_values("rank").dropna(subset=["rank"]).reset_index(drop=True)

# --- 2. עיצוב. ---
plt.style.use("dark_background")
plt.rcParams.update({
    "font.family": "DejaVu Sans",
    "axes.edgecolor": "#2a2f3a",
})

stage_colors = {
    "visited":   "#00d4ff",   # ציאן ניאון
    "carted":    "#ff8a00",   # ענבר
    "purchased": "#a6ff00",   # ליים ניאון (המרה = ניצחון)
}

fig, ax = plt.subplots(figsize=(11, 0.9 * max(len(agg), 3) + 2), facecolor="#0d1117")
ax.set_facecolor("#0d1117")

y_positions = np.arange(len(agg))
bar_h = 0.22

# צייר כל שלב כקבוצת עמודות אופקיות משלה.
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
    # סמן ספירות בסוף העמודה.
    for y, v in zip(y_positions + offset, agg[stage]):
        ax.text(v, y, f"  {int(v):,}", va="center", ha="left",
                color="#e6e6e6", fontsize=9, weight="bold")

# תוויות % שימור בין שלב לשלב בצד ימין.
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
ax.set_xlabel("שחקנים", color="#c8c8c8")
ax.set_title("משפך נטישת עגלה — לפי דרגה", fontsize=15, weight="bold", color="#ffffff", pad=16)

# נקה קווי מסגרת.
for side in ["top", "right"]:
    ax.spines[side].set_visible(False)
ax.spines["left"].set_color("#2a2f3a")
ax.spines["bottom"].set_color("#2a2f3a")
ax.grid(axis="x", color="#1c2230", linewidth=0.6)

# מקרא.
handles = [mpatches.Patch(color=stage_colors[s], label=s.capitalize())
           for s in ["visited", "carted", "purchased"]]
ax.legend(handles=handles, loc="lower right", frameon=False, labelcolor="#e6e6e6")

plt.tight_layout()
plt.show()
```

---

## גיליון פתרון תקלות

| תסמין ב-Power BI                                     | פתרון                                                                                          |
|------------------------------------------------------|-----------------------------------------------------------------------------------------------|
| "לא ניתן להציג ויזואל זה" (ללא טקסט שגיאה)          | הוסף `player_id` (או כל מזהה ייחודי) ל-*Values* כדי שPower BI יפסיק להסיר כפילויות.          |
| הגרף מרונדר אך הצירים מציגים פחות שורות מהצפוי      | מסנן ברמת עמוד מסתיר נתונים — כבה אותו זמנית לאישור.                                         |
| תיבות קוריאניות/ריקות בתוויות                         | שנה `font.family` ל-`Segoe UI` (מותקן כברירת מחדל ב-Windows).                               |
| מפת חום בצבע אחיד אחד                                | עמודה אינה מספרית — שורת `pd.to_numeric(..., errors="coerce")` מבטלת אותה בשקט; בדוק איות. |
| עמודות המשפך נראות מתוחות                             | קבע את הויזואל לאזור 16:9; הסקריפט מכוון גובה אוטומטית לפי מספר הדרגות.                    |
