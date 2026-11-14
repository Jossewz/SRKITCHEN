# -*- coding: utf-8 -*-
"""
Script generador de datos SQL para RSKitchen (PostgreSQL & MySQL)
Asegura consistencia referencial, sumas matemáticas exactas en facturación,
stocks categorizados y contraseñas cifradas en BCrypt.
"""

import sys

# Hashes BCrypt reales generados por Spring Security BCryptPasswordEncoder
# creator123: $2a$10$kN7HYrArOD8NRVX.WvGHVeadi9qCXP/A9eRdaO50d25PoEpCRpY36
# admin123:   $2a$10$QlxD/wOLGYlm4JPChUeDYuN9QhIQljCF2/BAE959357nA0hu0GUq6
# mesero123:  $2a$10$s8gaHGKENN3c.twzIGd2aOod5QFzCywrCZhLu.YNVPkREY6kBMuLi

HASH_CREATOR = "$2a$10$kN7HYrArOD8NRVX.WvGHVeadi9qCXP/A9eRdaO50d25PoEpCRpY36"
HASH_ADMIN = "$2a$10$QlxD/wOLGYlm4JPChUeDYuN9QhIQljCF2/BAE959357nA0hu0GUq6"
HASH_MESERO = "$2a$10$s8gaHGKENN3c.twzIGd2aOod5QFzCywrCZhLu.YNVPkREY6kBMuLi"

# 1. RESTAURANTES
restaurants = [
    (1, "RSKitchen Gourmet Central", "contacto@rskitchen.com", HASH_ADMIN, True),
    (2, "La Trattoria Bella Italia", "info@trattoriabella.com", HASH_ADMIN, True),
    (3, "Tacos & Cantina El Fuego", "reservas@elfuego.com", HASH_ADMIN, True),
]

# 2. USUARIOS
users = [
    # (id, id_mesero, name, mail, password, rol, restaurant_id, activo)
    (1, None, "Super Administrador Creador", "creator@rskitchen.com", HASH_CREATOR, "ROLE_CREATOR", "NULL", True),
    (2, None, "Admin Central RSKitchen", "admin@rskitchen.com", HASH_ADMIN, "ROLE_ADMIN", 1, True),
    (3, None, "Admin Gianluigi Trattoria", "admin.trattoria@rskitchen.com", HASH_ADMIN, "ROLE_ADMIN", 2, True),
    (4, None, "Admin Mateo Cantina", "admin.elfuego@rskitchen.com", HASH_ADMIN, "ROLE_ADMIN", 3, True),
    # Meseros Restaurante 1
    (5, "M01", "Andrés López (Mesero)", "mesero@rskitchen.com", HASH_MESERO, "ROLE_MESERO", 1, True),
    (6, "M02", "Carlos Gómez (Mesero)", "carlos.mesero@rskitchen.com", HASH_MESERO, "ROLE_MESERO", 1, True),
    (7, "M03", "Valentina Torres (Mesera)", "valentina.mesero@rskitchen.com", HASH_MESERO, "ROLE_MESERO", 1, True),
    (8, "M04", "Sofía Morales (Mesera)", "sofia.mesero@rskitchen.com", HASH_MESERO, "ROLE_MESERO", 1, True),
    # Meseros Restaurante 2
    (9, "M05", "Marco Rossi (Cameriere)", "marco.mesero@rskitchen.com", HASH_MESERO, "ROLE_MESERO", 2, True),
    (10, "M06", "Lucía Bellini (Cameriera)", "lucia.mesero@rskitchen.com", HASH_MESERO, "ROLE_MESERO", 2, True),
    # Meseros Restaurante 3
    (11, "M07", "Miguel Ángel Hernández (Mesero)", "miguel.mesero@rskitchen.com", HASH_MESERO, "ROLE_MESERO", 3, True),
    (12, "M08", "Fernanda Ortiz (Mesera)", "fernanda.mesero@rskitchen.com", HASH_MESERO, "ROLE_MESERO", 3, True),
]

# 3. MESAS
# (id, num, ocupado, mesero_id, restaurant_id)
mesas = [
    # Restaurante 1 (Mesas 1 a 14)
    (1, 1, False, None, 1),
    (2, 2, True, "5", 1),   # Andrés
    (3, 3, True, "6", 1),   # Carlos
    (4, 4, False, None, 1),
    (5, 5, True, "7", 1),   # Valentina
    (6, 6, False, None, 1),
    (7, 7, True, "8", 1),   # Sofía
    (8, 8, False, None, 1),
    (9, 9, False, None, 1),
    (10, 10, True, "5", 1),
    (11, 11, False, None, 1),
    (12, 12, False, None, 1),
    (13, 13, True, "6", 1),
    (14, 14, False, None, 1),
    # Restaurante 2 (Mesas 1 a 10)
    (15, 1, True, "9", 2),  # Marco
    (16, 2, False, None, 2),
    (17, 3, True, "10", 2), # Lucía
    (18, 4, False, None, 2),
    (19, 5, False, None, 2),
    (20, 6, True, "9", 2),
    (21, 7, False, None, 2),
    (22, 8, False, None, 2),
    (23, 9, False, None, 2),
    (24, 10, False, None, 2),
    # Restaurante 3 (Mesas 1 a 6)
    (25, 1, True, "11", 3), # Miguel
    (26, 2, False, None, 3),
    (27, 3, True, "12", 3), # Fernanda
    (28, 4, False, None, 3),
    (29, 5, False, None, 3),
    (30, 6, False, None, 3),
]

