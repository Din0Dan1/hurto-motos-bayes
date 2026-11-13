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
