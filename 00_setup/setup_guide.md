# **Guía de Configuración y Ejecución**
## **Data Warehouse con Arquitectura Medallion**

Esta guía describe los requisitos previos y el orden cronológico estricto para configurar y ejecutar la base de datos `DataWarehouse` en SQL Server.

---

## **1. Prerrequisitos**
* **Sistema Gestor de Base de Datos:** Microsoft SQL Server 2019 o superior.
* **Herramienta de Administración:** SQL Server Management Studio (SSMS) o Azure Data Studio.
* **Control de Versiones:** Git y cuenta en GitHub.
* **Archivos Fuente:** 6 archivos CSV ubicados en `01_datasets/` (`source_crm/` y `source_erp/`).

---

## **2. Secuencia de Ejecución**

Para desplegar el proyecto completo, abre y ejecuta los scripts en **SQL Server Management Studio (SSMS)** siguiendo este orden estricto:

### **Paso 1: Inicialización de la Base de Datos y Esquemas**
* **Script:** `03_scripts/init_database.sql`
* **Acción:** Crea la base de datos `DataWarehouse` y los esquemas `bronze`, `silver` y `gold`.
* **Resultado:** Base de datos lista y limpia.

---

### **Paso 2: Capa Bronze (Raw Data)**
1. **Crear Tablas Bronze:**
   * **Script:** `03_scripts/bronze/ddl_bronze.sql`
   * **Acción:** Ejecutar para crear las 6 tablas en el esquema `bronze`.
2. **Crear Procedimiento Almacenado de Carga:**
   * **Script:** `03_scripts/bronze/proc_load_bronze.sql`
   * **Acción:** Compilar el procedimiento `bronze.load_bronze`.  
     *(Nota: Si se clona en otra máquina, verificar que las rutas de los archivos CSV en los `BULK INSERT` apunten a la ubicación local correcta).*
3. **Ejecutar Ingesta en Bruto:**
   ```sql
   USE DataWarehouse;
   GO
   EXEC bronze.load_bronze;
   ```

---

### **Paso 3: Capa Silver (Cleaned & Enriched Data)**
1. **Crear Tablas Silver:**
   * **Script:** `03_scripts/silver/ddl_silver.sql`
   * **Acción:** Ejecutar para crear las 6 tablas con tipos de datos estándar y columnas de auditoría `dwh_create_date`.
2. **Crear Procedimiento Almacenado de Transformación:**
   * **Script:** `03_scripts/silver/proc_load_silver.sql`
   * **Acción:** Compilar el procedimiento `silver.load_silver`.
3. **Ejecutar Limpieza y Transformación:**
   ```sql
   USE DataWarehouse;
   GO
   EXEC silver.load_silver;
   ```

---

### **Paso 4: Capa Gold (Star Schema / Vistas Analíticas)**
* **Script:** `03_scripts/gold/ddl_gold.sql`
* **Acción:** Ejecutar para compilar las tres vistas dimensionales:
  * `gold.dim_customers`
  * `gold.dim_products`
  * `gold.fact_sales`

---

### **Paso 5: Validación y Pruebas de Calidad**
1. **Validación de Capa Silver:**
   * **Script:** `04_tests/quality_checks_silver.sql`
   * **Acción:** Verificar que no existan duplicados, espacios residuales ni inconsistencias de cálculo.
2. **Validación de Capa Gold:**
   * **Script:** `04_tests/quality_checks_gold.sql`
   * **Acción:** Comprobar la unicidad de las claves subrogadas y consultar las métricas analíticas globales.