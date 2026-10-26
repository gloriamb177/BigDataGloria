from pathlib import Path
import pandas as pd
import numpy as np
#Hola holaaaa
# ============================================================
# 🧭 CONFIGURACION GENERAL
# ============================================================

# Mostrar todas las columnas y evitar que pandas las sustituya por "..."
pd.set_option("display.max_columns", None)
pd.set_option("display.width", None)
pd.set_option("display.max_colwidth", None)

# 📂 Cargar el CSV limpio situado en la misma carpeta que este archivo
ARCHIVO = Path(__file__).resolve().parent / "airbnb_centro_europa_clean.csv"
#df = pd.read_csv(ARCHIVO, low_memory=False)
url = "https://enlace-directo-a-tu-archivo.csv" 
df = pd.read_csv(url)


if df.empty:
    raise ValueError("⚠️ El CSV limpio está vacío. Ejecuta primero preprocesamiento.py")

# 🔢 Asegurar que los campos numéricos se interpreten como números
for columna in [
    "precio_eur", "accommodates", "review_scores_rating",
    "number_of_reviews"
]:
    if columna in df.columns:
        df[columna] = pd.to_numeric(df[columna], errors="coerce")

print("\n" + "=" * 75)
print("🏡 EXPLORACIÓN DE DATOS DE AIRBNB — CENTROEUROPA")
print("=" * 75)
print(f"📍 Alojamientos analizados: {len(df):,}")
print(f"🌍 Países/ciudades identificados: {df['region_origen'].nunique()}")


def objetivo(texto: str) -> None:
    """Print a short objective and a visual section separator."""
    print("\n" + "━" * 72)
    print(f"🎯 OBJETIVO: {texto}")
    print("─" * 72)


def conclusion(texto: str, ejemplo: str) -> None:
    """Explain an observed result and show a compact data example."""
    print("─" * 72)
    print(f"🧠 CONCLUSIÓN: {texto}")
    print(f"🔎 EJEMPLO: {ejemplo}")
    print("━" * 72)



# ============================================================
# 🏆 EJERCICIO 1. LOS 5 ALOJAMIENTOS MAS CAROS
# ============================================================

print("\n🏆 1. TOP 5 ALOJAMIENTOS MÁS CAROS (EUR)")
objetivo("Identificar los cinco anuncios con mayor precio en euros.")
columnas_top = ["name", "region_origen", "precio_eur", "room_type"]
print(
    df.nlargest(5, "precio_eur")[columnas_top]
    .to_string(index=False)
)
mas_caro = df.nlargest(1, "precio_eur")
if not mas_caro.empty:
    fila = mas_caro.iloc[0]
    conclusion(
        "Este anuncio tiene el mayor precio registrado en el conjunto filtrado.",
        f"{fila['region_origen']}: {fila['precio_eur']:.2f} € por noche."
    )


# ============================================================
# 📊 EJERCICIO 2. RESUMEN POR PAIS/CIUDAD
# ============================================================

print("\n📊 2. RESUMEN POR PAÍS/CIUDAD")
objetivo("Comparar cantidad de anuncios, precios y puntuaciones por ciudad.")
resumen = df.groupby("region_origen").agg(
    alojamientos=("id", "count"),
    precio_medio_eur=("precio_eur", "mean"),
    precio_mediano_eur=("precio_eur", "median"),
    valoracion_media=("review_scores_rating", "mean"),
).round(2)

fila_total = pd.DataFrame([{
    "alojamientos": df["id"].count(),
    "precio_medio_eur": df["precio_eur"].mean(),
    "precio_mediano_eur": df["precio_eur"].median(),
    "valoracion_media": df["review_scores_rating"].mean(),
}], index=["🌍 TOTAL DATASET"])

