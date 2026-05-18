# Análisis — Práctico 6: Stored Procedures

**Módulo:** VI — Stored Procedures  
**Ejercicios:** 5

---

## SPs creados

| Ejercicio | Nombre SP | Param tipo | Descripción |
|-----------|-----------|-----------|-------------|
| 1 | `Sales.TotalOrders` | OUTPUT | Suma total de órdenes por cliente |
| 2 | `HumanResources.HireInDate` | INPUT | Empleados contratados en fecha |
| 3 | `OrdersProductID` (v1) | INPUT | Órdenes por ProductID |
| 4 | `OrdersProductID` (v2 ALTER) | INPUT | Órdenes por nombre de producto |
| 5 | `TotalDateRange` | INPUT + RETURN | Total entre dos fechas |

---

## Análisis por ejercicio

### Ej1 — Parámetro OUTPUT

```sql
CREATE PROCEDURE Sales.TotalOrders
    @CustomerID  INT,
    @TotalOrders INT OUTPUT
AS
SELECT @TotalOrders = SUM(TotalDue)
FROM Sales.SalesOrderHeader WHERE CustomerID = @CustomerID
```

**Ejecución con OUTPUT:**
```sql
DECLARE @Total INT
EXEC Sales.TotalOrders 11001, @Total OUTPUT
SELECT @Total
```

La variable `@TotalOrders` en el SP y `@Total` en el caller son dos variables distintas; `OUTPUT` hace que el valor se "propague" hacia afuera al finalizar el SP.

**Importante:** el tipo de dato de la variable externa debe coincidir con el parámetro OUTPUT del SP.

---

### Ej2 — Schema en el nombre del SP

```sql
CREATE PROCEDURE HumanResources.HireInDate @Fecha DATE
```

Usar el schema correcto (`HumanResources`) organiza los SPs junto a las tablas que manipulan. Evita colisiones en el schema `dbo`.

---

### Ej3 y Ej4 — CREATE vs ALTER PROCEDURE

```sql
-- Ej3: crear con ProductID
CREATE PROCEDURE OrdersProductID @ProductID INT AS ...

-- Ej4: modificar para recibir nombre
ALTER PROCEDURE OrdersProductID @ProductName NVARCHAR(50) AS ...
```

`ALTER PROCEDURE` reemplaza la definición completa, incluyendo los parámetros. El nombre del SP se reutiliza — si se cambia la firma, el código que lo llama debe actualizarse también.

**DROP + CREATE vs ALTER:**
- `DROP + CREATE` pierde los permisos otorgados al SP
- `ALTER` mantiene los permisos → preferible en producción

---

### Ej5 — RETURN para valor escalar

```sql
CREATE PROCEDURE TotalDateRange @DateInit DATE, @DateEnd DATE
AS
DECLARE @Total MONEY
SELECT @Total = SUM(TotalDue) FROM ...
RETURN @Total
```

**Limitación crítica:** `RETURN` en T-SQL acepta solo `INT`. El código usa `MONEY`, lo que causa pérdida implícita de precisión (se trunca a entero).

**Solución correcta para MONEY:** usar parámetro `OUTPUT`:
```sql
CREATE PROCEDURE TotalDateRange
    @DateInit DATE, @DateEnd DATE,
    @Total MONEY OUTPUT
AS
SELECT @Total = SUM(TotalDue) FROM ...
WHERE OrderDate BETWEEN @DateInit AND @DateEnd
```

---

## Comparación de formas de devolver valores desde un SP

| Método | Tipo de dato | Cuándo usar |
|--------|-------------|-------------|
| `OUTPUT param` | Cualquiera | Siempre preferible para valores |
| `RETURN` | Solo INT | Código de error (0 = OK, <> 0 = error) |
| `SELECT` resultset | Cualquiera | Cuando se necesita devolver múltiples filas |

---

## Patrón del examen: múltiples OUTPUT params

```sql
CREATE PROCEDURE dbo.QtyEmp_Vacation_Hours
    @JobTitle NVARCHAR(50), @FechaInicio DATE, @FechaFin DATE,
    @CantEmpleados INT OUTPUT, @TotalVacationHours INT OUTPUT
AS
SET NOCOUNT ON;
SELECT @CantEmpleados = COUNT(...), @TotalVacationHours = SUM(...)
FROM HumanResources.Employee
WHERE JobTitle = @JobTitle AND HireDate BETWEEN @FechaInicio AND @FechaFin
```

**Siempre `SET NOCOUNT ON`** en SPs del examen: el evaluador no debe ver mensajes de "N rows affected".

---

## Ver también

- [Teoría Módulo VI](../../teoria/markdown/06-stored-procedures.md)
- [Solución](../resoluciones/practico-06-stored-procedures-solucion.sql)