# 4. PRODUCTOS (Insumos / Inventario)
# (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo)
productos = [
    # Restaurante 1 (Gourmet Central)
    (1, "Carne Molida Angus", "Corte magro 80/20 especial para hamburguesas", "kg", "kg", 24000.0, 4, 1, True), # Stock crítico (<5)
    (2, "Pechuga de Pollo Fresca", "Pechuga deshuesada y limpia de primera calidad", "kg", "kg", 18500.0, 28, 1, True),
    (3, "Queso Cheddar Madurado", "Queso cheddar en láminas para hamburguesas", "paquetes", "paquetes", 15000.0, 8, 1, True), # Stock bajo (<15)
    (4, "Pan Brioche Artesanal", "Pan para hamburguesa con mantequilla y ajonjolí", "unidades", "unidades", 1200.0, 65, 1, True),
    (5, "Papas a la Francesa Corte Grueso", "Papas prefritas congeladas listas para freír", "kg", "kg", 8500.0, 42, 1, True),
    (6, "Tomate Chonto Seleccionado", "Tomate fresco para rodajas y ensaladas", "kg", "kg", 4200.0, 3, 1, True), # Stock crítico (<5)
    (7, "Lechuga Batavia Hidropónica", "Lechuga fresca crujiente lavada y desinfectada", "unidades", "unidades", 3000.0, 11, 1, True), # Stock bajo (<15)
    (8, "Cebolla Morada de Huerto", "Cebolla morada para caramelizar y ensaladas", "kg", "kg", 3800.0, 19, 1, True),
    (9, "Tiras de Tocineta Ahumada", "Tocineta ahumada en madera de manzano", "kg", "kg", 32000.0, 14, 1, True), # Stock bajo (<15)
    (10, "Salsa BBQ Ahumada Artesanal", "Salsa BBQ receta secreta con miel y especias", "litros", "litros", 16000.0, 9, 1, True),
    (11, "Costillas de Cerdo San Luis", "Corte tierno de costilla marinada para asar", "kg", "kg", 34000.0, 22, 1, True),
    (12, "Filete de Salmón Chileno", "Porciones de salmón rosado congelado individual", "kg", "kg", 62000.0, 7, 1, True), # Stock bajo
    (13, "Bife de Chorizo Angus", "Corte fino con marmoleo perfecto para parrilla", "kg", "kg", 54000.0, 18, 1, True),
    (14, "Crema de Coco y Limón", "Base para limonada de coco tradicional", "litros", "litros", 14000.0, 25, 1, True),
    (15, "Café en Grano Premium RS", "Café arábico de altura tostión media", "kg", "kg", 38000.0, 30, 1, True),
    (16, "Cerveza Artesanal IPA Botella", "Botella de cerveza rubia lupulada 330ml", "unidades", "unidades", 8000.0, 72, 1, True),
    (17, "Queso Mascarpone Italiano", "Queso suave para elaboración de tiramisú", "kg", "kg", 45000.0, 2, 1, True), # Stock crítico (<5)
    (18, "Cacao Puro en Polvo", "Cacao amargo 100% para repostería y postres", "kg", "kg", 22000.0, 15, 1, True),

    # Restaurante 2 (La Trattoria Bella Italia)
    (19, "Pasta Fettuccine al Huevo", "Pasta fresca al huevo de trigo duro", "kg", "kg", 12000.0, 35, 2, True),
    (20, "Harina de Trigo Tipo 00", "Harina italiana para masa de pizza napolitana", "kg", "kg", 9500.0, 80, 2, True),
    (21, "Salsa de Tomate San Marzano", "Passata de tomate italiano con albahaca", "litros", "litros", 18000.0, 4, 2, True), # Stock crítico
    (22, "Queso Mozzarella Fior di Latte", "Queso mozzarella fresco para pizzas", "kg", "kg", 26000.0, 22, 2, True),
    (23, "Queso Parmigiano Reggiano D.O.P.", "Parmesano curado 24 meses rallado", "kg", "kg", 75000.0, 6, 2, True), # Stock bajo
    (24, "Aceite de Oliva Extra Virgen", "Aceite primera prensada en frío", "litros", "litros", 42000.0, 16, 2, True),
    (25, "Hojas de Albahaca Fresca", "Albahaca fresca de cultivo orgánico", "paquetes", "paquetes", 4000.0, 10, 2, True),
    (26, "Pepperoni Italiano Curado", "Embutido rebanado con pimentón dulce", "kg", "kg", 36000.0, 13, 2, True),
    (27, "Crema de Leche Entera", "Crema espesa 35% grasa para salsas", "litros", "litros", 11000.0, 24, 2, True),
    (28, "Champiñones Portobello", "Hongos frescos para risottos y pastas", "kg", "kg", 19000.0, 3, 2, True), # Stock crítico

    # Restaurante 3 (Tacos & Cantina El Fuego)
    (29, "Tortillas de Maíz Nixtamalizado", "Paquete x30 tortillas suaves de maíz", "paquetes", "paquetes", 7000.0, 50, 3, True),
    (30, "Carne de Cerdo Marinada al Pastor", "Carne marinada en achiote con especias", "kg", "kg", 26000.0, 18, 3, True),
    (31, "Carne de Res para Birria", "Sobrecostilla desmechada y cocinada a fuego lento", "kg", "kg", 32000.0, 8, 3, True), # Stock bajo
    (32, "Aguacate Hass de Exportación", "Aguacates en punto perfecto para guacamole", "kg", "kg", 11000.0, 3, 3, True), # Stock crítico
    (33, "Queso Oaxaca / Quesillo", "Queso hebra fundente tradicional", "kg", "kg", 23000.0, 20, 3, True),
    (34, "Chiles Jalapeños y Habaneros", "Chiles frescos para salsas picantes", "kg", "kg", 8000.0, 14, 3, True),
    (35, "Tequila Blanco Reposado (Botella)", "Botella 750ml para margaritas y cócteles", "botellas", "botellas", 85000.0, 12, 3, True),
]

# 5. PLATILLOS
# (id, name, price, cant, restaurant_id)
platillos = [
    # Restaurante 1 (Gourmet Central)
    (1, "Hamburguesa Clásica Artesanal", 28000.0, "1 porción con papas", 1),
    (2, "Hamburguesa Doble RS Especial", 36000.0, "Doble carne 300g", 1),
    (3, "Costillas BBQ Ahumadas (500g)", 48000.0, "500g con papas rústicas", 1),
    (4, "Salmón a la Plancha con Espárragos", 52000.0, "Filete 250g con vegetales", 1),
    (5, "Bife de Chorizo Angus (350g)", 58000.0, "Corte 350g término a elección", 1),
    (6, "Alitas BBQ Crispy (8 unidades)", 26000.0, "8 piezas con aderezo blue cheese", 1),
    (7, "Ensalada César con Pollo Grill", 24000.0, "Pechuga grillada y parmesano", 1),
    (8, "Papas RS con Tocineta y Cheddar", 18000.0, "Porción grande para compartir", 1),
    (9, "Tiramisú Clásico de la Casa", 16000.0, "Porción individual", 1),
    (10, "Limonada de Coco Cremosita", 11000.0, "Vaso 400ml", 1),
    (11, "Cerveza Artesanal IPA 330ml", 14000.0, "Botella fría", 1),
    (12, "Café Espresso Doble", 6500.0, "Taza 60ml", 1),

    # Restaurante 2 (La Trattoria Bella Italia)
    (13, "Pizza Margarita Napolitana", 32000.0, "Masa madre 30cm (8 porciones)", 2),
    (14, "Pizza Pepperoni Suprema", 38000.0, "Masa madre con pepperoni y mozzarella", 2),
    (15, "Fettuccine Alfredo con Pollo", 34000.0, "Pasta fresca en salsa blanca cremosa", 2),
    (16, "Lasagna Bolognese Tradicional", 36000.0, "Capas de carne con salsa bechamel", 2),
    (17, "Risotto de Champiñones Portobello", 39000.0, "Arroz arborio con vino blanco", 2),
    (18, "Bruschetta al Pomodoro e Basilico", 19000.0, "4 rebanadas de pan rústico", 2),
    (19, "Panna Cotta con Frutos Rojos", 15000.0, "Postre frío italiano", 2),

    # Restaurante 3 (Tacos & Cantina El Fuego)
    (20, "Tacos de Birria de Res (Trío)", 29000.0, "3 tacos con consomé caliente", 3),
    (21, "Tacos al Pastor con Piña (Trío)", 27000.0, "3 tacos en tortilla de maíz", 3),
    (22, "Quesadillas de Queso Oaxaca", 22000.0, "2 quesadillas con guacamole", 3),
    (23, "Nachos Supremos El Fuego", 31000.0, "Totopos, queso fundido, frijoles y carne", 3),
    (24, "Margarita Tradicional al Tequila", 25000.0, "Copa escarchada con sal", 3),
    (25, "Churros Crujientes con Arequipe", 14000.0, "5 unidades azucaradas", 3),
]

