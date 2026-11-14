/*
=============================================================
Stored Procedure: Cargar la Capa Silver (Clean & Transform)
=============================================================
Objetivo:
    Realiza el proceso ETL desde el esquema 'bronze' hacia
    el esquema 'silver'. Aplica limpieza, estandarización,
    normalización, deduplicación y cálculo de columnas derivadas.

Uso:
    EXEC silver.load_silver;
=============================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME;
    DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '==================================================';
        PRINT 'Iniciando Carga de la Capa Silver';
        PRINT '==================================================';

        -- ---------------------------------------------------
        -- 1. SISTEMA CRM
        -- ---------------------------------------------------
        PRINT '--------------------------------------------------';
        PRINT 'Transformando y Cargando Tablas CRM...';
        PRINT '--------------------------------------------------';

        -- Tabla: silver.crm_cust_info
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: silver.crm_cust_info';
        TRUNCATE TABLE silver.crm_cust_info;

        PRINT '>> Insertando datos limpios en: silver.crm_cust_info';
        INSERT INTO silver.crm_cust_info (
            cst_id,
            cst_key,
            cst_firstname,
            cst_lastname,
            cst_marital_status,
            cst_gndr,
            cst_create_date
        )
        SELECT
            cst_id,
            cst_key,
            TRIM(cst_firstname) AS cst_firstname,
            TRIM(cst_lastname) AS cst_lastname,
            CASE 
                WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
                WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
                ELSE 'n/a'
            END AS cst_marital_status,
            CASE 
                WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
                WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
                ELSE 'n/a'
            END AS cst_gndr,
            CAST(cst_create_date AS DATE) AS cst_create_date
        FROM (
            SELECT
                *,
                ROW_NUMBER() OVER (
                    PARTITION BY cst_id 
                    ORDER BY cst_create_date DESC
                ) AS flag_last
            FROM bronze.crm_cust_info
            WHERE cst_id IS NOT NULL AND cst_id != ''
        ) t
        WHERE flag_last = 1;

        SET @end_time = GETDATE();
        PRINT '>> Duración: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -----------------------------------------------';

        -- Tabla: silver.crm_prd_info
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: silver.crm_prd_info';
        TRUNCATE TABLE silver.crm_prd_info;

        PRINT '>> Insertando datos limpios en: silver.crm_prd_info';
        INSERT INTO silver.crm_prd_info (
            prd_id,
            cat_id,
            prd_key,
            prd_nm,
            prd_cost,
            prd_line,
            prd_start_dt,
            prd_end_dt
        )
        SELECT
            CAST(prd_id AS INT) AS prd_id,
            REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
            SUBSTRING(prd_key, 7, LEN(prd_key)) AS prd_key,
            TRIM(prd_nm) AS prd_nm,
            ISNULL(CAST(prd_cost AS INT), 0) AS prd_cost,
            CASE UPPER(TRIM(prd_line))
                WHEN 'M' THEN 'Mountain'
                WHEN 'R' THEN 'Road'
                WHEN 'S' THEN 'Other Sales'
                WHEN 'T' THEN 'Touring'
                ELSE 'n/a'
            END AS prd_line,
            CAST(prd_start_dt AS DATE) AS prd_start_dt,
            CAST(
                DATEADD(day, -1, LEAD(CAST(prd_start_dt AS DATE)) OVER (PARTITION BY SUBSTRING(prd_key, 7, LEN(prd_key)) ORDER BY CAST(prd_start_dt AS DATE))) 
                AS DATE
            ) AS prd_end_dt
        FROM bronze.crm_prd_info;

        SET @end_time = GETDATE();
        PRINT '>> Duración: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -----------------------------------------------';

        -- Tabla: silver.crm_sales_details
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: silver.crm_sales_details';
        TRUNCATE TABLE silver.crm_sales_details;

        PRINT '>> Insertando datos limpios en: silver.crm_sales_details';
        INSERT INTO silver.crm_sales_details (
            sls_ord_num,
            sls_prd_key,
            sls_cust_id,
            sls_order_dt,
            sls_ship_dt,
            sls_due_dt,
            sls_sales,
            sls_quantity,
            sls_price
        )
        SELECT
            TRIM(sls_ord_num) AS sls_ord_num,
            TRIM(sls_prd_key) AS sls_prd_key,
            CAST(sls_cust_id AS INT) AS sls_cust_id,
            CASE 
                WHEN sls_order_dt = 0 OR LEN(sls_order_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_order_dt AS VARCHAR) AS DATE)
            END AS sls_order_dt,
            CASE 
                WHEN sls_ship_dt = 0 OR LEN(sls_ship_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_ship_dt AS VARCHAR) AS DATE)
            END AS sls_ship_dt,
            CASE 
                WHEN sls_due_dt = 0 OR LEN(sls_due_dt) != 8 THEN NULL
                ELSE CAST(CAST(sls_due_dt AS VARCHAR) AS DATE)
            END AS sls_due_dt,
            CASE 
                WHEN CAST(sls_sales AS INT) IS NULL 
                     OR CAST(sls_sales AS INT) <= 0 
                     OR CAST(sls_sales AS INT) != CAST(sls_quantity AS INT) * ABS(CAST(sls_price AS INT))
                    THEN CAST(sls_quantity AS INT) * ABS(CAST(sls_price AS INT))
                ELSE CAST(sls_sales AS INT)
            END AS sls_sales,
            CAST(sls_quantity AS INT) AS sls_quantity,
            CASE 
                WHEN CAST(sls_price AS INT) IS NULL OR CAST(sls_price AS INT) <= 0
                    THEN CAST(sls_sales AS INT) / NULLIF(CAST(sls_quantity AS INT), 0)
                ELSE CAST(sls_price AS INT)
            END AS sls_price
        FROM bronze.crm_sales_details;

        SET @end_time = GETDATE();
        PRINT '>> Duración: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -----------------------------------------------';

        -- ---------------------------------------------------
        -- 2. SISTEMA ERP
        -- ---------------------------------------------------
        PRINT '--------------------------------------------------';
        PRINT 'Transformando y Cargando Tablas ERP...';
        PRINT '--------------------------------------------------';

        -- Tabla: silver.erp_cust_az12
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: silver.erp_cust_az12';
        TRUNCATE TABLE silver.erp_cust_az12;

        PRINT '>> Insertando datos limpios en: silver.erp_cust_az12';
        INSERT INTO silver.erp_cust_az12 (
            cid,
            bdate,
            gen
        )
        SELECT
            CASE 
                WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LEN(cid))
                ELSE cid
            END AS cid,
            CASE 
                WHEN CAST(bdate AS DATE) > GETDATE() THEN NULL
                ELSE CAST(bdate AS DATE)
            END AS bdate,
            CASE 
                WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
                WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
                ELSE 'n/a'
            END AS gen
        FROM bronze.erp_cust_az12;

        SET @end_time = GETDATE();
        PRINT '>> Duración: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -----------------------------------------------';

        -- Tabla: silver.erp_loc_a101
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: silver.erp_loc_a101';
        TRUNCATE TABLE silver.erp_loc_a101;

        PRINT '>> Insertando datos limpios en: silver.erp_loc_a101';
        INSERT INTO silver.erp_loc_a101 (
            cid,
            cntry
        )
        SELECT
            REPLACE(cid, '-', '') AS cid,
            CASE 
                WHEN TRIM(cntry) = 'DE' THEN 'Germany'
                WHEN TRIM(cntry) IN ('US', 'USA') THEN 'United States'
                WHEN TRIM(cntry) = '' OR cntry IS NULL THEN 'n/a'
                ELSE TRIM(cntry)
            END AS cntry
        FROM bronze.erp_loc_a101;

        SET @end_time = GETDATE();
        PRINT '>> Duración: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -----------------------------------------------';

        -- Tabla: silver.erp_px_cat_g1v2
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: silver.erp_px_cat_g1v2';
        TRUNCATE TABLE silver.erp_px_cat_g1v2;

        PRINT '>> Insertando datos limpios en: silver.erp_px_cat_g1v2';
        INSERT INTO silver.erp_px_cat_g1v2 (
            id,
            cat,
            subcat,
            maintenance
        )
        SELECT
            TRIM(id) AS id,
            TRIM(cat) AS cat,
            TRIM(subcat) AS subcat,
            TRIM(maintenance) AS maintenance
        FROM bronze.erp_px_cat_g1v2;

        SET @end_time = GETDATE();
        PRINT '>> Duración: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -----------------------------------------------';

        SET @batch_end_time = GETDATE();
        PRINT '==================================================';
        PRINT 'Carga de Capa Silver Completada Exitosamente';
        PRINT 'Duración Total: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' segundos';
        PRINT '==================================================';

    END TRY
    BEGIN CATCH
        PRINT '==================================================';
        PRINT 'ERROR OCURRIDO DURANTE LA CARGA DE LA CAPA SILVER';
        PRINT 'Mensaje: ' + ERROR_MESSAGE();
        PRINT 'Número de Error: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Estado: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==================================================';
    END CATCH
END;
GO