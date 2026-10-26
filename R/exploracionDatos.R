# ============================================================================
# EXPLORACIÓN EN R | AIRBNB CENTROEUROPA
# 12 exercises adapted from exploracionDatos.py. Run preProcesamiento_R first.
# Required package: tidyverse
# ============================================================================

library(tidyverse)

# Absolute Windows path shared by all project files.
carpeta <- "C:/Users/6/Desktop/R"
archivo <- file.path(carpeta, 'airbnb_centro_europa_clean_R.csv')
if (!file.exists(archivo)) stop('Primero ejecuta preProcesamiento.R.')
df <- read_csv(archivo, show_col_types = FALSE, progress = FALSE)
for (columna in c('precio_eur', 'accommodates', 'review_scores_rating', 'number_of_reviews')) {
  df[[columna]] <- suppressWarnings(as.numeric(df[[columna]]))
}
objetivo <- function(texto) {
  cat('\n', strrep('━', 60), '\n🎯 OBJETIVO: ', texto, '\n', strrep('─', 60), '\n', sep = '')
}
conclusion <- function(texto, ejemplo) {
  cat(strrep('─', 60), '\n🧠 CONCLUSIÓN: ', texto,
      '\n🔎 EJEMPLO: ', ejemplo, '\n', strrep('━', 60), '\n', sep = '')
}
mostrar <- function(tabla, n = Inf) print(as.data.frame(head(tabla, n)), row.names = FALSE)
fmt <- function(x) sprintf('%.2f', x)

cat('\n🏡 EXPLORACIÓN DE AIRBNB — CENTROEUROPA\n')
cat('📍 Alojamientos:', nrow(df), '| Regiones:', n_distinct(df$region_origen), '\n')

# ============================================================================
# 🏆 EXERCISE 1: FIVE MOST EXPENSIVE LISTINGS
# ============================================================================
cat('\n🏆 1. LOS 5 ALOJAMIENTOS MÁS CAROS\n')
objetivo('Identificar los anuncios con mayor precio convertido a euros.')
top_caros <- df %>% arrange(desc(precio_eur)) %>% select(name, region_origen, precio_eur, room_type) %>% head(5)
mostrar(top_caros)
conclusion('Ordenar por precio permite identificar extremos.',
           paste(top_caros$region_origen[1], ':', fmt(top_caros$precio_eur[1]), '€ por noche.'))

# ============================================================================
# 📊 EXERCISE 2: CITY SUMMARY WITH TOTALS
# ============================================================================
cat('\n📊 2. RESUMEN POR PAÍS/CIUDAD\n')
objetivo('Comparar anuncios, precios medios y medianos, y valoraciones.')
resumen <- df %>% group_by(region_origen) %>% summarise(
  alojamientos = sum(!is.na(id)), precio_medio_eur = mean(precio_eur, na.rm = TRUE),
  precio_mediano_eur = median(precio_eur, na.rm = TRUE),
  valoracion_media = mean(review_scores_rating, na.rm = TRUE), .groups = 'drop')
total <- tibble(region_origen = '🌍 TOTAL DATASET', alojamientos = sum(!is.na(df$id)),
                precio_medio_eur = mean(df$precio_eur, na.rm = TRUE),
                precio_mediano_eur = median(df$precio_eur, na.rm = TRUE),
                valoracion_media = mean(df$review_scores_rating, na.rm = TRUE))
mostrar(bind_rows(total, resumen) %>% mutate(across(where(is.numeric), ~round(.x, 2))))
barata <- resumen %>% slice_min(precio_mediano_eur, n = 1, with_ties = FALSE)
conclusion('La mediana reduce la influencia de precios extremos.', paste(barata$region_origen, fmt(barata$precio_mediano_eur), '€'))

# ============================================================================
# ⭐ EXERCISE 3: SUPERHOST COMPARISON
# ============================================================================
cat('\n⭐ 3. COMPARACIÓN DE SUPERHOSTS\n')
objetivo('Comparar el precio y valoración de alojamientos con puntuación conocida.')
superhost <- df %>% filter(!is.na(review_scores_rating)) %>%
  mutate(grupo = case_when(host_is_superhost == 't' ~ '⭐ Superhost',
                           host_is_superhost == 'f' ~ '🏠 No superhost',
                           TRUE ~ '❔ Sin dato')) %>%
  group_by(grupo) %>% summarise(alojamientos = sum(!is.na(id)),
  precio_medio_eur = round(mean(precio_eur, na.rm = TRUE), 2),
  valoracion_media = round(mean(review_scores_rating, na.rm = TRUE), 2), .groups = 'drop')
mostrar(superhost)
if (nrow(superhost) > 0) {
  mejor <- superhost %>% slice_max(valoracion_media, n = 1, with_ties = FALSE)
  conclusion('Las diferencias observadas no demuestran causalidad.', paste(mejor$grupo, fmt(mejor$valoracion_media), '/5'))
}

