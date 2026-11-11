# 🗄️ Documentación de Datos y Scripts SQL - RSKitchen 5.0

Este directorio contiene los scripts SQL estructurados y poblados con un volumen considerable de datos realistas, coherentes y probados para el sistema **RSKitchen**.

---

## 📁 Archivos Disponibles

| Archivo | Motor Recomendado | Descripción |
| :--- | :--- | :--- |
| **`init_postgresql.sql`** | **PostgreSQL 16** (Docker Compose) | **Script Completo**: Crea la estructura DDL (tablas, llaves foráneas, índices), limpia datos anteriores (TRUNCATE en cascada), inserta todos los datos DML y actualiza las secuencias `BIGSERIAL` para evitar errores de ID al insertar nuevos registros desde la aplicación. |
| **`init_mysql.sql`** | **MySQL 8.0+ / MariaDB** (`application.properties`) | **Script Completo**: Crea la estructura DDL con motor InnoDB y cotejamiento UTF-8, desactiva temporalmente revisión de llaves foráneas (`FOREIGN_KEY_CHECKS = 0`) para una carga limpia, e inserta todo el conjunto de datos. |
| **`seed_data.sql`** | **Universal** (PostgreSQL / MySQL / H2) | **Solo Datos (DML)**: Útil cuando Spring Boot / Hibernate ya ha creado las tablas automáticamente (`spring.jpa.hibernate.ddl-auto=update` o `create`). Contiene exclusivamente las sentencias `INSERT INTO`. |
| **`generate_data.py`** | Python 3.x | Script generador automatizado que calcula las sumas, subtotales, recetas y genera los archivos SQL anteriores. |

---

## 📊 Resumen del Volumen de Datos Generados

Los datos han sido diseñados respetando todas las reglas de negocio del sistema:

- **🏢 3 Restaurantes (Multi-tenant):**
  1. `RSKitchen Gourmet Central` (ID 1 - Cocina de autor y parrilla)
  2. `La Trattoria Bella Italia` (ID 2 - Pizzería y pastas tradicionales)
  3. `Tacos & Cantina El Fuego` (ID 3 - Comida mexicana y coctelería)

- **👥 12 Usuarios y Empleados (Contraseñas encriptadas con BCrypt):**
  - **1 Super Administrador Maestro:** `creator@rskitchen.com` (`ROLE_CREATOR`)
  - **3 Administradores de Restaurante:**
    - `admin@rskitchen.com` (Restaurante 1 - Gourmet Central)
    - `admin.trattoria@rskitchen.com` (Restaurante 2 - Trattoria)
    - `admin.elfuego@rskitchen.com` (Restaurante 3 - Cantina)
  - **8 Meseros:**
    - R1: `mesero@rskitchen.com` (M01), `carlos.mesero@rskitchen.com` (M02), `valentina.mesero@rskitchen.com` (M03), `sofia.mesero@rskitchen.com` (M04)
    - R2: `marco.mesero@rskitchen.com` (M05), `lucia.mesero@rskitchen.com` (M06)
    - R3: `miguel.mesero@rskitchen.com` (M07), `fernanda.mesero@rskitchen.com` (M08)

- **🪑 30 Mesas:**
  - Restaurante 1: 14 mesas (mesas libres y mesas ocupadas con pedidos activos).
  - Restaurante 2: 10 mesas.
  - Restaurante 3: 6 mesas.

- **📦 35 Productos / Insumos de Inventario:**
  - Carnes, aves, lácteos finos, vegetales frescos, licores, harinas, abarrotes y salsas.
  - Diseñados específicamente para activar los diferentes niveles de alerta del Dashboard móvil:
    - **Stock Crítico (< 5 unidades):** Carne Molida Angus (4 kg), Tomate Chonto (3 kg), Mascarpone (2 kg), Aguacate Hass (3 kg), etc.
    - **Stock Bajo (< 15 unidades):** Queso Cheddar (8 pqts), Tocineta (14 kg), Queso Parmesano (6 kg), etc.
    - **Stock Normal (>= 15 unidades):** Pechuga de Pollo (28 kg), Papas (42 kg), Harina 00 (80 kg), Cerveza IPA (72 unids), etc.

