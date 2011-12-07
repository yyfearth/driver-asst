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
	public class Place {
		//private static DateTime origin = new DateTime(1970, 1, 1, 0, 0, 0, 0, DateTimeKind.Local); // or Utc
		[OperationContract, WebGet]
		public PlaceJson[] sync(DateTime last) {
			//DateTime lastdt = last > 0 ? origin.AddTicks(last) : new DateTime(0);
			return DataAccess.SyncPlace(last);
		}

		[OperationContract]
		[WebInvoke(Method = "POST", BodyStyle = WebMessageBodyStyle.WrappedRequest, RequestFormat = WebMessageFormat.Json, ResponseFormat = WebMessageFormat.Json)]
		public void add(PlaceJson place) {
			DataAccess.AddPlace(place);
		}
	}
}
