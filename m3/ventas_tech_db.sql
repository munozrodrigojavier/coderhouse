/* =====================================================================
   Proyecto RetailPro — Pre-entrega Módulo 3
   Checkpoint: Script SQL de Ingeniería de Datos
   Base de datos: ventas_tech_db

   Modelo:
     categorias (1) ── (N) productos (1) ── (N) ventas (N) ── (1) clientes
   ===================================================================== */


/* ---------------------------------------------------------------------
   0. CREACIÓN DE LA BASE DE DATOS
   Solo se crea si todavía no existe.
   --------------------------------------------------------------------- */
IF DB_ID('ventas_tech_db') IS NULL
    CREATE DATABASE ventas_tech_db;
GO

USE ventas_tech_db;
GO


/* ---------------------------------------------------------------------
   1. LIMPIEZA (DROP TABLES)
   Orden inverso a las dependencias: primero las tablas que tienen FK
   (ventas, productos) y al final las referenciadas (clientes, categorias).
   --------------------------------------------------------------------- */
DROP TABLE IF EXISTS ventas;
DROP TABLE IF EXISTS productos;
DROP TABLE IF EXISTS clientes;
DROP TABLE IF EXISTS categorias;
GO


/* ---------------------------------------------------------------------
   2. DEFINICIÓN DEL ESQUEMA (DDL) + RESTRICCIONES DE INTEGRIDAD
   Primero las dimensiones (sin dependencias), al final la tabla de hechos.
   --------------------------------------------------------------------- */

-- Dimensión: categorías de producto.
-- Tabla separada para cumplir 3NF: el nombre de la categoría no se repite
-- como texto en cada producto.
CREATE TABLE categorias (
    id_categoria      INT           NOT NULL,
    nombre_categoria  VARCHAR(50)   NOT NULL,
    descripcion       VARCHAR(200)  NULL,
    CONSTRAINT pk_categorias PRIMARY KEY (id_categoria)
);

-- Dimensión: clientes (quiénes compran).
CREATE TABLE clientes (
    id_cliente        INT           NOT NULL,
    nombre            VARCHAR(100)  NOT NULL,
    email             VARCHAR(100)  NULL,
    ciudad            VARCHAR(50)   NULL,
    fecha_registro    DATE          NOT NULL,
    CONSTRAINT pk_clientes       PRIMARY KEY (id_cliente),
    CONSTRAINT uq_clientes_email UNIQUE (email)
);

-- Dimensión: productos (qué se vende).
-- Nota: la consigna indica TINYINT(1), que es sintaxis de MySQL. En
-- SQL Server el tipo equivalente a un booleano es BIT (1 = activo,
-- 0 = inactivo), así que los INSERT de la consigna funcionan igual.
CREATE TABLE productos (
    id_producto       INT            NOT NULL,
    nombre_producto   VARCHAR(100)   NOT NULL,
    id_categoria      INT            NOT NULL,
    precio            DECIMAL(10,2)  NOT NULL,
    stock             INT            NULL CONSTRAINT df_productos_stock  DEFAULT 0,
    activo            BIT            NULL CONSTRAINT df_productos_activo DEFAULT 1,
    CONSTRAINT pk_productos PRIMARY KEY (id_producto),
    CONSTRAINT fk_productos_categorias
        FOREIGN KEY (id_categoria) REFERENCES categorias (id_categoria),
    CONSTRAINT ck_productos_precio CHECK (precio >= 0),
    CONSTRAINT ck_productos_stock  CHECK (stock >= 0)
);

-- Hechos: ventas (cada fila es una transacción).
-- precio_unitario se guarda en la venta (y no se toma de productos) porque
-- registra el precio al momento de vender: si mañana cambia el precio de
-- lista, el histórico de facturación no se altera.
CREATE TABLE ventas (
    id_venta          INT            NOT NULL,
    id_cliente        INT            NOT NULL,
    id_producto       INT            NOT NULL,
    cantidad          INT            NOT NULL,
    precio_unitario   DECIMAL(10,2)  NOT NULL,
    fecha_venta       DATE           NOT NULL,
    CONSTRAINT pk_ventas PRIMARY KEY (id_venta),
    CONSTRAINT fk_ventas_clientes
        FOREIGN KEY (id_cliente)  REFERENCES clientes (id_cliente),
    CONSTRAINT fk_ventas_productos
        FOREIGN KEY (id_producto) REFERENCES productos (id_producto),
    CONSTRAINT ck_ventas_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_ventas_precio   CHECK (precio_unitario >= 0)
);
GO


