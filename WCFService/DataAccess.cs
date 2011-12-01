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

		public class DataAccessException : Exception { } // base
		public class BadRequestException : DataAccessException { }
		public class NoResultException : DataAccessException { }
		public class ValidateException : NoResultException { }
		public class NoEffectException : DataAccessException { }
		public class ConflictException : DataAccessException { }

		private static string hash(string str) {
			var h = "\xE1\x0C\x67\xBF\x37\x10\x73\x0F\x7E\xF8\x88\x61\x8D\xEC\x31\xE6\x14\xCA\x0B\xB4";
			return FormsAuthentication.HashPasswordForStoringInConfigFile(h + str, "SHA1");
		}

		public static uint ValidateUser(string email, string password) {
			if (email == null || password == null || email == string.Empty || password == string.Empty)
				throw new BadRequestException();
			using (SqlConnection cn = new SqlConnection(conn)) {
				string sql = "SELECT ID FROM [User] WHERE Email = @Email and Password = @PK";
				SqlCommand cmd = new SqlCommand(sql, cn);
				cmd.Parameters.AddWithValue("@Email", email);
				var key = hash(email.ToLower() + '\0' + password);
				cmd.Parameters.AddWithValue("@PK", key);
				cn.Open();
				var ret = cmd.ExecuteScalar();
				if (ret == null) throw new ValidateException();
				return Convert.ToUInt32(ret); // return user id
			}
		}

		public static bool ValidateLogin(uint uid, string sid){
			return ValidateLogin(uid, Guid.ParseExact(sid, "N"));
		}
		public static bool ValidateLogin(uint userid, Guid sid) {
			if (userid == 0 || sid == null || sid == Guid.Empty)
				throw new BadRequestException();
			using (SqlConnection cn = new SqlConnection(conn)) {
				string sql = "SELECT ModifiedTime FROM [Login] WHERE UserID = @UID and SID = @SID";
				SqlCommand cmd = new SqlCommand(sql, cn);
				cmd.Parameters.AddWithValue("@UID", Convert.ToInt32(userid));
				cmd.Parameters.AddWithValue("@SID", sid);
				cn.Open();
				var last = cmd.ExecuteScalar();
				return !(last == null || ((DateTime)last).Subtract(DateTime.Now).Days > 30); // not exist or over 30d
			}
		}

		public static Guid LoginUser(uint userid) {
			if (userid == 0) throw new BadRequestException();
			using (SqlConnection cn = new SqlConnection(conn)) {
				var sid = Guid.NewGuid();
				string sql = "UPDATE [Login] SET SID = @SID, ModifiedTime = GETDATE() WHERE UserID = @UID";
				SqlCommand cmd = new SqlCommand(sql, cn);
				cmd.Parameters.AddWithValue("@UID", Convert.ToInt32(userid));
				cmd.Parameters.AddWithValue("@SID", sid);
				cn.Open();
				var ret = cmd.ExecuteNonQuery();
				if (ret < 1) throw new NoEffectException();
				return sid;
			}
		}

		public static void LogoutUser(uint uid, string sid) {
			LogoutUser(uid, Guid.ParseExact(sid, "N"));
		}
		public static void LogoutUser(uint userid, Guid sid) { // no result
			if (userid == 0) throw new BadRequestException();
			if (ValidateLogin(userid, sid)) LoginUser(userid); // over write
		}

		public static UserJson GetUser(uint id) {
			if (id == 0) throw new BadRequestException();
			using (SqlConnection cn = new SqlConnection(conn)) {
				string sql = "SELECT * FROM [User] WHERE ID = @ID";
				SqlCommand cmd = new SqlCommand(sql, cn);
				cmd.Parameters.AddWithValue("@ID", Convert.ToInt32(id));
				cn.Open();
				SqlDataReader rdr = cmd.ExecuteReader(CommandBehavior.CloseConnection);
				rdr.Read();
				if (rdr[0] == null) throw new NoResultException();
				var user = new UserJson() {
					id = Convert.ToUInt32(rdr["ID"]),
					email = (string)rdr["Email"],
					//password = (string)rdr["Password"], // no password
					fullname = new UserJson.Fullname() {
						first = (string)rdr["FirstName"],
						last = (string)rdr["LastName"],
					},
					phone = (string)rdr["Phone"],
					type = (UserType)(byte)rdr["Type"],
					status = (UserStatus)(byte)rdr["Status"],
					created = (DateTime)rdr["CreatedTime"],
					modified = (DateTime)rdr["ModifiedTime"],
				};
				return user;
			}
		}

		public static uint AddUser(UserJson user) {
			if (user == null || user.email == null || user.email == string.Empty)
				throw new BadRequestException();
			using (SqlConnection cn = new SqlConnection(conn)) {
				cn.Open();
				// add user
				string sql = "INSERT INTO [User] (Email, Password, FirstName, LastName, Phone, Type, Status, CreatedTime, ModifiedTime) VALUES (@Email, @Password, @FirstName, @LastName, @Phone, 1, 1, GETDATE(), GETDATE())";
				SqlCommand cmd = new SqlCommand(sql, cn);
				cmd.Parameters.AddWithValue("@Email", user.email);
				cmd.Parameters.AddWithValue("@Password", hash(user.email.ToLower() + '\0' + user.password));
				cmd.Parameters.AddWithValue("@FirstName", user.fullname.first);
				cmd.Parameters.AddWithValue("@LastName", user.fullname.last);
				cmd.Parameters.AddWithValue("@Phone", user.phone);
				var c = 0;
				try {
					c = cmd.ExecuteNonQuery();
				} catch (SqlException) {
					throw new ConflictException();
				}
				if (c < 1) throw new NoEffectException();
				// get user id
				sql = "SELECT ID FROM [User] WHERE Email=@Email";
				cmd = new SqlCommand(sql, cn);
				cmd.Parameters.AddWithValue("@Email", user.email);
				var uid = cmd.ExecuteScalar();
				if (uid == null) throw new NoEffectException();
				// add login info
				sql = "INSERT INTO [Login] (UserID, SID, CreatedTime, ModifiedTime) VALUES (@UserID, NEWID(), GETDATE(), GETDATE())";
				cmd = new SqlCommand(sql, cn);
				cmd.Parameters.AddWithValue("@UserID", uid);
				c = cmd.ExecuteNonQuery();
				if (c < 1) throw new NoEffectException();
				return Convert.ToUInt32(uid);
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
						id = Convert.ToUInt32(rdr["ID"]),
						place = (string)rdr["PlaceGID"],
						user = (uint)rdr["UserID"],
						contact = new AppointmentJson.Contact() {
							name = (string)rdr["ContactName"],
							phone = (string)rdr["ContactPhone"],
						},
						datetime = (DateTime)rdr["DateTime"],
						message = (string)rdr["Message"],
						status = (AppointmentStatus)(byte)rdr["Status"],
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
			if (appt.datetime == null) throw new BadRequestException();
			var days = (appt.datetime - DateTime.Now).Days;
			if (days < -1 || days > 30) throw new BadRequestException();
			using (SqlConnection cn = new SqlConnection(conn)) {
				string sql = "INSERT INTO [Appointment] (PlaceGID, UserID, ContactName, ContactPhone, DateTime, Message, Status, CreatedTime, ModifiedTime) VALUES (@PlaceGID, @UserID, @ContactName, @ContactPhone, @DateTime, @Message, 1, GETDATE(), GETDATE())";
				SqlCommand cmd = new SqlCommand(sql, cn);
				bool no_cname = appt.contact.name == null || appt.contact.name == string.Empty,
					no_cphone = appt.contact.phone == null || appt.contact.phone == string.Empty;
				if (appt.contact == null || no_cname || no_cphone) {
					var user = GetUser(appt.user);
					if (appt.contact == null)
						appt.contact = new AppointmentJson.Contact();
					if (no_cname) appt.contact.name = user.fullname.ToString();
					if (no_cphone) appt.contact.phone = user.phone;
				}
				cmd.Parameters.AddWithValue("@PlaceGID", appt.place);
				cmd.Parameters.AddWithValue("@UserID", Convert.ToInt32(appt.user));
				cmd.Parameters.AddWithValue("@ContactName", appt.contact.name);
				cmd.Parameters.AddWithValue("@ContactPhone", appt.contact.phone);
				cmd.Parameters.AddWithValue("@DateTime", appt.datetime);
				cmd.Parameters.AddWithValue("@Message", appt.message);
				cn.Open();
				var ret = cmd.ExecuteNonQuery();
				if (ret < 1) throw new NoEffectException();
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
						id = Convert.ToUInt32(rdr["ID"]),
						datetime = (DateTime)rdr["DateTime"],
						expired = (DateTime)rdr["ExpiredTime"],
						summary = (string)rdr["Summary"],
						message = (string)rdr["Message"],
						importance = (byte)rdr["Importance"],
						type = (AlertType)(byte)rdr["Type"],
						status = (AlertStatus)(byte)rdr["Status"],
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
			if (alert.message == null || alert.message == string.Empty) throw new BadRequestException();
			using (SqlConnection cn = new SqlConnection(conn)) {
				string sql = "INSERT INTO [Alert] (DateTime, ExpireDateTime, Summary, Message, Importance, Type, Status, CreatedTime, ModifiedTime) VALUES (@DateTime, @ExpireDateTime, @Summary, @Message, @Importance, 1, 1, GETDATE(), GETDATE())";
				SqlCommand cmd = new SqlCommand(sql, cn);
				if (alert.datetime == null) alert.datetime = DateTime.Now;
				if (alert.expired == null) alert.expired = alert.datetime.AddHours(1); // 1h default
				if (alert.summary == null) alert.summary = alert.message.Substring(0, 100);
				cmd.Parameters.AddWithValue("@DateTime", alert.datetime);
				cmd.Parameters.AddWithValue("@ExpireDateTime", alert.expired);
				cmd.Parameters.AddWithValue("@Summary", alert.summary);
				cmd.Parameters.AddWithValue("@Message", alert.message);
				cmd.Parameters.AddWithValue("@Importance", alert.importance); // default 0
				cn.Open();
				var ret = cmd.ExecuteNonQuery();
				if (ret < 1) throw new NoEffectException();
			}
		}
	}
}