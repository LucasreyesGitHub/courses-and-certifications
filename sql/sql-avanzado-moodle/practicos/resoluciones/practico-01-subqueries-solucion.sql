-- =============================================================
-- SQL Analytics II — Instituto CPE, Uruguay
-- Práctico 1 — Subqueries (Subconsultas)
-- Solución oficial
-- Base de datos: AdventureWorks2008 (T-SQL / SQL Server)
-- =============================================================

USE AdventureWorks2008;
GO

-- -------------------------------------------------------------
-- Ejercicio 1
-- Reporte con total de órdenes y total de unidades vendidas
-- para productos de la categoría 'Components'.
-- Ordenar por TerritoryID ascendente.
-- Patrón: subquery anidada en 3 niveles con IN
-- -------------------------------------------------------------
SELECT st.TerritoryID,
       st.Name,
       COUNT(DISTINCT sod.SalesOrderID) AS TotalOrdenes,
       SUM(OrderQty)                    AS TotalUnidades
FROM Sales.SalesTerritory AS st
JOIN Sales.SalesOrderHeader AS soh ON st.TerritoryID = soh.TerritoryID
JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
WHERE ProductID IN (
    SELECT ProductID
    FROM Production.Product AS p
    WHERE p.ProductSubcategoryID IN (
        SELECT ps.ProductSubcategoryID
        FROM Production.ProductSubcategory AS ps
        WHERE ps.ProductCategoryID IN (
            SELECT pc.ProductCategoryID
            FROM Production.ProductCategory AS pc
            WHERE pc.Name = 'Components'
        )
    )
)
GROUP BY st.TerritoryID, st.Name
ORDER BY st.TerritoryID;


-- -------------------------------------------------------------
-- Ejercicio 2a
-- Empleados con horas de enfermedad menores al promedio.
-- Usando EXISTS
-- Patrón: EXISTS con subquery correlacionada
-- -------------------------------------------------------------
SELECT p.BusinessEntityID, p.FirstName, p.LastName
FROM Person.Person AS p
WHERE EXISTS (
    SELECT hre.BusinessEntityID
    FROM HumanResources.Employee hre
    WHERE SickLeaveHours < (
        SELECT AVG(SickLeaveHours)
        FROM HumanResources.Employee
    )
    AND p.BusinessEntityID = hre.BusinessEntityID
)
ORDER BY p.BusinessEntityID;


-- -------------------------------------------------------------
-- Ejercicio 2b
-- Mismo resultado que 2a pero usando IN en lugar de EXISTS
-- Patrón: IN con subquery correlacionada
-- -------------------------------------------------------------
SELECT p.BusinessEntityID, p.FirstName, p.LastName
FROM Person.Person AS p
WHERE p.BusinessEntityID IN (
    SELECT hre.BusinessEntityID
    FROM HumanResources.Employee hre
    WHERE SickLeaveHours < (
        SELECT AVG(SickLeaveHours) FROM HumanResources.Employee
    )
    AND p.BusinessEntityID = hre.BusinessEntityID
)
ORDER BY p.BusinessEntityID;


-- -------------------------------------------------------------
-- Ejercicio 3
-- CustomerID, ventas del cliente en 2003 y total del año.
-- Ordenar por ventas del cliente DESC, luego CustomerID ASC.
-- Patrón: scalar subquery no correlacionada en SELECT
-- -------------------------------------------------------------
SELECT
    CustomerID,
    COUNT(soh.SalesOrderID) AS VentasPorCliente,
    (SELECT COUNT(SalesOrderID)
     FROM Sales.SalesOrderHeader
     WHERE YEAR(OrderDate) = 2003
    ) AS TotalDeVentas
FROM Sales.SalesOrderHeader AS soh
WHERE YEAR(soh.OrderDate) = 2003
GROUP BY CustomerID
ORDER BY VentasPorCliente DESC, CustomerID;


-- -------------------------------------------------------------
-- Ejercicio 4
-- CustomerID, ventas del cliente en 2004 y porcentaje del total.
-- Patrón: scalar subquery no correlacionada + FORMAT para porcentaje
-- -------------------------------------------------------------
SELECT
    CustomerID,
    COUNT(soh.SalesOrderID) AS VentasPorCliente,
    FORMAT(
        CAST(COUNT(soh.SalesOrderID) AS FLOAT) /
        (SELECT COUNT(SalesOrderID)
         FROM Sales.SalesOrderHeader
         WHERE YEAR(OrderDate) = 2004),
        'P'
    ) AS TotalDeVentas
FROM Sales.SalesOrderHeader AS soh
WHERE YEAR(soh.OrderDate) = 2004
GROUP BY CustomerID
ORDER BY VentasPorCliente DESC;


-- -------------------------------------------------------------
-- Ejercicio 5
-- Clientes con más de 20 compras: CustomerID, nombre, apellido.
-- Patrón: EXISTS con HAVING en la subquery interna
-- -------------------------------------------------------------
SELECT C.CustomerID, FirstName, LastName
FROM Sales.Customer C
INNER JOIN Person.Person P ON C.PersonID = P.BusinessEntityID
WHERE EXISTS (
    SELECT 1
    FROM Sales.SalesOrderHeader SH
    WHERE SH.CustomerID = C.CustomerID
    GROUP BY CustomerID
    HAVING COUNT(SalesOrderID) > 20
);