# 6. PLATILLO_INGREDIENTES (Recetas)
# (id, platillo_id, producto_id, cantidad)
platillo_ingredientes = [
    # Platillo 1: Hamburguesa Clásica Artesanal
    (1, 1, 1, 0.20),   # 200g Carne Molida
    (2, 1, 4, 1.0),    # 1 Pan Brioche
    (3, 1, 3, 1.0),    # 1 lámina Queso Cheddar
    (4, 1, 6, 0.05),   # 50g Tomate
    (5, 1, 7, 0.05),   # Lechuga
    (6, 1, 5, 0.15),   # 150g Papas

    # Platillo 2: Hamburguesa Doble RS
    (7, 2, 1, 0.35),   # 350g Carne
    (8, 2, 4, 1.0),    # 1 Pan Brioche
    (9, 2, 3, 2.0),    # 2 láminas Cheddar
    (10, 2, 9, 0.05),  # Tocineta
    (11, 2, 5, 0.20),  # Papas

    # Platillo 3: Costillas BBQ
    (12, 3, 11, 0.50), # 500g Costilla
    (13, 3, 10, 0.10), # Salsa BBQ
    (14, 3, 5, 0.20),  # Papas

    # Platillo 4: Salmón a la Plancha
    (15, 4, 12, 0.25), # 250g Salmón

    # Platillo 5: Bife de Chorizo
    (16, 5, 13, 0.35), # 350g Bife

    # Platillo 7: Ensalada César
    (17, 7, 2, 0.15),  # Pollo
    (18, 7, 7, 0.10),  # Lechuga

    # Platillo 8: Papas RS
    (19, 8, 5, 0.35),  # 350g Papas
    (20, 8, 3, 2.0),   # Queso
    (21, 8, 9, 0.08),  # Tocineta

    # Platillo 9: Tiramisú Clásico
    (22, 9, 17, 0.10), # Mascarpone
    (23, 9, 18, 0.02), # Cacao

    # Platillo 10: Limonada de Coco
    (24, 10, 14, 0.20), # Crema de coco

    # Platillo 13: Pizza Margarita
    (25, 13, 20, 0.25), # Harina 00
    (26, 13, 21, 0.10), # Tomate San Marzano
    (27, 13, 22, 0.15), # Mozzarella
    (28, 13, 25, 0.02), # Albahaca

    # Platillo 14: Pizza Pepperoni
    (29, 14, 20, 0.25), # Harina
    (30, 14, 21, 0.10), # Tomate
    (31, 14, 22, 0.15), # Mozzarella
    (32, 14, 26, 0.08), # Pepperoni

    # Platillo 15: Fettuccine Alfredo
    (33, 15, 19, 0.20), # Pasta Fettuccine
    (34, 15, 27, 0.10), # Crema de Leche
    (35, 15, 23, 0.04), # Parmigiano
    (36, 15, 2, 0.12),  # Pollo

    # Platillo 17: Risotto
    (37, 17, 28, 0.15), # Champiñones Portobello
    (38, 17, 24, 0.03), # Aceite oliva

    # Platillo 20: Tacos de Birria
    (39, 20, 29, 0.10), # Tortillas
    (40, 20, 31, 0.20), # Birria de Res

    # Platillo 21: Tacos al Pastor
    (41, 21, 29, 0.10), # Tortillas
    (42, 21, 30, 0.20), # Cerdo Pastor

    # Platillo 23: Nachos Supremos
    (43, 23, 33, 0.15), # Queso
    (44, 23, 32, 0.10), # Aguacate
]

# 7. PEDIDOS, ITEMS_PEDIDO, FACTURAS, PAGOS
# Generamos pedidos realistas distribuidos entre el 2026-11-01 y el 2026-11-11
# Con horarios de almuerzo (12:30 a 15:30) y cena (19:00 a 22:30)

