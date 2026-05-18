# Módulo VI — Stored Procedures (Procedimientos Almacenados)

**Curso:** SQL Analytics II — Instituto CPE, Uruguay  
**Dialecto:** T-SQL · Ver equivalencias en [T-SQL vs PostgreSQL](../../cheatsheets/t-sql-vs-postgresql.md)

---

## ¿Qué es un Stored Procedure?

Un SP es una rutina SQL almacenada en la base de datos con nombre. Puede recibir parámetros, ejecutar lógica compleja y devolver valores.

```sql
-- Ciclo de vida completo
CREATE PROCEDURE esquema.NombreSP @param1 TIPO, @param2 TIPO OUTPUT
AS
SET NOCOUNT ON;
-- lógica aquí

ALTER PROCEDURE esquema.NombreSP @param1 TIPO  -- modificar
AS
-- nueva lógica

DROP PROCEDURE esquema.NombreSP               -- eliminar
```

---

## Parámetros INPUT

```sql
CREATE PROCEDURE HumanResources.HireInDate @Fecha DATE
AS
SELECT Title, FirstName, LastName, JobTitle
FROM HumanResources.Employee E
INNER JOIN Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
WHERE HireDate = @Fecha

-- Ejecución
EXEC HumanResources.HireInDate '1999-01-07'
```

---

## Parámetros OUTPUT

Devuelven un valor calculado dentro del SP a la sesión que lo llama:

```sql
CREATE PROCEDURE Sales.TotalOrders
    @CustomerID  INT,
    @TotalOrders INT OUTPUT
AS
SELECT @TotalOrders = SUM(TotalDue)
FROM Sales.SalesOrderHeader
WHERE CustomerID = @CustomerID

-- Ejecución con OUTPUT
DECLARE @Total INT
EXEC Sales.TotalOrders 11001, @Total OUTPUT
SELECT @Total
```

---

## RETURN para valor escalar

`RETURN` sale del SP y devuelve un valor `INT` (o `MONEY` con cast):

```sql
CREATE PROCEDURE TotalDateRange @DateInit DATE, @DateEnd DATE
AS
DECLARE @Total MONEY
SELECT @Total = SUM(TotalDue)
FROM Sales.SalesOrderHeader
WHERE OrderDate BETWEEN @DateInit AND @DateEnd
RETURN @Total

-- Ejecución
DECLARE @ReturnTotal MONEY
EXEC @ReturnTotal = TotalDateRange '2001-07-01', '2001-09-01'
SELECT @ReturnTotal AS Total
```

> `RETURN` solo soporta `INT` nativamente. Para `MONEY`, usar parámetro `OUTPUT` en su lugar — más correcto.

---

## ALTER PROCEDURE

```sql
-- Cambiar el parámetro de ProductID a ProductName
CREATE PROCEDURE OrdersProductID @ProductID INT
AS
SELECT DISTINCT SalesOrderID
FROM Sales.SalesOrderDetail
WHERE ProductID = @ProductID

-- Modificar para recibir nombre en lugar de ID
ALTER PROCEDURE OrdersProductID @ProductName NVARCHAR(50)
AS
SELECT DISTINCT SalesOrderID
FROM Sales.SalesOrderDetail sod
JOIN Production.Product p ON sod.ProductID = p.ProductID
WHERE p.Name = @ProductName

EXEC OrdersProductID 'Sport-100 Helmet, Red'
```

---

## SP con múltiples parámetros OUTPUT

```sql
-- Patrón del examen obligatorio
CREATE PROCEDURE dbo.QtyEmp_Vacation_Hours
    @JobTitle          NVARCHAR(50),
    @FechaInicio       DATE,
    @FechaFin          DATE,
    @CantEmpleados     INT OUTPUT,
    @TotalVacationHours INT OUTPUT
AS
SET NOCOUNT ON;
SELECT
    @CantEmpleados      = COUNT(BusinessEntityID),
    @TotalVacationHours = SUM(VacationHours)
FROM HumanResources.Employee
WHERE JobTitle = @JobTitle
  AND HireDate BETWEEN @FechaInicio AND @FechaFin

-- Ejecución
DECLARE @Cant INT, @Vacaciones INT
EXEC dbo.QtyEmp_Vacation_Hours
    'Sales Representative', '2000-01-01', '2005-12-31',
    @Cant OUTPUT, @Vacaciones OUTPUT
SELECT @Cant AS CantidadEmpleados, @Vacaciones AS HorasVacacion
```

---

## SET NOCOUNT ON

Elimina los mensajes "N rows affected" del resultado:

```sql
AS
SET NOCOUNT ON;  -- ← siempre en SPs de producción
SELECT ...
```

Reduce el tráfico de red y evita confusión en clientes que leen row counts.

---

## @@ERROR y manejo de errores básico

```sql
-- T-SQL clásico (pre-SQL Server 2005)
IF (@@ERROR <> 0) SET @ErrorSave = @@ERROR

-- T-SQL moderno (SQL Server 2005+)
BEGIN TRY
    -- lógica
END TRY
BEGIN CATCH
    SELECT ERROR_MESSAGE(), ERROR_NUMBER()
END CATCH
```

---

## Equivalente en PostgreSQL

```sql
-- PostgreSQL usa CREATE FUNCTION con lenguaje plpgsql
CREATE OR REPLACE FUNCTION total_orders(p_customer_id INT)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT SUM(total_due) INTO v_total
    FROM sales_order_header
    WHERE customer_id = p_customer_id;
    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Llamada
SELECT total_orders(11001);
```

> PostgreSQL no tiene `STORED PROCEDURE` con `OUTPUT` params en el mismo sentido. Se usa `RETURNS` o `INOUT` params en funciones.

---

## Tips

- Usar nombres descriptivos con verbo: `GetEmployeeByTitle`, `InsertOrder`
- Siempre `SET NOCOUNT ON` en SPs de producción
- Preferir `TRY/CATCH` sobre `@@ERROR` en código nuevo
- Los SPs pueden encadenar: un SP puede llamar a otro con `EXEC`
- Usar schemas para organizar SPs: `Sales.TotalOrders` en lugar de `dbo.TotalOrders`

---

## Ver también

- [Práctico 6 — Enunciado](../../practicos/enunciados/practico-06-stored-procedures.pdf)
- [Práctico 6 — Solución](../../practicos/resoluciones/practico-06-stored-procedures-solucion.sql)
- [Módulo V — Variables](./05-variables.md)
- [Módulo VII — UDFs](./07-udfs.md)
