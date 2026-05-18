# Módulo VII — UDFs (User Defined Functions)

**Curso:** SQL Analytics II — Instituto CPE, Uruguay  
**Dialecto:** T-SQL · Ver equivalencias en [T-SQL vs PostgreSQL](../../cheatsheets/t-sql-vs-postgresql.md)

---

## ¿Qué es una UDF?

Una función definida por el usuario (UDF) encapsula lógica SQL reutilizable y devuelve un valor o una tabla. A diferencia de los SPs, las UDFs pueden usarse dentro de `SELECT`, `WHERE` y `FROM`.

```sql
CREATE FUNCTION esquema.NombreFuncion (@param TIPO)
RETURNS TipoRetorno
AS
BEGIN
    -- lógica
    RETURN valor
END

ALTER FUNCTION esquema.NombreFuncion (...)  -- modificar
DROP FUNCTION esquema.NombreFuncion         -- eliminar
```

---

## Tipo 1 — Scalar Function (valor escalar)

Devuelve un único valor. Se usa como expresión en `SELECT`, `WHERE`, `SET`.

```sql
-- Función de multiplicación (ejemplo del módulo)
CREATE FUNCTION dbo.Multiplicacion (@num_1 INT, @num_2 FLOAT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @Resultado FLOAT
    SET @Resultado = @num_1 * @num_2
    RETURN @Resultado
END

-- Uso
SELECT dbo.Multiplicacion(5, 3.14)
```

### Scalar UDF con control de NULL / división por cero

```sql
-- UDF del examen: variación porcentual con control de base cero
CREATE FUNCTION dbo.Variacion_Porc (@ValorA MONEY, @ValorB MONEY)
RETURNS VARCHAR(20)
AS
BEGIN
    DECLARE @Resultado VARCHAR(20)
    IF @ValorB = 0
        SET @Resultado = 'N/A'
    ELSE
        SET @Resultado = FORMAT((@ValorA / @ValorB) - 1, 'P2')
    RETURN @Resultado
END

-- Uso en SELECT
SELECT p.Name,
       p.ListPrice,
       p.StandardCost,
       dbo.Variacion_Porc(p.ListPrice, p.StandardCost) AS VariacionPct
FROM Production.Product p
```

### Scalar UDF de antigüedad de empleado

```sql
CREATE FUNCTION HumanResources.AntiguedadEmpleado (@EmployeeID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Antiguedad INT
    SELECT @Antiguedad = DATEDIFF(YEAR, HireDate, GETDATE())
    FROM HumanResources.Employee
    WHERE BusinessEntityID = @EmployeeID
    RETURN @Antiguedad
END

SELECT BusinessEntityID,
       HumanResources.AntiguedadEmpleado(BusinessEntityID) AS AnosEnEmpresa
FROM HumanResources.Employee
```

---

## Tipo 2 — Table-Valued Function (TVF)

Devuelve una tabla. Se usa en `FROM`, como si fuera una tabla o vista parametrizada.

### Inline TVF (RETURNS TABLE)

```sql
CREATE FUNCTION Sales.Top15Customers (@Year INT)
RETURNS TABLE
AS
RETURN (
    SELECT TOP 15
           p.FirstName,
           p.LastName,
           SUM(soh.TotalDue) AS TotalSales
    FROM Person.Person AS p
    JOIN Sales.Customer AS c ON p.BusinessEntityID = c.CustomerID
    LEFT JOIN Sales.SalesOrderHeader AS soh ON c.CustomerID = soh.CustomerID
    WHERE YEAR(soh.OrderDate) = @Year
    GROUP BY p.FirstName, p.LastName
    ORDER BY TotalSales DESC
)

-- Uso: TVF en FROM
SELECT * FROM Sales.Top15Customers(2004)
```

> Inline TVF: sin `BEGIN/END`, sin `DECLARE`, solo `RETURN (SELECT ...)`.  
> Es más eficiente que Multi-Statement TVF: SQL Server puede optimizarla como una vista.

### TVF de territorio de ventas por año

