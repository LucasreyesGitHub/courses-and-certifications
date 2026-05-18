# Módulo V — Variables

**Curso:** SQL Analytics II — Instituto CPE, Uruguay  
**Dialecto:** T-SQL · Ver equivalencias en [T-SQL vs PostgreSQL](../../cheatsheets/t-sql-vs-postgresql.md)

---

## Declaración y asignación

```sql
-- Declarar
DECLARE @NombreVariable TipoDato

-- Asignar con SET (un valor)
SET @Variable = valor

-- Asignar con SELECT (valor de una consulta)
SELECT @Variable = columna
FROM tabla
WHERE condicion

-- Múltiples variables en un SELECT
SELECT @Var1 = col1, @Var2 = col2
FROM tabla
WHERE condicion
```

> `SET` es más explícito y preferible para asignaciones simples.  
> `SELECT` permite asignar múltiples variables a la vez desde una consulta.

---

## Alcance (scope)

Las variables en T-SQL tienen scope de **batch** (hasta el `GO` o el fin del script). No existen variables globales de usuario.

```sql
DECLARE @Fecha DATE
SELECT @Fecha = MAX(OrderDate) FROM Sales.SalesOrderHeader
-- @Fecha es usable hasta el fin de este batch

GO  -- ← aquí muere @Fecha
```

---

## Ejemplos del práctico

### Variable para última fecha de orden

```sql
DECLARE @LastDate DATE

SELECT @LastDate = MAX(OrderDate)
FROM Sales.SalesOrderHeader

SELECT SalesOrderID, CustomerID, TotalDue
FROM Sales.SalesOrderHeader
WHERE OrderDate = @LastDate
ORDER BY TotalDue DESC
```

### Variable para ID del mejor cliente

```sql
DECLARE @IdCustomerMax INT

SELECT @IdCustomerMax = CustomerID
FROM Sales.SalesOrderHeader
GROUP BY CustomerID
ORDER BY COUNT(SalesOrderID)  -- el último valor asignado será el MAX

SELECT p.ProductID, p.Name, SUM(sod.OrderQty) AS QTY
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE soh.CustomerID = @IdCustomerMax
GROUP BY p.ProductID, p.Name
ORDER BY QTY DESC
```

> Cuando `SELECT @var = col ... ORDER BY` asigna múltiples filas, la variable retiene el **último valor** en el orden. Para el máximo, es mejor `SELECT @var = MAX(col)`.

### Construcción dinámica de fecha

```sql
DECLARE @Year  VARCHAR(4)
DECLARE @Month VARCHAR(2)
DECLARE @Day   VARCHAR(2)

SET @Year  = '2004'
SET @Month = '02'
SET @Day   = '01'

SELECT SalesOrderID, CustomerID, OrderDate, TotalDue
FROM Sales.SalesOrderHeader
WHERE OrderDate = @Year + '-' + @Month + '-' + @Day
```

### Dos variables desde el CEO

```sql
DECLARE @MaritalStatus NCHAR(1)
DECLARE @Gender        NCHAR(1)

SELECT @Gender = Gender, @MaritalStatus = MaritalStatus
FROM HumanResources.Employee
WHERE JobTitle = 'Chief Executive Officer'

SELECT FirstName, LastName
FROM HumanResources.Employee e
JOIN Person.Person p ON e.BusinessEntityID = p.BusinessEntityID
WHERE e.MaritalStatus <> @MaritalStatus AND e.Gender <> @Gender
```

---

## Tipos de dato más usados

| Tipo T-SQL | Descripción | PostgreSQL equiv. |
|-----------|-------------|-------------------|
| `INT` | Entero 32-bit | `INTEGER` |
| `BIGINT` | Entero 64-bit | `BIGINT` |
| `MONEY` | Monetario 4 decimales | `NUMERIC(19,4)` |
| `FLOAT` | Punto flotante | `DOUBLE PRECISION` |
| `DATE` | Fecha sin hora | `DATE` |
| `DATETIME` | Fecha + hora | `TIMESTAMP` |
| `VARCHAR(n)` | String variable ASCII | `VARCHAR(n)` |
| `NVARCHAR(n)` | String variable Unicode | `VARCHAR(n)` |
| `NCHAR(1)` | Char fijo Unicode | `CHAR(1)` |

---

## Equivalente en PostgreSQL

```sql
-- PostgreSQL usa DO blocks o funciones para variables
DO $$
DECLARE
    last_date DATE;
BEGIN
    SELECT MAX(order_date) INTO last_date FROM sales_order_header;
    -- usar last_date aquí
END $$;

-- Para queries interactivas, usar CTEs en lugar de variables:
WITH ultima_fecha AS (
    SELECT MAX(order_date) AS fecha FROM sales_order_header
)
SELECT * FROM sales_order_header
WHERE order_date = (SELECT fecha FROM ultima_fecha)
```

> En PostgreSQL las variables solo existen dentro de bloques `DO $$...$$` o funciones. En consultas normales se reemplazan con CTEs o subqueries.

---

## Tips

- Inicializar siempre las variables antes de usarlas: sin `SET`/`SELECT`, el valor es `NULL`
- Preferir `SELECT @var = MAX(col)` sobre `SELECT @var = col ORDER BY col DESC` para el máximo: más claro e inequívoco
- En SPs, declarar todas las variables al inicio del body (convención de legibilidad)
- `DECLARE` y `SET` no son statement-level: van en el mismo batch que las queries que los usan

---

## Ver también

- [Práctico 5 — Enunciado](../../practicos/enunciados/practico-05-variables.pdf)
- [Práctico 5 — Solución](../../practicos/resoluciones/practico-05-variables-solucion.sql)
- [Módulo VI — Stored Procedures](./06-stored-procedures.md)
