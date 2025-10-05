/* ============================================================
    PRUEBA CALIDAD DE DATOS - STAGING
   ============================================================ */

-- Validación de Clientes
SELECT 'Clientes' AS Tabla,
       (SELECT COUNT(*) FROM jardineria.dbo.cliente) AS Registros_Original,
       (SELECT COUNT(*) FROM dbo.stg_clientes) AS Registros_Staging;

-- Validación de Productos
SELECT 'Productos' AS Tabla,
       (SELECT COUNT(*) FROM jardineria.dbo.producto) AS Registros_Original,
       (SELECT COUNT(*) FROM dbo.stg_productos) AS Registros_Staging;

-- Validación de Pedidos
SELECT 'Pedidos' AS Tabla,
       (SELECT COUNT(*) FROM jardineria.dbo.pedido) AS Registros_Original,
       (SELECT COUNT(*) FROM dbo.stg_pedidos) AS Registros_Staging;

-- Validación de Detalle de Pedidos
SELECT 'DetallePedidos' AS Tabla,
       (SELECT COUNT(*) FROM jardineria.dbo.detalle_pedido) AS Registros_Original,
       (SELECT COUNT(*) FROM dbo.stg_detalle_pedido) AS Registros_Staging;

-- Validación de Empleados
SELECT 'Empleados' AS Tabla,
       (SELECT COUNT(*) FROM jardineria.dbo.empleado) AS Registros_Original,
       (SELECT COUNT(*) FROM dbo.stg_empleados) AS Registros_Staging;

-- Validación de Oficinas
SELECT 'Oficinas' AS Tabla,
       (SELECT COUNT(*) FROM jardineria.dbo.oficina) AS Registros_Original,
       (SELECT COUNT(*) FROM dbo.stg_oficinas) AS Registros_Staging;


SELECT TABLE_SCHEMA AS Esquema,
       TABLE_NAME   AS Nombre_Tabla
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_TYPE = 'BASE TABLE'
ORDER BY TABLE_NAME;


------------------------------------------------------------
-- HUÉRFANOS
------------------------------------------------------------

-- 1.1 Pedidos con cliente inexistente
IF EXISTS (
    SELECT 1
    FROM stg_pedidos p
    LEFT JOIN stg_clientes c ON p.id_cliente = c.id_cliente
    WHERE c.id_cliente IS NULL
)
    SELECT 'Pedidos con cliente inexistente' AS Prueba,
           p.id_pedido, p.id_cliente
    FROM stg_pedidos p
    LEFT JOIN stg_clientes c ON p.id_cliente = c.id_cliente
    WHERE c.id_cliente IS NULL;
ELSE
    SELECT 'OK - Sin pedidos huérfanos' AS Mensaje;

IF EXISTS (
    SELECT 1
    FROM stg_detalle_pedido d
    LEFT JOIN stg_pedidos p ON d.id_pedido = p.id_pedido
    WHERE p.id_pedido IS NULL
)
    SELECT 'Detalle con pedido inexistente' AS Prueba,
           d.id_pedido, d.id_producto
    FROM stg_detalle_pedido d
    LEFT JOIN stg_pedidos p ON d.id_pedido = p.id_pedido
    WHERE p.id_pedido IS NULL;
ELSE
    SELECT 'OK - Sin detalles huérfanos (pedido)' AS Mensaje;

-- 1.3 Detalle de pedido con producto inexistente
IF EXISTS (
    SELECT 1
    FROM stg_detalle_pedido d
    LEFT JOIN stg_productos p ON d.id_producto = p.id_producto
    WHERE p.id_producto IS NULL
)
    SELECT 'Detalle con producto inexistente' AS Prueba,
           d.id_pedido, d.id_producto
    FROM stg_detalle_pedido d
    LEFT JOIN stg_productos p ON d.id_producto = p.id_producto
    WHERE p.id_producto IS NULL;
ELSE
    SELECT 'OK - Sin detalles huérfanos (producto)' AS Mensaje;

-- 1.4 Empleados con oficina inexistente
IF EXISTS (
    SELECT 1
    FROM stg_empleados e
    LEFT JOIN stg_oficinas o ON e.id_oficina = o.id_oficina
    WHERE o.id_oficina IS NULL
)
    SELECT 'Empleados con oficina inexistente' AS Prueba,
           e.id_empleado, e.id_oficina
    FROM stg_empleados e
    LEFT JOIN stg_oficinas o ON e.id_oficina = o.id_oficina
    WHERE o.id_oficina IS NULL;
ELSE
    SELECT 'OK - Sin empleados huérfanos' AS Mensaje;

------------------------------------------------------------
-- DUPLICADOS
------------------------------------------------------------

-- 2.1 Clientes duplicados
IF EXISTS (
    SELECT 1
    FROM stg_clientes
    GROUP BY id_cliente
    HAVING COUNT(*) > 1
)
    SELECT 'Clientes duplicados' AS Prueba,
           id_cliente, COUNT(*) AS Total
    FROM stg_clientes
    GROUP BY id_cliente
    HAVING COUNT(*) > 1;
ELSE
    SELECT 'OK - Sin clientes duplicados' AS Mensaje;

