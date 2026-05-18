-- =============================================================
-- SQL Analytics II — Instituto CPE, Uruguay
-- Práctico 2 — DDL + DML (Comandos de Manipulación y Definición)
-- Solución oficial
-- Base de datos: AdventureWorks2008 (T-SQL / SQL Server)
-- Patrón general: BUILD → ENRICH → CLEAN sobre tablas temporales
-- =============================================================

USE AdventureWorks2008;
GO

-- -------------------------------------------------------------
-- Ejercicio 1
-- Crear tabla temporal con año, cliente, producto, qty y precio.
-- Patrón: SELECT INTO para creación implícita de tabla temporal
-- -------------------------------------------------------------
SELECT
    YEAR(soh.OrderDate) AS OrderYear,
    soh.CustomerID,
    sod.ProductID,
    sod.OrderQty,
    sod.UnitPrice
INTO #temp
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID;


-- -------------------------------------------------------------
-- Ejercicio 2
-- Desde #temp, crear tabla con total de ventas por año 2001.
-- Patrón: SELECT INTO con WHERE + GROUP BY sobre tabla temporal
-- -------------------------------------------------------------
SELECT
    OrderYear,
    CustomerID,
    ProductID,
    SUM(OrderQty * UnitPrice) AS TotalSales
INTO #ventasClientesAñoProd
FROM #temp
WHERE OrderYear = 2001
GROUP BY OrderYear, CustomerID, ProductID;


-- -------------------------------------------------------------
-- Ejercicio 3
-- Agregar columna NombreProducto a la tabla de ventas 2001.
-- Verificar que los registros existentes quedan con NULL.
-- Patrón: ALTER TABLE ADD
-- -------------------------------------------------------------
ALTER TABLE #ventasClientesAñoProd
ADD ProductName NVARCHAR(50);

SELECT *
FROM #ventasClientesAñoProd;


-- -------------------------------------------------------------
-- Ejercicio 4
-- Tabla temporal con ProductID y Nombre para todos los productos.
-- -------------------------------------------------------------
SELECT ProductID, Name AS ProductName
INTO #Productos
FROM Production.Product;


-- -------------------------------------------------------------
-- Ejercicio 5
-- Insertar ventas de otros años (no 2001) con el ProductName
-- obtenido del JOIN con #Productos.
-- Patrón: INSERT INTO ... SELECT con JOIN entre temps
-- -------------------------------------------------------------
INSERT INTO #ventasClientesAñoProd
SELECT
    OrderYear,
    CustomerID,
    t.ProductID,
    SUM(OrderQty * UnitPrice) AS TotalSales,
    p.ProductName
FROM #temp AS t
JOIN #Productos AS p ON t.ProductID = p.ProductID
WHERE OrderYear != 2001
GROUP BY OrderYear, CustomerID, t.ProductID, p.ProductName;


-- -------------------------------------------------------------
-- Ejercicio 6
-- Actualizar ProductName de los registros del 2001 (que son NULL).
-- Patrón: UPDATE con WHERE para filas específicas
-- -------------------------------------------------------------
UPDATE #ventasClientesAñoProd
SET ProductName = 'Producto Discontinuado'
WHERE OrderYear = 2001;


-- -------------------------------------------------------------
-- Ejercicio 7
-- Eliminar la columna ProductId de la tabla de resumen.
-- Patrón: ALTER TABLE DROP COLUMN
-- -------------------------------------------------------------
ALTER TABLE #ventasClientesAñoProd
DROP COLUMN ProductId;


-- -------------------------------------------------------------
-- Ejercicio 8
-- Eliminar la tabla temporal base #temp.
-- Patrón: DROP TABLE
-- -------------------------------------------------------------
DROP TABLE #temp;


-- -------------------------------------------------------------
-- Ejercicio 9
-- Eliminar registros de productos discontinuados.
-- Patrón: DELETE FROM con WHERE
-- -------------------------------------------------------------
DELETE FROM #ventasClientesAñoProd
WHERE ProductName = 'Producto Discontinuado';


-- Verificación final
SELECT TOP 20 * FROM #ventasClientesAñoProd ORDER BY OrderYear, CustomerID;
