use WisentoryDB;

CREATE PROCEDURE CreateClient
    @Name VARCHAR(30),
    @LastName VARCHAR(30),
    @Email VARCHAR(30) = 'N/A',
    @PhoneNumber VARCHAR(10) = 'N/A'
AS
BEGIN
    INSERT INTO Clients ([Name], [LastName], Email, PhoneNumber)
    VALUES (@Name, @LastName, @Email, @PhoneNumber)
END;


EXEC CreateClient 'Nora', 'Novikov', 'NNovikov@supplies_ru.com', '1234567890';

DROP VIEW seeClients5;

CREATE VIEW seeClients5 AS
SELECT TOP 5 C.Id AS NumeroCliente,CONCAT(C.[Name], ' ', C.[LastName]) AS NombreCompleto, SUM(B.Total) AS TotalFacturas
FROM Clients C
LEFT JOIN Bills B ON C.Id = B.ClientId
GROUP BY CONCAT(C.[Name], ' ', C.[LastName]), C.Id
ORDER BY TotalFacturas DESC;

CREATE VIEW seeClients AS
SELECT C.Id AS NumeroCliente,CONCAT(C.[Name], ' ', C.[LastName]) AS NombreCompleto, SUM(B.Total) AS TotalFacturas
FROM Clients C
LEFT JOIN Bills B ON C.Id = B.ClientId
GROUP BY CONCAT(C.[Name], ' ', C.[LastName]), C.Id
ORDER BY TotalFacturas DESC;

DROP PROCEDURE GetPagedClients;

CREATE PROCEDURE GetPagedClients
    @PageNumber INT = 1, -- Número de página solicitada (página inicial = 1)
    @PageSize INT = 10  -- Cantidad de registros por página
AS
BEGIN
    SELECT NombreCompleto, TotalFacturas
    FROM (
        SELECT CONCAT(C.[Name], ' ', C.[LastName]) AS NombreCompleto, SUM(B.Total) AS TotalFacturas,
               ROW_NUMBER() OVER (ORDER BY SUM(B.Total) DESC) AS RowNum
        FROM Clients C
        LEFT JOIN Bills B ON C.Id = B.ClientId
        GROUP BY C.Id, CONCAT(C.[Name], ' ', C.[LastName])
    ) AS TempTable
    WHERE RowNum > ((@PageNumber - 1) * @PageSize)
      AND RowNum <= (@PageNumber * @PageSize);
END;

EXEC GetPagedClients @PageNumber = 1, @PageSize = 5;

DROP PROCEDURE GetPagedProducts;

CREATE PROCEDURE GetPagedProducts
    @PageNumber INT = 1, -- Número de página solicitada (página inicial = 1)
    @PageSize INT = 10  -- Cantidad de registros por página
AS
BEGIN
    SELECT NombreProducto, CantidadVendida, TotalFacturas
    FROM (
        SELECT P.[Name] AS NombreProducto,
               SUM(BD.Amount) AS CantidadVendida,
               SUM(BD.Subtotal) AS TotalFacturas,
               ROW_NUMBER() OVER (ORDER BY SUM(BD.Subtotal) DESC) AS RowNum
        FROM Clients C
        LEFT JOIN Bills B ON C.Id = B.ClientId
        LEFT JOIN BillDetail BD ON B.Id = BD.BillId
        LEFT JOIN Products P ON BD.ProductId = P.Id
        GROUP BY P.Id, P.[Name]
    ) AS TempTable
    WHERE RowNum > ((@PageNumber - 1) * @PageSize)
      AND RowNum <= (@PageNumber * @PageSize);
END;


EXEC GetPagedProducts @PageNumber = 1, @PageSize = 5;

DROP PROCEDURE GetPagedBills;

CREATE PROCEDURE GetPagedBills
    @PageNumber INT = 1, -- Número de página solicitada (página inicial = 1)
    @PageSize INT = 10  -- Cantidad de registros por página
AS
BEGIN
    SELECT CONVERT(DATE, Fecha) AS Fecha, SUM(TotalFacturas) AS TotalVentas
    FROM (
        SELECT B.[Date] AS Fecha,
               B.Total AS TotalFacturas,
               ROW_NUMBER() OVER (ORDER BY B.Total DESC) AS RowNum
        FROM Bills B
    ) AS TempTable
    WHERE RowNum > ((@PageNumber - 1) * @PageSize)
      AND RowNum <= (@PageNumber * @PageSize)
    GROUP BY CONVERT(DATE, Fecha)
    ORDER BY TotalVentas DESC;
