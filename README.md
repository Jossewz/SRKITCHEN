# 🍽️ SR Kitchen - Sistema de Gestión de Restaurantes

Sistema integral y moderno para la administración y operación de restaurantes, incluyendo gestión de mesas, pedidos en tiempo real, catálogo de platillos, facturación, control de inventario, analítica de optimización de menús y asistente inteligente asistido por IA (Groq / LLaMA-3.3).

---

## 🛠️ Stack Tecnológico Actual

### Backend
- **Lenguaje & Plataforma:** Java 21 / Java 25
- **Framework:** Spring Boot 3.4.3
- **Persistencia:** Spring Data JPA + Hibernate ORM (HikariCP Connection Pool)
- **Seguridad:** Spring Security 6 (Autenticación basada en sesiones web, CSRF, BCrypt y endpoints REST para clientes móviles)
- **Inteligencia Artificial:** Cliente REST Groq API (`llama-3.3-70b-versatile`) + RagService integrado con contexto operacional.
- **Motor de Optimización:** Algoritmo lineal simplex para maximización de margen y rotación de insumos en cocina.

### Frontend Web
- **Motor de Vistas:** Thymeleaf 3
- **Estilos:** Tailwind CSS + Google Fonts (*Plus Jakarta Sans*, *Work Sans*)
- **Iconografía:** Google Material Symbols Outlined
- **Arquitectura UI:** Diseño modular responsive con fragmentos compartidos (Sidebar, Header, modales y alertas).

### Base de Datos & Herramientas
- **Motor Relacional:** PostgreSQL 16 (Alpine)
- **Administración Visual:** pgAdmin 4 (con autoconexión a la base de datos preconfigurada)

### Cliente Móvil
- **Compatibilidad:** API RESTful JSON para aplicación móvil Flutter (`/api/auth/**`, `/api/platillos/**`, etc.)

### DevOps & Contenedores
- **Contenedores:** Docker (Multi-stage build con runtime ligero Eclipse Temurin JRE 21 Alpine)
- **Orquestación:** Docker Compose v2

---

## 🔐 Credenciales de Acceso

### 1. Aplicación Web & API Móvil
| Rol | Correo / Usuario | Contraseña | URL de Acceso |
| :--- | :--- | :--- | :--- |
| **Administrador** | `admin@rskitchen.com` | `admin123` | [http://localhost:8080/login](http://localhost:8080/login) |
| **Mesero** | `mesero@rskitchen.com` | `mesero123` | [http://localhost:8080/login](http://localhost:8080/login) |

> **Nota:** La aplicación inicializa automáticamente estos usuarios y el menú base al primer arranque mediante `DataInitializer`.

### 2. pgAdmin 4 (Administrador de Base de Datos Web)
| Parámetro | Valor |
| :--- | :--- |
| **URL Web** | [http://localhost:5050](http://localhost:5050) |
| **Usuario / Email** | `admin@rskitchen.com` |
| **Contraseña** | `admin123` |
| **Servidor Preconfigurado** | `RSKitchen PostgreSQL` (host: `postgres`, puerto: `5432`, BD: `rskitchen`) |

### 3. Conexión Directa a PostgreSQL
| Parámetro | Valor |
| :--- | :--- |
| **Host** | `localhost` (desde el anfitrión) o `postgres` (dentro de Docker) |
| **Puerto** | `5432` |
| **Base de Datos** | `rskitchen` |
| **Usuario** | `postgres` |
| **Contraseña** | `postgres` |

---

## 🚀 Despliegue y Ejecución

### Opción A: Despliegue con Docker Compose (Recomendado)

Levanta PostgreSQL, pgAdmin y la aplicación Spring Boot de forma aislada:

```bash
# Construir imágenes y levantar en segundo plano
docker compose up -d --build

# Ver logs de la aplicación
docker compose logs -f app

# Detener los servicios
docker compose down
```

### Opción B: Ejecución Local en Desarrollo

Si prefieres correr la aplicación directamente con Maven mientras la base de datos corre en Docker:

1. **Iniciar únicamente PostgreSQL y pgAdmin:**
   ```bash
   docker compose up -d postgres pgadmin
   ```

2. **Ejecutar la aplicación Spring Boot:**
   ```powershell
   # Windows PowerShell
   .\mvnw.cmd spring-boot:run
   ```
   ```bash
   # Linux / macOS
   ./mvnw spring-boot:run
   ```

3. **Ejecutar pruebas unitarias y de integración:**
   ```bash
   ./mvnw test
   ```

---

## 🧭 Módulos y Rutas Principales

| Ruta | Descripción | Acceso |
| :--- | :--- | :--- |
| `/home` | Panel principal y métricas generales del restaurante | Admin / Mesero |
| `/mesa` | Mapa interactivo del estado de las mesas (Libre, Ocupada, Reservada) | Admin / Mesero |
| `/pedidos` | Toma y despacho de comandas de mesa | Admin / Mesero |
| `/factura` | Facturación, consolidación de comandas e impresión de tickets | Admin / Mesero |
| `/platillos` | Gestión y edición del menú gastronómico | Solo Admin |
| `/producto` | Control de inventario de materias primas e insumos de cocina | Solo Admin |
| `/mesero` | Administración del personal de meseros | Solo Admin |
| `/usuarios` | Gestión de usuarios y roles del sistema | Solo Admin |
| `/datos` | Motor de optimización de menús y dashboards analíticos | Solo Admin |
| `/foro` | Buzón colaborativo de sugerencias y comunicación interna | Admin / Mesero |
| `/api/chat` | Endpoint para el asistente inteligente chatbot | Autenticado |
| `/api/auth/login` | Endpoint de autenticación REST para la App Flutter | Público |