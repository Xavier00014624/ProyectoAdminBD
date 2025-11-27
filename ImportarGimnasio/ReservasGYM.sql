-- =========================================================
-- Proyecto Admin Base de datos
-- =========================================================

DROP DATABASE IF EXISTS ReservasGimnasio;
GO
-- 1. Cracion de BD y esquemas
CREATE DATABASE ReservasGimnasio;
GO

USE ReservasGimnasio;
GO

CREATE SCHEMA gimnasio;
CREATE SCHEMA seguridad;
CREATE SCHEMA auditoria;
CREATE SCHEMA procesos;
GO

-- ============================
-- 2. Tablas principales
-- ============================
CREATE TABLE gimnasio.Socios(
    IdSocio INT IDENTITY(1,1) PRIMARY KEY,
    NumeroMembresia AS ('S' + RIGHT('00000' + CAST(IdSocio AS VARCHAR(5)),5)) PERSISTED,
    Nombres NVARCHAR(100) NOT NULL,
    Apellidos NVARCHAR(100) NOT NULL,
    Correo NVARCHAR(200) UNIQUE,
    Telefono NVARCHAR(20),
    FechaNacimiento DATE,
    Genero CHAR(1),
    FechaIngreso DATETIME2 DEFAULT SYSUTCDATETIME(),
    Estado TINYINT NOT NULL DEFAULT 1 -- 1 = Activo, 0 = Inactivo
);
GO

CREATE TABLE gimnasio.Entrenadores(
    IdEntrenador INT IDENTITY(1,1) PRIMARY KEY,
    Nombres NVARCHAR(100) NOT NULL,
    Apellidos NVARCHAR(100) NOT NULL,
    Especialidad NVARCHAR(150),
    FechaContratacion DATE,
    Correo NVARCHAR(200) UNIQUE,
    Telefono NVARCHAR(20),
    Activo BIT DEFAULT 1
);
GO

CREATE TABLE gimnasio.Clases(
    IdClase INT IDENTITY(1,1) PRIMARY KEY,
    NombreClase NVARCHAR(150) NOT NULL,
    Descripcion NVARCHAR(500),
    Cupo INT NOT NULL CHECK (Cupo > 0),
    Nivel NVARCHAR(50)
);
GO

CREATE TABLE gimnasio.Horarios(
    IdHorario INT IDENTITY(1,1) PRIMARY KEY,
    IdClase INT NOT NULL REFERENCES gimnasio.Clases(IdClase),
    IdEntrenador INT NOT NULL REFERENCES gimnasio.Entrenadores(IdEntrenador),
    Inicio DATETIME2 NOT NULL,
    Fin DATETIME2 NOT NULL,
    Ubicacion NVARCHAR(200),
    CONSTRAINT CHK_Horario_Fechas CHECK (Fin > Inicio)
);
GO

CREATE TABLE gimnasio.Inscripciones(
    IdInscripcion INT IDENTITY(1,1) PRIMARY KEY,
    IdHorario INT NOT NULL REFERENCES gimnasio.Horarios(IdHorario),
    IdSocio INT NOT NULL REFERENCES gimnasio.Socios(IdSocio),
    FechaInscrito DATETIME2 DEFAULT SYSUTCDATETIME(),
    Estado NVARCHAR(20) DEFAULT 'Inscrito',
    CONSTRAINT UQ_Inscripcion UNIQUE (IdHorario, IdSocio)
);
GO

CREATE TABLE gimnasio.Pagos(
    IdPago INT IDENTITY(1,1) PRIMARY KEY,
    IdSocio INT NOT NULL REFERENCES gimnasio.Socios(IdSocio),
    Monto DECIMAL(10,2) NOT NULL CHECK (Monto >= 0),
    FechaPago DATETIME2 DEFAULT SYSUTCDATETIME(),
    MetodoPago NVARCHAR(50),
    Referencia NVARCHAR(200)
);
GO

-- ============================
-- 3. Auditor�a y logs
-- ============================
CREATE TABLE auditoria.LogSocios (
    IdLog INT IDENTITY(1,1) PRIMARY KEY,
    IdSocio INT NULL,
    Operacion NVARCHAR(20),
    UsuarioEjecutor NVARCHAR(200),
    Fecha DATETIME2 DEFAULT SYSUTCDATETIME(),
    Detalle NVARCHAR(1000) NULL
);
GO

CREATE TABLE auditoria.LogGeneral (
    IdLog INT IDENTITY(1,1) PRIMARY KEY,
    Esquema NVARCHAR(50),
    Tabla NVARCHAR(100),
    PK_Valor NVARCHAR(200),
    Operacion NVARCHAR(20),
    UsuarioEjecutor NVARCHAR(200),
    Fecha DATETIME2 DEFAULT SYSUTCDATETIME(),
    Detalle NVARCHAR(MAX)
);
GO

