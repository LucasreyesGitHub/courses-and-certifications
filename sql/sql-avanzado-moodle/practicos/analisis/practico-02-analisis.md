# Análisis — Práctico 2: DDL + DML

**Módulo:** II — DDL + DML  
**Ejercicios:** 9

---

## Patrón general: BUILD → ENRICH → CLEAN

Todo el práctico sigue una cadena de transformación sobre tablas temporales:

```
Ej1  SELECT INTO #temp                  ← BUILD: materializar datos crudos
Ej2  SELECT INTO #ventasClientesAñoProd ← BUILD: primer resumen (2001)
Ej3  ALTER TABLE ADD ProductName        ← ENRICH: extender estructura
Ej4  SELECT INTO #Productos             ← BUILD: tabla de referencia
Ej5  INSERT INTO #ventasClientesAñoProd ← ENRICH: agregar otros años con nombre
Ej6  UPDATE SET ProductName = '...'     ← ENRICH: poblar NULLs del 2001
Ej7  ALTER TABLE DROP COLUMN ProductId  ← CLEAN: eliminar columna innecesaria
Ej8  DROP TABLE #temp                   ← CLEAN: liberar tabla intermedia
Ej9  DELETE FROM WHERE = '...'         ← CLEAN: eliminar registros no válidos
```

---

## Análisis por ejercicio

### Ej1 — SELECT INTO #temp

`SELECT INTO` crea la tabla e inserta en un solo paso. Sin índices ni constraints.

**Tradeoff vs CREATE TABLE + INSERT:**
- `SELECT INTO` → rápido para prototipar
- `CREATE TABLE` → control de tipos, permite índices y constraints desde el inicio

---

### Ej2 — WHERE en el SELECT INTO

El filtro `WHERE OrderYear = 2001` se aplica **antes** de crear la tabla temporal. Esto es más eficiente que crear la tabla completa y luego filtrar.

---

### Ej3 — ALTER TABLE ADD con NULL implícito

Al agregar la columna `ProductName`, todos los registros existentes quedan con `NULL`. Este es el comportamiento esperado y es el punto que el ejercicio busca verificar.

Si se necesita un default:
```sql
ALTER TABLE #ventasClientesAñoProd
ADD ProductName NVARCHAR(50) DEFAULT 'Sin nombre'
```

---

### Ej5 — INSERT con JOIN entre tablas temporales

```sql
INSERT INTO #ventasClientesAñoProd
SELECT ..., p.ProductName
FROM #temp AS t
JOIN #Productos AS p ON t.ProductID = p.ProductID
WHERE OrderYear != 2001
GROUP BY ...
```

**Punto clave:** las filas insertadas ya tienen `ProductName` porque vienen del JOIN con `#Productos`. Solo las filas del 2001 (insertadas en Ej2) quedan con `NULL`.

---

### Ej6 — UPDATE para rellenar NULLs

```sql
UPDATE #ventasClientesAñoProd
SET ProductName = 'Producto Discontinuado'
WHERE OrderYear = 2001
```

El filtro `WHERE OrderYear = 2001` es el discriminador correcto — exactamente las filas que carecen de `ProductName`.

**Alternativa más robusta:**
```sql
WHERE ProductName IS NULL  -- más exacto que filtrar por año
```

---

### Ej7 y Ej8 — Limpieza de estructura

`ALTER TABLE DROP COLUMN` elimina datos irreversiblemente. `DROP TABLE` libera el espacio en `tempdb`.

**Orden importa:** no se puede eliminar una columna que está en un índice o constraint activo.

---

### Ej9 — DELETE con condición de negocio

```sql
DELETE FROM #ventasClientesAñoProd
WHERE ProductName = 'Producto Discontinuado'
```

El ejercicio usa `ProductName` como marcador de "datos no válidos". En producción, una columna booleana `IsDiscontinued` sería más semántica.

---

## Detección de optimizaciones

| Paso | Optimización posible |
|------|---------------------|
| Ej1 | Agregar índice después del SELECT INTO si la tabla se reutiliza mucho |
| Ej3/6 | Usar `DEFAULT` en el ADD si el valor es siempre conocido |
| Ej6 | Usar `WHERE ProductName IS NULL` en lugar de `WHERE OrderYear = 2001` para mayor robustez |
| Ej8 | `DROP TABLE IF EXISTS` para scripts reutilizables |

---

## Ver también

- [Teoría Módulo II](../../teoria/markdown/02-ddl-dml.md)
- [Solución](../resoluciones/practico-02-ddl-dml-solucion.sql)
- [Cheatsheet DDL + DML](../../cheatsheets/ddl-dml-cheatsheet.md)
