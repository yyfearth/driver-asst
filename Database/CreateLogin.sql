USE [KnightRider]
GO

/****** Object:  Table [dbo].[Login]    Script Date: 12/01/2011 03:10:14 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[Login](
	[UserID] [int] NOT NULL,
	[SID] [uniqueidentifier] NOT NULL,
	[ExtraData] [text] NULL,
	[CreatedTime] [datetime] NOT NULL,
	[ModifiedTime] [datetime] NOT NULL,
 CONSTRAINT [PK_Login] PRIMARY KEY CLUSTERED 
(
	[UserID] ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

ALTER TABLE [dbo].[Login]  WITH CHECK ADD  CONSTRAINT [FK_Login_User] FOREIGN KEY([UserID])
REFERENCES [dbo].[User] ([ID])
ON DELETE CASCADE
GO

ALTER TABLE [dbo].[Login] CHECK CONSTRAINT [FK_Login_User]
GO

