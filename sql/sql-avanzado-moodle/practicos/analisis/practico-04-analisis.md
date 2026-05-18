# Análisis — Práctico 4: Views

**Módulo:** IV — Views  
**Ejercicios:** 3 (con sub-items)

---

## Vistas creadas

| Vista | Propósito | Tablas base |
|-------|-----------|-------------|
| `CustomerProductTotalQty` | Resumen de unidades por cliente/producto | SalesOrderHeader, SalesOrderDetail, Product |
| `EmployeeWithNames` (v1) | JOIN simplificado Employee + Person (todos los campos) | Employee, Person |
| `EmployeeWithNames` (v2 — ALTER) | Solo campos seleccionados de Employee + Person | Employee, Person |

---

## Análisis por ejercicio

### Ej1 — CustomerProductTotalQty como capa de abstracción

```sql
CREATE VIEW CustomerProductTotalQty AS
SELECT soh.CustomerID, p.ProductID, p.Name, SUM(sod.OrderQty) AS Cantidad
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY soh.CustomerID, p.ProductID, p.Name
```

**Por qué es útil:** el JOIN de 3 tablas con GROUP BY es costoso de re-escribir. La vista lo encapsula y permite queries simples sobre el resultado.

**3 queries diferentes sobre la misma vista:**
- `WHERE CustomerID = 12001` → filter
- `GROUP BY ProductID, Name` → reagrupar el resultado de la vista
- `WHERE ProductID = 711 ORDER BY Cantidad DESC` → sort y filter

Esto demuestra la **reutilización** como ventaja principal de las vistas.

---

### Ej2 — EmployeeWithNames (v1): `SELECT e.*`

```sql
SELECT e.*, p.FirstName, p.LastName
FROM HumanResources.Employee AS e
JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
```

**Problema de `SELECT *` en vistas:** si se agrega una columna a `Employee`, la vista **no se actualiza automáticamente** — muestra las columnas que existían al momento de la creación. Es necesario `ALTER VIEW` o `sp_refreshview`.

**Regla:** No usar `SELECT *` en definiciones de vistas de producción.

---

### Ej3 — ALTER VIEW para cambiar la estructura expuesta

```sql
ALTER VIEW EmployeeWithNames AS
SELECT e.JobTitle, e.BirthDate, e.HireDate,
       p.Title, p.FirstName, p.MiddleName, p.LastName
```

`ALTER VIEW` reemplaza la definición completa. No es incremental.

**Impacto:** si alguna query depende de columnas que ya no existen en la nueva definición, fallará.

---

## Patrón detectado: vista como contrato de interfaz

Las vistas actúan como contratos entre la lógica de negocio y las tablas físicas:

```
Queries de negocio
       ↓
  [Vista: EmployeeWithNames]
       ↓
Employee JOIN Person
```

Si el schema físico cambia (ej: se mueve `FirstName` a otra tabla), solo hay que actualizar la vista — las queries de negocio no cambian.

---

## Diferencia T-SQL vs PostgreSQL para ALTER VIEW

```sql
-- T-SQL: ALTER VIEW existe
ALTER VIEW dbo.MiVista AS SELECT ...

-- PostgreSQL: no existe ALTER VIEW para redefinir el SELECT
-- Se usa CREATE OR REPLACE VIEW
CREATE OR REPLACE VIEW mi_vista AS SELECT ...
```

---

## Ver también

- [Teoría Módulo IV](../../teoria/markdown/04-views.md)
- [Solución](../resoluciones/practico-04-views-solucion.sql)
