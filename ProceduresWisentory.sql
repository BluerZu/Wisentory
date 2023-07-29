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
        RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
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
		RAISERROR('No se puede borrar este cliente, porque está asociado a una factura, elimine todas las facturas con este cliente para borrarlo.', 16, 1);
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
        RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
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
        RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
    END CATCH
END;

DROP PROCEDURE DeleteBill;
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
		RAISERROR('Para borrar una factura, no debe tener ningún detalle.', 16, 1);
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

DROP PROCEDURE InsertBillDetail;
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
        RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
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
		RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
    END CATCH
END;

EXEC UpdateBillDetail @BillId = 6, @ProductId = 1, @Amount = 1;
select * from BillDetail
where BillId =10;

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
        RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
    END CATCH
END;

SELECT * FROM BillDetail WHERE Billid = 4;

EXEC DeleteBillDetail @BillId = 4, @ProductId = 4;

DROP PROCEDURE SearchSuppliers;
CREATE PROCEDURE SearchSuppliers
    @Id VARCHAR(10) = NULL,
    @Name VARCHAR(30) = NULL,
    @Email VARCHAR(30) = NULL,
    @PhoneNumber VARCHAR(10) = NULL,
    @Address VARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT Id, [Name] as Nombre, Email, PhoneNumber as Número, [Address] as Dirección
    FROM Suppliers
    WHERE
        (@Id IS NULL OR CONVERT(VARCHAR(10),Id) LIKE @Id + '%')
        AND (@Name IS NULL OR [Name] LIKE @Name + '%')
        AND (@Email IS NULL OR Email LIKE @Email+ '%')
        AND (@PhoneNumber IS NULL OR PhoneNumber LIKE @PhoneNumber+ '%')
        AND (@Address IS NULL OR [Address] LIKE @Address+ '%');
END;

EXEC SearchSuppliers @Id = '';

DROP PROCEDURE InsertSupplier;
CREATE PROCEDURE InsertSupplier
    @Name VARCHAR(30),
    @Email VARCHAR(30),
    @PhoneNumber VARCHAR(10),
    @Address VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Insertar el nuevo proveedor en la tabla "Suppliers"
        INSERT INTO Suppliers ([Name], Email, PhoneNumber, [Address])
        VALUES (@Name, @Email, @PhoneNumber, @Address);

        PRINT 'Proveedor insertado correctamente.';
    END TRY
    BEGIN CATCH
		RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
    END CATCH
END;

-- Ejemplo de uso del procedimiento para insertar un nuevo proveedor
EXEC InsertSupplier @Name = 'Proveedor A', @Email = 'proveedorA@example.com', @PhoneNumber = '1234567890', @Address = 'Calle 123';

