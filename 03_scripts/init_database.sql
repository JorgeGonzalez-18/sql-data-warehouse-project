/*
=============================================================
Creación de la Base de Datos y Esquemas Medallion
=============================================================
Objetivo:
    Este script inicializa la base de datos 'DataWarehouse'.
    Si ya existe una versión previa, la elimina para garantizar
    un entorno limpio. Luego crea la base de datos y los tres
    esquemas de la arquitectura Medallion:
    - bronze: datos en bruto (sin procesar)
    - silver: datos limpios y estandarizados
    - gold: datos analíticos listos para el negocio
=============================================================
*/

-- Paso 1: Cambiar a la base de datos del sistema 'master'
USE master;
GO

-- Paso 2: Si ya existe 'DataWarehouse', forzar el cierre de conexiones y borrarla
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;
END;
GO

-- Paso 3: Crear la base de datos DataWarehouse desde cero
CREATE DATABASE DataWarehouse;
GO

-- Paso 4: Posicionarse dentro de la nueva base de datos
USE DataWarehouse;
GO

-- Paso 5: Crear los 3 esquemas de la arquitectura Medallion
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO