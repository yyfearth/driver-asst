using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data.SqlClient;
using System.Configuration;
using System.Web.Configuration;
using System.Data;
using System.Web.Security;

namespace KnightRider {
	public class DataAccess {
		private static string conn = WebConfigurationManager.ConnectionStrings["KRConn"].ToString();

		private static string hash(string str) {
			var h = "\xE1\x0C\x67\xBF\x37\x10\x73\x0F\x7E\xF8\x88\x61\x8D\xEC\x31\xE6\x14\xCA\x0B\xB4";
			return FormsAuthentication.HashPasswordForStoringInConfigFile(
				str + FormsAuthentication.HashPasswordForStoringInConfigFile(h + str, "SHA1") + h, "SHA1");
		}

		public static bool ValidateUser(string user, string password) {
			using (SqlConnection cn = new SqlConnection(conn)) {
				/*string key = user.IndexOf('@') < 0 ? "Username" : "Email";
				string sql = "SELECT Password FROM [User] WHERE " + key + " = @U;";
				SqlCommand cmd = new SqlCommand(sql, cn);
				cmd.Parameters.AddWithValue("@U", user);
				cn.Open();
				SqlDataReader rdr = cmd.ExecuteReader(CommandBehavior.CloseConnection);
				rdr.Read();
				var ps = rdr[0].ToString();
				return hash(password) == ps; // need hash*/
				string sql = "INSERT INTO [Alert] (DateTime, ExpireDateTime, Summary, Message, Importance, Type, Status, CreatedTime, ModifiedTime) VALUES (@DateTime, @ExpireDateTime, @Summary, @Message, @Importance, @Type, @Status, @CreatedTime, @ModifiedTime)";
				SqlCommand cmd = new SqlCommand(sql, cn);
				var now = DateTime.Now;
				cmd.Parameters.AddWithValue("@DateTime", now);
				cmd.Parameters.AddWithValue("@ExpireDateTime", now.AddHours(1));
				cmd.Parameters.AddWithValue("@Summary", "(Summary)");
				cmd.Parameters.AddWithValue("@Message", "(Message)");
				cmd.Parameters.AddWithValue("@Importance", 0);
				cmd.Parameters.AddWithValue("@Type", AlertType.Invalid);
				cmd.Parameters.AddWithValue("@Status", AlertStatus.Invalid);
				cmd.Parameters.AddWithValue("@CreatedTime", now);
				cmd.Parameters.AddWithValue("@ModifiedTime", now);
				cn.Open();
				var ret = cmd.ExecuteNonQuery();
				return true;
			}
		}
	}
}