# Documentación del Generador de Datos Sintéticos (`generate_synthetic.py`)

## 1. Justificación y Contexto
Debido a la escasez de datos transaccionales históricos reales en la base de datos (16 registros en MongoDB y 120 registros dispersos con alta varianza de precios en archivos de plantilla inicial), se implementó un generador estocástico reproducible para la materia **Minería de Datos II**.

El objetivo es simular un comportamiento de consumo gastronómico realista y coherente que permita entrenar, validar y comparar algoritmos de Machine Learning (regresión para demanda de platillos, clasificación de estados de pago y clustering) con series temporales válidas.

---

## 2. Parámetros Globales y Reproducibilidad
* **Semilla Pseudoaleatoria:** `seed = 42` (fijada en `random.seed(42)` y `numpy.random.seed(42)`).
* **Volumen:** 3.000 transacciones individuales de pedidos.
* **Ventana Temporal:** Del `2026-01-01` al `2026-10-31` (10 meses completos, 304 días naturales).
* **Colección / Destino:**
  * Archivo local: `ml/data/dataset_sintetico.csv`.
  * MongoDB (opcional, bajo confirmación previa): Colección aislada `pedido_sintetico` en la base `rskitchen5` con el atributo `origen = "sintetico"`. La colección productiva real `pedido` **nunca es modificada ni alterada**.

---

## 3. Catálogo de Platillos y Precios Fijos (COP)
Se utilizaron los 8 platillos representativos del restaurante RSKitchen con precios fijos coherentes con la economía gastronómica colombiana:

| Platillo | Categoría | Precio Unitario (COP) | Probabilidad Base ($\%$) |
| :--- | :--- | :--- | :--- |
| **Hamburguesa rsKitchen** | Plato fuerte | \$26.000 | $20\%$ |
| **Pizza Margarita** | Plato fuerte | \$32.000 | $18\%$ |
| **Cerveza Artesanal** | Bebida | \$14.000 | $14\%$ |
| **Limonada Natural** | Bebida | \$8.000 | $14\%$ |
| **Corte de Carne** | Plato fuerte | \$45.000 | $12\%$ |
| **Pasta Carbonara** | Plato fuerte | \$28.000 | $10\%$ |
| **Ensalada César** | Entrada | \$22.000 | $7\%$ |
| **Sopa del Día** | Entrada | \$15.000 | $5\%$ |

---

## 4. Patrones y Reglas Estadísticas de Generación

### A. Tendencia Temporal (Crecimiento Suave)
Se modeló un crecimiento sostenido de la demanda a medida que transcurren los meses del año (de enero a octubre):
$$\text{Factor Tendencia} = 0.80 + 0.45 \times \left(\frac{\text{días transcurridos}}{304}\right)$$
Esto simula un aumento gradual de clientela del $+56\%$ a lo largo del año.

### B. Estacionalidad Semanal (Día de la Semana)
Los hábitos de consumo restaurantero presentan marcadas variaciones entre días laborales y fines de semana:
* **Lunes y Martes:** Multiplicador $\times 0.65$ y $\times 0.70$ (días de menor concurrencia).
* **Miércoles y Jueves:** Multiplicador $\times 0.85$ y $\times 0.95$ (demanda media).
* **Viernes:** Multiplicador $\times 1.45$ (inicio de fin de semana, reuniones sociales).
* **Sábado:** Multiplicador $\times 1.65$ (día pico del restaurante).
* **Domingo:** Multiplicador $\times 1.40$ (consumo familiar).

### C. Efecto Quincena (Picos de Ingresos)
En Colombia, los días 15 y 30/31 corresponden a las fechas de pago salarial (quincena):
* Los días 15, 16, 30 y 31 reciben un multiplicador adicional de $\times 1.35$ (+35% de afluencia).

### D. Sedes y Canales
* **Sedes:**
  * Sede Principal: $60\%$ de los pedidos.
  * Sede Centro: $40\%$ de los pedidos.
* **Canales de Venta:**
  * `mesa` (atención en salón): $50\%$
  * `rappi` (delivery por app): $32\%$
  * `whatsapp` (delivery / encargo directo): $18\%$
* **Interacción Canal $\leftrightarrow$ Platillo:**
  * En pedidos vía `rappi`, la probabilidad de `Hamburguesa rsKitchen` y `Pizza Margarita` sube un $+30\%$ y $+20\%$, mientras que las sopas disminuyen.
  * En consumo en `mesa`, los `Corte de Carne` y `Cerveza Artesanal` aumentan un $+25\%$ y $+30\%$.

### E. Cantidades por Pedido
* $1$ unidad: $72\%$
* $2$ unidades: $20\%$
* $3$ unidades: $6\%$
* $4$ unidades: $2\%$
El campo `precio` total corresponde a $\text{precio unitario} \times \text{cantidad}$.

### F. Estado del Pedido (`pagado` vs `pendiente`)
La probabilidad de pago se estructuró a partir del ciclo de vida real de las cuentas:
1. **Pedidos Históricos (> 3 días de antigüedad):** $99.2\%$ de probabilidad de figurar como `pagado` (cuentas cerradas y auditadas; solo $0.8\%$ de anomalías o disputas no resueltas).
2. **Pedidos de 2 a 3 días:** $94.0\%$ `pagado`.
3. **Pedidos Recientes (últimas 24 a 48 horas):**
   * Canal `rappi`: $98\%$ pagado (cobro en línea inmediato).
   * Canal `whatsapp`: $85\%$ pagado (transferencia bancaria o cobro contra entrega).
   * Canal `mesa`: $75\%$ pagado (mesas activas consumiendo antes del cierre de cuenta).

---

## 5. Esquema del Dataset Generado

| Columna | Tipo de Dato | Descripción |
| :--- | :--- | :--- |
| `numeroPedido` | String (`PED-XXXX`) | Identificador único del pedido |
| `precio` | Integer (COP) | Monto total de la orden ($\text{precio unitario} \times \text{cantidad}$) |
| `platillo` | String | Nombre exacto del platillo |
| `CreacionPedido` | Datetime (`YYYY-MM-DD HH:MM:SS`) | Fecha y hora exacta de la orden |
| `estado` | String (`pagado` / `pendiente`) | Estado financiero de la comanda |
| `sede` | String (`Principal` / `Centro`) | Local comercial donde se originó el pedido |
| `canal` | String (`mesa` / `rappi` / `whatsapp`) | Medio de recepción de la orden |
| `cantidad` | Integer (1 - 4) | Número de raciones pedidas |
| `dia_semana` | String | Nombre del día en español |
