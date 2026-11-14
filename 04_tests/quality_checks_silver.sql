/*
=============================================================
Quality Checks: Validación de Calidad de la Capa Silver
=============================================================
Script Purpose:
    Ejecuta pruebas para verificar la integridad, estandarización
    y calidad de los datos depurados en el esquema 'silver'.
    Cualquier consulta que devuelva filas representa una anomalía.
=============================================================
*/

USE DataWarehouse;
GO

PRINT '=====================================================';
PRINT 'Iniciando Pruebas de Calidad en Capa Silver';
PRINT '=====================================================';

-- -----------------------------------------------------------
-- 1. Verificar duplicados o IDs nulos en silver.crm_cust_info
-- (Debe devolver 0 filas)
-- -----------------------------------------------------------
PRINT '>> Test 1: Duplicados en Clientes CRM';
SELECT 
    cst_id, 
    COUNT(*) AS ocurrencias
FROM silver.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1 OR cst_id IS NULL;

-- -----------------------------------------------------------
-- 2. Verificar espacios en blanco no deseados en nombres
-- (Debe devolver 0 filas)
-- -----------------------------------------------------------
PRINT '>> Test 2: Espacios no deseados en nombres CRM';
SELECT 
    cst_id, 
    cst_firstname, 
    cst_lastname
FROM silver.crm_cust_info
WHERE cst_firstname != TRIM(cst_firstname)
   OR cst_lastname != TRIM(cst_lastname);

-- -----------------------------------------------------------
-- 3. Verificar estandarización de Género y Estado Civil
-- (Solo deben existir: Male, Female, Single, Married, n/a)
-- -----------------------------------------------------------
PRINT '>> Test 3: Valores distintos de Género y Estado Civil';
SELECT DISTINCT cst_gndr FROM silver.crm_cust_info;
SELECT DISTINCT cst_marital_status FROM silver.crm_cust_info;

-- -----------------------------------------------------------
-- 4. Verificar fechas de ventas inválidas en silver.crm_sales_details
-- (Las fechas de orden no deben ser mayores a fecha de envío o entrega)
-- -----------------------------------------------------------
PRINT '>> Test 4: Coherencia de Fechas en Ventas';
SELECT 
    sls_ord_num, 
    sls_order_dt, 
    sls_ship_dt
FROM silver.crm_sales_details
WHERE sls_order_dt > sls_ship_dt;

-- -----------------------------------------------------------
-- 5. Verificar cálculo de Ventas = Cantidad * Precio
-- (Debe devolver 0 filas)
-- -----------------------------------------------------------
PRINT '>> Test 5: Consistencia de Monto de Ventas';
SELECT 
    sls_ord_num, 
    sls_sales, 
    sls_quantity, 
    sls_price
FROM silver.crm_sales_details
WHERE sls_sales != sls_quantity * sls_price
   OR sls_sales <= 0;

-- -----------------------------------------------------------
-- 6. Verificar estandarización de Países en ERP
-- (No deben aparecer códigos abreviados como 'US', 'USA', 'DE')
-- -----------------------------------------------------------
PRINT '>> Test 6: Países estandarizados en ERP';
SELECT DISTINCT cntry FROM silver.erp_loc_a101;
GO