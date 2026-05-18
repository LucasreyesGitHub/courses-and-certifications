# Módulo III — Tablas Temporales

**Curso:** SQL Analytics II — Instituto CPE, Uruguay  
**Dialecto:** T-SQL · Ver equivalencias en [T-SQL vs PostgreSQL](../../cheatsheets/t-sql-vs-postgresql.md)  
**Nota:** El PDF de teoría de este módulo no está disponible. Contenido reconstruido desde Práctico 3 y su solución oficial.

---

## ¿Qué es una tabla temporal?

Una tabla temporal es una tabla que existe solo durante la sesión (o el batch) en que fue creada. SQL Server las almacena en `tempdb`.

---

## Tipos de tablas temporales

### #Local (almohadilla simple)

```sql
SELECT p.BusinessEntityID,
       CONCAT(LastName, ', ', FirstName) AS NombreCompleto,
       (40 * hre2.Rate) AS SueldoSemanal,
       CONVERT(VARCHAR, hre2.RateChangeDate, 103) AS ValidoDesde
INTO #SueldoHistoricoEmpleados
FROM Person.Person AS p
JOIN HumanResources.Employee AS hre ON p.BusinessEntityID = hre.BusinessEntityID
JOIN HumanResources.EmployeePayHistory AS hre2 ON hre.BusinessEntityID = hre2.BusinessEntityID
```

| Característica | #Local |
|----------------|--------|
| Alcance | Solo la sesión/conexión actual |
| Visible para otras sesiones | No |
| Se elimina automáticamente | Al cerrar la sesión o el scope |
| Nombre | Prefijo `#` |

---

### ##Global (doble almohadilla)

```sql
SELECT p.BusinessEntityID,
       CONCAT(LastName, ', ', FirstName) AS NombreCompleto,
       (40 * hre2.Rate) AS SueldoSemanal,
       CONVERT(VARCHAR, hre2.RateChangeDate, 103) AS ValidoDesde
INTO ##SueldoActualEmpleados
FROM Person.Person AS p
JOIN HumanResources.Employee AS hre ON p.BusinessEntityID = hre.BusinessEntityID
JOIN HumanResources.EmployeePayHistory AS hre2 ON hre.BusinessEntityID = hre2.BusinessEntityID
WHERE hre2.RateChangeDate = (
    SELECT MAX(RateChangeDate)
    FROM HumanResources.EmployeePayHistory AS hre1
    WHERE hre.BusinessEntityID = hre1.BusinessEntityID
)
```

| Característica | ##Global |
|----------------|---------|
| Alcance | Todas las sesiones/conexiones |
| Visible para otras sesiones | Sí |
| Se elimina automáticamente | Cuando la sesión creadora la cierra y no hay referencias |
| Nombre | Prefijo `##` |

---

## Formas de crear tablas temporales

### SELECT INTO (inferencia de tipos)

```sql
SELECT CustomerID, FirstName, LastName, SH.OrderDate
INTO ##UnicaCompra
FROM Sales.SalesOrderHeader SH
JOIN Sales.Customer AS c ON SH.CustomerID = C.CustomerID
JOIN Person.Person AS P ON c.PersonID = P.BusinessEntityID
WHERE SH.CustomerID IN (
    SELECT CustomerID
    FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
    HAVING COUNT(SalesOrderID) = 1
)
```

### CREATE TABLE + INSERT (control explícito de tipos)

```sql
CREATE TABLE #PersonType (
    Id           NUMERIC(4),
    Categoria    NVARCHAR(50),
    Clasificacion NCHAR(50)
)

INSERT INTO #PersonType (Id, Categoria, Clasificacion)
VALUES (1, 'Accounting Manager', 'Mandos medios'),
       (2, 'Assistant Sales Agent', 'Empleados'),
       -- ... más filas
       (20, 'Sales Representative', 'Empleados')
```

> Usar `CREATE TABLE + INSERT` cuando se necesita control de tipos, índices o constraints.

---

## Cuándo usar tablas temporales

- Guardar resultados intermedios de consultas complejas
- Evitar recalcular el mismo subconjunto de datos múltiples veces
- Pasar datos entre pasos de un proceso batch
- Materializar CTEs o subqueries costosas

---

## Tablas temporales vs CTEs vs Subqueries

| | Tabla temporal | CTE | Subquery |
|--|---------------|-----|---------|
| Persiste entre statements | Sí | No | No |
| Reutilizable | Sí | Solo en el mismo SELECT | No |
| Indexable | Sí | No | No |
| Legibilidad | Media | Alta | Media |
| Overhead | Escribe a tempdb | Sin overhead | Sin overhead |

---

## Equivalente en PostgreSQL

```sql
-- PostgreSQL no tiene tablas temporales de sesión con el mismo scope
-- Se usan CREATE TEMP TABLE o CTE

CREATE TEMP TABLE sueldo_historico AS
SELECT ...;

-- O con CTE:
WITH sueldo_historico AS (
    SELECT ...
)
SELECT * FROM sueldo_historico;
```

---

## Tips y buenas prácticas

- Siempre hacer `DROP TABLE IF EXISTS #nombre` antes de `SELECT INTO` en scripts que se re-ejecutan
- Las tablas globales `##` son peligrosas en entornos multi-usuario: otro usuario puede leer/modificar tus datos
- Para grandes volúmenes, crear índices explícitamente después del `SELECT INTO`:
  ```sql
  CREATE INDEX idx_customerid ON #temp (CustomerID)
  ```
- En stored procedures, las tablas `#locales` se eliminan solas al finalizar el SP

---

## Ver también

- [Práctico 3 — Enunciado](../../practicos/enunciados/practico-03-temp-tables.pdf)
- [Práctico 3 — Solución](../../practicos/resoluciones/practico-03-temp-tables-solucion.sql)
- [Práctico 3 — Análisis](../../practicos/analisis/practico-03-analisis.md)
