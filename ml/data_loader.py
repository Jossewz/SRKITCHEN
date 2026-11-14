"""
Modulo de Carga de Datos Configurable para RSKitchen (Mineria de Datos II)
Permite cargar datos desde MongoDB (coleccion especificada) o fallback a archivo CSV/Excel.
"""

import os
import pandas as pd
from typing import Optional

def cargar_desde_mongodb(
    uri: str = "mongodb://localhost:27017/",
    database: str = "rskitchen5",
    collection: str = "pedido_sintetico",
    timeout_ms: int = 3000
) -> Optional[pd.DataFrame]:
    """
    Intenta conectarse a MongoDB y recuperar los registros de la coleccion especificada.
    Retorna un DataFrame de pandas o None si no hay conexion disponible.
    """
    try:
        from pymongo import MongoClient
        client = MongoClient(uri, serverSelectionTimeoutMS=timeout_ms)
        # Test rapido de conexion
        client.admin.command("ping")
        db = client[database]
        col = db[collection]
        docs = list(col.find({}, {"_id": 0}))

        if not docs:
            print(f"[DataLoader] Coleccion '{collection}' en MongoDB esta vacia.")
            return None

        df = pd.DataFrame(docs)
        print(f"[DataLoader] {len(df)} registros cargados exitosamente desde MongoDB ({database}.{collection}).")
        return df
    except Exception as e:
        print(f"[DataLoader] No se pudo conectar a MongoDB ({e}). Usando fuente alternativa.")
        return None

def cargar_desde_csv_o_excel(ruta_archivo: str) -> pd.DataFrame:
    """Carga datos desde archivo CSV o Excel."""
    if not os.path.exists(ruta_archivo):
        raise FileNotFoundError(f"Archivo no encontrado: {ruta_archivo}")

    if ruta_archivo.endswith(".csv"):
        df = pd.read_csv(ruta_archivo)
    elif ruta_archivo.endswith((".xlsx", ".xls")):
        df = pd.read_excel(ruta_archivo)
    else:
        raise ValueError(f"Formato de archivo no soportado: {ruta_archivo}")

    print(f"[DataLoader] {len(df)} registros cargados desde archivo: {ruta_archivo}")
    return df

def obtener_dataset(
    fuente_preferida: str = "auto",
    ruta_local: Optional[str] = None,
    mongo_uri: str = "mongodb://localhost:27017/",
    mongo_db: str = "rskitchen5",
    mongo_col: str = "pedido_sintetico"
) -> pd.DataFrame:
    """
    Fachada principal para obtener el DataFrame de trabajo.
    fuente_preferida: 'auto' (intenta MongoDB luego local), 'mongo' o 'local'.
    """
    base_dir = os.path.dirname(__file__)
    if ruta_local is None:
        ruta_local = os.path.join(base_dir, "data", "dataset_sintetico.csv")

    if fuente_preferida in ["auto", "mongo"]:
        df_mongo = cargar_desde_mongodb(
            uri=mongo_uri,
            database=mongo_db,
            collection=mongo_col
        )
        if df_mongo is not None:
            return df_mongo
        if fuente_preferida == "mongo":
            raise ConnectionError("Fallo la conexion requerida a MongoDB.")

    # Fallback o seleccion explicita local
    return cargar_desde_csv_o_excel(ruta_local)

if __name__ == "__main__":
    df = obtener_dataset()
    print("Columnas:", list(df.columns))
    print("Muestra inicial:")
    print(df.head(3))
