# 00_descarga_estrato.R
# Descarga de los servidores de la Alcaldía de Medellín los datos geográficos del proyecto:
#   1. datos/crudos/barrios.geojson: capa "Límite Administrativo" (barrios, veredas y zonas especiales)
#   2. datos/crudos/estrato_por_unidad.csv: manzanas por estrato dentro de cada unidad
# Se corre una vez (o cuando se quiera actualizar). Requiere conexión a internet y el paquete httr.

library(httr)
library(jsonlite)
library(here)

set_config(user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64)"))  # el servidor rechaza (error 403) solicitudes que no parecen de un navegador

capa_unidades <- "https://www.medellin.gov.co/servidormapas/rest/services/vivienda_ciudad_terri/VA_ConsultaOperadorCatastral_geo/MapServer/20"
capa_estrato  <- "https://www.medellin.gov.co/servidormapas/rest/services/vivienda_ciudad_terri/VC_Catastro_VCT/MapServer/10"


# ---- 1. Capa de barrios y veredas (GeoJSON, MAGNA-SIRGAS geográfico) ----
descargar_capa <- function(intentos = 3) {
  for (i in seq_len(intentos)) {
    resp <- GET(paste0(capa_unidades, "/query"),
                query = list(where = "1=1",
                             outFields = "codigo,nombre,nombre_comuna_corregimiento,subtipo_barriovereda",
                             returnGeometry = "true", outSR = "4686", f = "geojson"))
    texto <- content(resp, as = "text", encoding = "UTF-8")
    capa  <- tryCatch(fromJSON(texto, simplifyVector = FALSE), error = function(e) NULL)
    if (!is.null(capa) && length(capa$features) > 0) return(texto)   # respuesta válida: tiene unidades
    message("Intento ", i, " fallido; el servidor respondió: ", substr(texto, 1, 150))
    Sys.sleep(3)                                                      # espera antes de reintentar
  }
  stop("No se pudo descargar la capa de barrios; el archivo existente no se modificó.")
}

texto_capa <- descargar_capa()
writeLines(texto_capa, here("datos", "crudos", "barrios.geojson"), useBytes = TRUE)
# ---- 2. Estrato: manzanas por estrato dentro de cada unidad ----
# Polígonos de todas las unidades, en el sistema de coordenadas original de la capa
resp_unid <- GET(paste0(capa_unidades, "/query"),
                 query = list(where = "1=1", outFields = "codigo",
                              returnGeometry = "true", f = "json"))
stop_for_status(resp_unid)
unidades <- fromJSON(content(resp_unid, as = "text", encoding = "UTF-8"), simplifyVector = FALSE)

sr <- toJSON(unidades$spatialReference, auto_unbox = TRUE)

consultar_unidad <- function(f) {
  resp <- POST(paste0(capa_estrato, "/query"), encode = "form",
               body = list(geometry      = toJSON(f$geometry, auto_unbox = TRUE, digits = NA),
                           geometryType  = "esriGeometryPolygon",
                           spatialRel    = "esriSpatialRelContains",   # manzanas completamente dentro de la unidad
                           inSR          = sr,
                           where         = "1=1",
                           groupByFieldsForStatistics = "estrato",
                           outStatistics = '[{"statisticType":"count","onStatisticField":"objectid","outStatisticFieldName":"n"}]',
                           f             = "json"))
  stop_for_status(resp)
  r <- fromJSON(content(resp, as = "text", encoding = "UTF-8"))
  codigo <- f$attributes$codigo
  if (length(r$features) == 0) {
    return(data.frame(codigo = codigo, estrato = NA, n_manzanas = 0))   # unidad sin manzanas residenciales
  }
  data.frame(codigo = codigo, estrato = r$features$attributes$estrato, n_manzanas = r$features$attributes$n)
}

resultado <- do.call(rbind, lapply(unidades$features, consultar_unidad))  # una consulta por unidad (tarda 1 o 2 minutos)

write.csv(resultado, here("datos", "crudos", "estrato_por_unidad.csv"), row.names = FALSE)
