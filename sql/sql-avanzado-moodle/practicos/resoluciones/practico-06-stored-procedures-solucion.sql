-- =============================================================
-- SQL Analytics II — Instituto CPE, Uruguay
-- Práctico 6 — Stored Procedures (Procedimientos Almacenados)
-- Solución oficial
-- Base de datos: AdventureWorks2008 (T-SQL / SQL Server)
-- =============================================================

USE AdventureWorks2008;
GO

-- -------------------------------------------------------------
-- Ejercicio 1
-- SP que recibe CustomerID y devuelve la suma total en OUTPUT.
-- Patrón: CREATE PROCEDURE con parámetro OUTPUT
-- -------------------------------------------------------------
CREATE PROCEDURE Sales.TotalOrders
    @CustomerID  INT,
    @TotalOrders INT OUTPUT
AS
SELECT @TotalOrders = SUM(TotalDue)
FROM Sales.SalesOrderHeader
WHERE CustomerID = @CustomerID;
GO

-- Ejecución: CustomerID = 11001
DECLARE @Total INT;
EXEC Sales.TotalOrders 11001, @Total OUTPUT;
SELECT @Total AS TotalOrdenesCliente11001;
GO


-- -------------------------------------------------------------
-- Ejercicio 2
-- SP que recibe una fecha y muestra empleados contratados ese día.
-- Patrón: CREATE PROCEDURE con parámetro INPUT (DATE)
-- -------------------------------------------------------------
CREATE PROCEDURE HumanResources.HireInDate @Fecha DATE
AS
SELECT Title, FirstName, LastName, JobTitle
FROM HumanResources.Employee E
INNER JOIN Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
WHERE HireDate = @Fecha;
GO

-- Ejecución: fecha 07/01/1999
EXEC HumanResources.HireInDate '1999-01-07';
GO


-- -------------------------------------------------------------
-- Ejercicio 3
-- SP que recibe ProductID y devuelve las órdenes que lo tienen.
-- Patrón: CREATE PROCEDURE con DISTINCT para evitar duplicados
-- -------------------------------------------------------------
CREATE PROCEDURE OrdersProductID @ProductID INT
AS
SELECT DISTINCT SalesOrderID
FROM Sales.SalesOrderDetail
WHERE ProductID = @ProductID;
GO

-- Ejecución: ProductID = 707
EXEC OrdersProductID 707;
GO


-- -------------------------------------------------------------
-- Ejercicio 4
-- Modificar el SP anterior para recibir nombre de producto.
-- Patrón: ALTER PROCEDURE (cambia tipo de parámetro y lógica)
-- -------------------------------------------------------------
ALTER PROCEDURE OrdersProductID @ProductName NVARCHAR(50)
AS
SELECT DISTINCT SalesOrderID
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE p.Name = @ProductName;
GO

-- Ejecución con nombre
EXEC OrdersProductID 'Sport-100 Helmet, Red';
GO


-- -------------------------------------------------------------
-- Ejercicio 5
-- SP que recibe 2 fechas y devuelve la suma de TotalDue entre ellas.
-- Usa RETURN para devolver el valor escalar.
-- Patrón: RETURN @valor para resultado escalar entero/money
-- Nota: RETURN solo acepta INT nativamente; MONEY se puede perder precisión.
--       Para MONEY preciso, usar parámetro OUTPUT.
-- -------------------------------------------------------------
CREATE PROCEDURE TotalDateRange @DateInit DATE, @DateEnd DATE
AS
DECLARE @Total MONEY;
SELECT @Total = SUM(TotalDue)
FROM Sales.SalesOrderHeader
WHERE OrderDate BETWEEN @DateInit AND @DateEnd;
RETURN @Total;
GO

-- Ejecución: 01/07/2001 a 01/08/2001
DECLARE @ReturnTotal MONEY;
EXEC @ReturnTotal = TotalDateRange '2001-07-01', '2001-09-01';
SELECT @ReturnTotal AS TotalVentas;
GO
