using System;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Activation;

namespace KnightRider {
	[ServiceContract(Namespace = "")]
	[SilverlightFaultBehavior]
	[AspNetCompatibilityRequirements(RequirementsMode = AspNetCompatibilityRequirementsMode.Allowed)]
	public class WP7Service {
		[DataContract]
		public class LoginResult {
			[DataMember]
			public uint uid { get; set; }
			[DataMember]
			public string sid { get; set; }
		}

		[OperationContract]
		public LoginResult Login(string email, string password) { // cacheable
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
		public void Logout(uint uid, string sid) { // cacheable
			try {
				DataAccess.LogoutUser(uid, sid);
			} catch { }
		}

		[OperationContract]
		public uint Reg(UserJson user) { // cacheable
			try {
				return DataAccess.AddUser(user);
			} catch (DataAccess.ConflictException) {
				return 0;
			} catch {
				throw new FaultException("internal error", new FaultCode("error"));
			}
		}

		[OperationContract]
		public bool Check(uint uid, string sid) { // cacheable
			try {
				return DataAccess.ValidateLogin(uid, sid);
			} catch {
				throw new FaultException("internal error", new FaultCode("error"));
			}
		}

		[OperationContract]
		public AlertJson[] SyncAlerts(DateTime last) {
			return DataAccess.SyncAlerts(last);
		}

		[OperationContract]
		public PlaceJson[] SyncPlace(DateTime last) {
			return DataAccess.SyncPlace(last);
		}

		[OperationContract]
		public bool Appointment(AppointmentJson appt, string sid) {
			try {
				if (appt == null || appt.user == 0)
					throw new Exception("bad req");
				if (sid == null || sid == string.Empty ||
					!DataAccess.ValidateLogin(appt.user, Guid.ParseExact(sid, "N")))
					return false;
				DataAccess.AddAppointment(appt);
				return true;
			} catch {
				throw new FaultException("internal error", new FaultCode("error"));
			}
		}
	}
}
