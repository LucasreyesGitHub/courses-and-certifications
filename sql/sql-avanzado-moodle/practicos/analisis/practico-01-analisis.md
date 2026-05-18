# Análisis — Práctico 1: Subqueries

**Módulo:** I — Subqueries  
**Ejercicios:** 5 (contando 2a y 2b como 2)

---

## Patrones identificados

| Ejercicio | Patrón | Nivel de dificultad |
|-----------|--------|-------------------|
| 1 | `IN` anidado 3 niveles (categoría → subcategoría → producto) | Alto |
| 2a | `EXISTS` correlacionado | Medio |
| 2b | `IN` equivalente a `EXISTS` | Medio |
| 3 | Scalar subquery no correlacionada en `SELECT` | Medio |
| 4 | Scalar subquery + `FORMAT('P')` para porcentaje | Medio |
| 5 | `EXISTS` con `HAVING COUNT > 20` en subquery | Alto |

---

## Análisis por ejercicio

### Ejercicio 1 — Subquery anidada en 3 niveles

```
ProductCategory.Name = 'Components'
    → ProductSubcategory.ProductCategoryID
        → Product.ProductSubcategoryID
            → SalesOrderDetail.ProductID (filtro)
```

**Por qué 3 niveles:** el modelo de AdventureWorks normaliza categorías en 3 tablas (`ProductCategory` → `ProductSubcategory` → `Product`). Cada nivel resuelve la FK del nivel superior.

**Alternativa con JOIN:** más eficiente para sets grandes:
```sql
WHERE sod.ProductID IN (
    SELECT p.ProductID
    FROM Production.Product p
    JOIN Production.ProductSubcategory ps ON p.ProductSubcategoryID = ps.ProductSubcategoryID
    JOIN Production.ProductCategory pc ON ps.ProductCategoryID = pc.ProductCategoryID
    WHERE pc.Name = 'Components'
)
```

---

### Ejercicios 2a vs 2b — EXISTS vs IN para el mismo resultado

```sql
-- 2a: EXISTS con correlación
WHERE EXISTS (
    SELECT hre.BusinessEntityID
    FROM HumanResources.Employee hre
    WHERE SickLeaveHours < (SELECT AVG(...) FROM ...)
      AND p.BusinessEntityID = hre.BusinessEntityID  -- ← correlación
)

-- 2b: IN sin correlación en la subquery exterior
WHERE p.BusinessEntityID IN (
    SELECT hre.BusinessEntityID
    FROM HumanResources.Employee hre
    WHERE SickLeaveHours < (SELECT AVG(...) FROM ...)
      AND p.BusinessEntityID = hre.BusinessEntityID
)
```

**Nota:** La versión 2b es rara — la correlación dentro de `IN` es válida pero inusual. El resultado es el mismo que `EXISTS`.

**Cuándo preferir EXISTS:** en tablas grandes, ya que se detiene en el primer match.

---

### Ejercicios 3 y 4 — Scalar subquery en SELECT

**Ejercicio 3** (count, no correlacionada):
```sql
(SELECT COUNT(SalesOrderID)
 FROM Sales.SalesOrderHeader WHERE YEAR(OrderDate) = 2003
) AS TotalDeVentas
```
Esta subquery devuelve el mismo número para **todas** las filas. El optimizador la ejecuta una sola vez.

**Ejercicio 4** (porcentaje con FORMAT):
```sql
FORMAT(
    CAST(COUNT(soh.SalesOrderID) AS FLOAT) /
    (SELECT COUNT(SalesOrderID) FROM ... WHERE YEAR = 2004),
    'P'
)
```
El CAST a FLOAT es crítico: sin él, la división entre enteros trunca al número entero más cercano.

**Alternativa OVER para 3 y 4:**
```sql
-- Equivalente más eficiente para ejercicio 3
SUM(COUNT(soh.SalesOrderID)) OVER () AS TotalDeVentas
```

---

### Ejercicio 5 — EXISTS con HAVING

```sql
WHERE EXISTS (
    SELECT 1
    FROM Sales.SalesOrderHeader SH
    WHERE SH.CustomerID = C.CustomerID
    GROUP BY CustomerID
    HAVING COUNT(SalesOrderID) > 20
)
```

Patrón interesante: `EXISTS` valida una condición de agregado. La subquery agrupa por `CustomerID` y solo es `TRUE` si ese cliente tiene más de 20 filas.

**Alternativa equivalente con IN:**
```sql
WHERE C.CustomerID IN (
    SELECT CustomerID FROM Sales.SalesOrderHeader
    GROUP BY CustomerID
    HAVING COUNT(SalesOrderID) > 20
)
```

---

## Optimizaciones detectadas

1. **Ej1:** El triple anidamiento con `IN` puede reemplazarse por un JOIN de 3 tablas — mismo plan en la mayoría de los casos, más legible.
2. **Ej3/4:** La scalar subquery no correlacionada es eficiente, pero si se añaden más columnas del mismo tipo, `OVER()` escala mejor.
3. **Ej5:** `EXISTS` > `IN` cuando la tabla de órdenes es muy grande.

---

## Ver también

- [Teoría Módulo I](../../teoria/markdown/01-subqueries.md)
- [Solución](../resoluciones/practico-01-subqueries-solucion.sql)
- [Cheatsheet subqueries](../../cheatsheets/subqueries-cheatsheet.md)
