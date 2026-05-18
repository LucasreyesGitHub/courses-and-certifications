-- =============================================================
-- SQL Analytics II — Instituto CPE, Uruguay
-- EXAMEN OBLIGATORIO — Mayo 2026
-- Resolución generada y comentada
-- 7 ejercicios / 100 puntos
-- Base de datos: AdventureWorks2008 (T-SQL / SQL Server)
-- =============================================================

USE AdventureWorks2008;
GO

-- =============================================================
-- EJERCICIO 1 — 10 puntos
-- Crear tabla temporal #Vtas_Producto_Año con ventas por producto y año.
-- Campos requeridos: ProductID, ProductName, Año, TotalUnidades, TotalVentas
-- Patrón: SELECT INTO con GROUP BY sobre 3 tablas
-- =============================================================
SELECT
    p.ProductID,
    p.Name                                    AS ProductName,
    YEAR(soh.OrderDate)                       AS Anio,
    SUM(sod.OrderQty)                         AS TotalUnidades,
    SUM(sod.OrderQty * sod.UnitPrice)         AS TotalVentas
INTO #Vtas_Producto_Año
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
GROUP BY p.ProductID, p.Name, YEAR(soh.OrderDate);

-- Verificación
SELECT TOP 10 * FROM #Vtas_Producto_Año ORDER BY Anio, TotalVentas DESC;
GO


-- =============================================================
-- EJERCICIO 2 — 15 puntos
-- Función escalar dbo.Variacion_Porc
-- Recibe dos valores (A, B); devuelve (A/B)-1 formateado como porcentaje.
-- Si B = 0, devuelve 'N/A' (evitar división por cero).
-- Patrón: scalar UDF con IF y FORMAT('P2')
-- =============================================================
CREATE FUNCTION dbo.Variacion_Porc (
    @ValorA MONEY,
    @ValorB MONEY
)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @Resultado VARCHAR(20);
    IF @ValorB = 0
        SET @Resultado = 'N/A';
    ELSE
        SET @Resultado = FORMAT((@ValorA / @ValorB) - 1, 'P2');
    RETURN @Resultado;
END;
GO

-- Test rápido
SELECT dbo.Variacion_Porc(120, 100) AS Variacion;  -- esperado: 20.00%
SELECT dbo.Variacion_Porc(100, 0)   AS DivCero;    -- esperado: N/A
GO


-- =============================================================
-- EJERCICIO 3 — 10 puntos
-- Vista que usa dbo.Variacion_Porc para comparar ListPrice vs StandardCost.
-- Luego consultar la vista filtrando por Categoría = 'Accessories'.
-- Patrón: CREATE VIEW que llama a UDF escalar
-- =============================================================
CREATE VIEW dbo.VariacionPrecioCosto
AS
SELECT
    p.ProductID,
    p.Name                                            AS Producto,
    p.ListPrice                                       AS PrecioLista,
    p.StandardCost                                    AS CostoEstandar,
    dbo.Variacion_Porc(p.ListPrice, p.StandardCost)   AS VariacionPorcentual,
    pc.Name                                           AS Categoria
FROM Production.Product p
JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID;
GO

-- Consulta sobre la vista: solo Accessories
SELECT *
FROM dbo.VariacionPrecioCosto
WHERE Categoria = 'Accessories'
ORDER BY PrecioLista DESC;
GO


-- =============================================================
-- EJERCICIO 4 — 20 puntos
-- SP dbo.QtyEmp_Vacation_Hours
-- INPUT:  @JobTitle, @FechaInicio, @FechaFin
-- OUTPUT: @CantEmpleados (INT), @TotalVacationHours (INT)
-- Devuelve la cantidad de empleados y las horas de vacación acumuladas
-- para el JobTitle dado, contratados en el rango de fechas.
-- Patrón: SP con múltiples parámetros OUTPUT
-- =============================================================
CREATE PROCEDURE dbo.QtyEmp_Vacation_Hours
    @JobTitle            NVARCHAR(50),
    @FechaInicio         DATE,
    @FechaFin            DATE,
    @CantEmpleados       INT OUTPUT,
    @TotalVacationHours  INT OUTPUT
AS
SET NOCOUNT ON;
SELECT
    @CantEmpleados      = COUNT(BusinessEntityID),
    @TotalVacationHours = SUM(VacationHours)
