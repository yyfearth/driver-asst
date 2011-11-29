using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data.SqlClient;
using System.Configuration;
using System.Web.Configuration;
using System.Data;
using System.Web.Security;
using System.Collections;

namespace KnightRider {
	public class DataAccess {
		private static string conn = WebConfigurationManager.ConnectionStrings["KRConn"].ToString();

		private static string hash(string str) {
			var h = "\xE1\x0C\x67\xBF\x37\x10\x73\x0F\x7E\xF8\x88\x61\x8D\xEC\x31\xE6\x14\xCA\x0B\xB4";
			return FormsAuthentication.HashPasswordForStoringInConfigFile(h + str, "SHA1");
		}

		public static bool ValidateUser(string user, string password) {
			using (SqlConnection cn = new SqlConnection(conn)) {
				string key = user.IndexOf('@') < 0 ? "Username" : "Email";
				string sql = "SELECT Count(*) FROM [User] WHERE " + key + " = @U and Password = @P";
				SqlCommand cmd = new SqlCommand(sql, cn);
				cmd.Parameters.AddWithValue("@U", user);
				cmd.Parameters.AddWithValue("@P", hash(password));
				cn.Open();
				var c = (int)cmd.ExecuteScalar();
				return c == 1;
				/*SqlDataReader rdr = cmd.ExecuteReader(CommandBehavior.CloseConnection);
				rdr.Read();
				var ps = rdr.GetInt16(0);
				return ps == 1;*/
				/*string key = user.IndexOf('@') < 0 ? "Username" : "Email";
				string sql = "SELECT Password FROM [User] WHERE " + key + " = @U;";
				SqlCommand cmd = new SqlCommand(sql, cn);
				cmd.Parameters.AddWithValue("@U", user);
				cn.Open();
				SqlDataReader rdr = cmd.ExecuteReader(CommandBehavior.CloseConnection);
				rdr.Read();
				var ps = rdr[0].ToString();
				return hash(password) == ps; // need hash*/
			}
		}

		public static UserJson GetUser(uint id) {
			using (SqlConnection cn = new SqlConnection(conn)) {
				string sql = "SELECT * FROM [User] WHERE ID = @ID";
				SqlCommand cmd = new SqlCommand(sql, cn);
				cmd.Parameters.AddWithValue("@ID", id);
				cn.Open();
				SqlDataReader rdr = cmd.ExecuteReader(CommandBehavior.CloseConnection);
				rdr.Read();
				var user = new UserJson() {
					id = (uint)rdr["ID"],
					email = (string)rdr["Email"],
					username = (string)rdr["Username"],
					//password = (string)rdr["Password"], // no password
					fullname = new UserJson.Fullname() {
						first = (string)rdr["FirstName"],
						last = (string)rdr["LastName"],
					},
					type = (UserType)rdr["Type"],
					status = (UserStatus)rdr["Status"],
					created = (DateTime)rdr["CreatedTime"],
					modified = (DateTime)rdr["ModifiedTime"],
				};
				return user;
			}
		}

		public static void AddUser(UserJson user) {
			if (user == null) throw new Exception("req is null");
			if (user.username == null || user.username == string.Empty ||
				user.email == null || user.email == string.Empty)
				throw new Exception("bad req");
			using (SqlConnection cn = new SqlConnection(conn)) {
				string sql = "INSERT INTO [User] (Email, Username, Password, FirstName, LastName, Phone, Type, Status, CreatedTime, ModifiedTime) VALUES ('@Email', '@Username', '@Password', '@FirstName', '@LastName', '@Phone', @Type, @Status, @CreatedTime, @ModifiedTime)";
				SqlCommand cmd = new SqlCommand(sql, cn);
				cmd.Parameters.AddWithValue("@Email", user.email);
				cmd.Parameters.AddWithValue("@Username", user.username);
				cmd.Parameters.AddWithValue("@Password", user.password);
				cmd.Parameters.AddWithValue("@FirstName", user.fullname.first);
				cmd.Parameters.AddWithValue("@LastName", user.fullname.last);
				cmd.Parameters.AddWithValue("@Phone", user.phone);
				cmd.Parameters.AddWithValue("@Type", UserType.Driver);
				cmd.Parameters.AddWithValue("@Status", UserStatus.Normal);
				cmd.Parameters.AddWithValue("@CreatedTime", DateTime.Now);
				cmd.Parameters.AddWithValue("@ModifiedTime", DateTime.Now);
				cn.Open();
				var ret = cmd.ExecuteNonQuery();
				if (ret < 1) throw new Exception("no effect");
			}
		}

		public static AppointmentJson[] SyncAppointments(DateTime lastmod) {
			using (SqlConnection cn = new SqlConnection(conn)) {
				SqlCommand cmd;
				if (lastmod == null) {
					string sql = "SELECT * FROM [Appointment] WHERE Status!=0";
					cmd = new SqlCommand(sql, cn);
				} else {
					string sql = "SELECT * FROM [Appointment] WHERE Status!=0 and ModifedTime >= @MT";
					cmd = new SqlCommand(sql, cn);
					cmd.Parameters.AddWithValue("@MT", lastmod);
				}
				cn.Open();
				SqlDataReader rdr = cmd.ExecuteReader(CommandBehavior.CloseConnection);
				var list = new List<AppointmentJson>();
				while (rdr.Read()) {
					// get the results of each column
					var a = new AppointmentJson() {
						id = (uint)rdr["ID"],
						place = (string)rdr["PlaceGID"],
						user = (uint)rdr["UserID"],
						contact = new AppointmentJson.Contact() {
							name = (string)rdr["ContactName"],
							phone = (string)rdr["ContactPhone"],
						},
						datetime = (DateTime)rdr["DateTime"],
						message = (string)rdr["Message"],
						status = (AppointmentStatus)rdr["Status"],
						created = (DateTime)rdr["CreatedTime"],
						modified = (DateTime)rdr["ModifiedTime"],
					};
					list.Add(a);
				}
				return list.ToArray<AppointmentJson>();
			}
		}

