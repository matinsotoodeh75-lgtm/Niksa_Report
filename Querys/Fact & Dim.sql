----------------------------------------------------------------------------------------------------------
SELECT DISTINCT
    P.CounterPartNo,
    U.FK_intPersonCode,
    LTRIM(RTRIM(P.FName_AbvName)) as FName_AbvName,
    LTRIM(RTRIM(P.LName_CompName)) as LName_CompName ,
    LTRIM(RTRIM(CONCAT(
        P.FName_AbvName,
        N' ',
        P.LName_CompName
    ))) AS EmployeeFullName,

    P.FatherName_OfficeMgrName

INTO stg.DimEmployee

FROM [IMPORTDATA].[pegah].dbo.Dash_OS_V_PayrollPersonel AS P

LEFT JOIN [IMPORTDATA].[pegah].dbo.Com_CounterParts AS CCP
    ON CCP.CounterPartRecID = P.CounterPartRecID

LEFT JOIN [IMPORTDATA].[pegah].dbo.Tef_User AS U
    ON U.FK_intPersonCode = CCP.CounterPartRecID

WHERE P.CounterPartNo IS NOT NULL;

UPDATE stg.DimEmployee
SET EmployeeFullName = N'جواد انوری'
WHERE EmployeeFullName = N'جواد  انوری';

SELECT *
FROM stg.DimEmployee


SELECT CounterPartNo,COUNT(CounterPartNo)
FROM stg.DimEmployee group by CounterPartNo
HAVING COUNT(CounterPartNo)>1

DROP TABLE STG.DimEmployee
-----------------------------------------------------------------------------------------------------------------
SELECT
M.FactorMId,
M.FactorNo,
M.DefinableNo,
CONCAT(
    CAST(D.FactorMId AS VARCHAR(50)),
    '|',
    CAST(D.FactorDId AS VARCHAR(50))
) AS FactorLineKey ,
CONCAT( CAST(M.[CustCode] AS VARCHAR(50)),
	'|', CAST(M.[DistributionCode] AS VARCHAR(50)) ) AS CustomerDistributionKey,
CONCAT( CAST(D.Goods_Code AS VARCHAR(50)), '|', CAST(D.Unit_Code AS VARCHAR(50)))
AS Goods_unit_code,
M.AInfoSysID,
M.FDate,
M.DistributionCode,
D.FactorDId,
D.RowNumber,
M.CustCode,
M.CustomersCPRID,
D.Goods_ID,
D.Goods_Code,
D.ValueSysID,
D.WarehouseID,
D.Warehouse_Code,
M.SaleExpertCode,
M.DeliveryPlaceCode,
M.CapillaryDivisionCode,
M.MarketDivCode,
M.CategoryCode,
M.SaleStyleCode,
M.DeputyCode,
M.SaleManagerCode,
M.SellerCustomsCode,
E.CounterPartNo,
D.Qty / 1000.0 AS Qty,
D.UPrice/ 10.0 AS UPrice,         
D.TotalPrice / 10.0 AS TotalPrice, 
M.StatusFlag,
D.FactorDStatus

INTO stg.FactSales FROM [IMPORTDATA].[pegah].dbo.Dash_OS_V_SaleFactorM AS M 

INNER JOIN 
[IMPORTDATA].[pegah].dbo.Dash_OS_V_SaleFactorDGoods AS D
ON D.FactorMId = M.FactorMId

LEFT JOIN stg.DimEmployee AS E ON LTRIM(RTRIM(M.ReghUser)) = LTRIM(RTRIM(E.EmployeeFullName));


SELECT * FROM stg.FactSales

DROP TABLE stg.FactSales
-------------------------------------------------------------------------------------------------------------
SELECT
    CONCAT(
        CAST(D.FactorMId AS VARCHAR(50)),
        '|',
        CAST(D.FactorDId AS VARCHAR(50))
    ) AS FactorLineKey,

    D.FactorMId,
    D.FactorDId,
    M.FDate,
	P.ParameterCode,
    P.ParameterName,
    ISNULL(P.Amount, 0) / 10.0 AS Amount

INTO stg.FactParameter

FROM [IMPORTDATA].[pegah].dbo.Dash_OS_V_SaleFactorDGoods AS D

INNER JOIN [IMPORTDATA].[pegah].dbo.Dash_OS_V_SaleFactorDParameter AS P
    ON P.SanadId = D.FactorDId

INNER JOIN [IMPORTDATA].[pegah].dbo.Dash_OS_V_SaleFactorM AS M
    ON M.FactorMId = D.FactorMId;
ALTER TABLE stg.FactParameter ALTER COLUMN Amount int

SELECT * FROM stg.FactParameter

