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
	public class Alerts {
		//private static DateTime origin = new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Local); // or Utc
		[OperationContract, WebGet]
		public AlertJson[] sync(DateTime last) {
			//DateTime lastdt = last > 0 ? origin.AddTicks(last) : new DateTime(0);
			return DataAccess.SyncAlerts(last);
		}
	}
}
