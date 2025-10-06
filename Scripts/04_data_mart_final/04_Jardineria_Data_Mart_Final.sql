
/* ============================================================
    CREAR BASE DE DATOS DATA MART FINAL
   ============================================================ */

-- Crear la base del Data Mart
CREATE DATABASE Jardineria_Data_Mart_Final;

USE Jardineria_Data_Mart_Final;


CREATE TABLE DimCliente (
    ClienteID INT PRIMARY KEY,
    NombreCliente VARCHAR(100),
    Ciudad VARCHAR(50),
    Pais VARCHAR(50)
);


-- 2. Tabla DimProducto
CREATE TABLE DimProducto (
    ProductoID INT IDENTITY(1,1) PRIMARY KEY,
    NombreProducto VARCHAR(100) NOT NULL,
    Categoria VARCHAR(50),
    Precio DECIMAL(10,2)
);

-- 3. Tabla DimVendedor
CREATE TABLE DimVendedor (
    VendedorID INT IDENTITY(1,1) PRIMARY KEY,
    NombreVendedor VARCHAR(100) NOT NULL,
    Region VARCHAR(50)
);

-- 4. Tabla DimTiempo
CREATE TABLE DimTiempo (
    TiempoID INT IDENTITY(1,1) PRIMARY KEY,
    Fecha DATE NOT NULL,
    Dia INT,
    Mes INT,
    Año INT,
    Trimestre INT
);
-- 5. Tabla FactVentas
CREATE TABLE FactVentas (
    VentaID INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID INT,
    ProductoID INT,
    VendedorID INT,
    TiempoID INT,
    Cantidad INT,
    Total DECIMAL(10,2),
    CONSTRAINT FK_FactVentas_Cliente FOREIGN KEY (ClienteID)
        REFERENCES DimCliente(ClienteID),
    CONSTRAINT FK_FactVentas_Producto FOREIGN KEY (ProductoID)
        REFERENCES DimProducto(ProductoID),
    CONSTRAINT FK_FactVentas_Vendedor FOREIGN KEY (VendedorID)
        REFERENCES DimVendedor(VendedorID),
    CONSTRAINT FK_FactVentas_Tiempo FOREIGN KEY (TiempoID)
        REFERENCES DimTiempo(TiempoID)
);


/* ============================================================
    CARGA DE DIMENSIONES: STAGING → DATA MART
   ============================================================ */

-- Clientes
INSERT INTO DimCliente (ClienteID, NombreCliente, Ciudad, Pais)
SELECT DISTINCT id_cliente, nombre_cliente, ciudad, pais
FROM Jardineria_Staging.dbo.stg_clientes;

-- Productos
INSERT INTO dbo.DimProducto (NombreProducto, Categoria, Precio)
SELECT nombre_producto, categoria, precio_venta
FROM Jardineria_Staging.dbo.stg_productos;

-- Vendedores
INSERT INTO dbo.DimVendedor (NombreVendedor, Region)
SELECT DISTINCT (e.nombre + ' ' + e.apellido), o.region
FROM Jardineria_Staging.dbo.stg_empleados e
JOIN Jardineria_Staging.dbo.stg_oficinas o ON e.id_oficina = o.id_oficina;

-- Tiempo
INSERT INTO dbo.DimTiempo (Fecha, Año, Mes, Dia, Trimestre)
SELECT DISTINCT
    fecha_pedido,
    YEAR(fecha_pedido),
    MONTH(fecha_pedido),
    DAY(fecha_pedido),
    DATEPART(QUARTER, fecha_pedido)
FROM Jardineria_Staging.dbo.stg_pedidos;

/* ============================================================
    CARGA DE TABLA DE HECHOS
   ============================================================ */

INSERT INTO dbo.FactVentas (ClienteID, ProductoID, VendedorID, TiempoID, Cantidad, Total)
SELECT 
    dc.ClienteID,            
    dp.ProductoID,
    dv.VendedorID,
    dt.TiempoID,
    dpe.cantidad,
    (dpe.cantidad * dpe.precio_unidad) AS Total