END;


DROP PROCEDURE GetPagedSuppliersOrders;

CREATE PROCEDURE GetPagedSuppliersOrders
    @PageNumber INT = 1, -- Número de página solicitada (página inicial = 1)
    @PageSize INT = 10  -- Cantidad de registros por página
AS
BEGIN
    SELECT [Name] AS NombreProveedor, Total AS ValorTotal
    FROM (
        SELECT S.[Name],
               SUM(O.Total) AS Total,
               ROW_NUMBER() OVER (ORDER BY SUM(O.Total) DESC) AS RowNum
        FROM Suppliers S
        LEFT JOIN Orders O ON S.Id = O.SupplierId
        GROUP BY S.[Name]
    ) AS TempTable
    WHERE RowNum > ((@PageNumber - 1) * @PageSize)
      AND RowNum <= (@PageNumber * @PageSize)
    ORDER BY ValorTotal DESC;
END;

DROP PROCEDURE GetPagedOrders;

CREATE PROCEDURE GetPagedOrders
    @PageNumber INT = 1, -- Número de página solicitada (página inicial = 1)
    @PageSize INT = 10  -- Cantidad de registros por página
AS
BEGIN
    SELECT [Date] AS Fecha,
           [Status] AS Estado,
           Total AS TotalPedido
    FROM (
        SELECT O.[Date],
               O.[Status],
               O.Total,
               ROW_NUMBER() OVER (ORDER BY O.[Date] DESC) AS RowNum
        FROM Orders O
    ) AS TempTable
    WHERE RowNum > ((@PageNumber - 1) * @PageSize)
      AND RowNum <= (@PageNumber * @PageSize)
    ORDER BY [Date] DESC;
END;


DROP PROCEDURE SearchClients;

CREATE PROCEDURE SearchClients
    @Id NVARCHAR(10) = NULL,
	@Name NVARCHAR(100) = NULL,
    @Lastname NVARCHAR(100) = NULL,
    @Number NVARCHAR(20) = NULL,
    @Email NVARCHAR(100) = NULL
AS
BEGIN
    SELECT 
        Id AS [Id],
        [Name] AS [Nombre],
        [LastName] AS [Apellido],
        PhoneNumber AS [Número],
        Email AS [Email]
    FROM Clients
    WHERE (@Id IS NULL OR CONVERT(VARCHAR(10),[Id]) LIKE @Id + '%')
	  AND (@Name IS NULL OR [Name] LIKE @Name + '%')
      AND (@Lastname IS NULL OR [LastName] LIKE @Lastname + '%')
      AND (@Number IS NULL OR PhoneNumber LIKE @Number + '%')
      AND (@Email IS NULL OR Email LIKE @Email + '%');
END


EXEC SearchClients @Id = '1';

DROP PROCEDURE InsertClient;
CREATE PROCEDURE InsertClient
    @Name VARCHAR(30),
    @LastName VARCHAR(30),
    @Email VARCHAR(30) = 'N/A',
    @PhoneNumber VARCHAR(10) = 'N/A'
AS
BEGIN
    -- Verificar que los campos obligatorios (@Name y @LastName) no sean nulos o vacíos y tengan al menos 3 caracteres
    IF (@Name IS NULL OR @LastName IS NULL OR @Name = '' OR @LastName = '' OR LEN(@Name) < 3 OR LEN(@LastName) < 3)
    BEGIN
        RAISERROR('El nombre y el apellido son obligatorios y deben tener al menos 3 caracteres de longitud.', 16, 1);
        RETURN;
    END

    -- Verificar que los campos opcionales no excedan su longitud permitida
    IF (LEN(@Email) > 30 OR LEN(@PhoneNumber) > 10)
    BEGIN
        RAISERROR('El email o el número de teléfono excede la longitud permitida.', 16, 1);
        RETURN;
    END

    -- Insertar el cliente en la tabla
    INSERT INTO Clients ([Name], [LastName], Email, PhoneNumber)
    VALUES (@Name, @LastName, @Email, @PhoneNumber);
END

EXEC InsertClient @Name = 'Prueba',@LastName = 'Cinco';
select * from clients;

DROP PROCEDURE UpdateClient;
CREATE PROCEDURE UpdateClient
    @Id INT,
    @Name NVARCHAR(30),
    @LastName NVARCHAR(30),
    @PhoneNumber NVARCHAR(10) = NULL,
    @Email NVARCHAR(30) = NULL
