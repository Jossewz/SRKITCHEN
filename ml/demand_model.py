"""
Modelo Principal de Demanda de Platillos para RSKitchen (Mineria de Datos II)
- Agregacion por (platillo, fecha).
- Ingenieria de variables: dia de la semana, quincena, lags (t-1, t-7), media movil 7d, codificacion de platillo.
- Division temporal estricta (Train: meses 1 a 8 | Test: meses 9 y 10).
- Comparacion de Baseline, Regresion Lineal y Random Forest Regressor.
- Metricas reportadas en Test: MAE, RMSE, R2.
- Serializacion del mejor modelo con joblib.
"""

import os
import joblib
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, root_mean_squared_error, r2_score

from data_loader import obtener_dataset

def preparar_datos_diarios(df: pd.DataFrame) -> pd.DataFrame:
    """Agrega transacciones por (platillo, fecha) y genera una serie temporal continua."""
    df["fecha"] = pd.to_datetime(df["CreacionPedido"]).dt.date
    platillos = df["platillo"].unique()
    rango_fechas = pd.date_range(df["fecha"].min(), df["fecha"].max(), freq="D").date

    # Grid completo fecha x platillo para no tener fechas faltantes
    grid = pd.MultiIndex.from_product([rango_fechas, platillos], names=["fecha", "platillo"]).to_frame().reset_index(drop=True)

    agregado = df.groupby(["fecha", "platillo"]).agg(
        demanda=("cantidad", "sum"),
        ingresos=("precio", "sum"),
        pedidos=("numeroPedido", "count")
    ).reset_index()

    panel = pd.merge(grid, agregado, on=["fecha", "platillo"], how="left").fillna(0)
    panel["demanda"] = panel["demanda"].astype(float)
    panel = panel.sort_values(by=["platillo", "fecha"]).reset_index(drop=True)
    return panel

def construir_caracteristicas(panel: pd.DataFrame) -> pd.DataFrame:
    """Crea variables explicativas temporales, lags y medias moviles por platillo."""
    panel["fecha_dt"] = pd.to_datetime(panel["fecha"])
    panel["dia_semana"] = panel["fecha_dt"].dt.weekday
    panel["dia_mes"] = panel["fecha_dt"].dt.day
    panel["mes"] = panel["fecha_dt"].dt.month
    panel["es_fin_semana"] = panel["dia_semana"].isin([4, 5, 6]).astype(int)
    panel["es_quincena"] = panel["dia_mes"].isin([15, 16, 30, 31]).astype(int)

    # Lags y medias moviles por platillo
    dfs_platillo = []
    for p in panel["platillo"].unique():
        sub = panel[panel["platillo"] == p].copy()
        sub["lag_1"] = sub["demanda"].shift(1)
        sub["lag_7"] = sub["demanda"].shift(7)
        sub["media_movil_7"] = sub["demanda"].shift(1).rolling(7, min_periods=1).mean()
        sub["media_movil_14"] = sub["demanda"].shift(1).rolling(14, min_periods=1).mean()
        dfs_platillo.append(sub)

    df_fe = pd.concat(dfs_platillo, axis=0).dropna().reset_index(drop=True)
    return df_fe