-- 2.2 Productos duplicados
IF EXISTS (
    SELECT 1
    FROM stg_productos
    GROUP BY id_producto
    HAVING COUNT(*) > 1
)
    SELECT 'Productos duplicados' AS Prueba,
           id_producto, COUNT(*) AS Total
    FROM stg_productos
    GROUP BY id_producto
    HAVING COUNT(*) > 1;
ELSE
    SELECT 'OK - Sin productos duplicados' AS Mensaje;

-- 2.3 Pedidos duplicados
IF EXISTS (
    SELECT 1
    FROM stg_pedidos
    GROUP BY id_pedido
    HAVING COUNT(*) > 1
)
    SELECT 'Pedidos duplicados' AS Prueba,
           id_pedido, COUNT(*) AS Total
    FROM stg_pedidos
    GROUP BY id_pedido
    HAVING COUNT(*) > 1;
ELSE
    SELECT 'OK - Sin pedidos duplicados' AS Mensaje;

-- 2.4 Detalle duplicado por pedido + producto
IF EXISTS (
    SELECT 1
    FROM stg_detalle_pedido
    GROUP BY id_pedido, id_producto
    HAVING COUNT(*) > 1
)
    SELECT 'Detalle duplicado (pedido + producto)' AS Prueba,
           id_pedido, id_producto, COUNT(*) AS Total
    FROM stg_detalle_pedido
    GROUP BY id_pedido, id_producto
    HAVING COUNT(*) > 1;
ELSE
    SELECT 'OK - Sin detalles duplicados' AS Mensaje;

------------------------------------------------------------
-- NULOS
------------------------------------------------------------
-- 3.1 Clientes
IF EXISTS (
    SELECT 1
    FROM stg_clientes
    WHERE nombre_cliente IS NULL OR ciudad IS NULL OR pais IS NULL
)
    SELECT 'Clientes con campos nulos' AS Prueba, *
    FROM stg_clientes
    WHERE nombre_cliente IS NULL OR ciudad IS NULL OR pais IS NULL;
ELSE
    SELECT 'OK - Sin nulos en clientes' AS Mensaje;

-- 3.2 Productos
IF EXISTS (
    SELECT 1
    FROM stg_productos
    WHERE nombre_producto IS NULL OR categoria IS NULL OR precio_venta IS NULL
)
    SELECT 'Productos con campos nulos' AS Prueba, *
    FROM stg_productos
    WHERE nombre_producto IS NULL OR categoria IS NULL OR precio_venta IS NULL;
ELSE
    SELECT 'OK - Sin nulos en productos' AS Mensaje;

-- 3.3 Pedidos
IF EXISTS (
    SELECT 1
    FROM stg_pedidos
    WHERE fecha_pedido IS NULL OR estado IS NULL OR id_cliente IS NULL
)
    SELECT 'Pedidos con campos nulos' AS Prueba, *
    FROM stg_pedidos
    WHERE fecha_pedido IS NULL OR estado IS NULL OR id_cliente IS NULL;
ELSE
    SELECT 'OK - Sin nulos en pedidos' AS Mensaje;

------------------------------------------------------------
-- RANGOS DE VALORES
------------------------------------------------------------

-- 4.1 Precio de productos negativo o cero
IF EXISTS (
    SELECT 1 FROM stg_productos WHERE precio_venta <= 0
)
    SELECT 'Productos con precio <= 0' AS Prueba, *
    FROM stg_productos
    WHERE precio_venta <= 0;
ELSE
    SELECT 'OK - Precios válidos' AS Mensaje;

-- 4.2 Cantidad en stock negativa
IF EXISTS (
    SELECT 1 FROM stg_productos WHERE cantidad_en_stock < 0
)
    SELECT 'Stock negativo' AS Prueba, *
    FROM stg_productos
    WHERE cantidad_en_stock < 0;
ELSE
    SELECT 'OK - Stock válido' AS Mensaje;

-- 4.3 Límite de crédito fuera de rango
IF EXISTS (
    SELECT 1 FROM stg_clientes
    WHERE limite_credito < 0 OR limite_credito > 1000000
)
    SELECT 'Límites de crédito fuera de rango' AS Prueba, *
    FROM stg_clientes
    WHERE limite_credito < 0 OR limite_credito > 1000000;
ELSE
    SELECT 'OK - Límites de crédito válidos' AS Mensaje;

-- 4.4 Cantidad o precio de detalle <= 0
IF EXISTS (
    SELECT 1 FROM stg_detalle_pedido
    WHERE cantidad <= 0 OR precio_unidad <= 0
)
    SELECT 'Detalle con cantidad/precio inválido' AS Prueba, *
    FROM stg_detalle_pedido
    WHERE cantidad <= 0 OR precio_unidad <= 0;
ELSE
    SELECT 'OK - Cantidad y precio válidos en detalle' AS Mensaje;

-- 4.5 Fechas de pedido fuera de rango lógico
IF EXISTS (
    SELECT 1 FROM stg_pedidos
    WHERE fecha_pedido < '2000-01-01' OR fecha_pedido > GETDATE()
)
    SELECT 'Pedidos con fecha fuera de rango' AS Prueba, *
    FROM stg_pedidos
    WHERE fecha_pedido < '2000-01-01' OR fecha_pedido > GETDATE();
ELSE
    SELECT 'OK - Fechas de pedidos válidas' AS Mensaje;