AS
BEGIN
    BEGIN TRY
        UPDATE Clients
        SET
            [Name] = @Name,
            [LastName] = @LastName,
            PhoneNumber = ISNULL(@PhoneNumber, 'N/A'),
            Email = ISNULL(@Email, 'N/A')
        WHERE
            Id = @Id;
    END TRY
    BEGIN CATCH
        PRINT 'Existe un error inesperado. Posiblemente el id no sea correcto.';
    END CATCH
END;




DROP PROCEDURE DeleteClient;

CREATE PROCEDURE DeleteClient
    @id INT
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON;
		BEGIN
			DELETE FROM Clients
			WHERE Id = @id;
		END
	END TRY
	BEGIN CATCH
		PRINT 'Existe un error inesperado. Posiblemente el id no sea correcto.';
    END CATCH
END


DROP PROCEDURE SearchBills;

CREATE PROCEDURE SearchBills
    @Id NVARCHAR(10) = NULL,
    @Date NVARCHAR(10) = NULL,
    @ClientId NVARCHAR(10) = NULL,
    @Total DECIMAL(10, 2) = NULL,
    @Condition CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT B.Id, B.ClientId AS IdCliente, C.Name + ' '+C.LastName AS NombreCliente, CONVERT(NVARCHAR, B.[Date], 103) AS Fecha, B.Total
    FROM Bills B
    LEFT JOIN Clients C ON B.ClientId = C.Id
    WHERE
        (@Date IS NULL OR CONVERT(NVARCHAR, B.[Date], 103) = @Date)
        AND (@ClientId IS NULL OR CONVERT(NVARCHAR(10), B.ClientId) LIKE @ClientId + '%')
        AND (
            (@Condition = 'U' AND B.Total >= @Total) OR
            (@Condition = 'D' AND B.Total <= @Total) OR
            (@Condition = 'E' AND B.Total = @Total) OR
            (@Condition IS NULL AND @Total IS NULL)
        )
        AND (@Id IS NULL OR CONVERT(NVARCHAR(10), B.Id) LIKE @Id + '%')
    ORDER BY B.[Date] DESC;
END;





EXEC SearchBills @ClientId = '';

EXEC SearchBills @Total = '8848', @Condition = 'S';

DROP PROCEDURE InsertBill;

CREATE PROCEDURE InsertBill
    @Fecha DATETIME,
    @IdCliente INT
