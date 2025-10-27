USE [DBA_Inventory]
GO

/****** Object:  StoredProcedure [dbo].[usp_UpdateDailyServerReportFull]    Script Date: 10/27/2025 11:52:33 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_UpdateDailyServerReportFull]
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

    -------------------------------------------------------------------
    -- 0️⃣  DECLARE VARIABLES
    -------------------------------------------------------------------
    DECLARE @ReportID INT;
    DECLARE @PrevJobs INT, @PrevTables BIGINT, @PrevDB INT, @PrevSize DECIMAL(18,2), @PrevServers INT, @PrevDisk DECIMAL(18,2);
    DECLARE @CurrJobs INT, @CurrTables BIGINT, @CurrDB INT, @CurrSize DECIMAL(18,2), @CurrServers INT, @CurrDisk DECIMAL(18,2);

    -------------------------------------------------------------------
    -- 1️⃣  PREVIOUS REPORT SNAPSHOT
    -------------------------------------------------------------------
    SELECT TOP 1
        @PrevJobs = TotalDevJobs,
        @PrevTables = TotalDevTables,
        @PrevDB = TotalDevDB,
        @PrevSize = TotalDevDbSize,
        @PrevServers = TotalDevServers,
        @PrevDisk = TotalDevDiskSize
    FROM dbo.DailyServerReport
    ORDER BY ReportID DESC;

    -------------------------------------------------------------------
    -- 2️⃣  CURRENT COUNTS
    -------------------------------------------------------------------
    -- Jobs
    SELECT @CurrJobs = COUNT(*) FROM msdb.dbo.sysjobs;

    -- Databases & Tables & DB Size
    DECLARE @DBName SYSNAME;
    SET @CurrTables = 0;
    SET @CurrSize = 0;

    IF CURSOR_STATUS('global', 'db_cursor2') >= -1
    BEGIN
        CLOSE db_cursor2;
        DEALLOCATE db_cursor2;
    END;

    DECLARE db_cursor2 CURSOR LOCAL FAST_FORWARD FOR
        SELECT name FROM sys.databases WHERE database_id > 4 AND state_desc = 'ONLINE';

    OPEN db_cursor2;
    FETCH NEXT FROM db_cursor2 INTO @DBName;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @SQL NVARCHAR(MAX);
        DECLARE @TableCount INT = 0;
        DECLARE @DBSize DECIMAL(18,2) = 0;

        SET @SQL = '
            SELECT @TableCountOUT = COUNT(*) 
            FROM ' + QUOTENAME(@DBName) + '.sys.tables 
            WHERE is_ms_shipped = 0;

            SELECT @DBSizeOUT = ROUND(SUM(size) * 8.0 / 1024 / 1024, 2)
            FROM ' + QUOTENAME(@DBName) + '.sys.database_files;
        ';

        EXEC sp_executesql 
            @SQL,
            N'@TableCountOUT INT OUTPUT, @DBSizeOUT DECIMAL(18,2) OUTPUT',
            @TableCountOUT = @TableCount OUTPUT,
            @DBSizeOUT = @DBSize OUTPUT;

        SET @CurrTables += @TableCount;
        SET @CurrSize += ISNULL(@DBSize,0);

        FETCH NEXT FROM db_cursor2 INTO @DBName;
    END;

    CLOSE db_cursor2;
    DEALLOCATE db_cursor2;

    -- DB Count and Server Count
    SET @CurrDB = (SELECT COUNT(*) FROM sys.databases WHERE database_id > 4 AND state_desc = 'ONLINE');
    SET @CurrServers = 1;

    -------------------------------------------------------------------
    -- 3️⃣  CURRENT DISK SPACE (Drive E)
    -------------------------------------------------------------------
    IF OBJECT_ID('tempdb..#Disk') IS NOT NULL DROP TABLE #Disk;

    CREATE TABLE #Disk (Drive CHAR(1), MB_Free INT);
    INSERT INTO #Disk EXEC xp_fixeddrives;

    SELECT @CurrDisk = CAST(MB_Free / 1024.0 AS DECIMAL(18,2)) FROM #Disk WHERE Drive = 'E';
    DROP TABLE #Disk;

    -------------------------------------------------------------------
    -- 4️⃣  INSERT INTO DailyServerReport
    -------------------------------------------------------------------
    INSERT INTO dbo.DailyServerReport (
        ReportDate, TotalDevJobs, TotalDevTables, TotalDevDB, TotalDevDbSize, TotalDevServers, TotalDevDiskSize,
        ChangeDevJobs, ChangeDevTables, ChangeDevDB, ChangeDevDbSize, ChangeDevServers, ChangeDevDiskSize
    )
    SELECT
        SYSDATETIME(),
        @CurrJobs,
        @CurrTables,
        @CurrDB,
        @CurrSize,
        @CurrServers,
        @CurrDisk,
        ISNULL(@CurrJobs - @PrevJobs, @CurrJobs),
        ISNULL(@CurrTables - @PrevTables, @CurrTables),
        ISNULL(@CurrDB - @PrevDB, @CurrDB),
        ISNULL(@CurrSize - @PrevSize, @CurrSize),
        ISNULL(@CurrServers - @PrevServers, @CurrServers),
        ISNULL(@CurrDisk - @PrevDisk, @CurrDisk);

    SET @ReportID = SCOPE_IDENTITY();

    -------------------------------------------------------------------
    -- 5️⃣  CHANGE TRACKING: DATABASES, JOBS, TABLES, DISK
    -------------------------------------------------------------------
    -- Temp Snapshots
    IF OBJECT_ID('tempdb..#PrevDB') IS NOT NULL DROP TABLE #PrevDB;
    IF OBJECT_ID('tempdb..#PrevJobs') IS NOT NULL DROP TABLE #PrevJobs;
    IF OBJECT_ID('tempdb..#PrevDisk') IS NOT NULL DROP TABLE #PrevDisk;
    IF OBJECT_ID('tempdb..#PrevTables') IS NOT NULL DROP TABLE #PrevTables;

    SELECT DatabaseName INTO #PrevDB FROM dbo.DB_Snapshot;
    SELECT JobName INTO #PrevJobs FROM dbo.Job_Snapshot;
    SELECT Drive, MB_Free INTO #PrevDisk FROM dbo.Disk_Snapshot;
    SELECT TableName, DatabaseName INTO #PrevTables FROM dbo.Table_Snapshot;

    -- Database Changes
    INSERT INTO dbo.DailyServerChangeLog (ReportID, ChangeType, ObjectName, ObjectType, ChangeDate)
    SELECT @ReportID, 'DB Added', d.name, 'Database', SYSDATETIME()
    FROM sys.databases d
    LEFT JOIN #PrevDB p ON d.name = p.DatabaseName
    WHERE p.DatabaseName IS NULL AND d.database_id > 4;

    INSERT INTO dbo.DailyServerChangeLog (ReportID, ChangeType, ObjectName, ObjectType, ChangeDate)
    SELECT @ReportID, 'DB Deleted', p.DatabaseName, 'Database', SYSDATETIME()
    FROM #PrevDB p
    LEFT JOIN sys.databases d ON p.DatabaseName = d.name
    WHERE d.name IS NULL;

    -- Job Changes
    INSERT INTO dbo.DailyServerChangeLog (ReportID, ChangeType, ObjectName, ObjectType, ChangeDate)
    SELECT @ReportID, 'Job Added', j.name, 'Job', SYSDATETIME()
    FROM msdb.dbo.sysjobs j
    LEFT JOIN #PrevJobs p ON j.name = p.JobName
    WHERE p.JobName IS NULL;

    INSERT INTO dbo.DailyServerChangeLog (ReportID, ChangeType, ObjectName, ObjectType, ChangeDate)
    SELECT @ReportID, 'Job Deleted', p.JobName, 'Job', SYSDATETIME()
    FROM #PrevJobs p
    LEFT JOIN msdb.dbo.sysjobs j ON p.JobName = j.name
    WHERE j.name IS NULL;

    -- Table Changes (Cross-Database) with COLLATE fix
    DECLARE @tblDB SYSNAME;
    DECLARE tbl_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT name FROM sys.databases WHERE database_id > 4 AND state_desc = 'ONLINE';

    OPEN tbl_cursor;
    FETCH NEXT FROM tbl_cursor INTO @tblDB;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        DECLARE @tblSQL NVARCHAR(MAX);

        SET @tblSQL = '
            INSERT INTO dbo.DailyServerChangeLog (ReportID, ChangeType, ObjectName, ObjectType, ChangeDate)
            SELECT ' + CAST(@ReportID AS NVARCHAR(10)) + ',
                   ''Table Added'',
                   t.name,
                   ''Table'',
                   SYSDATETIME()
            FROM ' + QUOTENAME(@tblDB) + '.sys.tables t
            LEFT JOIN #PrevTables p 
                ON t.name COLLATE SQL_Latin1_General_CP1_CI_AS = p.TableName COLLATE SQL_Latin1_General_CP1_CI_AS
               AND ''' + @tblDB + ''' COLLATE SQL_Latin1_General_CP1_CI_AS = p.DatabaseName COLLATE SQL_Latin1_General_CP1_CI_AS
            WHERE t.is_ms_shipped = 0
              AND p.TableName IS NULL;

            INSERT INTO dbo.DailyServerChangeLog (ReportID, ChangeType, ObjectName, ObjectType, ChangeDate)
            SELECT ' + CAST(@ReportID AS NVARCHAR(10)) + ',
                   ''Table Deleted'',
                   p.TableName,
                   ''Table'',
                   SYSDATETIME()
            FROM #PrevTables p
            WHERE p.DatabaseName COLLATE SQL_Latin1_General_CP1_CI_AS = ''' + @tblDB + ''' COLLATE SQL_Latin1_General_CP1_CI_AS
              AND NOT EXISTS (
                  SELECT 1 
                  FROM ' + QUOTENAME(@tblDB) + '.sys.tables t
                  WHERE t.name COLLATE SQL_Latin1_General_CP1_CI_AS = p.TableName COLLATE SQL_Latin1_General_CP1_CI_AS
              );
        ';

        EXEC sp_executesql @tblSQL;
        FETCH NEXT FROM tbl_cursor INTO @tblDB;
    END;

    CLOSE tbl_cursor;
    DEALLOCATE tbl_cursor;

    -- Disk Changes (Drive E)
    INSERT INTO dbo.DailyServerChangeLog (ReportID, ChangeType, ObjectName, ObjectType, ChangeDate)
    SELECT @ReportID, 
           CASE 
               WHEN p.MB_Free IS NULL THEN 'Disk Added'
               WHEN @CurrDisk < p.MB_Free THEN 'Disk Space Decreased'
END,
           'Drive E',
           'Disk',
           SYSDATETIME()
    FROM #PrevDisk p
    WHERE p.Drive = 'E';

    -------------------------------------------------------------------
    -- 6️⃣  UPDATE SNAPSHOT TABLES
    -------------------------------------------------------------------
    TRUNCATE TABLE dbo.DB_Snapshot;
    INSERT INTO dbo.DB_Snapshot (DatabaseName)
    SELECT name FROM sys.databases WHERE database_id > 4;

    TRUNCATE TABLE dbo.Job_Snapshot;
    INSERT INTO dbo.Job_Snapshot (JobName)
    SELECT name FROM msdb.dbo.sysjobs;

    TRUNCATE TABLE dbo.Table_Snapshot;
    INSERT INTO dbo.Table_Snapshot (TableName, DatabaseName)
    SELECT t.name, DB_NAME()
    FROM sys.tables t
    WHERE t.is_ms_shipped = 0;

    TRUNCATE TABLE dbo.Disk_Snapshot;
    INSERT INTO dbo.Disk_Snapshot (Drive, MB_Free)
    VALUES ('E', @CurrDisk);

    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR('Error in usp_UpdateDailyServerReportFull: %s', 16, 1, @ErrMsg);
    END CATCH

END;
GO