# ============================================================================
# 🔎 EXERCISE 4: VIENNA MULTI-CRITERIA SEARCH
# ============================================================================
cat('\n🔎 4. VIENA: VIVIENDA ENTERA, 4 PLAZAS, <80 € Y NOTA >=4\n')
objetivo('Aplicar cuatro requisitos simultáneos para buscar alojamientos.')
oportunidades <- df %>% filter(region_origen == 'Austria, Viena', room_type == 'Entire home/apt',
                               accommodates >= 4, precio_eur < 80, review_scores_rating >= 4)
cat('✅ Coincidencias:', nrow(oportunidades), '\n')
mostrar(oportunidades %>% select(name, neighbourhood_cleansed, precio_eur, review_scores_rating), 5)
if (nrow(oportunidades) > 0) {
  candidato <- oportunidades %>% slice_min(precio_eur, n = 1, with_ties = FALSE)
  conclusion('Se cumplen simultáneamente todos los filtros.',
             paste(nrow(oportunidades), 'anuncios; mínimo:', fmt(candidato$precio_eur), '€; barrio:', candidato$neighbourhood_cleansed))
} else conclusion('No se encontraron resultados.', 'Modificar algún umbral puede ampliar la búsqueda.')

# ============================================================================
# 🛏️ EXERCISE 5: ROOM TYPE CONTINGENCY TABLE
# ============================================================================
cat('\n🛏️ 5. TIPOS DE ALOJAMIENTO POR CIUDAD\n')
objetivo('Contar cuántos anuncios hay por modalidad de alojamiento y región.')
tipos <- table(df$region_origen, df$room_type)
print(rbind('🌍 TOTAL DATASET' = colSums(tipos), tipos))
frecuente <- sort(table(df$room_type), decreasing = TRUE)
conclusion('Las modalidades tienen distinta presencia en la muestra.',
           paste(names(frecuente)[1], ':', frecuente[1], 'anuncios.'))

# ============================================================================
# 💶 EXERCISE 6: MEDIAN PRICE PER GUEST
# ============================================================================
cat('\n💶 6. PRECIO MEDIANO POR HUÉSPED Y CIUDAD\n')
objetivo('Estimar el coste por persona suponiendo ocupación completa.')
df <- df %>% mutate(precio_por_huesped_eur = if_else(!is.na(accommodates) & accommodates > 0,
                                                    round(precio_eur / accommodates, 2), NA_real_))
ph <- df %>% group_by(region_origen) %>% summarise(mediana_eur = median(precio_por_huesped_eur, na.rm = TRUE), .groups = 'drop')
mostrar(bind_rows(tibble(region_origen = '🌍 TOTAL DATASET', mediana_eur = median(df$precio_por_huesped_eur, na.rm = TRUE)), ph))
mejor <- ph %>% slice_min(mediana_eur, n = 1, with_ties = FALSE)
conclusion('El precio por huésped reparte el importe entre todas las plazas.', paste(mejor$region_origen, fmt(mejor$mediana_eur), '€/huésped.'))

# ============================================================================
# 🗺️ EXERCISE 7: LOW-PRICE NEIGHBOURHOODS WITH MINIMUM SAMPLE
# ============================================================================
cat('\n🗺️ 7. LOS 10 BARRIOS MÁS ECONÓMICOS CON 30 ANUNCIOS O MÁS\n')
objetivo('Comparar barrios con al menos 30 registros, usando precio mediano.')
barrios <- df %>% group_by(region_origen, neighbourhood_cleansed) %>%
  summarise(alojamientos = sum(!is.na(id)), precio_mediano_eur = median(precio_eur, na.rm = TRUE), .groups = 'drop') %>%
  filter(!is.na(neighbourhood_cleansed), alojamientos >= 30) %>% arrange(precio_mediano_eur) %>% head(10)
mostrar(barrios)
if (nrow(barrios) > 0) conclusion('El tamaño mínimo reduce comparaciones con muestras pequeñas.',
  paste(barrios$neighbourhood_cleansed[1], '(', barrios$region_origen[1], '):', fmt(barrios$precio_mediano_eur[1]), '€'))

# ============================================================================
# 💸 EXERCISE 8: PRICE BANDS
# ============================================================================
cat('\n💸 8. DISTRIBUCIÓN POR TRAMOS DE PRECIO\n')
objetivo('Detectar en qué intervalos se concentran los anuncios.')
etiquetas <- c('10-50 €', '50-100 €', '100-150 €', '150-250 €', '250-500 €', '500-1000 €')
df <- df %>% mutate(tramo_precio = cut(precio_eur, breaks = c(10, 50, 100, 150, 250, 500, 1000),
                                      labels = etiquetas, include.lowest = TRUE))
tramos <- table(df$region_origen, df$tramo_precio)
print(rbind('🌍 TOTAL DATASET' = colSums(tramos), tramos))
mas_frecuente <- sort(colSums(tramos), decreasing = TRUE)
conclusion('Los intervalos muestran la estructura de precios.', paste(names(mas_frecuente)[1], ':', mas_frecuente[1], 'anuncios.'))

