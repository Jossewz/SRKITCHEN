"""
Modelo Secundario de Clasificacion de Estado de Pago para RSKitchen (Mineria de Datos II)
- Predice si un pedido estara 'pagado' o 'pendiente'.
- Compara Arbol de Decision (equivalente a J48 de Weka) y Random Forest Classifier.
- Reporta Matriz de Confusion, Accuracy y F1-score evaluados en conjunto de Test.
- Serializa el modelo entrenado con joblib.
"""

import os
import joblib
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.model_selection import train_test_split
from sklearn.tree import DecisionTreeClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import accuracy_score, precision_score, recall_score, f1_score, confusion_matrix, classification_report

from data_loader import obtener_dataset

def preparar_datos_clasificacion(df: pd.DataFrame):
    """Genera matriz de caracteristicas y variable objetivo."""
    df = df.copy()
    df["CreacionPedido_dt"] = pd.to_datetime(df["CreacionPedido"])
    fecha_maxima = df["CreacionPedido_dt"].max()

    # Antiguedad en dias respecto al final del dataset
    df["antiguedad_dias"] = (fecha_maxima - df["CreacionPedido_dt"]).dt.total_seconds() / 86400.0
    df["hora"] = df["CreacionPedido_dt"].dt.hour
    df["dia_semana_num"] = df["CreacionPedido_dt"].dt.weekday

    # Variable objetivo binaria: 1 = pagado, 0 = pendiente
    y = (df["estado"].str.lower() == "pagado").astype(int)

    # Variables predictoras
    features_cat = ["canal", "sede", "platillo"]
    features_num = ["precio", "cantidad", "antiguedad_dias", "hora", "dia_semana_num"]

    X_cat = pd.get_dummies(df[features_cat], drop_first=True)
    X = pd.concat([df[features_num], X_cat], axis=1)

    return X, y, list(X.columns)

def entrenar_clasificadores(X: pd.DataFrame, y: pd.Series, feature_names: list, dir_modelos: str, dir_salida: str):
    """Entrena DecisionTree (J48) y RandomForest, evaluando sobre Test."""
    os.makedirs(dir_modelos, exist_ok=True)
    os.makedirs(dir_salida, exist_ok=True)

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.25, random_state=42, stratify=y
    )

    print(f"\n[Clasificacion] Total Muestras Train: {len(X_train)} | Test: {len(X_test)}")
    print(f"                Distribucion Train: {pd.Series(y_train).value_counts().to_dict()}")
    print(f"                Distribucion Test:  {pd.Series(y_test).value_counts().to_dict()}")

    # 1. Arbol de Decision (criterio 'entropy' para replicar C4.5 / J48 de Weka)
    dt = DecisionTreeClassifier(criterion="entropy", max_depth=5, min_samples_leaf=5, random_state=42)
    dt.fit(X_train, y_train)
    y_pred_dt = dt.predict(X_test)

    # 2. Random Forest Classifier
    rf = RandomForestClassifier(n_estimators=120, max_depth=6, random_state=42, class_weight="balanced")
    rf.fit(X_train, y_train)
    y_pred_rf = rf.predict(X_test)

    modelos = {
        "Arbol de Decision (J48)": (dt, y_pred_dt),
        "Random Forest Classifier": (rf, y_pred_rf)
    }

    reporte_metricas = []
    for nombre, (mod, y_pred) in modelos.items():
        acc = accuracy_score(y_test, y_pred)
        f1_macro = f1_score(y_test, y_pred, average="macro", zero_division=0)
        prec_macro = precision_score(y_test, y_pred, average="macro", zero_division=0)
        rec_macro = recall_score(y_test, y_pred, average="macro", zero_division=0)
        reporte_metricas.append({
            "Algoritmo": nombre,
            "Accuracy": round(acc, 4),
            "F1-Macro": round(f1_macro, 4),
            "Precision": round(prec_macro, 4),
            "Recall": round(rec_macro, 4)
        })

    df_metricas = pd.DataFrame(reporte_metricas)
    print("\n" + "=" * 65)
    print("METRICAS DE CLASIFICACION DEL ESTADO DE PAGO (EVALUADAS EN TEST)")
    print("=" * 65)
    print(df_metricas.to_string(index=False))

    # Matriz de confusion de ambos
    fig, axes = plt.subplots(1, 2, figsize=(11, 4.5))
    etiquetas = ["Pendiente (0)", "Pagado (1)"]

    cm_dt = confusion_matrix(y_test, y_pred_dt)
    sns.heatmap(cm_dt, annot=True, fmt="d", cmap="Blues", xticklabels=etiquetas, yticklabels=etiquetas, ax=axes[0])
    axes[0].set_title("Matriz: Arbol de Decision (J48)")
    axes[0].set_ylabel("Valor Real")
    axes[0].set_xlabel("Prediccion")

    cm_rf = confusion_matrix(y_test, y_pred_rf)
    sns.heatmap(cm_rf, annot=True, fmt="d", cmap="Greens", xticklabels=etiquetas, yticklabels=etiquetas, ax=axes[1])
    axes[1].set_title("Matriz: Random Forest")
    axes[1].set_ylabel("Valor Real")
    axes[1].set_xlabel("Prediccion")

    plt.tight_layout()
    ruta_cm = os.path.join(dir_salida, "confusion_matrix.png")
    plt.savefig(ruta_cm, dpi=200)
    plt.close()
    print(f"\n[Grafico] Matrices de confusion guardadas en: {ruta_cm}")

    # Guardar artefacto con joblib
    artefacto = {
        "modelo_arbol": dt,
        "modelo_rf": rf,
        "feature_names": feature_names,
        "metricas": reporte_metricas
    }
    ruta_modelo = os.path.join(dir_modelos, "payment_classifier.joblib")
    joblib.dump(artefacto, ruta_modelo)
    print(f"[OK] Modelo de clasificacion serializado en: {ruta_modelo}")

    return df_metricas

def main():
    base_dir = os.path.dirname(__file__)
    dir_modelos = os.path.join(base_dir, "models")
    dir_salida = os.path.join(base_dir, "out")

    df = obtener_dataset()
    X, y, feature_names = preparar_datos_clasificacion(df)
    entrenar_clasificadores(X, y, feature_names, dir_modelos, dir_salida)

if __name__ == "__main__":
    main()
