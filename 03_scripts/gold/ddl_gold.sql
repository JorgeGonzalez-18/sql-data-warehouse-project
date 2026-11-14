/*
=============================================================
DDL Script: Crear Vistas de la Capa Gold (Star Schema)
=============================================================
Objetivo:
    Crea las vistas analíticas en el esquema 'gold' representando
    un modelo dimensional en estrella (Star Schema):
    - gold.dim_customers: Información consolidada de clientes (CRM + ERP).
    - gold.dim_products: Catálogo consolidado de productos (CRM + ERP).
    - gold.fact_sales: Hechos transaccionales de ventas con claves subrogadas.
=============================================================
*/

USE DataWarehouse;
GO

-- -----------------------------------------------------------
-- 1. Dimensión: Clientes (gold.dim_customers)
-- -----------------------------------------------------------
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
    DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
SELECT
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key, -- Clave subrogada
    ci.cst_id                              AS customer_id,  -- Clave natural del sistema origen
    ci.cst_key                             AS customer_number,
    ci.cst_firstname                       AS first_name,
    ci.cst_lastname                        AS last_name,
    COALESCE(la.cntry, 'n/a')              AS country,
    ci.cst_marital_status                  AS marital_status,
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- Prioridad CRM
        ELSE COALESCE(ca.gen, 'n/a')               -- Fallback ERP
    END                                    AS gender,
    ca.bdate                               AS birthdate,
    ci.cst_create_date                     AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
    ON ci.cst_key = la.cid;
GO

-- -----------------------------------------------------------
-- 2. Dimensión: Productos (gold.dim_products)
-- -----------------------------------------------------------
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
    DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
SELECT
    ROW_NUMBER() OVER (ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- Clave subrogada
    pn.prd_id                                                AS product_id,  -- Clave natural
    pn.prd_key                                               AS product_number,
    pn.prd_nm                                                AS product_name,
    pn.cat_id                                                AS category_id,
    COALESCE(pc.cat, 'n/a')                                  AS category,
    COALESCE(pc.subcat, 'n/a')                               AS subcategory,
    COALESCE(pc.maintenance, 'n/a')                          AS maintenance,
    pn.prd_cost                                              AS cost,
    pn.prd_line                                              AS product_line,
    pn.prd_start_dt                                          AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
    ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- Alcance: Solo productos vigentes (datos más recientes)
GO

-- -----------------------------------------------------------
-- 3. Tabla de Hechos: Ventas (gold.fact_sales)
-- -----------------------------------------------------------
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
    DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
SELECT
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,  -- Clave foránea a dim_products
    cu.customer_key AS customer_key, -- Clave foránea a dim_customers
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
    ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
    ON sd.sls_cust_id = cu.customer_id;
GO