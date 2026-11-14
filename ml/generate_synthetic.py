"""
Generador de Dataset Sintetico para RSKitchen (Mineria de Datos II)
Genera 3.000 pedidos entre 2026-01-01 y 2026-10-31 con patrones realistas y reproducibles (seed=42).
"""

import os
import random
import datetime
import math
import pandas as pd
import numpy as np

# Fijar semillas para reproducibilidad
RANDOM_SEED = 42
random.seed(RANDOM_SEED)
np.random.seed(RANDOM_SEED)

# Definicion de los 8 platillos reales y sus precios fijos en COP
PLATILLOS_INFO = {
    "Corte de Carne": {"precio": 45000, "peso_base": 0.12, "categoria": "plato_fuerte"},
    "Pizza Margarita": {"precio": 32000, "peso_base": 0.18, "categoria": "plato_fuerte"},
    "Sopa del Dia": {"precio": 15000, "peso_base": 0.05, "categoria": "entrada"},
    "Ensalada Cesar": {"precio": 22000, "peso_base": 0.07, "categoria": "entrada"},
    "Pasta Carbonara": {"precio": 28000, "peso_base": 0.10, "categoria": "plato_fuerte"},
    "Hamburguesa rsKitchen": {"precio": 26000, "peso_base": 0.20, "categoria": "plato_fuerte"},
    "Limonada Natural": {"precio": 8000, "peso_base": 0.14, "categoria": "bebida"},
    "Cerveza Artesanal": {"precio": 14000, "peso_base": 0.14, "categoria": "bebida"}
}

SEDES = ["Principal", "Centro"]
SEDE_PESOS = [0.60, 0.40]

CANALES = ["mesa", "rappi", "whatsapp"]
CANAL_PESOS = [0.50, 0.32, 0.18]

DIAS_SEMANA_NOMBRES = [
    "Lunes", "Martes", "Miercoles", "Jueves", "Viernes", "Sabado", "Domingo"
]

# Factores multiplicadores por dia de la semana (mayor demanda en fin de semana)
FACTOR_DIA_SEMANA = {
    0: 0.65,  # Lunes
    1: 0.70,  # Martes
    2: 0.85,  # Miercoles
    3: 0.95,  # Jueves
    4: 1.45,  # Viernes
    5: 1.65,  # Sabado
    6: 1.40   # Domingo
}

def obtener_probabilidad_dia(fecha: datetime.date, fecha_inicio: datetime.date, total_dias: int) -> float:
    """
    Calcula el peso relativo de demanda para un dia especifico combinando:
    1. Tendencia de crecimiento suave a lo largo de los meses (de 0.8 a 1.25).
    2. Efecto de dia de la semana (viernes a domingo con mayor afluencia).
    3. Picos de quincena (dias 15, 16, 30, 31).
    4. Ruido aleatorio suave.
    """
    delta_dias = (fecha - fecha_inicio).days
    progreso_anual = delta_dias / max(1, total_dias)
    tendencia = 0.80 + (0.45 * progreso_anual)

    dia_sem = fecha.weekday()
    factor_sem = FACTOR_DIA_SEMANA[dia_sem]

    # Factor de quincena
    dia_mes = fecha.day
    es_quincena = dia_mes in [15, 16, 30, 31] or (dia_mes == 1 and fecha.month > 1)
    factor_quincena = 1.35 if es_quincena else 1.0

    peso = tendencia * factor_sem * factor_quincena
    return max(0.1, peso)

