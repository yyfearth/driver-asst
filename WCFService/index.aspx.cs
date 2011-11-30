using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace KnightRider {
	public partial class WebForm1 : System.Web.UI.Page {
		protected void Page_Load(object sender, EventArgs e) {
			var r = DataAccess.ValidateUser("yyfearth@gmail.com", "2nfbn72519np2yuoooigtgzvmmb7ptz");
			Response.Write(r);
			/*var svc = new User();
			var u = new UserJson() {
				email = "wilson@yyfearth.com",
				fullname = new UserJson.Fullname() {
					first = "Wilson",
					last = "Young",
				},
				password = "133cienawtkxiwvfahpwyom8zukd8v4dp1",
				phone = "0001112233",
			};
			var uid = DataAccess.AddUser(u);
			svc.login(u.email, u.password);*/
		}
	}
}