AS
BEGIN
	SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si el idcliente existe en la tabla "Clients"
        IF NOT EXISTS (SELECT 1 FROM Clients WHERE Id = @IdCliente)
        BEGIN
            RAISERROR('Usted ha ingresado un IdCliente que no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin insertar la factura
        END

        -- Insertar la nueva factura en la tabla "Bills"
        INSERT INTO Bills ([Date], ClientId)
        VALUES (@Fecha, @IdCliente);
    END TRY
    BEGIN CATCH
        -- Capturar la excepción y mostrar el mensaje de error personalizado
        PRINT 'Existe un error inesperado. Posiblemente el id no sea correcto.';
    END CATCH
END;


EXEC InsertBill @Fecha = '2023-07-14', @IdCliente = 1;

DROP PROCEDURE UpdateBill;

CREATE PROCEDURE UpdateBill
    @Id INT,
    @ClientId INT,
    @Date DATE
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE Bills
        SET ClientId = @ClientId,
            [Date] = @Date
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        PRINT 'Existe un error inesperado. Posiblemente el id no sea correcto.';
    END CATCH
END;

CREATE PROCEDURE DeleteBill
    @id INT
AS
BEGIN
	BEGIN TRY
		SET NOCOUNT ON;
		BEGIN
			DELETE FROM Bills
			WHERE Id = @id;
		END
	END TRY
	BEGIN CATCH
		PRINT 'Existe un error inesperado. Posiblemente el id no sea correcto.';
    END CATCH
END

EXEC UpdateBill @Id = 1, @ClientId = 1, @Date = '2023-07-01';


DROP PROCEDURE SearchBillDetail;

CREATE PROCEDURE SearchBillDetail
    @BillId INT,
    @ProductId NVARCHAR(10) = NULL,
    @ProductName NVARCHAR(40) = NULL,
    @VAT CHAR(1) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        P.Id AS IdProducto,
        P.[Name] AS NombreProducto,
        SUM(BD.Amount) AS Cantidad,
        P.SellPrice AS PrecioUnitario,
        CASE P.VAT
            WHEN 'Y' THEN 'Sí'
            WHEN 'N' THEN 'No'
        END AS TieneIVA,
        SUM(BD.Subtotal) AS Subtotal

        /*CASE
            WHEN SUM(BD.Subtotal) IS NOT NULL AND P.VAT = 'Y' THEN SUM(BD.Subtotal) * 1.16
            ELSE SUM(BD.Subtotal)
        END AS TotalConIVA*/
    FROM
        BillDetail BD
    INNER JOIN
        Products P ON BD.ProductId = P.Id
    WHERE
        BD.BillId = @BillId
        AND (@ProductId IS NULL OR CONVERT(NVARCHAR(10), P.Id) LIKE @ProductId + '%')
        AND (@ProductName IS NULL OR P.[Name] LIKE '%' + @ProductName + '%')
        AND (@VAT IS NULL OR P.VAT = @VAT)
    GROUP BY
        BD.BillId,
        P.Id,
        P.[Name],
        P.SellPrice,
        P.VAT;
END;


EXEC SearchBillDetail @BillId = 5, @ProductName = '',@ProductId='2';

CREATE PROCEDURE InsertBillDetail
    @BillId INT,
    @ProductId INT,
    @Amount INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si el BillId existe en la tabla "Bills"
        IF NOT EXISTS (SELECT 1 FROM Bills WHERE Id = @BillId)
        BEGIN
            RAISERROR('El BillId ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin insertar el detalle de la factura
        END

        -- Verificar si el ProductId existe en la tabla "Products"
        IF NOT EXISTS (SELECT 1 FROM Products WHERE Id = @ProductId)
        BEGIN
            RAISERROR('El ProductId ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin insertar el detalle de la factura
        END
        -- Insertar el detalle de la factura en la tabla "BillDetail"
        INSERT INTO BillDetail (BillId, ProductId, Amount)
        VALUES (@BillId, @ProductId, @Amount);

    END TRY
    BEGIN CATCH
        -- Capturar la excepción y mostrar el mensaje de error personalizado
        PRINT 'Existe un error inesperado. Posiblemente el BillId o el ProductId no sean válidos.';
    END CATCH
END;

EXEC InsertBillDetail @BillId = 1, @ProductId = 3, @Amount = 2;

DROP PROCEDURE UpdateBillDetail;

CREATE PROCEDURE UpdateBillDetail
    @BillId INT,
    @ProductId INT,
    @Amount INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si el BillId existe en la tabla "Bills"
        IF NOT EXISTS (SELECT 1 FROM Bills WHERE Id = @BillId)
        BEGIN
            RAISERROR('El BillId ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin actualizar el detalle de la factura
        END

        -- Verificar si el ProductId existe en la tabla "Products"
        IF NOT EXISTS (SELECT 1 FROM Products WHERE Id = @ProductId)
        BEGIN
            RAISERROR('El ProductId ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin actualizar el detalle de la factura
        END

        -- Actualizar el detalle de la factura en la tabla "BillDetail"
        UPDATE BillDetail
        SET Amount = @Amount
        WHERE BillId = @BillId AND ProductId = @ProductId;

    END TRY
    BEGIN CATCH
        -- Capturar la excepción y mostrar el mensaje de error personalizado
        PRINT 'Existe un error inesperado.';
    END CATCH
END;

EXEC UpdateBillDetail @BillId = 10, @ProductId = 1, @Amount = 5;

DROP PROCEDURE DeleteBillDetail;

CREATE PROCEDURE DeleteBillDetail
	@BillId INT,
    @ProductId INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY    

    -- Verificar si el IdProducto existe en la tabla "Products"
    IF NOT EXISTS (SELECT 1 FROM Products WHERE Id = @ProductId)
    BEGIN
        RAISERROR('El IdProducto ingresado no es válido.', 16, 1);
        RETURN; -- Salir del procedimiento sin borrar los registros
    END

    -- Borrar los registros de BillDetail que corresponden al IdProducto
    DELETE FROM BillDetail WHERE Billid = @BillId AND ProductId = @ProductId;
	END TRY
	BEGIN CATCH
        -- Capturar la excepción y mostrar el mensaje de error personalizado
        PRINT 'Existe un error inesperado.';
    END CATCH
END;

SELECT * FROM BillDetail WHERE Billid = 4;

EXEC DeleteBillDetail @BillId = 4, @ProductId = 4;

