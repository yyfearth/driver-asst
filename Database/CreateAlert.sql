USE [KnightRider]
GO

/****** Object:  Table [dbo].[Alert]    Script Date: 12/01/2011 03:09:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Alert](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DateTime] [datetime] NOT NULL,
	[ExpireDateTime] [datetime] NULL,
	[Summary] [nvarchar](300) NOT NULL,
	[Message] [text] NOT NULL,
	[Importance] [tinyint] NOT NULL,
	[Type] [tinyint] NOT NULL,
	[Status] [tinyint] NOT NULL,
	[ExtraData] [text] NULL,
	[CreatedTime] [datetime] NOT NULL,
	[ModifiedTime] [datetime] NOT NULL,
 CONSTRAINT [PK_Alerts] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Greater have Higher Priority' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Alert', @level2type=N'COLUMN',@level2name=N'Importance'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'AlertType: 0(Invalid) 1(Unspec) 2(Weather) 3(Traffic)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Alert', @level2type=N'COLUMN',@level2name=N'Type'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'AlertStatus: 0(invalid) 1(init) 2(started) 3(expired) 4(canceled)' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'Alert', @level2type=N'COLUMN',@level2name=N'Status'
GO

ALTER TABLE [dbo].[Alert] ADD  CONSTRAINT [DF_Alerts_Importance]  DEFAULT ((0)) FOR [Importance]
GO

ALTER TABLE [dbo].[Alert] ADD  CONSTRAINT [DF_Alerts_Type]  DEFAULT ((0)) FOR [Type]
GO

ALTER TABLE [dbo].[Alert] ADD  CONSTRAINT [DF_Alerts_Status]  DEFAULT ((0)) FOR [Status]
GO

