# Informe Técnico de Resultados — Minería de Datos II (RSKitchen)

**Proyecto:** Sistema de Proyección de Demanda y Análisis de Ventas (RSKitchen)  
**Materia:** Minería de Datos II  
**Fecha:** Noviembre 2026  
**Autor:** Equipo de Ingeniería de Datos (Carlos Ruiz Herrera / Carlox99)  

---

## 1. Resumen Ejecutivo y Metodología Experimental

Este reporte documenta los resultados obtenidos tras el despliegue del pipeline de minería de datos y machine learning para **RSKitchen**. Ante la limitación de volumen histórico en base de datos productiva (16 registros reales en MongoDB y 120 registros dispersos con ruido de precios en la plantilla inicial), se implementó un generador estocástico reproducible (`seed=42`) de 3.000 pedidos en el horizonte temporal del `2026-01-01` al `2026-10-31` (10 meses completos).

> [!IMPORTANT]
> **Aviso de Integridad Metodológica:**
> Las métricas reportadas a continuación sobre el dataset sintético evalúan la capacidad de los modelos para **recuperar y capturar patrones simulados** (estacionalidad semanal, picos salariales de quincena, tendencias de crecimiento y dinámicas de canal) bajo una división temporal estricta (*Out-of-Time Validation*). No representan métricas en producción con comensales reales.

---

## 2. Auditoría Técnica e Inconsistencias Documentadas

| Aspecto | En el "Informe Metodológico" | En la Realidad Experimental | Diagnóstico Técnico |
| :--- | :--- | :--- | :--- |
| **Tamaño de muestra** | Afirma contar con **150 registros** | El Excel trae **120 registros**; la base real contenía **16 registros** | Discrepancia de volumen. Trabajar con 120 o 150 filas para 8 platillos genera una serie temporal de apenas ~1.5 observaciones por platillo al mes, inviable para entrenar redes o modelos complejos sin sobreajuste severo. |
| **Métrica $R^2$ de regresión** | Reporta un **$R^2 = 0.89$** | En validación temporal real: **$R^2 \approx 0.18$** (Regresión Lineal) y **$R^2 \approx 0.13$** (Random Forest) | Un $R^2 = 0.89$ en un dataset de demanda diaria atomizada con valores discretos pequeños (0 a 6 unidades diarias por platillo) es síntoma inequívoco de **evaluación sobre el conjunto de entrenamiento (data leakage / overfitting)**. En un split cronológico realista (*Train* Ene–Ago vs *Test* Sep–Oct), el $R^2$ out-of-sample real se ubica entre 0.13 y 0.18, superando al Baseline ($R^2 = -0.57$). |
| **Redundancia de columnas** | Reporta `precio (COP)` | La columna `precio` venía **repetida 3 veces** | Se aplicó deduplicación y normalización a un único campo entero en pesos colombianos. |

---

## 3. Demostración con los 16 Pedidos Reales

Se ejecutó un análisis aislado sobre los 16 pedidos históricos reales extraídos de la base de datos de RSKitchen (`ml/data/pedidos_reales_16.csv`):

* **Total facturado:** \$570.000 COP
* **Raciones despachadas:** 28 unidades
* **Rango temporal:** 2026-11-01 al 2026-11-10 (10 días)
* **Ranking Real:**
  1. *Corte de Carne:* 9 unidades (\$248.000 COP)
  2. *Hamburguesa rsKitchen:* 7 unidades (\$84.000 COP)
  3. *Pizza Margarita:* 5 unidades (\$102.000 COP)
  4. *Pasta Carbonara:* 4 unidades (\$96.000 COP)
  5. *Sopa del Día:* 2 unidades (\$16.000 COP)
  6. *Ensalada César:* 1 unidad (\$24.000 COP)

**Conclusión:** Los datos reales validan la plausibilidad de los precios unitarios y la preferencia de la clientela por platos fuertes y carnes, pero carecen de la densidad temporal necesaria para entrenar modelos predictivos supervisados.