def entrenar_y_evaluar(df_fe: pd.DataFrame, dir_modelos: str, dir_salida: str):
    """Ejecuta la validacion temporal y compara los modelos."""
    os.makedirs(dir_modelos, exist_ok=True)
    os.makedirs(dir_salida, exist_ok=True)

    # Division temporal: Train <= 2026-08-31, Test >= 2026-09-01 (ultimos 2 meses)
    corte_temporal = pd.to_datetime("2026-09-01").date()

    train = df_fe[df_fe["fecha"] < corte_temporal].copy()
    test = df_fe[df_fe["fecha"] >= corte_temporal].copy()

    print(f"\n[Validacion Temporal] Registros Train (Ene-Ago): {len(train):,} | Test (Sep-Oct): {len(test):,}")

    columnas_numericas = [
        "dia_semana", "dia_mes", "mes", "es_fin_semana", "es_quincena",
        "lag_1", "lag_7", "media_movil_7", "media_movil_14"
    ]

    # One-hot encoding de platillo
    train_encoded = pd.get_dummies(train[["platillo"] + columnas_numericas], columns=["platillo"], drop_first=True)
    test_encoded = pd.get_dummies(test[["platillo"] + columnas_numericas], columns=["platillo"], drop_first=True)

    # Alinear columnas
    train_encoded, test_encoded = train_encoded.align(test_encoded, join="left", axis=1, fill_value=0)

    X_train = train_encoded.values
    y_train = train["demanda"].values
    X_test = test_encoded.values
    y_test = test["demanda"].values

    features_cols = list(train_encoded.columns)

    # 1. Baseline: prediccion con lag_7 (lo mismo de hace una semana)
    y_pred_baseline = test["lag_7"].values

    # 2. Regresion Lineal
    lr = LinearRegression()
    lr.fit(X_train, y_train)
    y_pred_lr = lr.predict(X_test)
    y_pred_lr = np.clip(y_pred_lr, 0, None)  # Demanda no puede ser negativa

    # 3. Random Forest Regressor
    rf = RandomForestRegressor(n_estimators=150, max_depth=10, random_state=42, n_jobs=-1)
    rf.fit(X_train, y_train)
    y_pred_rf = rf.predict(X_test)
    y_pred_rf = np.clip(y_pred_rf, 0, None)

    # Calculo de metricas en TEST
    modelos_preds = {
        "Baseline (Lag-7)": y_pred_baseline,
        "Regresion Lineal": y_pred_lr,
        "Random Forest": y_pred_rf
    }

    metricas = []
    for nombre, y_p in modelos_preds.items():
        mae = mean_absolute_error(y_test, y_p)
        rmse = root_mean_squared_error(y_test, y_p)
        r2 = r2_score(y_test, y_p)
        metricas.append({
            "Modelo": nombre,
            "MAE (Test)": round(mae, 4),
            "RMSE (Test)": round(rmse, 4),
            "R2 (Test)": round(r2, 4)
        })

    df_metricas = pd.DataFrame(metricas)
    print("\n" + "=" * 65)
    print("COMPARACION DE MODELOS DE DEMANDA (EVALUADOS EN TEST TEMPORAL)")
    print("=" * 65)
    print(df_metricas.to_string(index=False))

    # Guardar el mejor modelo (Random Forest) con joblib
    mejor_artefacto = {
        "modelo": rf,
        "features": features_cols,
        "columnas_numericas": columnas_numericas,
        "metricas": df_metricas.to_dict(orient="records")
    }
    ruta_modelo = os.path.join(dir_modelos, "demand_model.joblib")
    joblib.dump(mejor_artefacto, ruta_modelo)
    print(f"\n[OK] Mejor modelo guardado en: {ruta_modelo}")

    # Grafico comparativo de prediccion vs real para un platillo popular (Hamburguesa)
    test["pred_rf"] = y_pred_rf
    sub_test = test[test["platillo"] == "Hamburguesa rsKitchen"].sort_values("fecha")

    plt.figure(figsize=(12, 5))
    plt.plot(pd.to_datetime(sub_test["fecha"]), sub_test["demanda"], label="Demanda Real (Test)", color="black", marker="o", markersize=3)
    plt.plot(pd.to_datetime(sub_test["fecha"]), sub_test["pred_rf"], label="Prediccion Random Forest", color="#e65100", linestyle="--")
    plt.title("Proyeccion de Demanda en Test - Hamburguesa rsKitchen (Sep-Oct 2026)")
    plt.xlabel("Fecha")
    plt.ylabel("Unidades Demandadas")
    plt.legend()
    plt.tight_layout()
    ruta_grafico = os.path.join(dir_salida, "demand_predictions.png")
    plt.savefig(ruta_grafico, dpi=200)
    plt.close()
    print(f"[Grafico] Predicciones vs Real guardado en: {ruta_grafico}")

    return df_metricas

def main():
    base_dir = os.path.dirname(__file__)
    dir_modelos = os.path.join(base_dir, "models")
    dir_salida = os.path.join(base_dir, "out")

    df = obtener_dataset()
    panel = preparar_datos_diarios(df)
    df_fe = construir_caracteristicas(panel)
    entrenar_y_evaluar(df_fe, dir_modelos, dir_salida)

if __name__ == "__main__":
    main()