pedidos_raw = [
    # Pedido 1: R1, Mesa 2, Andrés (M01), Pagado
    {
        "id": 1, "mesa_num": 2, "mesero_name": "Andrés López", "mesa_id": "2", "mesero_id": "5",
        "fecha": "2026-11-01 13:15:00", "pagado": True, "restaurant_id": 1,
        "items": [
            {"product_id": "1", "name": "Hamburguesa Clásica Artesanal", "price": 28000.0, "unidades": 2},
            {"product_id": "8", "name": "Papas RS con Tocineta y Cheddar", "price": 18000.0, "unidades": 1},
            {"product_id": "10", "name": "Limonada de Coco Cremosita", "price": 11000.0, "unidades": 2},
        ],
        "metodo_pago": "TARJETA"
    },
    # Pedido 2: R1, Mesa 5, Carlos (M02), Pagado
    {
        "id": 2, "mesa_num": 5, "mesero_name": "Carlos Gómez", "mesa_id": "5", "mesero_id": "6",
        "fecha": "2026-11-02 20:10:00", "pagado": True, "restaurant_id": 1,
        "items": [
            {"product_id": "3", "name": "Costillas BBQ Ahumadas (500g)", "price": 48000.0, "unidades": 2},
            {"product_id": "11", "name": "Cerveza Artesanal IPA 330ml", "price": 14000.0, "unidades": 4},
            {"product_id": "9", "name": "Tiramisú Clásico de la Casa", "price": 16000.0, "unidades": 2},
        ],
        "metodo_pago": "EFECTIVO"
    },
    # Pedido 3: R1, Mesa 7, Valentina (M03), Pagado
    {
        "id": 3, "mesa_num": 7, "mesero_name": "Valentina Torres", "mesa_id": "7", "mesero_id": "7",
        "fecha": "2026-11-03 14:00:00", "pagado": True, "restaurant_id": 1,
        "items": [
            {"product_id": "4", "name": "Salmón a la Plancha con Espárragos", "price": 52000.0, "unidades": 1},
            {"product_id": "7", "name": "Ensalada César con Pollo Grill", "price": 24000.0, "unidades": 1},
            {"product_id": "10", "name": "Limonada de Coco Cremosita", "price": 11000.0, "unidades": 2},
        ],
        "metodo_pago": "TRANSFERENCIA"
    },
    # Pedido 4: R1, Mesa 10, Sofía (M04), Pagado
    {
        "id": 4, "mesa_num": 10, "mesero_name": "Sofía Morales", "mesa_id": "10", "mesero_id": "8",
        "fecha": "2026-11-04 19:45:00", "pagado": True, "restaurant_id": 1,
        "items": [
            {"product_id": "5", "name": "Bife de Chorizo Angus (350g)", "price": 58000.0, "unidades": 2},
            {"product_id": "11", "name": "Cerveza Artesanal IPA 330ml", "price": 14000.0, "unidades": 3},
            {"product_id": "12", "name": "Café Espresso Doble", "price": 6500.0, "unidades": 2},
        ],
        "metodo_pago": "TARJETA"
    },
    # Pedido 5: R1, Mesa 3, Andrés (M01), Pagado
    {
        "id": 5, "mesa_num": 3, "mesero_name": "Andrés López", "mesa_id": "3", "mesero_id": "5",
        "fecha": "2026-11-05 13:30:00", "pagado": True, "restaurant_id": 1,
        "items": [
            {"product_id": "2", "name": "Hamburguesa Doble RS Especial", "price": 36000.0, "unidades": 1},
            {"product_id": "6", "name": "Alitas BBQ Crispy (8 unidades)", "price": 26000.0, "unidades": 1},
            {"product_id": "11", "name": "Cerveza Artesanal IPA 330ml", "price": 14000.0, "unidades": 2},
        ],
        "metodo_pago": "NEQUI"
    },
    # Pedido 6: R2, Mesa 1, Marco (M05), Pagado
    {
        "id": 6, "mesa_num": 1, "mesero_name": "Marco Rossi", "mesa_id": "15", "mesero_id": "9",
        "fecha": "2026-11-05 20:30:00", "pagado": True, "restaurant_id": 2,
        "items": [
            {"product_id": "13", "name": "Pizza Margarita Napolitana", "price": 32000.0, "unidades": 1},
            {"product_id": "14", "name": "Pizza Pepperoni Suprema", "price": 38000.0, "unidades": 1},
            {"product_id": "18", "name": "Bruschetta al Pomodoro e Basilico", "price": 19000.0, "unidades": 1},
            {"product_id": "19", "name": "Panna Cotta con Frutos Rojos", "price": 15000.0, "unidades": 2},
        ],
        "metodo_pago": "TARJETA"
    },
    # Pedido 7: R2, Mesa 3, Lucía (M06), Pagado
    {
        "id": 7, "mesa_num": 3, "mesero_name": "Lucía Bellini", "mesa_id": "17", "mesero_id": "10",
        "fecha": "2026-11-06 14:15:00", "pagado": True, "restaurant_id": 2,
        "items": [
            {"product_id": "15", "name": "Fettuccine Alfredo con Pollo", "price": 34000.0, "unidades": 2},
            {"product_id": "16", "name": "Lasagna Bolognese Tradicional", "price": 36000.0, "unidades": 1},
        ],
        "metodo_pago": "EFECTIVO"
    },
    # Pedido 8: R3, Mesa 1, Miguel (M07), Pagado
    {
        "id": 8, "mesa_num": 1, "mesero_name": "Miguel Ángel Hernández", "mesa_id": "25", "mesero_id": "11",
        "fecha": "2026-11-06 21:00:00", "pagado": True, "restaurant_id": 3,
        "items": [
            {"product_id": "20", "name": "Tacos de Birria de Res (Trío)", "price": 29000.0, "unidades": 2},
            {"product_id": "23", "name": "Nachos Supremos El Fuego", "price": 31000.0, "unidades": 1},
            {"product_id": "24", "name": "Margarita Tradicional al Tequila", "price": 25000.0, "unidades": 2},
        ],
        "metodo_pago": "DAVIPLATA"
    },
    # Pedido 9: R1, Mesa 1, Andrés (M01), Pagado
    {
        "id": 9, "mesa_num": 1, "mesero_name": "Andrés López", "mesa_id": "1", "mesero_id": "5",
        "fecha": "2026-11-07 13:45:00", "pagado": True, "restaurant_id": 1,
        "items": [
            {"product_id": "1", "name": "Hamburguesa Clásica Artesanal", "price": 28000.0, "unidades": 3},
            {"product_id": "8", "name": "Papas RS con Tocineta y Cheddar", "price": 18000.0, "unidades": 1},
            {"product_id": "10", "name": "Limonada de Coco Cremosita", "price": 11000.0, "unidades": 3},
        ],
        "metodo_pago": "TARJETA"
    },
    # Pedido 10: R1, Mesa 4, Carlos (M02), Pagado
    {
        "id": 10, "mesa_num": 4, "mesero_name": "Carlos Gómez", "mesa_id": "4", "mesero_id": "6",
        "fecha": "2026-11-07 20:00:00", "pagado": True, "restaurant_id": 1,
        "items": [
            {"product_id": "4", "name": "Salmón a la Plancha con Espárragos", "price": 52000.0, "unidades": 2},
            {"product_id": "9", "name": "Tiramisú Clásico de la Casa", "price": 16000.0, "unidades": 2},
            {"product_id": "12", "name": "Café Espresso Doble", "price": 6500.0, "unidades": 2},
        ],
        "metodo_pago": "TRANSFERENCIA"
    },
    # Pedido 11: R1, Mesa 8, Valentina (M03), Pagado
    {
        "id": 11, "mesa_num": 8, "mesero_name": "Valentina Torres", "mesa_id": "8", "mesero_id": "7",
        "fecha": "2026-11-08 14:10:00", "pagado": True, "restaurant_id": 1,
        "items": [
            {"product_id": "2", "name": "Hamburguesa Doble RS Especial", "price": 36000.0, "unidades": 2},
            {"product_id": "6", "name": "Alitas BBQ Crispy (8 unidades)", "price": 26000.0, "unidades": 1},
            {"product_id": "11", "name": "Cerveza Artesanal IPA 330ml", "price": 14000.0, "unidades": 2},
        ],
        "metodo_pago": "NEQUI"
    },
    # Pedido 12: R1, Mesa 12, Sofía (M04), Pagado
    {
        "id": 12, "mesa_num": 12, "mesero_name": "Sofía Morales", "mesa_id": "12", "mesero_id": "8",
        "fecha": "2026-11-08 20:45:00", "pagado": True, "restaurant_id": 1,
        "items": [
            {"product_id": "5", "name": "Bife de Chorizo Angus (350g)", "price": 58000.0, "unidades": 1},
            {"product_id": "3", "name": "Costillas BBQ Ahumadas (500g)", "price": 48000.0, "unidades": 1},
            {"product_id": "11", "name": "Cerveza Artesanal IPA 330ml", "price": 14000.0, "unidades": 3},
        ],
        "metodo_pago": "TARJETA"
    },
    # Pedido 13: R2, Mesa 6, Marco (M05), Pagado
    {
        "id": 13, "mesa_num": 6, "mesero_name": "Marco Rossi", "mesa_id": "20", "mesero_id": "9",
        "fecha": "2026-11-09 13:30:00", "pagado": True, "restaurant_id": 2,
        "items": [
            {"product_id": "17", "name": "Risotto de Champiñones Portobello", "price": 39000.0, "unidades": 2},
            {"product_id": "18", "name": "Bruschetta al Pomodoro e Basilico", "price": 19000.0, "unidades": 1},
        ],
        "metodo_pago": "EFECTIVO"
    },
    # Pedido 14: R3, Mesa 3, Fernanda (M08), Pagado
    {
        "id": 14, "mesa_num": 3, "mesero_name": "Fernanda Ortiz", "mesa_id": "27", "mesero_id": "12",
        "fecha": "2026-11-09 19:30:00", "pagado": True, "restaurant_id": 3,
        "items": [
            {"product_id": "21", "name": "Tacos al Pastor con Piña (Trío)", "price": 27000.0, "unidades": 3},
            {"product_id": "22", "name": "Quesadillas de Queso Oaxaca", "price": 22000.0, "unidades": 1},
            {"product_id": "25", "name": "Churros Crujientes con Arequipe", "price": 14000.0, "unidades": 2},
        ],
        "metodo_pago": "NEQUI"
    },
    # Pedido 15: R1, Mesa 6, Carlos (M02), Pagado
    {
        "id": 15, "mesa_num": 6, "mesero_name": "Carlos Gómez", "mesa_id": "6", "mesero_id": "6",
        "fecha": "2026-11-10 13:00:00", "pagado": True, "restaurant_id": 1,
        "items": [
            {"product_id": "1", "name": "Hamburguesa Clásica Artesanal", "price": 28000.0, "unidades": 2},
            {"product_id": "7", "name": "Ensalada César con Pollo Grill", "price": 24000.0, "unidades": 1},
            {"product_id": "10", "name": "Limonada de Coco Cremosita", "price": 11000.0, "unidades": 3},
        ],
        "metodo_pago": "TARJETA"
    },
    # Pedido 16: R1, Mesa 9, Valentina (M03), Pagado
    {
        "id": 16, "mesa_num": 9, "mesero_name": "Valentina Torres", "mesa_id": "9", "mesero_id": "7",
        "fecha": "2026-11-10 20:15:00", "pagado": True, "restaurant_id": 1,
        "items": [
            {"product_id": "3", "name": "Costillas BBQ Ahumadas (500g)", "price": 48000.0, "unidades": 1},
            {"product_id": "4", "name": "Salmón a la Plancha con Espárragos", "price": 52000.0, "unidades": 1},
            {"product_id": "9", "name": "Tiramisú Clásico de la Casa", "price": 16000.0, "unidades": 2},
        ],
        "metodo_pago": "TRANSFERENCIA"
    },
    # --- PEDIDOS DE HOY (2026-11-11) ---
    # Pedido 17: R1, Mesa 11, Sofía (M04), Pagado (Almuerzo de hoy)
    {
        "id": 17, "mesa_num": 11, "mesero_name": "Sofía Morales", "mesa_id": "11", "mesero_id": "8",
        "fecha": "2026-11-11 12:40:00", "pagado": True, "restaurant_id": 1,
        "items": [
            {"product_id": "1", "name": "Hamburguesa Clásica Artesanal", "price": 28000.0, "unidades": 1},
            {"product_id": "2", "name": "Hamburguesa Doble RS Especial", "price": 36000.0, "unidades": 1},
            {"product_id": "10", "name": "Limonada de Coco Cremosita", "price": 11000.0, "unidades": 2},
        ],
        "metodo_pago": "EFECTIVO"
    },
    # Pedido 18: R1, Mesa 14, Carlos (M02), Pagado (Almuerzo de hoy)
    {
        "id": 18, "mesa_num": 14, "mesero_name": "Carlos Gómez", "mesa_id": "14", "mesero_id": "6",
        "fecha": "2026-11-11 13:10:00", "pagado": True, "restaurant_id": 1,
        "items": [
            {"product_id": "5", "name": "Bife de Chorizo Angus (350g)", "price": 58000.0, "unidades": 2},
            {"product_id": "11", "name": "Cerveza Artesanal IPA 330ml", "price": 14000.0, "unidades": 2},
        ],
        "metodo_pago": "TARJETA"
    },
    # Pedido 19: R2, Mesa 2, Marco (M05), Pagado (Almuerzo de hoy)
    {
        "id": 19, "mesa_num": 2, "mesero_name": "Marco Rossi", "mesa_id": "16", "mesero_id": "9",
        "fecha": "2026-11-11 13:20:00", "pagado": True, "restaurant_id": 2,
        "items": [
            {"product_id": "13", "name": "Pizza Margarita Napolitana", "price": 32000.0, "unidades": 2},
            {"product_id": "18", "name": "Bruschetta al Pomodoro e Basilico", "price": 19000.0, "unidades": 1},
        ],
        "metodo_pago": "TARJETA"
    },
    # Pedido 20: R3, Mesa 2, Miguel (M07), Pagado (Almuerzo de hoy)
    {
        "id": 20, "mesa_num": 2, "mesero_name": "Miguel Ángel Hernández", "mesa_id": "26", "mesero_id": "11",
        "fecha": "2026-11-11 13:40:00", "pagado": True, "restaurant_id": 3,
        "items": [
            {"product_id": "20", "name": "Tacos de Birria de Res (Trío)", "price": 29000.0, "unidades": 2},
            {"product_id": "21", "name": "Tacos al Pastor con Piña (Trío)", "price": 27000.0, "unidades": 1},
        ],
        "metodo_pago": "NEQUI"
    },

    # --- PEDIDOS ACTIVOS EN MESAS OCUPADAS (En curso - Pendientes de pago) ---
    # Pedido 21: R1, Mesa 2 (Ocupada por Andrés M01) - PENDIENTE
    {
        "id": 21, "mesa_num": 2, "mesero_name": "Andrés López", "mesa_id": "2", "mesero_id": "5",
        "fecha": "2026-11-11 15:00:00", "pagado": False, "restaurant_id": 1,
        "items": [
            {"product_id": "1", "name": "Hamburguesa Clásica Artesanal", "price": 28000.0, "unidades": 2},
            {"product_id": "8", "name": "Papas RS con Tocineta y Cheddar", "price": 18000.0, "unidades": 1},
            {"product_id": "11", "name": "Cerveza Artesanal IPA 330ml", "price": 14000.0, "unidades": 2},
        ],
        "estado_factura": "PENDIENTE",
        "metodo_pago": None
    },
    # Pedido 22: R1, Mesa 3 (Ocupada por Carlos M02) - PENDIENTE
    {
        "id": 22, "mesa_num": 3, "mesero_name": "Carlos Gómez", "mesa_id": "3", "mesero_id": "6",
        "fecha": "2026-11-11 15:10:00", "pagado": False, "restaurant_id": 1,
        "items": [
            {"product_id": "3", "name": "Costillas BBQ Ahumadas (500g)", "price": 48000.0, "unidades": 1},
            {"product_id": "6", "name": "Alitas BBQ Crispy (8 unidades)", "price": 26000.0, "unidades": 1},
            {"product_id": "10", "name": "Limonada de Coco Cremosita", "price": 11000.0, "unidades": 2},
        ],
        "estado_factura": "PENDIENTE",
        "metodo_pago": None
    },
    # Pedido 23: R1, Mesa 5 (Ocupada por Valentina M03) - APROBADA (Esperando cobro)
    {
        "id": 23, "mesa_num": 5, "mesero_name": "Valentina Torres", "mesa_id": "5", "mesero_id": "7",
        "fecha": "2026-11-11 14:50:00", "pagado": False, "restaurant_id": 1,
        "items": [
            {"product_id": "4", "name": "Salmón a la Plancha con Espárragos", "price": 52000.0, "unidades": 1},
            {"product_id": "7", "name": "Ensalada César con Pollo Grill", "price": 24000.0, "unidades": 1},
            {"product_id": "12", "name": "Café Espresso Doble", "price": 6500.0, "unidades": 2},
        ],
        "estado_factura": "APROBADA",
        "metodo_pago": None
    },
    # Pedido 24: R1, Mesa 7 (Ocupada por Sofía M04) - PENDIENTE
    {
        "id": 24, "mesa_num": 7, "mesero_name": "Sofía Morales", "mesa_id": "7", "mesero_id": "8",
        "fecha": "2026-11-11 15:15:00", "pagado": False, "restaurant_id": 1,
        "items": [
            {"product_id": "5", "name": "Bife de Chorizo Angus (350g)", "price": 58000.0, "unidades": 1},
            {"product_id": "1", "name": "Hamburguesa Clásica Artesanal", "price": 28000.0, "unidades": 1},
            {"product_id": "10", "name": "Limonada de Coco Cremosita", "price": 11000.0, "unidades": 2},
        ],
        "estado_factura": "PENDIENTE",
        "metodo_pago": None
    },
    # Pedido 25: R1, Mesa 10 (Ocupada por Andrés M01) - PENDIENTE
    {
        "id": 25, "mesa_num": 10, "mesero_name": "Andrés López", "mesa_id": "10", "mesero_id": "5",
        "fecha": "2026-11-11 15:20:00", "pagado": False, "restaurant_id": 1,
        "items": [
            {"product_id": "2", "name": "Hamburguesa Doble RS Especial", "price": 36000.0, "unidades": 2},
            {"product_id": "8", "name": "Papas RS con Tocineta y Cheddar", "price": 18000.0, "unidades": 1},
        ],
        "estado_factura": "PENDIENTE",
        "metodo_pago": None
    },
    # Pedido 26: R1, Mesa 13 (Ocupada por Carlos M02) - PENDIENTE
    {
        "id": 26, "mesa_num": 13, "mesero_name": "Carlos Gómez", "mesa_id": "13", "mesero_id": "6",
        "fecha": "2026-11-11 15:25:00", "pagado": False, "restaurant_id": 1,
        "items": [
            {"product_id": "6", "name": "Alitas BBQ Crispy (8 unidades)", "price": 26000.0, "unidades": 2},
            {"product_id": "11", "name": "Cerveza Artesanal IPA 330ml", "price": 14000.0, "unidades": 4},
        ],
        "estado_factura": "PENDIENTE",
        "metodo_pago": None
    },
    # Pedido 27: R2, Mesa 1 (Ocupada por Marco M05) - PENDIENTE
    {
        "id": 27, "mesa_num": 1, "mesero_name": "Marco Rossi", "mesa_id": "15", "mesero_id": "9",
        "fecha": "2026-11-11 15:10:00", "pagado": False, "restaurant_id": 2,
        "items": [
            {"product_id": "14", "name": "Pizza Pepperoni Suprema", "price": 38000.0, "unidades": 1},
            {"product_id": "15", "name": "Fettuccine Alfredo con Pollo", "price": 34000.0, "unidades": 1},
        ],
        "estado_factura": "PENDIENTE",
        "metodo_pago": None
    },
    # Pedido 28: R2, Mesa 3 (Ocupada por Lucía M06) - PENDIENTE
    {
        "id": 28, "mesa_num": 3, "mesero_name": "Lucía Bellini", "mesa_id": "17", "mesero_id": "10",
        "fecha": "2026-11-11 15:18:00", "pagado": False, "restaurant_id": 2,
        "items": [
            {"product_id": "16", "name": "Lasagna Bolognese Tradicional", "price": 36000.0, "unidades": 2},
            {"product_id": "18", "name": "Bruschetta al Pomodoro e Basilico", "price": 19000.0, "unidades": 1},
        ],
        "estado_factura": "PENDIENTE",
        "metodo_pago": None
    },
    # Pedido 29: R3, Mesa 1 (Ocupada por Miguel M07) - PENDIENTE
    {
        "id": 29, "mesa_num": 1, "mesero_name": "Miguel Ángel Hernández", "mesa_id": "25", "mesero_id": "11",
        "fecha": "2026-11-11 15:05:00", "pagado": False, "restaurant_id": 3,
        "items": [
            {"product_id": "23", "name": "Nachos Supremos El Fuego", "price": 31000.0, "unidades": 1},
            {"product_id": "24", "name": "Margarita Tradicional al Tequila", "price": 25000.0, "unidades": 2},
        ],
        "estado_factura": "PENDIENTE",
        "metodo_pago": None
    },
    # Pedido 30: R3, Mesa 3 (Ocupada por Fernanda M08) - PENDIENTE
    {
        "id": 30, "mesa_num": 3, "mesero_name": "Fernanda Ortiz", "mesa_id": "27", "mesero_id": "12",
        "fecha": "2026-11-11 15:22:00", "pagado": False, "restaurant_id": 3,
        "items": [
            {"product_id": "20", "name": "Tacos de Birria de Res (Trío)", "price": 29000.0, "unidades": 2},
            {"product_id": "22", "name": "Quesadillas de Queso Oaxaca", "price": 22000.0, "unidades": 1},
        ],
        "estado_factura": "PENDIENTE",
        "metodo_pago": None
    },
]