# ============================================================================
# 👥 EXERCISE 9: MEDIAN PRICE BY CAPACITY
# ============================================================================
cat('\n👥 9. PRECIO MEDIANO SEGÚN CAPACIDAD (1 A 8)\n')
objetivo('Comparar precios medianos según el número de huéspedes.')
capacidad <- df %>% filter(between(accommodates, 1, 8)) %>% group_by(accommodates) %>%
  summarise(alojamientos = sum(!is.na(id)), precio_mediano_eur = median(precio_eur, na.rm = TRUE), .groups = 'drop')
mostrar(capacidad)
if (nrow(capacidad) > 0) conclusion('La capacidad permite segmentar precios, sin probar causalidad.',
  paste(capacidad$accommodates[1], 'huésped:', fmt(capacidad$precio_mediano_eur[1]), '€;',
        tail(capacidad$accommodates, 1), 'huéspedes:', fmt(tail(capacidad$precio_mediano_eur, 1)), '€'))

# ============================================================================
# ⭐ EXERCISE 10: REVIEW COVERAGE
# ============================================================================
cat('\n⭐ 10. COBERTURA DE VALORACIONES Y RESEÑAS\n')
objetivo('Medir la cobertura de puntuaciones y volumen de reseñas por ciudad.')
calidad <- df %>% group_by(region_origen) %>% summarise(
  alojamientos = sum(!is.na(id)), con_valoracion = sum(!is.na(review_scores_rating)),
  resenas_totales = sum(number_of_reviews, na.rm = TRUE),
  porcentaje_con_valoracion = round(100 * con_valoracion / alojamientos, 1), .groups = 'drop')
total_calidad <- tibble(region_origen = '🌍 TOTAL DATASET', alojamientos = sum(!is.na(df$id)),
  con_valoracion = sum(!is.na(df$review_scores_rating)), resenas_totales = sum(df$number_of_reviews, na.rm = TRUE),
  porcentaje_con_valoracion = round(100 * sum(!is.na(df$review_scores_rating)) / sum(!is.na(df$id)), 1))
mostrar(bind_rows(total_calidad, calidad))
mejor <- calidad %>% slice_max(porcentaje_con_valoracion, n = 1, with_ties = FALSE)
conclusion('La cobertura mide disponibilidad de notas, no satisfacción.', paste(mejor$region_origen, mejor$porcentaje_con_valoracion, '%.'))

# ============================================================================
# 🏘️ EXERCISE 11: HOST LISTING CONCENTRATION
# ============================================================================
cat('\n🏘️ 11. CONCENTRACIÓN DE ANUNCIOS POR ANFITRIÓN Y CIUDAD\n')
objetivo('Comparar anuncios, anfitriones y precios por tamaño de la cuenta.')
grupo_niveles <- c('🏠 1 alojamiento', '🏘️ 2-4 alojamientos', '🏢 5-10 alojamientos', '🏙️ Más de 10 alojamientos')
datos <- df %>% filter(!is.na(host_id), !is.na(region_origen)) %>%
  group_by(host_id, region_origen) %>% mutate(num_alojamientos_host = sum(!is.na(id))) %>% ungroup() %>%
  mutate(grupo_host = cut(num_alojamientos_host, breaks = c(0, 1, 4, 10, Inf),
                          labels = grupo_niveles, include.lowest = TRUE))
cat('\n🏠 11.1 Número de anuncios por grupo y ciudad\n')
tabla_anuncios <- table(datos$region_origen, datos$grupo_host)
print(rbind('🌍 TOTAL DATASET' = colSums(tabla_anuncios), tabla_anuncios))
cat('\n📈 11.2 Porcentaje de anuncios por grupo y ciudad\n')
print(round(rbind('🌍 TOTAL DATASET' = 100 * colSums(tabla_anuncios) / sum(tabla_anuncios),
                  prop.table(tabla_anuncios, 1) * 100), 2))
cat('\n👤 11.3 Número y porcentaje de anfitriones por grupo\n')
anfitriones <- datos %>% distinct(host_id, region_origen, .keep_all = TRUE)
tabla_hosts <- table(anfitriones$region_origen, anfitriones$grupo_host)
print(rbind('🌍 TOTAL DATASET' = colSums(tabla_hosts), tabla_hosts))
print(round(rbind('🌍 TOTAL DATASET' = 100 * colSums(tabla_hosts) / sum(tabla_hosts),
                  prop.table(tabla_hosts, 1) * 100), 2))
cat('\n💶 11.4 Precio medio y mediano por grupo\n')
precios_host <- datos %>% group_by(region_origen, grupo_host) %>%
  summarise(precio_medio_eur = round(mean(precio_eur, na.rm = TRUE), 2),
            precio_mediano_eur = round(median(precio_eur, na.rm = TRUE), 2), .groups = 'drop')
