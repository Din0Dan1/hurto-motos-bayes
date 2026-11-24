# Hurto de motos y estrato socioeconómico en Medellín

Trabajo final de Estadística Bayesiana. Se estudia cómo varía el número de hurtos de moto entre las unidades territoriales de Medellín (barrios, veredas y zonas especiales) según su estrato socioeconómico, y si existe una estructura espacial en los robos, con datos de 2012 a 2022.

## Estructura del proyecto

```
hurto-motos-bayes/
├── hurto-motos-bayes.Rproj     ← abrir siempre el proyecto desde aquí
├── datos/
│   ├── crudos/                 ← datos originales (no están en GitHub, ver abajo)
│   └── procesados/             ← generados por los documentos (no están en GitHub)
├── scripts/
│   ├── 00_descarga_estrato.R   ← descarga la capa de barrios y el estrato por unidad
│   ├── 01_limpieza.qmd         ← limpieza de la base de hurtos
│   ├── 02_unidad_analisis.qmd  ← conteos por unidad y año
│   ├── 03_estrato.qmd          ← estrato de cada unidad
│   └── 04_descriptivo.qmd      ← análisis descriptivo, mapa y dependencia espacial
├── resultados/
│   └── figuras/                ← figuras hechas fuera de R (mapa de ArcGIS)
├── exploración/                ← análisis exploratorios previos, no forman parte del flujo
├── stan/                       ← modelos (pendiente)
└── articulo/                   ← documento final (pendiente)
```

## Requisitos

- R y RStudio, con Quarto (viene incluido en las versiones recientes de RStudio).
- Paquetes de R. Se instalan una sola vez desde la consola:

```r
install.packages(c("dplyr", "tidyr", "here", "jsonlite", "ggplot2",
                   "sf", "spdep", "httr", "knitr", "rmarkdown"))
```

## Datos de entrada

Los datos crudos no están en GitHub por su tamaño. Deben quedar en `datos/crudos/` con exactamente estos nombres:

| Archivo | Qué es | Cómo obtenerlo |
|---|---|---|
| `hurto_de_moto.csv` | Registros de hurto de motos, MEData (Alcaldía de Medellín) | Pedirlo por Drive, o descargarlo de https://medata.app.medellin.gov.co/dataset/1-027-23-000014 y renombrarlo |
| `estratos.json` | Manzanas por estrato y código catastral de barrio (solo se usa para validar el estrato en `03`) | Pedirlo por Drive |
| `barrios.geojson` | Capa oficial de barrios, veredas y zonas especiales | Lo descarga `00_descarga_estrato.R`, o pedirlo por Drive |
| `estrato_por_unidad.csv` | Manzanas por estrato dentro de cada unidad | Lo descarga `00_descarga_estrato.R`, o pedirlo por Drive |

`00_descarga_estrato.R` consulta los servidores de la Alcaldía, así que necesita internet. Se corre completo con el botón **Source** de RStudio (no línea por línea) y tarda uno o dos minutos. Si los servidores fallan, el script se detiene sin dañar los archivos existentes; en ese caso, pedir los archivos por Drive.

## Cómo ejecutar el proyecto

1. Abrir `hurto-motos-bayes.Rproj` (así todas las rutas funcionan en cualquier computador).
2. Verificar que los cuatro archivos de datos estén en `datos/crudos/`.
3. Renderizar los documentos **en este orden**, con el botón **Render** de RStudio:

| Orden | Documento | Lee | Produce |
|---|---|---|---|
| 1 | `01_limpieza.qmd` | `hurto_de_moto.csv` | `datos/procesados/hurtos_limpio.csv` |
| 2 | `02_unidad_analisis.qmd` | `hurtos_limpio.csv`, `barrios.geojson` | `datos/procesados/conteos_barrio_anio.csv` |
| 3 | `03_estrato.qmd` | `conteos_barrio_anio.csv`, `estrato_por_unidad.csv`, `estratos.json` | `datos/procesados/tabla_analisis.csv` |
| 4 | `04_descriptivo.qmd` | `hurtos_limpio.csv`, `tabla_analisis.csv`, `barrios.geojson` | `resultados/mapa_robos.gpkg` |

Cada documento usa lo que produjo el anterior. Si se cambia uno, hay que volver a renderizar ese y todos los siguientes.

Cada documento genera un `.html` con el informe. Los `.html`, los datos procesados y la capa `.gpkg` no se suben a GitHub porque se regeneran al renderizar.

## Reglas de trabajo

- **Los datos crudos no se modifican.** Todo cambio se hace en código y se guarda en `datos/procesados/`.
- **Rutas relativas con `here()`**, nunca rutas como `C:/Users/...`.
- **Cada decisión de limpieza se documenta** en el propio documento con el esquema pregunta → evidencia → decisión.
- **Git:** hacer *Pull* antes de empezar a trabajar y *Commit* + *Push* al terminar. Para evitar conflictos, no editar el mismo documento al mismo tiempo.
- **El mapa** (`resultados/figuras/RobosAniovs_estratos.png`) se hace en ArcGIS a partir de `resultados/mapa_robos.gpkg`. Como no se puede regenerar con código, la imagen sí se sube a GitHub.
