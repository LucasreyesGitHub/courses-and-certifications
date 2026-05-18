# Análisis — Práctico 7: UDFs

**Módulo:** VII — User Defined Functions  
**Ejercicios:** 5  
**Solución:** generada (sin solución oficial)

---

## UDFs desarrolladas

| Ejercicio | Nombre | Tipo | Retorna |
|-----------|--------|------|---------|
| 1 | `Sales.TotalCustomerByYear` | Scalar | `MONEY` |
| 2 | `HumanResources.AntiguedadEmpleado` | Scalar | `INT` |
| 3 | `Sales.OrdenesEntreFechas` | Scalar | `INT` |
| 4 | `Sales.VentasPorTerritorio` | TVF (inline) | `TABLE` |
| 5 | `Production.Bottom5ProductosPorAnio` | TVF (inline) | `TABLE` |

---

## Análisis por ejercicio

### Ej1 y Ej2 — Scalar UDFs sobre datos de sesión

Ambas funciones siguen el mismo patrón:
```
DECLARE @result TIPO → SELECT @result = valor → RETURN @result
```

**Rendimiento en SELECT masivo:** las scalar UDFs se ejecutan **una vez por fila**. En una query sobre 100,000 filas, la función se ejecuta 100,000 veces.

**SQL Server 2019+:** Scalar UDF Inlining puede convertirlas automáticamente en expresiones inline. Para versiones anteriores, reemplazar por:
```sql
-- En lugar de SELECT dbo.AntiguedadEmpleado(id) FROM ...
SELECT DATEDIFF(YEAR, e.HireDate, GETDATE()) AS Antiguedad FROM Employee e
```

---

### Ej3 — Scalar con rango de fechas

```sql
CREATE FUNCTION Sales.OrdenesEntreFechas (
    @CustomerID INT, @FechaInicio DATE, @FechaFin DATE
) RETURNS INT AS BEGIN
    DECLARE @Total INT
    SELECT @Total = COUNT(SalesOrderID) FROM ...
    WHERE CustomerID = @CustomerID AND OrderDate BETWEEN @FechaInicio AND @FechaFin
    RETURN @Total
END
```

**Uso típico:**
```sql
SELECT CustomerID, Sales.OrdenesEntreFechas(CustomerID, '2004-01-01', '2004-12-31')
FROM Sales.Customer
```

Cada llamada hace un COUNT sobre `SalesOrderHeader`. En tablas grandes, un índice en `(CustomerID, OrderDate)` es crítico.

---

### Ej4 — TVF inline: VentasPorTerritorio

```sql
CREATE FUNCTION Sales.VentasPorTerritorio (@Year INT) RETURNS TABLE AS
RETURN (SELECT st.TerritoryID, st.Name, SUM(soh.TotalDue) AS TotalVentas ...)
```

**Ventaja vs vista:** la vista no acepta parámetros — la TVF sí. Permite filtrar por año dinámicamente.

**Ventaja vs SP:** la TVF puede usarse en `JOIN`:
```sql
SELECT t.Territorio, t.TotalVentas, r.CountryRegionCode
FROM Sales.VentasPorTerritorio(2004) t
JOIN Sales.SalesTerritory st ON t.TerritoryID = st.TerritoryID
```

---

### Ej5 — TVF con TOP dentro de RETURNS TABLE

```sql
RETURN (
    SELECT TOP 5 p.ProductID, p.Name, SUM(...) AS TotalVentas
    FROM ...
    GROUP BY p.ProductID, p.Name
    ORDER BY TotalVentas ASC  -- bottom 5
)
```

**Cuidado:** `TOP` sin `ORDER BY` no garantiza cuáles 5 filas devuelve. Siempre acompañar `TOP` con `ORDER BY`.

---

## Scalar vs TVF — comparación práctica

| | Scalar | TVF inline |
|--|--------|-----------|
| Se usa en | `SELECT list`, `WHERE` | `FROM`, `JOIN` |
| Retorna | 1 valor | múltiples filas/columnas |
| Puede filtrar filas | No | Sí (en la consulta exterior) |
| Riesgo de rendimiento | Alto (N ejecuciones) | Bajo (optimizado como vista) |
| Permite `TOP`, `ORDER BY` | Solo dentro de `BEGIN/END` | En el `RETURN (SELECT ...)` |

---

## Optimizaciones detectadas

1. Para `AntiguedadEmpleado` en queries masivas: mejor expresión inline que UDF
2. Para `OrdenesEntreFechas`: índice compuesto en `(CustomerID, OrderDate)` en `SalesOrderHeader`
3. Para TVFs: SQL Server puede combinar el plan de la TVF con el plan de la query exterior (predicate pushdown)

---

## Ver también

- [Teoría Módulo VII](../../teoria/markdown/07-udfs.md)
- [Solución generada](../resoluciones/practico-07-udfs-solucion.sql)
