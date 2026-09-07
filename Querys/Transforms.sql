/* ============================================================
   STEP 0 - نگاه اولیه به داده
   ============================================================ */

SELECT TOP 100 *
FROM STG.SALES;


/* ============================================================
   STEP 1 - بررسی تعداد کل رکوردها
   ============================================================ */

SELECT COUNT(*) AS TotalRows
FROM STG.SALES;


/* ============================================================
   STEP 2 - پیدا کردن NULL ها در ستون‌های مهم
   فقط نمایش می‌دهد، چیزی حذف نمی‌کند
   ============================================================ */

SELECT *
FROM STG.SALES
WHERE FactorMId IS NULL
   OR FactorDId IS NULL
   OR Goods_ID IS NULL
   OR Goods_Code IS NULL
   OR CustCode IS NULL
   OR Qty IS NULL
   OR UPrice IS NULL;


/* ============================================================
   STEP 3 - شمارش NULL ها به تفکیک ستون
   کمک می‌کند بفهمی کدام ستون کیفیت پایین‌تری دارد
   ============================================================ */

SELECT
    SUM(CASE WHEN FactorMId IS NULL THEN 1 ELSE 0 END) AS Null_FactorMId,
    SUM(CASE WHEN FactorDId IS NULL THEN 1 ELSE 0 END) AS Null_FactorDId,
    SUM(CASE WHEN Goods_ID IS NULL THEN 1 ELSE 0 END) AS Null_Goods_ID,
    SUM(CASE WHEN Goods_Code IS NULL THEN 1 ELSE 0 END) AS Null_Goods_Code,
    SUM(CASE WHEN CustCode IS NULL THEN 1 ELSE 0 END) AS Null_CustCode,
    SUM(CASE WHEN Qty IS NULL THEN 1 ELSE 0 END) AS Null_Qty,
    SUM(CASE WHEN UPrice IS NULL THEN 1 ELSE 0 END) AS Null_UPrice
FROM STG.SALES;


/* ============================================================
   STEP 4 - پیدا کردن رشته‌های خالی یا Blank
   فقط برای ستون‌های متنی
   ============================================================ */

SELECT *
FROM STG.SALES
WHERE TRIM(ISNULL(Goods_Code, '')) = ''
   OR TRIM(ISNULL(Goods_Title, '')) = ''
   OR TRIM(ISNULL(Unit_Code, '')) = ''
   OR TRIM(ISNULL(CustCode, '')) = '';


/* ============================================================
   STEP 5 - پیدا کردن مقادیر غیرمنطقی
   نکته: قبل از حذف باید از Business مطمئن شوی
   ============================================================ */

SELECT *
FROM STG.SALES
WHERE Qty < 0
   OR UPrice < 0
   OR TotalPrice < 0
   OR SalePercent < 0
   OR SalePercent > 100;


/* ============================================================
   STEP 6 - پیدا کردن Qty یا UPrice صفر
   صفر همیشه غلط نیست؛ ممکن است اشانتیون یا برگشت باشد
   ============================================================ */

SELECT *
FROM STG.SALES
WHERE Qty = 0
   OR UPrice = 0;


/* ============================================================
   STEP 7 - بررسی Duplicate روی یک کلید احتمالی
   اینجا FactorDId را بررسی می‌کنیم
   ============================================================ */

SELECT
    FactorDId,
    COUNT(*) AS CNT
FROM STG.SALES
WHERE FactorDId IS NOT NULL
GROUP BY FactorDId
HAVING COUNT(*) > 1
ORDER BY CNT DESC;


/* ============================================================
   STEP 8 - بررسی Duplicate برای محصول
   ببین Goods_ID چند بار با اطلاعات متفاوت تکرار شده
   ============================================================ */

SELECT
    Goods_ID,
    COUNT(*) AS CNT
FROM STG.SALES
WHERE Goods_ID IS NOT NULL
GROUP BY Goods_ID
HAVING COUNT(*) > 1
ORDER BY CNT DESC;


/* ============================================================
   STEP 9 - بررسی اینکه یک Goods_ID چند عنوان متفاوت دارد
   اگر خروجی داد، نباید کورکورانه DISTINCT بزنی
   ============================================================ */

SELECT
    Goods_ID,
    COUNT(DISTINCT Goods_Title) AS TitleCount
FROM STG.SALES
WHERE Goods_ID IS NOT NULL
GROUP BY Goods_ID
HAVING COUNT(DISTINCT Goods_Title) > 1;


/* ============================================================
   STEP 10 - بررسی اینکه یک CustCode چند نام متفاوت دارد
   ============================================================ */

SELECT
    CustCode,
    COUNT(DISTINCT Name) AS NameCount
FROM STG.SALES
WHERE CustCode IS NOT NULL
GROUP BY CustCode
HAVING COUNT(DISTINCT Name) > 1;


/* ============================================================
   STEP 11 - پاک کردن فاصله اول و آخر متن
   فعلاً فقط نتیجه را نمایش می‌دهد
   ============================================================ */