FROM Jardineria_Staging.dbo.stg_detalle_pedido dpe
JOIN Jardineria_Staging.dbo.stg_pedidos pe ON dpe.id_pedido = pe.id_pedido
JOIN Jardineria_Staging.dbo.stg_clientes c ON pe.id_cliente = c.id_cliente
JOIN Jardineria_Staging.dbo.stg_productos p ON dpe.id_producto = p.id_producto
JOIN DimCliente dc ON dc.ClienteID = c.id_cliente
JOIN DimProducto dp ON dp.NombreProducto = p.nombre_producto
JOIN DimTiempo dt ON dt.Fecha = pe.fecha_pedido
JOIN DimVendedor dv ON dv.VendedorID = (
        SELECT TOP 1 e.id_empleado 
        FROM Jardineria_Staging.dbo.stg_empleados e
        WHERE e.id_empleado = (
            SELECT TOP 1 id_empleado 
            FROM Jardineria_Staging.dbo.stg_empleados
        )
    );


/* ============================================================
    CONSULTAS ANALÍTICAS FINALES
   ============================================================ */

-- Producto más vendido
SELECT TOP 1 dp.NombreProducto, SUM(fv.Cantidad) AS TotalUnidadesVendidas
FROM dbo.FactVentas fv
JOIN dbo.DimProducto dp ON fv.ProductoID = dp.ProductoID
GROUP BY dp.NombreProducto
ORDER BY TotalUnidadesVendidas DESC;

-- Categoría con más productos
SELECT TOP 1 Categoria, COUNT(*) AS CantidadProductos
FROM dbo.DimProducto
GROUP BY Categoria
ORDER BY CantidadProductos DESC;

-- Año con mayores ventas
SELECT TOP 1 dt.Año, SUM(fv.Total) AS TotalVentas
FROM dbo.FactVentas fv
JOIN dbo.DimTiempo dt ON fv.TiempoID = dt.TiempoID
GROUP BY dt.Año
ORDER BY TotalVentas DESC;

-- Validación de Clientes
SELECT 'Clientes' AS Tabla,
       (SELECT COUNT(*) FROM Jardineria_Staging.dbo.stg_clientes) AS Registros_Staging,
       (SELECT COUNT(*) FROM dbo.DimCliente) AS Registros_Data_Mart_Final;

-- Validación de Productos
SELECT 'Productos' AS Tabla,
       (SELECT COUNT(*) FROM Jardineria_Staging.dbo.stg_productos) AS Registros_Staging,
       (SELECT COUNT(*) FROM dbo.DimProducto) AS Registros_Data_Mart_Final;

-- Validación de Vendedor
SELECT 'Empleados' AS Tabla,
       (SELECT COUNT(*) FROM Jardineria_Staging.dbo.stg_empleados) AS Registros_Staging,
       (SELECT COUNT(*) FROM dbo.DimVendedor) AS Registros_Data_Mart_Final;

-- Validación de Tiempo
SELECT 'Fecha Pedido' AS Tabla,
       (SELECT COUNT(DISTINCT CAST(fecha_pedido AS DATE)) FROM Jardineria_Staging.dbo.stg_pedidos) AS Fechas_Staging,
       (SELECT COUNT(*) FROM dbo.DimTiempo) AS Registros_Data_Mart_Final;

------------------------------------------------------------
-- HUÉRFANOS
------------------------------------------------------------

-- FactVentas con Cliente inexistente
IF EXISTS (
    SELECT 1
    FROM dbo.FactVentas f
    LEFT JOIN dbo.DimCliente c ON f.ClienteID = c.ClienteID
    WHERE c.ClienteID IS NULL
)
    SELECT 'FactVentas con Cliente inexistente' AS Prueba, f.VentaID, f.ClienteID
    FROM dbo.FactVentas f
    LEFT JOIN dbo.DimCliente c ON f.ClienteID = c.ClienteID
    WHERE c.ClienteID IS NULL;
