# Cheatsheet — Subqueries

**Dialecto primario:** T-SQL · Equivalencias PostgreSQL incluidas

---

## Sintaxis rápida

```sql
-- WHERE IN
SELECT ... FROM T WHERE col IN (SELECT col FROM T2 WHERE cond)

-- WHERE NOT IN  ⚠ cuidado con NULLs
SELECT ... FROM T WHERE col NOT IN (SELECT col FROM T2)

-- WHERE EXISTS
SELECT ... FROM T WHERE EXISTS (SELECT 1 FROM T2 WHERE T2.fk = T.pk)

-- WHERE NOT EXISTS
SELECT ... FROM T WHERE NOT EXISTS (SELECT 1 FROM T2 WHERE T2.fk = T.pk)

-- Scalar en SELECT
SELECT col1, (SELECT MAX(col) FROM T2) AS MaxVal FROM T

-- Subquery correlacionada en SELECT
SELECT col1, (SELECT SUM(col) FROM T2 WHERE T2.fk = T.pk) AS Total FROM T

-- ALL / ANY
SELECT ... FROM T WHERE col > ALL (SELECT col FROM T2)
SELECT ... FROM T WHERE col > ANY (SELECT col FROM T2)

-- Tabla derivada (subquery en FROM)
SELECT * FROM (SELECT col, COUNT(*) AS cnt FROM T GROUP BY col) AS sub WHERE cnt > 5
```

---

## Tabla de equivalencias operador → semántica

| Operador | Equivale a | Notas |
|----------|-----------|-------|
| `= ANY` | `IN` | |
| `<> ALL` | `NOT IN` | ⚠ falla con NULL |
| `> ALL (subq)` | `> MAX(subq)` | |
| `> ANY (subq)` | `> MIN(subq)` | |
| `EXISTS` | `IN` (eficiente) | Se detiene en 1er match |
| `NOT EXISTS` | `NOT IN` (seguro) | Maneja NULL correctamente |

---

## Reglas de NOT IN con NULL

```sql
-- Si la subquery devuelve un NULL, NOT IN devuelve vacío
WHERE id NOT IN (SELECT id FROM T WHERE cond)  -- PELIGROSO si T tiene NULLs

-- NOT EXISTS es seguro
WHERE NOT EXISTS (SELECT 1 FROM T WHERE T.id = outer.id AND cond)

-- Solución alternativa para NOT IN con NULL:
WHERE id NOT IN (SELECT id FROM T WHERE id IS NOT NULL AND cond)
```

---

## Cuándo usar cada patrón

| Situación | Patrón recomendado |
|-----------|-------------------|
| Filtrar por lista de IDs de otra tabla | `IN` o `JOIN` |
| Verificar existencia de relación | `EXISTS` |
| Excluir filas sin relación | `NOT EXISTS` |
| Valor calculado por grupo en cada fila | Scalar subquery o `OVER()` |
| Múltiples filas relacionadas con condición de conteo | `EXISTS + HAVING` |
| Filtro complejo sobre conjunto | Tabla derivada en `FROM` |

---

## Optimización: subquery → OVER

```sql
-- Antes: scalar subquery correlacionada (N ejecuciones)
SELECT CustomerID, TotalDue,
       (SELECT SUM(TotalDue) FROM T WHERE CustomerID = outer.CustomerID) AS Total
FROM T AS outer

-- Después: window function (1 pasada)
SELECT CustomerID, TotalDue,
       SUM(TotalDue) OVER (PARTITION BY CustomerID) AS Total
FROM T
```

---

## PostgreSQL — diferencias

- Sintaxis de subqueries: **idéntica** a T-SQL
- `SOME` es sinónimo de `ANY` en ambos dialectos
- `LATERAL` en PostgreSQL (equivale a subquery correlacionada en FROM):
  ```sql
  SELECT t.id, sub.total
  FROM T t
  CROSS JOIN LATERAL (SELECT SUM(amount) FROM orders o WHERE o.customer_id = t.id) AS sub(total)
  ```
