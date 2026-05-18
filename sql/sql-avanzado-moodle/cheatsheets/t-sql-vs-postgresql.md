# Cheatsheet — T-SQL vs PostgreSQL

Equivalencias y diferencias de sintaxis entre los dialectos del curso (T-SQL) y el estándar general (PostgreSQL).

---

## Funciones de fecha

| Operación | T-SQL | PostgreSQL |
|-----------|-------|-----------|
| Año de una fecha | `YEAR(col)` | `EXTRACT(YEAR FROM col)` |
| Mes | `MONTH(col)` | `EXTRACT(MONTH FROM col)` |
| Día | `DAY(col)` | `EXTRACT(DAY FROM col)` |
| Fecha actual | `GETDATE()` | `NOW()` o `CURRENT_TIMESTAMP` |
| Solo fecha actual | `CAST(GETDATE() AS DATE)` | `CURRENT_DATE` |
| Diferencia en días | `DATEDIFF(DAY, f1, f2)` | `f2 - f1` (retorna INT) |
| Diferencia en años | `DATEDIFF(YEAR, f1, f2)` | `DATE_PART('year', age(f2, f1))` |
| Agregar días | `DATEADD(DAY, n, fecha)` | `fecha + n` |
| Agregar meses | `DATEADD(MONTH, n, fecha)` | `fecha + INTERVAL 'n months'` |
| Construir fecha | `DATEFROMPARTS(y, m, d)` | `MAKE_DATE(y, m, d)` |
| Convertir formato | `CONVERT(VARCHAR, fecha, 103)` | `TO_CHAR(fecha, 'DD/MM/YYYY')` |

---

## Funciones de texto

| Operación | T-SQL | PostgreSQL |
|-----------|-------|-----------|
| Longitud | `LEN(col)` | `LENGTH(col)` |
| Substring | `SUBSTRING(col, inicio, largo)` | `SUBSTRING(col FROM inicio FOR largo)` |
| Reemplazar | `REPLACE(col, 'a', 'b')` | `REPLACE(col, 'a', 'b')` |
| Mayúsculas | `UPPER(col)` | `UPPER(col)` |
| Minúsculas | `LOWER(col)` | `LOWER(col)` |
| Concatenar | `col1 + col2` o `CONCAT(c1,c2)` | `col1 \|\| col2` o `CONCAT(c1,c2)` |
| Recortar espacios | `LTRIM(RTRIM(col))` | `TRIM(col)` |
| Formatear número | `FORMAT(num, 'P2')` | `TO_CHAR(num*100, 'FM999.99') \|\| '%'` |

---

## Selección de Top N filas

```sql
-- T-SQL
SELECT TOP 10 * FROM tabla ORDER BY col DESC

SELECT TOP 10 WITH TIES * FROM tabla ORDER BY col DESC  -- incluye empates

-- PostgreSQL
SELECT * FROM tabla ORDER BY col DESC LIMIT 10
```

---

## Variables y bloques procedurales

```sql
-- T-SQL (batch / stored procedure)
DECLARE @var INT
SET @var = 5
SELECT @var = MAX(col) FROM tabla

-- PostgreSQL (solo dentro de DO block o función)
DO $$
DECLARE
    v_var INT;
BEGIN
    SELECT MAX(col) INTO v_var FROM tabla;
    -- usar v_var aquí
END $$;

-- PostgreSQL en queries normales: usar CTE como "variable"
WITH params AS (SELECT MAX(col) AS max_col FROM tabla)
SELECT * FROM tabla WHERE col = (SELECT max_col FROM params)
```

---

## Stored Procedures vs Functions

| | T-SQL | PostgreSQL |
|--|-------|-----------|
| Crear SP | `CREATE PROCEDURE` | `CREATE FUNCTION` (no existe SP nativo) |
| Parámetros OUTPUT | `@param TIPO OUTPUT` | `INOUT p_param TIPO` |
| Valor de retorno escalar | `RETURN valor` | `RETURN valor` en función |
| Ejecutar | `EXEC nombre params` | `SELECT nombre(params)` o `CALL` |
| Modificar | `ALTER PROCEDURE` | `CREATE OR REPLACE FUNCTION` |

---

## Views

```sql
-- Crear: idéntico
CREATE VIEW nombre AS SELECT ...

-- Modificar
ALTER VIEW nombre AS SELECT ...           -- T-SQL
CREATE OR REPLACE VIEW nombre AS SELECT ...  -- PostgreSQL

-- Eliminar: idéntico
DROP VIEW IF EXISTS nombre
```

---

## UDFs — Scalar Functions

```sql
-- T-SQL
CREATE FUNCTION dbo.MiFuncion (@param INT) RETURNS INT
AS BEGIN
    DECLARE @result INT
    SET @result = @param * 2
    RETURN @result
END
-- Llamada: SELECT dbo.MiFuncion(5)

-- PostgreSQL
CREATE OR REPLACE FUNCTION mi_funcion(param INT) RETURNS INT AS $$
BEGIN
    RETURN param * 2;
END;
$$ LANGUAGE plpgsql;
-- Llamada: SELECT mi_funcion(5)
```

---

## UDFs — Table-Valued Functions (TVF)

```sql
-- T-SQL (inline TVF)
CREATE FUNCTION Sales.MiTVF (@year INT) RETURNS TABLE AS
RETURN (SELECT * FROM tabla WHERE YEAR(fecha) = @year)
-- Llamada: SELECT * FROM Sales.MiTVF(2004)

-- PostgreSQL (RETURNS TABLE)
CREATE OR REPLACE FUNCTION mi_tvf(p_year INT)
RETURNS TABLE(col1 INT, col2 TEXT) AS $$
BEGIN
    RETURN QUERY SELECT col1, col2 FROM tabla
    WHERE EXTRACT(YEAR FROM fecha) = p_year;
END;
$$ LANGUAGE plpgsql;
-- Llamada: SELECT * FROM mi_tvf(2004)
```

---

## Tablas temporales

```sql
-- T-SQL
SELECT ... INTO #temp FROM ...          -- local
SELECT ... INTO ##temp FROM ...         -- global
CREATE TABLE #temp (col TIPO)

-- PostgreSQL
CREATE TEMP TABLE temp AS SELECT ...
CREATE TEMPORARY TABLE temp (col TIPO)
-- PostgreSQL no tiene tablas temporales globales (##)
```

---

## Manejo de NULL

```sql
-- T-SQL
ISNULL(col, valor_default)
NULLIF(col, 0)           -- retorna NULL si col = 0

-- PostgreSQL
COALESCE(col, valor_default)   -- funciona también en T-SQL
NULLIF(col, 0)                 -- idéntico en ambos
```

---

## Transacciones

```sql
-- Idéntico en ambos
BEGIN TRANSACTION
    UPDATE ...
    DELETE ...
COMMIT
-- o
ROLLBACK
```

---

## Diferencias menores que suelen causar errores

| Situación | T-SQL | PostgreSQL |
|-----------|-------|-----------|
| String con comillas | `'texto'` | `'texto'` |
| Identificadores con mayúsculas | `[NombreConMayúsculas]` | `"NombreConMayúsculas"` |
| Booleano | `BIT (0/1)` | `BOOLEAN (true/false)` |
| Auto-incremento | `IDENTITY(1,1)` | `SERIAL` o `GENERATED ALWAYS AS IDENTITY` |
| Schema por defecto | `dbo` | `public` |
| Separador de esquema | `.` (Sales.Tabla) | `.` (sales.tabla) |
| Case-sensitive nombres | No por defecto | No por defecto (depende de collation) |
