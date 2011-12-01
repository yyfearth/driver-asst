using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Activation;
using System.ServiceModel.Web;
using System.Text;
using System.Text.RegularExpressions;

namespace KnightRider {
	[ServiceContract(Namespace = "")]
	[AspNetCompatibilityRequirements(RequirementsMode = AspNetCompatibilityRequirementsMode.Allowed)]
	public class User {
		[DataContract]
		public class LoginResult {
			[DataMember]
			public uint uid { get; set; }
			[DataMember]
			public string sid { get; set; }
		}

		[OperationContract]
		[WebInvoke(Method = "POST", BodyStyle = WebMessageBodyStyle.WrappedRequest, RequestFormat = WebMessageFormat.Json, ResponseFormat = WebMessageFormat.Json)]
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
		[WebInvoke(Method = "POST", BodyStyle = WebMessageBodyStyle.WrappedRequest, RequestFormat = WebMessageFormat.Json, ResponseFormat = WebMessageFormat.Json)]
		public void logout(uint uid, string sid) { // cacheable
			try {
				DataAccess.LogoutUser(uid, Guid.ParseExact(sid, "N"));
			} catch { }
		}

		[OperationContract]
		[WebInvoke(Method = "POST", BodyStyle = WebMessageBodyStyle.WrappedRequest, RequestFormat = WebMessageFormat.Json, ResponseFormat = WebMessageFormat.Json)]
		public uint reg(UserJson user) { // cacheable
			try {
				return DataAccess.AddUser(user);
			} catch (DataAccess.ConflictException) {
				return 0;
			} catch {
				throw new FaultException("internal error", new FaultCode("error"));
			}
		}

		// Add more operations here and mark them with [OperationContract]
	}
}