mostrar(precios_host)
conclusion('Concentración de anuncios no equivale a propiedad legal.',
           paste(nrow(datos), 'anuncios y', nrow(anfitriones), 'cuentas distintas por ciudad.'))

# ============================================================================
# 🏅 EXERCISE 12: AFFORDABLE HIGH-RATED CENTRAL LISTINGS
# ============================================================================
cat('\n🏅 12. TOP 10 BARATOS, BIEN VALORADOS Y CÉNTRICOS\n')
objetivo('Buscar menor precio entre anuncios de barrios seleccionados con nota >= 4,7 y 20+ reseñas.')
barrios_centro <- list(
  'Alemania, Berlin' = c('Alexanderplatz', 'Brunnenstr. Süd', 'Südliche Friedrichstadt'),
  'Austria, Viena' = c('Innere Stadt', 'Neubau', 'Wieden', 'Mariahilf'),
  'Republica Checa, Praga' = c('Praha 1', 'Praha 2'),
  'Hungria, Budapest' = c('V. kerület', 'VI. kerület', 'VII. kerület')
)
filtro_centro <- rep(FALSE, nrow(df))
for (ciudad in names(barrios_centro)) {
  coincidencia <- df$region_origen == ciudad & df$neighbourhood_cleansed %in% barrios_centro[[ciudad]]
  filtro_centro <- filtro_centro | replace_na(coincidencia, FALSE)
}
candidatos <- df %>% filter(filtro_centro, review_scores_rating >= 4.7, number_of_reviews >= 20)
top_10 <- candidatos %>% arrange(precio_eur, desc(review_scores_rating), desc(number_of_reviews)) %>% head(10)
cat('✅ Candidatos:', nrow(candidatos), '\n')
mostrar(top_10 %>% transmute(Alojamiento = str_trunc(name, 25), Ciudad = region_origen,
   Barrio = neighbourhood_cleansed, `Precio €` = precio_eur, Nota = review_scores_rating,
   Resenas = number_of_reviews, Enlace = listing_url))
cat('ℹ️ La centralidad se aproxima mediante una lista de barrios seleccionados.\n')
if (nrow(top_10) > 0) {
  conclusion('El listado ordena los candidatos válidos por precio.',
    paste('Más barato:', fmt(top_10$precio_eur[1]), '€; nota:', fmt(top_10$review_scores_rating[1]), '/5.'))
} else {
  conclusion('Ningún anuncio cumple todos los criterios.', 'Revisar barrios y umbrales.')
}

# ============================================================================
# 🌍 GLOBAL CONCLUSIONS
# ============================================================================
cat('\n', strrep('═', 65), '\n🌍 CONCLUSIONES GLOBALES\n', sep = '')
medianas <- df %>% group_by(region_origen) %>% summarise(mediana = median(precio_eur, na.rm = TRUE), .groups = 'drop')
ciudad_barata <- medianas %>% slice_min(mediana, n = 1, with_ties = FALSE)
ciudad_cara <- medianas %>% slice_max(mediana, n = 1, with_ties = FALSE)
cat('💶 Menor mediana:', ciudad_barata$region_origen, fmt(ciudad_barata$mediana), '€;',
    'mayor:', ciudad_cara$region_origen, fmt(ciudad_cara$mediana), '€\n')
cat('📊 Tramo más frecuente:', names(mas_frecuente)[1],
    '(', round(100 * mas_frecuente[1] / nrow(df), 1), '% del dataset).\n')
cat('🏘️ Anuncios de cuentas con 5+ anuncios en una ciudad:',
    round(100 * sum(datos$num_alojamientos_host >= 5) / nrow(datos), 1), '% de los identificados.\n')
cat('🧭 RECOMENDACIÓN: comparar precios medianos, capacidad, ubicación y valoración; no solo precio mínimo.\n')
cat('⚠️ Son anuncios, no reservas confirmadas; los tipos de cambio son referencias del ejercicio.\n')
cat(strrep('═', 65), '\n✅ EXPLORACIÓN FINALIZADA\n')


# ============================================================================
# 📉 VISUALIZACIÓN DE DATOS | 5 GRÁFICOS CON GGPLOT2
# ============================================================================
# OBJECTIVE: Visualize the dataset already loaded and analyzed above.
# The same df is reused; no second CSV import or preprocessing is performed.
# Charts are printed explicitly so that source() displays them in RStudio.

library(ggplot2)

# Keep missing review scores excluded from correlation calculations.
if ('has_no_reviews' %in% names(df)) {
  df$review_scores_rating[df$has_no_reviews == 1] <- NA_real_
}

# Use short labels without modifying the underlying source data.
ciudades <- c("Alemania, Berlin" = "Berlín",
             "Austria, Viena" = "Viena",
             "Republica Checa, Praga" = "Praga",
             "Hungria, Budapest" = "Budapest")
df$ciudad <- ifelse(df$region_origen %in% names(ciudades),
                    unname(ciudades[df$region_origen]), df$region_origen)