resumen.index.name = "📍 País/ciudad"
resumen = pd.concat([fila_total, resumen])
print(resumen.to_string())
ciudades_resumen = resumen.drop(index="🌍 TOTAL DATASET")
barata = ciudades_resumen["precio_mediano_eur"].idxmin()
conclusion(
    "La mediana permite comparar ciudades sin que unos pocos precios extremos dominen la lectura.",
    f"Menor mediana: {barata}, {ciudades_resumen.loc[barata, 'precio_mediano_eur']:.2f} €."
)


# ============================================================
# ⭐ EJERCICIO 3. COMPARACION DE SUPERHOSTS
# ============================================================

print("\n⭐ 3. COMPARACIÓN DE SUPERHOSTS")
objetivo("Comparar precio y valoración de anuncios según el distintivo Superhost.")
con_valoracion = df.loc[df["review_scores_rating"].notna()].copy()

superhost = con_valoracion.groupby("host_is_superhost", dropna=False).agg(
    alojamientos=("id", "count"),
    precio_medio_eur=("precio_eur", "mean"),
    valoracion_media=("review_scores_rating", "mean"),
).round(2)

superhost.index = [
    "⭐ Superhost" if valor is True or str(valor).lower() == "t"
    else "🏠 No superhost" if valor is False or str(valor).lower() == "f"
    else "❔ Sin dato"
    for valor in superhost.index
]
print(superhost.to_string())
if not superhost.empty:
    grupo_mejor = superhost["valoracion_media"].idxmax()
    conclusion(
        "La tabla compara anuncios con puntuación disponible; una diferencia no demuestra causalidad.",
        f"Mayor valoración media: {grupo_mejor}, {superhost.loc[grupo_mejor, 'valoracion_media']:.2f}/5."
    )


# ============================================================
# 🔎 EJERCICIO 4. BUSQUEDA DE ALOJAMIENTOS
# ============================================================

print("\n🔎 4. BÚSQUEDA DE ALOJAMIENTOS")

# 4.1: Keep the professor's Vienna multi-criteria search.
print("\n🏠 4.1. VIENA: VIVIENDA ENTERA, 4 PERSONAS, <80 EUR Y VALORACIÓN >=4")
objetivo("Buscar apartamentos enteros en Viena que cumplan cuatro requisitos.")
filtro_viena = (
    df["region_origen"].eq("Austria, Viena")
    & df["room_type"].eq("Entire home/apt")
    & df["accommodates"].ge(4)
    & df["precio_eur"].lt(80)
    & df["review_scores_rating"].ge(4)
)
oportunidades = df.loc[filtro_viena]
print(f"✅ Coincidencias encontradas: {len(oportunidades)}")
columnas_oportunidades = [
    "name", "neighbourhood_cleansed", "precio_eur", "review_scores_rating"
]
print(oportunidades[columnas_oportunidades].head(5).to_string(index=False))
if not oportunidades.empty:
    candidato = oportunidades.nsmallest(1, "precio_eur").iloc[0]
    conclusion(
        f"Hay {len(oportunidades)} anuncios que cumplen simultáneamente los requisitos.",
        f"El menor precio entre ellos es {candidato['precio_eur']:.2f} €; barrio: {candidato['neighbourhood_cleansed']}."
    )
else:
    conclusion("Ningún anuncio cumple todos los filtros actuales.", "Prueba a modificar un umbral.")

# ============================================================
# 🛏️ EJERCICIO 5. TIPOS DE ALOJAMIENTO POR PAIS/CIUDAD
# ============================================================

