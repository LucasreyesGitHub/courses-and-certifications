-- =============================================================
-- SQL Analytics II — Instituto CPE, Uruguay
-- Práctico 4 — Views (Vistas)
-- Solución oficial
-- Base de datos: AdventureWorks2008 (T-SQL / SQL Server)
-- =============================================================

USE AdventureWorks2008;
GO

-- -------------------------------------------------------------
-- Ejercicio 1
-- Vista CustomerProductTotalQty: resumen de unidades por cliente/producto.
-- Luego: 3 consultas sobre la vista.
-- Patrón: CREATE VIEW con GROUP BY + queries reutilizando la vista
-- -------------------------------------------------------------
CREATE VIEW CustomerProductTotalQty
AS
SELECT soh.CustomerID,
       p.ProductID,
       p.Name,
       SUM(sod.OrderQty) AS Cantidad
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY soh.CustomerID, p.ProductID, p.Name;
GO

-- 1a. Total de unidades para CustomerID 12001
SELECT SUM(Cantidad) AS TotalCustomer
FROM CustomerProductTotalQty
WHERE CustomerID = 12001;

-- 1b. Top 10 productos por unidades vendidas
SELECT TOP 10 ProductID, Name, SUM(Cantidad) AS Total
FROM CustomerProductTotalQty
GROUP BY ProductID, Name
ORDER BY Total DESC;

-- 1c. 5 clientes con menos unidades del producto 711
SELECT TOP 5 CustomerID
FROM CustomerProductTotalQty
WHERE ProductID = 711
ORDER BY Cantidad DESC;


-- -------------------------------------------------------------
-- Ejercicio 2
-- Vista EmployeeWithNames: simplifica el JOIN Employee ↔ Person.
-- Luego: 3 consultas sobre la vista.
-- Patrón: vista como capa de abstracción para JOINs frecuentes
-- -------------------------------------------------------------
CREATE VIEW EmployeeWithNames
AS
SELECT e.*, p.FirstName, p.LastName
FROM HumanResources.Employee AS e
JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID;
GO

-- 2a. Empleados contratados en 2001
SELECT JobTitle, FirstName, LastName
FROM EmployeeWithNames
WHERE YEAR(HireDate) = 2001;

-- 2b. 5 empleados más longevos (nacidos antes)
SELECT TOP 5 FirstName, LastName, BirthDate
FROM EmployeeWithNames
ORDER BY BirthDate;

-- 2c. 10 empleados más nuevos en la empresa
SELECT TOP 10 FirstName, LastName, HireDate
FROM EmployeeWithNames
ORDER BY HireDate DESC;


-- -------------------------------------------------------------
-- Ejercicio 3
-- Modificar la vista para exponer campos específicos.
-- Luego: 2 consultas sobre la vista modificada.
-- Patrón: ALTER VIEW para cambiar la estructura expuesta
-- -------------------------------------------------------------
ALTER VIEW EmployeeWithNames
AS
SELECT e.JobTitle,
       e.BirthDate,
       e.HireDate,
       p.Title,
       p.FirstName,
       p.MiddleName,
       p.LastName
FROM HumanResources.Employee AS e
JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID;
GO

-- 3a. Todos los que tienen 'Manager' en el título
SELECT Title, FirstName, MiddleName, LastName, JobTitle
FROM EmployeeWithNames
WHERE JobTitle LIKE '%Manager%';

-- 3b. Empleados sin segundo nombre en la base
SELECT FirstName, LastName, JobTitle
FROM EmployeeWithNames
WHERE MiddleName IS NULL;
