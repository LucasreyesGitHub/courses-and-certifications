# Cheatsheet — Window Functions

**Dialecto primario:** T-SQL · PostgreSQL: sintaxis OVER() idéntica

---

## Anatomía de OVER()

```sql
FUNCION() OVER (
    PARTITION BY col1, col2   -- grupos (como GROUP BY pero sin colapsar filas)
    ORDER BY col3 DESC        -- orden dentro de cada partición
    ROWS BETWEEN              -- marco de filas (opcional)
        UNBOUNDED PRECEDING   -- desde el inicio de la partición
        AND CURRENT ROW       -- hasta la fila actual (default si hay ORDER BY)
)
```

---

## Funciones de ranking

| Función | Empates | Gaps | Uso típico |
|---------|---------|------|-----------|
| `ROW_NUMBER()` | Sin empates | N/A | Paginación, ID único por fila |
| `RANK()` | Mismo número | Sí (1,1,3) | Rankings competitivos |
| `DENSE_RANK()` | Mismo número | No (1,1,2) | Rankings continuos |
| `NTILE(n)` | Distribuye en n grupos | N/A | Cuartiles, deciles |

```sql
ROW_NUMBER()  OVER (PARTITION BY dept ORDER BY salary DESC)
RANK()        OVER (PARTITION BY dept ORDER BY salary DESC)
DENSE_RANK()  OVER (PARTITION BY dept ORDER BY salary DESC)
NTILE(4)      OVER (ORDER BY salary DESC)  -- cuartiles
```

---

## Funciones de valor

```sql
-- Valor de la fila ANTERIOR (N pasos atrás, default=1)
LAG(col)      OVER (PARTITION BY grp ORDER BY ord)
LAG(col, 2)   OVER (...)  -- 2 filas atrás
LAG(col, 1, 0) OVER (...) -- default 0 si es NULL (primera fila)

-- Valor de la fila SIGUIENTE (N pasos adelante)
LEAD(col)     OVER (PARTITION BY grp ORDER BY ord)

-- Primer/último valor de la partición
FIRST_VALUE(col) OVER (PARTITION BY grp ORDER BY ord)
LAST_VALUE(col)  OVER (PARTITION BY grp ORDER BY ord
                       ROWS BETWEEN UNBOUNDED PRECEDING
                            AND UNBOUNDED FOLLOWING)  -- ← necesario
```

> `LAST_VALUE` con el frame default no llega al final — siempre especificar `ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING`.

---

## Funciones de agregado como ventana

```sql
SUM(col)   OVER (PARTITION BY grp)           -- total del grupo por fila
SUM(col)   OVER (PARTITION BY grp ORDER BY ord) -- acumulativo
AVG(col)   OVER (PARTITION BY grp)
COUNT(col) OVER ()                            -- total global en cada fila
MAX(col)   OVER (PARTITION BY grp)
```

---

## Patrones frecuentes

### Porcentaje dentro de grupo
```sql
FORMAT(col / SUM(col) OVER (PARTITION BY grp), 'P2') AS Pct
```

### Ranking top-N por grupo (filtrar luego)
```sql
SELECT * FROM (
    SELECT *, RANK() OVER (PARTITION BY cat ORDER BY valor DESC) AS rk
    FROM tabla
) sub
WHERE rk = 1
```

### Total global como referencia por fila
```sql
SUM(col) OVER () AS TotalGlobal
col / SUM(col) OVER () AS PctGlobal
```

### Total del agregado (SUM dentro de GROUP BY con OVER)
```sql
-- Cuando ya hay GROUP BY y se necesita el total de los grupos
SUM(SUM(col)) OVER () AS TotalDeGrupos
```

### Días entre eventos consecutivos por entidad
```sql
DATEDIFF(DAY,
    LAG(fecha) OVER (PARTITION BY entidad_id ORDER BY fecha),
    fecha
) AS DiasDesdeAnterior
```

### Acumulado con reset por grupo
```sql
SUM(col) OVER (
    PARTITION BY anio, region
    ORDER BY mes
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
) AS AcumuladoMensual
```

---

## Window vs GROUP BY — diferencias clave

```sql
-- GROUP BY: colapsa filas, pierde detalle
SELECT dept, AVG(salary) FROM employees GROUP BY dept

-- OVER: mantiene detalle, agrega contexto
SELECT dept, salary, AVG(salary) OVER (PARTITION BY dept) AS avg_dept
FROM employees
```

---

## PostgreSQL — diferencias menores

```sql
-- T-SQL FORMAT para porcentaje
FORMAT(ratio, 'P2')

-- PostgreSQL equivalente
ROUND(ratio * 100, 2) || '%'
-- o
TO_CHAR(ratio, 'FM999.99%')
```

La sintaxis de `OVER()`, `PARTITION BY`, `ORDER BY`, `ROWS BETWEEN`, `LAG`, `LEAD`, `RANK`, `DENSE_RANK`, `ROW_NUMBER`, `NTILE`, `FIRST_VALUE`, `LAST_VALUE` es **idéntica** en T-SQL y PostgreSQL.
