USE [DBA_Inventory]
GO

/****** Object:  Table [dbo].[DailyServerChangeLog]    Script Date: 10/21/2025 1:21:34 PM ******/
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

/****** Object:  Table [dbo].[DailyServerReport]    Script Date: 10/21/2025 1:21:34 PM ******/
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
PRIMARY KEY CLUSTERED 
(
	[ReportID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

/****** Object:  Table [dbo].[DB_Snapshot]    Script Date: 10/21/2025 1:21:34 PM ******/
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

/****** Object:  Table [dbo].[Job_Snapshot]    Script Date: 10/21/2025 1:21:34 PM ******/
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

ALTER TABLE [dbo].[DailyServerChangeLog] ADD  DEFAULT (sysdatetime()) FOR [ChangeDate]
GO

ALTER TABLE [dbo].[DailyServerReport] ADD  DEFAULT (sysdatetime()) FOR [ReportDate]
GO

ALTER TABLE [dbo].[DB_Snapshot] ADD  DEFAULT (sysdatetime()) FOR [CollectionDate]
GO

ALTER TABLE [dbo].[Job_Snapshot] ADD  DEFAULT (sysdatetime()) FOR [CollectionDate]
GO