SELECT
    Goods_Title,
    TRIM(Goods_Title) AS Clean_Goods_Title,

    Name,
    TRIM(Name) AS Clean_Customer_Name
FROM STG.SALES;


/* ============================================================
   STEP 12 - استانداردسازی ی و ک عربی
   فقط Preview
   ============================================================ */

SELECT
    Goods_Title,

    TRIM(
        REPLACE(
            REPLACE(Goods_Title, N'ي', N'ی'),
            N'ك', N'ک'
        )
    ) AS Clean_Goods_Title

FROM STG.SALES;


/* ============================================================
   STEP 13 - تست تبدیل نوع داده با TRY_CAST
   اگر ستون متنی باشد و عددی نباشد، NULL می‌دهد
   ============================================================ */

SELECT
    UPrice, TRY_CAST(UPrice AS DECIMAL(18,2)) AS UPrice_Number
FROM STG.SALES


/* ============================================================
   STEP 14 - پیدا کردن مقادیری که قابل تبدیل به عدد نیستند
   فقط اگر UPrice یا Qty در Source از نوع Text باشند
   ============================================================ */

SELECT *
FROM STG.SALES
WHERE TRY_CAST(UPrice AS DECIMAL(18,2)) IS NULL
  AND UPrice IS NOT NULL;


/* ============================================================
   STEP 15 - جایگزینی NULL فقط در صورت منطقی بودن Business Rule
   مثال: اگر NULL در SalePercent یعنی بدون تخفیف
   ============================================================ */

SELECT
    SalePercent,
    ISNULL(SalePercent, 0) AS Clean_SalePercent
FROM STG.SALES;


/* ============================================================
   STEP 16 - CASE WHEN برای اصلاح شرطی
   مثال آموزشی
   ============================================================ */

SELECT
    SalePercent,

    CASE
        WHEN SalePercent IS NULL THEN 0
        WHEN SalePercent < 0 THEN 0
        WHEN SalePercent > 100 THEN 100
        ELSE SalePercent
    END AS Clean_SalePercent

FROM STG.SALES;


/* ============================================================
   STEP 17 - انتخاب جدیدترین رکورد از Duplicateها
   مثال: اگر برای یک Goods_ID چند رکورد داری
   از UpdDate استفاده می‌کنیم
   ============================================================ */

WITH ProductRank AS
(
    SELECT
        *,
        ROW_NUMBER() OVER
        (
            PARTITION BY Goods_ID
            ORDER BY UpdDate DESC, UpdTime DESC
        ) AS RN
    FROM STG.SALES
    WHERE Goods_ID IS NOT NULL
)

SELECT *
FROM ProductRank
WHERE RN = 1;


/* ============================================================
   STEP 18 - ساخت یک Preview از داده تمیز
   هنوز چیزی داخل DW نمی‌ریزد
   ============================================================ */

SELECT
    FactorMId,
    FactorDId,

    CustCode,

    Goods_ID,
    Goods_Code,

    TRIM(
        REPLACE(
            REPLACE(Goods_Title, N'ي', N'ی'),
            N'ك', N'ک'
        )
    ) AS Goods_Title,

    Qty,

    UPrice,

    ISNULL(SalePercent, 0) AS SalePercent,

    TotalPrice,

    FDate

FROM STG.SALES

WHERE FactorMId IS NOT NULL
  AND FactorDId IS NOT NULL
  AND Goods_ID IS NOT NULL;


/* ============================================================
   STEP 19 - رکوردهای Reject
   یعنی رکوردهایی که فعلاً نمی‌خواهی وارد DW شوند
   ============================================================ */

SELECT *
FROM STG.SALES
WHERE FactorMId IS NULL
   OR FactorDId IS NULL
   OR Goods_ID IS NULL;


/* ============================================================
   STEP 20 - نمونه Load تمیز به FACT
   این بخش را فقط وقتی اجرا کن که DW.FACT از قبل ساخته شده باشد
   ============================================================ */

/*
INSERT INTO DW.FACT
(
    FactorMId,
    FactorDId,
    CustCode,
    Goods_ID,
    Goods_Code,
    Qty,
    UPrice,
    SalePercent,
    TotalPrice,
    FDate
)

SELECT
    FactorMId,
    FactorDId,
    CustCode,
    Goods_ID,
    Goods_Code,
    Qty,
    UPrice,
    ISNULL(SalePercent, 0),
    TotalPrice,
    FDate

FROM STG.SALES

WHERE FactorMId IS NOT NULL
  AND FactorDId IS NOT NULL
  AND Goods_ID IS NOT NULL;
*/


/* ============================================================
   STEP 21 - حذف واقعی داده
   فعلاً اجرا نکن مگر Business Rule قطعی داشته باشی
   ============================================================ */

/*
DELETE FROM STG.SALES
WHERE FactorMId IS NULL;
*/