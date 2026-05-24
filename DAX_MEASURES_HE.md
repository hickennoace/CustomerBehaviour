# Craftiverse — מדדי DAX מתקדמים (Power BI)

**קובץ יעד:** `C:/Users/danie/Desktop/Data and Financel Analysis/PowerBI/CustomerBehaviour.pbip`
**מודל סמנטי:** `CustomerBehaviour.SemanticModel/definition/model.tmdl`

> **מדוע קובץ `.md` ולא הזרקה ישירה ל-TMDL?**
> הקובץ `model.tmdl` הנוכחי הוא מעטפת ריקה — עדיין לא הוצהרו טבלאות, לכן כתיבת מדדים אליו תייצר הפניות לעמודות שאינן קיימות ו-Power BI יסרב לפתוח את המודל. טען קודם את שלושת המקורות, ואז הדבק אותם דרך תיבת הדו-שיח **Modeling → New measure** ב-Power BI Desktop (מומלץ) או על ידי הוספת בלוק `measure ...` לטבלה הרלוונטית בתוך `model.tmdl` לאחר שהטבלאות קיימות.

---

## 0. תנאי מקדים: טען טבלאות אלה למודל

| שם טבלה (השתמש בדיוק כך) | מקור                                                                                    | מצב אחסון |
|---|---|---|
| `dim_players`            | `C:/Users/danie/PycharmProjects/CustomerBehaviour/dim_players.csv`                       | Import     |
| `fact_purchases`         | `C:/Users/danie/PycharmProjects/CustomerBehaviour/fact_purchases.csv`                    | Import     |
| `fact_abandoned_carts`   | `C:/Users/danie/PycharmProjects/CustomerBehaviour/fact_abandoned_carts.csv`              | Import     |

**קשרים (כיוון יחיד, 1→*):**
- `dim_players[player_id]`  →  `fact_purchases[player_id]`
- `dim_players[player_id]`  →  `fact_abandoned_carts[player_id]`

**מיקום מדדים מומלץ:** צור טבלה ריקה בשם `_Measures` (Modeling → New table → `_Measures = {BLANK()}`, ואז הסתר את העמודה). הכנס כל מדד מטה לשם כדי שה-KPI לא יהיו מפוזרים בין טבלאות עובדות.

---

## 1. סך הכנסות

```DAX
Total Revenue =
SUM ( fact_purchases[price] )
```

**פורמט:** מטבע, 2 ספרות עשרוניות, סמל `$`.

---

## 2. ARPU (הכנסה ממוצעת למשתמש)

שני גרסאות — בחר את זו שמתאימה לנרטיב שלך. **השתמש ב-ARPPU לדיון מונטיזציה; השתמש ב-ARPU לדיון על כלל הבסיס.**

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

**פורמט:** מטבע, 2 ספרות עשרוניות.

---

## 3. שיעור נטישת עגלה %

עגלה נחשבת "נטושה" אם היא מופיעה ב-`fact_abandoned_carts` והפריט לעולם לא מופיע ב-`fact_purchases` עבור אותו שחקן. אנו משתמשים ביחס ספירת שורות כקירוב (תואם את גיליון ה-SQL ב-`kpi_cheatsheet.sql`).

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

**פורמט:** אחוז, ספרה עשרונית אחת.

> **טיפ לשיחה:** כשבעל עניין שואל "למה כל כך גבוה?" תוכל להכניס את אותו מדד לתוך מטריקס מסוננת לפי `rank` — שחקני דרגת Default מניעים את רוב הנטישה, וזה הגרעין של עמוד ההכנסה האבודה.

---

## 4. הכנסות לפי קטגוריית מוצר

זהו הסוס העבודה לגרפי עמודות לפי מוצר/קטגוריה. המדד הוא פשוט `[Total Revenue]` מסונן לפי `fact_purchases[category]` בויזואל, אך הגרסאות המפורשות למטה שימושיות לכרטיסים וטולטיפים.

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

**תווית קטגוריה מובילה דינמית** (מצוין ככרטיס בעמוד סיכום מנהלים):

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

## 5. שיעור המרת רכישה ראשונה (שחקני דרגת Default)

המשפך: **שחקני Default שביקרו בחנות הווב** ← **שחקני Default עם ≥ 1 רכישה**.

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

**פורמט:** אחוז, ספרה עשרונית אחת.

> אם המודל יקבל בהמשך עמודת תאריך לרכישה ראשונה, החלף `total_transactions >= 1` ב-`NOT ISBLANK ( dim_players[last_purchase_date] )` כדי לקבל הגדרה מדויקת של "אי פעם רכש."

---

