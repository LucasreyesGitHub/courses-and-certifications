-- =============================================================
-- SQL Analytics II — Instituto CPE, Uruguay
-- Práctico 8 — Window Functions (Tracking Analytics)
-- Solución generada (sin solución oficial disponible)
-- Verificar resultados contra AdventureWorks2008 en SQL Server
-- Base de datos: AdventureWorks2008 (T-SQL / SQL Server)
-- =============================================================

USE AdventureWorks2008;
GO

-- -------------------------------------------------------------
-- Ejercicio 1
-- Porcentaje del precio unitario respecto al total de la orden.
-- Cada línea de detalle muestra su participación en la orden.
-- Patrón: SUM() OVER (PARTITION BY SalesOrderID) para total por orden
-- Patrón: FORMAT para porcentaje
-- -------------------------------------------------------------
SELECT
    sod.SalesOrderID,
    sod.SalesOrderDetailID,
    sod.ProductID,
    sod.OrderQty,
    sod.UnitPrice,
    -- Total de la orden (suma de precios unitarios de todas las líneas)
    SUM(sod.UnitPrice) OVER (PARTITION BY sod.SalesOrderID) AS TotalOrden,
    -- Participación de esta línea en el total
    FORMAT(
        sod.UnitPrice / SUM(sod.UnitPrice) OVER (PARTITION BY sod.SalesOrderID),
        'P2'
    ) AS PorcentajeEnOrden
FROM Sales.SalesOrderDetail sod
ORDER BY sod.SalesOrderID, sod.SalesOrderDetailID;


-- -------------------------------------------------------------
-- Ejercicio 2
-- Producto con mayor venta por subcategoría usando RANK.
-- Obtener el ranking 1 de cada subcategoría.
-- Patrón: RANK() OVER (PARTITION BY subcategoria ORDER BY ventas DESC)
--         con subquery exterior para filtrar Ranking = 1
-- -------------------------------------------------------------
SELECT Categoria, Subcategoria, Producto, TotalVentas
FROM (
    SELECT
        pc.Name                                    AS Categoria,
        ps.Name                                    AS Subcategoria,
        p.Name                                     AS Producto,
        SUM(sod.OrderQty * sod.UnitPrice)          AS TotalVentas,
        RANK() OVER (
            PARTITION BY ps.ProductSubcategoryID
            ORDER BY SUM(sod.OrderQty * sod.UnitPrice) DESC
        ) AS Ranking
    FROM Production.Product p
    JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    GROUP BY pc.Name, ps.Name, ps.ProductSubcategoryID, p.Name
) AS ProductosRankeados
WHERE Ranking = 1
ORDER BY Categoria, Subcategoria;


-- -------------------------------------------------------------
-- Ejercicio 3
-- Participación porcentual de ventas por territorio sobre el total global.
-- Patrón: SUM(SUM(col)) OVER () para el total global
--         (SUM interno = GROUP BY, OVER externo = window sobre todos)
-- -------------------------------------------------------------
SELECT
    st.Name                                 AS Territorio,
    SUM(soh.TotalDue)                       AS VentasTerritorrio,
    SUM(SUM(soh.TotalDue)) OVER ()          AS VentasTotales,
    -- Porcentaje de participación de este territorio
    FORMAT(
        SUM(soh.TotalDue) / SUM(SUM(soh.TotalDue)) OVER (),
        'P2'
    ) AS PorcentajeParticipacion
FROM Sales.SalesTerritory st
JOIN Sales.SalesOrderHeader soh ON st.TerritoryID = soh.TerritoryID
GROUP BY st.TerritoryID, st.Name
ORDER BY VentasTerritorrio DESC;


-- -------------------------------------------------------------
-- Ejercicio 4
-- Variación mes a mes usando LAG.
-- Cada fila muestra ventas del mes actual, del mes anterior
-- y la diferencia (variación absoluta y porcentual).
-- Patrón: LAG(SUM(TotalDue)) OVER (ORDER BY año, mes) aplicado sobre GROUP BY
-- -------------------------------------------------------------
SELECT
    YEAR(OrderDate)                          AS Anio,
    MONTH(OrderDate)                         AS Mes,
    SUM(TotalDue)                            AS VentasMes,
    -- Ventas del mes anterior (NULL para el primer mes)
    LAG(SUM(TotalDue)) OVER (
        ORDER BY YEAR(OrderDate), MONTH(OrderDate)
    )                                        AS VentasMesAnterior,
    -- Variación absoluta
    SUM(TotalDue) - LAG(SUM(TotalDue)) OVER (
        ORDER BY YEAR(OrderDate), MONTH(OrderDate)
    )                                        AS VariacionAbsoluta,
    -- Variación porcentual (evitar división por NULL con NULLIF)
    FORMAT(
        (SUM(TotalDue) - LAG(SUM(TotalDue)) OVER (
            ORDER BY YEAR(OrderDate), MONTH(OrderDate)
        )) / NULLIF(
            LAG(SUM(TotalDue)) OVER (
                ORDER BY YEAR(OrderDate), MONTH(OrderDate)
            ), 0
        ),
        'P2'
    )                                        AS VariacionPorcentual
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Anio, Mes;