-- Trigger para INSERT en Socios 
CREATE TRIGGER gimnasio.trg_InsertSocios
ON gimnasio.Socios
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO auditoria.LogSocios(IdSocio, Operacion, UsuarioEjecutor)
    SELECT i.IdSocio, 'INSERT', SUSER_SNAME()
    FROM inserted i;
END;
GO


-- Trigger general para INSERT/UPDATE/DELETE (gen�rico) sobre tablas cr�ticas
-- (Aqu� se aplica solo a pagos como ejemplo;)
CREATE TRIGGER gimnasio.trg_Pagos_CUD
ON gimnasio.Pagos
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @usuario NVARCHAR(200) = SUSER_SNAME();

    -- INSERT o UPDATE (inserted existe en ambos casos)
    IF EXISTS (SELECT 1 FROM inserted)
    BEGIN
        INSERT INTO auditoria.LogGeneral
            (Esquema, Tabla, PK_Valor, Operacion, UsuarioEjecutor, Detalle)
        SELECT 
            'gimnasio',
            'Pagos',
            CAST(i.IdPago AS NVARCHAR(50)),
            CASE 
                WHEN EXISTS (SELECT 1 FROM deleted WHERE IdPago = i.IdPago) THEN 'UPDATE'
                ELSE 'INSERT'
            END,
            @usuario,
            'Cambio desde trigger'
        FROM inserted i;
    END

    -- DELETE
    IF EXISTS (SELECT 1 FROM deleted)
    BEGIN
        INSERT INTO auditoria.LogGeneral
            (Esquema, Tabla, PK_Valor, Operacion, UsuarioEjecutor, Detalle)
        SELECT 
            'gimnasio',
            'Pagos',
            CAST(d.IdPago AS NVARCHAR(50)),
            'DELETE',
            @usuario,
            'Delete desde trigger'
        FROM deleted d;
    END
END;
GO


-- ============================
-- 4. Roles, usuarios y permisos
-- ============================
CREATE ROLE db_gym_admin;
CREATE ROLE db_gym_reception;
CREATE ROLE db_gym_trainer;
CREATE ROLE db_gym_reporting;
GO

-- -- Creacion logins / usuarios 
CREATE LOGIN adminUser WITH PASSWORD = 'AdminPass123!';
CREATE USER adminUser FOR LOGIN adminUser;
EXEC sp_addrolemember 'db_gym_admin', 'adminUser';

CREATE LOGIN recepUser WITH PASSWORD = 'RecepPass123!';
CREATE USER recepUser FOR LOGIN recepUser;
EXEC sp_addrolemember 'db_gym_reception', 'recepUser';

CREATE LOGIN trainerUser WITH PASSWORD = 'TrainerPass123!';
CREATE USER trainerUser FOR LOGIN trainerUser;
EXEC sp_addrolemember 'db_gym_trainer', 'trainerUser';

CREATE LOGIN reportUser WITH PASSWORD = 'ReportPass123!';
CREATE USER reportUser FOR LOGIN reportUser;
EXEC sp_addrolemember 'db_gym_reporting', 'reportUser';
GO

-- Permisos por rol
GRANT CONTROL ON SCHEMA::gimnasio TO db_gym_admin;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA::gimnasio TO db_gym_reception;
GRANT SELECT ON SCHEMA::gimnasio TO db_gym_trainer;
GRANT EXECUTE ON SCHEMA::gimnasio TO db_gym_reporting;
GO

-- ============================
-- 5. �ndices 
-- ============================
CREATE INDEX idx_entrenadores_correo ON gimnasio.Entrenadores(Correo);
CREATE INDEX idx_horarios_idclase ON gimnasio.Horarios(IdClase);
CREATE INDEX idx_inscripciones_horario_socio ON gimnasio.Inscripciones(IdHorario, IdSocio);
CREATE INDEX idx_socios_activos ON gimnasio.Socios(Estado) WHERE Estado = 1;
CREATE INDEX idx_pagos_fecha ON gimnasio.Pagos(FechaPago);
GO

-- ============================
-- 6. Vistas y consultas �tiles (para reporting / Power BI)
-- ============================
-- Vista: Resumen de pagos por socio
CREATE VIEW procesos.vw_PagosResumenPorSocio
AS
SELECT 
    s.IdSocio,
    s.NumeroMembresia,
    s.Nombres + ' ' + s.Apellidos AS NombreCompleto,
    SUM(p.Monto) AS TotalPagado,
    COUNT(p.IdPago) AS CantidadPagos,
    AVG(p.Monto) AS PromedioPago
