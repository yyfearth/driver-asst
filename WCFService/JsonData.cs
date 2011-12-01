using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Runtime.Serialization;

namespace KnightRider {
	[DataContract]
	public class DataJson {
		public uint id { get; set; }
		public DateTime created { get; set; }
		public DateTime modified { get; set; }
		private dynamic ExtraData { get; set; } // json
	}
	// user
	[DataContract]
	public enum UserType { // 1 should be the default correct value
		Invalid = 0,
		Unspecified = 1,
		Driver = 2,
		VIP = 3,
		// todo: add more types
	}
	[DataContract]
	public enum UserStatus { // 1 should be the default correct value
		Invalid = 0,
		Normal = 1,
		// todo: add more status
	}
	[DataContract]
	public class UserJson : DataJson {
		public class Fullname {
			public string first { get; set; }
			public string last { get; set; }
			public override string ToString() {
				return first + ' ' + last;
			}
		}
		[DataMember]
		public string email { get; set; }
		[DataMember]
		public string password { get; set; }
		[DataMember]
		public Fullname fullname { get; set; }
		[DataMember]
		public string phone { get; set; }
		[DataMember]
		public UserType type { get; set; }
		[DataMember]
		public UserStatus status { get; set; }
	}
	// place
	[DataContract]
	public enum PlaceKRType { // 1 should be the default correct value
		Invalid = 0,
		Unspecified = 1,
		// todo: add more types
	}
	[DataContract]
	public enum PlaceStatus { // 1 should be the default correct value
		Invalid = 0,
		IDOnly = 1, // only has gid
		Parsed = 2, // have parsed raw data
		Processed = 3, // todo: define it
		// todo: add more status
	}
	[DataContract]
	public class PlaceJson : DataJson {
		public class GeoLocation {
			public double lat { get; set; }
			public double lng { get; set; }
		}
		[DataMember]
		public string name { get; set; }
		[DataMember]
		public string vicinity { get; set; }
		[DataMember]
		public string fulladdr { get; set; }
		[DataMember]
		public GeoLocation location { get; set; }
		[DataMember]
		public byte rating { get; set; }
		//public ContactInfo contacts { get; set; }
		[DataMember]
		public PlaceKRType krtype { get; set; }
		[DataMember]
		public PlaceStatus status { get; set; }
		[DataMember]
		public string gid { get; set; }
		[DataMember]
		public string gref { get; set; } // uid or json
		[DataMember]
		public dynamic RawData { get; set; } // json
	}
	// appointment
	[DataContract]
	public enum AppointmentStatus { // 1 should be the default correct value
		Invalid = 0,
		Created = 1, // init
		Received = 2,
		Approved = 3,
		Rejected = 4,
		// todo: add more types
		Expired = 8,
		Canceled = 9,
	}
	[DataContract]
	public class AppointmentJson : DataJson {
		// place user contact datetime message status
		public class Contact {
			public string name { get; set; }
			public string phone { get; set; }
		}
		[DataMember]
		public string place { get; set; } // GID
		[DataMember]
		public uint user { get; set; }
		[DataMember]
		public Contact contact { get; set; }
		[DataMember]
		public DateTime datetime { get; set; }
		[DataMember]
		public string message { get; set; }
		[DataMember]
		public AppointmentStatus status { get; set; }
	}
	// alerts
	[DataContract]
	public enum AlertType { // 1 should be the default correct value
		Invalid = 0,
		Unspecified = 1,
		Weather = 2,
		Traffic = 3,
		Service = 4,
		// todo: add more types
	}
	[DataContract]
	public enum AlertStatus { // 1 should be the default correct value
		Invalid = 0,
		Normal = 1,
		// these shoud be auto calc, and auto clear after expire
		//Saved = 1,
		//Started = 2,
		//Expired = 3,
		// todo: add more status
		Canceled = 9,
	}
	[DataContract]
	public class AlertJson : DataJson {
		// datetime expired summary message importance type status
		[DataMember]
		public DateTime datetime { get; set; }
		[DataMember]
		public DateTime expired { get; set; }
		[DataMember]
		public string summary { get; set; }
		[DataMember]
		public string message { get; set; }
		[DataMember]
		public byte importance { get; set; }
		[DataMember]
		public AlertType type { get; set; }
		[DataMember]
		public AlertStatus status { get; set; }
	}
}