// Weather API: http://www.google.com/ig/api?weather=san+jose,ca

// To convert an XML node contained in string xml into a JSON string   
XmlDocument doc = new XmlDocument();
doc.LoadXml(xml);
string jsonText = JsonConvert.SerializeXmlNode(doc);

// To convert JSON text contained in string json into an XML node
XmlDocument doc = (XmlDocument)JsonConvert.DeserializeXmlNode(json);

// $.ajax({url:'/gapi?weather=san+jose,ca', complete:function(xhr){console.log(xhr.responseText)}})