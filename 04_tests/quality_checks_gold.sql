/*
=============================================================
Quality Checks: Validación de Calidad de la Capa Gold
=============================================================
Script Purpose:
    Verifica la integridad dimensional y analítica de las vistas
    en el esquema 'gold' (Esquema en Estrella).
=============================================================
*/

USE DataWarehouse;
GO

PRINT '=====================================================';
PRINT 'Iniciando Pruebas de Calidad en Capa Gold';
PRINT '=====================================================';

-- -----------------------------------------------------------
-- 1. Unicidad de Claves Subrogadas en gold.dim_customers
-- (Debe devolver 0 filas)
-- -----------------------------------------------------------
PRINT '>> Test 1: Unicidad de customer_key en dim_customers';
SELECT 
    customer_key, 
    COUNT(*) AS ocurrencias
FROM gold.dim_customers
GROUP BY customer_key
HAVING COUNT(*) > 1 OR customer_key IS NULL;

-- -----------------------------------------------------------
-- 2. Unicidad de Claves Subrogadas en gold.dim_products
-- (Debe devolver 0 filas)
-- -----------------------------------------------------------
PRINT '>> Test 2: Unicidad de product_key en dim_products';
SELECT 
    product_key, 
    COUNT(*) AS ocurrencias
FROM gold.dim_products
GROUP BY product_key
HAVING COUNT(*) > 1 OR product_key IS NULL;

-- -----------------------------------------------------------
-- 3. Integridad Referencial: Ventas vinculadas a Clientes
-- (Verifica que todas las ventas tengan un cliente válido)
-- -----------------------------------------------------------
PRINT '>> Test 3: Ventas sin cliente vinculado (huérfanos)';
SELECT 
    COUNT(*) AS ventas_sin_cliente
FROM gold.fact_sales
WHERE customer_key IS NULL;

-- -----------------------------------------------------------
-- 4. Prueba Analítica de Negocio: Total de Ventas Globales
-- -----------------------------------------------------------
PRINT '>> Test 4: Métricas Globales de Negocio';
SELECT 
    COUNT(DISTINCT order_number) AS total_pedidos,
    COUNT(*)                     AS total_transacciones,
    SUM(quantity)                AS unidades_vendidas,
    SUM(sales_amount)            AS monto_total_ventas,
    AVG(sales_amount)            AS ticket_promedio
FROM gold.fact_sales;

-- -----------------------------------------------------------
-- 5. Prueba Analítica de Negocio: Ventas por Categoría y País
-- -----------------------------------------------------------
PRINT '>> Test 5: Ventas agrupadas por Categoría de Producto';
SELECT 
    COALESCE(p.category, 'Historical / Unassigned') AS categoria,
    COUNT(f.order_number)                           AS total_pedidos,
    SUM(f.sales_amount)                             AS total_ventas
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
    ON f.product_key = p.product_key
GROUP BY p.category
ORDER BY total_ventas DESC;
GO