df$ciudad <- factor(df$ciudad, levels = c("Berlín", "Viena", "Praga", "Budapest"))

# Helper functions for clear, consistent console output.
separador <- function(titulo, objetivo) {
  cat("\n", strrep("=", 68), "\n", titulo, "\n", strrep("-", 68),
      "\nOBJETIVO: ", objetivo, "\n", sep = "")
}
conclusiones <- function(frases) {
  cat("\nCONCLUSIONES:\n")
  for (i in seq_along(frases)) cat(i, ". ", frases[i], "\n", sep = "")
  cat(strrep("=", 68), "\n")
}
formato <- function(x, decimales = 2) {
  formatC(x, format = "f", digits = decimales, decimal.mark = ",")
}

cat("\nAIRBNB CENTROEUROPA |", nrow(df), "anuncios disponibles para gráficos\n")

# ============================================================
# GRAFICO 1. BOXPLOT DE PRECIOS POR CIUDAD
# ============================================================
separador("GRAFICO 1: DISTRIBUCION DE PRECIOS POR CIUDAD",
          "Comparar medianas, dispersion y valores extremos de precios por noche.")

precios <- df %>% filter(!is.na(ciudad), !is.na(precio_eur))
g1 <- ggplot(precios, aes(x = ciudad, y = precio_eur, fill = ciudad)) +
  geom_boxplot(outlier.alpha = 0.20, outlier.color = "firebrick") +
  coord_cartesian(ylim = c(0, 400)) +
  labs(title = "Distribución de precios por noche",
       subtitle = "Vista ampliada hasta 400 €; estadísticos calculados con todos los precios",
       x = "Ciudad", y = "Precio por noche (€)") +
  theme_minimal() +
  theme(legend.position = "none", plot.title = element_text(face = "bold"))
print(g1)

medianas <- precios %>% group_by(ciudad) %>%
  summarise(mediana = median(precio_eur),
            q1 = as.numeric(quantile(precio_eur, 0.25)),
            q3 = as.numeric(quantile(precio_eur, 0.75)), .groups = "drop") %>%
  mutate(amplitud_caja = q3 - q1)
print(as.data.frame(medianas))
mayor <- medianas %>% slice_max(mediana, n = 1, with_ties = FALSE)
menor <- medianas %>% slice_min(mediana, n = 1, with_ties = FALSE)
dispersa <- medianas %>% slice_max(amplitud_caja, n = 1, with_ties = FALSE)
conclusiones(c(
  paste0("Mayor precio mediano: ", mayor$ciudad, " (", formato(mayor$mediana), " €)."),
  paste0("Menor precio mediano: ", menor$ciudad, " (", formato(menor$mediana), " €)."),
  paste0("Mayor dispersion central (rango intercuartil): ", dispersa$ciudad,
         " (", formato(dispersa$amplitud_caja), " €).")
))

# ============================================================
# GRAFICO 2. PRECIO MEDIO POR TIPO Y CIUDAD
# ============================================================
separador("GRAFICO 2: PRECIO MEDIO POR TIPO DE ALOJAMIENTO",
          "Comparar los precios medios de cada modalidad entre ciudades.")

datos_g2 <- precios %>% filter(!is.na(room_type)) %>%
  group_by(ciudad, room_type) %>%
  summarise(precio_medio = mean(precio_eur), anuncios = n(), .groups = "drop")
g2 <- ggplot(datos_g2, aes(x = ciudad, y = precio_medio, fill = room_type)) +
  geom_col(position = position_dodge(width = 0.85), width = 0.75) +
  labs(title = "Precio medio según tipo de alojamiento",
       subtitle = "Comparación entre las cuatro ciudades",
       x = "Ciudad", y = "Precio medio por noche (€)", fill = "Tipo") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"), legend.position = "bottom")
print(g2)
print(as.data.frame(datos_g2))
mayor_tipo <- datos_g2 %>% slice_max(precio_medio, n = 1, with_ties = FALSE)
menor_tipo <- datos_g2 %>% slice_min(precio_medio, n = 1, with_ties = FALSE)
medias_tipo <- datos_g2 %>% group_by(room_type) %>%
  summarise(n_anuncios = sum(anuncios),
            media_ponderada = weighted.mean(precio_medio, anuncios), .groups = "drop")
tipo_frecuente <- medias_tipo %>% slice_max(n_anuncios, n = 1, with_ties = FALSE)
conclusiones(c(
  paste0("Combinacion ciudad/tipo mas cara en media: ", mayor_tipo$ciudad, " / ",
         mayor_tipo$room_type, " (", formato(mayor_tipo$precio_medio), " €)."),
  paste0("Combinacion ciudad/tipo mas barata en media: ", menor_tipo$ciudad, " / ",
         menor_tipo$room_type, " (", formato(menor_tipo$precio_medio), " €)."),
  paste0("Modalidad con mas anuncios: ", tipo_frecuente$room_type,
         " (", tipo_frecuente$n_anuncios, " anuncios).")
))

