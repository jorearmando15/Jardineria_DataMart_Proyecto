
/* ============================================================
    PRUEBA CALIDAD DE DATOS - DATA MART FINAL
   ============================================================ */

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

PRINT '===== 1. HUÉRFANOS =====';

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


PRINT '===== 2. DUPLICADOS =====';

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

PRINT '===== 3. NULOS =====';

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

PRINT '===== 4. RANGOS DE VALORES =====';

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



