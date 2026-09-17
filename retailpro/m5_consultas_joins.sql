/* =====================================================================
   Proyecto RetailPro — Pre-entrega Módulo 5
   Consultas con JOINs: cruzando tablas para enriquecer el análisis
   Base de datos: ventas_tech_db (creada en M3)
   Motor: SQL Server (SQL Server Management Studio)
   Autor: Rodrigo Muñoz

   Esquema usado (M3):
     categorias (1) ── (N) productos (1) ── (N) ventas (N) ── (1) clientes

   Dimensiones para agrupar y filtrar en Power BI:
     - Geográfica: clientes.ciudad
     - Producto:   categorias.nombre_categoria
   ===================================================================== */

USE ventas_tech_db;
GO


/* ---------------------------------------------------------------------
   Datos de prueba para las Consultas 2 y 3
   Con los datos de M3 todos los clientes compraron y todos los productos
   se vendieron, así que los LEFT JOIN devolverían 0 filas y no se podría
   comprobar que funcionan. Se agregan un cliente y un producto SIN
   ventas. IF NOT EXISTS evita errores de clave duplicada si el script
   se ejecuta más de una vez. No se agregan ventas: los resultados de M4
   no cambian.
   --------------------------------------------------------------------- */
IF NOT EXISTS (SELECT 1 FROM clientes WHERE id_cliente = 6)
    INSERT INTO clientes VALUES (6, 'Sofía Díaz', 'sofia@mail.com', 'Salta', '2024-03-20');

IF NOT EXISTS (SELECT 1 FROM productos WHERE id_producto = 7)
    INSERT INTO productos VALUES (7, 'Webcam Full HD', 2, 65.00, 25, 1);
GO


/* ---------------------------------------------------------------------
   Consulta 1 — Vista base del proyecto (INNER JOIN)
   Una fila por venta con los datos de cliente, producto y categoría.
   INNER JOIN deja solo las ventas que tienen cliente y producto válidos
   (las FK de M3 garantizan que siempre existan).
   --------------------------------------------------------------------- */
SELECT
    v.id_venta,
    v.fecha_venta,
    c.id_cliente,
    c.nombre                              AS cliente,
    c.ciudad,
    p.nombre_producto                     AS producto,
    cat.nombre_categoria                  AS categoria,
    v.cantidad,
    v.precio_unitario,
    v.cantidad * v.precio_unitario        AS total_venta
FROM ventas AS v
INNER JOIN clientes   AS c   ON v.id_cliente   = c.id_cliente
INNER JOIN productos  AS p   ON v.id_producto  = p.id_producto
INNER JOIN categorias AS cat ON p.id_categoria = cat.id_categoria
ORDER BY v.fecha_venta, v.id_venta;
GO

-- La misma consulta guardada como vista, para conectarla directamente
-- desde Power BI en los próximos módulos (Obtener datos → SQL Server →
-- vw_ventas_detalle). CREATE OR ALTER permite re-ejecutar el script.
CREATE OR ALTER VIEW vw_ventas_detalle AS
SELECT
    v.id_venta,
    v.fecha_venta,
    c.id_cliente,
    c.nombre                              AS cliente,
    c.ciudad,
    p.nombre_producto                     AS producto,
    cat.nombre_categoria                  AS categoria,
    v.cantidad,
    v.precio_unitario,
    v.cantidad * v.precio_unitario        AS total_venta
FROM ventas AS v
INNER JOIN clientes   AS c   ON v.id_cliente   = c.id_cliente
INNER JOIN productos  AS p   ON v.id_producto  = p.id_producto
INNER JOIN categorias AS cat ON p.id_categoria = cat.id_categoria;
GO


/* ---------------------------------------------------------------------
   Consulta 2 — Clientes sin ventas (LEFT JOIN)
   LEFT JOIN conserva TODOS los clientes; los que no tienen ventas
   quedan con las columnas de ventas en NULL, y WHERE ... IS NULL
   aísla exactamente esos casos.
   Resultado esperado: Sofía Díaz (registrada el 2024-03-20).
   --------------------------------------------------------------------- */
