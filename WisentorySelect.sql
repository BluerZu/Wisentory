--Ver usuario:
USE WisentoryDB;
SELECT name
FROM sys.database_principals
WHERE name = 'WisentoryManager';

--Ver permisos:
USE WisentoryDB;
SELECT 
    pr.principal_id,
    pr.name AS [Principal],
    pr.type_desc AS [Principal Type],
    pe.permission_name AS [Permission]
FROM sys.database_principals AS pr
LEFT JOIN sys.database_permissions AS pe ON pe.grantee_principal_id = pr.principal_id
WHERE pr.name = 'WisentoryManager';

--Ver Users:
Use WisentoryDB;
Select * From Users;

Select * From Suppliers;

Select * From Products;

Select * From Clients;

Select * From Orders;

Select * From OrderDetail;

Select * From Bills;

Select * From BillDetail;

SELECT  C.Id AS NumeroCliente,CONCAT(C.[Name], ' ', C.[LastName]) AS NombreCompleto, SUM(B.Total) AS TotalFacturas
FROM Clients C
LEFT JOIN Bills B ON C.Id = B.ClientId
GROUP BY CONCAT(C.[Name], ' ', C.[LastName]), C.Id
ORDER BY TotalFacturas DESC;

