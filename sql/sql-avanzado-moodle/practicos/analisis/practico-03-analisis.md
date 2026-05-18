# Análisis — Práctico 3: Tablas Temporales

**Módulo:** III — Tablas Temporales  
**Ejercicios:** 5

---

## Resumen de objetos creados

| Ejercicio | Objeto | Tipo | Contenido |
|-----------|--------|------|-----------|
| 1 | `#SueldoHistoricoEmpleados` | Local | Histórico completo de sueldos |
| 2 | `##SueldoActualEmpleados` | Global | Solo sueldo actual por empleado |
| 3 | `#PersonType` | Local | Tabla de clasificación (20 filas) |
| 4 | `#VentasAnualesPorTerritorio` | Local | Total de ventas por año/territorio |
| 5 | `##UnicaCompra` | Global | Clientes con exactamente 1 compra |

---

## Análisis por ejercicio

### Ej1 — Historial con CONCAT y CONVERT

```sql
CONCAT(LastName, ', ', FirstName) AS NombreCompleto
CONVERT(VARCHAR, hre2.RateChangeDate, 103) AS ValidoDesde
```

- `CONCAT` evita el NULL implícito de la concatenación con `+` (si algún campo es NULL, `+` devuelve NULL)
- `CONVERT(VARCHAR, fecha, 103)` → formato DD/MM/YYYY (código 103 = estándar British/French)

**Tabla de códigos CONVERT frecuentes:**

| Código | Formato | Ejemplo |
|--------|---------|---------|
| 101 | MM/DD/YYYY | 05/18/2026 |
| 103 | DD/MM/YYYY | 18/05/2026 |
| 112 | YYYYMMDD | 20260518 |
| 120 | YYYY-MM-DD HH:MM:SS | 2026-05-18 10:30:00 |

---

### Ej2 — Sueldo actual con subquery correlacionada para MAX fecha

```sql
WHERE hre2.RateChangeDate = (
    SELECT MAX(RateChangeDate)
    FROM HumanResources.EmployeePayHistory AS hre1
    WHERE hre.BusinessEntityID = hre1.BusinessEntityID
)
```

Este patrón garantiza una sola fila por empleado: la más reciente. La correlación `hre.BusinessEntityID = hre1.BusinessEntityID` asegura que el MAX se evalúa por empleado, no global.

**Alternativa con ROW_NUMBER** (más moderna):
```sql
WITH LatestPay AS (
    SELECT *, ROW_NUMBER() OVER (
        PARTITION BY BusinessEntityID ORDER BY RateChangeDate DESC
    ) AS rn
    FROM HumanResources.EmployeePayHistory
)
SELECT p.BusinessEntityID, ...
FROM LatestPay lp
JOIN ... WHERE lp.rn = 1
```

---

### Ej3 — CREATE TABLE + INSERT VALUES vs SELECT INTO

Este ejercicio usa `CREATE TABLE` explícita + `INSERT` con múltiples VALUES porque la tabla no proviene de otra tabla — sus datos son literales. `SELECT INTO` no aplica aquí.

**Patrón multi-VALUES (T-SQL 2008+):**
```sql
INSERT INTO #PersonType VALUES
    (1, 'Accounting Manager', 'Mandos medios'),
    (2, 'Assistant Sales Agent', 'Empleados'),
    ...
    (20, 'Sales Representative', 'Empleados')
```

Un solo `INSERT` es más eficiente que 20 `INSERT` individuales.

---

### Ej4 — Ventas anuales por territorio

El `GROUP BY` incluye `st.TerritoryID, st.Name, YEAR(soh.OrderDate)` — tres columnas porque necesitamos granularidad de año + territorio.

---

### Ej5 — Clientes con exactamente 1 compra (HAVING COUNT = 1)

```sql
WHERE SH.CustomerID IN (
    SELECT CustomerID FROM Sales.SalesOrderHeader
    GROUP BY CustomerID HAVING COUNT(SalesOrderID) = 1
)
```

El `IN + HAVING` es el patrón estándar para filtrar por conteo de filas relacionadas.

---

## #Local vs ##Global — regla práctica

- Usar `#local` cuando los datos son de uso exclusivo de la sesión actual
- Usar `##global` solo cuando otras sesiones necesitan leer los datos
- Evitar `##global` en entornos multi-usuario: riesgo de colisiones de nombres

---

## Ver también

- [Teoría Módulo III](../../teoria/markdown/03-temp-tables.md)
- [Solución](../resoluciones/practico-03-temp-tables-solucion.sql)
