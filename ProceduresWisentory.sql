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
    @name NVARCHAR(100) = NULL,
    @lastName NVARCHAR(100) = NULL,
    @number NVARCHAR(20) = NULL,
    @email NVARCHAR(100) = NULL
AS
BEGIN
    SELECT 
        Id AS [Id],
        [Name] AS [Nombre],
        [LastName] AS [Apellido],
        PhoneNumber AS [Número],
        Email AS [Email]
    FROM Clients
    WHERE (@name IS NULL OR [Name] LIKE @name + '%')
      AND (@lastName IS NULL OR [LastName] LIKE @lastName + '%')
      AND (@number IS NULL OR PhoneNumber LIKE @number + '%')
      AND (@email IS NULL OR Email LIKE @email + '%');
END


EXEC SearchClients @name = 'No';

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
    UPDATE Clients
    SET
        [Name] = @Name,
        [LastName] = @LastName,
        PhoneNumber = ISNULL(@PhoneNumber, 'N/A'),
        Email = ISNULL(@Email, 'N/A')
    WHERE
        Id = @Id;
END




CREATE PROCEDURE DeleteClient
    @id INT
AS
BEGIN
    DELETE FROM Clients
    WHERE Id = @id;
END