print("\n🛏️ 5. TIPOS DE ALOJAMIENTO POR PAÍS/CIUDAD")
objetivo("Contar los distintos tipos de alojamientos en cada ciudad.")
tipos = pd.crosstab(df["region_origen"], df["room_type"])
tipos.index.name = "📍 País/ciudad"
tipos.columns = [
    f"🏠 {col}" if col == "Entire home/apt"
    else f"🛌 {col}" if col == "Private room"
    else f"🚪 {col}" if col == "Shared room"
    else f"🏨 {col}" if col == "Hotel room"
    else f"🧳 {col}"
    for col in tipos.columns
]
fila_total_tipos = tipos.sum(axis=0).to_frame().T
fila_total_tipos.index = ["🌍 TOTAL DATASET"]
print(pd.concat([fila_total_tipos, tipos]).to_string())
tipo_mas_comun = df["room_type"].value_counts().head(1)
if not tipo_mas_comun.empty:
    conclusion(
        "Las modalidades de alojamiento no tienen el mismo peso en la muestra.",
        f"La más frecuente es {tipo_mas_comun.index[0]}: {int(tipo_mas_comun.iloc[0]):,} anuncios."
    )


# ============================================================
# 💶 EJERCICIO 6. PRECIO MEDIANO POR HUESPED Y PAIS/CIUDAD
# ============================================================

print("\n💶 6. PRECIO MEDIANO POR HUÉSPED Y PAÍS/CIUDAD")
objetivo("Comparar el coste por huésped suponiendo ocupación completa.")
capacidad_valida = df["accommodates"].gt(0)
df["precio_por_huesped_eur"] = (
    df["precio_eur"] / df["accommodates"].where(capacidad_valida)
).round(2)

precio_huesped = df.groupby("region_origen")["precio_por_huesped_eur"].median().round(2)
precio_huesped = pd.concat([
    pd.Series(
        {"🌍 TOTAL DATASET": df["precio_por_huesped_eur"].median().round(2)}
    ),
    precio_huesped
])
precio_huesped.index.name = "📍 País/ciudad"
print(precio_huesped.to_string())
por_ciudad = precio_huesped.drop(index="🌍 TOTAL DATASET").dropna()
if not por_ciudad.empty:
    ciudad_economica = por_ciudad.idxmin()
    conclusion(
        "El coste por persona supone repartir el precio entre todas las plazas disponibles.",
        f"Menor mediana: {ciudad_economica}, {por_ciudad.min():.2f} €/huésped."
    )


# ============================================================
# 🗺️ EJERCICIO 7. LOS 10 BARRIOS MAS ECONOMICOS CON AL MENOS 30 ANUNCIOS
# ============================================================

print("\n🗺️ 7. BARRIOS CON AL MENOS 30 ALOJAMIENTOS: LOS 10 MÁS ECONÓMICOS")
objetivo("Identificar barrios con menor precio mediano y al menos 30 anuncios.")
barrios = df.groupby(
    ["region_origen", "neighbourhood_cleansed"]
).agg(
    alojamientos=("id", "count"),
    precio_mediano_eur=("precio_eur", "median")
)
barrios = barrios.loc[barrios["alojamientos"].ge(30)]
top_barrios = barrios.nsmallest(10, "precio_mediano_eur")
print(top_barrios.round(2).to_string())
if not top_barrios.empty:
    ciudad_barrio, nombre_barrio = top_barrios.index[0]
    conclusion(
        "Se utiliza la mediana y un mínimo de 30 anuncios para evitar muestras demasiado pequeñas.",
        f"Menor mediana: {nombre_barrio} ({ciudad_barrio}), {top_barrios.iloc[0]['precio_mediano_eur']:.2f} €."
    )


# ============================================================
# 💸 EJERCICIO 8. DISTRIBUCION POR TRAMOS DE PRECIO
# ============================================================

