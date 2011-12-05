USE [KnightRider]
GO

/****** Object:  Table [dbo].[Place]    Script Date: 12/04/2011 17:28:30 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[Place](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[GID] [char](40) NOT NULL,
	[GTypes] [varchar](100) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[Latitude] [float] NOT NULL,
	[Longitude] [float] NOT NULL,
	[Vicinity] [nvarchar](200) NOT NULL,
	[FullAddress] [nvarchar](1000) NOT NULL,
	[Phone] [varchar](15) NULL,
	[Email] [varchar](100) NULL,
	[Website] [varchar](100) NULL,
	[Rating] [float] NULL,
	[OpenHours] [text] NULL,
	[CanAppointment] [bit] NOT NULL,
	[SvcTypes] [tinyint] NOT NULL,
	[Status] [tinyint] NOT NULL,
	[ExtraData] [text] NULL,
	[CreatedTime] [datetime] NOT NULL,
	[ModifiedTime] [datetime] NOT NULL,
 CONSTRAINT [PK_Place] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

CREATE UNIQUE NONCLUSTERED INDEX IX_Place_GID ON dbo.Place
	(
	GID
	) WITH( STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO
SET ANSI_PADDING OFF
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Google Place ID not auto inc' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Place', @level2type=N'COLUMN',@level2name=N'ID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'0(invalid) 1(id only) 2(parsed) 3(processed)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Place', @level2type=N'COLUMN',@level2name=N'Status'
GO

ALTER TABLE [dbo].[Place] ADD  CONSTRAINT [DF_Place_Status]  DEFAULT ((0)) FOR [Status]
GO


