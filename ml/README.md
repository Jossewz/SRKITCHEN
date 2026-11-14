# Guía de Puesta en Marcha y Arquitectura de Integración (RSKitchen + ML)

Esta guía documenta la integración funcional del microservicio de Machine Learning (FastAPI) con el backend Java Spring Boot y la interfaz web del restaurante.

---

## 1. Arquitectura de Componentes

```
┌─────────────────────────────────┐
│     Cliente Web / Móvil         │
│  (Thymeleaf + Chart.js / Flutter)│
└────────────────┬────────────────┘
                 │ HTTP (Port 8080)
┌────────────────▼────────────────┐
│      Spring Boot Backend        │
│  - PrediccionController (/prediccion)
│  - PrediccionRestController (/api/prediccion)
│  - PrediccionService (RestTemplate, 3s timeout)
└────────────────┬────────────────┘
                 │ REST / JSON (Port 8000)
┌────────────────▼────────────────┐
│      FastAPI Microservicio      │
│  - /predict (7 o 14 días)       │
│  - /demanda-diaria (series)     │
│  - /ranking-historico           │
│  - /health y /reentrenar        │
│  - Modelos .joblib serializados │
└────────────────┬────────────────┘
                 │ pymongo (Port 27017)
┌────────────────▼────────────────┐
│      MongoDB (rskitchen5)       │
│  - Colección: pedido_sintetico  │
│  - (pedido real preservada)     │
└─────────────────────────────────┘
```

---

## 2. Orden de Arranque Obligatorio

Para que el ecosistema funcione de manera fluida y con datos en tiempo real, inicie los servicios en el siguiente orden estricto:

### Paso 1: Base de Datos MongoDB
Asegúrese de que el servicio de MongoDB esté activo en el puerto estándar:
```bash
# Verificar puerto local (Windows PowerShell)
Test-NetConnection -ComputerName localhost -Port 27017
```
*(Si no estuviera activo, el cargador de datos `data_loader.py` cuenta con fallback automático al archivo local `ml/data/dataset_sintetico.csv`)*.

---

### Paso 2: Microservicio de Machine Learning (FastAPI)
Abra una terminal dedicada e inicie el servidor de inferencia:
```bash
# Desde la raíz del repositorio
python ml/api.py
```
O con Uvicorn directamente:
```bash
uvicorn ml.api:app --host 0.0.0.0 --port 8000 --reload
```

**Verificación:**
* Healthcheck: `http://localhost:8000/health`
* Swagger UI interactivo: `http://localhost:8000/docs`
* Proyección a 7 días: `http://localhost:8000/predict?fecha=2026-11-01&dias=7`

---

### Paso 3: Backend Java Spring Boot
En otra terminal, compile e inicie el backend de RSKitchen:
```bash
# Desde la raíz del repositorio
./mvnw spring-boot:run
```
El servidor levantará en `http://localhost:8080`.

---

## 3. Cómo Probar la Nueva Funcionalidad (`/prediccion`)

1. Inicie sesión en la plataforma con una cuenta con rol **ADMIN** o **CREATOR**:
   * URL de acceso: `http://localhost:8080/login`
2. En la barra lateral izquierda, diríjase a la sección **Administración** y haga clic en **"Predicción Ventas"** (o ingrese directamente a `http://localhost:8080/prediccion`).
3. **Interacciones en la vista:**
   * **Selector de Días:** Alterne entre **"7 Días"** y **"14 Días"** para recalcular el horizonte.
   * **Selector de Fecha:** Modifique la fecha base (`YYYY-MM-DD`) para proyectar cualquier semana del año.
   * **Tarjetas KPI:** Observe el total de unidades proyectadas, ingresos estimados en COP, platillo líder y métrica MAE del modelo.
   * **Gráficos Dinámicos:** Gráfico de barras con la demanda por platillo y gráfico de líneas con la evolución diaria generados mediante Chart.js.
   * **Tabla de Ranking:** Platillos ordenados por demanda con insumos críticos específicos.
   * **Plan de Compras:** Lista consolidada de insumos indispensables con casillas de verificación e impresión directa.
4. **Prueba de Resiliencia / Fallback:**
   * Si apaga el microservicio Python (`Ctrl+C`), recargue `/prediccion` en el navegador: la vista detectará automáticamente el estado fuera de línea y mostrará un banner amable informando que el servicio ML está desconectado, sin colapsar el backend Java.

---

## 4. Endpoints REST para la App Móvil Flutter

* `GET /api/prediccion?fecha=2026-11-01&dias=7` (Ranking semanal completo).
* `GET /api/mobile/prediccion` (Alias para la aplicación móvil).
* `GET /api/prediccion/demanda-diaria?dias=14` (Series cronológicas para gráficos).
* `GET /api/prediccion/ranking-historico` (Estadísticas globales de ventas y días de la semana).
* `GET /api/prediccion/health` (Estado de comunicación entre Spring Boot y FastAPI).