/* ---------------------------------------------------------------------
   3. CARGA INICIAL DE DATOS (DML)
   Mismo orden lógico que el DDL: categorias y clientes antes que
   productos y ventas, para que las FK encuentren su referencia.
   Las fechas van en formato 'AAAA-MM-DD', que SQL Server interpreta
   igual sin importar la configuración regional del equipo.
   --------------------------------------------------------------------- */

-- categorias — 4 registros
INSERT INTO categorias VALUES (1, 'Computación',    'Laptops, PCs y monitores');
INSERT INTO categorias VALUES (2, 'Accesorios',     'Periféricos y complementos');
INSERT INTO categorias VALUES (3, 'Audio',          'Auriculares y parlantes');
INSERT INTO categorias VALUES (4, 'Almacenamiento', 'Discos y memorias');

-- clientes — 5 registros
INSERT INTO clientes VALUES (1, 'María López',  'maria@mail.com',  'Buenos Aires', '2024-01-05');
INSERT INTO clientes VALUES (2, 'Carlos Ruiz',  'carlos@mail.com', 'Córdoba',      '2024-01-10');
INSERT INTO clientes VALUES (3, 'Ana Gómez',    'ana@mail.com',    'Rosario',      '2024-02-01');
INSERT INTO clientes VALUES (4, 'Pedro Sanz',   'pedro@mail.com',  'Mendoza',      '2024-02-15');
INSERT INTO clientes VALUES (5, 'Laura Torres', 'laura@mail.com',  'Tucumán',      '2024-03-01');

-- productos — 6 registros
INSERT INTO productos VALUES (1, 'Laptop Pro 15',      1, 1200.00, 15, 1);
INSERT INTO productos VALUES (2, 'Mouse Inalámbrico',  2,   28.00, 80, 1);
INSERT INTO productos VALUES (3, 'Monitor 4K 27"',     1,  450.00, 12, 1);
INSERT INTO productos VALUES (4, 'Auriculares BT Pro', 3,  120.00, 35, 1);
INSERT INTO productos VALUES (5, 'SSD Externo 1TB',    4,  130.00, 18, 1);
INSERT INTO productos VALUES (6, 'Teclado Mecánico',   2,   95.00, 40, 1);

-- ventas — 10 registros
INSERT INTO ventas VALUES ( 1, 1, 1, 2, 1200.00, '2024-03-05');
INSERT INTO ventas VALUES ( 2, 2, 2, 5,   28.00, '2024-03-06');
INSERT INTO ventas VALUES ( 3, 3, 3, 1,  450.00, '2024-03-07');
INSERT INTO ventas VALUES ( 4, 1, 4, 2,  120.00, '2024-03-08');
INSERT INTO ventas VALUES ( 5, 4, 5, 3,  130.00, '2024-03-10');
INSERT INTO ventas VALUES ( 6, 2, 6, 4,   95.00, '2024-03-11');
INSERT INTO ventas VALUES ( 7, 5, 1, 1, 1200.00, '2024-03-12');
INSERT INTO ventas VALUES ( 8, 3, 2, 8,   28.00, '2024-03-13');
INSERT INTO ventas VALUES ( 9, 4, 4, 1,  120.00, '2024-03-14');
INSERT INTO ventas VALUES (10, 5, 3, 2,  450.00, '2024-03-15');
GO


/* ---------------------------------------------------------------------
   4. VERIFICACIÓN DE INTEGRIDAD
   --------------------------------------------------------------------- */

-- Contenido de cada tabla
SELECT * FROM categorias;
SELECT * FROM clientes;
SELECT * FROM productos;
SELECT * FROM ventas;

-- Conteo esperado: categorias 4 | clientes 5 | productos 6 | ventas 10
SELECT 'categorias' AS tabla, COUNT(*) AS filas FROM categorias
UNION ALL SELECT 'clientes',  COUNT(*) FROM clientes
UNION ALL SELECT 'productos', COUNT(*) FROM productos
UNION ALL SELECT 'ventas',    COUNT(*) FROM ventas;

-- Prueba de integridad referencial (dejar comentada).
-- Si se descomenta, debe FALLAR (Msg 547) porque el producto 99 no existe:
-- INSERT INTO ventas VALUES (11, 1, 99, 1, 10.00, '2024-03-16');

-- (En el Módulo 5 se cruzarán estas tablas con JOIN para ver cada venta
--  junto al nombre del cliente y del producto.)
GO
