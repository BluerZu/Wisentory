--Creando un nuevo usuario para conectarse a la base de datos.
USE master;
CREATE LOGIN WisentoryManager WITH PASSWORD = 'admin';

--Creando un nuevo usuario para administrar la base de datos.
USE WisentoryDB;

CREATE USER WisentoryManager FOR LOGIN WisentoryManager;
GRANT CONNECT SQL TO WFDB;

--Asignamos los permisos al usuario.
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::dbo TO WisentoryManager;
GRANT EXECUTE ON SCHEMA::dbo TO WisentoryManager;

--Creamos la tabla "Users" para administrar el login.
Drop table Users;
CREATE TABLE Users (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    [Name] VARCHAR(20) NOT NULL UNIQUE CHECK (LEN([Name]) >= 4),
    [Password] VARCHAR(20) NOT NULL UNIQUE CHECK (LEN([Password]) >= 4)
);

--Asignamos los usuarios.
INSERT INTO Users ([Name], [Password])
VALUES 
	('Blue', 'Blue123'), 
	('Admin', 'Admin');

-- Creación de la tabla "Clients"
Drop table Clients;
CREATE TABLE Clients (
    Id INT IDENTITY(1, 1) PRIMARY KEY,
    [Name] VARCHAR(30) NOT NULL CHECK (LEN([Name]) >= 3),
	[LastName] VARCHAR(30) NOT NULL CHECK (LEN([LastName]) >= 3),
    Email VARCHAR(30) NOT NULL DEFAULT 'N/A',
	PhoneNumber VARCHAR(10) NOT NULL DEFAULT 'N/A'
);
delete from clients;
-- Asignamos los valores.
INSERT INTO Clients ([Name], [LastName])
VALUES ('Consumidor', 'Final');

INSERT INTO Clients ([Name], [LastName], Email, PhoneNumber)
VALUES ('John', 'Doe', 'john.doe@example.com', '1234567890'),
    ('Alice', 'Smith', 'N/A', 'N/A'),
    ('Bob', 'Johnson', 'N/A', 'N/A'),
    ('Sam', 'Lil', 'N/A', 'N/A'),
    ('Sarah', 'Brown', 'a-email-address@example.com', '1234567890');


-- Creación de la tabla "Suppliers"
Drop table Suppliers;
CREATE TABLE Suppliers (
    Id INT IDENTITY(1, 1) PRIMARY KEY,
    [Name] VARCHAR(30) NOT NULL CHECK (LEN([Name]) >= 3),
    Email VARCHAR(30) NOT NULL CHECK (LEN(Email) >= 4), 
	PhoneNumber VARCHAR(10) NOT NULL DEFAULT 'N/A',
	[Address] VARCHAR(30) NOT NULL
);

-- Asignamos los valores.
INSERT INTO Suppliers ([Name], Email, PhoneNumber, [Address])
VALUES ('Proveedor1', 'proveedor1@example.com', '1234567890', 'Calle Principal 123');

-- Creación de la tabla "Products"
Drop table Products;
CREATE TABLE Products (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    [Name] VARCHAR(40) NOT NULL CHECK (LEN([Name]) >= 3),
    [Description] VARCHAR(100),
	VAT VARCHAR(1) NOT NULL CHECK ([VAT] IN ('Y', 'N')) DEFAULT 'Y',
	BuyPrice DECIMAL(10, 2) NOT NULL,
    SellPrice DECIMAL(10, 2) NOT NULL,
    Stock INT NOT NULL,
	SupplierId INT,
    FOREIGN KEY (SupplierId) REFERENCES Suppliers(Id)
);

-- Asignamos los valores.
INSERT INTO Products ([Name], [Description], BuyPrice, SellPrice, Stock, SupplierId)
VALUES
    ('Laptop HP', 'Laptop HP modelo XYZ', 1300.00,1500.00, 10,1),
    ('Teléfono Samsung', 'Teléfono Samsung modelo ABC',700.00, 800.00, 20,1),
    ('Monitor LG', 'Monitor LG de 24 pulgadas',240.00, 250.00, 15,1),
    ('Impresora Epson', 'Impresora Epson modelo XYZ', 125.00,150.00, 5,1),
    ('Teclado Logitech', 'Teclado Logitech con retroiluminación',60.00, 80.00, 12,1);

-- Creación de la tabla "Orders"
Drop table Orders;
CREATE TABLE Orders (
    Id INT IDENTITY(1, 1) PRIMARY KEY,
    [Date] DATE NOT NULL,
    [Status] VARCHAR(10) NOT NULL CHECK ([Status] IN ('Pendiente', 'Entregado', 'Cancelado')),
    SupplierId INT NOT NULL,
	Total DECIMAL(10, 2)
    FOREIGN KEY (SupplierId) REFERENCES Suppliers(Id)
);

-- Asignamos los valores.
INSERT INTO Orders ([Date], [Status], SupplierId)
VALUES ('2023-07-15', 'Pendiente', 1);


