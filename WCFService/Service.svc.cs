using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.Text;

namespace KnightRider {
	// NOTE: You can use the "Rename" command on the "Refactor" menu to change the class name "Service" in code, svc and config file together.
	public class Service {
		[ServiceContract(Namespace = "")]
		[DataContract]
		public class LoginResult {
			[DataMember]
			public uint uid { get; set; }
			[DataMember]
			public string sid { get; set; }
		}

		[OperationContract]
		public LoginResult login(string email, string password) { // cacheable
			try {
				var userid = DataAccess.ValidateUser(email, password);
				var sid = DataAccess.LoginUser(userid).ToString("N"); // return sid
				return new LoginResult() { uid = userid, sid = sid };
			} catch (DataAccess.ValidateException) {
				return new LoginResult();
			} catch {
				throw new FaultException("internal error", new FaultCode("error"));
			}
		}

		[OperationContract]
		public void logout(uint uid, string sid) { // cacheable
			try {
				DataAccess.LogoutUser(uid, sid);
			} catch { }
		}

		[OperationContract]
		public uint reg(UserJson user) { // cacheable
			try {
				return DataAccess.AddUser(user);
			} catch (DataAccess.ConflictException) {
				return 0;
			} catch {
				throw new FaultException("internal error", new FaultCode("error"));
			}
		}

		[OperationContract]
		public bool check(uint uid, string sid) { // cacheable
			try {
				return DataAccess.ValidateLogin(uid, sid);
			} catch {
				throw new FaultException("internal error", new FaultCode("error"));
			}
		}

		[OperationContract]
		public DataJson[] sync(string name, DateTime last) {
			//DateTime lastdt = last > 0 ? origin.AddTicks(last) : new DateTime(0);
			switch (name) {
				case "alert":
				case "alerts":
					return DataAccess.SyncAlerts(last);
				case "place":
					return DataAccess.SyncPlace(last);
				default:
					throw new Exception("Invalid name");
			}
		}

		[OperationContract]
		public void add(string name, DataJson json) {
			switch (name) {
				case "appt":
				case "appointment":
					DataAccess.AddAppointment(json as AppointmentJson);
					return;
				default:
					throw new Exception("Invalid name");
			}
		}
	}
}
