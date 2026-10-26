# ============================================================================
# PREPROCESAMIENTO EN R | AIRBNB CENTROEUROPA
# Equivalent logic to preprocesamiento.py. Run this script first.
# Required package: tidyverse
# ============================================================================

library(tidyverse)

# Locate input next to this script when run with Rscript; otherwise use working directory.
# Absolute Windows path shared by all project files.
carpeta <- "C:/Users/6/Desktop/R"
entrada <- file.path(carpeta, 'airbnb_centro_europa_master.csv')
salida <- file.path(carpeta, 'airbnb_centro_europa_clean_R.csv')
if (!file.exists(entrada)) stop(paste('No se encuentra el CSV maestro:', entrada))

cat('\n', strrep('=', 72), '\n', '🧹 PREPROCESAMIENTO DE AIRBNB EN R\n', strrep('=', 72), '\n', sep = '')
cat('🎯 OBJETIVO: generar desde el maestro un CSV comparable con Python.\n')

df <- readr::read_csv(entrada, show_col_types = FALSE, progress = FALSE)
filas_iniciales <- nrow(df)

# 1. Convert regional listing prices to EUR using fixed classroom rates.
tipos_cambio <- c('Alemania, Berlin' = 1, 'Austria, Viena' = 1,
                  'Republica Checa, Praga' = 24.36, 'Hungria, Budapest' = 363.30)
monedas <- c('Alemania, Berlin' = 'EUR', 'Austria, Viena' = 'EUR',
             'Republica Checa, Praga' = 'CZK', 'Hungria, Budapest' = 'HUF')
regiones_invalidas <- setdiff(unique(df$region_origen), names(tipos_cambio))
if (any(is.na(df$region_origen)) || length(regiones_invalidas) > 0) {
  stop('Hay regiones sin tipo de cambio asignado.')
}

df <- df %>%
  mutate(
    price_original = price,
    moneda_original = unname(monedas[region_origen]),
    tipo_cambio_por_eur = unname(tipos_cambio[region_origen]),
    precio_moneda_local = suppressWarnings(as.numeric(
      str_trim(str_replace_all(as.character(price), '[$,]', ''))
    )),
    precio_eur = round(precio_moneda_local / tipo_cambio_por_eur, 2)
  )

# 2. Replace missing bedrooms and beds with each region's median.
# A missing review rating remains NA (unknown), not 0.
df <- df %>%
  group_by(region_origen) %>%
  mutate(across(c(bedrooms, beds), ~ replace_na(.x, median(.x, na.rm = TRUE)))) %>%
  ungroup() %>%
  mutate(
    has_no_reviews = as.integer(is.na(review_scores_rating)),
    host_is_superhost = replace_na(as.character(host_is_superhost), 'f')
  )

# 3. Extract number of bathrooms from descriptive text.
# Preserve unknown bathroom counts as NA; 'half' means half a bathroom.
texto_banos <- str_to_lower(as.character(df$bathrooms_text))
df$bathrooms_num <- suppressWarnings(as.numeric(str_extract(texto_banos, '\\d+\\.?\\d*')))
medio_bano <- !is.na(texto_banos) & str_detect(texto_banos, 'half') & is.na(df$bathrooms_num)
df$bathrooms_num[medio_bano] <- 0.5

# 4. Apply range in EUR, not the original local currency.
nulos_precio <- sum(is.na(df$precio_eur))
inferiores <- sum(df$precio_eur < 10, na.rm = TRUE)
superiores <- sum(df$precio_eur > 1000, na.rm = TRUE)
df <- df %>% filter(!is.na(precio_eur), between(precio_eur, 10, 1000))
if (nrow(df) == 0) stop('El filtro ha eliminado todas las filas; no se guarda el CSV.')

# 5. Match Python's final schema: price is numeric in EUR; keep original text separately.
df <- df %>% mutate(price = precio_eur)
readr::write_excel_csv(df, salida, na = '')

cat('\n', strrep('-', 72), '\n', sep = '')
cat('🧠 CONCLUSIÓN: se han normalizado los precios, tratado nulos y creado variables.\n')
cat('🔎 EJEMPLO: price_original =', as.character(df$price_original[1]),
    '| precio_eur =', df$precio_eur[1], '| moneda =', df$moneda_original[1], '\n')
cat(sprintf('Registros originales: %s | Sin precio: %s | <10 €: %s | >1000 €: %s\n',
            filas_iniciales, nulos_precio, inferiores, superiores))
cat(sprintf('✅ Resultado: %s filas y %s columnas.\n', nrow(df), ncol(df)))
cat('📂 Guardado:', salida, '\n', strrep('=', 72), '\n')