ELSE
    SELECT 'OK - Sin clientes huérfanos en FactVentas' AS Mensaje;

-- FactVentas con Producto inexistente
IF EXISTS (
    SELECT 1
    FROM dbo.FactVentas f
    LEFT JOIN dbo.DimProducto p ON f.ProductoID = p.ProductoID
    WHERE p.ProductoID IS NULL
)
    SELECT 'FactVentas con Producto inexistente' AS Prueba, f.VentaID, f.ProductoID
    FROM dbo.FactVentas f
    LEFT JOIN dbo.DimProducto p ON f.ProductoID = p.ProductoID
    WHERE p.ProductoID IS NULL;
ELSE
    SELECT 'OK - Sin productos huérfanos en FactVentas' AS Mensaje;

-- FactVentas con Vendedor inexistente
IF EXISTS (
    SELECT 1
    FROM dbo.FactVentas f
    LEFT JOIN dbo.DimVendedor v ON f.VendedorID = v.VendedorID
    WHERE v.VendedorID IS NULL
)
    SELECT 'FactVentas con Vendedor inexistente' AS Prueba, f.VentaID, f.VendedorID
    FROM dbo.FactVentas f
    LEFT JOIN dbo.DimVendedor v ON f.VendedorID = v.VendedorID
    WHERE v.VendedorID IS NULL;
ELSE
    SELECT 'OK - Sin vendedores huérfanos en FactVentas' AS Mensaje;

-- FactVentas con Tiempo inexistente
IF EXISTS (
    SELECT 1
    FROM dbo.FactVentas f
    LEFT JOIN dbo.DimTiempo t ON f.TiempoID = t.TiempoID
    WHERE t.TiempoID IS NULL
)
    SELECT 'FactVentas con Tiempo inexistente' AS Prueba, f.VentaID, f.TiempoID
    FROM dbo.FactVentas f
    LEFT JOIN dbo.DimTiempo t ON f.TiempoID = t.TiempoID
    WHERE t.TiempoID IS NULL;
ELSE
    SELECT 'OK - Sin tiempos huérfanos en FactVentas' AS Mensaje;


------------------------------------------------------------
-- DUPLICADOS
------------------------------------------------------------

-- DimCliente
IF EXISTS (SELECT 1 FROM dbo.DimCliente GROUP BY NombreCliente, Ciudad, Pais HAVING COUNT(*) > 1)
    SELECT 'DimCliente duplicados' AS Prueba, NombreCliente, Ciudad, Pais, COUNT(*) AS Total
    FROM dbo.DimCliente
    GROUP BY NombreCliente, Ciudad, Pais
    HAVING COUNT(*) > 1;
ELSE
    SELECT 'OK - Sin duplicados en DimCliente' AS Mensaje;

-- DimProducto
IF EXISTS (SELECT 1 FROM dbo.DimProducto GROUP BY NombreProducto, Categoria, Precio HAVING COUNT(*) > 1)
    SELECT 'DimProducto duplicados' AS Prueba, NombreProducto, Categoria, Precio, COUNT(*) AS Total
    FROM dbo.DimProducto
    GROUP BY NombreProducto, Categoria, Precio
    HAVING COUNT(*) > 1;
ELSE
    SELECT 'OK - Sin duplicados en DimProducto' AS Mensaje;

-- DimVendedor
IF EXISTS (SELECT 1 FROM dbo.DimVendedor GROUP BY NombreVendedor, Region HAVING COUNT(*) > 1)
    SELECT 'DimVendedor duplicados' AS Prueba, NombreVendedor, Region, COUNT(*) AS Total
    FROM dbo.DimVendedor
    GROUP BY NombreVendedor, Region
    HAVING COUNT(*) > 1;
ELSE
    SELECT 'OK - Sin duplicados en DimVendedor' AS Mensaje;