---

## 4. Hallazgos de Minería de Datos (Dataset 3.000 Pedidos)

### A. Ranking de Platillos por Demanda e Ingresos

```
              Platillo  Pedidos  Unidades  Ingresos Totales (COP)  Precio Prom.  % Unidades  % Ingresos
 Hamburguesa rsKitchen      590       801             $20.826.000       $35.298       19.4%       20.3%
       Pizza Margarita      535       728             $23.296.000       $43.544       17.7%       22.7%
     Cerveza Artesanal      468       634              $8.876.000       $18.966       15.4%        8.6%
        Corte de Carne      370       526             $23.670.000       $63.973       12.8%       23.0%
      Limonada Natural      389       508              $4.064.000       $10.447       12.3%        4.0%
       Pasta Carbonara      318       451             $12.628.000       $39.711       10.9%       12.3%
        Ensalada César      221       322              $7.084.000       $32.054        7.8%        6.9%
          Sopa del Día      109       154              $2.310.000       $21.193        3.7%        2.2%
```

### B. Segmentación K-Means ($k=3$)
El agrupamiento por volumen e ingresos clasificó el menú en 3 perfiles estratégicos:
* **Cluster 0 — Platos Estrella de Alto Valor y Volumen:** *Hamburguesa rsKitchen, Pizza Margarita, Corte de Carne*. Representan el motor financiero del negocio (66% de la facturación total).
* **Cluster 1 — Platos de Rotación Media/Baja:** *Pasta Carbonara, Ensalada César, Sopa del Día*. Platos de acompañamiento y margen moderado.
* **Cluster 2 — Bebidas de Alto Flujo:** *Cerveza Artesanal, Limonada Natural*. Gran volumen de raciones, alta recurrencia y bajo ticket unitario.

*(Gráfica persistida en `ml/out/kmeans_clusters.png`)*.

---

## 5. Evaluación del Modelo Principal: Proyección de Demanda

### Configuración del Experimento
* **Granularidad:** Panel agregado diario por platillo (`fecha`, `platillo`).
* **Variables explicativas:** Día de semana (0-6), día del mes, mes, flag fin de semana, flag quincena, lag $t-1$, lag $t-7$, media móvil 7 días, media móvil 14 días y dummies de platillo.
* **División Temporal Estricta:**
  * **Entrenamiento (Train):** 2026-01-01 a 2026-08-31 (1.888 registros diarios-platillo).
  * **Prueba (Test Hold-Out):** 2026-09-01 a 2026-10-31 (488 registros diarios-platillo, meses completos posteriores).

### Métricas Reales Obtenidas en Test

| Modelo | MAE (Test) | RMSE (Test) | $R^2$ (Test) | Comportamiento |
| :--- | :---: | :---: | :---: | :--- |
| **Baseline (Lag-7 Naïve)** | $1.9980$ | $2.7695$ | $-0.5774$ | Replicar la venta de hace 7 días es inestable debido a la varianza estocástica diaria. |
| **Regresión Lineal Múltiple** | **$1.4698$** | **$1.9918$** | **$0.1841$** | **Mejor generalización out-of-sample.** Modela adecuadamente la pendiente de tendencia y los efectos fijos de fin de semana y quincena. |
| **Random Forest Regressor** | $1.5355$ | $2.0547$ | $0.1318$ | Captura no-linealidades, pero presenta ligera sobre-sensibilidad en los valles de días lunes. |

**Interpretación del $R^2 = 0.1841$:**  
En demanda diaria desagregada por SKU con valores pequeños (medias de 1 a 4 raciones diarias), una precisión con error absoluto medio de **$\approx 1.47$ raciones** es operativamente excelente para la gestión de cocina, aunque el $R^2$ estadístico no alcance cifras artificialmente elevadas.

