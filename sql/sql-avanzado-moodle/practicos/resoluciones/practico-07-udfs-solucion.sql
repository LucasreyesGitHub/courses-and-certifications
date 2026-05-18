-- =============================================================
-- SQL Analytics II — Instituto CPE, Uruguay
-- Práctico 7 — UDFs (User Defined Functions)
-- Solución generada (sin solución oficial disponible)
-- Verificar resultados contra AdventureWorks2008 en SQL Server
-- Base de datos: AdventureWorks2008 (T-SQL / SQL Server)
-- =============================================================

USE AdventureWorks2008;
GO

-- -------------------------------------------------------------
-- Ejercicio 1
-- Función escalar: TotalCustomerByYear
-- Recibe CustomerID y año; devuelve el total de ventas (TotalDue).
-- Patrón: scalar UDF con SELECT @var = SUM(...)
-- -------------------------------------------------------------
CREATE FUNCTION Sales.TotalCustomerByYear (
    @CustomerID INT,
    @Year       INT
)
RETURNS MONEY
AS
BEGIN
    DECLARE @Total MONEY;
    SELECT @Total = SUM(TotalDue)
    FROM Sales.SalesOrderHeader
    WHERE CustomerID = @CustomerID
      AND YEAR(OrderDate) = @Year;
    RETURN @Total;
END;
GO

-- Uso: total del cliente 11001 en 2004
SELECT Sales.TotalCustomerByYear(11001, 2004) AS TotalCliente11001_2004;

-- Uso en SELECT sobre todos los clientes (2004)
SELECT DISTINCT CustomerID,
       Sales.TotalCustomerByYear(CustomerID, 2004) AS TotalAnual2004
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2004
ORDER BY TotalAnual2004 DESC;
GO


-- -------------------------------------------------------------
-- Ejercicio 2
-- Función escalar: AntiguedadEmpleado
-- Recibe BusinessEntityID; devuelve años de antigüedad.
-- Patrón: scalar UDF con DATEDIFF(YEAR, HireDate, GETDATE())
-- -------------------------------------------------------------
CREATE FUNCTION HumanResources.AntiguedadEmpleado (
    @EmployeeID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Antiguedad INT;
    SELECT @Antiguedad = DATEDIFF(YEAR, HireDate, GETDATE())
    FROM HumanResources.Employee
    WHERE BusinessEntityID = @EmployeeID;
    RETURN @Antiguedad;
END;
GO

-- Uso: antigüedad del empleado 1
SELECT HumanResources.AntiguedadEmpleado(1) AS AnosDeAntigüedad;

-- Uso en SELECT: ranking de empleados por antigüedad
SELECT p.BusinessEntityID,
       p.FirstName,
       p.LastName,
       e.HireDate,
       HumanResources.AntiguedadEmpleado(e.BusinessEntityID) AS Antiguedad
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
ORDER BY Antiguedad DESC;
GO


-- -------------------------------------------------------------
-- Ejercicio 3
-- Función escalar: OrdenesEntreFechas
-- Recibe CustomerID, fecha inicio y fecha fin.
-- Devuelve el conteo de órdenes del cliente en ese rango.
-- Patrón: scalar UDF con COUNT + BETWEEN
-- -------------------------------------------------------------
CREATE FUNCTION Sales.OrdenesEntreFechas (
    @CustomerID   INT,
    @FechaInicio  DATE,
    @FechaFin     DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @Total INT;
    SELECT @Total = COUNT(SalesOrderID)
    FROM Sales.SalesOrderHeader
    WHERE CustomerID = @CustomerID
      AND OrderDate BETWEEN @FechaInicio AND @FechaFin;
    RETURN @Total;
END;
GO

-- Uso: órdenes del cliente 11001 en 2003
SELECT Sales.OrdenesEntreFechas(11001, '2003-01-01', '2003-12-31') AS OrdenesEn2003;

-- Uso en SELECT para los 10 clientes más activos en un período
SELECT TOP 10
    CustomerID,
    Sales.OrdenesEntreFechas(CustomerID, '2004-01-01', '2004-12-31') AS OrdenesPeriodo
FROM Sales.SalesOrderHeader
WHERE YEAR(OrderDate) = 2004
GROUP BY CustomerID
ORDER BY OrdenesPeriodo DESC;
GO


-- -------------------------------------------------------------
-- Ejercicio 4
-- TVF: VentasPorTerritorio
-- Recibe año; devuelve tabla con TerritoryID, nombre y TotalVentas.
-- Patrón: inline TVF (RETURNS TABLE) con JOIN y GROUP BY
-- Uso: en FROM como vista parametrizada
-- -------------------------------------------------------------
CREATE FUNCTION Sales.VentasPorTerritorio (@Year INT)
RETURNS TABLE
AS
RETURN (
    SELECT st.TerritoryID,
           st.Name                        AS Territorio,
           SUM(soh.TotalDue)              AS TotalVentas,
           COUNT(DISTINCT soh.SalesOrderID) AS TotalOrdenes
    FROM Sales.SalesTerritory st
    JOIN Sales.SalesOrderHeader soh ON st.TerritoryID = soh.TerritoryID
    WHERE YEAR(soh.OrderDate) = @Year
    GROUP BY st.TerritoryID, st.Name
);
GO

-- Uso: ventas por territorio en 2004
SELECT * FROM Sales.VentasPorTerritorio(2004) ORDER BY TotalVentas DESC;

-- Uso con JOIN: territorio + detalle adicional
SELECT t.Territorio, t.TotalVentas, st.CountryRegionCode
FROM Sales.VentasPorTerritorio(2004) t
JOIN Sales.SalesTerritory st ON t.TerritoryID = st.TerritoryID
ORDER BY t.TotalVentas DESC;
GO


-- -------------------------------------------------------------
-- Ejercicio 5
-- TVF: Bottom5ProductosPorAnio
-- Recibe año; devuelve los 5 productos con MENOR total de ventas.
-- Patrón: inline TVF con TOP 5 + ORDER BY ASC
-- Uso: en FROM como vista parametrizada
-- -------------------------------------------------------------
CREATE FUNCTION Production.Bottom5ProductosPorAnio (@Year INT)
RETURNS TABLE
AS
RETURN (
    SELECT TOP 5
           p.ProductID,
           p.Name                                    AS Producto,
           SUM(sod.OrderQty * sod.UnitPrice)         AS TotalVentas,
           SUM(sod.OrderQty)                         AS TotalUnidades
    FROM Production.Product p
    JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    WHERE YEAR(soh.OrderDate) = @Year
    GROUP BY p.ProductID, p.Name
    ORDER BY TotalVentas ASC
);
GO

-- Uso: peores productos en 2004
SELECT * FROM Production.Bottom5ProductosPorAnio(2004);

-- Comparar: peores de 2003 vs 2004
SELECT '2003' AS Anio, Producto, TotalVentas FROM Production.Bottom5ProductosPorAnio(2003)
UNION ALL
SELECT '2004', Producto, TotalVentas FROM Production.Bottom5ProductosPorAnio(2004)
ORDER BY Anio, TotalVentas;
GO