print("\n💸 8. DISTRIBUCIÓN POR TRAMOS DE PRECIO (EUR)")
objetivo("Contar cuántos anuncios hay en cada tramo de precios.")
df["tramo_precio"] = pd.cut(
    df["precio_eur"],
    bins=[10, 50, 100, 150, 250, 500, 1000],
    labels=["10-50 €", "50-100 €", "100-150 €", "150-250 €",
            "250-500 €", "500-1000 €"],
    include_lowest=True,
)
distribucion_precios = pd.crosstab(df["region_origen"], df["tramo_precio"])
fila_total_tramos = distribucion_precios.sum(axis=0).to_frame().T
fila_total_tramos.index = ["🌍 TOTAL DATASET"]
distribucion_precios.index.name = "📍 País/ciudad"
print(pd.concat([fila_total_tramos, distribucion_precios]).to_string())
tramo_principal = distribucion_precios.sum(axis=0).idxmax()
conclusion(
    "Los intervalos permiten identificar dónde se concentran los precios anunciados.",
    f"Tramo con más anuncios: {tramo_principal}, {int(distribucion_precios[tramo_principal].sum()):,} registros."
)


# ============================================================
# 👥 EJERCICIO 9. PRECIO MEDIANO SEGUN CAPACIDAD
# ============================================================

print("\n👥 9. PRECIO MEDIANO SEGÚN CAPACIDAD (1 A 8 HUÉSPEDES)")
objetivo("Observar cómo varía el precio según la capacidad de huéspedes.")
por_capacidad = df.loc[df["accommodates"].between(1, 8)].groupby(
    "accommodates"
).agg(
    alojamientos=("id", "count"),
    precio_mediano_eur=("precio_eur", "median")
).round(2)
por_capacidad.index = [f"👥 {n} huésped(es)" for n in por_capacidad.index]
print(por_capacidad.to_string())
if not por_capacidad.empty:
    primer_grupo = por_capacidad.iloc[0]
    ultimo_grupo = por_capacidad.iloc[-1]
    conclusion(
        "Podemos comparar las medianas por capacidad, sin suponer una relación causal.",
        f"{por_capacidad.index[0]}: {primer_grupo['precio_mediano_eur']:.2f} €; "
        f"{por_capacidad.index[-1]}: {ultimo_grupo['precio_mediano_eur']:.2f} €."
    )


# ============================================================
# ⭐ EJERCICIO 10. VALORACIONES Y ACTIVIDAD DE RESENAS
# ============================================================

print("\n⭐ 10. COBERTURA DE VALORACIONES Y ACTIVIDAD DE RESEÑAS")
objetivo("Medir cuántos anuncios tienen valoración y cuántas reseñas acumulan.")
calidad = df.groupby("region_origen").agg(
    alojamientos=("id", "count"),
    con_valoracion=("review_scores_rating", "count"),
    resenas_totales=("number_of_reviews", "sum"),
)
calidad["porcentaje_con_valoracion"] = (
    100 * calidad["con_valoracion"] / calidad["alojamientos"]
).round(1)

fila_total_calidad = pd.DataFrame([{
    "alojamientos": df["id"].count(),
    "con_valoracion": df["review_scores_rating"].count(),
    "resenas_totales": df["number_of_reviews"].sum(),
    "porcentaje_con_valoracion": (
        100 * df["review_scores_rating"].notna().sum() / df["id"].count()
        if df["id"].count() else 0
    ),
}], index=["🌍 TOTAL DATASET"]).round(1)

calidad.index.name = "📍 País/ciudad"
print(pd.concat([fila_total_calidad, calidad]).to_string())
ciudad_cobertura = calidad["porcentaje_con_valoracion"].idxmax()
conclusion(
    "El porcentaje indica disponibilidad de puntuaciones, no calidad media.",
    f"Mayor cobertura: {ciudad_cobertura}, {calidad.loc[ciudad_cobertura, 'porcentaje_con_valoracion']:.1f} %."
)


# ============================================================
# 🏘️ EJERCICIO 11. CONCENTRACION DE ANUNCIOS POR ANFITRION
# ============================================================

print("\n" + "=" * 75)
print("🏘️ 11. CONCENTRACIÓN DE ALOJAMIENTOS POR ANFITRIÓN Y CIUDAD")
objetivo("Estudiar cómo se distribuyen anuncios y precios según tamaño del anfitrión.")
print("=" * 75)

