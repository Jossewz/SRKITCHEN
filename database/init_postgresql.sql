-- ============================================================================
-- RSKITCHEN 5.0 - SCRIPT DE INICIALIZACIÓN COMPLETO PARA POSTGRESQL
-- Base de datos: rskitchen (Docker Compose / Alpine PostgreSQL 16)
-- Incluye DDL (Tablas, Índices, Constraints) y DML con datos completos y coherentes.
-- ============================================================================

-- Crear tablas si no existen
CREATE TABLE IF NOT EXISTS restaurants (
    id BIGSERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    correo VARCHAR(255) NOT NULL UNIQUE,
    contraseña VARCHAR(255) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS usuarios (
    id BIGSERIAL PRIMARY KEY,
    id_mesero VARCHAR(255),
    name VARCHAR(255) NOT NULL,
    mail VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    rol VARCHAR(255) NOT NULL,
    restaurant_id BIGINT REFERENCES restaurants(id) ON DELETE SET NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS mesas (
    id BIGSERIAL PRIMARY KEY,
    num INT NOT NULL,
    ocupado BOOLEAN NOT NULL DEFAULT FALSE,
    mesero_id VARCHAR(255),
    restaurant_id BIGINT REFERENCES restaurants(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS mesa_pedidos (
    mesa_id BIGINT NOT NULL REFERENCES mesas(id) ON DELETE CASCADE,
    pedido_id VARCHAR(255) NOT NULL
);

CREATE TABLE IF NOT EXISTS productos (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255),
    descripcion VARCHAR(1000),
    u_medida VARCHAR(255),
    cant VARCHAR(255),
    price DOUBLE PRECISION NOT NULL,
    stock INT NOT NULL,
    restaurant_id BIGINT REFERENCES restaurants(id) ON DELETE CASCADE,
    activo BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS platillos (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DOUBLE PRECISION NOT NULL,
    cant VARCHAR(255),
    restaurant_id BIGINT REFERENCES restaurants(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS platillo_ingredientes (
    id BIGSERIAL PRIMARY KEY,
    platillo_id BIGINT NOT NULL REFERENCES platillos(id) ON DELETE CASCADE,
    producto_id BIGINT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    cantidad DOUBLE PRECISION NOT NULL DEFAULT 1.0
);

CREATE TABLE IF NOT EXISTS pedidos (
    id BIGSERIAL PRIMARY KEY,
    mesa_num INT NOT NULL,
    mesero_name VARCHAR(255),
    mesa_id VARCHAR(255),
    mesero_id VARCHAR(255),
    fecha TIMESTAMP,
    total DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    pagado BOOLEAN NOT NULL DEFAULT FALSE,
    restaurant_id BIGINT REFERENCES restaurants(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS items_pedido (
    id BIGSERIAL PRIMARY KEY,
    pedido_id BIGINT REFERENCES pedidos(id) ON DELETE CASCADE,
    product_id VARCHAR(255),
    name VARCHAR(255),
    price DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    cant VARCHAR(255),
    unidades INT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS facturas (
    id BIGSERIAL PRIMARY KEY,
    pedido_id VARCHAR(255),
    mesa_num VARCHAR(255),
    mesero_name VARCHAR(255),
    fecha TIMESTAMP,
    total DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    pagada BOOLEAN NOT NULL DEFAULT FALSE,
    estado VARCHAR(255) DEFAULT 'PENDIENTE',
    restaurant_id BIGINT REFERENCES restaurants(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS factura_items (
    factura_id BIGINT NOT NULL REFERENCES facturas(id) ON DELETE CASCADE,
    item_id BIGINT NOT NULL REFERENCES items_pedido(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS pagos (
    id BIGSERIAL PRIMARY KEY,
    factura_id VARCHAR(255),
    metodo VARCHAR(255),
    monto DOUBLE PRECISION NOT NULL,
    fecha TIMESTAMP,
    imprimir_copia BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS foros (
    id BIGSERIAL PRIMARY KEY,
    fnombre VARCHAR(255),
    fcomentario VARCHAR(2000),
    fecha TIMESTAMP
);

-- Limpieza previa opcional para garantizar inserción limpia
TRUNCATE TABLE foros, pagos, factura_items, facturas, items_pedido, pedidos, platillo_ingredientes, platillos, productos, mesa_pedidos, mesas, usuarios, restaurants RESTART IDENTITY CASCADE;

-- ============================================================================
-- 1. RESTAURANTES (Multi-tenant)
-- ============================================================================
INSERT INTO restaurants (id, nombre, correo, contraseña, activo) VALUES (1, 'RSKitchen Gourmet Central', 'contacto@rskitchen.com', '$2a$10$QlxD/wOLGYlm4JPChUeDYuN9QhIQljCF2/BAE959357nA0hu0GUq6', TRUE);
INSERT INTO restaurants (id, nombre, correo, contraseña, activo) VALUES (2, 'La Trattoria Bella Italia', 'info@trattoriabella.com', '$2a$10$QlxD/wOLGYlm4JPChUeDYuN9QhIQljCF2/BAE959357nA0hu0GUq6', TRUE);
INSERT INTO restaurants (id, nombre, correo, contraseña, activo) VALUES (3, 'Tacos & Cantina El Fuego', 'reservas@elfuego.com', '$2a$10$QlxD/wOLGYlm4JPChUeDYuN9QhIQljCF2/BAE959357nA0hu0GUq6', TRUE);

-- ============================================================================
-- 2. USUARIOS (Roles: ROLE_CREATOR, ROLE_ADMIN, ROLE_MESERO)
-- ============================================================================
INSERT INTO usuarios (id, id_mesero, name, mail, password, rol, restaurant_id, activo) VALUES (1, NULL, 'Super Administrador Creador', 'creator@rskitchen.com', '$2a$10$kN7HYrArOD8NRVX.WvGHVeadi9qCXP/A9eRdaO50d25PoEpCRpY36', 'ROLE_CREATOR', NULL, TRUE);
INSERT INTO usuarios (id, id_mesero, name, mail, password, rol, restaurant_id, activo) VALUES (2, NULL, 'Admin Central RSKitchen', 'admin@rskitchen.com', '$2a$10$QlxD/wOLGYlm4JPChUeDYuN9QhIQljCF2/BAE959357nA0hu0GUq6', 'ROLE_ADMIN', 1, TRUE);
INSERT INTO usuarios (id, id_mesero, name, mail, password, rol, restaurant_id, activo) VALUES (3, NULL, 'Admin Gianluigi Trattoria', 'admin.trattoria@rskitchen.com', '$2a$10$QlxD/wOLGYlm4JPChUeDYuN9QhIQljCF2/BAE959357nA0hu0GUq6', 'ROLE_ADMIN', 2, TRUE);
INSERT INTO usuarios (id, id_mesero, name, mail, password, rol, restaurant_id, activo) VALUES (4, NULL, 'Admin Mateo Cantina', 'admin.elfuego@rskitchen.com', '$2a$10$QlxD/wOLGYlm4JPChUeDYuN9QhIQljCF2/BAE959357nA0hu0GUq6', 'ROLE_ADMIN', 3, TRUE);
INSERT INTO usuarios (id, id_mesero, name, mail, password, rol, restaurant_id, activo) VALUES (5, 'M01', 'Andrés López (Mesero)', 'mesero@rskitchen.com', '$2a$10$s8gaHGKENN3c.twzIGd2aOod5QFzCywrCZhLu.YNVPkREY6kBMuLi', 'ROLE_MESERO', 1, TRUE);
INSERT INTO usuarios (id, id_mesero, name, mail, password, rol, restaurant_id, activo) VALUES (6, 'M02', 'Carlos Gómez (Mesero)', 'carlos.mesero@rskitchen.com', '$2a$10$s8gaHGKENN3c.twzIGd2aOod5QFzCywrCZhLu.YNVPkREY6kBMuLi', 'ROLE_MESERO', 1, TRUE);
INSERT INTO usuarios (id, id_mesero, name, mail, password, rol, restaurant_id, activo) VALUES (7, 'M03', 'Valentina Torres (Mesera)', 'valentina.mesero@rskitchen.com', '$2a$10$s8gaHGKENN3c.twzIGd2aOod5QFzCywrCZhLu.YNVPkREY6kBMuLi', 'ROLE_MESERO', 1, TRUE);
INSERT INTO usuarios (id, id_mesero, name, mail, password, rol, restaurant_id, activo) VALUES (8, 'M04', 'Sofía Morales (Mesera)', 'sofia.mesero@rskitchen.com', '$2a$10$s8gaHGKENN3c.twzIGd2aOod5QFzCywrCZhLu.YNVPkREY6kBMuLi', 'ROLE_MESERO', 1, TRUE);
INSERT INTO usuarios (id, id_mesero, name, mail, password, rol, restaurant_id, activo) VALUES (9, 'M05', 'Marco Rossi (Cameriere)', 'marco.mesero@rskitchen.com', '$2a$10$s8gaHGKENN3c.twzIGd2aOod5QFzCywrCZhLu.YNVPkREY6kBMuLi', 'ROLE_MESERO', 2, TRUE);
INSERT INTO usuarios (id, id_mesero, name, mail, password, rol, restaurant_id, activo) VALUES (10, 'M06', 'Lucía Bellini (Cameriera)', 'lucia.mesero@rskitchen.com', '$2a$10$s8gaHGKENN3c.twzIGd2aOod5QFzCywrCZhLu.YNVPkREY6kBMuLi', 'ROLE_MESERO', 2, TRUE);
INSERT INTO usuarios (id, id_mesero, name, mail, password, rol, restaurant_id, activo) VALUES (11, 'M07', 'Miguel Ángel Hernández (Mesero)', 'miguel.mesero@rskitchen.com', '$2a$10$s8gaHGKENN3c.twzIGd2aOod5QFzCywrCZhLu.YNVPkREY6kBMuLi', 'ROLE_MESERO', 3, TRUE);
INSERT INTO usuarios (id, id_mesero, name, mail, password, rol, restaurant_id, activo) VALUES (12, 'M08', 'Fernanda Ortiz (Mesera)', 'fernanda.mesero@rskitchen.com', '$2a$10$s8gaHGKENN3c.twzIGd2aOod5QFzCywrCZhLu.YNVPkREY6kBMuLi', 'ROLE_MESERO', 3, TRUE);

-- ============================================================================
-- 3. MESAS (Salón principal, terraza y barras)
-- ============================================================================
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (1, 1, FALSE, NULL, 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (2, 2, TRUE, '5', 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (3, 3, TRUE, '6', 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (4, 4, FALSE, NULL, 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (5, 5, TRUE, '7', 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (6, 6, FALSE, NULL, 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (7, 7, TRUE, '8', 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (8, 8, FALSE, NULL, 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (9, 9, FALSE, NULL, 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (10, 10, TRUE, '5', 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (11, 11, FALSE, NULL, 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (12, 12, FALSE, NULL, 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (13, 13, TRUE, '6', 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (14, 14, FALSE, NULL, 1);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (15, 1, TRUE, '9', 2);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (16, 2, FALSE, NULL, 2);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (17, 3, TRUE, '10', 2);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (18, 4, FALSE, NULL, 2);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (19, 5, FALSE, NULL, 2);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (20, 6, TRUE, '9', 2);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (21, 7, FALSE, NULL, 2);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (22, 8, FALSE, NULL, 2);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (23, 9, FALSE, NULL, 2);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (24, 10, FALSE, NULL, 2);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (25, 1, TRUE, '11', 3);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (26, 2, FALSE, NULL, 3);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (27, 3, TRUE, '12', 3);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (28, 4, FALSE, NULL, 3);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (29, 5, FALSE, NULL, 3);
INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES (30, 6, FALSE, NULL, 3);

-- ============================================================================
-- 4. MESA_PEDIDOS (Asociación mesa - pedidos activos/históricos)
-- ============================================================================
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (2, '1');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (5, '2');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (7, '3');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (10, '4');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (3, '5');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (15, '6');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (17, '7');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (25, '8');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (1, '9');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (4, '10');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (8, '11');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (12, '12');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (20, '13');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (27, '14');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (6, '15');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (9, '16');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (11, '17');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (14, '18');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (16, '19');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (26, '20');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (2, '21');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (3, '22');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (5, '23');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (7, '24');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (10, '25');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (13, '26');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (15, '27');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (17, '28');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (25, '29');
INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES (27, '30');

-- ============================================================================
-- 5. PRODUCTOS / INSUMOS / INVENTARIO
-- ============================================================================
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (1, 'Carne Molida Angus', 'Corte magro 80/20 especial para hamburguesas', 'kg', 'kg', 24000.0, 4, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (2, 'Pechuga de Pollo Fresca', 'Pechuga deshuesada y limpia de primera calidad', 'kg', 'kg', 18500.0, 28, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (3, 'Queso Cheddar Madurado', 'Queso cheddar en láminas para hamburguesas', 'paquetes', 'paquetes', 15000.0, 8, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (4, 'Pan Brioche Artesanal', 'Pan para hamburguesa con mantequilla y ajonjolí', 'unidades', 'unidades', 1200.0, 65, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (5, 'Papas a la Francesa Corte Grueso', 'Papas prefritas congeladas listas para freír', 'kg', 'kg', 8500.0, 42, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (6, 'Tomate Chonto Seleccionado', 'Tomate fresco para rodajas y ensaladas', 'kg', 'kg', 4200.0, 3, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (7, 'Lechuga Batavia Hidropónica', 'Lechuga fresca crujiente lavada y desinfectada', 'unidades', 'unidades', 3000.0, 11, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (8, 'Cebolla Morada de Huerto', 'Cebolla morada para caramelizar y ensaladas', 'kg', 'kg', 3800.0, 19, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (9, 'Tiras de Tocineta Ahumada', 'Tocineta ahumada en madera de manzano', 'kg', 'kg', 32000.0, 14, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (10, 'Salsa BBQ Ahumada Artesanal', 'Salsa BBQ receta secreta con miel y especias', 'litros', 'litros', 16000.0, 9, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (11, 'Costillas de Cerdo San Luis', 'Corte tierno de costilla marinada para asar', 'kg', 'kg', 34000.0, 22, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (12, 'Filete de Salmón Chileno', 'Porciones de salmón rosado congelado individual', 'kg', 'kg', 62000.0, 7, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (13, 'Bife de Chorizo Angus', 'Corte fino con marmoleo perfecto para parrilla', 'kg', 'kg', 54000.0, 18, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (14, 'Crema de Coco y Limón', 'Base para limonada de coco tradicional', 'litros', 'litros', 14000.0, 25, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (15, 'Café en Grano Premium RS', 'Café arábico de altura tostión media', 'kg', 'kg', 38000.0, 30, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (16, 'Cerveza Artesanal IPA Botella', 'Botella de cerveza rubia lupulada 330ml', 'unidades', 'unidades', 8000.0, 72, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (17, 'Queso Mascarpone Italiano', 'Queso suave para elaboración de tiramisú', 'kg', 'kg', 45000.0, 2, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (18, 'Cacao Puro en Polvo', 'Cacao amargo 100% para repostería y postres', 'kg', 'kg', 22000.0, 15, 1, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (19, 'Pasta Fettuccine al Huevo', 'Pasta fresca al huevo de trigo duro', 'kg', 'kg', 12000.0, 35, 2, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (20, 'Harina de Trigo Tipo 00', 'Harina italiana para masa de pizza napolitana', 'kg', 'kg', 9500.0, 80, 2, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (21, 'Salsa de Tomate San Marzano', 'Passata de tomate italiano con albahaca', 'litros', 'litros', 18000.0, 4, 2, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (22, 'Queso Mozzarella Fior di Latte', 'Queso mozzarella fresco para pizzas', 'kg', 'kg', 26000.0, 22, 2, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (23, 'Queso Parmigiano Reggiano D.O.P.', 'Parmesano curado 24 meses rallado', 'kg', 'kg', 75000.0, 6, 2, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (24, 'Aceite de Oliva Extra Virgen', 'Aceite primera prensada en frío', 'litros', 'litros', 42000.0, 16, 2, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (25, 'Hojas de Albahaca Fresca', 'Albahaca fresca de cultivo orgánico', 'paquetes', 'paquetes', 4000.0, 10, 2, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (26, 'Pepperoni Italiano Curado', 'Embutido rebanado con pimentón dulce', 'kg', 'kg', 36000.0, 13, 2, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (27, 'Crema de Leche Entera', 'Crema espesa 35% grasa para salsas', 'litros', 'litros', 11000.0, 24, 2, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (28, 'Champiñones Portobello', 'Hongos frescos para risottos y pastas', 'kg', 'kg', 19000.0, 3, 2, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (29, 'Tortillas de Maíz Nixtamalizado', 'Paquete x30 tortillas suaves de maíz', 'paquetes', 'paquetes', 7000.0, 50, 3, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (30, 'Carne de Cerdo Marinada al Pastor', 'Carne marinada en achiote con especias', 'kg', 'kg', 26000.0, 18, 3, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (31, 'Carne de Res para Birria', 'Sobrecostilla desmechada y cocinada a fuego lento', 'kg', 'kg', 32000.0, 8, 3, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (32, 'Aguacate Hass de Exportación', 'Aguacates en punto perfecto para guacamole', 'kg', 'kg', 11000.0, 3, 3, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (33, 'Queso Oaxaca / Quesillo', 'Queso hebra fundente tradicional', 'kg', 'kg', 23000.0, 20, 3, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (34, 'Chiles Jalapeños y Habaneros', 'Chiles frescos para salsas picantes', 'kg', 'kg', 8000.0, 14, 3, TRUE);
INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES (35, 'Tequila Blanco Reposado (Botella)', 'Botella 750ml para margaritas y cócteles', 'botellas', 'botellas', 85000.0, 12, 3, TRUE);

-- ============================================================================
-- 6. PLATILLOS (Catálogo / Menú)
-- ============================================================================
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (1, 'Hamburguesa Clásica Artesanal', 28000.0, '1 porción con papas', 1);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (2, 'Hamburguesa Doble RS Especial', 36000.0, 'Doble carne 300g', 1);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (3, 'Costillas BBQ Ahumadas (500g)', 48000.0, '500g con papas rústicas', 1);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (4, 'Salmón a la Plancha con Espárragos', 52000.0, 'Filete 250g con vegetales', 1);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (5, 'Bife de Chorizo Angus (350g)', 58000.0, 'Corte 350g término a elección', 1);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (6, 'Alitas BBQ Crispy (8 unidades)', 26000.0, '8 piezas con aderezo blue cheese', 1);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (7, 'Ensalada César con Pollo Grill', 24000.0, 'Pechuga grillada y parmesano', 1);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (8, 'Papas RS con Tocineta y Cheddar', 18000.0, 'Porción grande para compartir', 1);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (9, 'Tiramisú Clásico de la Casa', 16000.0, 'Porción individual', 1);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (10, 'Limonada de Coco Cremosita', 11000.0, 'Vaso 400ml', 1);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (11, 'Cerveza Artesanal IPA 330ml', 14000.0, 'Botella fría', 1);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (12, 'Café Espresso Doble', 6500.0, 'Taza 60ml', 1);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (13, 'Pizza Margarita Napolitana', 32000.0, 'Masa madre 30cm (8 porciones)', 2);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (14, 'Pizza Pepperoni Suprema', 38000.0, 'Masa madre con pepperoni y mozzarella', 2);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (15, 'Fettuccine Alfredo con Pollo', 34000.0, 'Pasta fresca en salsa blanca cremosa', 2);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (16, 'Lasagna Bolognese Tradicional', 36000.0, 'Capas de carne con salsa bechamel', 2);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (17, 'Risotto de Champiñones Portobello', 39000.0, 'Arroz arborio con vino blanco', 2);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (18, 'Bruschetta al Pomodoro e Basilico', 19000.0, '4 rebanadas de pan rústico', 2);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (19, 'Panna Cotta con Frutos Rojos', 15000.0, 'Postre frío italiano', 2);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (20, 'Tacos de Birria de Res (Trío)', 29000.0, '3 tacos con consomé caliente', 3);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (21, 'Tacos al Pastor con Piña (Trío)', 27000.0, '3 tacos en tortilla de maíz', 3);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (22, 'Quesadillas de Queso Oaxaca', 22000.0, '2 quesadillas con guacamole', 3);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (23, 'Nachos Supremos El Fuego', 31000.0, 'Totopos, queso fundido, frijoles y carne', 3);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (24, 'Margarita Tradicional al Tequila', 25000.0, 'Copa escarchada con sal', 3);
INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES (25, 'Churros Crujientes con Arequipe', 14000.0, '5 unidades azucaradas', 3);

-- ============================================================================
-- 7. PLATILLO_INGREDIENTES (Recetas e Insumos)
-- ============================================================================
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (1, 1, 1, 0.2);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (2, 1, 4, 1.0);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (3, 1, 3, 1.0);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (4, 1, 6, 0.05);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (5, 1, 7, 0.05);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (6, 1, 5, 0.15);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (7, 2, 1, 0.35);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (8, 2, 4, 1.0);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (9, 2, 3, 2.0);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (10, 2, 9, 0.05);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (11, 2, 5, 0.2);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (12, 3, 11, 0.5);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (13, 3, 10, 0.1);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (14, 3, 5, 0.2);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (15, 4, 12, 0.25);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (16, 5, 13, 0.35);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (17, 7, 2, 0.15);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (18, 7, 7, 0.1);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (19, 8, 5, 0.35);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (20, 8, 3, 2.0);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (21, 8, 9, 0.08);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (22, 9, 17, 0.1);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (23, 9, 18, 0.02);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (24, 10, 14, 0.2);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (25, 13, 20, 0.25);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (26, 13, 21, 0.1);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (27, 13, 22, 0.15);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (28, 13, 25, 0.02);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (29, 14, 20, 0.25);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (30, 14, 21, 0.1);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (31, 14, 22, 0.15);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (32, 14, 26, 0.08);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (33, 15, 19, 0.2);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (34, 15, 27, 0.1);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (35, 15, 23, 0.04);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (36, 15, 2, 0.12);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (37, 17, 28, 0.15);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (38, 17, 24, 0.03);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (39, 20, 29, 0.1);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (40, 20, 31, 0.2);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (41, 21, 29, 0.1);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (42, 21, 30, 0.2);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (43, 23, 33, 0.15);
INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES (44, 23, 32, 0.1);

-- ============================================================================
-- 8. PEDIDOS (Órdenes de clientes)
-- ============================================================================
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (1, 2, 'Andrés López', '2', '5', '2026-11-01 13:15:00', 96000.0, TRUE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (2, 5, 'Carlos Gómez', '5', '6', '2026-11-02 20:10:00', 184000.0, TRUE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (3, 7, 'Valentina Torres', '7', '7', '2026-11-03 14:00:00', 98000.0, TRUE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (4, 10, 'Sofía Morales', '10', '8', '2026-11-04 19:45:00', 171000.0, TRUE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (5, 3, 'Andrés López', '3', '5', '2026-11-05 13:30:00', 90000.0, TRUE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (6, 1, 'Marco Rossi', '15', '9', '2026-11-05 20:30:00', 119000.0, TRUE, 2);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (7, 3, 'Lucía Bellini', '17', '10', '2026-11-06 14:15:00', 104000.0, TRUE, 2);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (8, 1, 'Miguel Ángel Hernández', '25', '11', '2026-11-06 21:00:00', 139000.0, TRUE, 3);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (9, 1, 'Andrés López', '1', '5', '2026-11-07 13:45:00', 135000.0, TRUE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (10, 4, 'Carlos Gómez', '4', '6', '2026-11-07 20:00:00', 149000.0, TRUE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (11, 8, 'Valentina Torres', '8', '7', '2026-11-08 14:10:00', 126000.0, TRUE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (12, 12, 'Sofía Morales', '12', '8', '2026-11-08 20:45:00', 148000.0, TRUE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (13, 6, 'Marco Rossi', '20', '9', '2026-11-09 13:30:00', 97000.0, TRUE, 2);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (14, 3, 'Fernanda Ortiz', '27', '12', '2026-11-09 19:30:00', 131000.0, TRUE, 3);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (15, 6, 'Carlos Gómez', '6', '6', '2026-11-10 13:00:00', 113000.0, TRUE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (16, 9, 'Valentina Torres', '9', '7', '2026-11-10 20:15:00', 132000.0, TRUE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (17, 11, 'Sofía Morales', '11', '8', '2026-11-11 12:40:00', 86000.0, TRUE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (18, 14, 'Carlos Gómez', '14', '6', '2026-11-11 13:10:00', 144000.0, TRUE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (19, 2, 'Marco Rossi', '16', '9', '2026-11-11 13:20:00', 83000.0, TRUE, 2);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (20, 2, 'Miguel Ángel Hernández', '26', '11', '2026-11-11 13:40:00', 85000.0, TRUE, 3);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (21, 2, 'Andrés López', '2', '5', '2026-11-11 15:00:00', 102000.0, FALSE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (22, 3, 'Carlos Gómez', '3', '6', '2026-11-11 15:10:00', 96000.0, FALSE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (23, 5, 'Valentina Torres', '5', '7', '2026-11-11 14:50:00', 89000.0, FALSE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (24, 7, 'Sofía Morales', '7', '8', '2026-11-11 15:15:00', 108000.0, FALSE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (25, 10, 'Andrés López', '10', '5', '2026-11-11 15:20:00', 90000.0, FALSE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (26, 13, 'Carlos Gómez', '13', '6', '2026-11-11 15:25:00', 108000.0, FALSE, 1);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (27, 1, 'Marco Rossi', '15', '9', '2026-11-11 15:10:00', 72000.0, FALSE, 2);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (28, 3, 'Lucía Bellini', '17', '10', '2026-11-11 15:18:00', 91000.0, FALSE, 2);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (29, 1, 'Miguel Ángel Hernández', '25', '11', '2026-11-11 15:05:00', 81000.0, FALSE, 3);
INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES (30, 3, 'Fernanda Ortiz', '27', '12', '2026-11-11 15:22:00', 80000.0, FALSE, 3);

-- ============================================================================
-- 9. ITEMS_PEDIDO (Detalle de cada orden)
-- ============================================================================
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (1, 1, '1', 'Hamburguesa Clásica Artesanal', 28000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (2, 1, '8', 'Papas RS con Tocineta y Cheddar', 18000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (3, 1, '10', 'Limonada de Coco Cremosita', 11000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (4, 2, '3', 'Costillas BBQ Ahumadas (500g)', 48000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (5, 2, '11', 'Cerveza Artesanal IPA 330ml', 14000.0, '4', 4);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (6, 2, '9', 'Tiramisú Clásico de la Casa', 16000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (7, 3, '4', 'Salmón a la Plancha con Espárragos', 52000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (8, 3, '7', 'Ensalada César con Pollo Grill', 24000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (9, 3, '10', 'Limonada de Coco Cremosita', 11000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (10, 4, '5', 'Bife de Chorizo Angus (350g)', 58000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (11, 4, '11', 'Cerveza Artesanal IPA 330ml', 14000.0, '3', 3);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (12, 4, '12', 'Café Espresso Doble', 6500.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (13, 5, '2', 'Hamburguesa Doble RS Especial', 36000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (14, 5, '6', 'Alitas BBQ Crispy (8 unidades)', 26000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (15, 5, '11', 'Cerveza Artesanal IPA 330ml', 14000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (16, 6, '13', 'Pizza Margarita Napolitana', 32000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (17, 6, '14', 'Pizza Pepperoni Suprema', 38000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (18, 6, '18', 'Bruschetta al Pomodoro e Basilico', 19000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (19, 6, '19', 'Panna Cotta con Frutos Rojos', 15000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (20, 7, '15', 'Fettuccine Alfredo con Pollo', 34000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (21, 7, '16', 'Lasagna Bolognese Tradicional', 36000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (22, 8, '20', 'Tacos de Birria de Res (Trío)', 29000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (23, 8, '23', 'Nachos Supremos El Fuego', 31000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (24, 8, '24', 'Margarita Tradicional al Tequila', 25000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (25, 9, '1', 'Hamburguesa Clásica Artesanal', 28000.0, '3', 3);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (26, 9, '8', 'Papas RS con Tocineta y Cheddar', 18000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (27, 9, '10', 'Limonada de Coco Cremosita', 11000.0, '3', 3);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (28, 10, '4', 'Salmón a la Plancha con Espárragos', 52000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (29, 10, '9', 'Tiramisú Clásico de la Casa', 16000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (30, 10, '12', 'Café Espresso Doble', 6500.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (31, 11, '2', 'Hamburguesa Doble RS Especial', 36000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (32, 11, '6', 'Alitas BBQ Crispy (8 unidades)', 26000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (33, 11, '11', 'Cerveza Artesanal IPA 330ml', 14000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (34, 12, '5', 'Bife de Chorizo Angus (350g)', 58000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (35, 12, '3', 'Costillas BBQ Ahumadas (500g)', 48000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (36, 12, '11', 'Cerveza Artesanal IPA 330ml', 14000.0, '3', 3);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (37, 13, '17', 'Risotto de Champiñones Portobello', 39000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (38, 13, '18', 'Bruschetta al Pomodoro e Basilico', 19000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (39, 14, '21', 'Tacos al Pastor con Piña (Trío)', 27000.0, '3', 3);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (40, 14, '22', 'Quesadillas de Queso Oaxaca', 22000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (41, 14, '25', 'Churros Crujientes con Arequipe', 14000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (42, 15, '1', 'Hamburguesa Clásica Artesanal', 28000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (43, 15, '7', 'Ensalada César con Pollo Grill', 24000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (44, 15, '10', 'Limonada de Coco Cremosita', 11000.0, '3', 3);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (45, 16, '3', 'Costillas BBQ Ahumadas (500g)', 48000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (46, 16, '4', 'Salmón a la Plancha con Espárragos', 52000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (47, 16, '9', 'Tiramisú Clásico de la Casa', 16000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (48, 17, '1', 'Hamburguesa Clásica Artesanal', 28000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (49, 17, '2', 'Hamburguesa Doble RS Especial', 36000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (50, 17, '10', 'Limonada de Coco Cremosita', 11000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (51, 18, '5', 'Bife de Chorizo Angus (350g)', 58000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (52, 18, '11', 'Cerveza Artesanal IPA 330ml', 14000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (53, 19, '13', 'Pizza Margarita Napolitana', 32000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (54, 19, '18', 'Bruschetta al Pomodoro e Basilico', 19000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (55, 20, '20', 'Tacos de Birria de Res (Trío)', 29000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (56, 20, '21', 'Tacos al Pastor con Piña (Trío)', 27000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (57, 21, '1', 'Hamburguesa Clásica Artesanal', 28000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (58, 21, '8', 'Papas RS con Tocineta y Cheddar', 18000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (59, 21, '11', 'Cerveza Artesanal IPA 330ml', 14000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (60, 22, '3', 'Costillas BBQ Ahumadas (500g)', 48000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (61, 22, '6', 'Alitas BBQ Crispy (8 unidades)', 26000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (62, 22, '10', 'Limonada de Coco Cremosita', 11000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (63, 23, '4', 'Salmón a la Plancha con Espárragos', 52000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (64, 23, '7', 'Ensalada César con Pollo Grill', 24000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (65, 23, '12', 'Café Espresso Doble', 6500.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (66, 24, '5', 'Bife de Chorizo Angus (350g)', 58000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (67, 24, '1', 'Hamburguesa Clásica Artesanal', 28000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (68, 24, '10', 'Limonada de Coco Cremosita', 11000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (69, 25, '2', 'Hamburguesa Doble RS Especial', 36000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (70, 25, '8', 'Papas RS con Tocineta y Cheddar', 18000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (71, 26, '6', 'Alitas BBQ Crispy (8 unidades)', 26000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (72, 26, '11', 'Cerveza Artesanal IPA 330ml', 14000.0, '4', 4);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (73, 27, '14', 'Pizza Pepperoni Suprema', 38000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (74, 27, '15', 'Fettuccine Alfredo con Pollo', 34000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (75, 28, '16', 'Lasagna Bolognese Tradicional', 36000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (76, 28, '18', 'Bruschetta al Pomodoro e Basilico', 19000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (77, 29, '23', 'Nachos Supremos El Fuego', 31000.0, '1', 1);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (78, 29, '24', 'Margarita Tradicional al Tequila', 25000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (79, 30, '20', 'Tacos de Birria de Res (Trío)', 29000.0, '2', 2);
INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES (80, 30, '22', 'Quesadillas de Queso Oaxaca', 22000.0, '1', 1);

-- ============================================================================
-- 10. FACTURAS
-- ============================================================================
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (1, '1', '2', 'Andrés López', '2026-11-01 13:15:00', 96000.0, TRUE, 'PAGADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (2, '2', '5', 'Carlos Gómez', '2026-11-02 20:10:00', 184000.0, TRUE, 'PAGADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (3, '3', '7', 'Valentina Torres', '2026-11-03 14:00:00', 98000.0, TRUE, 'PAGADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (4, '4', '10', 'Sofía Morales', '2026-11-04 19:45:00', 171000.0, TRUE, 'PAGADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (5, '5', '3', 'Andrés López', '2026-11-05 13:30:00', 90000.0, TRUE, 'PAGADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (6, '6', '1', 'Marco Rossi', '2026-11-05 20:30:00', 119000.0, TRUE, 'PAGADA', 2);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (7, '7', '3', 'Lucía Bellini', '2026-11-06 14:15:00', 104000.0, TRUE, 'PAGADA', 2);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (8, '8', '1', 'Miguel Ángel Hernández', '2026-11-06 21:00:00', 139000.0, TRUE, 'PAGADA', 3);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (9, '9', '1', 'Andrés López', '2026-11-07 13:45:00', 135000.0, TRUE, 'PAGADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (10, '10', '4', 'Carlos Gómez', '2026-11-07 20:00:00', 149000.0, TRUE, 'PAGADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (11, '11', '8', 'Valentina Torres', '2026-11-08 14:10:00', 126000.0, TRUE, 'PAGADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (12, '12', '12', 'Sofía Morales', '2026-11-08 20:45:00', 148000.0, TRUE, 'PAGADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (13, '13', '6', 'Marco Rossi', '2026-11-09 13:30:00', 97000.0, TRUE, 'PAGADA', 2);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (14, '14', '3', 'Fernanda Ortiz', '2026-11-09 19:30:00', 131000.0, TRUE, 'PAGADA', 3);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (15, '15', '6', 'Carlos Gómez', '2026-11-10 13:00:00', 113000.0, TRUE, 'PAGADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (16, '16', '9', 'Valentina Torres', '2026-11-10 20:15:00', 132000.0, TRUE, 'PAGADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (17, '17', '11', 'Sofía Morales', '2026-11-11 12:40:00', 86000.0, TRUE, 'PAGADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (18, '18', '14', 'Carlos Gómez', '2026-11-11 13:10:00', 144000.0, TRUE, 'PAGADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (19, '19', '2', 'Marco Rossi', '2026-11-11 13:20:00', 83000.0, TRUE, 'PAGADA', 2);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (20, '20', '2', 'Miguel Ángel Hernández', '2026-11-11 13:40:00', 85000.0, TRUE, 'PAGADA', 3);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (21, '21', '2', 'Andrés López', '2026-11-11 15:00:00', 102000.0, FALSE, 'PENDIENTE', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (22, '22', '3', 'Carlos Gómez', '2026-11-11 15:10:00', 96000.0, FALSE, 'PENDIENTE', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (23, '23', '5', 'Valentina Torres', '2026-11-11 14:50:00', 89000.0, FALSE, 'APROBADA', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (24, '24', '7', 'Sofía Morales', '2026-11-11 15:15:00', 108000.0, FALSE, 'PENDIENTE', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (25, '25', '10', 'Andrés López', '2026-11-11 15:20:00', 90000.0, FALSE, 'PENDIENTE', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (26, '26', '13', 'Carlos Gómez', '2026-11-11 15:25:00', 108000.0, FALSE, 'PENDIENTE', 1);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (27, '27', '1', 'Marco Rossi', '2026-11-11 15:10:00', 72000.0, FALSE, 'PENDIENTE', 2);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (28, '28', '3', 'Lucía Bellini', '2026-11-11 15:18:00', 91000.0, FALSE, 'PENDIENTE', 2);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (29, '29', '1', 'Miguel Ángel Hernández', '2026-11-11 15:05:00', 81000.0, FALSE, 'PENDIENTE', 3);
INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES (30, '30', '3', 'Fernanda Ortiz', '2026-11-11 15:22:00', 80000.0, FALSE, 'PENDIENTE', 3);

-- ============================================================================
-- 11. FACTURA_ITEMS (Asociación factura - ítems consumidos)
-- ============================================================================
INSERT INTO factura_items (factura_id, item_id) VALUES (1, 1);
INSERT INTO factura_items (factura_id, item_id) VALUES (1, 2);
INSERT INTO factura_items (factura_id, item_id) VALUES (1, 3);
INSERT INTO factura_items (factura_id, item_id) VALUES (2, 4);
INSERT INTO factura_items (factura_id, item_id) VALUES (2, 5);
INSERT INTO factura_items (factura_id, item_id) VALUES (2, 6);
INSERT INTO factura_items (factura_id, item_id) VALUES (3, 7);
INSERT INTO factura_items (factura_id, item_id) VALUES (3, 8);
INSERT INTO factura_items (factura_id, item_id) VALUES (3, 9);
INSERT INTO factura_items (factura_id, item_id) VALUES (4, 10);
INSERT INTO factura_items (factura_id, item_id) VALUES (4, 11);
INSERT INTO factura_items (factura_id, item_id) VALUES (4, 12);
INSERT INTO factura_items (factura_id, item_id) VALUES (5, 13);
INSERT INTO factura_items (factura_id, item_id) VALUES (5, 14);
INSERT INTO factura_items (factura_id, item_id) VALUES (5, 15);
INSERT INTO factura_items (factura_id, item_id) VALUES (6, 16);
INSERT INTO factura_items (factura_id, item_id) VALUES (6, 17);
INSERT INTO factura_items (factura_id, item_id) VALUES (6, 18);
INSERT INTO factura_items (factura_id, item_id) VALUES (6, 19);
INSERT INTO factura_items (factura_id, item_id) VALUES (7, 20);
INSERT INTO factura_items (factura_id, item_id) VALUES (7, 21);
INSERT INTO factura_items (factura_id, item_id) VALUES (8, 22);
INSERT INTO factura_items (factura_id, item_id) VALUES (8, 23);
INSERT INTO factura_items (factura_id, item_id) VALUES (8, 24);
INSERT INTO factura_items (factura_id, item_id) VALUES (9, 25);
INSERT INTO factura_items (factura_id, item_id) VALUES (9, 26);
INSERT INTO factura_items (factura_id, item_id) VALUES (9, 27);
INSERT INTO factura_items (factura_id, item_id) VALUES (10, 28);
INSERT INTO factura_items (factura_id, item_id) VALUES (10, 29);
INSERT INTO factura_items (factura_id, item_id) VALUES (10, 30);
INSERT INTO factura_items (factura_id, item_id) VALUES (11, 31);
INSERT INTO factura_items (factura_id, item_id) VALUES (11, 32);
INSERT INTO factura_items (factura_id, item_id) VALUES (11, 33);
INSERT INTO factura_items (factura_id, item_id) VALUES (12, 34);
INSERT INTO factura_items (factura_id, item_id) VALUES (12, 35);
INSERT INTO factura_items (factura_id, item_id) VALUES (12, 36);
INSERT INTO factura_items (factura_id, item_id) VALUES (13, 37);
INSERT INTO factura_items (factura_id, item_id) VALUES (13, 38);
INSERT INTO factura_items (factura_id, item_id) VALUES (14, 39);
INSERT INTO factura_items (factura_id, item_id) VALUES (14, 40);
INSERT INTO factura_items (factura_id, item_id) VALUES (14, 41);
INSERT INTO factura_items (factura_id, item_id) VALUES (15, 42);
INSERT INTO factura_items (factura_id, item_id) VALUES (15, 43);
INSERT INTO factura_items (factura_id, item_id) VALUES (15, 44);
INSERT INTO factura_items (factura_id, item_id) VALUES (16, 45);
INSERT INTO factura_items (factura_id, item_id) VALUES (16, 46);
INSERT INTO factura_items (factura_id, item_id) VALUES (16, 47);
INSERT INTO factura_items (factura_id, item_id) VALUES (17, 48);
INSERT INTO factura_items (factura_id, item_id) VALUES (17, 49);
INSERT INTO factura_items (factura_id, item_id) VALUES (17, 50);
INSERT INTO factura_items (factura_id, item_id) VALUES (18, 51);
INSERT INTO factura_items (factura_id, item_id) VALUES (18, 52);
INSERT INTO factura_items (factura_id, item_id) VALUES (19, 53);
INSERT INTO factura_items (factura_id, item_id) VALUES (19, 54);
INSERT INTO factura_items (factura_id, item_id) VALUES (20, 55);
INSERT INTO factura_items (factura_id, item_id) VALUES (20, 56);
INSERT INTO factura_items (factura_id, item_id) VALUES (21, 57);
INSERT INTO factura_items (factura_id, item_id) VALUES (21, 58);
INSERT INTO factura_items (factura_id, item_id) VALUES (21, 59);
INSERT INTO factura_items (factura_id, item_id) VALUES (22, 60);
INSERT INTO factura_items (factura_id, item_id) VALUES (22, 61);
INSERT INTO factura_items (factura_id, item_id) VALUES (22, 62);
INSERT INTO factura_items (factura_id, item_id) VALUES (23, 63);
INSERT INTO factura_items (factura_id, item_id) VALUES (23, 64);
INSERT INTO factura_items (factura_id, item_id) VALUES (23, 65);
INSERT INTO factura_items (factura_id, item_id) VALUES (24, 66);
INSERT INTO factura_items (factura_id, item_id) VALUES (24, 67);
INSERT INTO factura_items (factura_id, item_id) VALUES (24, 68);
INSERT INTO factura_items (factura_id, item_id) VALUES (25, 69);
INSERT INTO factura_items (factura_id, item_id) VALUES (25, 70);
INSERT INTO factura_items (factura_id, item_id) VALUES (26, 71);
INSERT INTO factura_items (factura_id, item_id) VALUES (26, 72);
INSERT INTO factura_items (factura_id, item_id) VALUES (27, 73);
INSERT INTO factura_items (factura_id, item_id) VALUES (27, 74);
INSERT INTO factura_items (factura_id, item_id) VALUES (28, 75);
INSERT INTO factura_items (factura_id, item_id) VALUES (28, 76);
INSERT INTO factura_items (factura_id, item_id) VALUES (29, 77);
INSERT INTO factura_items (factura_id, item_id) VALUES (29, 78);
INSERT INTO factura_items (factura_id, item_id) VALUES (30, 79);
INSERT INTO factura_items (factura_id, item_id) VALUES (30, 80);

-- ============================================================================
-- 12. PAGOS (Transacciones y métodos de cobro)
-- ============================================================================
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (1, '1', 'TARJETA', 96000.0, '2026-11-01 13:15:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (2, '2', 'EFECTIVO', 184000.0, '2026-11-02 20:10:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (3, '3', 'TRANSFERENCIA', 98000.0, '2026-11-03 14:00:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (4, '4', 'TARJETA', 171000.0, '2026-11-04 19:45:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (5, '5', 'NEQUI', 90000.0, '2026-11-05 13:30:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (6, '6', 'TARJETA', 119000.0, '2026-11-05 20:30:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (7, '7', 'EFECTIVO', 104000.0, '2026-11-06 14:15:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (8, '8', 'DAVIPLATA', 139000.0, '2026-11-06 21:00:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (9, '9', 'TARJETA', 135000.0, '2026-11-07 13:45:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (10, '10', 'TRANSFERENCIA', 149000.0, '2026-11-07 20:00:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (11, '11', 'NEQUI', 126000.0, '2026-11-08 14:10:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (12, '12', 'TARJETA', 148000.0, '2026-11-08 20:45:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (13, '13', 'EFECTIVO', 97000.0, '2026-11-09 13:30:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (14, '14', 'NEQUI', 131000.0, '2026-11-09 19:30:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (15, '15', 'TARJETA', 113000.0, '2026-11-10 13:00:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (16, '16', 'TRANSFERENCIA', 132000.0, '2026-11-10 20:15:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (17, '17', 'EFECTIVO', 86000.0, '2026-11-11 12:40:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (18, '18', 'TARJETA', 144000.0, '2026-11-11 13:10:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (19, '19', 'TARJETA', 83000.0, '2026-11-11 13:20:00', TRUE);
INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES (20, '20', 'NEQUI', 85000.0, '2026-11-11 13:40:00', TRUE);

-- ============================================================================
-- 13. FOROS (Comentarios, novedades de turno y notas de equipo)
-- ============================================================================
INSERT INTO foros (id, fnombre, fcomentario, fecha) VALUES (1, 'Carlos Gómez (Mesero)', 'Turno mediodía: Excelente afluencia en terraza. Las mesas 2, 5 y 7 tuvieron alta rotación de hamburguesas.', '2026-11-05 16:30:00');
INSERT INTO foros (id, fnombre, fcomentario, fecha) VALUES (2, 'Chef Rodrigo (Cocina)', 'Recordatorio: Se debe revisar el stock de carne molida Angus antes del viernes. La demanda subió un 25%.', '2026-11-06 09:15:00');
INSERT INTO foros (id, fnombre, fcomentario, fecha) VALUES (3, 'Andrés López (Mesero)', 'Cliente de mesa 4 felicitó el término del Bife de Chorizo. Sugiere incluir opción de salsa chimichurri ahumada.', '2026-11-07 21:30:00');
INSERT INTO foros (id, fnombre, fcomentario, fecha) VALUES (4, 'Valentina Torres (Mesera)', 'Mesa 10 reporta que la Limonada de Coco es la mejor de la ciudad. Muy buena presentación hoy.', '2026-11-08 15:10:00');
INSERT INTO foros (id, fnombre, fcomentario, fecha) VALUES (5, 'Admin Central', 'El fin de semana tendremos evento corporativo en salón principal. Se reservan mesas 8 a 12.', '2026-11-09 11:00:00');
INSERT INTO foros (id, fnombre, fcomentario, fecha) VALUES (6, 'Sofía Morales (Mesera)', 'Se implementó con éxito el cobro móvil vía Nequi y Daviplata en mesas externas. Más rápido el cierre.', '2026-11-09 17:45:00');
INSERT INTO foros (id, fnombre, fcomentario, fecha) VALUES (7, 'Marco Rossi (Trattoria)', 'La masa madre de pizza napolitana quedó con fermentación perfecta de 48h. Gran respuesta de comensales.', '2026-11-10 14:00:00');
INSERT INTO foros (id, fnombre, fcomentario, fecha) VALUES (8, 'Lucía Bellini (Trattoria)', 'Clientes fascinados con el Tiramisú tradicional. Casi agotamos el queso mascarpone.', '2026-11-10 22:00:00');
INSERT INTO foros (id, fnombre, fcomentario, fecha) VALUES (9, 'Miguel Ángel (Cantina)', 'El consomé de birria caliente fue el más pedido en la noche fresca de ayer. Preparar más caldo base.', '2026-11-11 10:30:00');
INSERT INTO foros (id, fnombre, fcomentario, fecha) VALUES (10, 'Fernanda Ortiz (Cantina)', 'Revisar stock de aguacate Hass, el guacamole está saliendo en casi todas las órdenes.', '2026-11-11 11:45:00');
INSERT INTO foros (id, fnombre, fcomentario, fecha) VALUES (11, 'Super Admin Creador', 'Nueva actualización del sistema RSKitchen 5.0 con sincronización para app móvil Flutter desplegada.', '2026-11-11 12:00:00');
INSERT INTO foros (id, fnombre, fcomentario, fecha) VALUES (12, 'Carlos Gómez (Mesero)', 'Mesas del almuerzo cerradas con éxito. Servicio ágil y sin demoras en cocina.', '2026-11-11 14:40:00');

-- ============================================================================
-- ACTUALIZACIÓN DE SECUENCIAS (Para evitar colisiones de ID en PostgreSQL)
-- ============================================================================
SELECT setval(pg_get_serial_sequence('restaurants', 'id'), COALESCE(MAX(id), 1)) FROM restaurants;
SELECT setval(pg_get_serial_sequence('usuarios', 'id'), COALESCE(MAX(id), 1)) FROM usuarios;
SELECT setval(pg_get_serial_sequence('mesas', 'id'), COALESCE(MAX(id), 1)) FROM mesas;
SELECT setval(pg_get_serial_sequence('productos', 'id'), COALESCE(MAX(id), 1)) FROM productos;
SELECT setval(pg_get_serial_sequence('platillos', 'id'), COALESCE(MAX(id), 1)) FROM platillos;
SELECT setval(pg_get_serial_sequence('platillo_ingredientes', 'id'), COALESCE(MAX(id), 1)) FROM platillo_ingredientes;
SELECT setval(pg_get_serial_sequence('pedidos', 'id'), COALESCE(MAX(id), 1)) FROM pedidos;
SELECT setval(pg_get_serial_sequence('items_pedido', 'id'), COALESCE(MAX(id), 1)) FROM items_pedido;
SELECT setval(pg_get_serial_sequence('facturas', 'id'), COALESCE(MAX(id), 1)) FROM facturas;
SELECT setval(pg_get_serial_sequence('pagos', 'id'), COALESCE(MAX(id), 1)) FROM pagos;
SELECT setval(pg_get_serial_sequence('foros', 'id'), COALESCE(MAX(id), 1)) FROM foros;

-- Confirmación final
-- RSKitchen inicializado exitosamente en PostgreSQL.
