-- =============================================================
-- SQL Analytics II — Instituto CPE, Uruguay
-- Práctico 3 — Tablas Temporales
-- Solución oficial
-- Base de datos: AdventureWorks2008 (T-SQL / SQL Server)
-- =============================================================

USE AdventureWorks2008;
GO

-- -------------------------------------------------------------
-- Ejercicio 1
-- Tabla temporal LOCAL con historial de sueldos de empleados.
-- Campos: BusinessEntityID, NombreCompleto, SueldoSemanal (40hs), ValidoDesde.
-- Patrón: SELECT INTO #local con CONCAT y CONVERT de fecha
-- -------------------------------------------------------------
SELECT p.BusinessEntityID,
       CONCAT(LastName, ', ', FirstName)     AS NombreCompleto,
       (40 * hre2.Rate)                      AS SueldoSemanal,
       CONVERT(VARCHAR, hre2.RateChangeDate, 103) AS ValidoDesde
INTO #SueldoHistoricoEmpleados
FROM Person.Person AS p
JOIN HumanResources.Employee AS hre
    ON p.BusinessEntityID = hre.BusinessEntityID
JOIN HumanResources.EmployeePayHistory AS hre2
    ON hre.BusinessEntityID = hre2.BusinessEntityID;

SELECT TOP 10 * FROM #SueldoHistoricoEmpleados ORDER BY NombreCompleto;


-- -------------------------------------------------------------
-- Ejercicio 2
-- Tabla temporal GLOBAL con solo el sueldo actual de cada empleado
-- (fecha de cambio más reciente por empleado).
-- Patrón: SELECT INTO ##global con subquery correlacionada para MAX fecha
-- -------------------------------------------------------------
SELECT p.BusinessEntityID,
       CONCAT(LastName, ', ', FirstName)     AS NombreCompleto,
       (40 * hre2.Rate)                      AS SueldoSemanal,
       CONVERT(VARCHAR, hre2.RateChangeDate, 103) AS ValidoDesde
INTO ##SueldoActualEmpleados
FROM Person.Person AS p
JOIN HumanResources.Employee AS hre
    ON p.BusinessEntityID = hre.BusinessEntityID
JOIN HumanResources.EmployeePayHistory AS hre2
    ON hre.BusinessEntityID = hre2.BusinessEntityID
WHERE hre2.RateChangeDate = (
    SELECT MAX(RateChangeDate)
    FROM HumanResources.EmployeePayHistory AS hre1
    WHERE hre.BusinessEntityID = hre1.BusinessEntityID
);

SELECT TOP 10 * FROM ##SueldoActualEmpleados ORDER BY NombreCompleto;


-- -------------------------------------------------------------
-- Ejercicio 3
-- Tabla temporal con categorías de empleados y su clasificación.
-- Patrón: CREATE TABLE + INSERT VALUES (20 filas)
-- Diferencia con SELECT INTO: control explícito de tipos y estructura
-- -------------------------------------------------------------
CREATE TABLE #PersonType (
    Id            NUMERIC(4),
    Categoria     NVARCHAR(50),
    Clasificacion NCHAR(50)
);

INSERT INTO #PersonType (Id, Categoria, Clasificacion)
VALUES
    (1,  'Accounting Manager',               'Mandos medios'),
    (2,  'Assistant Sales Agent',            'Empleados'),
    (3,  'Assistant Sales Representative',   'Empleados'),
    (4,  'Coordinator Foreign Markets',      'Empleados Senior'),
    (5,  'Export Administrator',             'Empleados'),
    (6,  'International Marketing Manager',  'Mandos medios'),
    (7,  'Marketing Assistant',              'Empleados'),
    (8,  'Marketing Manager',               'Mandos medios'),
    (9,  'Marketing Representative',         'Empleados'),
    (10, 'Order Administrator',              'Empleados Senior'),
    (11, 'Owner',                            'Alta Gerencia'),
    (12, 'Owner/Marketing Assistant',        'Empleados Senior'),
    (13, 'Product Manager',                  'Mandos medios'),
    (14, 'Purchasing Agent',                 'Empleados'),
    (15, 'Purchasing Manager',               'Mandos medios'),
    (16, 'Regional Account Representative',  'Empleados Senior'),
    (17, 'Sales Agent',                      'Empleados'),
    (18, 'Sales Associate',                  'Empleados'),
    (19, 'Sales Manager',                    'Mandos medios'),
    (20, 'Sales Representative',             'Empleados');

SELECT * FROM #PersonType ORDER BY Id;


-- -------------------------------------------------------------
-- Ejercicio 4
-- Tabla temporal con ventas totales por territorio y año.
-- Patrón: SELECT INTO con agregación y JOIN de 3 tablas
-- -------------------------------------------------------------
SELECT st.Name AS Territorio,
       YEAR(soh.OrderDate) AS Año,
       SUM(sod.OrderQty * sod.UnitPrice) AS TotalVendido
INTO #VentasAnualesPorTerritorio
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Sales.SalesTerritory st ON st.TerritoryID = soh.TerritoryID
GROUP BY st.TerritoryID, st.Name, YEAR(soh.OrderDate);

SELECT TOP 20 * FROM #VentasAnualesPorTerritorio ORDER BY Territorio, Año;


-- -------------------------------------------------------------
-- Ejercicio 5
-- Tabla temporal GLOBAL con clientes que solo compraron una vez.
-- Patrón: SELECT INTO ##global con IN + subquery HAVING COUNT = 1
-- -------------------------------------------------------------
SELECT C.CustomerID, FirstName, LastName, SH.OrderDate
INTO ##UnicaCompra
FROM Sales.SalesOrderHeader SH
JOIN Sales.Customer AS c ON SH.CustomerID = C.CustomerID
JOIN Person.Person AS P ON c.PersonID = P.BusinessEntityID
WHERE SH.CustomerID IN (
    SELECT CustomerID
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
    HAVING COUNT(SalesOrderID) = 1
);

SELECT COUNT(*) AS TotalClientesUnicaCompra FROM ##UnicaCompra;
SELECT TOP 10 * FROM ##UnicaCompra ORDER BY LastName;
