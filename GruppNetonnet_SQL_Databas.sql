USE master; 

IF EXISTS(SELECT * FROM sys.databases WHERE name = 'NetOnNet') 
	BEGIN
		ALTER DATABASE NetOnNet SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
		DROP DATABASE NetOnNet
	END
GO

IF NOT EXISTS(SELECT * FROM sys.databases WHERE name = 'NetOnNet') 
	BEGIN
		CREATE DATABASE [NetOnNet]
	END
GO

USE NetOnNet;
GO

SET NOCOUNT ON;
GO

CREATE TABLE Countries (
    CountryID INT PRIMARY KEY IDENTITY (1,1),
    Name NVARCHAR(255) NOT NULL
);
GO

CREATE TABLE Colors (
    ColorID INT PRIMARY KEY IDENTITY (1,1),
    Name NVARCHAR(100) NOT NULL
);
GO

CREATE TABLE Reasons (
    ReasonID INT PRIMARY KEY IDENTITY (1,1),
    Name NVARCHAR(255) NOT NULL
);
GO

CREATE TABLE Campaigns (
    CampaignID INT PRIMARY KEY IDENTITY (1,1),
    Name NVARCHAR(255) NOT NULL,
    Amount DECIMAL(10,2),
    Description NVARCHAR(MAX),
    ValidFrom DATE,
    ValidTo DATE
);
GO

CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY IDENTITY (1,1),
    Name VARCHAR(255) NOT NULL,
    Description NVARCHAR(MAX)
);
GO

CREATE TABLE Shippers (
    ShipperID INT PRIMARY KEY IDENTITY (1,1),
    Name NVARCHAR(255) NOT NULL,
    Price DECIMAL(10,2),
    Description NVARCHAR(MAX)
);
GO

CREATE TABLE Manufacturers (
    ManufacturerID INT PRIMARY KEY IDENTITY (1,1),
    Name VARCHAR(255) NOT NULL,
    Address NVARCHAR(MAX),
    CountryID INT,
    Phone NVARCHAR(20),
    Email NVARCHAR(255),
    CONSTRAINT FK_Manufacturers_Countries FOREIGN KEY (CountryID) REFERENCES Countries(CountryID)
);
GO

CREATE TABLE Suppliers (
    SupplierID INT PRIMARY KEY IDENTITY (1,1),
    Name NVARCHAR(255) NOT NULL,
	ManufacturerID INT,
	CONSTRAINT FK_Suppliers_Manufacturers FOREIGN KEY (ManufacturerID) REFERENCES Manufacturers(ManufacturerID)
);
GO

CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY (1,1),
    IsMember BIT, 
    Name NVARCHAR(255) NOT NULL,
    Address NVARCHAR(MAX),
    City NVARCHAR(255),
    Phone NVARCHAR(20),
    DateOfBirth DATE NOT NULL,
    CountryID INT CHECK(CountryID IN (1, 2)),
    CONSTRAINT FK_Users_Countries FOREIGN KEY (CountryID) REFERENCES Countries(CountryID)
);
GO

CREATE TABLE Subcategories (
    SubCategoryID INT PRIMARY KEY IDENTITY (1,1),
    Name VARCHAR(255) NOT NULL,
    CategoryID INT,
    Description NVARCHAR(MAX),
    CONSTRAINT FK_Subcategories_Categories FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID)
);
GO

CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY (1,1),
    Name NVARCHAR(255) NOT NULL,
    Weight DECIMAL(10,2),
    Price DECIMAL(10,2),
    IsActive BIT,
    ColorID INT,
    Description NVARCHAR(MAX),
    SKU VARCHAR(100),
    CampaignID INT,
    SubCategoryID INT,
    SupplierID INT,
    CONSTRAINT FK_Products_Colors FOREIGN KEY (ColorID) REFERENCES Colors(ColorID),
    CONSTRAINT FK_Products_Campaigns FOREIGN KEY (CampaignID) REFERENCES Campaigns(CampaignID),
    CONSTRAINT FK_Products_Subcategories FOREIGN KEY (SubCategoryID) REFERENCES Subcategories(SubCategoryID),
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);
GO

CREATE TABLE Warehouses (
    WarehouseID INT PRIMARY KEY IDENTITY (1,1),
    Name NVARCHAR(255) NOT NULL,
    Address NVARCHAR(MAX),
    CountryID INT CHECK(CountryID IN (1, 2)),
    CONSTRAINT FK_Warehouses_Countries FOREIGN KEY (CountryID) REFERENCES Countries(CountryID)
);
GO