# 8. FORO / COMENTARIOS DEL EQUIPO Y CLIENTES
foros = [
    (1, "Carlos Gómez (Mesero)", "Turno mediodía: Excelente afluencia en terraza. Las mesas 2, 5 y 7 tuvieron alta rotación de hamburguesas.", "2026-11-05 16:30:00"),
    (2, "Chef Rodrigo (Cocina)", "Recordatorio: Se debe revisar el stock de carne molida Angus antes del viernes. La demanda subió un 25%.", "2026-11-06 09:15:00"),
    (3, "Andrés López (Mesero)", "Cliente de mesa 4 felicitó el término del Bife de Chorizo. Sugiere incluir opción de salsa chimichurri ahumada.", "2026-11-07 21:30:00"),
    (4, "Valentina Torres (Mesera)", "Mesa 10 reporta que la Limonada de Coco es la mejor de la ciudad. Muy buena presentación hoy.", "2026-11-08 15:10:00"),
    (5, "Admin Central", "El fin de semana tendremos evento corporativo en salón principal. Se reservan mesas 8 a 12.", "2026-11-09 11:00:00"),
    (6, "Sofía Morales (Mesera)", "Se implementó con éxito el cobro móvil vía Nequi y Daviplata en mesas externas. Más rápido el cierre.", "2026-11-09 17:45:00"),
    (7, "Marco Rossi (Trattoria)", "La masa madre de pizza napolitana quedó con fermentación perfecta de 48h. Gran respuesta de comensales.", "2026-11-10 14:00:00"),
    (8, "Lucía Bellini (Trattoria)", "Clientes fascinados con el Tiramisú tradicional. Casi agotamos el queso mascarpone.", "2026-11-10 22:00:00"),
    (9, "Miguel Ángel (Cantina)", "El consomé de birria caliente fue el más pedido en la noche fresca de ayer. Preparar más caldo base.", "2026-11-11 10:30:00"),
    (10, "Fernanda Ortiz (Cantina)", "Revisar stock de aguacate Hass, el guacamole está saliendo en casi todas las órdenes.", "2026-11-11 11:45:00"),
    (11, "Super Admin Creador", "Nueva actualización del sistema RSKitchen 5.0 con sincronización para app móvil Flutter desplegada.", "2026-11-11 12:00:00"),
    (12, "Carlos Gómez (Mesero)", "Mesas del almuerzo cerradas con éxito. Servicio ágil y sin demoras en cocina.", "2026-11-11 14:40:00"),
]