```sql
CREATE FUNCTION Sales.VentasPorTerritorio (@Year INT)
RETURNS TABLE
AS
RETURN (
    SELECT st.TerritoryID,
           st.Name AS Territorio,
           SUM(soh.TotalDue) AS TotalVentas
    FROM Sales.SalesTerritory st
    JOIN Sales.SalesOrderHeader soh ON st.TerritoryID = soh.TerritoryID
    WHERE YEAR(soh.OrderDate) = @Year
    GROUP BY st.TerritoryID, st.Name
)

SELECT * FROM Sales.VentasPorTerritorio(2004)
ORDER BY TotalVentas DESC
```

### TVF de bottom 5 productos por año

```sql
CREATE FUNCTION Production.Bottom5ProductosPorAnio (@Year INT)
RETURNS TABLE
AS
RETURN (
    SELECT TOP 5
           p.ProductID,
           p.Name,
           SUM(sod.OrderQty * sod.UnitPrice) AS TotalVentas
    FROM Production.Product p
    JOIN Sales.SalesOrderDetail sod ON p.ProductID = sod.ProductID
    JOIN Sales.SalesOrderHeader soh ON sod.SalesOrderID = soh.SalesOrderID
    WHERE YEAR(soh.OrderDate) = @Year
    GROUP BY p.ProductID, p.Name
    ORDER BY TotalVentas ASC
)
```

---

## Scalar vs TVF — cuándo usar cada una

| | Scalar | TVF |
|--|--------|-----|
| Devuelve | Un valor | Una tabla |
| Se usa en | `SELECT`, `WHERE`, `SET` | `FROM`, `JOIN` |
| Puede filtrar filas | No | Sí |
| Parámetros | Sí | Sí |
| Reemplaza a | Expresión | Vista parametrizada |
| Rendimiento | A veces lento (llamada por fila) | Mejor (inline TVF) |

---

## Limitaciones de UDFs en T-SQL

- Las UDFs no pueden tener efectos secundarios: no hacen `INSERT`, `UPDATE`, `DELETE`, ni modifican objetos
- No pueden usar tablas temporales `#local` (sí variables de tabla `@tabla`)
- Las scalar UDFs pueden ser lentas en grandes datasets: se ejecutan fila por fila
- En SQL Server 2019+ existe "Scalar UDF Inlining" para mitigar esto

---

## Equivalente en PostgreSQL

```sql
-- Scalar function
CREATE OR REPLACE FUNCTION variacion_porc(valor_a NUMERIC, valor_b NUMERIC)
RETURNS TEXT AS $$
BEGIN
    IF valor_b = 0 THEN
        RETURN 'N/A';
    END IF;
    RETURN TO_CHAR((valor_a / valor_b) - 1, 'FM999.99%');
END;
$$ LANGUAGE plpgsql;

-- TVF (setof / returns table)
CREATE OR REPLACE FUNCTION top_customers(p_year INT)
RETURNS TABLE(first_name TEXT, last_name TEXT, total_sales NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT p.first_name, p.last_name, SUM(soh.total_due)
    FROM person p
    JOIN customer c ON p.id = c.person_id
    JOIN sales_order_header soh ON c.id = soh.customer_id
    WHERE EXTRACT(YEAR FROM soh.order_date) = p_year
    GROUP BY p.first_name, p.last_name
    ORDER BY 3 DESC
    LIMIT 15;
END;
$$ LANGUAGE plpgsql;

-- Uso: igual que T-SQL
SELECT * FROM top_customers(2004);
```

---

## Tips

- Para variación porcentual: siempre controlar división por cero antes de calcular
- TVFs inline son más performantes que Multi-Statement TVFs: preferir siempre que sea posible
- Nombrar UDFs con verbo descriptivo o sustantivo del resultado: `GetAntiguedad`, `VentasPorTerritorio`
- Las scalar UDFs se llaman siempre con el schema: `dbo.MiFuncion(...)`, no `MiFuncion(...)`

---

## Ver también

- [Práctico 7 — Enunciado](../../practicos/enunciados/practico-07-udfs.pdf)
- [Práctico 7 — Solución](../../practicos/resoluciones/practico-07-udfs-solucion.sql)
- [Módulo VI — Stored Procedures](./06-stored-procedures.md)
- [Módulo VIII — Window Functions](./08-window-functions.md)
