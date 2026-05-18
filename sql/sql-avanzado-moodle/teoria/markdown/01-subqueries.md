# Módulo I — Subqueries (Subconsultas)

**Curso:** SQL Analytics II — Instituto CPE, Uruguay  
**Dialecto:** T-SQL · Ver equivalencias en [T-SQL vs PostgreSQL](../../cheatsheets/t-sql-vs-postgresql.md)

---

## ¿Qué es una subquery?

Una subquery es una consulta anidada dentro de otra. Puede aparecer en:

- `WHERE` — para filtrar filas
- `SELECT` — como valor calculado por fila (scalar subquery)
- `FROM` — como tabla derivada

---

## 1. Subquery con `IN` / `NOT IN`

```sql
-- Productos de la categoría 'Components'
SELECT ProductID, Name
FROM Production.Product
WHERE ProductSubcategoryID IN (
    SELECT ProductSubcategoryID
    FROM Production.ProductSubcategory
    WHERE ProductCategoryID IN (
        SELECT ProductCategoryID
        FROM Production.ProductCategory
        WHERE Name = 'Components'
    )
)
```

> Permite anidar múltiples niveles. Cada nivel filtra el nivel superior.

**Cuándo usar:** el conjunto de valores a comparar viene de otra tabla.  
**Cuidado:** `NOT IN` devuelve vacío si la subquery retorna algún `NULL`. Preferir `NOT EXISTS`.

**PostgreSQL:** sintaxis idéntica.

---

## 2. Subquery con `ALL` / `ANY` / `SOME`

```sql
-- Empleados con salario mayor que TODOS los de otro departamento
WHERE Salary > ALL (SELECT Salary FROM ...)

-- Empleados con salario mayor que AL MENOS UNO
WHERE Salary > ANY (SELECT Salary FROM ...)
-- SOME es sinónimo de ANY en T-SQL y PostgreSQL
```

| Operador | Equivale a |
|----------|-----------|
| `= ANY` | `IN` |
| `<> ALL` | `NOT IN` |
| `> ALL` | mayor que el MAX |
| `> ANY` | mayor que el MIN |

---

## 3. Subquery con `EXISTS` / `NOT EXISTS`

```sql
-- Clientes que realizaron más de 20 compras
SELECT C.CustomerID, FirstName, LastName
FROM Sales.Customer C
INNER JOIN Person.Person P ON C.PersonID = P.BusinessEntityID
WHERE EXISTS (
    SELECT 1
    FROM Sales.SalesOrderHeader SH
    WHERE SH.CustomerID = C.CustomerID
    GROUP BY CustomerID
    HAVING COUNT(SalesOrderID) > 20
)
```

> `EXISTS` retorna `TRUE` si la subquery devuelve al menos una fila.  
> Usar `SELECT 1` (no `SELECT *`) en el interior: más claro y sin overhead.

**EXISTS vs IN:**
- `EXISTS` se detiene en el primer match → más eficiente en tablas grandes
- `NOT EXISTS` maneja `NULL` correctamente; `NOT IN` no

**PostgreSQL:** sintaxis idéntica.

---

## 4. Scalar subquery en `SELECT`

Una subquery que devuelve exactamente **un valor** por fila del resultado exterior:

```sql
-- Para cada cliente en 2003: su conteo y el total del año
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
```

> Esta subquery es **no correlacionada**: se ejecuta una sola vez y devuelve el mismo valor para todas las filas.

---

## 5. Subquery correlacionada

La subquery referencia una columna de la query exterior. Se ejecuta **por cada fila** de la query exterior:

```sql
-- Empleados con sick leave menor al promedio
SELECT p.BusinessEntityID, p.FirstName, p.LastName
FROM Person.Person AS p
WHERE EXISTS (
    SELECT hre.BusinessEntityID
    FROM HumanResources.Employee hre
    WHERE SickLeaveHours < (
        SELECT AVG(SickLeaveHours)
        FROM HumanResources.Employee
    )
    AND p.BusinessEntityID = hre.BusinessEntityID  -- ← correlación
)
ORDER BY p.BusinessEntityID
```

---

## Resumen de patrones

| Patrón | Uso | Precaución |
|--------|-----|-----------|
| `IN (subquery)` | Filtrar por conjunto de valores | `NOT IN` falla con NULLs |
| `EXISTS (subquery)` | Verificar existencia | Preferible a `IN` en tablas grandes |
| `> ALL (subquery)` | Comparar contra todos | La subquery debe retornar un conjunto |
| Scalar en `SELECT` | Valor calculado por fila | Debe retornar exactamente 1 fila y 1 columna |
| Correlacionada | Depende de la fila exterior | Puede ser lenta (N ejecuciones) |

---

## Tips y optimizaciones

- Reemplazar scalar subquery en `SELECT` por `OVER()` cuando es posible → mejor rendimiento
- `EXISTS` > `IN` para tablas grandes o cuando hay riesgo de `NULL`
- Anidar más de 3 niveles de `IN` suele ser señal de que hace falta un `JOIN`
- En T-SQL: `YEAR(OrderDate)` impide uso de índices; preferir rangos de fecha explícitos en producción

---

## Ver también

- [Práctico 1 — Enunciado](../../practicos/enunciados/practico-01-subqueries.pdf)
- [Práctico 1 — Solución](../../practicos/resoluciones/practico-01-subqueries-solucion.sql)
- [Práctico 1 — Análisis](../../practicos/analisis/practico-01-analisis.md)
