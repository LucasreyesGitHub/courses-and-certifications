# Módulo VIII — Window Functions (Funciones de Ventana)

**Curso:** SQL Analytics II — Instituto CPE, Uruguay  
**Dialecto:** T-SQL · Ver equivalencias en [T-SQL vs PostgreSQL](../../cheatsheets/t-sql-vs-postgresql.md)

---

## ¿Qué es una window function?

Una window function realiza un cálculo sobre un conjunto de filas relacionadas con la fila actual, **sin colapsarlas** (sin `GROUP BY`). Cada fila mantiene su identidad en el resultado.

```sql
FUNCION() OVER (
    [PARTITION BY columna]   -- división en grupos (opcional)
    [ORDER BY columna]       -- orden dentro del grupo
    [ROWS/RANGE BETWEEN ...] -- marco de filas (opcional)
)
```

---

## La cláusula OVER

```sql
-- Sin PARTITION: ventana = toda la tabla
SUM(TotalDue) OVER () AS TotalGlobal

-- Con PARTITION: ventana = grupo por CustomerID y Año
SUM(TotalDue) OVER (
    PARTITION BY CustomerID, YEAR(OrderDate)
) AS TotalAnualCliente

-- Con ORDER BY: ventana acumulativa
SUM(TotalDue) OVER (
    PARTITION BY CustomerID
    ORDER BY OrderDate
) AS TotalAcumuladoCliente
```

---

## Funciones de ranking

### ROW_NUMBER

Número único por fila, sin empates:

```sql
SELECT SalesOrderID, SalesOrderDetailID,
       ROW_NUMBER() OVER (
           PARTITION BY SalesOrderID
           ORDER BY SalesOrderDetailID
       ) AS NumeroFila
FROM Sales.SalesOrderDetail
```

### RANK

Número de posición con gaps ante empates (1, 1, 3, 4…):

```sql
SELECT ProductID,
       SUM(OrderQty * UnitPrice) AS TotalVentas,
       RANK() OVER (ORDER BY SUM(OrderQty * UnitPrice) DESC) AS Ranking
FROM Sales.SalesOrderDetail
GROUP BY ProductID
```

### DENSE_RANK

Igual que RANK pero sin gaps (1, 1, 2, 3…):

```sql
DENSE_RANK() OVER (ORDER BY SalesOrderID, OrderQty DESC)
```

### NTILE(n)

Divide las filas en n grupos de igual tamaño:

```sql
-- Cuartiles de ventas por representante
NTILE(4) OVER (ORDER BY SalesYTD DESC) AS Quartile
```

| n=4 | Grupo | Descripción |
|-----|-------|-------------|
| 1 | Q1 | Top 25% |
| 2 | Q2 | 25%–50% |
| 3 | Q3 | 50%–75% |
| 4 | Q4 | Bottom 25% |

---

## Funciones de valor

### LAG — valor de la fila anterior

```sql
-- Ventas del mes anterior para comparar
SELECT YEAR(OrderDate)  AS Anio,
       MONTH(OrderDate) AS Mes,
       SUM(TotalDue)    AS VentasMes,
       LAG(SUM(TotalDue)) OVER (
           ORDER BY YEAR(OrderDate), MONTH(OrderDate)
       ) AS VentasMesAnterior,
       SUM(TotalDue) - LAG(SUM(TotalDue)) OVER (
           ORDER BY YEAR(OrderDate), MONTH(OrderDate)
       ) AS Variacion
FROM Sales.SalesOrderHeader
GROUP BY YEAR(OrderDate), MONTH(OrderDate)
ORDER BY Anio, Mes
```

### LEAD — valor de la fila siguiente

```sql
LEAD(SalesOrderDetailID) OVER (
    PARTITION BY SalesOrderID
    ORDER BY SalesOrderDetailID
) AS SiguienteDetalle
```

### FIRST_VALUE / LAST_VALUE

