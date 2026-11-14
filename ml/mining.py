"""
Modulo de Mineria de Datos para RSKitchen
- Ranking de platillos por unidades e ingresos.
- Tasa de pago por platillo.
- Clustering K-Means para segmentacion de platillos (volumen vs precio vs ingresos).
- Analisis de asociacion / co-ocurrencia de demanda entre platillos.
"""

import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.cluster import KMeans
from sklearn.preprocessing import StandardScaler

from data_loader import obtener_dataset

def calcular_rankings(df: pd.DataFrame) -> pd.DataFrame:
    """Calcula unidades, ingresos totales, ticket promedio y porcentaje de venta."""
    ranking = df.groupby("platillo").agg(
        pedidos=("numeroPedido", "count"),
        unidades=("cantidad", "sum"),
        ingresos_totales=("precio", "sum"),
        precio_promedio=("precio", "mean")
    ).reset_index()

    total_unidades = ranking["unidades"].sum()
    total_ingresos = ranking["ingresos_totales"].sum()

    ranking["pct_unidades"] = (ranking["unidades"] / total_unidades) * 100
    ranking["pct_ingresos"] = (ranking["ingresos_totales"] / total_ingresos) * 100
    ranking = ranking.sort_values(by="unidades", ascending=False).reset_index(drop=True)
    return ranking

def calcular_tasa_pago(df: pd.DataFrame) -> pd.DataFrame:
    """Calcula la tasa de pago efectivo por platillo."""
    tasa = df.groupby("platillo")["estado"].value_counts(normalize=True).unstack(fill_value=0)
    if "pagado" in tasa.columns:
        tasa["tasa_pago_pct"] = tasa["pagado"] * 100
    else:
        tasa["tasa_pago_pct"] = 0.0
    return tasa.reset_index()

def ejecutar_clustering_kmeans(df_ranking: pd.DataFrame, dir_salida: str, n_clusters: int = 3):
    """
    Segmenta los platillos mediante K-Means usando unidades vendidas y precio promedio.
    Genera el grafico en /ml/out/kmeans_clusters.png.
    """
    features = ["unidades", "precio_promedio"]
    X = df_ranking[features].values

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    kmeans = KMeans(n_clusters=n_clusters, random_state=42, n_init=10)
    df_ranking["cluster"] = kmeans.fit_predict(X_scaled)

    # Nombres descriptivos para los clusters segun centroides
    cluster_stats = df_ranking.groupby("cluster")[features].mean()
    print("\nCentroides de Clusters (K-Means):")
    print(cluster_stats)

    # Grafico de dispersion
    os.makedirs(dir_salida, exist_ok=True)
    plt.figure(figsize=(9, 6))
    palette = sns.color_palette("Set2", n_clusters)
    sns.scatterplot(
        data=df_ranking,
        x="unidades",
        y="precio_promedio",
        hue="cluster",
        palette=palette,
        s=220,
        style="cluster",
        legend="full"
    )

    for _, row in df_ranking.iterrows():
        plt.text(
            row["unidades"] + 8,
            row["precio_promedio"] + 400,
            row["platillo"],
            fontsize=9,
            weight="semibold"
        )

    plt.title("Segmentacion de Platillos por K-Means (Unidades vs Precio)")
    plt.xlabel("Total Unidades Vendidas")
    plt.ylabel("Precio Unitario Promedio (COP)")
    plt.tight_layout()
    ruta_img = os.path.join(dir_salida, "kmeans_clusters.png")
    plt.savefig(ruta_img, dpi=200)
    plt.close()
    print(f"[Mineria] Grafico de Clustering guardado en: {ruta_img}")

    return df_ranking

def analizar_reglas_asociacion_diaria(df: pd.DataFrame, dir_salida: str):
    """
    Analiza la co-demanda diaria entre platillos calculando la matriz de correlacion
    y pares de mayor co-ocurrencia en el mismo dia de servicio.
    """
    df["fecha"] = pd.to_datetime(df["CreacionPedido"]).dt.date
    canasta_diaria = df.pivot_table(
        index="fecha",
        columns="platillo",
        values="cantidad",
        aggfunc="sum",
        fill_value=0
    )

    corr = canasta_diaria.corr()

    plt.figure(figsize=(10, 8))
    sns.heatmap(corr, annot=True, cmap="coolwarm", fmt=".2f", vmin=-1, vmax=1)
    plt.title("Matriz de Co-ocurrencia y Correlacion de Demanda Diaria")
    plt.tight_layout()
    ruta_img = os.path.join(dir_salida, "correlacion_coocurrencia.png")
    plt.savefig(ruta_img, dpi=200)
    plt.close()
    print(f"[Mineria] Matriz de correlacion guardada en: {ruta_img}")
    return corr

def main():
    base_dir = os.path.dirname(__file__)
    dir_salida = os.path.join(base_dir, "out")
    df = obtener_dataset()

    print("=" * 60)
    print("1. RANKING DE PLATILLOS POR UNIDADES E INGRESOS")
    print("=" * 60)
    ranking = calcular_rankings(df)
    print(ranking.to_string(index=False))

    print("\n" + "=" * 60)
    print("2. TASA DE PAGO POR PLATILLO")
    print("=" * 60)
    tasa_pago = calcular_tasa_pago(df)
    print(tasa_pago.to_string(index=False))

    print("\n" + "=" * 60)
    print("3. CLUSTERING K-MEANS DE PLATILLOS")
    print("=" * 60)
    df_clustered = ejecutar_clustering_kmeans(ranking, dir_salida, n_clusters=3)
    print("\nAsignacion de clusters:")
    print(df_clustered[["platillo", "unidades", "precio_promedio", "cluster"]].to_string(index=False))

    print("\n" + "=" * 60)
    print("4. ANALISIS DE ASOCIACION Y CO-DEMANDA")
    print("=" * 60)
    corr = analizar_reglas_asociacion_diaria(df, dir_salida)

if __name__ == "__main__":
    main()
