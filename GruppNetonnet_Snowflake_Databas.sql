USE master;
IF EXISTS(SELECT * FROM sys.databases WHERE name = 'NetOnNetSales') 
	BEGIN
		ALTER DATABASE NetOnNetSales SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
		DROP DATABASE NetOnNetSales
	END
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'NetOnNetSales') 
	BEGIN
		CREATE DATABASE [NetOnNetSales]
	END
GO

USE NetOnNetSales;
GO

CREATE TABLE CityDim (
	CityID INT PRIMARY KEY IDENTITY(1,1),
	CityName NVARCHAR(255)
);

INSERT INTO CityDim 
	(CityName)
SELECT
	City
FROM NetOnNet.dbo.Users

CREATE TABLE CountryDim (
	CountryID INT PRIMARY KEY,
	CountryName NVARCHAR(255)
);

INSERT INTO CountryDim 
	(CountryID, CountryName)
SELECT
	CountryID,
	Name
FROM NetOnNet.dbo.Countries

CREATE TABLE CustomerinfoDim (
	UserID INT PRIMARY KEY,
	CityID INT,
	CountryID INT,
	Name NVARCHAR(255),
	DateOfBirth DATE
	FOREIGN KEY (CityID) REFERENCES CityDim(CityID),
	FOREIGN KEY (CountryID) REFERENCES CountryDim(CountryID)
);

INSERT INTO CustomerinfoDim 
	(UserID, CountryID, Name, DateOfBirth, CityID)
SELECT 
    u.UserID,
    u.CountryID,
    u.Name,
    u.DateOfBirth,
    c.CityID
FROM NetOnNet.dbo.Users u
INNER JOIN NetOnNetSales.dbo.CityDim c ON u.City = c.CityName;

CREATE TABLE CategoryDim (
	CategoryID INT PRIMARY KEY,
	CategoryName NVARCHAR(255)
);

INSERT INTO CategoryDim
	(CategoryID, CategoryName)
SELECT
	CategoryID,
	Name
FROM NetOnNet.dbo.Categories

CREATE TABLE SubCategoryDim (
	SubCategoryID INT PRIMARY KEY,
	SubCategoryName NVARCHAR(255)
);

INSERT INTO SubCategoryDim 
	(SubCategoryID, SubCategoryName)
SELECT
	SubCategoryID,
	Name
FROM NetOnNet.dbo.Subcategories

CREATE TABLE ProductDim (
	ProductID INT PRIMARY KEY,
	CategoryID INT,
	SubCategoryID INT,
	Name NVARCHAR(255) NOT NULL,
	Price DECIMAL(10,2)
    FOREIGN KEY (CategoryID) REFERENCES CategoryDim(CategoryID),
    FOREIGN KEY (SubCategoryID) REFERENCES SubCategoryDim(SubCategoryID)
);

INSERT INTO ProductDim 
	(ProductID, CategoryID, SubCategoryID, Name, Price)
SELECT
	p.ProductID,
	s.CategoryID,
	p.SubCategoryID,
	p.Name,
	p.Price
FROM NetOnNet.dbo.Products p
INNER JOIN NetOnNet.dbo.Subcategories s ON p.SubCategoryID = s.SubCategoryID

CREATE TABLE ReviewDim (
	ReviewID INT PRIMARY KEY,
	UserID INT,
	ProductID INT,
	Rating INT,
	CreatedAt DATE
);

INSERT INTO ReviewDim 
	(ReviewID, UserID, ProductID, Rating, CreatedAt)
SELECT
	ReviewID,
	UserID,
	ProductID,
	Rating,
	CreatedAt
FROM NetOnNet.dbo.Reviews

CREATE TABLE OrderDim (
	OrderID INT PRIMARY KEY,
	UserID INT,
	CreatedAt DATE,
	TotalValue MONEY
);

INSERT INTO OrderDim 
	(OrderID, UserID, CreatedAt, TotalValue)
SELECT
	OrderID,
	UserID,
	CreatedAt,
	TotalValue
FROM NetOnNet.dbo.Orders

CREATE TABLE PaymentMethodDim (
	PaymentMethodID INT PRIMARY KEY IDENTITY(1,1),
	PaymentMethod NVARCHAR(255)
);

INSERT INTO PaymentMethodDim 
	(PaymentMethod)
SELECT
	PaymentMethod
FROM NetOnNet.dbo.PaymentMethod

CREATE TABLE PaymentDim (
	PaymentID INT PRIMARY KEY,
	PaymentMethodID INT,
	OrderID INT,
	FOREIGN KEY (PaymentMethodID) REFERENCES PaymentMethodDim(PaymentMethodID)
);

INSERT INTO PaymentDim 
	(PaymentID, PaymentMethodID, OrderID)
SELECT
	p.PaymentID,
	p.PaymentMethodID,
	p. OrderID
FROM NetOnNet.dbo.Payments p

CREATE TABLE DateDim (
	DateID INT PRIMARY KEY IDENTITY(1,1),
	FullDateAlternateKey DATE,
	Date DATE,
	Year DATE,
	Month DATE,
	Week DATE,
	Day DATE,
	DayNumberOfYear INT,
	DayNumberOfMonth INT,
	DayNumberOfWeek INT,
	WeekNumberOfYear INT,
	WeekNumberOfMonth INT,
	MonthNumberOfYear INT
);

DECLARE @StartDate DATE = '2020-01-01';
DECLARE @EndDate DATE = '2030-12-31';