# ============================================================
# GRAFICO 3. RELACION ENTRE VALORACION Y PRECIO
# ============================================================
separador("GRAFICO 3: VALORACION FRENTE A PRECIO",
          "Comprobar si existe una relacion lineal entre puntuacion y precio.")

# The 500 EUR ceiling affects this visualization and the calculated correlation.
datos_g3 <- df %>% filter(!is.na(review_scores_rating),
                          review_scores_rating > 0,
                          !is.na(precio_eur), precio_eur <= 500)
g3 <- ggplot(datos_g3, aes(x = review_scores_rating, y = precio_eur)) +
  geom_point(alpha = 0.15, color = "steelblue") +
  geom_smooth(method = "lm", se = FALSE, color = "darkred", na.rm = TRUE) +
  labs(title = "Relación entre valoración y precio",
       subtitle = "Anuncios con valoración y precio hasta 500 €",
       x = "Valoración del huésped (0–5)", y = "Precio por noche (€)") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"))
print(g3)

correlacion <- if (nrow(datos_g3) >= 3 &&
                   sd(datos_g3$precio_eur) > 0 && sd(datos_g3$review_scores_rating) > 0) {
  cor(datos_g3$review_scores_rating, datos_g3$precio_eur)
} else NA_real_
porcentaje_altas <- 100 * mean(datos_g3$review_scores_rating >= 4.5)
conclusiones(c(
  paste0("Se comparan ", nrow(datos_g3), " anuncios con puntuaciones disponibles."),
  paste0("El ", formato(porcentaje_altas, 1), "% tiene valoracion >= 4,5/5."),
  paste0("Correlacion lineal de Pearson: ", formato(correlacion, 3),
         ". La correlacion no implica causalidad.")
))

# ============================================================
# GRAFICO 4. CONCENTRACION DE ANUNCIOS POR ANFITRION
# ============================================================
separador("GRAFICO 4: CONCENTRACION POR ANFITRION",
          "Medir el porcentaje de anuncios asociado a cuentas con distinta cantidad de anuncios.")

# Count each host's listings within each city, as in Python exercise 11.
datos_g4 <- df %>% filter(!is.na(ciudad), !is.na(host_id), host_id != "") %>%
  group_by(ciudad, host_id) %>% mutate(num_anuncios_host = n()) %>% ungroup() %>%
  mutate(grupo_host = cut(num_anuncios_host, breaks = c(0, 1, 4, 10, Inf),
                          labels = c("1 anuncio", "2–4 anuncios", "5–10 anuncios", ">10 anuncios"))) %>%
  count(ciudad, grupo_host, name = "anuncios") %>%
  group_by(ciudad) %>% mutate(porcentaje = 100 * anuncios / sum(anuncios)) %>% ungroup()
g4 <- ggplot(datos_g4, aes(x = ciudad, y = porcentaje, fill = grupo_host)) +
  geom_col(width = 0.7) +
  labs(title = "Concentración de anuncios por anfitrión",
       subtitle = "Porcentaje de anuncios según tamaño de la cuenta en cada ciudad",
       x = "Ciudad", y = "Porcentaje de anuncios (%)", fill = "Anuncios por cuenta") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"), legend.position = "bottom")
print(g4)
print(as.data.frame(datos_g4))
concentracion <- datos_g4 %>% filter(grupo_host %in% c("5–10 anuncios", ">10 anuncios")) %>%
  group_by(ciudad) %>% summarise(pct = sum(porcentaje), .groups = "drop")
mas_concentrada <- concentracion %>% slice_max(pct, n = 1, with_ties = FALSE)
menos_concentrada <- concentracion %>% slice_min(pct, n = 1, with_ties = FALSE)
conclusiones(c(
  paste0("Mayor cuota de anuncios de cuentas con >=5 anuncios: ",
         mas_concentrada$ciudad, " (", formato(mas_concentrada$pct, 1), "%)."),
  paste0("Menor cuota de anuncios de cuentas con >=5 anuncios: ",
         menos_concentrada$ciudad, " (", formato(menos_concentrada$pct, 1), "%)."),
  "La cifra muestra anuncios asociados a una cuenta; no acredita propiedad legal de inmuebles."
))

# ============================================================
# GRAFICO 5. TOP 10 BARRIOS CON MENOR PRECIO MEDIANO
# ============================================================
separador("GRAFICO 5: LOS DIEZ BARRIOS MAS ECONOMICOS",
          "Identificar los barrios con menor precio mediano y al menos 30 anuncios.")

datos_g5 <- precios %>% filter(!is.na(neighbourhood_cleansed),
                               trimws(neighbourhood_cleansed) != "") %>%
  group_by(ciudad, neighbourhood_cleansed) %>%
  summarise(anuncios = n(), mediana = median(precio_eur), .groups = "drop") %>%
  filter(anuncios >= 30) %>%
  arrange(mediana, desc(anuncios)) %>% slice_head(n = 10) %>%
  mutate(barrio_ciudad = paste0(neighbourhood_cleansed, " (", ciudad, ")"),
         barrio_ciudad = factor(barrio_ciudad, levels = rev(barrio_ciudad)))
