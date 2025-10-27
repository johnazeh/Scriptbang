USE [DBA_Inventory]
GO

/****** Object:  Table [dbo].[DailyServerChangeLog]    Script Date: 10/27/2025 11:47:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DailyServerChangeLog](
	[ChangeID] [int] IDENTITY(1,1) NOT NULL,
	[ReportID] [int] NULL,
	[ChangeType] [nvarchar](20) NULL,
	[ObjectName] [nvarchar](128) NULL,
	[ObjectType] [nvarchar](20) NULL,
	[ChangeValue] [decimal](18, 2) NULL,
	[ChangeDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[ChangeID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[DailyServerReport]    Script Date: 10/27/2025 11:47:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DailyServerReport](
	[ReportID] [int] IDENTITY(1,1) NOT NULL,
	[ReportDate] [datetime] NULL,
	[TotalDevJobs] [int] NULL,
	[TotalDevTables] [int] NULL,
	[TotalDevDB] [int] NULL,
	[TotalDevDbSize] [decimal](18, 2) NULL,
	[TotalDevServers] [int] NULL,
	[ChangeDevJobs] [int] NULL,
	[ChangeDevTables] [int] NULL,
	[ChangeDevDB] [int] NULL,
	[ChangeDevDbSize] [decimal](18, 2) NULL,
	[ChangeDevServers] [int] NULL,
	[TotalDevDisksize] [decimal](18, 2) NULL,
	[ChangeDevDisksize] [decimal](18, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[ReportID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[DatabaseInfo]    Script Date: 10/27/2025 11:47:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DatabaseInfo](
	[DatabaseName] [nvarchar](128) NULL,
	[ServerName] [nvarchar](128) NULL,
	[TableCount] [int] NULL,
	[SizeGB] [decimal](18, 2) NULL,
	[GrowthPercent] [decimal](6, 2) NULL,
	[CollectionDate] [datetime2](7) NULL,
	[DatabaseNum] [int] NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[DB_Snapshot]    Script Date: 10/27/2025 11:47:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[DB_Snapshot](
	[DatabaseName] [nvarchar](128) NOT NULL,
	[CollectionDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[DatabaseName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Disk_Snapshot]    Script Date: 10/27/2025 11:47:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Disk_Snapshot](
	[Drive] [char](1) NOT NULL,
	[MB_Free] [decimal](18, 2) NULL,
PRIMARY KEY CLUSTERED 
(
	[Drive] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Job_Snapshot]    Script Date: 10/27/2025 11:47:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Job_Snapshot](
	[JobName] [nvarchar](128) NOT NULL,
	[CollectionDate] [datetime] NULL,
PRIMARY KEY CLUSTERED 
(
	[JobName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[JobInfo]    Script Date: 10/27/2025 11:47:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[JobInfo](
	[ServerName] [nvarchar](128) NULL,
	[JobName] [nvarchar](256) NULL,
	[IsEnabled] [bit] NULL,
	[CollectionDate] [datetime2](7) NULL,
	[JOBNUMBER] [int] NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ServerDiskUsage]    Script Date: 10/27/2025 11:47:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ServerDiskUsage](
	[ServerDiskUsageID] [int] IDENTITY(1,1) NOT NULL,
	[ServerName] [nvarchar](128) NOT NULL,
	[Drive] [char](1) NOT NULL,
	[TotalSizeTB] [decimal](10, 2) NOT NULL,
	[FreeGB] [decimal](10, 2) NOT NULL,
	[FreePercent] [decimal](5, 2) NULL,
	[CollectionDate] [datetime2](7) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[ServerDiskUsageID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[ServerInfo]    Script Date: 10/27/2025 11:47:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ServerInfo](
	[ServerName] [nvarchar](128) NULL,
	[SQLVersion] [nvarchar](128) NULL,
	[Edition] [nvarchar](128) NULL,
	[EngineEdition] [nvarchar](50) NULL,
	[CollectionDate] [datetime2](7) NULL,
	[AGStatus] [nvarchar](50) NULL,
	[ServerNum] [int] NULL
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[Table_Snapshot]    Script Date: 10/27/2025 11:47:10 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Table_Snapshot](
	[TableName] [nvarchar](256) NOT NULL,
	[DatabaseName] [nvarchar](256) NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[TableName] ASC,
	[DatabaseName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[DailyServerChangeLog] ADD  DEFAULT (sysdatetime()) FOR [ChangeDate]
GO

ALTER TABLE [dbo].[DailyServerReport] ADD  DEFAULT (sysdatetime()) FOR [ReportDate]
GO

ALTER TABLE [dbo].[DatabaseInfo] ADD  DEFAULT (sysdatetime()) FOR [CollectionDate]
GO

ALTER TABLE [dbo].[DB_Snapshot] ADD  DEFAULT (sysdatetime()) FOR [CollectionDate]
GO

ALTER TABLE [dbo].[Job_Snapshot] ADD  DEFAULT (sysdatetime()) FOR [CollectionDate]
GO

ALTER TABLE [dbo].[JobInfo] ADD  DEFAULT (sysdatetime()) FOR [CollectionDate]
GO

ALTER TABLE [dbo].[ServerInfo] ADD  DEFAULT (sysdatetime()) FOR [CollectionDate]
GO