GRUPOS = [
    "🏠 1 alojamiento", "🏘️ 2-4 alojamientos", "🏢 5-10 alojamientos", "🏙️ Más de 10 alojamientos"
]

# Count listings per host and city; this does not establish legal ownership.
datos = df.dropna(subset=["host_id", "region_origen"]).copy()
datos["num_alojamientos_host"] = datos.groupby(
    ["host_id", "region_origen"]
)["id"].transform("count")

datos["grupo_host"] = pd.cut(
    datos["num_alojamientos_host"],
    bins=[0, 1, 4, 10, float("inf")],
    labels=GRUPOS,
    include_lowest=True,
)

# 11.1: Count listings by host size and city.
print("\n🏠 11.1. NÚMERO DE ALOJAMIENTOS POR GRUPO")
tabla_anuncios = pd.crosstab(datos["region_origen"], datos["grupo_host"])
tabla_anuncios = tabla_anuncios.reindex(columns=GRUPOS, fill_value=0)
print(pd.concat([
    pd.DataFrame([tabla_anuncios.sum()], index=["🌍 TOTAL DATASET"]),
    tabla_anuncios,
]).to_string())

# 11.2: Show percentages of listings within each city and in the whole dataset.
print("\n📈 11.2. PORCENTAJE DE ALOJAMIENTOS POR GRUPO")
porcentaje_anuncios = tabla_anuncios.div(
    tabla_anuncios.sum(axis=1).replace(0, np.nan), axis=0
).mul(100).round(2)
total_porcentaje = (tabla_anuncios.sum() / len(datos) * 100).round(2)
print(pd.concat([
    pd.DataFrame([total_porcentaje], index=["🌍 TOTAL DATASET"]),
    porcentaje_anuncios,
]).to_string())

# 11.3: Count distinct hosts; include percentages in the same table.
print("\n👤 11.3. NÚMERO Y PORCENTAJE DE ANFITRIONES POR GRUPO")
anfitriones = datos.drop_duplicates(subset=["host_id", "region_origen"])
tabla_hosts = pd.crosstab(anfitriones["region_origen"], anfitriones["grupo_host"])
tabla_hosts = tabla_hosts.reindex(columns=GRUPOS, fill_value=0)
total_hosts = pd.DataFrame([tabla_hosts.sum()], index=["🌍 TOTAL DATASET"])
tabla_hosts = pd.concat([total_hosts, tabla_hosts])
porcentaje_hosts = tabla_hosts.div(
    tabla_hosts.sum(axis=1).replace(0, np.nan), axis=0
).mul(100).round(2)
print("👥 NÚMERO DE ANFITRIONES:")
print(tabla_hosts.to_string())
print("📊 PORCENTAJE DE ANFITRIONES:")
print(porcentaje_hosts.to_string())

# 11.4: Compare mean and median listing prices by host size and city.
print("\n💶 11.4. PRECIO MEDIO Y MEDIANO POR GRUPO DE ANFITRIONES")
resumen_precios = datos.groupby(
    ["region_origen", "grupo_host"], observed=True
)["precio_eur"].agg(precio_medio_eur="mean", precio_mediano_eur="median")
print(resumen_precios.round(2).to_string())
print("ℹ️ Nota: el número de anuncios no demuestra la propiedad legal de los inmuebles.")
conclusion(
    "Los grupos describen concentración de anuncios, no titularidad inmobiliaria ni causalidad de precios.",
    f"Anuncios clasificados: {len(datos):,}; anfitriones distintos por ciudad: {len(anfitriones):,}."
)


# ============================================================
# 🏅 EJERCICIO 12. TOP 10 ALOJAMIENTOS BARATOS, VALORADOS Y CÉNTRICOS
# ============================================================

