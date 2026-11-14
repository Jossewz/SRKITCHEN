"""
Servicio API REST con FastAPI para RSKitchen (Mineria de Datos II)
Expone endpoints JSON para prediccion de demanda, demanda diaria, ranking historico y reentrenamiento.
"""

import os
import sys
import datetime
from typing import Optional, List, Dict, Any

# Asegurar que el directorio de ml este en el path para importaciones relativas
sys.path.insert(0, os.path.dirname(__file__))

from fastapi import FastAPI, Query, HTTPException, Header, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import pandas as pd
import numpy as np

from predict import (
    proyectar_proximos_7_dias,
    cargar_modelo_demanda,
    PRECIOS_UNITARIOS,
    INSUMOS_RECOMENDADOS
)
from data_loader import obtener_dataset

app = FastAPI(
    title="RSKitchen ML Demand & Prediction API",
    version="1.1.0",
    description="Microservicio de Machine Learning para proyeccion de demanda semanal de platillos y compra de insumos."
)

# Configuracion de CORS para consumo desde Spring Boot, Flutter o SPA Web
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SECRET_REENTRENAR_TOKEN = os.getenv("ML_REENTRENAR_KEY", "rskitchen_ml_secret_key_2026")

class ReentrenarRequest(BaseModel):
    token: str

@app.get("/health")
def health():
    """Verifica el estado del servicio y disponibilidad de los modelos."""
    modelo_demanda_ok = os.path.exists(os.path.join(os.path.dirname(__file__), "models", "demand_model.joblib"))
    modelo_pago_ok = os.path.exists(os.path.join(os.path.dirname(__file__), "models", "payment_classifier.joblib"))
    return {
        "status": "UP",
        "timestamp": datetime.datetime.now().isoformat(),
        "models": {
            "demand_model": "LOADED" if modelo_demanda_ok else "NOT_FOUND",
            "payment_classifier": "LOADED" if modelo_pago_ok else "NOT_FOUND"
        }
    }

@app.get("/predict")
def predict(
    fecha: str = Query(default="2026-11-01", description="Fecha base YYYY-MM-DD"),
    dias: int = Query(default=7, ge=1, le=30, description="Horizonte de proyeccion en dias (7 o 14)")
):
    """
    Retorna el ranking proyectado por platillo: unidades proyectadas, ingresos estimados,
    insumos criticos y totales agregados para el horizonte especificado.
    """
    try:
        fecha_dt = datetime.datetime.strptime(fecha, "%Y-%m-%d").date()
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha invalido. Use YYYY-MM-DD.")

    base_dir = os.path.dirname(__file__)
    ruta_modelo = os.path.join(base_dir, "models", "demand_model.joblib")
    artefacto = cargar_modelo_demanda(ruta_modelo)
    modelo = artefacto["modelo"]
    features_esperadas = artefacto["features"]

    # Cargar ultimos datos historicos para calcular lags reales
    df_hist = obtener_dataset()
    df_hist["fecha_dt"] = pd.to_datetime(df_hist["CreacionPedido"]).dt.date
    demanda_reciente = df_hist.groupby(["fecha_dt", "platillo"])["cantidad"].sum().reset_index()

    fechas_futuras = [fecha_dt + datetime.timedelta(days=i) for i in range(1, dias + 1)]
    platillos = list(PRECIOS_UNITARIOS.keys())

    proyecciones = []
    for p in platillos:
        sub_hist = demanda_reciente[demanda_reciente["platillo"] == p].sort_values("fecha_dt")
        media_historica = sub_hist["cantidad"].mean() if len(sub_hist) > 0 else 3.0
        lag_recientes = list(sub_hist["cantidad"].tail(14).values)

        unidades_acumuladas = 0.0
        serie_diaria_platillo = []

        for f in fechas_futuras:
            dia_sem = f.weekday()
            dia_m = f.day
            mes = f.month
            es_fin_semana = 1 if dia_sem in [4, 5, 6] else 0
            es_quincena = 1 if dia_m in [15, 16, 30, 31] else 0

            lag_1 = lag_recientes[-1] if len(lag_recientes) >= 1 else media_historica
            lag_7 = lag_recientes[-7] if len(lag_recientes) >= 7 else media_historica
            mm_7 = np.mean(lag_recientes[-7:]) if len(lag_recientes) >= 7 else media_historica
            mm_14 = np.mean(lag_recientes[-14:]) if len(lag_recientes) >= 14 else media_historica

            fila_dict = {
                "dia_semana": dia_sem,
                "dia_mes": dia_m,
                "mes": mes,
                "es_fin_semana": es_fin_semana,
                "es_quincena": es_quincena,
                "lag_1": lag_1,
                "lag_7": lag_7,
                "media_movil_7": mm_7,
                "media_movil_14": mm_14
            }

            for feat in features_esperadas:
                if feat.startswith("platillo_"):
                    nombre_col = feat.replace("platillo_", "")
                    fila_dict[feat] = 1 if nombre_col == p else 0

            X_vec = [fila_dict.get(c, 0) for c in features_esperadas]
            pred_dia = max(0.0, float(modelo.predict([X_vec])[0]))
            unidades_acumuladas += pred_dia
            lag_recientes.append(pred_dia)

            serie_diaria_platillo.append({
                "fecha": f.strftime("%Y-%m-%d"),
                "dia": f.strftime("%a"),
                "prediccion": round(pred_dia, 1)
            })

        unidades_redondeadas = int(round(unidades_acumuladas))
        precio_unitario = PRECIOS_UNITARIOS[p]
        ingresos_est = unidades_redondeadas * precio_unitario

        proyecciones.append({
            "platillo": p,
            "unidades_proyectadas": unidades_redondeadas,
            "precio_unitario_COP": precio_unitario,
            "ingresos_estimados_COP": ingresos_est,
            "insumos_criticos": INSUMOS_RECOMENDADOS.get(p, []),
            "serie_diaria": serie_diaria_platillo
        })

    # Ordenar por unidades proyectadas
    proyecciones = sorted(proyecciones, key=lambda x: x["unidades_proyectadas"], reverse=True)
    for idx, item in enumerate(proyecciones, start=1):
        item["ranking"] = idx

    total_unidades = sum(x["unidades_proyectadas"] for x in proyecciones)
    total_ingresos = sum(x["ingresos_estimados_COP"] for x in proyecciones)

    # Insumos consolidados unicos ordenados
    insumos_unicos = []
    for item in proyecciones:
        for ins in item["insumos_criticos"]:
            if ins not in insumos_unicos:
                insumos_unicos.append(ins)

    return {
        "fecha_base": fecha,
        "dias_proyectados": dias,
        "total_unidades": total_unidades,
        "total_ingresos_COP": total_ingresos,
        "ranking": proyecciones,
        "insumos_consolidados": insumos_unicos,
        "nota_metodologica": "Proyeccion basada en modelo de ML entrenado con datos sinteticos de validacion."
    }

