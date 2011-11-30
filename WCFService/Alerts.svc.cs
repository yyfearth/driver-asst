﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.Serialization;
using System.ServiceModel;
using System.ServiceModel.Activation;
using System.ServiceModel.Web;
using System.Text;

namespace KnightRider {
	[ServiceContract(Namespace = "")]
	[AspNetCompatibilityRequirements(RequirementsMode = AspNetCompatibilityRequirementsMode.Allowed)]
	public class Alerts {
		// To use HTTP GET, add [WebGet] attribute. (Default ResponseFormat is WebMessageFormat.Json)
		// To create an operation that returns XML,
		//     add [WebGet(ResponseFormat=WebMessageFormat.Xml)],
		//     and include the following line in the operation body:
		//         WebOperationContext.Current.OutgoingResponse.ContentType = "text/xml";
		[OperationContract]
		[WebInvoke(BodyStyle = WebMessageBodyStyle.WrappedRequest, RequestFormat = WebMessageFormat.Json, ResponseFormat = WebMessageFormat.Json)]
		public void sync() {
			// Add your operation implementation here
			return;
		}

		// Add more operations here and mark them with [OperationContract]
	}
}
