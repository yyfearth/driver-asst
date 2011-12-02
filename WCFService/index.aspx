<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="index.aspx.cs" Inherits="KnightRider.WebForm1" %>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title></title>
</head>
<body>
    <form id="form1" runat="server">
    <div>
		Alert:
		<asp:TextBox ID="AlertText" runat="server"></asp:TextBox>
    	<asp:Button ID="AlertAdd" runat="server" onclick="Add_Click" Text="Add" />
    </div>
    </form>
</body>
</html>