g5 <- ggplot(datos_g5, aes(x = barrio_ciudad, y = mediana, fill = ciudad)) +
  geom_col(width = 0.7) +
  coord_flip() +
  labs(title = "Los 10 barrios con menor precio mediano",
       subtitle = "Solo barrios con al menos 30 anuncios",
       x = "Barrio y ciudad", y = "Precio mediano por noche (€)", fill = "Ciudad") +
  theme_minimal() +
  theme(plot.title = element_text(face = "bold"), legend.position = "bottom")
print(g5)
print(as.data.frame(datos_g5 %>% select(ciudad, neighbourhood_cleansed, anuncios, mediana)))
if (nrow(datos_g5) > 0) {
  primero <- datos_g5 %>% slice_min(mediana, n = 1, with_ties = FALSE)
  conclusiones(c(
    paste0("Barrio con menor mediana: ", primero$neighbourhood_cleansed,
           " (", primero$ciudad, "), ", formato(primero$mediana), " €."),
    paste0("Se han representado ", nrow(datos_g5), " barrios con muestra >=30 anuncios."),
    "La mediana reduce la influencia de precios extremos; no equivale a una tarifa garantizada."
  ))
} else {
  cat("No hay barrios que cumplan el mínimo de anuncios.\n")
}

# ============================================================
# GRAFICO 6. EFECTO SUPERHOST: DISTRIBUCION DE RESENAS
# ============================================================
# HOW TO READ THIS CHART:
# - The pink violin represents standard hosts; turquoise represents Superhosts.
# - The width of each violin indicates where more listings are concentrated.
# - The box shows the middle 50% of observations (Q1 to Q3).
# - The horizontal line and black dot mark the median review count.
# - The whiskers extend to values within 1.5 times the interquartile range.
# - Each observation is a listing, not a host; reviews are not reservations.
# - Only listings with 0 to 150 reviews are included in this comparison.
separador("GRAFICO 6: SUPERHOST Y VOLUMEN DE RESEÑAS",
          "Comparar la distribución de reseñas por anuncio según el estatus Superhost.")

# Normalize the host category to handle logical values and strings alike.
# Use only listings with 0 to 150 reviews for this comparison.
datos_g6 <- df %>%
  mutate(
    estado_host = tolower(trimws(as.character(host_is_superhost))),
    grupo_superhost = case_when(
      estado_host %in% c("true", "t", "1") ~ "Superhost",
      estado_host %in% c("false", "f", "0") ~ "Anfitrión estándar",
      TRUE ~ NA_character_
    )
  ) %>%
  filter(!is.na(grupo_superhost), !is.na(number_of_reviews),
         number_of_reviews >= 0, number_of_reviews <= 150) %>%
  mutate(grupo_superhost = factor(grupo_superhost,
          levels = c("Anfitrión estándar", "Superhost")))