DROP TABLE stg.FactParameter
--------------------------------------------------------------------------------------------------------------
SELECT DISTINCT ParameterCode, ParameterName , ParameterType
into stg.DimParameter
from [IMPORTDATA].[pegah].dbo.Dash_OS_V_SaleFactorDParameter
WHERE ParameterCode IS NOT NULL

SELECT * FROM stg.DimParameter

DROP TABLE stg.DimParameter

--------------------------------------------------------------------------------------------------------------
SELECT DISTINCT
    M.[CustCode],
	 CONCAT(
		  CAST(M.[CustCode] AS VARCHAR(50)),
        '|',
        CAST(M.[DistributionCode] AS VARCHAR(50))
    ) AS CustomerDistributionKey,
    LTRIM(RTRIM(M.[Name])) AS [Name],
	S.[CustomersCPRID],
    S.[Cust_type],
    S.[VatStatuse_Type],
    S.[SaleExpertCode],
    S.[CapillaryDivisionCode],
    S.[CapillaryDivisionName],
    S.[MarketDivCode],
    S.[MarketDivName],
    S.[CustSerialCode],
    S.[CustSerialName],
    S.[CategoryCode],
    S.[CategoryName],
	M.[DistributionCode],
	M.[DistributionName]

INTO stg.DimCustomer

FROM [IMPORTDATA].[pegah].dbo.Dash_OS_V_SaleFactorM AS M

LEFT JOIN [IMPORTDATA].[pegah].dbo.Dash_OS_V_SaleReturnM AS S
    ON M.[CustCode] = S.[CustCode]

WHERE M.[CustCode] IS NOT NULL 

SELECT CustomerDistributionKey,COUNT(CustomerDistributionKey) FROM stg.DimCustomer group by CustomerDistributionKey HAVING COUNT(CustomerDistributionKey)>1

SELECT * FROM stg.DimCustomer 


DROP TABLE stg.DimCustomer

------------------------------------------------------------------------------------------------------------------
SELECT DISTINCT
    G.Goods_ID,
	CONCAT(
        CAST(G.Goods_Code AS VARCHAR(50)),
        '|',
        CAST(S.Unit_Code AS VARCHAR(50))
    ) AS Goods_unit_code,
    G.GoodsKind_Code,
    G.GoodsKind_Title,
    G.Goods_Code,
    G.Goods_Title,
    G.GoodsCategory_Code,
    G.GoodsCategory_Title,
	S.Unit_Code,
	S.Unit_Title

INTO stg.DimProduct
FROM [IMPORTDATA].[pegah].dbo.Dash_OS_V_GeneralGoods AS G
LEFT JOIN [IMPORTDATA].[pegah].dbo.Dash_OS_V_SaleFactorDGoods AS S
    ON G.Goods_Code = S.Goods_Code
WHERE G.GoodsKind_Title= N'محصول'    OR G.Goods_Code IN
    (   '6020006',
        '03010009',
        '03010010',
        '03010016',
        '03020017',
        '06010001',
		'06020006'
    );
UPDATE stg.DimProduct
SET GoodsCategory_Title =
    CASE
        WHEN GoodsCategory_Code = 10 THEN N'فیله'
        WHEN GoodsCategory_Code = 15 THEN N'ماهی تازه'
        ELSE GoodsCategory_Title
    END
WHERE GoodsCategory_Code IN (10, 15);

SELECT * FROM stg.DimProduct

DROP TABLE stg.DimProduct

-------------------------------------------------------------------------------------------------------------------
SELECT DISTINCT  
[Warehouse_ID],
[Warehouse_Code],
[Warehouse_Title],
[Warehouse_Address]
INTO stg.DimWarehouse
FROM [IMPORTDATA].[pegah].dbo.Dash_OS_V_GeneralWarehouse  WHERE WarehouseType_Title= N'محصول' AND [Warehouse_ID] IS NOT NULL

SELECT [Warehouse_Code],COUNT(*) FROM stg.DimWarehouse
GROUP BY [Warehouse_Code] HAVING COUNT(*)>1

SELECT  * FROM stg.DimWarehouse

DROP TABLE stg.DimWarehouse

--------------------------------------------------------------------------------------------------------------------------
DROP TABLE STG.DimCustomer
DROP TABLE STG.DimProduct
DROP TABLE STG.DimWarehouse
DROP TABLE STG.DimDistribution
DROP TABLE STG.DimEmployee
DROP TABLE [stg].[Unit_CodeS]


SELECT * FROM STG.DimCustomer
SELECT * FROM STG.DimProduct
SELECT * FROM STG.DimWarehouse
SELECT * FROM STG.DimEmployee
SELECT * FROM STG.DimDistribution
select * from [stg].[Unit_CodeS]



-------------------------------------------------------------------------------------------------------------
