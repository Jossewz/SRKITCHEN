"""
Modulo EDA (Exploratory Data Analysis) para RSKitchen
Realiza limpieza de datos, estadisticas descriptivas y generacion de graficos en /ml/out.
"""

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Configuracion de estilo visual para los graficos
sns.set_theme(style="whitegrid")
plt.rcParams.update({
    "font.size": 11,
    "figure.titlesize": 14,
    "axes.titlesize": 12,
    "axes.labelsize": 11
})

def cargar_y_limpiar_datos(ruta_csv: str) -> pd.DataFrame:
    """
    Carga el dataset y ejecuta tareas de limpieza:
    1. Tratamiento de nulos.
    2. Deduplicacion de registros.
    3. Validacion y filtrado de precio > 0 y cantidad > 0.
    4. Conversion y formateo de fechas.
    """
    if not os.path.exists(ruta_csv):
        raise FileNotFoundError(f"No se encontro el archivo de datos en: {ruta_csv}")

    df = pd.read_csv(ruta_csv)
    n_inicial = len(df)

    # 1. Eliminar duplicados exactos si existieran
    df = df.drop_duplicates()
    n_sin_duplicados = len(df)

    # 2. Filtrar nulos en variables clave
    df = df.dropna(subset=["numeroPedido", "platillo", "precio", "CreacionPedido"])

    # 3. Filtrar condiciones logicas de negocio
    df["precio"] = pd.to_numeric(df["precio"], errors="coerce")
    df = df[df["precio"] > 0]
    if "cantidad" in df.columns:
        df["cantidad"] = pd.to_numeric(df["cantidad"], errors="coerce").fillna(1)
        df = df[df["cantidad"] > 0]

    # 4. Formato de fecha
    df["CreacionPedido"] = pd.to_datetime(df["CreacionPedido"])
    df["fecha"] = df["CreacionPedido"].dt.date
    df["mes_anio"] = df["CreacionPedido"].dt.to_period("M").astype(str)
    df["hora"] = df["CreacionPedido"].dt.hour

    print(f"[Limpieza] Registros iniciales: {n_inicial} | Registros limpios: {len(df)}")
    return df

def generar_graficos_eda(df: pd.DataFrame, dir_salida: str):
    """Genera y guarda los graficos exploratorios requeridos en dir_salida."""
    os.makedirs(dir_salida, exist_ok=True)

    # 1. Ventas e ingresos por platillo
    fig, ax = plt.subplots(figsize=(10, 5))
    agrup_platillo = df.groupby("platillo").agg(
        unidades=("cantidad", "sum"),
        ingresos=("precio", "sum")
    ).sort_values("unidades", ascending=False).reset_index()

    sns.barplot(
        data=agrup_platillo,
        x="unidades",
        y="platillo",
        palette="viridis",
        ax=ax
    )
    ax.set_title("Ventas Totales por Platillo (Unidades)")
    ax.set_xlabel("Unidades Vendidas")
    ax.set_ylabel("Platillo")
    plt.tight_layout()
    ruta_g1 = os.path.join(dir_salida, "eda_ventas_platillo.png")
    plt.savefig(ruta_g1, dpi=200)
    plt.close()
    print(f"[Grafico] Guardado: {ruta_g1}")

    # 2. Ventas por dia de la semana
    dias_orden = ["Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo"]
    ventas_dia = df["dia_semana"].value_counts().reindex(dias_orden).fillna(0)

    fig, ax = plt.subplots(figsize=(8, 4.5))
    sns.barplot(x=ventas_dia.index, y=ventas_dia.values, palette="rocket", ax=ax)
    ax.set_title("Distribucion de Pedidos por Dia de la Semana")
    ax.set_xlabel("Dia de la Semana")
    ax.set_ylabel("Numero de Pedidos")
    plt.xticks(rotation=25)
    plt.tight_layout()
    ruta_g2 = os.path.join(dir_salida, "eda_ventas_dia_semana.png")
    plt.savefig(ruta_g2, dpi=200)
    plt.close()
    print(f"[Grafico] Guardado: {ruta_g2}")

    # 3. Serie temporal diaria (volumen e ingresos)
    serie_diaria = df.groupby("fecha").agg(
        pedidos=("numeroPedido", "count"),
        ingresos=("precio", "sum")
    ).reset_index()
    serie_diaria["fecha"] = pd.to_datetime(serie_diaria["fecha"])

    fig, ax = plt.subplots(figsize=(12, 5))
    ax.plot(serie_diaria["fecha"], serie_diaria["pedidos"], color="#1f77b4", linewidth=1.5, label="Pedidos diarios")
    serie_diaria["media_movil_7d"] = serie_diaria["pedidos"].rolling(7, min_periods=1).mean()
    ax.plot(serie_diaria["fecha"], serie_diaria["media_movil_7d"], color="#d62728", linewidth=2, label="Media Movil 7D")

    ax.set_title("Evolucion Temporal Diaria de la Demanda (2026-01 a 2026-10)")
    ax.set_xlabel("Fecha")
    ax.set_ylabel("Cantidad de Pedidos")
    ax.legend()
    plt.tight_layout()
    ruta_g3 = os.path.join(dir_salida, "eda_serie_temporal.png")
    plt.savefig(ruta_g3, dpi=200)
    plt.close()
    print(f"[Grafico] Guardado: {ruta_g3}")

    # 4. Distribucion por Canal y Sede
    fig, axes = plt.subplots(1, 2, figsize=(12, 4.5))
    sns.countplot(data=df, x="canal", palette="crest", ax=axes[0])
    axes[0].set_title("Distribucion por Canal de Venta")
    axes[0].set_xlabel("Canal")
    axes[0].set_ylabel("Pedidos")

    sns.countplot(data=df, x="sede", palette="magma", ax=axes[1])
    axes[1].set_title("Distribucion por Sede")
    axes[1].set_xlabel("Sede")
    axes[1].set_ylabel("Pedidos")
    plt.tight_layout()
    ruta_g4 = os.path.join(dir_salida, "eda_canal_sede.png")
    plt.savefig(ruta_g4, dpi=200)
    plt.close()
    print(f"[Grafico] Guardado: {ruta_g4}")

def main():
    directorio_ml = os.path.dirname(__file__)
    ruta_datos = os.path.join(directorio_ml, "data", "dataset_sintetico.csv")
    dir_salida = os.path.join(directorio_ml, "out")

    df_limpio = cargar_y_limpiar_datos(ruta_datos)
    generar_graficos_eda(df_limpio, dir_salida)
    print("\n[OK] Analisis Exploratorio completado exitosamente.")

if __name__ == "__main__":
    main()
