"""
Modulo de Inferencia y Proyeccion de Demanda para RSKitchen (Mineria de Datos II)
Dada una fecha base, proyecta la demanda de los 8 platillos para los proximos 7 dias
y devuelve el ranking proyectado de ventas con recomendaciones de compra de insumos.
"""

import os
import argparse
import datetime
import joblib
import pandas as pd
import numpy as np

# Metadatos de platillos e insumos asociados
INSUMOS_RECOMENDADOS = {
    "Hamburguesa rsKitchen": ["Pan artesanal", "Carne molida seleccionada", "Queso cheddar", "Tocineta", "Papas rusticas"],
    "Pizza Margarita": ["Masa madre / harina de fuerza", "Salsa pomodoro", "Queso mozzarella fresco", "Albahaca fresca"],
    "Cerveza Artesanal": ["Barriles / botellas de cerveza artesanal rubia e IPA"],
    "Limonada Natural": ["Limones frescos tahiti", "Hierbabuena", "Azucar organica"],
    "Corte de Carne": ["Cortes premium de lomo/bife de res", "Mantequilla de romero", "Sal marina gruesa"],
    "Pasta Carbonara": ["Pasta larga / fettuccine", "Guanciale / tocineta ahumada", "Queso pecorino/parmesano", "Huevos frescos"],
    "Ensalada Cesar": ["Lechuga romana fresca", "Pechuga de pollo", "Aderezo cesar", "Croûtons y queso parmesano"],
    "Sopa del Dia": ["Verduras frescas de temporada", "Fondo/caldo concentrado de res y ave"]
}

PRECIOS_UNITARIOS = {
    "Hamburguesa rsKitchen": 26000,
    "Pizza Margarita": 32000,
    "Cerveza Artesanal": 14000,
    "Limonada Natural": 8000,
    "Corte de Carne": 45000,
    "Pasta Carbonara": 28000,
    "Ensalada Cesar": 22000,
    "Sopa del Dia": 15000
}

def cargar_modelo_demanda(ruta_modelo: str = None):
    if ruta_modelo is None:
        ruta_modelo = os.path.join(os.path.dirname(__file__), "models", "demand_model.joblib")
    if not os.path.exists(ruta_modelo):
        raise FileNotFoundError(f"El artefacto del modelo no existe en: {ruta_modelo}. Ejecute demand_model.py primero.")
    return joblib.load(ruta_modelo)

def proyectar_proximos_7_dias(fecha_str: str = "2026-11-01", ruta_modelo: str = None) -> pd.DataFrame:
    """Genera la proyeccion de 7 dias a partir de la fecha base."""
    artefacto = cargar_modelo_demanda(ruta_modelo)
    modelo = artefacto["modelo"]
    features_esperadas = artefacto["features"]

    fecha_base = datetime.datetime.strptime(fecha_str, "%Y-%m-%d").date()
    fechas_futuras = [fecha_base + datetime.timedelta(days=i) for i in range(1, 8)]

    # Cargar historico reciente para alimentar lags (ultimos 14 dias antes de la fecha base)
    ruta_datos = os.path.join(os.path.dirname(__file__), "data", "dataset_sintetico.csv")
    df_hist = pd.read_csv(ruta_datos)
    df_hist["fecha"] = pd.to_datetime(df_hist["CreacionPedido"]).dt.date

    demanda_reciente = df_hist.groupby(["fecha", "platillo"])["cantidad"].sum().reset_index()

    proyecciones = []
    platillos = list(PRECIOS_UNITARIOS.keys())

    for p in platillos:
        sub_hist = demanda_reciente[demanda_reciente["platillo"] == p].sort_values("fecha")
        media_historica = sub_hist["cantidad"].mean() if len(sub_hist) > 0 else 3.0
        lag_recientes = list(sub_hist["cantidad"].tail(14).values)

        demanda_acumulada_7d = 0.0

        for f in fechas_futuras:
            dia_sem = f.weekday()
            dia_m = f.day
            mes = f.month
            es_fin_semana = 1 if dia_sem in [4, 5, 6] else 0
            es_quincena = 1 if dia_m in [15, 16, 30, 31] else 0

            # Lags simulados usando la cola de valores
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

            # Dummies de platillo
            for feat in features_esperadas:
                if feat.startswith("platillo_"):
                    nombre_col_platillo = feat.replace("platillo_", "")
                    fila_dict[feat] = 1 if nombre_col_platillo == p else 0

            # Armar vector respetando orden de features
            X_vec = [fila_dict.get(c, 0) for c in features_esperadas]
            pred_dia = modelo.predict([X_vec])[0]
            pred_dia = max(0.0, float(pred_dia))

            demanda_acumulada_7d += pred_dia
            lag_recientes.append(pred_dia)

        unidades_estimadas = int(round(demanda_acumulada_7d))
        precio_unitario = PRECIOS_UNITARIOS[p]
        ingresos_estimados = unidades_estimadas * precio_unitario

        proyecciones.append({
            "platillo": p,
            "unidades_proyectadas_7d": unidades_estimadas,
            "precio_unitario_COP": precio_unitario,
            "ingresos_estimados_COP": ingresos_estimados,
            "insumos_criticos": ", ".join(INSUMOS_RECOMENDADOS.get(p, []))
        })

    df_proy = pd.DataFrame(proyecciones).sort_values("unidades_proyectadas_7d", ascending=False).reset_index(drop=True)
    df_proy.index = df_proy.index + 1
    df_proy.index.name = "ranking"
    return df_proy.reset_index()

def main():
    parser = argparse.ArgumentParser(description="Proyeccion de demanda semanal para RSKitchen")
    parser.add_argument("--fecha", type=str, default="2026-11-01", help="Fecha inicial de proyeccion (YYYY-MM-DD)")
    args = parser.parse_args()

    print("=" * 80)
    print(f"RANKING PROYECTADO DE PLATILLOS (7 DIAS A PARTIR DE {args.fecha})")
    print("=" * 80)
    df_ranking = proyectar_proximos_7_dias(args.fecha)

    columnas_vista = ["ranking", "platillo", "unidades_proyectadas_7d", "ingresos_estimados_COP", "insumos_criticos"]
    print(df_ranking[columnas_vista].to_string(index=False))

    total_unidades = df_ranking["unidades_proyectadas_7d"].sum()
    total_ingresos = df_ranking["ingresos_estimados_COP"].sum()
    print("\n" + "-" * 80)
    print(f"TOTAL ESTIMADO 7 DIAS: {total_unidades} unidades | ${total_ingresos:,.0f} COP")
    print("-" * 80)

if __name__ == "__main__":
    main()
