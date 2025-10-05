/* ============================================================
    PRUEBA CALIDAD DE DATOS DATA MART (MODELO ESTRELLA)
   ============================================================ */

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
