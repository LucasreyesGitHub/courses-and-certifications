# Módulo IV — Views (Vistas)

**Curso:** SQL Analytics II — Instituto CPE, Uruguay  
**Dialecto:** T-SQL · Ver equivalencias en [T-SQL vs PostgreSQL](../../cheatsheets/t-sql-vs-postgresql.md)

---

## ¿Qué es una vista?

Una vista es una consulta almacenada con nombre. Se comporta como una tabla virtual: se puede hacer `SELECT`, `JOIN`, `WHERE`, etc. sobre ella, sin repetir la consulta original.

```sql
-- Crear
CREATE VIEW NombreVista AS
SELECT ...

-- Consultar como tabla
SELECT * FROM NombreVista WHERE ...

-- Modificar
ALTER VIEW NombreVista AS
SELECT ...

-- Eliminar
DROP VIEW NombreVista
```

---

## Ejemplo 1 — Vista de resumen por cliente y producto

```sql
CREATE VIEW CustomerProductTotalQty
AS
SELECT soh.CustomerID,
       p.ProductID,
       p.Name,
       SUM(sod.OrderQty) AS Cantidad
FROM Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON soh.SalesOrderID = sod.SalesOrderID
JOIN Production.Product p ON sod.ProductID = p.ProductID
GROUP BY soh.CustomerID, p.ProductID, p.Name
```

Una vez creada, se puede consultar de múltiples formas:

```sql
-- a. Total de unidades del cliente 12001
SELECT SUM(Cantidad) AS TotalCustomer
FROM CustomerProductTotalQty
WHERE CustomerID = 12001

-- b. Top 10 productos por unidades
SELECT TOP 10 ProductID, Name, SUM(Cantidad) AS Total
FROM CustomerProductTotalQty
GROUP BY ProductID, Name
ORDER BY Total DESC

-- c. 5 clientes con menos unidades del producto 711
SELECT TOP 5 CustomerID
FROM CustomerProductTotalQty
WHERE ProductID = 711
ORDER BY Cantidad DESC
```

---

## Ejemplo 2 — Vista que simplifica JOINs frecuentes

```sql
-- El JOIN Employee ↔ Person se repite en muchas queries → abstraerlo en vista
CREATE VIEW EmployeeWithNames
AS
SELECT e.*, p.FirstName, p.LastName
FROM HumanResources.Employee AS e
JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
```

```sql
-- Empleados contratados en 2001
SELECT JobTitle, FirstName, LastName
FROM EmployeeWithNames
WHERE YEAR(HireDate) = 2001

-- 5 empleados más longevos
SELECT TOP 5 FirstName, LastName, BirthDate
FROM EmployeeWithNames
ORDER BY BirthDate

-- 10 empleados más nuevos
SELECT TOP 10 FirstName, LastName, HireDate
FROM EmployeeWithNames
ORDER BY HireDate DESC
```

---

## Ejemplo 3 — ALTER VIEW

```sql
ALTER VIEW EmployeeWithNames
AS
SELECT e.JobTitle, e.BirthDate, e.HireDate,
       p.Title, p.FirstName, p.MiddleName, p.LastName
FROM HumanResources.Employee AS e
JOIN Person.Person AS p ON e.BusinessEntityID = p.BusinessEntityID
```

```sql
-- Managers
SELECT Title, FirstName, MiddleName, LastName, JobTitle
FROM EmployeeWithNames
WHERE JobTitle LIKE '%Manager%'

-- Sin segundo nombre
SELECT FirstName, LastName, JobTitle
FROM EmployeeWithNames
WHERE MiddleName IS NULL
```

---

## Cuándo usar vistas

| Caso de uso | ¿Vista? |
|-------------|---------|
| Simplificar JOINs frecuentes | Sí |
| Exponer solo columnas específicas (seguridad) | Sí |
| Abstraer lógica de negocio compleja | Sí |
| Reemplazar lógica que cambia frecuentemente | Sí |
| Resultado que necesita parámetros dinámicos | No → usar TVF |
| Resultado muy grande que se consulta pocas veces | Considerar indexed view |

---

## Vistas actualizables

Una vista es actualizable (INSERT/UPDATE/DELETE) si:
- No usa `GROUP BY`, `HAVING`, `DISTINCT`
- No tiene funciones de agregado
- No usa `UNION`
- Referencia una sola tabla base

---

## Equivalente en PostgreSQL

```sql
-- CREATE VIEW: sintaxis idéntica
CREATE VIEW customer_product_qty AS
SELECT ...

-- ALTER VIEW en PostgreSQL se hace con CREATE OR REPLACE VIEW
CREATE OR REPLACE VIEW employee_with_names AS
SELECT ...

-- DROP VIEW: idéntico
DROP VIEW IF EXISTS employee_with_names
```

> T-SQL tiene `ALTER VIEW`; PostgreSQL usa `CREATE OR REPLACE VIEW`.

---

## Tips

- Nombrar vistas con sustantivos descriptivos, sin prefijo `v_` (redundante)
- No usar `SELECT *` en la definición de la vista: si cambia la tabla base, la vista queda desactualizada
- Documentar las vistas con un comentario de propósito al crearlas
- En SQL Server, usar `WITH SCHEMABINDING` si la vista no debe romperse cuando se modifican las tablas base

---

## Ver también

- [Práctico 4 — Enunciado](../../practicos/enunciados/practico-04-views.pdf)
- [Práctico 4 — Solución](../../practicos/resoluciones/practico-04-views-solucion.sql)
- [Práctico 4 — Análisis](../../practicos/analisis/practico-04-analisis.md)
