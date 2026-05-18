# Módulo IX — Performance Tips

**Curso:** SQL Analytics II — Instituto CPE, Uruguay  
**Dialecto:** T-SQL · Aplica conceptualmente a PostgreSQL también

---

## 1. Evitar SELECT *

```sql
-- MAL: trae columnas innecesarias, bloquea optimizaciones de índice
SELECT * FROM Sales.SalesOrderHeader

-- BIEN: solo las columnas necesarias
SELECT SalesOrderID, CustomerID, OrderDate, TotalDue
FROM Sales.SalesOrderHeader
```

**Por qué:** `SELECT *` impide que SQL Server use índices cubrientes (covering indexes), aumenta el I/O y el consumo de red.

---

## 2. Preferir JOIN sobre subquery cuando es posible

```sql
-- Subquery (puede ser menos eficiente)
SELECT ProductID, Name
FROM Production.Product
WHERE ProductID IN (
    SELECT ProductID FROM Sales.SalesOrderDetail
)

-- JOIN equivalente (generalmente mejor plan)
SELECT DISTINCT p.ProductID, p.Name
FROM Production.Product p
JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
```

> El optimizador suele generar el mismo plan, pero el JOIN es más explícito sobre la intención y más fácil de extender.

---

## 3. EXISTS vs IN / NOT IN

```sql
-- NOT IN falla con NULLs: si la subquery devuelve un NULL, el resultado es vacío
WHERE CustomerID NOT IN (SELECT CustomerID FROM Tabla)  -- PELIGROSO con NULLs

-- NOT EXISTS: maneja NULLs correctamente, generalmente más eficiente
WHERE NOT EXISTS (
    SELECT 1 FROM Tabla WHERE Tabla.CustomerID = soh.CustomerID
)
```

**Regla:** Para sets grandes, `EXISTS` se detiene en el primer match. `IN` evalúa todo el conjunto primero.

---

## 4. Igualdad (=) vs LIKE sin comodín inicial

```sql
-- MAL: LIKE con % al inicio no puede usar índices
WHERE LastName LIKE '%Smith'

-- BIEN: = o LIKE sin % al inicio usan índices
WHERE LastName = 'Smith'
WHERE LastName LIKE 'Smi%'  -- puede usar índice de árbol B
```

---

## 5. Filtrar con WHERE lo antes posible

```sql
-- MAL: agregar primero, luego filtrar (mucho dato procesado)
SELECT CustomerID, COUNT(*) AS Total
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
HAVING CustomerID = 12001

-- BIEN: filtrar antes de agregar
SELECT CustomerID, COUNT(*) AS Total
FROM Sales.SalesOrderHeader
WHERE CustomerID = 12001
GROUP BY CustomerID
```

---

## 6. Evitar búsquedas negativas (≠, NOT IN, NOT LIKE)

Las comparaciones negativas (`<>`, `!=`, `NOT IN`, `NOT LIKE`) generalmente no pueden aprovechar índices.

```sql
-- Puede generar full scan
WHERE Status <> 'Cancelled'

-- Alternativa: reformular como positiva si es posible
WHERE Status IN ('Active', 'Pending', 'Completed')
```

---

## 7. Evitar funciones sobre columnas indexadas en WHERE

```sql
-- MAL: la función impide usar el índice sobre OrderDate
WHERE YEAR(OrderDate) = 2004

-- BIEN: rango explícito usa el índice
WHERE OrderDate >= '2004-01-01' AND OrderDate < '2005-01-01'
```

> Esto aplica a cualquier función: `UPPER(Name) = 'SMITH'` también bloquea el índice.

---

## 8. Programar queries costosas fuera de hora pico

Para reports o agregaciones sobre toda la base de datos:
- Usar SQL Server Agent Jobs programados en horario de baja carga
- Materializar resultados en tablas de staging o data marts
- Usar `WITH (NOLOCK)` en read-only reports no críticos (asume lecturas sucias)

---

## 9. Usar TOP para exploración

```sql
-- Durante desarrollo: limitar siempre el resultado
SELECT TOP 100 *
FROM Sales.SalesOrderHeader
ORDER BY OrderDate DESC
```

---

## 10. Indices: índice cubriente

Un índice cubriente incluye todas las columnas que la query necesita:

```sql
-- Si frecuentemente se hace:
SELECT CustomerID, TotalDue FROM Sales.SalesOrderHeader WHERE OrderDate = '2004-01-01'

-- Índice cubriente: OrderDate como key, CustomerID y TotalDue como INCLUDE
CREATE INDEX idx_soh_orderdate ON Sales.SalesOrderHeader (OrderDate)
INCLUDE (CustomerID, TotalDue)
```

---

## Resumen rápido

| Práctica | Impacto |
|---------|---------|
| Evitar `SELECT *` | Alto |
| `WHERE` antes de `GROUP BY` | Alto |
| Rango de fecha explícito vs `YEAR()` | Alto |
| `EXISTS` vs `NOT IN` con NULLs | Crítico (corrección) |
| `JOIN` vs subquery correlacionada | Medio |
| `LIKE 'val%'` vs `LIKE '%val'` | Alto |
| `DISTINCT` solo cuando necesario | Medio |

---

## Equivalencias en PostgreSQL

Los principios son idénticos. PostgreSQL adiciona:
- `EXPLAIN ANALYZE` para ver el plan de ejecución real
- `pg_stat_user_tables` para estadísticas de acceso a tablas
- Índices parciales: `CREATE INDEX ... WHERE status = 'Active'`

---

## Ver también

- [Subqueries — Módulo I](./01-subqueries.md)
- [Window Functions — Módulo VIII](./08-window-functions.md)
- [T-SQL vs PostgreSQL Cheatsheet](../../cheatsheets/t-sql-vs-postgresql.md)
