#01_limpieza.R
#Entrada: datos/crudos/hurto_de_moto.csv
#Salida: datos/procesados/hurtos_limpio.csv


# ---- DECISIONES DE LIMPIEZA ----
# 1. codigo_comuna: "SIN DATO" -> NA (1732 registros, 2 %)
# 2. sexo: "Sin dato" -> NA
# 3. modalidad: agrupar por mecanismo
#    - Violencia: Atraco, Miedo o terror, Enfrentamiento con la fuerza pública
#    - Sin contacto: Halado, Descuido, Llave maestra, Desvalijar o descuartizar
#    - Engaño: Engaño, Escopolamina, Abuso de confianza, Suplantación,
#              Tóxico o agente químico
#    - "Sin dato" y "Vehículo" -> NA
# 4. edad: -1 -> NA (2982 registros, 3.5 %)
# 5. modelo: -1 -> NA (25 023 registros, 29 %). Solo uso descriptivo, con advertencia
# 6. cantidad: siempre 1 -> cada fila es un robo; se cuentan filas
# 7. Duplicados exactos: 7625, casi todos en 2005-2010 (error de registro probable).
#    Se eliminan. Junto con los casi duplicados de 2003-2004, motivo para usar 2011 en adelante.


# ---- Exploración ----
library(dplyr)
hurtos <- read.csv("datos/crudos/hurto_de_moto.csv", stringsAsFactors = FALSE)


dim(hurtos)
glimpse(hurtos)

table(hurtos$codigo_comuna)
table(hurtos$sexo)
table(hurtos$modalidad)

# Valores -1 (faltantes en columnas numéricas)
sum(hurtos$edad == -1) #2982
sum(hurtos$modelo == -1) #25023

# ¿cantidad siempre vale 1?
table(hurtos$cantidad) #Sí 86410

# Filas repetidas
sum(duplicated(hurtos)) #7625

# ---- Limpieza -----
hurtos_limpio <- hurtos |> 
  distinct()|> #quitar duplicados
  mutate(fecha = as.Date(substr(fecha_hecho, 1, 10)), #de texto a fecha
          anio = as.integer(format(fecha, "%Y")),
          mes = as.integer(format(fecha, "%m"))) |>
  filter(anio >= 2011) #periodo de trabajo

#convertir faltantes a NA
hurtos_limpio <- hurtos_limpio |>
  mutate(codigo_comuna = na_if(codigo_comuna, "SIN DATO"),
         sexo = na_if(sexo , "Sin dato"),
         modelo = na_if(modelo, -1),
         edad = na_if(edad, -1))

#¿Funcionó?
sum(is.na(hurtos_limpio$edad)) #Sí, 2531 NA

#Reclasificación de las categorías de modalidad
hurtos_limpio <- hurtos_limpio |>
  mutate(mecanismo = case_when(
    modalidad %in% c("Atraco", "Miedo o terror",
                     "Enfrentamiento con la fuerza pública") ~ "Violencia",
    modalidad %in% c("Halado", "Descuido", "Llave maestra",
                     "Desvalijar o descuartizar")             ~ "Sin contacto",
    modalidad %in% c("Engaño", "Escopolamina", "Abuso de confianza",
                     "Suplantación", "Tóxico o agente químico") ~ "Engaño"
  ))

table(hurtos_limpio$modalidad, hurtos_limpio$mecanismo, useNA = "ifany")