-- Creación de la tabla "OrderDetail"
Drop table OrderDetail;
CREATE TABLE OrderDetail (
    Id INT IDENTITY(1, 1) PRIMARY KEY,
    OrderId INT NOT NULL,
    ProductId INT NOT NULL,
    Amount INT NOT NULL CHECK (LEN([Amount]) >= 1),
    UnitPrice DECIMAL(10, 2),
	Subtotal DECIMAL(10, 2),
    FOREIGN KEY (OrderId) REFERENCES Orders(Id),
    FOREIGN KEY (ProductId) REFERENCES Products(Id)
);

--Creación de un trigger que calcule el subtotal en la tabla OrderDetail.
DROP TRIGGER UpdateOrderSubtotal;

CREATE TRIGGER UpdateOrderSubtotal
ON OrderDetail
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE OD
	SET OD.UnitPrice = P.BuyPrice,
        OD.Subtotal = P.BuyPrice * OD.Amount
    FROM OrderDetail AS OD
    INNER JOIN Products AS P ON OD.ProductId = P.Id
    INNER JOIN inserted AS I ON OD.Id = I.Id;
END;


--Creación de un trigger que calcule el total en la tabla Bills.
DROP TRIGGER UpdateOrderTotal;

CREATE TRIGGER UpdateOrderTotal
ON OrderDetail
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @OrderId INT;

    -- Obtener el ID de la factura afectada
    SELECT @OrderId = OrderId FROM inserted;

    -- Actualizar el campo "Total" en la tabla "Bill" con la suma de los "Subtotales"
    UPDATE Orders
    SET Total = (
        SELECT SUM(Subtotal)
        FROM OrderDetail
        WHERE OrderId = @OrderId
    )
    WHERE Id = @OrderId;
END;

delete from OrderDetail;
-- Asignamos los valores.
INSERT INTO OrderDetail (OrderId, ProductId, Amount)
VALUES (1, 1, 5),
	(1,3,3),
	(1,4,1);

-- Tabla Bills
Drop table Bills;
CREATE TABLE Bills (
    Id INT IDENTITY(1,1) PRIMARY KEY,
	ClientId INT NOT NULL DEFAULT 1,
    [Date] DATETIME NOT NULL,
    Total DECIMAL(10, 2)
	FOREIGN KEY (ClientId) REFERENCES Clients(Id)
);

-- Asignamos los valores.
INSERT INTO Bills (ClientId, [Date])
VALUES (1, GETDATE());

INSERT INTO Bills (ClientId, [Date])
VALUES (2, GETDATE()),
(1002, GETDATE()),
(1003, GETDATE()),
(1004, GETDATE());



-- Tabla BillDetail
Drop table BillDetail;
CREATE TABLE BillDetail (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    BillId INT NOT NULL,
    ProductId INT NOT NULL,
    Amount INT NOT NULL CHECK (LEN([Amount]) >= 1),
    UnitPrice DECIMAL(10, 2),
	Subtotal DECIMAL(10, 2),
    FOREIGN KEY (BillId) REFERENCES Bills(Id),
    FOREIGN KEY (ProductId) REFERENCES Products(Id)
);


--Creación de un trigger que calcule el subtotal en la tabla BillDetail.
DROP TRIGGER UpdateBillSubtotal;

CREATE TRIGGER UpdateBillSubtotal
ON BillDetail
AFTER INSERT, UPDATE
AS
BEGIN
    UPDATE BD
	SET BD.UnitPrice = P.SellPrice,
        BD.Subtotal = CASE WHEN P.VAT = 'Y' THEN (P.SellPrice * BD.Amount) * 1.12 ELSE (P.SellPrice * BD.Amount) END
    FROM BillDetail AS BD
    INNER JOIN Products AS P ON BD.ProductId = P.Id
    INNER JOIN inserted AS I ON BD.Id = I.Id;
END;


--Creación de un trigger que calcule el total en la tabla Bills.
DROP TRIGGER UpdateBillTotal;

CREATE TRIGGER UpdateBillTotal
ON BillDetail
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    DECLARE @BillId INT;

    -- Obtener el ID de la factura afectada (utilizando la tabla "inserted" para INSERT y UPDATE, y la tabla "deleted" para DELETE)
    IF EXISTS (SELECT 1 FROM inserted)
        SELECT @BillId = BillId FROM inserted;
    ELSE IF EXISTS (SELECT 1 FROM deleted)
        SELECT @BillId = BillId FROM deleted;

    -- Actualizar el campo "Total" en la tabla "Bill" con la suma de los "Subtotales"
    UPDATE Bills
    SET Total = (
        SELECT SUM(Subtotal)
        FROM BillDetail
        WHERE BillId = @BillId
    )
    WHERE Id = @BillId;
END;


-- Asignamos los valores.
delete from BillDetail;
INSERT INTO BillDetail (BillId, ProductId, Amount)
VALUES (1, 1, 3),
       (1, 2, 5),
       (1, 3, 2);


INSERT INTO BillDetail (BillId, ProductId, Amount)
VALUES (4, 1, 3);

INSERT INTO BillDetail (BillId, ProductId, Amount)
VALUES (5, 1, 3);

INSERT INTO BillDetail (BillId, ProductId, Amount)
VALUES (6, 5, 3);

select * from bills

select * from BillDetail

INSERT INTO BillDetail (BillId, ProductId, Amount)
VALUES (4, 1, 2);

EXEC DeleteBillDetail @BillId = 4, @ProductId = 1;