		public static void AddAppointment(AppointmentJson appt) {
			if (appt == null) throw new Exception("req is null");
			if (appt.message == null || appt.message == string.Empty) throw new Exception("bad req");
			using (SqlConnection cn = new SqlConnection(conn)) {
				string sql = "INSERT INTO [Appointment] (PlaceGID, UserID, ContactName, ContactPhone, DateTime, Message, Status, CreatedTime, ModifiedTime) VALUES (@PlaceGID, @UserID, @ContactName, @ContactPhone, @DateTime, @Message, @Status, @CreatedTime, @ModifiedTime)";
				SqlCommand cmd = new SqlCommand(sql, cn);
				bool no_cname = appt.contact.name == null || appt.contact.name == string.Empty,
					no_cphone = appt.contact.phone == null || appt.contact.phone == string.Empty;
				if (appt.contact == null || no_cname || no_cphone) {
					var user = GetUser(appt.user);
					if (appt.contact == null)
						appt.contact = new AppointmentJson.Contact();
					if (no_cname) appt.contact.name = user.username;
					if (no_cphone) appt.contact.phone = user.phone;
				}
				cmd.Parameters.AddWithValue("@PlaceGID", appt.place);
				cmd.Parameters.AddWithValue("@UserID", appt.user);
				cmd.Parameters.AddWithValue("@ContactName", appt.contact.name);
				cmd.Parameters.AddWithValue("@ContactPhone", appt.contact.phone);
				cmd.Parameters.AddWithValue("@DateTime", appt.datetime);
				cmd.Parameters.AddWithValue("@Message", appt.message);
				cmd.Parameters.AddWithValue("@Status", AppointmentStatus.Created);
				cmd.Parameters.AddWithValue("@CreatedTime", DateTime.Now);
				cmd.Parameters.AddWithValue("@ModifiedTime", DateTime.Now);
				cn.Open();
				var ret = cmd.ExecuteNonQuery();
				if (ret < 1) throw new Exception("no effect");
			}
		}

		public static AlertJson[] SyncAlerts(DateTime lastmod) {
			using (SqlConnection cn = new SqlConnection(conn)) {
				SqlCommand cmd;
				if (lastmod == null) {
					string sql = "SELECT * FROM [Alert] WHERE Status!=0";
					cmd = new SqlCommand(sql, cn);
				} else {
					string sql = "SELECT * FROM [Alert] WHERE Status!=0 and ModifedTime >= @MT";
					cmd = new SqlCommand(sql, cn);
					cmd.Parameters.AddWithValue("@MT", lastmod);
				}
				cn.Open();
				SqlDataReader rdr = cmd.ExecuteReader(CommandBehavior.CloseConnection);
				var list = new List<AlertJson>();
				while (rdr.Read()) {
					// get the results of each column
					var a = new AlertJson() {
						id = (uint)rdr["ID"],
						datetime = (DateTime)rdr["DateTime"],
						expired = (DateTime)rdr["ExpiredTime"],
						summary = (string)rdr["Summary"],
						message = (string)rdr["Message"],
						importance = (byte)rdr["Importance"],
						type = (AlertType)rdr["Type"],
						status = (AlertStatus)rdr["Status"],
						created = (DateTime)rdr["CreatedTime"],
						modified = (DateTime)rdr["ModifiedTime"],
					};
					list.Add(a);
				}
				return list.ToArray<AlertJson>();
			}
		}

		public static void AddAlert(AlertJson alert) {
			if (alert == null) throw new Exception("req is null");
			if (alert.message == null || alert.message == string.Empty) throw new Exception("bad req");
			using (SqlConnection cn = new SqlConnection(conn)) {
				string sql = "INSERT INTO [Alert] (DateTime, ExpireDateTime, Summary, Message, Importance, Type, Status, CreatedTime, ModifiedTime) VALUES (@DateTime, @ExpireDateTime, '@Summary', '@Message', @Importance, @Type, @Status, @CreatedTime, @ModifiedTime)";
				SqlCommand cmd = new SqlCommand(sql, cn);
				if (alert.datetime == null) alert.datetime = DateTime.Now;
				if (alert.summary == null) alert.summary = alert.message.Substring(0, 100);
				cmd.Parameters.AddWithValue("@DateTime", alert.datetime);
				cmd.Parameters.AddWithValue("@ExpireDateTime", alert.expired);
				cmd.Parameters.AddWithValue("@Summary", alert.summary);
				cmd.Parameters.AddWithValue("@Message", alert.message);
				cmd.Parameters.AddWithValue("@Importance", alert.importance);
				cmd.Parameters.AddWithValue("@Type", AlertType.Unspecified);
				cmd.Parameters.AddWithValue("@Status", AlertStatus.Normal);
				cmd.Parameters.AddWithValue("@CreatedTime", DateTime.Now);
				cmd.Parameters.AddWithValue("@ModifiedTime", DateTime.Now);
				cn.Open();
				var ret = cmd.ExecuteNonQuery();
				if (ret < 1) throw new Exception("no effect");
			}
		}
	}
}