if (nrow(datos_g6) > 0 && n_distinct(datos_g6$grupo_superhost) == 2) {
  g6 <- ggplot(datos_g6,
               aes(x = grupo_superhost, y = number_of_reviews,
                   fill = grupo_superhost)) +
    # Violin width shows the density of listings at each review count.
    geom_violin(trim = FALSE, alpha = 0.65, color = "#555555", linewidth = 0.35) +
    # Overlay quartiles and the median without drawing outlier points twice.
    geom_boxplot(width = 0.12, alpha = 0.80, outlier.shape = NA,
                 color = "#222222", linewidth = 0.45) +
    stat_summary(fun = median, geom = "point", size = 2.3, color = "black") +
    scale_fill_manual(values = c(
      "Anfitrión estándar" = "#F4A6A6",
      "Superhost" = "#46C7C7"
    )) +
    coord_cartesian(ylim = c(0, 150)) +
    labs(
      title = "El 'Efecto Superhost': volumen de reseñas por anfitrión",
      subtitle = "Número de reseñas acumuladas por anuncio (muestra limitada a 150 reseñas)",
      x = "Categoría de anfitrión",
      y = "Número total de reseñas por anuncio",
      caption = paste0(
"COMO INTERPRETAR EL GRÁFICO:\n",
"• Rosa: alojamientos de anfitriones normales. Turquesa: Superhost.\n",
"• Forma del violín: cuanto más ancho es en una zona, más alojamientos se concentran en ese número de reseñas.\n",
"• Caja interior: contiene el 50 % central de los alojamientos, excluyendo el 25 % con menos reseñas y el 25 % con más.\n",
"• Línea negra: indica la mediana. La mitad de los alojamientos tiene menos reseñas que ese valor y la otra mitad tiene más.\n",
"• Bigotes de la caja: muestran hasta dónde llegan los valores habituales, sin incluir los extremos más alejados.\n",
"• Solo se analizan alojamientos que tienen entre 0 y 150 reseñas.\n",
"CONCLUSIÓN: si el violín y su caja están más arriba, ese grupo suele acumular más reseñas por alojamiento.\n"
      )
    ) +
    theme_minimal(base_size = 12) +
    theme(
      legend.position = "none",
      plot.title = element_text(face = "bold", size = 15),
      plot.subtitle = element_text(size = 10),
      axis.title = element_text(face = "bold"),
      axis.text = element_text(size = 11),
      plot.caption = element_text(size = 9, color = "#555555", hjust = 0, margin = margin(t = 12)),
      panel.grid.minor = element_blank()
    )
  # Display the violin + boxplot in the RStudio Plots pane.
  print(g6)

  # Save the chart automatically so it is easy to find independently.
  ruta_g6 <- file.path(carpeta, "GRAFICO_6_SUPERHOST_VIOLIN.png")
  ggsave(filename = ruta_g6, plot = g6, width = 11, height = 6,
         units = "in", dpi = 300, bg = "white")
  cat("\n✅ Gráfico 6 generado y guardado en: ", ruta_g6, "\n", sep = "")
  cat("ℹ️ En RStudio, abre la pestaña Plots o el PNG de la carpeta R.\n")

  cat("\n📖 CÓMO INTERPRETAR EL GRÁFICO 6\n")
  cat("  • Rosa: anfitriones estándar. Turquesa: Superhost.\n")
  cat("  • Violín: cuanto más ancho es a cierta altura, más anuncios se concentran en ese número de reseñas.\n")
  cat("  • Caja interior: contiene el 50 % central de los anuncios (entre el primer y el tercer cuartil).\n")
  cat("  • Línea horizontal y punto negro: mediana; la mitad de los anuncios queda por debajo y la otra mitad por encima.\n")
  cat("  • Bigotes: rango habitual según el criterio de 1,5 veces el recorrido intercuartílico.\n")
  cat("  • Comparación limitada a anuncios con 0–150 reseñas; no representa todas las reservas.\n")

  resumen_g6 <- datos_g6 %>%
    group_by(grupo_superhost) %>%
    summarise(anuncios = n(),
              media_resenas = mean(number_of_reviews),
              mediana_resenas = median(number_of_reviews),
              .groups = "drop")
  print(as.data.frame(resumen_g6))

  estandar_g6 <- resumen_g6 %>% filter(grupo_superhost == "Anfitrión estándar")
  superhost_g6 <- resumen_g6 %>% filter(grupo_superhost == "Superhost")
  diferencia_g6 <- superhost_g6$mediana_resenas - estandar_g6$mediana_resenas
  comparacion_g6 <- if (diferencia_g6 > 0) {
    "superior"
  } else if (diferencia_g6 < 0) {
    "inferior"
  } else {
    "igual"
  }
  conclusiones(c(
    paste0("Mediana de reseñas estándar: ", formato(estandar_g6$mediana_resenas, 0),
           "; Superhost: ", formato(superhost_g6$mediana_resenas, 0),
           ". La mediana Superhost es ", comparacion_g6, "."),
    paste0("Medias de reseñas: estándar ", formato(estandar_g6$media_resenas),
           "; Superhost ", formato(superhost_g6$media_resenas),
           ". Anuncios representados: ", nrow(datos_g6), "."),
    "Las reseñas no equivalen a reservas ni demuestran causalidad; el filtro de 150 afecta a la muestra."
  ))
} else {
  stop("No hay datos suficientes de ambas categorías para generar el gráfico 6. Revisa host_is_superhost.")
}

# ============================================================
# CONCLUSION GENERAL
# ============================================================
cat("\n", strrep("=", 68), "\nCONCLUSION GENERAL\n", sep = "")
cat("Los seis graficos permiten comparar precios, tipos de alojamiento,\n",
    "valoraciones, concentracion de anuncios, barrios y reseñas por Superhost.\n",
    "Los resultados describen anuncios de esta muestra; no demuestran\n",
    "causas ni garantizan precios o disponibilidad futuros.\n", sep = "")
cat(strrep("=", 68), "\n")

# OPTIONAL: Export all charts to PNG files in the same folder.
# Uncomment these lines if you want image files for your coursework.
# ggsave(file.path(carpeta, "grafico_1_boxplot.png"), g1, width = 10, height = 6, dpi = 300)
# ggsave(file.path(carpeta, "grafico_2_tipos.png"), g2, width = 10, height = 6, dpi = 300)
# ggsave(file.path(carpeta, "grafico_3_rating.png"), g3, width = 10, height = 6, dpi = 300)
# ggsave(file.path(carpeta, "grafico_4_anfitriones.png"), g4, width = 10, height = 6, dpi = 300)
# ggsave(file.path(carpeta, "grafico_5_barrios.png"), g5, width = 10, height = 6, dpi = 300)

# ggsave(file.path(carpeta, "grafico_6_superhost_resenas.png"), g6, width = 10, height = 6, dpi = 300)