DROP PROCEDURE UpdateSupplier;
CREATE PROCEDURE UpdateSupplier
    @Id INT,
    @Name VARCHAR(30),
    @Email VARCHAR(30),
    @PhoneNumber VARCHAR(10),
    @Address VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si el proveedor con el Id existe en la tabla "Suppliers"
        IF NOT EXISTS (SELECT 1 FROM Suppliers WHERE Id = @Id)
        BEGIN
            RAISERROR('El Id del proveedor ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin actualizar el proveedor
        END

        -- Actualizar los datos del proveedor en la tabla "Suppliers"
        UPDATE Suppliers
        SET [Name] = @Name,
            Email = @Email,
            PhoneNumber = @PhoneNumber,
            [Address] = @Address
        WHERE Id = @Id;

        PRINT 'Proveedor actualizado correctamente.';
    END TRY
    BEGIN CATCH
		RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
    END CATCH
END;

EXEC UpdateSupplier @Id = 4, @Name = 'Proveedor B Modificado', @Email = 'proveedorA@example.com', @PhoneNumber = '1234567892', @Address = 'Calle B Modificada';

DROP PROCEDURE DeleteSupplier;

CREATE PROCEDURE DeleteSupplier
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si el proveedor con el Id existe en la tabla "Suppliers"
        IF NOT EXISTS (SELECT 1 FROM Suppliers WHERE Id = @Id)
        BEGIN
            RAISERROR('El Id del proveedor ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin borrar el proveedor
        END

        -- Borrar el proveedor de la tabla "Suppliers"
        DELETE FROM Suppliers WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        -- Capturar la excepción y mostrar el mensaje de error personalizado
        RAISERROR('El proveedor está constando en algún producto, primero hay que borrar todos los productos con este proveedor, para borrarlo.', 16, 1);
    END CATCH
END;

-- Ejemplo de uso del procedimiento para eliminar un proveedor con Id 1
EXEC DeleteSupplier @Id = 1;

CREATE PROCEDURE DeleteProductsBySupplierId
    @SupplierId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        -- Iniciar la transacción
        BEGIN TRANSACTION;

        -- Verificar si el proveedor existe en la tabla "Suppliers"
        IF NOT EXISTS (SELECT 1 FROM Suppliers WHERE Id = @SupplierId)
        BEGIN
            RAISERROR('El SupplierId ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin borrar los productos
        END

        -- Eliminar los productos asociados al proveedor
        DELETE FROM Products WHERE SupplierId = @SupplierId;

        -- Confirmar la transacción si no hubo errores
        COMMIT TRANSACTION;

        PRINT 'Productos eliminados correctamente.';
    END TRY
    BEGIN CATCH
        -- Si ocurre un error, deshacer la transacción para que no se realicen los cambios en la base de datos
        ROLLBACK TRANSACTION;

        -- Capturar la excepción y mostrar el mensaje de error personalizado
        RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
    END CATCH
END;

(@Date IS NULL OR CONVERT(NVARCHAR, B.[Date], 103) = @Date)
        AND (@SupplierId IS NULL OR CONVERT(NVARCHAR(10), SupplierId) LIKE @SupplierId + '%')

DROP PROCEDURE SearchOrders;

CREATE PROCEDURE SearchOrders
    @OrderId NVARCHAR(10) = NULL,
    @SupplierId NVARCHAR(10) = NULL,
    @Date NVARCHAR(10) = NULL,
    @Status NVARCHAR(10) = NULL -- Nuevo parámetro para buscar por Estado
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        O.Id AS Id,
        O.SupplierId AS IdProveedor,
        S.Name AS NombreProveedor,
        CONVERT(NVARCHAR,O.[Date],103) AS Fecha,
        O.[Status] AS Estado,
        O.Total
    FROM Orders O
    INNER JOIN Suppliers S ON O.SupplierId = S.Id
    WHERE
        (@OrderId IS NULL OR CONVERT(NVARCHAR,O.Id) LIKE @OrderId + '%')
        AND (@SupplierId IS NULL OR CONVERT(NVARCHAR,O.SupplierId) LIKE @SupplierId + '%')
        AND (@Date IS NULL OR CONVERT(NVARCHAR,O.[Date], 103) = @Date)
        AND (@Status IS NULL OR O.[Status] = @Status); -- Nueva condición de búsqueda por Estado
END;

DROP PROCEDURE InsertOrder;
CREATE PROCEDURE InsertOrder
    @Date DATE,
    @Status VARCHAR(10),
    @SupplierId INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si el SupplierId existe en la tabla "Suppliers"
        IF NOT EXISTS (SELECT 1 FROM Suppliers WHERE Id = @SupplierId)
        BEGIN
            RAISERROR('El SupplierId ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin insertar la orden
        END

        -- Verificar que el Status sea válido ('Pendiente', 'Entregado', 'Cancelado')
        IF NOT (@Status IN ('Pendiente', 'Entregado', 'Cancelado'))
        BEGIN
            RAISERROR('El Status ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin insertar la orden
        END

        -- Insertar la orden en la tabla "Orders"
        INSERT INTO Orders ([Date], [Status], SupplierId)
        VALUES (@Date, @Status, @SupplierId);
    END TRY
    BEGIN CATCH
        -- Capturar la excepción y mostrar el mensaje de error personalizado
        RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
    END CATCH
END;

-- Ejemplo de uso del procedimiento para insertar una nueva orden
EXEC InsertOrder @Date = '2023-07-23', @Status = 'Pendiente', @SupplierId = 4;

DROP PROCEDURE UpdateOrder;

CREATE PROCEDURE UpdateOrder
    @OrderId INT,
    @Date DATE,
    @Status VARCHAR(10),
    @SupplierId INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si el SupplierId existe en la tabla "Suppliers"
        IF NOT EXISTS (SELECT 1 FROM Suppliers WHERE Id = @SupplierId)
        BEGIN
            RAISERROR('El SupplierId ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin modificar la orden
        END

        -- Verificar que el Status sea válido ('Pendiente', 'Entregado', 'Cancelado')
        IF NOT (@Status IN ('Pendiente', 'Entregado', 'Cancelado'))
        BEGIN
            RAISERROR('El Status ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin modificar la orden
        END

        -- Verificar si la orden con el OrderId existe en la tabla "Orders"
        IF NOT EXISTS (SELECT 1 FROM Orders WHERE Id = @OrderId)
        BEGIN
            RAISERROR('El OrderId ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin modificar la orden
        END

        -- Actualizar la orden en la tabla "Orders"
        UPDATE Orders
        SET [Date] = @Date,
            [Status] = @Status,
            SupplierId = @SupplierId
        WHERE Id = @OrderId;

    END TRY
    BEGIN CATCH
        RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
    END CATCH
END;

-- Ejemplo de uso del procedimiento para modificar una orden con OrderId 1
EXEC UpdateOrder @OrderId = 3, @Date = '2023-07-24', @Status = 'Entregado', @SupplierId = 3;

DROP PROCEDURE DeleteOrder;

CREATE PROCEDURE DeleteOrder
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si la orden con el OrderId existe en la tabla "Orders"
        IF NOT EXISTS (SELECT 1 FROM Orders WHERE Id = @Id)
        BEGIN
            RAISERROR('El OrderId ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin borrar la orden
        END

        -- Eliminar la orden de la tabla "Orders"
        DELETE FROM Orders WHERE Id =  @Id;
    END TRY
    BEGIN CATCH
        -- Capturar la excepción y mostrar el mensaje de error personalizado
        RAISERROR('Para borrar una orden, su detalle debe estar vacío.', 16, 1);
    END CATCH
END;

DROP PROCEDURE SearchProducts;

CREATE PROCEDURE SearchProducts
    @Id VARCHAR(10) = NULL,
    @Name VARCHAR(30) = NULL,
    @Description VARCHAR(100) = NULL,
    @VAT VARCHAR(1) = NULL,
    @BuyPrice DECIMAL(10, 2) = NULL,
    @SellPrice DECIMAL(10, 2) = NULL,
    @Stock INT = NULL, -- Nuevo parámetro para buscar por Stock
    @SupplierId INT = NULL -- Nuevo parámetro para buscar por SupplierId
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        Id AS Id,
        [Name] AS Nombre,
        [Description] AS Descripción,
        CASE VAT
            WHEN 'Y' THEN 'Sí'
            WHEN 'N' THEN 'No'
        END AS Impuesto,
        BuyPrice AS PrecioCompra,
        SellPrice AS PrecioVenta,
        Stock,
        SupplierId AS IdProveedor
    FROM Products
    WHERE
        (@Id IS NULL OR CONVERT(NVARCHAR,Id) LIKE @Id + '%')
        AND (@Name IS NULL OR [Name] LIKE @Name + '%')
        AND (@Description IS NULL OR [Description] LIKE @Description + '%')
        AND (@VAT IS NULL OR VAT LIKE @VAT + '%')
        AND (@BuyPrice IS NULL OR BuyPrice = @BuyPrice)
        AND (@SellPrice IS NULL OR SellPrice = @SellPrice)
        AND (@Stock IS NULL OR Stock = @Stock) -- Condición para buscar por Stock
        AND (@SupplierId IS NULL OR SupplierId = @SupplierId); -- Condición para buscar por SupplierId
END;


EXEC SearchProducts @SupplierId = 1;

DROP PROCEDURE InsertProduct;

CREATE PROCEDURE InsertProduct
    @Name VARCHAR(40),
    @Description VARCHAR(100),
    @VAT VARCHAR(1),
    @BuyPrice DECIMAL(10, 2),
    @SellPrice DECIMAL(10, 2),
    @Stock INT,
    @SupplierId INT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        INSERT INTO Products ([Name], [Description], VAT, BuyPrice, SellPrice, Stock, SupplierId)
        VALUES (@Name, @Description, @VAT, @BuyPrice, @SellPrice, @Stock, @SupplierId);
    END TRY
    BEGIN CATCH
        RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
    END CATCH;
END;

EXEC InsertProduct
    @Name = 'Producto de ejemplo 1',
    @Description = 'Este es un producto de ejemplo para demostración 1',
    @VAT = 'N',
    @BuyPrice = 150.00,
    @SellPrice = 180.00,
    @Stock = 10,
    @SupplierId = 3;


USE WisentoryDB;
DROP PROCEDURE UpdateProduct;
CREATE PROCEDURE UpdateProduct
    @Id INT,
    @Name VARCHAR(30),
    @Description VARCHAR(100),
    @VAT VARCHAR(1),
    @BuyPrice DECIMAL(10, 2),
    @SellPrice DECIMAL(10, 2),
    @Stock INT,
    @SupplierId INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        UPDATE Products
        SET
            [Name] = @Name,
            [Description] = @Description,
            VAT = @VAT,
            BuyPrice = @BuyPrice,
            SellPrice = @SellPrice,
            Stock = @Stock,
            SupplierId = @SupplierId
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
    END CATCH;
END;

DROP PROCEDURE DeleteProduct;
CREATE PROCEDURE DeleteProduct
    @Id INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DELETE FROM Products
        WHERE Id = @Id;
    END TRY
    BEGIN CATCH
        RAISERROR('Para borrar este producto primero debe borrarlo todos los detalle factura dónde aparezca.', 16, 1);
    END CATCH;
END;

EXEC DeleteProduct
    @Id = 1;

DROP PROCEDURE SearchOrderDetail;

CREATE PROCEDURE SearchOrderDetail
    @OrderId INT,
    @ProductId NVARCHAR(10) = NULL,
    @ProductName NVARCHAR(30) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        P.Id AS IdProducto,
        P.[Name] AS NombreProducto,
        SUM(OD.Amount) AS Cantidad,
        P.SellPrice AS PrecioUnitario,
        SUM(OD.Subtotal) AS Subtotal
    FROM
        OrderDetail OD
    INNER JOIN
        Products P ON OD.ProductId = P.Id
    WHERE
        OD.OrderId = @OrderId
        AND (@ProductId IS NULL OR CONVERT(NVARCHAR(10), P.Id) LIKE @ProductId + '%')
        AND (@ProductName IS NULL OR P.[Name] LIKE @ProductName + '%')
    GROUP BY
        OD.OrderId,
        P.Id,
        P.[Name],
        P.SellPrice
END;

EXEC SearchOrderDetail @OrderId = 1, @ProductName = 'Lap';

DROP PROCEDURE InsertOrderDetail;

CREATE PROCEDURE InsertOrderDetail
    @OrderId INT,
    @ProductId INT,
    @Amount INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si el BillId existe en la tabla "Bills"
        IF NOT EXISTS (SELECT 1 FROM Orders WHERE Id = @OrderId)
        BEGIN
            RAISERROR('El OrderId ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin insertar el detalle de la factura
        END

        -- Verificar si el ProductId existe en la tabla "Products"
        IF NOT EXISTS (SELECT 1 FROM Products WHERE Id = @ProductId)
        BEGIN
            RAISERROR('El ProductId ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin insertar el detalle de la factura
        END
        -- Insertar el detalle de la factura en la tabla "BillDetail"
        INSERT INTO OrderDetail (OrderId, ProductId, Amount)
        VALUES (@OrderId, @ProductId, @Amount);

    END TRY
    BEGIN CATCH
        -- Capturar la excepción y mostrar el mensaje de error personalizado
        RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
    END CATCH
END;
select * from orderdetail
select * from products

EXEC InsertOrderDetail @OrderId = 2, @ProductId = 3, @Amount = 2;

DROP PROCEDURE UpdateOrderDetail;

CREATE PROCEDURE UpdateOrderDetail
    @OrderId INT,
    @ProductId INT,
    @Amount INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        -- Verificar si el BillId existe en la tabla "Bills"
        IF NOT EXISTS (SELECT 1 FROM Orders WHERE Id = @OrderId)
        BEGIN
            RAISERROR('El OrderId ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin actualizar el detalle de la factura
        END

        -- Verificar si el ProductId existe en la tabla "Products"
        IF NOT EXISTS (SELECT 1 FROM Products WHERE Id = @ProductId)
        BEGIN
            RAISERROR('El ProductId ingresado no es válido.', 16, 1);
            RETURN; -- Salir del procedimiento sin actualizar el detalle de la factura
        END

        -- Actualizar el detalle de la factura en la tabla "BillDetail"
        UPDATE OrderDetail
        SET Amount = @Amount
        WHERE OrderId = @OrderId AND ProductId = @ProductId;

    END TRY
    BEGIN CATCH
		DECLARE @ErrorMessage NVARCHAR(4000) = 'Ha ocurrido un error inesperado. ' + ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;

EXEC UpdateOrderDetail @OrderId = 2, @ProductId = 3, @Amount = 10;


DROP PROCEDURE DeleteOrderDetail;

CREATE PROCEDURE DeleteOrderDetail
	@OrderId INT,
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
    DELETE FROM OrderDetail WHERE Orderid = @OrderId AND ProductId = @ProductId;
	END TRY
	BEGIN CATCH
        -- Capturar la excepción y mostrar el mensaje de error personalizado
        RAISERROR('Ha ocurrido un error inesperado.', 16, 1);
    END CATCH
END;

SELECT * FROM OrderDetail WHERE Orderid = 2;

EXEC DeleteOrderDetail @OrderId = 2, @ProductId = 3;





