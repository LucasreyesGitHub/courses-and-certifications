# Análisis — Práctico 5: Variables

**Módulo:** V — Variables  
**Ejercicios:** 5

---

## Patrones de asignación cubiertos

| Ejercicio | Patrón | Variable |
|-----------|--------|---------|
| 1 | `SELECT @var = MAX(col)` | `@LastDate DATE` |
| 2 | `SELECT @var = col ORDER BY` | `@IdCustomerMax INT` |
| 3 | `SELECT @var = AVG(col)` | `@AVGSickLeaveHours INT` |
| 4 | `SET @var = literal` × 3 | `@Year`, `@Month`, `@Day VARCHAR` |
| 5 | `SELECT @v1 = c1, @v2 = c2` | `@MaritalStatus`, `@Gender NCHAR(1)` |

---

## Análisis por ejercicio

### Ej1 — SELECT @var = MAX(col) → uso en WHERE

El flujo canónico de variables en T-SQL:
```
DECLARE → asignar con SELECT/SET → usar en WHERE/SELECT
```

Aquí el valor de la variable no cambia entre la asignación y el uso → tipo de dato `DATE` es apropiado.

---

### Ej2 — El peligro de ORDER BY con asignación

```sql
SELECT @IdCustomerMax = CustomerID
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
ORDER BY COUNT(SalesOrderID)
```

Cuando una `SELECT @var = col` devuelve múltiples filas con `ORDER BY`, la variable retiene el **último valor** asignado según el orden. Con `ORDER BY COUNT ASC`, el último será el cliente con MÁS órdenes (el que queda al final).

**Forma más clara y robusta:**
```sql
SELECT @IdCustomerMax = CustomerID
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
ORDER BY COUNT(SalesOrderID) DESC  -- primero el mayor

-- O directamente:
SELECT TOP 1 @IdCustomerMax = CustomerID
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
ORDER BY COUNT(SalesOrderID) DESC
```

---

### Ej3 — Promedio como variable intermedia

Separar el cálculo del promedio en una variable permite:
1. Reutilizarlo sin recalcular
2. Inspeccionarlo fácilmente durante el debugging
3. Cambiarlo una sola vez si la lógica evoluciona

---

### Ej4 — Construcción de fecha por concatenación

```sql
SET @Year = '2004'; SET @Month = '02'; SET @Day = '01'
WHERE OrderDate = @Year + '-' + @Month + '-' + @Day
```

**Riesgo:** si `@Month` fuera `'2'` en lugar de `'02'`, la fecha resultante `'2004-2-01'` podría fallar según la configuración regional del servidor.

**Alternativa robusta:**
```sql
WHERE OrderDate = DATEFROMPARTS(CAST(@Year AS INT), CAST(@Month AS INT), CAST(@Day AS INT))
```

---

### Ej5 — Múltiples variables desde una fila

```sql
SELECT @Gender = Gender, @MaritalStatus = MaritalStatus
FROM HumanResources.Employee
WHERE JobTitle = 'Chief Executive Officer'
```

Si la subquery devuelve más de una fila (dos CEOs), el comportamiento es no determinístico. Siempre verificar que el filtro retorna exactamente 1 fila.

---

## Tips de debugging para variables

```sql
-- Verificar el valor asignado antes de usarlo
DECLARE @test INT
SELECT @test = COUNT(*) FROM Sales.SalesOrderHeader
SELECT @test AS Verificacion  -- ← imprimir antes de usar
WHERE ...
```

---

## Equivalente en PostgreSQL

Las variables T-SQL solo existen en bloques `DO $$ ... $$` o funciones en PostgreSQL. Para queries interactivas, usar CTEs:

```sql
-- T-SQL:
DECLARE @LastDate DATE
SELECT @LastDate = MAX(OrderDate) FROM ...
SELECT * FROM ... WHERE OrderDate = @LastDate

-- PostgreSQL equivalente con CTE:
WITH params AS (
    SELECT MAX(order_date) AS last_date FROM sales_order_header
)
SELECT * FROM sales_order_header
WHERE order_date = (SELECT last_date FROM params)
```

---

## Ver también

- [Teoría Módulo V](../../teoria/markdown/05-variables.md)
- [Solución](../resoluciones/practico-05-variables-solucion.sql)