------------------------------------------------------------
-- NULOS
------------------------------------------------------------
-- DimCliente
IF EXISTS (SELECT 1 FROM dbo.DimCliente WHERE NombreCliente IS NULL OR Ciudad IS NULL OR Pais IS NULL)
    SELECT 'DimCliente con campos nulos' AS Prueba, *
    FROM dbo.DimCliente
    WHERE NombreCliente IS NULL OR Ciudad IS NULL OR Pais IS NULL;
ELSE
    SELECT 'OK - Sin nulos en DimCliente' AS Mensaje;

-- DimProducto
IF EXISTS (SELECT 1 FROM dbo.DimProducto WHERE NombreProducto IS NULL OR Categoria IS NULL OR Precio IS NULL)
    SELECT 'DimProducto con campos nulos' AS Prueba, *
    FROM dbo.DimProducto
    WHERE NombreProducto IS NULL OR Categoria IS NULL OR Precio IS NULL;
ELSE
    SELECT 'OK - Sin nulos en DimProducto' AS Mensaje;

-- DimVendedor
IF EXISTS (SELECT 1 FROM dbo.DimVendedor WHERE NombreVendedor IS NULL OR Region IS NULL)
    SELECT 'DimVendedor con campos nulos' AS Prueba, *
    FROM dbo.DimVendedor
    WHERE NombreVendedor IS NULL OR Region IS NULL;
ELSE
    SELECT 'OK - Sin nulos en DimVendedor' AS Mensaje;

-- DimTiempo
IF EXISTS (SELECT 1 FROM dbo.DimTiempo WHERE Fecha IS NULL)
    SELECT 'DimTiempo con Fecha nula' AS Prueba, *
    FROM dbo.DimTiempo
    WHERE Fecha IS NULL;
ELSE
    SELECT 'OK - Sin nulos en DimTiempo' AS Mensaje;

-- FactVentas
IF EXISTS (SELECT 1 FROM dbo.FactVentas
           WHERE ClienteID IS NULL OR ProductoID IS NULL OR VendedorID IS NULL
                 OR TiempoID IS NULL OR Cantidad IS NULL OR Total IS NULL)
    SELECT 'FactVentas con campos nulos' AS Prueba, *
    FROM dbo.FactVentas
    WHERE ClienteID IS NULL OR ProductoID IS NULL OR VendedorID IS NULL
          OR TiempoID IS NULL OR Cantidad IS NULL OR Total IS NULL;
ELSE
    SELECT 'OK - Sin nulos en FactVentas' AS Mensaje;

------------------------------------------------------------
-- RANGOS DE VALORES
------------------------------------------------------------
-- Precio negativo o cero en DimProducto
IF EXISTS (SELECT 1 FROM dbo.DimProducto WHERE Precio <= 0)
    SELECT 'DimProducto con precio <= 0' AS Prueba, *
    FROM dbo.DimProducto
    WHERE Precio <= 0;
ELSE
    SELECT 'OK - Precios válidos en DimProducto' AS Mensaje;

-- Cantidad o Total negativo en FactVentas
IF EXISTS (SELECT 1 FROM dbo.FactVentas WHERE Cantidad <= 0 OR Total <= 0)
    SELECT 'FactVentas con Cantidad/Total inválido' AS Prueba, *
    FROM dbo.FactVentas
    WHERE Cantidad <= 0 OR Total <= 0;
ELSE
    SELECT 'OK - Cantidad y Total válidos en FactVentas' AS Mensaje;

-- Fechas fuera de rango lógico en DimTiempo
IF EXISTS (
    SELECT 1 FROM dbo.DimTiempo
    WHERE Fecha < '2000-01-01' OR Fecha > GETDATE()
)
    SELECT 'DimTiempo con fechas fuera de rango' AS Prueba, *
    FROM dbo.DimTiempo
    WHERE Fecha < '2000-01-01' OR Fecha > GETDATE();
ELSE
    SELECT 'OK - Fechas válidas en DimTiempo' AS Mensaje;



