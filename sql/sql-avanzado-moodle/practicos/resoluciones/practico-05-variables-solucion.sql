-- =============================================================
-- SQL Analytics II — Instituto CPE, Uruguay
-- Práctico 5 — Variables
-- Solución oficial
-- Base de datos: AdventureWorks2008 (T-SQL / SQL Server)
-- =============================================================

USE AdventureWorks2008;
GO

-- -------------------------------------------------------------
-- Ejercicio 1
-- Variable con última fecha de orden. Reporte de órdenes en esa fecha.
-- Patrón: DECLARE → SELECT @var = MAX(...) → usar en WHERE
-- -------------------------------------------------------------
DECLARE @LastDate DATE;

SELECT @LastDate = MAX(OrderDate)
FROM Sales.SalesOrderHeader;

SELECT SalesOrderID, CustomerID, TotalDue
FROM Sales.SalesOrderHeader
WHERE OrderDate = @LastDate
ORDER BY TotalDue DESC;
GO


-- -------------------------------------------------------------
-- Ejercicio 2
-- Variable con CustomerID del cliente con más órdenes.
-- Luego: productos y cantidades que ordenó ese cliente.
-- Patrón: DECLARE → SELECT con ORDER BY (retiene último valor)
-- -------------------------------------------------------------
DECLARE @IdCustomerMax INT;

SELECT @IdCustomerMax = CustomerID
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
ORDER BY COUNT(SalesOrderID);

SELECT p.ProductID, p.Name, SUM(sod.OrderQty) AS QTY
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE soh.CustomerID = @IdCustomerMax
GROUP BY p.ProductID, p.Name
ORDER BY QTY DESC;
GO


-- -------------------------------------------------------------
-- Ejercicio 3
-- Variable para el promedio de sick leave hours.
-- Empleados con sick leave menor al promedio.
-- Patrón: DECLARE → SELECT @var = AVG(...) → usar en WHERE
-- -------------------------------------------------------------
DECLARE @AVGSickLeaveHours INT;

SELECT @AVGSickLeaveHours = AVG(SickLeaveHours)
FROM HumanResources.Employee;

SELECT e.BusinessEntityID, p.FirstName, p.LastName
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
WHERE e.SickLeaveHours < @AVGSickLeaveHours
ORDER BY BusinessEntityID;
GO


-- -------------------------------------------------------------
-- Ejercicio 4
-- Variables de año, mes, día para construir fecha 01-02-2004.
-- Patrón: DECLARE + SET + concatenación de strings como fecha
-- -------------------------------------------------------------
DECLARE @Year  VARCHAR(4);
DECLARE @Month VARCHAR(2);
DECLARE @Day   VARCHAR(2);

SET @Year  = '2004';
SET @Month = '02';
SET @Day   = '01';

SELECT SalesOrderID, CustomerID, OrderDate, TotalDue
FROM Sales.SalesOrderHeader
WHERE OrderDate = @Year + '-' + @Month + '-' + @Day;
GO


-- -------------------------------------------------------------
-- Ejercicio 5
-- Variables con el estado civil y género del CEO.
-- Empleados con valores DISTINTOS a los del CEO.
-- Patrón: SELECT @v1 = col1, @v2 = col2 → filtrar con <>
-- -------------------------------------------------------------
DECLARE @MaritalStatus NCHAR(1);
DECLARE @Gender        NCHAR(1);

SELECT @Gender = Gender, @MaritalStatus = MaritalStatus
FROM HumanResources.Employee
WHERE JobTitle = 'Chief Executive Officer';

SELECT FirstName, LastName
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
WHERE e.MaritalStatus <> @MaritalStatus
  AND e.Gender        <> @Gender;
GO