# EXERCISE 12: Find affordable, highly rated listings in selected central neighbourhoods.
print("\n🏅 12. TOP 10 MÁS BARATOS, BIEN VALORADOS Y CÉNTRICOS")
objetivo("Buscar los diez anuncios de menor precio con nota >= 4,7, >= 20 reseñas y barrio seleccionado.")
BARRIOS_CENTRICOS: dict[str, list[str]] = {
    "Alemania, Berlin": ["Alexanderplatz", "Brunnenstr. Süd", "Südliche Friedrichstadt"],
    "Austria, Viena": ["Innere Stadt", "Neubau", "Wieden", "Mariahilf"],
    "Republica Checa, Praga": ["Praha 1", "Praha 2"],
    "Hungria, Budapest": ["V. kerület", "VI. kerület", "VII. kerület"],
}
filtro_centrico = pd.Series(False, index=df.index)
for ciudad, barrios_seleccionados in BARRIOS_CENTRICOS.items():
    filtro_centrico |= (
        df["region_origen"].eq(ciudad)
        & df["neighbourhood_cleansed"].isin(barrios_seleccionados)
    )

candidatos = df.loc[
    filtro_centrico
    & df["review_scores_rating"].ge(4.7)
    & df["number_of_reviews"].ge(20)
].copy()

top_10 = candidatos.sort_values(
    by=["precio_eur", "review_scores_rating", "number_of_reviews"],
    ascending=[True, False, False],
).head(10)
# Make the terminal table readable: abbreviate names and omit long URLs.
top_10_vista = top_10.copy()
# Create concise but recognizable listing titles for console output.
def nombre_corto(nombre: object) -> str:
    """Return a brief listing label without losing its main description."""
    texto: str = str(nombre).strip() if pd.notna(nombre) else "Sin nombre"
    normalizado: str = texto.lower()
    if "lovely room" in normalizado:
        return "Lovely Room"
    if "estudio" in normalizado or "studio" in normalizado:
        return "Estudio"
    if "capsule" in normalizado:
        return "Capsule Bed"
    if "generator mitte" in normalizado:
        return "Generator Mitte"
    if "female" in normalizado and "bed" in normalizado:
        return "Female Dorm Bed"
    if "bed" in normalizado and "6-" in normalizado:
        return "Bed in 6-Bed Room"
    if "private room" in normalizado:
        return "Private Room"
    return texto[:24].rstrip(" -,.!")


top_10_vista["Alojamiento"] = top_10_vista["name"].map(nombre_corto)
top_10_vista["Ciudad"] = top_10_vista["region_origen"].map({
    "Alemania, Berlin": "Berlín",
    "Austria, Viena": "Viena",
    "Republica Checa, Praga": "Praga",
    "Hungria, Budapest": "Budapest",
}).fillna(top_10_vista["region_origen"])
top_10_vista["Barrio"] = top_10_vista["neighbourhood_cleansed"].fillna("-").str.slice(0, 20)
top_10_vista = top_10_vista.rename(columns={
    "precio_eur": "Precio €",
    "review_scores_rating": "Nota",
    "number_of_reviews": "Reseñas",
})

print(f"✅ Coincidencias encontradas: {len(candidatos)}")

# Use OSC 8 hyperlinks so the URL stays hidden behind a short label.
# Click support depends on the terminal (Windows Terminal or VS Code are recommended).
def enlace_terminal(url: str) -> str:
    """Return a terminal hyperlink labelled 'PINCHA AQUÍ'."""
    if not isinstance(url, str) or not url.startswith(("https://", "http://")):
        return "-"
    return f"\033]8;;{url}\033\\PINCHA AQUÍ\033]8;;\033\\"