def generar_dataset(n_pedidos: int = 3000) -> pd.DataFrame:
    """Genera 3.000 pedidos con atributos y distribuciones estadisticas documentadas."""
    fecha_inicio = datetime.date(2026, 1, 1)
    fecha_fin = datetime.date(2026, 10, 31)
    total_dias = (fecha_fin - fecha_inicio).days + 1

    dias_posibles = [fecha_inicio + datetime.timedelta(days=i) for i in range(total_dias)]
    pesos_dias = [obtener_probabilidad_dia(d, fecha_inicio, total_dias) for d in dias_posibles]
    suma_pesos = sum(pesos_dias)
    prob_dias = [p / suma_pesos for p in pesos_dias]

    # Muestrear fechas segun la distribucion de demanda
    fechas_elegidas = np.random.choice(dias_posibles, size=n_pedidos, p=prob_dias)
    fechas_elegidas = sorted(fechas_elegidas)

    nombres_platillos = list(PLATILLOS_INFO.keys())
    pesos_platillos = [PLATILLOS_INFO[p]["peso_base"] for p in nombres_platillos]

    registros = []
    fecha_corte_reciente = fecha_fin - datetime.timedelta(days=5)

    for i in range(n_pedidos):
        num_pedido = f"PED-{i + 1:04d}"
        fecha_d = fechas_elegidas[i]

        # Hora: horas pico almuerzo (12:00-15:30) y cena (18:30-22:30)
        es_almuerzo = random.random() < 0.52
        if es_almuerzo:
            hora = random.randint(12, 15)
            minuto = random.randint(0, 59)
            segundo = random.randint(0, 59)
        else:
            hora = random.randint(18, 22)
            minuto = random.randint(0, 59)
            segundo = random.randint(0, 59)

        creacion_fecha = datetime.datetime(
            fecha_d.year, fecha_d.month, fecha_d.day, hora, minuto, segundo
        )

        dia_semana_nombre = DIAS_SEMANA_NOMBRES[fecha_d.weekday()]

        sede = np.random.choice(SEDES, p=SEDE_PESOS)
        canal = np.random.choice(CANALES, p=CANAL_PESOS)

        # Modulacion de platillo segun canal (p.ej. rappi pide mas hamburguesa/pizza)
        pesos_ajustados = list(pesos_platillos)
        if canal == "rappi":
            # Incremento en hamburguesa y pizza para delivery
            pesos_ajustados[nombres_platillos.index("Hamburguesa rsKitchen")] *= 1.3
            pesos_ajustados[nombres_platillos.index("Pizza Margarita")] *= 1.2
            pesos_ajustados[nombres_platillos.index("Sopa del Dia")] *= 0.4
        elif canal == "mesa":
            # Mas cortes de carne y cervezas en mesa
            pesos_ajustados[nombres_platillos.index("Corte de Carne")] *= 1.25
            pesos_ajustados[nombres_platillos.index("Cerveza Artesanal")] *= 1.3

        suma_pesos_adj = sum(pesos_ajustados)
        prob_platillos_adj = [p / suma_pesos_adj for p in pesos_ajustados]
        platillo = np.random.choice(nombres_platillos, p=prob_platillos_adj)

        # Cantidad de unidades pedidas del platillo (1 a 4, mayoritariamente 1 o 2)
        cantidad = np.random.choice([1, 2, 3, 4], p=[0.72, 0.20, 0.06, 0.02])
        precio_unitario = PLATILLOS_INFO[platillo]["precio"]
        precio_total = int(precio_unitario * cantidad)

        # Estado del pedido (pagado vs pendiente)
        # Regla: pedidos antiguos casi siempre pagados. Pedidos recientes tienen tasa pendiente normal.
        antiguedad_dias = (fecha_fin - fecha_d).days
        if antiguedad_dias > 3:
            # Pedido antiguo: 99.2% de probabilidad de estar pagado
            prob_pagado = 0.992
        elif antiguedad_dias > 1:
            # Hace 2-3 dias
            prob_pagado = 0.940
        else:
            # Pedido del dia o reciente: canal mesa suele tener pagos pendientes mientras consumen
            if canal == "mesa":
                prob_pagado = 0.75
            elif canal == "whatsapp":
                prob_pagado = 0.85
            else:  # rappi
                prob_pagado = 0.98

        estado = "pagado" if random.random() < prob_pagado else "pendiente"

        registros.append({
            "numeroPedido": num_pedido,
            "precio": precio_total,
            "platillo": platillo,
            "CreacionPedido": creacion_fecha.strftime("%Y-%m-%d %H:%M:%S"),
            "estado": estado,
            "sede": sede,
            "canal": canal,
            "cantidad": int(cantidad),
            "dia_semana": dia_semana_nombre
        })

    df = pd.DataFrame(registros)
    return df

def guardar_csv(df: pd.DataFrame, ruta_destino: str):
    """Crea directorios si no existen y guarda el archivo CSV."""
    os.makedirs(os.path.dirname(ruta_destino), exist_ok=True)
    df.to_csv(ruta_destino, index=False, encoding="utf-8")
    print(f"[OK] Dataset sintetico guardado exitosamente en: {ruta_destino}")
    print(f"     Total registros: {len(df):,}")
    print(f"     Rango temporal:  {df['CreacionPedido'].min()} -> {df['CreacionPedido'].max()}")
    print("\nDistribucion por Platillo:")
    print(df["platillo"].value_counts().to_string())
    print("\nDistribucion por Estado:")
    print(df["estado"].value_counts().to_string())
    print("\nDistribucion por Canal:")
    print(df["canal"].value_counts().to_string())

def insertar_en_mongodb(df: pd.DataFrame, uri="mongodb://localhost:27017/rskitchen5"):
    """
    Inserta el dataset en la coleccion 'pedido_sintetico'.
    NOTA: NUNCA toca ni borra la coleccion 'pedido' real.
    Solo se ejecuta si el usuario lo confirma explícitamente.
    """
    try:
        from pymongo import MongoClient
        client = MongoClient(uri, serverSelectionTimeoutMS=3000)
        db = client.get_database()
        coleccion = db["pedido_sintetico"]

        documentos = df.to_dict(orient="records")
        for doc in documentos:
            doc["origen"] = "sintetico"

        resultado = coleccion.insert_many(documentos)
        print(f"[OK] Insertados {len(resultado.inserted_ids)} documentos en 'pedido_sintetico'.")
    except Exception as e:
        print(f"[AVISO] No se pudo insertar en MongoDB: {e}")

if __name__ == "__main__":
    ruta_salida = os.path.join(os.path.dirname(__file__), "data", "dataset_sintetico.csv")
    df_sintetico = generar_dataset(n_pedidos=3000)
    guardar_csv(df_sintetico, ruta_salida)