@app.get("/demanda-diaria")
def demanda_diaria(dias: int = Query(default=14, ge=1, le=30, description="Dias futuros a proyectar")):
    """
    Retorna la serie temporal dia a dia por platillo formateada para graficos de lineas en Chart.js.
    """
    hoy_str = datetime.date(2026, 11, 1).strftime("%Y-%m-%d")
    res_predict = predict(fecha=hoy_str, dias=dias)

    fechas_eje = []
    fechas_dt = [datetime.date(2026, 11, 1) + datetime.timedelta(days=i) for i in range(1, dias + 1)]
    fechas_eje = [f.strftime("%Y-%m-%d") for f in fechas_dt]

    series_platillo = {}
    for item in res_predict["ranking"]:
        p_nombre = item["platillo"]
        series_platillo[p_nombre] = [d["prediccion"] for d in item["serie_diaria"]]

    return {
        "fechas": fechas_eje,
        "series": series_platillo,
        "total_diario": [
            round(sum(series_platillo[p][idx] for p in series_platillo), 1)
            for idx in range(len(fechas_eje))
        ]
    }

@app.get("/ranking-historico")
def ranking_historico():
    """
    Retorna estadisticas descriptivas de ventas historicas por platillo y distribucion por dia de la semana.
    """
    df = obtener_dataset()
    df["CreacionPedido_dt"] = pd.to_datetime(df["CreacionPedido"])

    # 1. Ventas por platillo
    agrup_platillo = df.groupby("platillo").agg(
        pedidos=("numeroPedido", "count"),
        unidades=("cantidad", "sum"),
        ingresos=("precio", "sum")
    ).reset_index().sort_values("unidades", ascending=False)

    # 2. Ventas por dia de la semana
    dias_orden = ["Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo"]
    ventas_dia = df["dia_semana"].value_counts().reindex(dias_orden).fillna(0).to_dict()

    return {
        "por_platillo": agrup_platillo.to_dict(orient="records"),
        "por_dia_semana": ventas_dia,
        "total_pedidos_historicos": len(df),
        "total_ingresos_historicos": float(df["precio"].sum())
    }

@app.post("/reentrenar")
def reentrenar(req: ReentrenarRequest):
    """
    Endpoint protegido para volver a ejecutar el pipeline de entrenamiento.
    """
    if req.token != SECRET_REENTRENAR_TOKEN:
        raise HTTPException(status_code=403, detail="Token de reentrenamiento no valido.")

    from demand_model import main as reentrenar_demanda
    from classification_model import main as reentrenar_clasificacion

    reentrenar_demanda()
    reentrenar_clasificacion()

    return {
        "status": "SUCCESS",
        "message": "Modelos reentrenados y actualizados exitosamente en /ml/models."
    }

def main():
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    print(f"[FastAPI] Escuchando en http://0.0.0.0:{port}")
    uvicorn.run("api:app", host="0.0.0.0", port=port, reload=False)

if __name__ == "__main__":
    main()
