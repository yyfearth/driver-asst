using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Runtime.Serialization;

namespace KnightRider {
	[DataContract]
	public class DataJson {
		[DataMember]
		public uint id { get; set; }
		[DataMember]
		public DateTime created { get; set; }
		[DataMember]
		public DateTime modified { get; set; }
		private dynamic ExtraData { get; set; } // json
	}
	// user
	[DataContract]
	public enum UserType { // 1 should be the default correct value
		[EnumMember]
		Invalid = 0,
		[EnumMember]
		Unspecified = 1,
		[EnumMember]
		Driver = 2,
		[EnumMember]
		VIP = 3,
		// todo: add more types
	}
	[DataContract]
	public enum UserStatus { // 1 should be the default correct value
		[EnumMember]
		Invalid = 0,
		[EnumMember]
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
	[DataContract, Flags]
	public enum PlaceSvcType { // 1 should be the default correct value
		[EnumMember]
		Invalid = 0,
		[EnumMember]
		Unspecified = 1, // All
		[EnumMember]
		ServiceStation = 2,
		[EnumMember]
		GasStation = 4,
		[EnumMember]
		TowingStation = 8,
		[EnumMember]
		RepairStation = 16,
		// todo: add more types
	}
	[DataContract]
	public enum PlaceStatus { // 1 should be the default correct value
		[EnumMember]
		Invalid = 0,
		[EnumMember]
		Normal = 1,
		// todo: add more status
	}
	[DataContract]
	public class PlaceJson : DataJson {
		// name,vicinity,fulladdr,location,rating,phone,website,gtypes,svctypes,status,gid,gref
		//private float? _rating;
		[DataContract]
		public class GeoLocation {
			[DataMember]
			public double lat { get; set; }
			[DataMember]
			public double lng { get; set; }
		}
		[DataMember]
		public string name { get; set; }
		[DataMember]
		public string vicinity { get; set; }
		[DataMember]
		public string fulladdr { get; set; } // formatted_address
		[DataMember]
		public GeoLocation location { get; set; } // geometry.location
		[DataMember]
		public float? rating { get; set; }
		[DataMember]
		public string email { get; set; }
		[DataMember]
		public string phone { get; set; } // formatted_phone_number
		[DataMember]
		public string website { get; set; } // website or google place page url
		[DataMember]
		public string gtypes { get; set; } // types
		[DataMember]
		public bool canappt { get; set; }
		[DataMember]
		public string openhours { get; set; }
		[DataMember]
		public PlaceSvcType svctypes { get; set; } // multi
		[DataMember]
		public PlaceStatus status { get; set; }
		[DataMember]
		public string gid { get; set; } // id
	}
	// appointment
	[DataContract]
	public enum AppointmentStatus { // 1 should be the default correct value
		[EnumMember]
		Invalid = 0,
		[EnumMember]
		Created = 1, // init
		[EnumMember]
		Received = 2,
		[EnumMember]
		Approved = 3,
		[EnumMember]
		Rejected = 4,
		// todo: add more types
		[EnumMember]
		Expired = 8,
		[EnumMember]
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
		[EnumMember]
		Invalid = 0,
		[EnumMember]
		Unspecified = 1,
		[EnumMember]
		Weather = 2,
		[EnumMember]
		Traffic = 3,
		[EnumMember]
		Service = 4,
		// todo: add more types
	}
	[DataContract]
	public enum AlertStatus { // 1 should be the default correct value
		[EnumMember]
		Invalid = 0,
		[EnumMember]
		Normal = 1,
		// these shoud be auto calc, and auto clear after expire
		//Saved = 1,
		//Started = 2,
		//Expired = 3,
		// todo: add more status
		[EnumMember]
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