- **🍽️ 25 Platillos de Menú:**
  - Entradas, hamburguesas gourmet, cortes de carne Angus, pizzas napolitanas en masa madre, pastas frescas, tacos de birria al pastor, postres y coctelería.

- **📜 44 Registros de Recetas (`platillo_ingredientes`):**
  - Cada platillo descuenta insumos proporcionales del inventario real.

- **🧾 30 Pedidos con Fechas Históricas y Actuales:**
  - Distribuidos entre el 1 de noviembre y el 11 de noviembre de 2026.
  - 20 pedidos históricos cerrados y facturados en horas de almuerzo y cena.
  - 10 pedidos activos y en curso en mesas ocupadas (`PENDIENTE` y `APROBADA`) para interactuar en tiempo real desde la UI web y móvil.

- **📑 80 Items de Pedido (`items_pedido`):**
  - Precios unitarios y cantidades coherentes cuyos subtotales suman exactamente el total de cada orden.

- **💰 30 Facturas y 20 Pagos Transaccionales:**
  - Métodos de pago registrados: `EFECTIVO`, `TARJETA`, `TRANSFERENCIA`, `NEQUI` y `DAVIPLATA`.

- **💬 12 Mensajes de Foro (`foros`):**
  - Registro de cambios de turno, felicitaciones de comensales, notas de inventario del chef y novedades operativas.

---

## 🔐 Credenciales de Acceso para Pruebas

Todas las contraseñas han sido hasheadas con el mismo algoritmo **BCrypt** utilizado por Spring Security:

| Rol | Correo / Usuario | Contraseña en Texto Plano | Acceso Web / Móvil |
| :--- | :--- | :--- | :--- |
| **Super Admin (Creator)** | `creator@rskitchen.com` | `creator123` | Multi-restaurante, métricas globales |
| **Administrador Central** | `admin@rskitchen.com` | `admin123` | Panel R1, productos, platillos, analítica |
| **Administrador Trattoria** | `admin.trattoria@rskitchen.com` | `admin123` | Panel R2 (Trattoria) |
| **Administrador Cantina** | `admin.elfuego@rskitchen.com` | `admin123` | Panel R3 (Cantina) |
| **Mesero R1 (Andrés)** | `mesero@rskitchen.com` | `mesero123` | Mesas, comandas, pedidos R1 |
| **Mesero R1 (Carlos)** | `carlos.mesero@rskitchen.com` | `mesero123` | Mesas, comandas, pedidos R1 |
| **Mesero R2 (Marco)** | `marco.mesero@rskitchen.com` | `mesero123` | Mesas, comandas, pedidos R2 |
| **Mesero R3 (Miguel)** | `miguel.mesero@rskitchen.com` | `mesero123` | Mesas, comandas, pedidos R3 |

*(Para cualquier otro usuario secundario, la contraseña por defecto es `mesero123` o `123456`).*

---

## 🚀 Instrucciones de Ejecución

### Opción 1: En PostgreSQL con Docker (Recomendada)
Si ejecutas el proyecto con `docker compose`:

```bash
# Ejecutar directamente el script dentro del contenedor de PostgreSQL
docker exec -i rskitchen-postgres psql -U postgres -d rskitchen < PA5-RSKITCHEN/database/init_postgresql.sql
```

O desde **pgAdmin 4** (en `http://localhost:5050`):
1. Inicia sesión con `admin@rskitchen.com` / `admin123`.
2. Conéctate a la base de datos `rskitchen`.
3. Abre el **Query Tool** (`Alt + Shift + Q`).
4. Abre o pega el contenido de `init_postgresql.sql` y presiona **Execute / Run** (`F5`).

---

### Opción 2: En MySQL Local
Si tienes MySQL corriendo localmente en el puerto 3306 según tu `application.properties`:

```bash
# Desde PowerShell o CMD
Get-Content PA5-RSKITCHEN\database\init_mysql.sql | mysql -u root -p Rskitchen6
```

O ábrelo en **MySQL Workbench**, **DBeaver** o **HeidiSQL** y ejecútalo sobre la base de datos `Rskitchen6`.

---

### Opción 3: Carga Directa de Seed Data (Cuando Hibernate ya creó las tablas)
Si ya ejecutaste la aplicación Spring Boot una vez y las tablas ya existen:
- Ejecuta el archivo `seed_data.sql` en tu gestor de base de datos preferido.