# Print compact columns manually to avoid URL wrapping in Pandas tables.
print(f"{'Alojamiento':24} {'Ciudad':9} {'Barrio':20} {'Precio €':>9} {'Nota':>5} {'Reseñas':>7}  Enlace")
print("-" * 100)
for _, alojamiento in top_10_vista.iterrows():
    enlace = enlace_terminal(alojamiento.get("listing_url", ""))
    print(
        f"{str(alojamiento['Alojamiento'])[:24]:24} "
        f"{str(alojamiento['Ciudad'])[:9]:9} "
        f"{str(alojamiento['Barrio'])[:20]:20} "
        f"{alojamiento['Precio €']:>9.2f} "
        f"{alojamiento['Nota']:>5.2f} "
        f"{int(alojamiento['Reseñas']):>7}  {enlace}"
    )

print("ℹ️ Haz clic en 'PINCHA AQUÍ' si tu terminal admite hipervínculos OSC 8.")
print("ℹ️ Ubicación céntrica aproximada según barrios seleccionados.")
if not top_10.empty:
    mejor = top_10.iloc[0]
    conclusion(
        "Son los diez de menor precio entre los candidatos; la ubicación es una selección orientativa de barrios.",
        f"{len(candidatos):,} candidatos; más barato: {mejor['precio_eur']:.2f} €, "
        f"nota {mejor['review_scores_rating']:.2f}/5."
    )
else:
    conclusion("No hay anuncios que cumplan todos los criterios.", "Revisa barrios o umbrales.")

# ============================================================
# 🌍 CONCLUSIONES GLOBALES Y RECOMENDACIÓN ESTRATÉGICA
# ============================================================

print("\n" + "═" * 72)
print("🌍 CONCLUSIONES FINALES DEL ANÁLISIS")
print("═" * 72)

# Compare city medians instead of averages to reduce outlier effects.
medianas_ciudad: pd.Series = df.groupby("region_origen")["precio_eur"].median().dropna()
if not medianas_ciudad.empty:
    ciudad_mas_economica: str = str(medianas_ciudad.idxmin())
    ciudad_mas_cara: str = str(medianas_ciudad.idxmax())
    print(
        f"💶 1. Precio: menor mediana en {ciudad_mas_economica} "
        f"({medianas_ciudad.min():.2f} €); mayor en {ciudad_mas_cara} "
        f"({medianas_ciudad.max():.2f} €)."
    )

# Identify the most common price band using the bins from exercise 8.
tramos_totales: pd.Series = df["tramo_precio"].value_counts(dropna=True)
if not tramos_totales.empty:
    tramo_frecuente: str = str(tramos_totales.idxmax())
    porcentaje_tramo: float = 100 * float(tramos_totales.max()) / len(df)
    print(
        f"📊 2. Mercado: el tramo {tramo_frecuente} concentra "
        f"{tramos_totales.max():,} anuncios ({porcentaje_tramo:.1f} %)."
    )

# Compare how many listings belong to hosts with five or more listings per city.
if not datos.empty:
    anuncios_host_grande: int = int(datos["num_alojamientos_host"].ge(5).sum())
    cuota_grandes: float = 100 * anuncios_host_grande / len(datos)
    print(
        f"🏘️ 3. Anfitriones: {cuota_grandes:.1f} % de los anuncios con "
        "anfitrión identificado pertenecen a cuentas con 5+ anuncios "
        "en la misma ciudad."
    )

print("─" * 72)
print("🧭 RECOMENDACIÓN ESTRATÉGICA")
print(
    "Comparar alojamientos por ciudad y barrio usando precio mediano, "
    "tipo de habitación, capacidad y valoración; no elegir solo por "
    "el precio más bajo."
)
print(
    "⚠️ Los datos son anuncios filtrados, no reservas confirmadas; "
    "la centralidad de los barrios y las monedas de origen deben verificarse."
)
print("═" * 72)

# ============================================================
# ✅ FIN DEL ANALISIS
# ============================================================

print("\n" + "=" * 75)
print("✅ EXPLORACIÓN FINALIZADA")
print("ℹ️ Los importes están expresados en euros (EUR).")
print("⚠️ 5 o más anuncios indica concentración, no propiedad legal.")
print("=" * 75)