FROM gimnasio.Socios s
LEFT JOIN gimnasio.Pagos p ON s.IdSocio = p.IdSocio
GROUP BY s.IdSocio, s.NumeroMembresia, s.Nombres, s.Apellidos;
GO

-- ============================
-- 7. Consultas avanzadas / funciones ventana 
-- ============================

-- 1) Ranking de entrenadores por n�mero de clases
SELECT 
    e.IdEntrenador,
    e.Nombres,
    e.Apellidos,
    COUNT(h.IdClase) AS TotalClases,
    RANK() OVER (ORDER BY COUNT(h.IdClase) DESC) AS Ranking
FROM gimnasio.Entrenadores e
LEFT JOIN gimnasio.Horarios h ON e.IdEntrenador = h.IdEntrenador
GROUP BY e.IdEntrenador, e.Nombres, e.Apellidos;
GO

-- 2) Promedio m�vil (3 pagos window) por socio
SELECT
    p.IdPago,
    p.IdSocio,
    p.Monto,
    p.FechaPago,
    AVG(p.Monto) OVER (
        PARTITION BY p.IdSocio 
        ORDER BY p.FechaPago 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS PromedioMovil3
FROM gimnasio.Pagos p;
GO

-- 3) Promedio por socio con ventana (sin agregaci�n previa)
SELECT 
    p.IdSocio,
    SUM(p.Monto) OVER (PARTITION BY p.IdSocio) AS TotalPorSocio,
    AVG(p.Monto) OVER (PARTITION BY p.IdSocio) AS PromedioPorSocio
FROM gimnasio.Pagos p;
GO

-- ============================
-- 8. Carga masiva (BULK INSERT) - actualizar rutas seg�n servidor
-- ============================

BULK INSERT gimnasio.Socios
FROM 'C:\ImportarGimnasio\socios.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001', TABLOCK);
GO

BULK INSERT gimnasio.Entrenadores
FROM 'C:\ImportarGimnasio\entrenadores.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001', TABLOCK);
GO

BULK INSERT gimnasio.Clases
FROM 'C:\ImportarGimnasio\clases.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001', TABLOCK);
GO

BULK INSERT gimnasio.Horarios
FROM 'C:\ImportarGimnasio\horarios.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001', TABLOCK);
GO

BULK INSERT gimnasio.Inscripciones
FROM 'C:\ImportarGimnasio\inscripciones.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001', TABLOCK);
GO

BULK INSERT gimnasio.Pagos
FROM 'C:\ImportarGimnasio\pagos.csv'
WITH (FIRSTROW = 2, FIELDTERMINATOR = ',', ROWTERMINATOR = '\n', CODEPAGE = '65001', TABLOCK);
GO

-- ============================
-- 9. Consultas de verificaci�n r�pida
-- ============================
SELECT TOP 10 * FROM gimnasio.Socios;
SELECT COUNT(*) AS TotalEntrenadores FROM gimnasio.Entrenadores;
SELECT COUNT(*) AS TotalClases FROM gimnasio.Clases;
GO

-- ============================
-- 10. Dimensionamiento y proyecciones (c�lculos estimativos)
-- ============================
-- Tama�o actual por tabla (KB/MB)
SELECT 
    t.name AS Tabla,
    SUM(p.row_count) AS Filas,
    SUM(a.total_pages)*8 AS KB_Usados,
    (SUM(a.total_pages)*8)/1024.0 AS MB_Usados
FROM sys.tables t
JOIN sys.dm_db_partition_stats p ON t.object_id = p.object_id
JOIN sys.allocation_units a ON p.partition_id = a.container_id
GROUP BY t.name
ORDER BY MB_Usados DESC;
GO

-- Proyecci�n simple anual 
SELECT 
    'Socios' AS Tabla,
    COUNT(*) AS FilasActual,
    COUNT(*) * 12 AS ProyeccionAnual -- si entra la misma cantidad por mes
FROM gimnasio.Socios;
GO

-- ============================
-- 11. Backups (ejecutar con paths del servidor)
-- ============================
-- Backup FULL diario (ejecutar desde SQL Agent o manual)
BACKUP DATABASE ReservasGimnasio
TO DISK = 'C:\Backups\ReservasGimnasio_FULL.bak'
WITH INIT, COMPRESSION;
GO

-- Backup diferencial (ej: cada 6 horas)
BACKUP DATABASE ReservasGimnasio
TO DISK = 'C:\Backups\ReservasGimnasio_DIFF.bak'
WITH DIFFERENTIAL, COMPRESSION;
GO

-- Backup de logs (ej: cada 15 min)
BACKUP LOG ReservasGimnasio
TO DISK = 'C:\Backups\ReservasGimnasio_LOG.trn';
GO