## 6. מדדי בונוס שכדאי להדביק גם כן

אלה מניעים את עמודי המצגת מבלי להוסיף רעש לארבעת ה-KPI הליבה.

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

## 7. (אופציונלי) הזרקה ישירה ל-TMDL — רק לאחר שהטבלאות קיימות

אם אתה מעדיף לשמור מדדים בבקרת גרסאות במקום ללחוץ בממשק, לאחר טעינת שלושת הטבלאות פתח את `CustomerBehaviour.SemanticModel/definition/tables/dim_players.tmdl` (או קובץ טבלת `_Measures` שPower BI מייצר) והוסף בלוקים כגון:

```tmdl
measure 'Total Revenue' = SUM ( fact_purchases[price] )
    formatString: \$#,0.00
    displayFolder: KPIs

measure 'ARPU (All Players)' = DIVIDE ( [Total Revenue], DISTINCTCOUNT ( dim_players[player_id] ) )
    formatString: \$#,0.00
    displayFolder: KPIs
```

שמור, פתח מחדש את `.pbip`, ו-Power BI יאמת את ההפניות. **אל** תוסיף בלוקים אלה ל-`model.tmdl` עצמו — הם שייכים לקובץ הטבלה.

---

## 8. ממוצעים לאדם (כרטיסי KPI למצגת)

שלושה ממוצעים מודעי-מסנן עבור עמוד סיכום מנהלים. כולם קוראים ישירות מ-`dim_players` — אין צורך בחיבור ל-`fact_purchases` — מכיוון ש-`total_votes`, `total_spent_dollars` ו-`total_transactions` כבר מצוברים לפי שחקן באותה טבלה.

**ערכי בסיס מאומתים (580 שחקנים, ללא מסננים):**

| מדד | ערך גולמי |
|---|---|
| ממוצע הצבעות לאדם | 58.02 |
| ממוצע הוצאה לאדם (ARPU) | $17.09 |
| ממוצע עסקאות לאדם | 1.16 |

### 8.1 ממוצע הצבעות לאדם

```DAX
Avg Votes Per Person =
-- SUM ÷ DISTINCTCOUNT הופך את המכנה לגלוי: "שחקנים ייחודיים בהקשר הסינון הנוכחי."
-- DIVIDE(..., 0) מחזיר 0 במקום לקרוס כשמסנן מייצר בחירה ריקה.
DIVIDE(
    SUM( dim_players[total_votes] ),
    DISTINCTCOUNT( dim_players[player_id] ),
    0
)
```

**פורמט:** מספר עשרוני, 2 ספרות עשרוניות. **תווית כרטיס:** "ממוצע הצבעות / שחקן"

### 8.2 ממוצע דולרים שהוצאו לאדם (ARPU — כלל השחקנים)

```DAX
Avg Spend Per Person (ARPU) =
-- AVERAGE עובר על כל שורה של dim_players הגלויה בהקשר הסינון הנוכחי.
-- שחקנים עם $0 הוצאה כלולים במכנה, מה שנותן ARPU אמיתי של האוכלוסייה
-- (לא ARPPU). מסננים על דרגה או תאריך מצמצמים את השורות הגלויות אוטומטית.
AVERAGE( dim_players[total_spent_dollars] )
```

**פורמט:** מטבע, 2 ספרות עשרוניות, סמל `$`. **תווית כרטיס:** "ARPU (כלל השחקנים)"

> **קשר למדדים קיימים:** `[Avg Spend Per Person (ARPU)]` ו-`[ARPU (All Players)]` (§2) מייצרים את אותו מספר גלובלית — שניהם שווים ל-`סך הכנסות ÷ סך שחקנים`. העדף מדד זה בכרטיסי KPI (עמודה אחת, ללא תלות בין-טבלאות); העדף את גרסת §2 כשצריך אותו לצד `[ARPPU (Paying Players Only)]` להשוואה זה לצד זה.

### 8.3 ממוצע עסקאות לאדם

```DAX
Avg Transactions Per Person =
-- אותו דפוס כמו §8.1: SUM ÷ DISTINCTCOUNT שומר את המכנה שקוף.
-- כשמסוננים לדרגה = "Default", זה יורד לכ-1.03 לעומת כ-1.77–1.82 לדרגות בתשלום,
-- מה שהופך אותו לכרטיס תומך חזק לנרטיב של עמוד פסיכולוגיית שחקנים.
DIVIDE(
    SUM( dim_players[total_transactions] ),
    DISTINCTCOUNT( dim_players[player_id] ),
    0
)
```

**פורמט:** עשרוני, 2 ספרות. **תווית כרטיס:** "ממוצע עסקאות / שחקן"