# Procesar pedidos, calcular totales y armar items_pedido, facturas, factura_items, mesa_pedidos y pagos
processed_pedidos = []
items_pedido = []
facturas = []
factura_items = []
mesa_pedidos = []
pagos = []

item_id_counter = 1
factura_id_counter = 1
pago_id_counter = 1

for p in pedidos_raw:
    pid = p["id"]
    p_total = 0.0
    p_item_ids = []
    
    for item in p["items"]:
        subtotal = item["price"] * item["unidades"]
        p_total += subtotal
        items_pedido.append((
            item_id_counter,
            pid,
            item["product_id"],
            item["name"],
            item["price"],
            str(item["unidades"]),
            item["unidades"]
        ))
        p_item_ids.append(item_id_counter)
        item_id_counter += 1
        
    p["total"] = p_total
    processed_pedidos.append((
        pid,
        p["mesa_num"],
        p["mesero_name"],
        p["mesa_id"],
        p["mesero_id"],
        p["fecha"],
        p_total,
        p["pagado"],
        p["restaurant_id"]
    ))
    
    # Mesa pedidos mapping
    mesa_pedidos.append((int(p["mesa_id"]), str(pid)))
    
    # Factura
    estado_factura = "PAGADA" if p["pagado"] else p.get("estado_factura", "PENDIENTE")
    fid = factura_id_counter
    factura_id_counter += 1
    
    facturas.append((
        fid,
        str(pid),
        str(p["mesa_num"]),
        p["mesero_name"],
        p["fecha"],
        p_total,
        p["pagado"],
        estado_factura,
        p["restaurant_id"]
    ))
    
    for iid in p_item_ids:
        factura_items.append((fid, iid))
        
    # Pago (si está pagado)
    if p["pagado"] and p.get("metodo_pago"):
        pagos.append((
            pago_id_counter,
            str(fid),
            p["metodo_pago"],
            p_total,
            p["fecha"],
            True
        ))
        pago_id_counter += 1

