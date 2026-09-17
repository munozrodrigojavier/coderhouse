/* =====================================================================
   Proyecto RetailPro — Pre-entrega Módulo 4
   Consultas SQL de negocio: extrayendo métricas clave
   Base de datos: ventas_tech_db (creada en M3)
   Motor: SQL Server (SQL Server Management Studio)
   Autor: Rodrigo Muñoz

   Alcance: solo tabla ventas (id_cliente, id_producto, cantidad,
   precio_unitario, fecha_venta). Los nombres de clientes y productos
   se incorporan con JOIN en el Módulo 5.

   Nota sobre el motor: la consigna menciona EXTRACT(MONTH FROM ...) y
   LIMIT, que son sintaxis de PostgreSQL/MySQL. En SQL Server se usan sus
   equivalentes: MONTH(fecha_venta) y TOP 5. El resultado es el mismo.
   ===================================================================== */

USE ventas_tech_db;
GO


/* ---------------------------------------------------------------------
   Consulta 1 — Resumen ejecutivo mensual
   Total facturado, cantidad de pedidos y ticket promedio por mes.
   Se agrupa también por año para que, cuando haya más de un año de
   datos, marzo 2024 y marzo 2025 no se sumen juntos.
   --------------------------------------------------------------------- */
SELECT
    YEAR(fecha_venta)                                    AS anio,
    MONTH(fecha_venta)                                   AS mes,
    SUM(cantidad * precio_unitario)                      AS total_facturado,
    COUNT(*)                                             AS cantidad_pedidos,
    CAST(SUM(cantidad * precio_unitario) / COUNT(*)
         AS DECIMAL(10,2))                               AS ticket_promedio
FROM ventas
GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
ORDER BY anio, mes;


/* ---------------------------------------------------------------------
   Consulta 2 — Ranking de productos
   Top 5 de productos por total facturado, con unidades vendidas.
   (En SQL Server, TOP 5 cumple la función de LIMIT 5.)
   --------------------------------------------------------------------- */
SELECT TOP 5
    id_producto,
    SUM(cantidad)                    AS unidades_vendidas,
    SUM(cantidad * precio_unitario)  AS total_facturado
FROM ventas
GROUP BY id_producto
ORDER BY total_facturado DESC;


/* ---------------------------------------------------------------------
   Consulta 3 — Clientes recurrentes
   Clientes con más de un pedido, cantidad de pedidos y total gastado.
   HAVING filtra después de agrupar (WHERE no puede usar COUNT).
   --------------------------------------------------------------------- */
SELECT
    id_cliente,
    COUNT(*)                         AS cantidad_pedidos,
    SUM(cantidad * precio_unitario)  AS total_gastado
FROM ventas
GROUP BY id_cliente
HAVING COUNT(*) > 1
ORDER BY total_gastado DESC;


/* ---------------------------------------------------------------------
   Consulta 4 — Meses por encima / por debajo del promedio
   1) La CTE ventas_mensuales calcula el total facturado de cada mes.
   2) Una subconsulta obtiene el promedio de esos totales mensuales.
   3) CASE WHEN compara cada mes contra ese promedio.
   Se agrega la etiqueta 'En el promedio' para el caso de igualdad
   (por ejemplo, cuando hay un solo mes, su total ES el promedio).
   --------------------------------------------------------------------- */
WITH ventas_mensuales AS (
    SELECT
        YEAR(fecha_venta)                AS anio,
        MONTH(fecha_venta)               AS mes,
        SUM(cantidad * precio_unitario)  AS total_facturado
    FROM ventas
    GROUP BY YEAR(fecha_venta), MONTH(fecha_venta)
)
SELECT
    anio,
    mes,
    total_facturado,
    CAST((SELECT AVG(total_facturado) FROM ventas_mensuales)
         AS DECIMAL(10,2))               AS promedio_mensual,
    CASE
        WHEN total_facturado > (SELECT AVG(total_facturado) FROM ventas_mensuales)
            THEN 'Por encima'
        WHEN total_facturado < (SELECT AVG(total_facturado) FROM ventas_mensuales)
            THEN 'Por debajo'
        ELSE 'En el promedio'
    END                                  AS comparacion_promedio
FROM ventas_mensuales
ORDER BY anio, mes;
GO


/* =====================================================================
   Hallazgos (sobre los datos cargados en M3: 10 ventas, marzo 2024)
   ===================================================================== */

-- Hallazgo 1 — Concentración en un producto:
--   El producto 1 (id 1) facturó $3.600 de un total de $6.444, es decir
--   el 55,9% de la facturación del período con solo 3 unidades. Sumando
--   el producto 3 ($1.350), dos productos explican el 76,8% de las
--   ventas: el negocio depende fuertemente de los artículos de mayor
--   precio y cualquier caída en ellos impacta de lleno en el total.

-- Hallazgo 2 — Volumen no es igual a facturación:
--   El producto 2 es el más vendido en unidades (13 de 29, el 44,8%)
--   pero aporta solo $364 (5,6% de la facturación) y queda último en el
--   Top 5. Mirar solo unidades llevaría a priorizar el producto
--   equivocado; conviene analizar margen (costo) en los próximos módulos.

-- Hallazgo 3 — Cartera recurrente pero concentrada:
--   Los 5 clientes realizaron 2 pedidos cada uno (100% recurrencia), con
--   un ticket promedio de $644,40. Sin embargo, los clientes 1 ($2.640) y
--   5 ($2.100) concentran el 73,6% de lo facturado: solo perder al cliente 1
--   reduciría las ventas un 41%.

-- Limitación de los datos:
--   Todas las ventas son de marzo 2024, por lo que la Consulta 4 devuelve
--   un único mes igual al promedio ('En el promedio'). La lógica queda
--   lista para cuando la base tenga varios meses de historia.
