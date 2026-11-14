/*
=============================================================
Stored Procedure: Cargar la Capa Bronze (Raw Ingestion)
=============================================================
Objetivo:
    Carga todos los datos sin procesar desde los archivos CSV
    de los orígenes CRM y ERP a sus respectivas tablas en el
    esquema 'bronze'.
    
Estrategia:
    - Truncate & Insert (Carga completa).
    - Monitoreo de tiempos de ejecución por tabla y global.
    - Manejo de excepciones con TRY...CATCH.

Uso:
    EXEC bronze.load_bronze;
=============================================================
*/

USE DataWarehouse;
GO

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
    DECLARE @start_time DATETIME, @end_time DATETIME;
    DECLARE @batch_start_time DATETIME, @batch_end_time DATETIME;

    BEGIN TRY
        SET @batch_start_time = GETDATE();
        PRINT '==================================================';
        PRINT 'Iniciando Carga de la Capa Bronze';
        PRINT '==================================================';

        -- ---------------------------------------------------
        -- 1. SISTEMA ORIGEN: CRM
        -- ---------------------------------------------------
        PRINT '--------------------------------------------------';
        PRINT 'Cargando Tablas de CRM...';
        PRINT '--------------------------------------------------';

        -- Tabla: bronze.crm_cust_info
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: bronze.crm_cust_info';
        TRUNCATE TABLE bronze.crm_cust_info;

        PRINT '>> Insertando datos en: bronze.crm_cust_info';
        BULK INSERT bronze.crm_cust_info
        FROM 'C:\Users\jorge\OneDrive\Escritorio\lII Cuatri\Base de Datos Avanzadas\Ejercicio 07 - ETL Datawarehouse Medallion\sql-data-warehouse-project\01_datasets\source_crm\cust_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -----------------------------------------------';

        -- Tabla: bronze.crm_prd_info
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: bronze.crm_prd_info';
        TRUNCATE TABLE bronze.crm_prd_info;

        PRINT '>> Insertando datos en: bronze.crm_prd_info';
        BULK INSERT bronze.crm_prd_info
        FROM 'C:\Users\jorge\OneDrive\Escritorio\lII Cuatri\Base de Datos Avanzadas\Ejercicio 07 - ETL Datawarehouse Medallion\sql-data-warehouse-project\01_datasets\source_crm\prd_info.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -----------------------------------------------';

        -- Tabla: bronze.crm_sales_details
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: bronze.crm_sales_details';
        TRUNCATE TABLE bronze.crm_sales_details;

        PRINT '>> Insertando datos en: bronze.crm_sales_details';
        BULK INSERT bronze.crm_sales_details
        FROM 'C:\Users\jorge\OneDrive\Escritorio\lII Cuatri\Base de Datos Avanzadas\Ejercicio 07 - ETL Datawarehouse Medallion\sql-data-warehouse-project\01_datasets\source_crm\sales_details.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -----------------------------------------------';

        -- ---------------------------------------------------
        -- 2. SISTEMA ORIGEN: ERP
        -- ---------------------------------------------------
        PRINT '--------------------------------------------------';
        PRINT 'Cargando Tablas de ERP...';
        PRINT '--------------------------------------------------';

        -- Tabla: bronze.erp_cust_az12
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: bronze.erp_cust_az12';
        TRUNCATE TABLE bronze.erp_cust_az12;

        PRINT '>> Insertando datos en: bronze.erp_cust_az12';
        BULK INSERT bronze.erp_cust_az12
        FROM 'C:\Users\jorge\OneDrive\Escritorio\lII Cuatri\Base de Datos Avanzadas\Ejercicio 07 - ETL Datawarehouse Medallion\sql-data-warehouse-project\01_datasets\source_erp\CUST_AZ12.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -----------------------------------------------';

        -- Tabla: bronze.erp_loc_a101
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: bronze.erp_loc_a101';
        TRUNCATE TABLE bronze.erp_loc_a101;

        PRINT '>> Insertando datos en: bronze.erp_loc_a101';
        BULK INSERT bronze.erp_loc_a101
        FROM 'C:\Users\jorge\OneDrive\Escritorio\lII Cuatri\Base de Datos Avanzadas\Ejercicio 07 - ETL Datawarehouse Medallion\sql-data-warehouse-project\01_datasets\source_erp\LOC_A101.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -----------------------------------------------';

        -- Tabla: bronze.erp_px_cat_g1v2
        SET @start_time = GETDATE();
        PRINT '>> Truncando tabla: bronze.erp_px_cat_g1v2';
        TRUNCATE TABLE bronze.erp_px_cat_g1v2;

        PRINT '>> Insertando datos en: bronze.erp_px_cat_g1v2';
        BULK INSERT bronze.erp_px_cat_g1v2
        FROM 'C:\Users\jorge\OneDrive\Escritorio\lII Cuatri\Base de Datos Avanzadas\Ejercicio 07 - ETL Datawarehouse Medallion\sql-data-warehouse-project\01_datasets\source_erp\PX_CAT_G1V2.csv'
        WITH (
            FIRSTROW = 2,
            FIELDTERMINATOR = ',',
            ROWTERMINATOR = '\n',
            TABLOCK
        );
        SET @end_time = GETDATE();
        PRINT '>> Duración: ' + CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + ' segundos';
        PRINT '>> -----------------------------------------------';

        SET @batch_end_time = GETDATE();
        PRINT '==================================================';
        PRINT 'Carga de Capa Bronze Completada Exitosamente';
        PRINT 'Duración Total: ' + CAST(DATEDIFF(second, @batch_start_time, @batch_end_time) AS NVARCHAR) + ' segundos';
        PRINT '==================================================';

    END TRY
    BEGIN CATCH
        PRINT '==================================================';
        PRINT 'ERROR OCURRIDO DURANTE LA CARGA DE LA CAPA BRONZE';
        PRINT 'Mensaje: ' + ERROR_MESSAGE();
        PRINT 'Número de Error: ' + CAST(ERROR_NUMBER() AS NVARCHAR);
        PRINT 'Estado: ' + CAST(ERROR_STATE() AS NVARCHAR);
        PRINT '==================================================';
    END CATCH
END;
GO