def escape_str(s):
    if s is None:
        return "NULL"
    return "'" + str(s).replace("'", "''") + "'"

def bool_val(b, dialect="pg"):
    if dialect == "pg":
        return "TRUE" if b else "FALSE"
    return "1" if b else "0"

def generate_dml(dialect="pg"):
    lines = []
    
    # 1. Restaurants
    lines.append("-- ============================================================================")
    lines.append("-- 1. RESTAURANTES (Multi-tenant)")
    lines.append("-- ============================================================================")
    for r in restaurants:
        act = bool_val(r[4], dialect)
        lines.append(f"INSERT INTO restaurants (id, nombre, correo, contraseña, activo) VALUES ({r[0]}, {escape_str(r[1])}, {escape_str(r[2])}, {escape_str(r[3])}, {act});")
        
    # 2. Usuarios
    lines.append("\n-- ============================================================================")
    lines.append("-- 2. USUARIOS (Roles: ROLE_CREATOR, ROLE_ADMIN, ROLE_MESERO)")
    lines.append("-- ============================================================================")
    for u in users:
        id_m = escape_str(u[1])
        r_id = u[6] if u[6] is not None and u[6] != "NULL" else "NULL"
        act = bool_val(u[7], dialect)
        lines.append(f"INSERT INTO usuarios (id, id_mesero, name, mail, password, rol, restaurant_id, activo) VALUES ({u[0]}, {id_m}, {escape_str(u[2])}, {escape_str(u[3])}, {escape_str(u[4])}, {escape_str(u[5])}, {r_id}, {act});")

    # 3. Mesas
    lines.append("\n-- ============================================================================")
    lines.append("-- 3. MESAS (Salón principal, terraza y barras)")
    lines.append("-- ============================================================================")
    for m in mesas:
        oc = bool_val(m[2], dialect)
        m_id = escape_str(m[3])
        lines.append(f"INSERT INTO mesas (id, num, ocupado, mesero_id, restaurant_id) VALUES ({m[0]}, {m[1]}, {oc}, {m_id}, {m[4]});")

    # 4. Mesa Pedidos (Mapping)
    lines.append("\n-- ============================================================================")
    lines.append("-- 4. MESA_PEDIDOS (Asociación mesa - pedidos activos/históricos)")
    lines.append("-- ============================================================================")
    for mp in mesa_pedidos:
        lines.append(f"INSERT INTO mesa_pedidos (mesa_id, pedido_id) VALUES ({mp[0]}, {escape_str(mp[1])});")

    # 5. Productos
    lines.append("\n-- ============================================================================")
    lines.append("-- 5. PRODUCTOS / INSUMOS / INVENTARIO")
    lines.append("-- ============================================================================")
    for pr in productos:
        act = bool_val(pr[8], dialect)
        lines.append(f"INSERT INTO productos (id, name, descripcion, u_medida, cant, price, stock, restaurant_id, activo) VALUES ({pr[0]}, {escape_str(pr[1])}, {escape_str(pr[2])}, {escape_str(pr[3])}, {escape_str(pr[4])}, {pr[5]}, {pr[6]}, {pr[7]}, {act});")

    # 6. Platillos
    lines.append("\n-- ============================================================================")
    lines.append("-- 6. PLATILLOS (Catálogo / Menú)")
    lines.append("-- ============================================================================")
    for pl in platillos:
        lines.append(f"INSERT INTO platillos (id, name, price, cant, restaurant_id) VALUES ({pl[0]}, {escape_str(pl[1])}, {pl[2]}, {escape_str(pl[3])}, {pl[4]});")

    # 7. Platillo Ingredientes
    lines.append("\n-- ============================================================================")
    lines.append("-- 7. PLATILLO_INGREDIENTES (Recetas e Insumos)")
    lines.append("-- ============================================================================")
    for pi in platillo_ingredientes:
        lines.append(f"INSERT INTO platillo_ingredientes (id, platillo_id, producto_id, cantidad) VALUES ({pi[0]}, {pi[1]}, {pi[2]}, {pi[3]});")

    # 8. Pedidos
    lines.append("\n-- ============================================================================")
    lines.append("-- 8. PEDIDOS (Órdenes de clientes)")
    lines.append("-- ============================================================================")
    for ped in processed_pedidos:
        pag = bool_val(ped[7], dialect)
        lines.append(f"INSERT INTO pedidos (id, mesa_num, mesero_name, mesa_id, mesero_id, fecha, total, pagado, restaurant_id) VALUES ({ped[0]}, {ped[1]}, {escape_str(ped[2])}, {escape_str(ped[3])}, {escape_str(ped[4])}, '{ped[5]}', {ped[6]}, {pag}, {ped[8]});")

    # 9. Items Pedido
    lines.append("\n-- ============================================================================")
    lines.append("-- 9. ITEMS_PEDIDO (Detalle de cada orden)")
    lines.append("-- ============================================================================")
    for it in items_pedido:
        lines.append(f"INSERT INTO items_pedido (id, pedido_id, product_id, name, price, cant, unidades) VALUES ({it[0]}, {it[1]}, {escape_str(it[2])}, {escape_str(it[3])}, {it[4]}, {escape_str(it[5])}, {it[6]});")

    # 10. Facturas
    lines.append("\n-- ============================================================================")
    lines.append("-- 10. FACTURAS")
    lines.append("-- ============================================================================")
    for fac in facturas:
        pag = bool_val(fac[6], dialect)
        lines.append(f"INSERT INTO facturas (id, pedido_id, mesa_num, mesero_name, fecha, total, pagada, estado, restaurant_id) VALUES ({fac[0]}, {escape_str(fac[1])}, {escape_str(fac[2])}, {escape_str(fac[3])}, '{fac[4]}', {fac[5]}, {pag}, {escape_str(fac[7])}, {fac[8]});")

    # 11. Factura Items
    lines.append("\n-- ============================================================================")
    lines.append("-- 11. FACTURA_ITEMS (Asociación factura - ítems consumidos)")
    lines.append("-- ============================================================================")
    for fi in factura_items:
        lines.append(f"INSERT INTO factura_items (factura_id, item_id) VALUES ({fi[0]}, {fi[1]});")

    # 12. Pagos
    lines.append("\n-- ============================================================================")
    lines.append("-- 12. PAGOS (Transacciones y métodos de cobro)")
    lines.append("-- ============================================================================")
    for pa in pagos:
        ic = bool_val(pa[5], dialect)
        lines.append(f"INSERT INTO pagos (id, factura_id, metodo, monto, fecha, imprimir_copia) VALUES ({pa[0]}, {escape_str(pa[1])}, {escape_str(pa[2])}, {pa[3]}, '{pa[4]}', {ic});")

    # 13. Foros
    lines.append("\n-- ============================================================================")
    lines.append("-- 13. FOROS (Comentarios, novedades de turno y notas de equipo)")
    lines.append("-- ============================================================================")
    for fo in foros:
        lines.append(f"INSERT INTO foros (id, fnombre, fcomentario, fecha) VALUES ({fo[0]}, {escape_str(fo[1])}, {escape_str(fo[2])}, '{fo[3]}');")

    return "\n".join(lines)


