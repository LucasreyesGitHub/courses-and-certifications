# Cheatsheet — DDL + DML

**Dialecto primario:** T-SQL · Equivalencias PostgreSQL incluidas

---

## DDL — Data Definition Language

### CREATE TABLE

```sql
-- T-SQL
CREATE TABLE dbo.Empleados (
    ID       INT            NOT NULL PRIMARY KEY,
    Nombre   NVARCHAR(100)  NOT NULL,
    Salario  MONEY          DEFAULT 0,
    FechaAlta DATE          DEFAULT GETDATE()
)

-- PostgreSQL
CREATE TABLE empleados (
    id        SERIAL PRIMARY KEY,
    nombre    VARCHAR(100)  NOT NULL,
    salario   NUMERIC(19,4) DEFAULT 0,
    fecha_alta DATE         DEFAULT CURRENT_DATE
)
```

### SELECT INTO (T-SQL)

```sql
-- Crea la tabla e inserta en una pasada
SELECT col1, col2, col3
INTO #nueva_tabla
FROM tabla_origen
WHERE condicion

-- PostgreSQL equivalente
CREATE TABLE nueva_tabla AS
SELECT col1, col2, col3 FROM tabla_origen WHERE condicion
```

### ALTER TABLE

```sql
-- Agregar columna
ALTER TABLE tabla ADD columna TIPO [NULL | NOT NULL] [DEFAULT valor]

-- Eliminar columna
ALTER TABLE tabla DROP COLUMN columna

-- Cambiar tipo (T-SQL)
ALTER TABLE tabla ALTER COLUMN columna NUEVO_TIPO

-- Cambiar tipo (PostgreSQL)
ALTER TABLE tabla ALTER COLUMN columna TYPE nuevo_tipo [USING expresion]
```

### DROP TABLE

```sql
-- T-SQL
DROP TABLE tabla
DROP TABLE IF EXISTS tabla  -- SQL Server 2016+

-- PostgreSQL
DROP TABLE IF EXISTS tabla CASCADE
```

### TRUNCATE vs DELETE

```sql
TRUNCATE TABLE tabla                   -- rápido, no WHERE, resetea identity
DELETE FROM tabla                      -- lento, permite WHERE, no resetea identity
DELETE FROM tabla WHERE condicion      -- eliminar filas específicas
```

---

## DML — Data Manipulation Language

### INSERT

```sql
-- Fila única
INSERT INTO tabla (col1, col2) VALUES (val1, val2)

-- Múltiples filas (T-SQL 2008+ / PostgreSQL)
INSERT INTO tabla (col1, col2) VALUES
    (val1a, val2a),
    (val1b, val2b)

-- Desde SELECT
INSERT INTO tabla (col1, col2)
SELECT expr1, expr2 FROM otra_tabla WHERE cond

-- Con OUTPUT (T-SQL) / RETURNING (PostgreSQL)
INSERT INTO tabla (col1) VALUES (val) OUTPUT INSERTED.id  -- T-SQL
INSERT INTO tabla (col1) VALUES (val) RETURNING id          -- PostgreSQL
```

### UPDATE

```sql
-- Simple
UPDATE tabla SET col1 = val1, col2 = val2 WHERE cond

-- Desde otra tabla (T-SQL)
UPDATE t SET t.col = s.col
FROM tabla t JOIN otra_tabla s ON t.id = s.id WHERE cond

-- Desde otra tabla (PostgreSQL)
UPDATE tabla t SET col = s.col
FROM otra_tabla s WHERE t.id = s.id AND cond
```

### DELETE

```sql
DELETE FROM tabla WHERE cond

-- Con OUTPUT (T-SQL) — ver qué se eliminó
DELETE FROM tabla OUTPUT DELETED.* WHERE cond

-- Con RETURNING (PostgreSQL)
DELETE FROM tabla WHERE cond RETURNING *
```

---

## Tablas temporales (T-SQL)

```sql
-- Local (solo sesión actual)
SELECT ... INTO #nombre FROM ...
CREATE TABLE #nombre (col TIPO)

-- Global (todas las sesiones)
SELECT ... INTO ##nombre FROM ...

-- Limpiar
DROP TABLE IF EXISTS #nombre
DROP TABLE IF EXISTS ##nombre
```

---

## Secuencia típica de trabajo con temps

```sql
-- 1. Proteger re-ejecución
DROP TABLE IF EXISTS #resultado

-- 2. Materializar datos base
SELECT col1, col2, SUM(col3) AS total
INTO #resultado
FROM tabla
WHERE cond
GROUP BY col1, col2

-- 3. Agregar índice si se re-usa mucho
CREATE INDEX idx ON #resultado (col1)

-- 4. Trabajar con la tabla temporal
SELECT * FROM #resultado ORDER BY total DESC

-- 5. Limpiar (o dejar que la sesión lo haga)
DROP TABLE #resultado
```

---

## Tipos de dato comunes T-SQL vs PostgreSQL

| T-SQL | PostgreSQL | Descripción |
|-------|-----------|-------------|
| `INT` | `INTEGER` | Entero 32-bit |
| `BIGINT` | `BIGINT` | Entero 64-bit |
| `MONEY` | `NUMERIC(19,4)` | Monetario |
| `FLOAT` | `DOUBLE PRECISION` | Flotante |
| `BIT` | `BOOLEAN` | Booleano |
| `DATE` | `DATE` | Solo fecha |
| `DATETIME` | `TIMESTAMP` | Fecha + hora |
| `NVARCHAR(n)` | `VARCHAR(n)` | String Unicode variable |
| `NCHAR(n)` | `CHAR(n)` | String fijo |
| `UNIQUEIDENTIFIER` | `UUID` | GUID |
