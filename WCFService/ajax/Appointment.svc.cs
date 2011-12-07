using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Activation;
using System.ServiceModel.Web;
using System.Text;

namespace KnightRider {
	[ServiceContract(Namespace = "")]
	public class Appointment {
		[OperationContract]
		[WebInvoke(Method = "POST", BodyStyle = WebMessageBodyStyle.WrappedRequest, RequestFormat = WebMessageFormat.Json, ResponseFormat = WebMessageFormat.Json)]
		public bool add(AppointmentJson appt, string sid) {
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