# ==============================================================================
# GENERACIÓN DE POSTGRESQL (init_postgresql.sql)
# ==============================================================================
pg_header = """-- ============================================================================
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

"""

pg_footer = """

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
"""

# ==============================================================================
# GENERACIÓN DE MYSQL (init_mysql.sql)
# ==============================================================================
my_header = """-- ============================================================================
-- RSKITCHEN 5.0 - SCRIPT DE INICIALIZACIÓN COMPLETO PARA MYSQL / MARIADB
-- Base de datos: Rskitchen6 (Configuración local en application.properties)
-- Incluye DDL (Tablas, Índices, Constraints) y DML con datos completos y coherentes.
-- ============================================================================

SET FOREIGN_KEY_CHECKS = 0;
SET NAMES utf8mb4;

-- Crear tablas si no existen
CREATE TABLE IF NOT EXISTS restaurants (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    correo VARCHAR(255) NOT NULL UNIQUE,
    contraseña VARCHAR(255) NOT NULL,
    activo BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS usuarios (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    id_mesero VARCHAR(255),
    name VARCHAR(255) NOT NULL,
    mail VARCHAR(255) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    rol VARCHAR(255) NOT NULL,
    restaurant_id BIGINT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_usuarios_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mesas (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    num INT NOT NULL,
    ocupado BOOLEAN NOT NULL DEFAULT FALSE,
    mesero_id VARCHAR(255),
    restaurant_id BIGINT,
    CONSTRAINT fk_mesas_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS mesa_pedidos (
    mesa_id BIGINT NOT NULL,
    pedido_id VARCHAR(255) NOT NULL,
    CONSTRAINT fk_mesa_pedidos_mesa FOREIGN KEY (mesa_id) REFERENCES mesas(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS productos (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255),
    descripcion VARCHAR(1000),
    u_medida VARCHAR(255),
    cant VARCHAR(255),
    price DOUBLE NOT NULL,
    stock INT NOT NULL,
    restaurant_id BIGINT,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_productos_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS platillos (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    price DOUBLE NOT NULL,
    cant VARCHAR(255),
    restaurant_id BIGINT,
    CONSTRAINT fk_platillos_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS platillo_ingredientes (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    platillo_id BIGINT NOT NULL,
    producto_id BIGINT NOT NULL,
    cantidad DOUBLE NOT NULL DEFAULT 1.0,
    CONSTRAINT fk_pi_platillo FOREIGN KEY (platillo_id) REFERENCES platillos(id) ON DELETE CASCADE,
    CONSTRAINT fk_pi_producto FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pedidos (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    mesa_num INT NOT NULL,
    mesero_name VARCHAR(255),
    mesa_id VARCHAR(255),
    mesero_id VARCHAR(255),
    fecha DATETIME,
    total DOUBLE NOT NULL DEFAULT 0.0,
    pagado BOOLEAN NOT NULL DEFAULT FALSE,
    restaurant_id BIGINT,
    CONSTRAINT fk_pedidos_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS items_pedido (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    pedido_id BIGINT,
    product_id VARCHAR(255),
    name VARCHAR(255),
    price DOUBLE NOT NULL DEFAULT 0.0,
    cant VARCHAR(255),
    unidades INT NOT NULL DEFAULT 0,
    CONSTRAINT fk_items_pedido FOREIGN KEY (pedido_id) REFERENCES pedidos(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS facturas (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    pedido_id VARCHAR(255),
    mesa_num VARCHAR(255),
    mesero_name VARCHAR(255),
    fecha DATETIME,
    total DOUBLE NOT NULL DEFAULT 0.0,
    pagada BOOLEAN NOT NULL DEFAULT FALSE,
    estado VARCHAR(255) DEFAULT 'PENDIENTE',
    restaurant_id BIGINT,
    CONSTRAINT fk_facturas_restaurant FOREIGN KEY (restaurant_id) REFERENCES restaurants(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS factura_items (
    factura_id BIGINT NOT NULL,
    item_id BIGINT NOT NULL,
    PRIMARY KEY (factura_id, item_id),
    CONSTRAINT fk_fi_factura FOREIGN KEY (factura_id) REFERENCES facturas(id) ON DELETE CASCADE,
    CONSTRAINT fk_fi_item FOREIGN KEY (item_id) REFERENCES items_pedido(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS pagos (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    factura_id VARCHAR(255),
    metodo VARCHAR(255),
    monto DOUBLE NOT NULL,
    fecha DATETIME,
    imprimir_copia BOOLEAN NOT NULL DEFAULT FALSE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS foros (
    id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    fnombre VARCHAR(255),
    fcomentario VARCHAR(2000),
    fecha DATETIME
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Limpieza previa opcional
TRUNCATE TABLE foros;
TRUNCATE TABLE pagos;
TRUNCATE TABLE factura_items;
TRUNCATE TABLE facturas;
TRUNCATE TABLE items_pedido;
TRUNCATE TABLE pedidos;
TRUNCATE TABLE platillo_ingredientes;
TRUNCATE TABLE platillos;
TRUNCATE TABLE productos;
TRUNCATE TABLE mesa_pedidos;
TRUNCATE TABLE mesas;
TRUNCATE TABLE usuarios;
TRUNCATE TABLE restaurants;

"""

my_footer = """

SET FOREIGN_KEY_CHECKS = 1;

-- RSKitchen inicializado exitosamente en MySQL.
"""

# ==============================================================================
# GENERACIÓN DE SEED DATA UNIVERSAL (seed_data.sql)
# ==============================================================================
seed_header = """-- ============================================================================
-- RSKITCHEN 5.0 - SEED DATA UNIVERSAL (SOLO INSERCIONES DML)
-- Compatible con Hibernate ddl-auto=update / ddl-auto=create
-- Funciona tanto en PostgreSQL como en MySQL.
-- ============================================================================

"""

import os

base_dir = os.path.dirname(os.path.abspath(__file__))
root_db_dir = os.path.abspath(os.path.join(base_dir, "..", "..", "database"))

pg_content = pg_header + generate_dml("pg") + pg_footer
my_content = my_header + generate_dml("mysql") + my_footer
seed_content = seed_header + generate_dml("pg")

# Guardar en PA5-RSKITCHEN/database/
with open(os.path.join(base_dir, "init_postgresql.sql"), "w", encoding="utf-8") as f:
    f.write(pg_content)

with open(os.path.join(base_dir, "init_mysql.sql"), "w", encoding="utf-8") as f:
    f.write(my_content)

with open(os.path.join(base_dir, "seed_data.sql"), "w", encoding="utf-8") as f:
    f.write(seed_content)

# Guardar copia en /database raíz para comodidad del usuario
with open(os.path.join(root_db_dir, "init_postgresql.sql"), "w", encoding="utf-8") as f:
    f.write(pg_content)

with open(os.path.join(root_db_dir, "init_mysql.sql"), "w", encoding="utf-8") as f:
    f.write(my_content)

with open(os.path.join(root_db_dir, "seed_data.sql"), "w", encoding="utf-8") as f:
    f.write(seed_content)

print("Archivos SQL generados exitosamente en:")
print(" - PA5-RSKITCHEN/database/")
print(" - database/ (raíz)")