*(Gráfica de predicciones vs valores reales en `ml/out/demand_predictions.png`)*.

---

## 6. Evaluación del Modelo Secundario: Clasificación del Estado de Pago

### Configuración
* **Objetivo:** Predecir `estado` ($1 = \text{pagado}$, $0 = \text{pendiente}$).
* **Partición:** 75% Train (2.250 pedidos) / 25% Test (750 pedidos), estratificado.
* **Desbalance de clases en Test:** 743 `pagado` vs 7 `pendiente` (reflejo de la operación donde el 99% de comandas históricas se saldan).

### Métricas en Test

| Algoritmo | Accuracy | Precision (Macro) | Recall (Macro) | F1-Score (Macro) |
| :--- | :---: | :---: | :---: | :---: |
| **Árbol de Decisión (C4.5 / J48)** | **$98.93\%$** | $0.4953$ | $0.4993$ | **$0.4973$** |
| **Random Forest Classifier** | $95.60\%$ | $0.4952$ | $0.4825$ | $0.4888$ |

*(Matriz de confusión generada en `ml/out/confusion_matrix.png`)*.

---

## 7. Proyección a 7 Días y Plan de Compras de Insumos

Ejecutando la inferencia predictiva desde `ml/predict.py` para la primera semana de noviembre de 2026:

* **Demanda Total Proyectada (7 días):** **121 raciones**
* **Ingresos Proyectados Estimados:** **\$2.908.000 COP**

### Plan de Compras Semanal por Platillo

| Ranking | Platillo | Raciones (7d) | Ingresos Estimados | Insumos Críticos a Comprar |
| :---: | :--- | :---: | :---: | :--- |
| **1** | Cerveza Artesanal | 19 | \$266.000 | 1 barril o 24 botellas de cerveza artesanal rubia / IPA. |
| **2** | Hamburguesa rsKitchen | 18 | \$468.000 | 20 panes artesanales brioche, 3.5 kg de carne molida especial, 1 kg queso cheddar madurado, 1 kg tocineta, 5 kg papas rústicas. |
| **3** | Pizza Margarita | 18 | \$576.000 | 4 kg harina de fuerza / masa madre, 2 kg salsa pomodoro, 2.5 kg mozzarella fresca, 2 manojos de albahaca fresca. |
| **4** | Pasta Carbonara | 15 | \$420.000 | 2 kg pasta larga fettuccine, 1.5 kg guanciale o tocineta ahumada, 1 kg queso pecorino/parmesano, 2 cubetas de huevos. |
| **5** | Corte de Carne | 14 | \$630.000 | 5 kg cortes premium de lomo/bife de res, mantequilla de romero, sal marina gruesa. |
| **6** | Limonada Natural | 13 | \$104.000 | 4 kg limones tahití frescos, 1 manojo hierbabuena, 2 kg azúcar orgánica. |
| **7** | Ensalada César | 12 | \$264.000 | 6 lechugas romanas, 2.5 kg pechuga de pollo, 1 botella aderezo césar, croûtons y parmesano. |
| **8** | Sopa del Día | 12 | \$180.000 | 4 kg verduras frescas de temporada (zanahoria, papa, apio, cebolla), huesos y fondos de res/ave. |

---

## 8. Recomendaciones Finales

1. **Abastecimiento Justo a Tiempo (JIT):** Los insumos perecederos para Hamburguesas, Pizzas y Cortes deben adquirirse entre miércoles y jueves por la mañana para cubrir el 65% de la demanda que se concentra de viernes a domingo.
2. **Priorización de Mesas:** El corte de carne genera el 23% de los ingresos totales pese a representar solo el 12.8% del volumen; debe priorizarse la oferta de cortes en el canal presencial (`mesa`).
3. **Escalamiento:** La API REST en `ml/api.py` permite que el módulo Java Spring Boot consulte periódicamente `/predict` y actualice el dashboard de inventario de forma automática sin intervención manual.
