# Análisis — Práctico 8: Window Functions

**Módulo:** VIII — Window Functions (Tracking Analytics)  
**Ejercicios:** 4  
**Solución:** generada (sin solución oficial)

---

## Funciones de ventana cubiertas

| Ejercicio | Función | PARTITION BY | ORDER BY |
|-----------|---------|-------------|---------|
| 1 | `SUM() OVER` | SalesOrderID | — |
| 2 | `RANK() OVER` | ProductSubcategoryID | TotalVentas DESC |
| 3 | `SUM(SUM()) OVER` | — (global) | — |
| 4 | `LAG() OVER` | — (global) | Año, Mes |

---

## Análisis por ejercicio

### Ej1 — SUM() OVER para porcentaje por orden

```sql
SUM(sod.UnitPrice) OVER (PARTITION BY sod.SalesOrderID) AS TotalOrden
FORMAT(sod.UnitPrice / SUM(sod.UnitPrice) OVER (PARTITION BY sod.SalesOrderID), 'P2') AS Pct
```

**Clave:** `PARTITION BY SalesOrderID` define una ventana distinta por cada orden. La función de ventana calcula el `SUM` del grupo pero **no colapsa las filas** — cada línea de detalle mantiene su fila individual con el total de la orden como referencia.

**Sin OVER:** habría que usar un GROUP BY y luego un JOIN de vuelta a la tabla de detalle (más costoso).

---

### Ej2 — RANK() con subquery exterior para filtrar Ranking = 1

```sql
SELECT ... FROM (
    SELECT ..., RANK() OVER (
        PARTITION BY ps.ProductSubcategoryID
        ORDER BY SUM(sod.OrderQty * sod.UnitPrice) DESC
    ) AS Ranking
    FROM ...
    GROUP BY ...
) AS ranked
WHERE Ranking = 1
```

**Por qué subquery:** no se puede filtrar con `WHERE Ranking = 1` directamente en el mismo nivel donde se define la window function — las window functions se evalúan después del `WHERE`. La subquery materializa el resultado antes de aplicar el filtro exterior.

**RANK vs ROW_NUMBER aquí:** si dos productos tienen exactamente el mismo total en la misma subcategoría, `RANK` les asigna el mismo puesto (1, 1) — ambos aparecen. `ROW_NUMBER` elegiría uno arbitrariamente.

---

### Ej3 — SUM(SUM()) OVER () — el patrón de suma de agregados

```sql
SUM(soh.TotalDue) AS VentasTerritorrio,
SUM(SUM(soh.TotalDue)) OVER () AS VentasTotales
```

**Por qué es necesario el doble SUM:**
- El `SUM` interno es el agregado del `GROUP BY` (total por territorio)
- El `SUM` externo + `OVER()` suma los totales de todos los grupos (total global)

**Sin `OVER()`:** sería un error, porque no se puede usar una función de agregado sobre otra función de agregado en el mismo nivel.

**Alternativa con subquery:**
```sql
(SELECT SUM(TotalDue) FROM Sales.SalesOrderHeader) AS VentasTotales
```
Más claro pero menos eficiente (segunda pasada sobre la tabla).

---

### Ej4 — LAG para análisis mes a mes

```sql
LAG(SUM(TotalDue)) OVER (ORDER BY YEAR(OrderDate), MONTH(OrderDate)) AS VentasMesAnterior
```

**Clave:** el `ORDER BY` de la window function es sobre el resultado del `GROUP BY`, no sobre las filas originales. El `LAG` accede a la fila anterior en el orden definido por Año+Mes.

**NULLIF para división segura:**
```sql
FORMAT(
    (ventas_mes - ventas_anterior) / NULLIF(ventas_anterior, 0),
    'P2'
)
```
`NULLIF(x, 0)` devuelve NULL si x = 0, convirtiendo la división por cero en NULL (en lugar de error).

---

## Comparación: subquery correlacionada vs OVER

Para el mismo resultado (total anual del cliente por fila):

```sql
-- Subquery correlacionada (Ej5 del examen)
(SELECT SUM(soh2.TotalDue) FROM ... WHERE soh2.CustomerID = soh.CustomerID AND YEAR = YEAR)

-- OVER equivalente (Ej6 del examen)
SUM(TotalDue) OVER (PARTITION BY CustomerID, YEAR(OrderDate))
```

| | Subquery correlacionada | OVER |
|--|------------------------|------|
| Pasadas sobre la tabla | N (una por fila exterior) | 1 |
| Complejidad de lectura | Alta | Baja |
| Rendimiento en tablas grandes | Bajo | Alto |
| Disponible en | Cualquier SQL moderno | SQL:2003+ |

---

## Cuándo usar cada función de ranking

| Función | Comportamiento con empates | Uso típico |
|---------|--------------------------|-----------|
| `ROW_NUMBER` | Sin empates (arbitrario) | Paginación, índice único por fila |
| `RANK` | Empates comparten posición, gap después | Rankings competitivos |
| `DENSE_RANK` | Empates comparten posición, sin gap | Rankings continuos |
| `NTILE(n)` | Distribuye equitativamente en n grupos | Cuartiles, deciles |

---

## Ver también

- [Teoría Módulo VIII](../../teoria/markdown/08-window-functions.md)
- [Solución generada](../resoluciones/practico-08-window-functions-solucion.sql)
- [Window Functions Cheatsheet](../../cheatsheets/window-functions-cheatsheet.md)