CREATE TABLE Stock_Items (
    StockItemID INT PRIMARY KEY IDENTITY (1,1),
    WarehouseID INT,
    Quantity INT,
    ReasonID INT,
    ProductID INT,
    CONSTRAINT FK_StockItems_Warehouses FOREIGN KEY (WarehouseID) REFERENCES Warehouses(WarehouseID),
    CONSTRAINT FK_StockItems_Reasons FOREIGN KEY (ReasonID) REFERENCES Reasons(ReasonID),
    CONSTRAINT FK_StockItems_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
GO

CREATE TABLE Product_Inventory (
    InventoryID INT PRIMARY KEY IDENTITY (1,1),
    ProductID INT,
    WarehouseID INT,
    StockLevel INT,
    ReorderLevel INT,
    ModifiedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_ProductInventory_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT FK_ProductInventory_Warehouses FOREIGN KEY (WarehouseID) REFERENCES Warehouses(WarehouseID)
);
GO

CREATE TABLE Orders (
    OrderID INT PRIMARY KEY IDENTITY (1,1),
    UserID INT,
    Discount DECIMAL(10,2),
    CreatedAt DATETIME DEFAULT GETDATE(),
    ShippedAt DATETIME,
    TotalValue DECIMAL(10,2),
    CONSTRAINT FK_Orders_Users FOREIGN KEY (UserID) REFERENCES Users(UserID)
);
GO

CREATE TABLE Shipments (
    ShipmentID INT PRIMARY KEY IDENTITY (1,1),
    OrderID INT,
    ShipperID INT, 
    TrackingNumber NVARCHAR(255),
    ShippingDate DATE,
    EstimatedDeliveryDate DATE,
    CONSTRAINT FK_Shipments_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID),
    CONSTRAINT FK_Shipments_Shippers FOREIGN KEY (ShipperID) REFERENCES Shippers(ShipperID)
);
GO

CREATE TABLE Order_Items (
    OrderItemsID INT PRIMARY KEY IDENTITY (1,1),
    ItemID INT,
    Value DECIMAL(10,2),
    Amount INT,
    CONSTRAINT FK_OrderItems_Products FOREIGN KEY (ItemID) REFERENCES Products(ProductID)
);
GO

CREATE TABLE PaymentMethod (
	PaymentMethodID INT PRIMARY KEY IDENTITY (1,1),
	PaymentMethod NVARCHAR(255)
);
GO

CREATE TABLE Payments (
    PaymentID INT PRIMARY KEY IDENTITY (1,1),
    OrderID INT,
	PaymentMethodID INT,
    PaymentDate DATETIME,
	CONSTRAINT FK_Payments_PaymentMethod FOREIGN KEY (PaymentMethodID) REFERENCES PaymentMethod(PaymentMethodID),
    CONSTRAINT FK_Payments_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);
GO

CREATE TABLE Invoices (
    InvoiceID INT PRIMARY KEY IDENTITY (1,1),
    OrderID INT,
    TotalAmount DECIMAL(10,2),
    TaxAmount DECIMAL(10,2),
    DiscountAmount DECIMAL(10,2),
    CreatedAt DATETIME DEFAULT GETDATE(),
    DueDate DATE,
    PaymentStatus NVARCHAR(100),
    CONSTRAINT FK_Invoices_Orders FOREIGN KEY (OrderID) REFERENCES Orders(OrderID)
);
GO

