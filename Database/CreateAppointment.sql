USE [KnightRider]
GO

/****** Object:  Table [dbo].[Appointment]    Script Date: 12/01/2011 03:10:03 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[Appointment](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[PlaceGID] [char](40) NOT NULL,
	[UserID] [int] NOT NULL,
	[ContactName] [nvarchar](100) NOT NULL,
	[ContactPhone] [varchar](15) NOT NULL,
	[DateTime] [datetime] NOT NULL,
	[Message] [text] NULL,
	[Status] [tinyint] NOT NULL,
	[ExtraData] [text] NULL,
	[CreatedTime] [datetime] NOT NULL,
	[ModifiedTime] [datetime] NOT NULL,
 CONSTRAINT [PK_Appointment] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[Appointment]  WITH CHECK ADD  CONSTRAINT [FK_Appointment_User] FOREIGN KEY([UserID])
REFERENCES [dbo].[User] ([ID])
GO

ALTER TABLE [dbo].[Appointment] CHECK CONSTRAINT [FK_Appointment_User]
GO

ALTER TABLE [dbo].[Appointment] ADD  CONSTRAINT [DF_Appointment_Status]  DEFAULT ((0)) FOR [Status]
GO