```sql
-- Primer precio en cada orden
FIRST_VALUE(UnitPrice) OVER (
    PARTITION BY SalesOrderID
    ORDER BY SalesOrderDetailID
) AS PrimerPrecio

-- Último precio — necesita ROWS BETWEEN para evitar el default
LAST_VALUE(UnitPrice) OVER (
    PARTITION BY SalesOrderID
    ORDER BY SalesOrderDetailID
    ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
) AS UltimoPrecio
```

---

## Patrón: porcentaje dentro de un grupo

```sql
-- Participación de cada territorio en ventas totales
SELECT st.Name AS Territorio,
       SUM(soh.TotalDue) AS VentasTerritorrio,
       SUM(SUM(soh.TotalDue)) OVER () AS VentasTotales,
       FORMAT(
           SUM(soh.TotalDue) / SUM(SUM(soh.TotalDue)) OVER (),
           'P2'
       ) AS Porcentaje
FROM Sales.SalesTerritory st
JOIN Sales.SalesOrderHeader soh ON st.TerritoryID = soh.TerritoryID
GROUP BY st.TerritoryID, st.Name
ORDER BY VentasTerritorrio DESC
```

> `SUM(SUM(col)) OVER ()`: el `SUM` interno es el agregado por grupo, el externo es la window function sobre todos los grupos.

---

## Patrón: ranking top por subcategoría

```sql
-- Producto con más ventas por subcategoría
SELECT * FROM (
    SELECT pc.Name AS Categoria,
           ps.Name AS Subcategoria,
           p.Name  AS Producto,
           SUM(sod.OrderQty * sod.UnitPrice) AS TotalVentas,
           RANK() OVER (
               PARTITION BY ps.ProductSubcategoryID
               ORDER BY SUM(sod.OrderQty * sod.UnitPrice) DESC
           ) AS Ranking
    FROM Production.Product p
    JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    GROUP BY pc.Name, ps.Name, ps.ProductSubcategoryID, p.Name
) AS Ranked
WHERE Ranking = 1
```

---

## Patrón: días entre compras consecutivas (LAG con DATEDIFF)

```sql
-- Días entre la compra actual y la anterior del mismo cliente
SELECT soh.CustomerID,
       soh.SalesOrderID,
       soh.OrderDate,
       LAG(soh.OrderDate) OVER (
           PARTITION BY soh.CustomerID
           ORDER BY soh.OrderDate
       ) AS CompraAnterior,
       DATEDIFF(DAY,
           LAG(soh.OrderDate) OVER (
               PARTITION BY soh.CustomerID
               ORDER BY soh.OrderDate
           ),
           soh.OrderDate
       ) AS DiasEntreCompras
FROM Sales.SalesOrderHeader soh
ORDER BY soh.CustomerID, soh.OrderDate
```

---

## Window vs GROUP BY

| | `GROUP BY` | `OVER()` |
|--|-----------|---------|
| Colapsa filas | Sí | No |
| Mantiene detalle | No | Sí |
| Permite mezclar agregado y detalle | No | Sí |
| Necesita subquery para filtrar el rango | Sí | No (WHERE en outer) |

---

## Equivalente en PostgreSQL

La sintaxis de `OVER()` es idéntica en PostgreSQL. Diferencias menores:

```sql
-- T-SQL FORMAT para porcentaje
FORMAT(valor, 'P2')

-- PostgreSQL equivalente
TO_CHAR(valor * 100, 'FM999.99') || '%'
-- o ROUND(valor * 100, 2) || '%'
```

---

## Tips

- `RANK()` para rankings con empates visibles (ej: competencias); `ROW_NUMBER()` para paginación
- `LAST_VALUE` siempre necesita `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING` — el default es hasta la fila actual, no el final
- `LAG(col, 2)` para 2 filas atrás; `LAG(col, 1, 0)` con valor por defecto cuando es NULL
- Las window functions se evalúan después del `WHERE` y `GROUP BY`, antes del `ORDER BY` final

---

## Ver también

- [Práctico 8 — Enunciado](../../practicos/enunciados/practico-08-window-functions.pdf)
- [Práctico 8 — Solución](../../practicos/resoluciones/practico-08-window-functions-solucion.sql)
- [Window Functions Cheatsheet](../../cheatsheets/window-functions-cheatsheet.md)