-- ============================
-- 12. Jobs de SQL Agent 
-- ============================
-- Estos procedimientos deben ejecutarse en msdb; si ejecutas desde la base ReservasGimnasio
-- anteponer msdb.dbo.sp_add_job... con permisos suficientes.

-- JOB: Backup FULL diario 02:00
USE msdb;
GO
EXEC sp_add_job @job_name = 'JOB_BackupFull_ReservasGimnasio', @enabled = 1, @description = 'Backup FULL diario';
EXEC sp_add_jobstep @job_name = 'JOB_BackupFull_ReservasGimnasio',
    @step_name = 'BackupFull',
    @subsystem = 'TSQL',
    @command = N'BACKUP DATABASE ReservasGimnasio TO DISK = ''C:\Backups\ReservasGimnasio_FULL.bak'' WITH INIT, COMPRESSION;';

EXEC sp_add_jobschedule @job_name = 'JOB_BackupFull_ReservasGimnasio', 
    @name = 'ScheduleDaily0200', @freq_type = 4, @freq_interval = 1, @active_start_time = 020000;
EXEC sp_add_jobserver @job_name = 'JOB_BackupFull_ReservasGimnasio';
GO

-- JOB: Backup LOG cada 15 minutos
EXEC sp_add_job @job_name = 'JOB_BackupLog_ReservasGimnasio', @enabled = 1, @description = 'Backup LOG cada 15 min';
EXEC sp_add_jobstep @job_name = 'JOB_BackupLog_ReservasGimnasio',
    @step_name = 'BackupLog',
    @subsystem = 'TSQL',
    @command = N'BACKUP LOG ReservasGimnasio TO DISK = ''C:\Backups\ReservasGimnasio_LOG.trn'' WITH NOFORMAT, INIT, NAME = ''LogBackup'';';

EXEC sp_add_jobschedule @job_name = 'JOB_BackupLog_ReservasGimnasio',
    @name = 'ScheduleEvery15Min', @freq_type = 4, @freq_interval = 1, @freq_subday_type = 4, @freq_subday_interval = 15, @active_start_time = 000000;
EXEC sp_add_jobserver @job_name = 'JOB_BackupLog_ReservasGimnasio';
GO

-- Volver al contexto de la BD
USE ReservasGimnasio;
GO

-- ============================
-- 13. Restauraci�n 
-- ============================
-- Ejecutar en caso de desastre (ajusta rutas)
-- RESTORE DATABASE ReservasGimnasio FROM DISK = 'C:\Backups\ReservasGimnasio_FULL.bak' WITH NORECOVERY;
-- RESTORE DATABASE ReservasGimnasio FROM DISK = 'C:\Backups\ReservasGimnasio_DIFF.bak' WITH NORECOVERY;
-- RESTORE LOG ReservasGimnasio FROM DISK = 'C:\Backups\ReservasGimnasio_LOG.trn' WITH RECOVERY;

-- ============================
-- 14. Mantenimiento de �ndices / estad�sticas
-- ============================
-- Rebuild �ndices 
ALTER INDEX ALL ON gimnasio.Pagos REBUILD;
ALTER INDEX ALL ON gimnasio.Inscripciones REBUILD;
ALTER INDEX ALL ON gimnasio.Horarios REBUILD;
GO

-- ============================
-- 15. Verificaciones
-- ============================
INSERT INTO gimnasio.Socios (Nombres, Apellidos, Correo) VALUES ('Prueba', 'Usuario', 'prueba@dominio.test');
SELECT * FROM auditoria.LogSocios;
--
--Probar triggers CUD en pagos
--
INSERT INTO gimnasio.Pagos (IdSocio, Monto, MetodoPago) VALUES (1, 25.00, 'Efectivo');
SELECT TOP 10 * FROM auditoria.LogGeneral ORDER BY Fecha DESC;
--
--Probar Indicies
--
SET STATISTICS IO ON
SET STATISTICS TIME ON;
SELECT *
FROM gimnasio.Entrenadores
WHERE Correo = 'Casper_Reichel@yahoo.com';

SELECT *
FROM gimnasio.Horarios
WHERE IdClase = 10;


SELECT *
FROM gimnasio.Inscripciones
WHERE IdHorario = 286 AND IdSocio = 99;


UPDATE STATISTICS gimnasio.Socios WITH FULLSCAN;
UPDATE STATISTICS gimnasio.Socios(idx_socios_activos) WITH FULLSCAN;

SELECT IdSocio, Estado
FROM gimnasio.Socios
WHERE Estado = 1;

SELECT *
FROM gimnasio.Pagos
WHERE FechaPago >= '2025-11-18'
  AND FechaPago <  '2025-11-19';

-- ============================
-- Fin 
-- ============================
