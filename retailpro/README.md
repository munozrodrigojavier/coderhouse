# Proyecto RetailPro — Data Analytics (Coderhouse)

Sistema de análisis de ventas para **RetailPro**, una distribuidora de tecnología.
El proyecto recorre el camino completo del dato: del modelo relacional en SQL Server
al dashboard ejecutivo en Power BI.

**Pregunta de negocio que guía el proyecto:** ¿por qué cayeron las ventas de la
categoría Notebooks a clientes minoristas en el último trimestre, y qué territorios
concentran esa caída?

## Estructura del repositorio

```
retailpro/
├── ventas_tech_db.sql          M3 — creación de la base y carga inicial
├── m4_consultas_negocio.sql    M4 — métricas, rankings y comparativas
├── m5_consultas_joins.sql      M5 — vista enriquecida con JOINs y UNION ALL
└── Munoz_Rodrigo_Checkpoint2.pbix   M6/M8 — ETL, modelo y medidas DAX
```

## Modelo de datos

```
categorias (1) ── (N) productos (1) ── (N) ventas (N) ── (1) clientes
```

`ventas` es la tabla de hechos; el resto son dimensiones. Las claves foráneas
garantizan que no se registre una venta de un producto o un cliente inexistente.

## Herramientas

| Etapa | Herramienta |
|---|---|
| Base de datos | SQL Server (T-SQL), SQL Server Management Studio 22 |
| ETL | Power Query (lenguaje M) |
| Modelo y medidas | Power BI Desktop, DAX |
| Control de versiones | Git / GitHub |

## Cómo ejecutar los scripts

Requisitos: SQL Server 2016 o superior y SSMS.

1. Abrir `ventas_tech_db.sql` en SSMS y ejecutarlo completo (F5). Crea la base
   `ventas_tech_db`, sus cuatro tablas y los datos iniciales. El script es
   repetible: borra y vuelve a crear las tablas en cada ejecución.
2. Ejecutar `m4_consultas_negocio.sql` para las métricas de negocio: resumen
   mensual, ranking de productos, clientes recurrentes y comparación contra el
   promedio mensual.
3. Ejecutar `m5_consultas_joins.sql` para la vista enriquecida. Además de las
   consultas, crea la vista `vw_ventas_detalle`, que es la fuente de datos que
   consume Power BI.

Los scripts están escritos en T-SQL. Para ejecutarlos en PostgreSQL o MySQL hay
que adaptar `TOP` (por `LIMIT`), `MONTH()` / `YEAR()` (por `EXTRACT`) e `ISNULL`
(por `COALESCE`).

## Cómo abrir el informe de Power BI

Requisitos: Power BI Desktop (gratuito).

1. Abrir `Munoz_Rodrigo_Checkpoint2.pbix`.
2. El archivo trae los datos importados, así que se puede explorar sin conexión
   a la base. Para actualizarlo hay que corregir la ruta del origen en
   Transformar datos → Configuración del origen de datos.
3. La página **Validación** contiene la matriz que verifica las medidas de
   inteligencia temporal (Ventas YTD, Ventas LY y % Crecimiento Anual).

## Medidas DAX principales

| Medida | Qué calcula |
|---|---|
| Total Ventas | Facturación total del período seleccionado |
| Ventas Online | Facturación del canal Online (CALCULATE) |
| Ventas YTD | Acumulado del año en curso (TOTALYTD) |
| Ventas LY | Mismo período del año anterior (SAMEPERIODLASTYEAR) |
| % Crecimiento Anual | Variación contra el año anterior (VAR + DIVIDE) |

## Limitaciones conocidas

- El dataset de ejemplo cubre de enero de 2023 a julio de 2024. La comparación
  anual completa contra 2023 arroja un −34,6 % que refleja ese corte de datos, no
  una caída real del negocio: la medida es válida en la comparación mes a mes.
- Dos registros del origen llegan con datos faltantes (un email y una ciudad de
  cliente). Se conservan con la etiqueta "Sin dato" en lugar de eliminarse, para
  no perder las ventas asociadas.

## Autor

Rodrigo Muñoz — Carrera de Data Analytics, Coderhouse.