CREATE TABLE Reviews (
    ReviewID INT PRIMARY KEY IDENTITY (1,1),
    UserID INT,
    ProductID INT,
    Rating INT CHECK (Rating BETWEEN 1 AND 5),
    ReviewText NVARCHAR(MAX),
    CreatedAt DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Reviews_Users FOREIGN KEY (UserID) REFERENCES Users(UserID),
    CONSTRAINT FK_Reviews_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
GO

CREATE TABLE Special_Offers (
    SpecialOfferID INT PRIMARY KEY IDENTITY (1,1),
    DiscountPct DECIMAL(5,2),
    StartDate DATE,
    EndDate DATE,
    MinQty INT,
    MaxQty INT
);
GO

CREATE TABLE Special_Offer_Products (
    ProductID INT,
    SpecialOfferID INT,
    PRIMARY KEY (ProductID, SpecialOfferID),
    CONSTRAINT FK_SpecialOfferProducts_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT FK_SpecialOfferProducts_SpecialOffers FOREIGN KEY (SpecialOfferID) REFERENCES Special_Offers(SpecialOfferID)
);
GO

INSERT INTO Countries
	(Name)
VALUES
    ('Sweden'),
    ('Norway'),
    ('Denmark'),
    ('Finland'),
    ('Iceland'),
    ('Germany'),
    ('France'),
    ('United Kingdom'),
    ('United States'),
    ('Canada'),
    ('Australia'),
    ('Japan'),
    ('China'),
    ('Brazil'),
    ('South Africa');

INSERT INTO Colors
	(Name)
VALUES
    ('Red'),
    ('Blue'),
    ('Green'),
    ('Yellow'),
    ('Orange'),
    ('Purple'),
    ('Pink'),
    ('Brown'),
    ('Black'),
    ('White'),
    ('Gray'),
    ('Cyan'),
    ('Magenta'),
    ('Lime'),
    ('Maroon'),
    ('Navy'),
    ('Olive'),
    ('Teal'),
    ('Silver'),
    ('Gold');

INSERT INTO Reasons
	(Name)
VALUES
	('Customer Request'),
	('System Error'),
	('Manual Adjustment'),
	('Inventory Shortage'),
	('Product Defect'),
	('Supplier Delay'),
	('Pricing Error'),
	('Policy Update'),
	('Fraud Prevention'),
	('Quality Control'),
	('User Mistake'),
	('Technical Issue'),
	('Warranty Claim'),
	('Return Request'),
	('Compliance Requirement');


INSERT INTO Campaigns
	(Name, Amount, Description, ValidFrom, ValidTo)
VALUES
	('Spring Sale','15','Discounts on all spring collection', '2025-04-01', '2025-04-15'),
	('Summer Clearance','25','End of season clearance sale', '2025-06-10', '2025-06-30'),
	('Black Friday Deals','50','Biggest discounts of the year', '2025-11-22', '2025-11-29'),
	('Cyber Monday','40','Online exclusive discounts', '2025-12-01', '2025-12-01'),
	('Back to School','20','Discounts on school supplies', '2025-08-01', '2025-08-15'),
	('Holiday Special','30','Festive season discounts', '2025-12-15', '2025-12-31'),
	('Valentine’s Day','10','Special deals for couples', '2025-02-07', '2025-02-14'),
	('Easter Promotion','15','Spring holiday offers', '2025-03-28', '2025-04-05'),
	('Anniversary Sale','20','Celebrating our company anniversary', '2025-09-01', '2025-09-10'),
	('Tech Week','35','Discounts on electronics and gadgets', '2025-07-05', '2025-07-12'),
	('Fitness Frenzy','25','Deals on sports and fitness gear', '2025-05-10', '2025-05-20'),
	('Luxury Days','40','Premium brands at discounted prices', '2025-10-01', '2025-10-07'),
	('Weekend Flash Sale','15','Limited time weekend-only offers', '2025-03-15', '2025-03-17'),
	('Green Week','20','Eco-friendly products discounts', '2025-06-05', '2025-06-12'),
	('Exclusive Members Sale','30','Special discounts for members', '2025-11-10', '2025-11-17');

INSERT INTO Categories
	(Name, Description)
VALUES
	('Laptops', 'Various laptops including gaming, business, and ultrabooks'),
	('Smartphones', 'Latest smartphones from top brands'),
	('Televisions', 'LED, OLED, and QLED TVs in various sizes'),
	('Headphones', 'Over-ear, in-ear, and noise-canceling headphones'),
	('Smart Home', 'Smart speakers, lights, and automation devices'),
	('Cameras', 'DSLRs, mirrorless, and action cameras'),
	('Gaming', 'Consoles, gaming PCs, and accessories'),
	('Kitchen Appliances', 'Blenders, coffee makers, and microwaves'),
	('Wearables', 'Smartwatches and fitness trackers'),
	('Tablets', 'iPads and Android tablets for work and entertainment'),
	('Monitors', 'Computer monitors for work and gaming'),
	('PC Components', 'Graphics cards, processors, and RAM'),
	('Networking', 'Routers, extenders, and networking gear'),
	('Audio Systems', 'Speakers, soundbars, and home theater systems'),
	('Vacuum Cleaners', 'Robot vacuums, handheld, and traditional vacuums');


INSERT INTO Subcategories
	(Name, CategoryID, Description)
VALUES
	('Gaming Laptops', 1, 'High-performance laptops for gaming'),
	('Business Laptops', 1, 'Laptops designed for productivity and office use'),
	('Android Phones', 2, 'Smartphones running the Android OS'),
	('iPhones', 2, 'Apple smartphones with iOS'),
	('4K TVs', 3, 'Ultra HD televisions with 4K resolution'),
	('OLED TVs', 3, 'High-end OLED screen televisions'),
	('Wireless Headphones', 4, 'Bluetooth-enabled headphones'),
	('Noise Cancelling Headphones', 4, 'Headphones with active noise cancellation'),
	('Smart Speakers', 5, 'Voice-controlled smart speakers'),
	('Smart Lighting', 5, 'Wi-Fi and app-controlled light systems'),
	('DSLR Cameras', 6, 'Digital single-lens reflex cameras'),
	('Gaming Consoles', 7, 'Popular gaming consoles like PlayStation and Xbox'),
	('Blenders', 8, 'Kitchen appliances for blending and mixing'),
	('Smartwatches', 9, 'Wearable smart devices with fitness tracking features'),
	('Wi-Fi Routers', 13, 'Networking devices for high-speed internet connectivity');

INSERT INTO Manufacturers
	(Name, Address, CountryID, Phone, Email)
VALUES
	('Apple', 'One Apple Park Way, Cupertino, CA, USA', 1, '+1-800-275-2273', 'contact@apple.com'),
	('Samsung', '40th Fl., Samsung Electronics Bldg., Seoul, South Korea', 2, '+82-2-2255-0114', 'support@samsung.com'),
	('Sony', '1-7-1 Konan, Minato-ku, Tokyo, Japan', 3, '+81-3-6748-2111', 'info@sony.com'),
	('Dell', '1 Dell Way, Round Rock, TX, USA', 1, '+1-800-624-9897', 'sales@dell.com'),
	('HP', '1501 Page Mill Road, Palo Alto, CA, USA', 1, '+1-650-857-1501', 'contact@hp.com'),
	('Lenovo', 'No.6 Chuang Ye Road, Beijing, China', 4, '+86-10-5886-8888', 'support@lenovo.com'),
	('Microsoft', 'One Microsoft Way, Redmond, WA, USA', 1, '+1-425-882-8080', 'support@microsoft.com'),
	('LG', '128 Yeoui-daero, Yeongdeungpo-gu, Seoul, South Korea', 2, '+82-2-3777-1114', 'contact@lg.com'),
	('Asus', '15 Li-Te Rd., Beitou Dist., Taipei, Taiwan', 5, '+886-2-2894-3447', 'info@asus.com'),
	('Acer', '8F, 88, Sec. 1, Xintai 5th Rd., New Taipei City, Taiwan', 5, '+886-2-2696-1234', 'support@acer.com'),
	('Huawei', 'Huawei HQ, Bantian, Shenzhen, China', 4, '+86-755-2878-0808', 'contact@huawei.com'),
	('Bose', 'The Mountain, Framingham, MA, USA', 1, '+1-800-379-2073', 'support@bose.com'),
	('Philips', 'High Tech Campus 5, Eindhoven, Netherlands', 6, '+31-20-59-77777', 'contact@philips.com'),
	('Panasonic', '1006, Oaza Kadoma, Kadoma-shi, Osaka, Japan', 3, '+81-6-6908-1121', 'support@panasonic.com'),
	('Nvidia', '2701 San Tomas Expressway, Santa Clara, CA, USA', 1, '+1-408-486-2000', 'info@nvidia.com');

INSERT INTO Suppliers
	(Name, ManufacturerID)
VALUES
	('Ingram Micro', 1),
	('Tech Data', 2),
	('Arrow Electronics', 3),
	('Synnex', 4),
	('Avnet', 5),
	('D&H Distributing', 6),
	('Westcoast', 7),
	('Exertis', 8),
	('TD Synnex', 9),
	('Also Holding', 10),
	('Esprinet', 11),
	('ABC Data', 12),
	('ASBIS', 13),
	('ELKO Group', 14),
	('Copaco', 15);

INSERT INTO Products
	(Name, Weight, Price, IsActive, ColorID, Description, SKU, CampaignID, SubCategoryID, SupplierID)
VALUES
	('Apple MacBook Air M2', 1.24, 14990, 1, 1, '13.6" Retina, 8GB RAM, 256GB SSD', 'MBAIR2023', 1, 1, 1),
	('Asus ROG Zephyrus G14', 1.6, 19990, 1, 2, '14" QHD, Ryzen 9, RTX 4060, 16GB RAM, 1TB SSD', 'ROGZEPH14', 2, 1, 2),
	('Samsung Galaxy S23 Ultra', 0.234, 13990, 1, 3, '6.8" AMOLED, 256GB, 200MP Kamera', 'SGS23U256', 3, 3, 3),
	('iPhone 15 Pro Max', 0.221, 17990, 1, 4, '6.7" Super Retina XDR, 256GB', 'IP15PM256', 4, 4, 1),
	('Sony WH-1000XM5', 0.25, 3990, 1, 5, 'Trådlösa brusreducerande hörlurar', 'WH1000XM5', 5, 7, 6),
	('LG OLED C3 65”', 14.5, 17990, 1, 6, '65” 4K OLED Smart TV, Dolby Vision', 'LGOLED65C3', 6, 5, 8),
	('Bose QuietComfort Ultra', 0.24, 4990, 1, 7, 'Trådlösa over-ear hörlurar', 'BOSEQCULTRA', 7, 8, 12),
	('Philips Hue Starter Kit', 1.2, 1990, 1, 8, '3-pack smarta LED-lampor + brygga', 'PHUESTART3', 8, 10, 14),
	('GoPro Hero 12 Black', 0.32, 4990, 1, 9, '5.3K video, vattentät, actionkamera', 'GPHERO12B', 9, 11, 5),
	('Sony PlayStation 5', 4.5, 6990, 1, 10, 'Spelkonsol, 4K HDR, DualSense-kontroll', 'PS5STD', 10, 12, 3),
	('Nvidia RTX 4080 Super', 1.9, 12990, 1, 11, '16GB GDDR6X, Ray Tracing, DLSS 3.0', 'RTX4080S', 11, 12, 15),
	('Lenovo Legion 5 Pro', 2.4, 17990, 1, 12, '16" 165Hz, Ryzen 7, RTX 4070, 32GB RAM, 1TB SSD', 'LEGION5PRO', 12, 1, 6),
	('Samsung Galaxy Tab S9', 0.58, 9990, 1, 13, '11" AMOLED, Snapdragon 8 Gen 2, 256GB', 'SGTABS9', 13, 10, 2),
	('Dyson V15 Detect', 3.1, 7990, 1, 14, 'Sladdlös dammsugare med laser och HEPA-filter', 'DYSONV15', 14, 15, 7),
	('TP-Link Deco X90', 1.5, 3990, 1, 15, 'Wi-Fi 6 Mesh-system, upp till 6600 Mbps', 'TPLDECOX90', 15, 15, 9);

INSERT INTO Users
	(IsMember, Name, Address, City, Phone, DateOfBirth, CountryID)
VALUES
    ('1', 'Johan Andersson', 'Storgatan 12', 'Stockholm', '0701234567', '1985-07-15', 1),
    ('0', 'Kari Hansen', 'Karl Johans gate 8', 'Oslo', '4732345678', '1992-03-22', 2), 
    ('1', 'Emilie Svensson', 'Lilla Nygatan 14', 'Göteborg', '0709876543', '1988-11-10', 1), 
    ('1', 'Erik Solberg', 'Dronningens gate 5', 'Bergen', '4761234567', '1995-06-30', 2), 
    ('0', 'Eva Lund', 'Hamngatan 20', 'Malmö', '0723456789', '1980-04-05', 1), 
    ('1', 'Lars Pettersen', 'Kirkegata 22', 'Trondheim', '4733456789', '1994-02-13', 2),
    ('0', 'Sofia Nilsson', 'Vasagatan 18', 'Uppsala', '0704567890', '1983-12-25', 1), 
    ('1', 'Magnus Berg', 'Kungsgatan 11', 'Helsingborg', '0722345678', '1990-10-30', 1), 
    ('0', 'Petra Eriksen', 'Bryggen 17', 'Stavanger', '4762345678', '1987-09-12', 2), 
    ('1', 'Fredrik Johansson', 'Sveavägen 3', 'Örebro', '0708765432', '1991-05-18', 1), 
    ('0', 'Linnea Karlsson', 'Rådhusgatan 10', 'Jönköping', '0721234567', '1990-08-25', 1), 
    ('1', 'Anders Olsen', 'Nygata 15', 'Drammen', '4738765432', '1993-01-09', 2), 
    ('0', 'David Brown', 'Hammarbyvägen 6', 'Umeå', '0702345678', '1984-11-04', 1), 
    ('1', 'Caroline Wilson', 'Strandgatan 9', 'Kristiansand', '4723456789', '1997-02-28', 2), 
    ('1', 'Oscar King', 'Nobelvägen 13', 'Lund', '0732345678', '1989-07-07', 1); 

INSERT INTO Orders
	(UserID, Discount, CreatedAt, ShippedAt, TotalValue)
VALUES
	(1, '200', '2025-02-15', '2025-02-18', '1200'),
	(2, '150', '2025-02-20', '2025-02-23', '850'),
	(3, '300', '2025-02-25', '2025-02-28', '1500'),
	(4, '100', '2025-03-01', '2025-03-04', '600'),
	(5, '250', '2025-03-03', '2025-03-06', '1300'),
	(6, '180', '2025-03-05', '2025-03-08', '950'),
	(7, '120', '2025-03-07', '2025-03-10', '750'),
	(8, '400', '2025-03-10', '2025-03-14', '2000'),
	(9, '220', '2025-03-12', '2025-03-15', '1100'),
	(10, '90', '2025-03-15', '2025-03-18', '580'),
	(11, '310', '2025-03-17', '2025-03-20', '1550'),
	(12, '275', '2025-03-20', '2025-03-23', '1375'),
	(13, '160', '2025-03-22', '2025-03-25', '890'),
	(14, '340', '2025-03-24', '2025-03-27', '1700'),
	(15, '200', '2025-03-27', '2025-03-30', '1200'),
	(3, '130', '2025-03-29', '2025-04-02', '780'),
	(5, '270', '2025-03-31', '2025-04-03', '1350'),
	(7, '180', '2025-04-02', '2025-04-05', '900'),
	(9, '250', '2025-04-04', '2025-04-07', '1250'),
	(12, '300', '2025-04-06', '2025-04-09', '1500');

INSERT INTO Order_Items
	(ItemID, Value, Amount)
VALUES
	(1, '14990', '1'),
	(2, '19990', '1'),
	(3, '13990', '2'),
	(4, '17990', '1'),
	(5, '3990', '3'),
	(6, '17990', '1'),
	(7, '4990', '2'),
	(8, '1990', '4'),
	(9, '4990', '1'),
	(10, '6990', '2'),
	(11, '12990', '1'),
	(12, '17990', '1'),
	(13, '9990', '2'),
	(14, '7990', '1'),
	(15, '3990', '3');

INSERT INTO Invoices
	(OrderID, TotalAmount, TaxAmount, DiscountAmount, DueDate, PaymentStatus)
VALUES
	(1, '1200', '120', '200', '2025-02-18', 'Paid'),
	(2, '850', '85', '150', '2025-02-23', 'Paid'),
	(3, '1500', '150', '300', '2025-02-28', 'Unpaid'),
	(4, '600', '60', '100', '2025-03-04', 'Paid'),
	(5, '1300', '130', '250', '2025-03-06', 'Paid'),
	(6, '950', '95', '180', '2025-03-08', 'Unpaid'),
	(7, '750', '75', '120', '2025-03-10', 'Paid'),
	(8, '2000', '200', '400', '2025-03-14', 'Unpaid'),
	(9, '1100', '110', '220', '2025-03-15', 'Paid'),
	(10, '580', '58', '90', '2025-03-18', 'Paid'),
	(11, '1550', '155', '310', '2025-03-20', 'Unpaid'),
	(12, '1375', '138', '275', '2025-03-23', 'Paid'),
	(13, '890', '89', '160', '2025-03-25', 'Paid'),
	(14, '1700', '170', '340', '2025-03-27', 'Unpaid'),
	(15, '1200', '120', '200', '2025-03-30', 'Paid');

INSERT INTO PaymentMethod
	(PaymentMethod)
VALUES
	('Card'),
	('Bank Transfer'),
	('PayPal')

INSERT INTO Payments
    (PaymentMethodID, OrderID, PaymentDate)
VALUES
    (1, 1, '2025-02-18'),
    (2, 2, '2025-02-22'),
    (3, 3, '2025-02-28'),
    (1, 4, '2025-03-04'),
    (1, 5, '2025-03-06'),
    (2, 6, '2025-03-08'),
    (3, 7, '2025-03-10'),
    (1, 8, '2025-03-14'),
    (2, 9, '2025-03-15'),
    (1, 10, '2025-03-18'),
    (3, 11, '2025-03-20'),
    (2, 12, '2025-03-23'),
    (1, 13, '2025-03-25'),
    (3, 14, '2025-03-27'),
    (2, 15, '2025-03-30');


INSERT INTO Shippers
	(Name, Price, Description)
VALUES
	('DHL Express', '149', 'Fast international and domestic shipping.'),
	('FedEx', '129', 'Reliable global courier services.'),
	('UPS', '139', 'Secure and timely package deliveries.'),
	('PostNord', '99', 'Nordic postal and logistics solutions.'),
	('DB Schenker', '179', 'Comprehensive freight and logistics services.'),
	('Bring', '109', 'Scandinavian parcel and freight delivery.'),
	('GLS', '119', 'Efficient European parcel delivery network.'),
	('TNT', '159', 'Express shipping and logistics solutions.'),
	('USPS', '89', 'United States Postal Service.'),
	('Royal Mail', '99', 'UK’s national mail and parcel carrier.'),
	('Hermes', '109', 'Affordable European shipping services.'),
	('Yodel', '119', 'UK parcel delivery and logistics.'),
	('Purolator', '139', 'Canadian parcel and freight shipping.'),
	('Japan Post', '149', 'Reliable shipping across Japan and worldwide.'),
	('China Post', '89', 'Affordable shipping within China and globally.');

INSERT INTO Shipments
	(OrderID, ShipperID, TrackingNumber, ShippingDate, EstimatedDeliveryDate)
VALUES
	(1, 4, 'RR123456789SE', '2025-03-06', '2025-03-09'),
	(2, 4, 'RR987654321SE', '2025-03-08', '2025-03-11'),
	(3, 1, 'RR567890123SE', '2025-03-10', '2025-03-13'),
	(4, 2, 'RR234567890SE', '2025-03-12', '2025-03-14'),
	(5, 4, 'RR345678901SE', '2025-03-15', '2025-03-18'),
	(6, 6, 'RR456789012SE', '2025-03-17', '2025-03-20'),
	(7, 3, 'RR567890124SE', '2025-03-20', '2025-03-23'),
	(8, 5, 'RR678901235SE', '2025-03-22', '2025-03-26'),
	(9, 4, 'RR789012346SE', '2025-03-25', '2025-03-28'),
	(10, 9, 'RR890123457SE', '2025-03-27', '2025-03-30'),
	(11, 10, 'RR901234568SE', '2025-03-29', '2025-04-01'),
	(12, 12, 'RR012345679SE', '2025-04-01', '2025-04-04'),
	(13, 4, 'RR123456780SE', '2025-04-03', '2025-04-06'),
	(14, 8, 'RR234567891SE', '2025-04-06', '2025-04-09'),
	(15, 7, 'RR345678902SE', '2025-04-08', '2025-04-11');

INSERT INTO Warehouses
	(Name, Address, CountryID)
VALUES
    ('Borås Viared Lagershop', 'Viaredsvägen 14a, 50464 Borås', 1),
    ('Falun Lagershop', 'Bataljonsvägen 9, 79140 Falun', 1),
    ('Göteborg Hisings Backa Lagershop', 'Exportgatan 20, 42246 Hisings Backa', 1),
    ('Göteborg Järnbrott Lagershop', 'Axel Adlers gata 4, 42132 Frölunda', 1),
    ('Halmstad Lagershop', 'Ryttarevägen 5, 30262 Halmstad', 1),
    ('Helsingborg Lagershop', 'Andesitgatan 16, 25468 Helsingborg', 1),
    ('Jönköping Lagershop', 'Vasavägen 3, 55454 Jönköping', 1),
    ('Stockholm Slagsta Lagershop', 'Fågelviksvägen 5, 14553 Norsborg', 1),
    ('Oslo Alnabru Lagershop', 'Strømsveien 266, 0668 Oslo', 2),
    ('Bergen Åsane Lagershop', 'Hesthaugvegen 16, 5119 Ulset', 2);

INSERT INTO Product_Inventory
	(ProductID, WarehouseID, StockLevel, ReorderLevel)
VALUES
    (1, 1, 15, 10),
    (2, 2, 30, 20),
    (3, 3, 8, 5),
    (4, 1, 50, 25),
    (5, 2, 12, 10),
    (6, 3, 22, 15),
    (7, 1, 18, 12),
    (8, 2, 5, 8),
    (9, 3, 40, 30),
    (10, 1, 6, 10),
    (11, 2, 25, 20),
    (12, 3, 35, 25),
    (13, 1, 10, 15),
    (14, 2, 28, 22),
    (15, 3, 14, 10);

INSERT INTO Stock_Items
	(WarehouseID, Quantity, ReasonID, ProductID)
VALUES
    (3,  520,  5,  7),
    (7,  310, 12,  3),
    (1,  450,  8, 10),
    (10, 200,  6,  5),
    (5,  600,  2, 15),
    (9,  275, 14, 11), 
    (8,  480,  9, 13), 
    (2,  720,  4,  6),
    (6,  340, 13,  2),
    (10, 560,  1,  8),
    (5,  150,  7, 12), 
    (8,  410, 11,  4),
    (4,  530,  3,  1),
    (7,  300, 10,  9), 
    (3,  620, 15, 14); 

INSERT INTO Special_Offers
	(DiscountPct, StartDate, EndDate, MinQty, MaxQty)
VALUES
    ('10.00', '2025-02-01', '2025-02-07', 1, 3),
    ('15.00', '2025-03-10', '2025-03-15', 2, 6),
    ('20.00', '2025-04-05', '2025-04-12', 1, 4),
    ('25.00', '2025-05-01', '2025-05-10', 3, 8),
    ('30.00', '2025-06-15', '2025-06-20', 1, 5),
    ('12.50', '2025-07-01', '2025-07-05', 2, 7),
    ('40.00', '2025-08-20', '2025-08-30', 1, 10),
    ('18.00', '2025-09-10', '2025-09-15', 1, 3),
    ('22.00', '2025-10-05', '2025-10-12', 2, 5),
    ('28.00', '2025-11-01', '2025-11-07', 3, 6),
    ('35.00', '2025-12-15', '2025-12-25', 1, 4),
    ('45.00', '2026-01-05', '2026-01-10', 2, 9),
    ('50.00', '2026-02-14', '2026-02-20', 1, 2),
    ('8.00',  '2026-03-01', '2026-03-07', 1, 6),
    ('55.00', '2026-04-10', '2026-04-18', 3, 12);

INSERT INTO Special_Offer_Products
	(ProductID, SpecialOfferID)
VALUES
    (1, 3),
    (2, 5),
    (3, 7),
    (4, 2),
    (5, 10),
    (6, 12),
    (7, 8),
    (8, 6),
    (9, 1),
    (10, 9),
    (11, 4),
    (12, 11),
    (13, 14),
    (14, 13),
    (15, 15);

INSERT INTO Reviews
	(UserID, ProductID, Rating, ReviewText)
VALUES
    (3, 5, '5', 'Absolutely love this product! High quality and great value.'),
    (7, 12, '2', 'Disappointed with the build quality. Not worth the price.'),
    (10, 3, '4', 'Good product overall, but shipping took too long.'),
    (2, 8, '3', 'It’s okay, does the job but nothing special.'),
    (15, 1, '5', 'Exceeded my expectations! Would buy again.'),
    (5, 14, '1', 'Stopped working after a week. Very disappointed.'),
    (8, 7, '4', 'Works well, but could be slightly cheaper.'),
    (12, 10, '3', 'Average performance, had higher hopes.'),
    (1, 9, '5', 'Fantastic product! Super happy with my purchase.'),
    (6, 2, '2', 'Not what I expected. Feels cheap.'),
    (9, 6, '4', 'Does what it says. No complaints.'),
    (11, 11, '3', 'Nothing special, but not bad either.'),
    (4, 15, '5', 'Great product! Highly recommended.'),
    (14, 4, '1', 'Broke within a month. Avoid this.'),
    (13, 13, '2', 'Quality control issues. Not satisfied.'),
    (2, 5, '4', 'Good overall, but some minor flaws.'),
    (7, 3, '3', 'Decent product, but expected better.'),
    (10, 8, '5', 'Best purchase I have made this year!'),
    (15, 12, '2', 'Not worth the money, would not buy again.'),
    (5, 1, '3', 'Mediocre experience, nothing too bad.'),
    (8, 14, '4', 'Nice and functional, but a little pricey.'),
    (6, 11, '5', 'Impressed with the quality.'),
    (1, 7, '2', 'Had some issues, but customer service was helpful.'),
    (9, 9, '4', 'Good value for money, would recommend.'),
    (3, 15, '1', 'Arrived damaged. Very poor experience.');

/* Contains all SELECT-Statements for all tables. Remove /* and */ if you want to use them.
SELECT * 
FROM Countries

SELECT * 
FROM Colors

SELECT * 
FROM Reasons

SELECT * 
FROM Campaigns

SELECT * 
FROM Categories

SELECT * 
FROM Subcategories

SELECT * 
FROM Manufacturers

SELECT * 
FROM Suppliers

SELECT p.*, c.Name 
FROM Products p
INNER JOIN Colors c ON p.ColorID = c.ColorID

SELECT * 
FROM Users

SELECT * 
FROM Orders

SELECT * 
FROM Order_Items

SELECT * 
FROM Invoices

SELECT * 
FROM Payments

SELECT * 
FROM Shippers

SELECT * 
FROM Shipments

SELECT * 
FROM Warehouses

SELECT * 
FROM Product_Inventory

SELECT * 
FROM Stock_Items

SELECT * 
FROM Special_Offers

SELECT * 
FROM Special_Offer_Products

SELECT * 
FROM Reviews
*/