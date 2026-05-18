# Módulo II — DDL + DML

**Curso:** SQL Analytics II — Instituto CPE, Uruguay  
**Dialecto:** T-SQL · Ver equivalencias en [T-SQL vs PostgreSQL](../../cheatsheets/t-sql-vs-postgresql.md)

---

## DDL — Data Definition Language

Comandos que modifican la **estructura** de la base de datos.

### CREATE TABLE

```sql
CREATE TABLE dbo.MiTabla (
    Id        INT           NOT NULL,
    Nombre    NVARCHAR(100) NOT NULL,
    Precio    MONEY,
    FechaAlta DATE          DEFAULT GETDATE()
)
```

**SELECT INTO** — crea una tabla nueva a partir de un SELECT:

```sql
-- Crea #temp con los datos del SELECT (inferencia automática de tipos)
SELECT YEAR(soh.OrderDate) AS OrderYear,
       soh.CustomerID,
       sod.ProductID,
       sod.OrderQty,
       sod.UnitPrice
INTO #temp
FROM Sales.SalesOrderHeader AS soh
JOIN Sales.SalesOrderDetail AS sod ON soh.SalesOrderID = sod.SalesOrderID
```

> `SELECT INTO` no crea índices ni constraints. Para tablas permanentes con estructura controlada, preferir `CREATE TABLE` + `INSERT`.

**PostgreSQL:** `SELECT INTO` existe pero es preferible `CREATE TABLE ... AS SELECT ...`.

---

### ALTER TABLE

```sql
-- Agregar columna
ALTER TABLE #MiTabla ADD ProductName NVARCHAR(50)

-- Eliminar columna
ALTER TABLE #MiTabla DROP COLUMN ProductId

-- Cambiar tipo de dato
ALTER TABLE dbo.MiTabla ALTER COLUMN Nombre NVARCHAR(200)
```

> No se puede eliminar una columna si tiene un índice o constraint. Primero hay que eliminar el constraint.

---

### DROP TABLE

```sql
DROP TABLE #temp

-- Versión segura (T-SQL 2016+)
DROP TABLE IF EXISTS #temp

-- PostgreSQL equivalente
DROP TABLE IF EXISTS mi_tabla
```

---

### TRUNCATE TABLE

```sql
TRUNCATE TABLE dbo.MiTabla
```

| | `TRUNCATE` | `DELETE` |
|--|-----------|---------|
| Resetea identity | Sí | No |
| Se puede filtrar con WHERE | No | Sí |
| Activar triggers | No | Sí |
| Velocidad | Muy rápido | Más lento |
| Rollback | Sí (dentro de transacción) | Sí |

---

## DML — Data Manipulation Language

Comandos que modifican los **datos** dentro de una tabla.

### INSERT

```sql
-- Insertar filas individuales
INSERT INTO #PersonType (Id, Categoria, Clasificacion)
VALUES (1, 'Accounting Manager', 'Mandos medios'),
       (2, 'Assistant Sales Agent', 'Empleados')

-- Insertar resultado de SELECT
INSERT INTO #ventasClientesAñoProd
SELECT OrderYear, CustomerID, t.ProductID,
       SUM(OrderQty * UnitPrice) AS TotalSales,
       p.ProductName
FROM #temp AS t
JOIN #Productos AS p ON t.ProductID = p.ProductID
WHERE OrderYear != 2001
GROUP BY OrderYear, CustomerID, t.ProductID, p.ProductName
```

---

### UPDATE

```sql
-- Actualizar con valor literal
UPDATE #ventasClientesAñoProd
SET ProductName = 'Producto Discontinuado'
WHERE OrderYear = 2001

-- Actualizar desde otra tabla (T-SQL)
UPDATE t
SET t.ProductName = p.Name
FROM #ventasClientesAñoProd t
JOIN #Productos p ON t.ProductID = p.ProductID
```

> **PostgreSQL:** el UPDATE desde otra tabla usa sintaxis diferente:
> ```sql
> UPDATE mi_tabla t
> SET nombre = p.name
> FROM productos p
> WHERE t.product_id = p.id
> ```

---

### DELETE

```sql
-- Eliminar filas por condición
DELETE FROM #ventasClientesAñoProd
WHERE ProductName = 'Producto Discontinuado'

-- Eliminar todas las filas (equivalente a TRUNCATE en efecto, pero lento)
DELETE FROM dbo.MiTabla
```

---

## Patrón típico del práctico: BUILD → ENRICH → CLEAN

```
1. SELECT INTO #base          ← construir tabla de trabajo
2. SELECT INTO #resumen       ← agregar/resumir desde #base
3. ALTER TABLE ADD columna    ← extender estructura
4. INSERT INTO #resumen       ← insertar datos adicionales
5. UPDATE SET columna = valor ← actualizar datos faltantes
6. ALTER TABLE DROP COLUMN    ← limpiar columnas innecesarias
7. DROP TABLE #base           ← liberar tabla intermedia
8. DELETE FROM #resumen WHERE ← eliminar registros no válidos
```

---

## Tips y buenas prácticas

- Siempre hacer `DROP TABLE IF EXISTS #temp` antes de recrearla en desarrollo
- Usar `BEGIN TRANSACTION` / `ROLLBACK` al practicar `UPDATE` y `DELETE`
- `SELECT INTO` para prototipado rápido; `CREATE TABLE` para producción
- En T-SQL, los tipos `NVARCHAR` soportan Unicode; usar para nombres de personas

---

## Ver también

- [Práctico 2 — Enunciado](../../practicos/enunciados/practico-02-ddl-dml.pdf)
- [Práctico 2 — Solución](../../practicos/resoluciones/practico-02-ddl-dml-solucion.sql)
- [DDL + DML Cheatsheet](../../cheatsheets/ddl-dml-cheatsheet.md)
