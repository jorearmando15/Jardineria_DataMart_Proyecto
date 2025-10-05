/* ============================================================
    CREACIÓN DE TABLAS DATA MART (MODELO ESTRELLA)
   ============================================================ */

-- Crear la base del Data Mart
CREATE DATABASE Jardineria_Dim_Data_Mart;

USE Jardineria_Dim_Data_Mart;

-- 1. Tabla DimCliente
CREATE TABLE DimCliente (
    ClienteID INT IDENTITY(1,1) PRIMARY KEY,
    NombreCliente VARCHAR(100) NOT NULL,
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
-- Poblar DimCliente
INSERT INTO DimCliente (NombreCliente, Ciudad, Pais)
SELECT DISTINCT nombre_cliente, ciudad, pais
FROM jardineria.dbo.cliente;

-- Poblar DimProducto
INSERT INTO DimProducto (NombreProducto, Categoria, Precio)
SELECT p.nombre_producto, cp.Desc_Categoria, p.precio_venta
FROM jardineria.dbo.producto p
JOIN jardineria.dbo.Categoria_producto cp ON p.Categoria = cp.Id_Categoria;

-- Poblar DimVendedor
INSERT INTO DimVendedor (NombreVendedor, Region)
SELECT DISTINCT (e.nombre + ' ' + e.apellido1), o.region
FROM jardineria.dbo.empleado e
JOIN jardineria.dbo.oficina o ON e.ID_oficina = o.ID_oficina;

-- Poblar DimTiempo
INSERT INTO DimTiempo (Fecha, Año, Mes, Dia, Trimestre)
SELECT DISTINCT 
    fecha_pedido,
    YEAR(fecha_pedido),
    MONTH(fecha_pedido),
    DAY(fecha_pedido),
    DATEPART(QUARTER, fecha_pedido)
FROM jardineria.dbo.pedido;

INSERT INTO FactVentas (ClienteID, ProductoID, VendedorID, TiempoID, Cantidad, Total)
SELECT 
    dc.ClienteID,
    dp2.ProductoID,
    dv.VendedorID,
    dt.TiempoID,
    dpe.cantidad,
    (dpe.cantidad * dpe.precio_unidad) AS Total
FROM jardineria.dbo.detalle_pedido dpe
JOIN jardineria.dbo.pedido pe ON dpe.ID_pedido = pe.ID_pedido
JOIN jardineria.dbo.cliente c ON pe.ID_cliente = c.ID_cliente
JOIN jardineria.dbo.producto p ON dpe.ID_producto = p.ID_producto
JOIN jardineria.dbo.Categoria_producto cp ON p.Categoria = cp.Id_Categoria
-- match con dimensiones
JOIN DimCliente dc ON dc.NombreCliente = c.nombre_cliente
JOIN DimProducto dp2 ON dp2.NombreProducto = p.nombre_producto
JOIN DimTiempo dt ON dt.Fecha = pe.fecha_pedido
JOIN DimVendedor dv ON dv.NombreVendedor = (
    SELECT TOP 1 (e.nombre + ' ' + e.apellido1)
    FROM jardineria.dbo.empleado e
    WHERE e.ID_empleado = c.ID_empleado_rep_ventas
);

/*Producto mas vendido */
SELECT TOP 1 
    dp.NombreProducto, 
    SUM(fv.Cantidad) AS TotalUnidadesVendidas
FROM FactVentas fv
JOIN DimProducto dp ON fv.ProductoID = dp.ProductoID
GROUP BY dp.NombreProducto
ORDER BY TotalUnidadesVendidas DESC;

/*Categoria con mas productos*/
SELECT TOP 1 
    Categoria, 
    COUNT(*) AS CantidadProductos
FROM DimProducto
GROUP BY Categoria
ORDER BY CantidadProductos DESC;


/*A o con mas ventas por valor total*/
SELECT TOP 1 
    dt.Año, 
    SUM(fv.Total) AS TotalVentas
FROM FactVentas fv
JOIN DimTiempo dt ON fv.TiempoID = dt.TiempoID
GROUP BY dt.Año
ORDER BY TotalVentas DESC;
