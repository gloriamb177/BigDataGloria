from pathlib import Path
import pandas as pd

# Work with files located next to this script
CARPETA: Path = Path(__file__).resolve().parent
ARCHIVO_ENTRADA: Path = CARPETA / "airbnb_centro_europa_master.csv"
ARCHIVO_SALIDA: Path = CARPETA / "airbnb_centro_europa_clean.csv"

# Reference rates provided for the classroom exercise: local units per EUR
TIPO_CAMBIO: dict[str, float] = {
    "Alemania, Berlin": 1.0,
    "Austria, Viena": 1.0,
    "Republica Checa, Praga": 24.36,
    "Hungria, Budapest": 363.30,
}
MONEDA: dict[str, str] = {
    "Alemania, Berlin": "EUR",
    "Austria, Viena": "EUR",
    "Republica Checa, Praga": "CZK",
    "Hungria, Budapest": "HUF",
}

print("1. Cargando dataset maestro...")
df: pd.DataFrame = pd.read_csv(ARCHIVO_ENTRADA, low_memory=False)
filas_iniciales: int = len(df)

# Reject unmapped regions instead of silently applying a wrong exchange rate
regiones_desconocidas: set[str] = set(df["region_origen"].dropna().unique()) - set(TIPO_CAMBIO)
if regiones_desconocidas or df["region_origen"].isna().any():
    raise ValueError(f"Regiones sin tipo de cambio: {regiones_desconocidas}")

print("2. Limpiando precios y convirtiendo monedas...")
df["price_original"] = df["price"]
df["moneda_original"] = df["region_origen"].map(MONEDA)
df["tipo_cambio_por_eur"] = df["region_origen"].map(TIPO_CAMBIO)
# Example: '$35,109.00' -> 35109.00 (not 35.109)
df["precio_moneda_local"] = pd.to_numeric(
    df["price"].astype("string").str.replace(r"[$,]", "", regex=True).str.strip(),
    errors="coerce",
)
df["precio_eur"] = (df["precio_moneda_local"] / df["tipo_cambio_por_eur"]).round(2)

print("3. Tratando nulos y creando variables...")
for columna in ("bedrooms", "beds"):
    # Impute from city median only for the classroom exercise
    df[columna] = df.groupby("region_origen")[columna].transform(
        lambda serie: serie.fillna(serie.median())
    )
# A null rating means unknown, not zero or a new property
df["has_no_reviews"] = df["review_scores_rating"].isna().astype(int)
df["host_is_superhost"] = df["host_is_superhost"].fillna("f")

texto_banos: pd.Series = df["bathrooms_text"].astype("string").str.lower()
df["bathrooms_num"] = pd.to_numeric(
    texto_banos.str.extract(r"(\d+\.?\d*)", expand=False), errors="coerce"
)
medio_bano: pd.Series = texto_banos.str.contains("half", na=False) & df["bathrooms_num"].isna()
df.loc[medio_bano, "bathrooms_num"] = 0.5
# Keep unknown bathroom counts missing instead of inventing one bathroom

print("4. Filtrando precios de 10 a 1.000 EUR...")
nulos_precio: int = int(df["precio_eur"].isna().sum())
inferiores: int = int((df["precio_eur"] < 10).sum())
superiores: int = int((df["precio_eur"] > 1000).sum())
df = df.loc[df["precio_eur"].between(10, 1000)].copy()
if df.empty:
    raise ValueError("El filtro dejo cero filas: revisa monedas y formatos; no se guardo el CSV.")

# Keep the teacher's 'price' variable numeric and denominated in EUR
# 'price_original' preserves the original text for checking assumptions
df["price"] = df["precio_eur"]
df.to_csv(ARCHIVO_SALIDA, index=False, encoding="utf-8-sig")
print(f"Filas originales: {filas_iniciales}")
print(f"Sin precio valido: {nulos_precio}")
print(f"Fuera de rango: {inferiores} inferiores y {superiores} superiores")
print(f"Filas conservadas: {len(df)}")
print(f"Archivo generado: {ARCHIVO_SALIDA.name}")
