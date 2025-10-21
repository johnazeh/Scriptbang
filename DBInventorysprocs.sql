USE [DBA_Inventory]
GO

/****** Object:  StoredProcedure [dbo].[usp_ExportDailyServerReportCSV]    Script Date: 10/21/2025 1:23:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE   PROCEDURE [dbo].[usp_ExportDailyServerReportCSV]
AS
BEGIN
    DECLARE @FilePath NVARCHAR(255) = 'C:\SQLJobs\DailyServerReport.csv';
    DECLARE @BCP NVARCHAR(MAX);

    -- Overwrite the CSV each run
    SET @BCP = 'bcp "SELECT ReportID, ReportDate, TotalDevJobs, TotalDevTables, TotalDevDB, TotalDevDbSize, TotalDevServers,
                         ChangeDevJobs, ChangeDevTables, ChangeDevDB, ChangeDevDbSize, ChangeDevServers
                  FROM DBA_Inventory.dbo.DailyServerReport ORDER BY ReportDate DESC"
                queryout "' + @FilePath + '" -c -t, -T -S ' + @@SERVERNAME;

    EXEC xp_cmdshell @BCP, NO_OUTPUT;
END;
GO

/****** Object:  StoredProcedure [dbo].[usp_UpdateDailyServerReportFull]    Script Date: 10/21/2025 1:23:24 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_UpdateDailyServerReportFull]
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ReportID INT;
    DECLARE @PrevJobs INT, @PrevTables INT, @PrevDB INT, @PrevSize DECIMAL(18,2), @PrevServers INT;
    DECLARE @CurrJobs INT, @CurrTables INT, @CurrDB INT, @CurrSize DECIMAL(18,2), @CurrServers INT;

    -------------------------------------------------------------------
    -- 1️⃣  PREVIOUS REPORT SNAPSHOT
    -------------------------------------------------------------------
    SELECT TOP 1
        @PrevJobs = TotalDevJobs,
        @PrevTables = TotalDevTables,
        @PrevDB = TotalDevDB,
        @PrevSize = TotalDevDbSize,
        @PrevServers = TotalDevServers
    FROM dbo.DailyServerReport
    ORDER BY ReportID DESC;

    -------------------------------------------------------------------
    -- 2️⃣  CURRENT COUNTS (Directly from system views)
    -------------------------------------------------------------------
    SELECT @CurrJobs = COUNT(*) FROM msdb.dbo.sysjobs;

    DECLARE @DBName SYSNAME;
    DECLARE @TotalTables BIGINT = 0;
    DECLARE @TotalSize DECIMAL(18,2) = 0;

    -- Clean up if cursors exist
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
            SELECT @TableCountOUT = COUNT(*) FROM ' + QUOTENAME(@DBName) + '.sys.tables WHERE is_ms_shipped = 0;
            SELECT @DBSizeOUT = ROUND(SUM(size) * 8.0 / 1024 / 1024, 2)
            FROM ' + QUOTENAME(@DBName) + '.sys.database_files;
        ';

        EXEC sp_executesql 
            @SQL,
            N'@TableCountOUT INT OUTPUT, @DBSizeOUT DECIMAL(18,2) OUTPUT',
            @TableCountOUT = @TableCount OUTPUT,
            @DBSizeOUT = @DBSize OUTPUT;

        SET @TotalTables += @TableCount;
        SET @TotalSize += ISNULL(@DBSize,0);

        FETCH NEXT FROM db_cursor2 INTO @DBName;
    END;

    CLOSE db_cursor2;
    DEALLOCATE db_cursor2;

    SET @CurrDB = (SELECT COUNT(*) FROM sys.databases WHERE database_id > 4 AND state_desc = 'ONLINE');
    SET @CurrServers = 1; -- single server context

    -------------------------------------------------------------------
    -- 3️⃣  INSERT INTO DailyServerReport
    -------------------------------------------------------------------
    INSERT INTO dbo.DailyServerReport (
        ReportDate, TotalDevJobs, TotalDevTables, TotalDevDB, TotalDevDbSize, TotalDevServers,
        ChangeDevJobs, ChangeDevTables, ChangeDevDB, ChangeDevDbSize, ChangeDevServers
    )
    SELECT
        SYSDATETIME(),
        @CurrJobs,
        @TotalTables,
        @CurrDB,
        @TotalSize,
        @CurrServers,
        ISNULL(@CurrJobs - @PrevJobs, @CurrJobs),
        ISNULL(@TotalTables - @PrevTables, @TotalTables),
        ISNULL(@CurrDB - @PrevDB, @CurrDB),
        ISNULL(@TotalSize - @PrevSize, @TotalSize),
        ISNULL(@CurrServers - @PrevServers, @CurrServers);

    SET @ReportID = SCOPE_IDENTITY();

    -------------------------------------------------------------------
    -- 4️⃣  CHANGE TRACKING FOR DATABASES, TABLES, JOBS
    -------------------------------------------------------------------
    -- TEMP SNAPSHOTS
    IF OBJECT_ID('tempdb..#PrevDB') IS NOT NULL DROP TABLE #PrevDB;
    IF OBJECT_ID('tempdb..#PrevJobs') IS NOT NULL DROP TABLE #PrevJobs;

    SELECT DatabaseName INTO #PrevDB FROM dbo.DB_Snapshot;
    SELECT JobName INTO #PrevJobs FROM dbo.Job_Snapshot;

    -------------------------------------------------------------------
    -- DB Changes
    -------------------------------------------------------------------
    INSERT INTO dbo.DailyServerChangeLog (ReportID, ChangeType, ObjectName, ObjectType)
    SELECT @ReportID, 'DB Added', d.name, 'Database'
    FROM sys.databases d
    LEFT JOIN #PrevDB p ON d.name = p.DatabaseName
    WHERE p.DatabaseName IS NULL AND d.database_id > 4;

    INSERT INTO dbo.DailyServerChangeLog (ReportID, ChangeType, ObjectName, ObjectType)
    SELECT @ReportID, 'DB Deleted', p.DatabaseName, 'Database'
    FROM #PrevDB p
    LEFT JOIN sys.databases d ON p.DatabaseName = d.name
    WHERE d.name IS NULL;

    -------------------------------------------------------------------
    -- JOB Changes
    -------------------------------------------------------------------
    INSERT INTO dbo.DailyServerChangeLog (ReportID, ChangeType, ObjectName, ObjectType)
    SELECT @ReportID, 'Job Added', j.name, 'Job'
    FROM msdb.dbo.sysjobs j
    LEFT JOIN #PrevJobs p ON j.name = p.JobName
    WHERE p.JobName IS NULL;

    INSERT INTO dbo.DailyServerChangeLog (ReportID, ChangeType, ObjectName, ObjectType)
    SELECT @ReportID, 'Job Deleted', p.JobName, 'Job'
    FROM #PrevJobs p
    LEFT JOIN msdb.dbo.sysjobs j ON p.JobName = j.name
    WHERE j.name IS NULL;

    -------------------------------------------------------------------
    -- 5️⃣  UPDATE SNAPSHOT TABLES
    -------------------------------------------------------------------
    TRUNCATE TABLE dbo.DB_Snapshot;
    INSERT INTO dbo.DB_Snapshot (DatabaseName)
    SELECT name FROM sys.databases WHERE database_id > 4;

    TRUNCATE TABLE dbo.Job_Snapshot;
    INSERT INTO dbo.Job_Snapshot (JobName)
    SELECT name FROM msdb.dbo.sysjobs;

END;
GO


