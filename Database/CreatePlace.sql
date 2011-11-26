USE [KnightRider]
GO

/****** Object:  Table [dbo].[Place]    Script Date: 11/26/2011 00:43:19 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[Place](
	[ID] [int] NOT NULL,
	[GID] [char](40) NOT NULL,
	[RawData] [text] NULL,
	[GReference] [text] NULL,
	[Name] [nvarchar](100) NULL,
	[Latitude] [float] NULL,
	[Longitude] [float] NULL,
	[Vicinity] [nvarchar](200) NULL,
	[FullAddress] [nvarchar](1000) NULL,
	[ContactInfo] [text] NULL,
	[Rating] [tinyint] NULL,
	[KRType] [tinyint] NULL,
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

SET ANSI_PADDING OFF
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Google Place ID not auto inc' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Place', @level2type=N'COLUMN',@level2name=N'ID'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'0(invalid) 1(id only) 2(parsed) 3(processed)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Place', @level2type=N'COLUMN',@level2name=N'Status'
GO

ALTER TABLE [dbo].[Place] ADD  CONSTRAINT [DF_Place_Status]  DEFAULT ((0)) FOR [Status]
GO

