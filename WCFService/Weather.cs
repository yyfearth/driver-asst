using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Xml;
using System.Web.Script.Serialization;

namespace KnightRider {
	public class Weather {
		// Weather API: http://www.google.com/ig/api?weather=san+jose,ca
		public string Xml2Json(string xml){
		// To convert an XML node contained in string xml into a JSON string   
		XmlDocument doc = new XmlDocument();
		doc.LoadXml(xml);
		var jss = new JavaScriptSerializer();
		//string jsonText = jss. //JsonConvert.SerializeXmlNode(doc);

		// To convert JSON text contained in string json into an XML node
		// XmlDocument doc = (XmlDocument)JsonConvert.DeserializeXmlNode(json);

		// $.ajax({url:'/gapi?weather=san+jose,ca', complete:function(xhr){console.log(xhr.responseText)}})
		}
	}
}