FROM HumanResources.Employee
WHERE JobTitle = @JobTitle
  AND HireDate BETWEEN @FechaInicio AND @FechaFin;
GO

-- Ejecución de ejemplo
DECLARE @Cant INT, @Vacaciones INT;
EXEC dbo.QtyEmp_Vacation_Hours
    'Sales Representative',
    '2000-01-01',
    '2005-12-31',
    @Cant OUTPUT,
    @Vacaciones OUTPUT;
SELECT @Cant AS CantidadEmpleados, @Vacaciones AS HorasVacacion;
GO


-- =============================================================
-- EJERCICIO 5 — 10 puntos
-- Para cada fila de SalesOrderHeader: mostrar SalesOrderID, CustomerID,
-- OrderDate, TotalDue, y el total anual del cliente (mismo año).
-- Usar SUBQUERY correlacionada.
-- Patrón: scalar subquery correlacionada en SELECT
-- =============================================================
SELECT
    soh.SalesOrderID,
    soh.CustomerID,
    soh.OrderDate,
    soh.TotalDue,
    -- Subquery: suma anual de ese cliente en ese año
    (SELECT SUM(soh2.TotalDue)
     FROM Sales.SalesOrderHeader AS soh2
     WHERE soh2.CustomerID = soh.CustomerID
       AND YEAR(soh2.OrderDate) = YEAR(soh.OrderDate)
    ) AS TotalAnualCliente
FROM Sales.SalesOrderHeader soh
ORDER BY soh.CustomerID, soh.OrderDate;


-- =============================================================
-- EJERCICIO 6 — 15 puntos
-- Mismo resultado que Ejercicio 5, pero usando OVER en lugar de subquery.
-- Patrón: SUM() OVER (PARTITION BY CustomerID, YEAR(OrderDate))
-- Optimización: OVER procesa una sola pasada; la subquery se ejecuta N veces
-- =============================================================
SELECT
    soh.SalesOrderID,
    soh.CustomerID,
    soh.OrderDate,
    soh.TotalDue,
    -- Window function: equivalente al total anual del cliente
    SUM(soh.TotalDue) OVER (
        PARTITION BY soh.CustomerID, YEAR(soh.OrderDate)
    ) AS TotalAnualCliente
FROM Sales.SalesOrderHeader soh
ORDER BY soh.CustomerID, soh.OrderDate;


-- =============================================================
-- EJERCICIO 7 — 20 puntos
-- Para cada orden de un cliente: mostrar la fecha de esa compra,
-- la fecha de la compra anterior del mismo cliente,
-- y los días transcurridos entre ambas.
-- Patrón: LAG(OrderDate) OVER (PARTITION BY CustomerID ORDER BY OrderDate)
--         + DATEDIFF(DAY, fecha_anterior, fecha_actual)
-- Primer compra de cada cliente: CompraAnterior = NULL, Dias = NULL
-- =============================================================
SELECT
    soh.CustomerID,
    soh.SalesOrderID,
    soh.OrderDate                                               AS FechaCompraActual,
    -- Fecha de la compra anterior del mismo cliente
    LAG(soh.OrderDate) OVER (
        PARTITION BY soh.CustomerID
        ORDER BY soh.OrderDate
    )                                                           AS FechaCompraAnterior,
    -- Días entre la compra anterior y la actual
    DATEDIFF(
        DAY,
        LAG(soh.OrderDate) OVER (
            PARTITION BY soh.CustomerID
            ORDER BY soh.OrderDate
        ),
        soh.OrderDate
    )                                                           AS DiasEntreCompras
FROM Sales.SalesOrderHeader soh
ORDER BY soh.CustomerID, soh.OrderDate;

-- =============================================================
-- FIN DEL EXAMEN
-- Temas integrados:
--   Ex1: SELECT INTO (Módulo III)
--   Ex2: UDF escalar con control de errores (Módulo VII)
--   Ex3: Vista que consume UDF (Módulo IV)
--   Ex4: SP con OUTPUT params (Módulo VI)
--   Ex5: Subquery correlacionada en SELECT (Módulo I)
--   Ex6: OVER como alternativa a subquery (Módulo VIII)
--   Ex7: LAG para análisis temporal (Módulo VIII)
-- =============================================================