SELECT
    c.nombre,
    c.email,
    c.fecha_registro
FROM clientes AS c
LEFT JOIN ventas AS v ON c.id_cliente = v.id_cliente
WHERE v.id_venta IS NULL
ORDER BY c.fecha_registro;


/* ---------------------------------------------------------------------
   Consulta 3 — Productos sin ventas (LEFT JOIN)
   Mismo criterio: todos los productos del catálogo, y se filtran los
   que no aparecen en ventas. La categoría se trae con INNER JOIN porque
   todo producto tiene categoría obligatoria (NOT NULL + FK).
   Resultado esperado: Webcam Full HD (Accesorios, $65,00).
   --------------------------------------------------------------------- */
SELECT
    p.nombre_producto,
    cat.nombre_categoria                  AS categoria,
    p.precio
FROM productos AS p
INNER JOIN categorias AS cat ON p.id_categoria = cat.id_categoria
LEFT  JOIN ventas     AS v   ON p.id_producto  = v.id_producto
WHERE v.id_venta IS NULL
ORDER BY p.nombre_producto;


/* ---------------------------------------------------------------------
   Consulta 4 — Consolidado por canal (UNION ALL)
   Criterio: dos sucursales según la ciudad del cliente.
     - 'Sucursal Buenos Aires' → clientes de Buenos Aires
     - 'Sucursal Interior'     → clientes del resto del país
   La columna canal NO existe en las tablas: se crea como texto fijo en
   cada SELECT. Ambos SELECT devuelven las mismas 4 columnas, en el
   mismo orden y con tipos compatibles.

   Por qué UNION ALL y no UNION: UNION elimina filas idénticas, y dos
   ventas distintas pueden coincidir en fecha, total y canal. Con UNION
   se perdería una de ellas y el total quedaría mal. UNION ALL conserva
   cada venta una sola vez.

   Cuidado con los NULL: si un cliente tuviera ciudad NULL, la condición
   ciudad <> 'Buenos Aires' daría "desconocido" y esa venta no entraría
   en ningún canal. ISNULL(c.ciudad, '') la manda al Interior para que
   ninguna venta quede afuera.
   Resultado esperado: Buenos Aires 2 ventas / $2.640 — Interior 8 ventas / $3.804.
   --------------------------------------------------------------------- */
SELECT
    consolidado.canal,
    COUNT(*)                    AS cantidad_ventas,
    SUM(consolidado.total)      AS total_facturado
FROM (
    SELECT
        v.id_venta,
        v.fecha_venta                     AS fecha,
        v.cantidad * v.precio_unitario    AS total,
        'Sucursal Buenos Aires'           AS canal
    FROM ventas AS v
    INNER JOIN clientes AS c ON v.id_cliente = c.id_cliente
    WHERE c.ciudad = 'Buenos Aires'

    UNION ALL

    SELECT
        v.id_venta,
        v.fecha_venta                     AS fecha,
        v.cantidad * v.precio_unitario    AS total,
        'Sucursal Interior'               AS canal
    FROM ventas AS v
    INNER JOIN clientes AS c ON v.id_cliente = c.id_cliente
    WHERE ISNULL(c.ciudad, '') <> 'Buenos Aires'
) AS consolidado
GROUP BY consolidado.canal
ORDER BY total_facturado DESC;
GO


/* =====================================================================
   Lectura de resultados (conexión con el brief de M1)
   ===================================================================== */
-- 1) La vista base (Consulta 1) devuelve las 10 ventas con cliente,
--    ciudad, producto y categoría: es la tabla que alimentará Power BI.
-- 2) CRM: Sofía Díaz se registró el 20/03/2024 y todavía no compró.
--    Es candidata a una acción de primera compra.
-- 3) Producto: la Webcam Full HD está en catálogo, con 25 unidades de
--    stock inmovilizado y sin ventas ("rotación de productos", M1).
-- 4) Territorio: el Interior factura $3.804 (59%) contra $2.640 (41%)
--    de Buenos Aires, pero Buenos Aires lo logra con un solo cliente
--    y solo 2 ventas: ticket promedio $1.320 vs $475,50 del Interior.
