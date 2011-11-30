using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace KnightRider {
	public class DataJson {
		public uint id { get; set; }
		public DateTime created { get; set; }
		public DateTime modified { get; set; }
		private dynamic ExtraData { get; set; } // json
	}
	// user
	public enum UserType { // 1 should be the default correct value
		Invalid = 0,
		Unspecified = 1,
		Driver = 2,
		VIP = 3,
		// todo: add more types
	}
	public enum UserStatus { // 1 should be the default correct value
		Invalid = 0,
		Normal = 1,
		// todo: add more status
	}
	public class UserJson : DataJson {
		public class Fullname {
			public string first { get; set; }
			public string last { get; set; }
			public override string ToString() {
				return first + ' ' + last;
			}
		}
		public string email { get; set; }
		public string password { get; set; }
		public Fullname fullname { get; set; }
		public string phone { get; set; }
		public UserType type { get; set; }
		public UserStatus status { get; set; }
	}
	// place
	public enum PlaceKRType { // 1 should be the default correct value
		Invalid = 0,
		Unspecified = 1,
		// todo: add more types
	}
	public enum PlaceStatus { // 1 should be the default correct value
		Invalid = 0,
		IDOnly = 1, // only has gid
		Parsed = 2, // have parsed raw data
		Processed = 3, // todo: define it
		// todo: add more status
	}
	public class PlaceJson : DataJson {
		public class GeoLocation {
			public double lat { get; set; }
			public double lng { get; set; }
		}
		public string name { get; set; }
		public string vicinity { get; set; }
		public string fulladdr { get; set; }
		public GeoLocation location { get; set; }
		public byte rating { get; set; }
		//public ContactInfo contacts { get; set; }
		public PlaceKRType krtype { get; set; }
		public PlaceStatus status { get; set; }
		public string gid { get; set; }
		public string gref { get; set; } // uid or json
		public dynamic RawData { get; set; } // json
	}
	// appointment
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
	public class AppointmentJson : DataJson {
		// place user contact datetime message status
		public class Contact {
			public string name { get; set; }
			public string phone { get; set; }
		}
		public string place { get; set; } // GID
		public uint user { get; set; }
		public Contact contact { get; set; }
		public DateTime datetime { get; set; }
		public string message { get; set; }
		public AppointmentStatus status { get; set; }
	}
	// alerts
	public enum AlertType { // 1 should be the default correct value
		Invalid = 0,
		Unspecified = 1,
		Weather = 2,
		Traffic = 3,
		Service = 4,
		// todo: add more types
	}
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
	public class AlertJson : DataJson {
		// datetime expired summary message importance type status
		public DateTime datetime { get; set; }
		public DateTime expired { get; set; }
		public string summary { get; set; }
		public string message { get; set; }
		public byte importance { get; set; }
		public AlertType type { get; set; }
		public AlertStatus status { get; set; }
	}
}