WITH DateSequence AS (
    SELECT @StartDate AS [Date]
    UNION ALL
    SELECT DATEADD(DAY, 1, [Date])
    FROM DateSequence
    WHERE [Date] < @EndDate
)
INSERT INTO DateDim (
    FullDateAlternateKey,
    Date,
    Year,
    Month,
    Week,
    Day,
    DayNumberOfYear,
    DayNumberOfMonth,
    DayNumberOfWeek,
    WeekNumberOfYear,
    WeekNumberOfMonth,
    MonthNumberOfYear
)
SELECT 
    ds.[Date] AS FullDateAlternateKey,
    ds.[Date] AS [Date],
	DATEFROMPARTS(YEAR(ds.[Date]), 1, 1) AS [Year],
    CAST(DATEFROMPARTS(YEAR(ds.[Date]), MONTH(ds.[Date]), 1) AS DATE) AS [Month],
    CAST(DATEADD(DAY, 1 - DATEPART(WEEKDAY, ds.[Date]), ds.[Date]) AS DATE) AS [Week],
    CAST(ds.[Date] AS DATE) AS [Day],
    DATEPART(DAYOFYEAR, ds.[Date]) AS DayNumberOfYear,
    DATEPART(DAY, ds.[Date]) AS DayNumberOfMonth,
    DATEPART(WEEKDAY, ds.[Date]) AS DayNumberOfWeek,
    DATEPART(WEEK, ds.[Date]) AS WeekNumberOfYear,
    DATEDIFF(WEEK, DATEADD(MONTH, DATEDIFF(MONTH, 0, ds.[Date]), 0), ds.[Date]) + 1 AS WeekNumberOfMonth,
    MONTH(ds.[Date]) AS MonthNumberOfYear
FROM DateSequence ds
OPTION (MAXRECURSION 32767);


CREATE TABLE CustomerFact (
	CustomerFactID INT PRIMARY KEY IDENTITY(1,1),
	UserID INT,
	OrderID INT,
	PaymentID INT,
	ReviewID INT,
	ProductID INT,
	DateID INT,
	TotalOrderValue MONEY,
	NumOfOrdersPerUser INT,
	FOREIGN KEY (UserID) REFERENCES CustomerinfoDim(UserID),
    FOREIGN KEY (OrderID) REFERENCES OrderDim(OrderID),
    FOREIGN KEY (PaymentID) REFERENCES PaymentDim(PaymentID),
    FOREIGN KEY (ReviewID) REFERENCES ReviewDim(ReviewID),
    FOREIGN KEY (ProductID) REFERENCES ProductDim(ProductID),
    FOREIGN KEY (DateID) REFERENCES DateDim(DateID) 
);

WITH SourceData AS (
	SELECT 
		OD.UserID,
		OD.OrderID,
		PD.PaymentID,
		RD.ReviewID,
		RD.ProductID,
		DD.DateID,
		OD2.TotalValueByEachUser AS TotalOrderValue,
		OD2.CountOfOrderByEachUser AS NumOfOrdersPerUser
	FROM [dbo].[OrderDim] AS OD
	LEFT JOIN (
		SELECT 
			UserID, 
			SUM(TotalValue) AS TotalValueByEachUser,
			COUNT(OrderID) AS CountOfOrderByEachUser 
		FROM [dbo].[OrderDim] 
		GROUP BY UserID
	) AS OD2 ON OD.UserID = OD2.UserID
	LEFT JOIN [dbo].[ReviewDim] AS RD ON RD.UserID = OD.UserID
	LEFT JOIN [dbo].[PaymentDim] AS PD ON PD.OrderID = OD.OrderID
	LEFT JOIN [dbo].[DateDim] AS DD ON OD.CreatedAt = DD.FullDateAlternateKey
)
MERGE INTO dbo.CustomerFact AS Target
USING SourceData AS Source
ON 
	Target.UserID = Source.UserID AND
	Target.OrderID = Source.OrderID AND
	Target.PaymentID = Source.PaymentID AND
	Target.ReviewID = Source.ReviewID AND
	Target.ProductID = Source.ProductID AND
	Target.DateID = Source.DateID

--  UPDATE when IDs match but values differ
WHEN MATCHED AND 
	(
		Target.TotalOrderValue <> Source.TotalOrderValue OR
		Target.NumOfOrdersPerUser <> Source.NumOfOrdersPerUser
	)
THEN UPDATE SET
	Target.TotalOrderValue = Source.TotalOrderValue,
	Target.NumOfOrdersPerUser = Source.NumOfOrdersPerUser

--  INSERT when no match found
WHEN NOT MATCHED BY TARGET
THEN INSERT (
	UserID,
	OrderID,
	PaymentID,
	ReviewID,
	ProductID,
	DateID,
	TotalOrderValue,
	NumOfOrdersPerUser
)
VALUES (
	Source.UserID,
	Source.OrderID,
	Source.PaymentID,
	Source.ReviewID,
	Source.ProductID,
	Source.DateID,
	Source.TotalOrderValue,
	Source.NumOfOrdersPerUser
);


/*
SELECT *
FROM CityDim

SELECT *
FROM CountryDim

SELECT *
FROM CustomerinfoDim

SELECT *
FROM ReviewDim

SELECT *
FROM CategoryDim

SELECT *
FROM SubCategoryDim

SELECT *
FROM ProductDim

SELECT *
FROM CustomerFact

SELECT *
FROM OrderDim

SELECT *
FROM PaymentDim

SELECT *
FROM PaymentMethodDim

SELECT *
FROM DateDim
*/
