## Knight Rider
## Wilson @ yyfearth.com
window.offline_mode = not navigator.onLine	
# app init
window.app = # ns
	back: -> history.go -1
	autologin: $('#autologin').val() is 'on'
	offline: -> window.offline_mode or not navigator.onLine
check_online = ->
	if window.offline_mode and navigator.onLine
		if confirm 'You are online now, \npress OK to reload the App and enable online features!'
			location.reload()
		else
			setTimeout arguments.callee, 60000 # 60s
	else setTimeout arguments.callee, 10000 # 10s
check_online() # 10s
$(document.body).addClass 'offline' if app.offline()
# ========== svc ========== 
xss_safe = 
	remove_regex: /on\w{1,20}?=|javascript:/ig # prevent attr injection
	replace_regex: /<|>/g # prevent html esp script
	replace_dict:
		'>': '&gt;'
		'<': '&lt;'
	str: (str) -> # str should be a string
		str = str.toString()
			.replace @remove_regex, ''
			.replace @replace_regex, (p) -> @replace_dict[p]
	json: (json, parse) -> # str is string or json obj, parse = true if need to parse json obj back
		is_str = typeof json is 'string'
		json = JSON.stringify json if not is_str
		json = @str json
		if is_str or not parse then json else JSON.parse json
svc = (svc, cfg) ->
	if svc.svc? and not cfg?
		cfg = svc
		svc = cfg.svc
	else if typeof svc is 'string'
		cfg.svc = svc
	cfg.type = if cfg.type? and /get/i.test(cfg.type) then 'GET' else 'POST'
	cfg.background = true if cfg.nowait
	if cfg.type is 'POST'
		cfg.data = xss_safe.json cfg.data # return json str
	console.log cfg.data
	# start
	$.mobile.showPageLoadingMsg() if not cfg.background
	$.ajax # ajax call
		url: "svc/ajax/#{cfg.svc}.svc/#{cfg.method}"
		type: cfg.type
		dataType: 'json'
		contentType: 'application/json;charset=utf-8'
		data: cfg.data
		processdata: cfg.type isnt 'POST'
		dataFilter: (data, type) -> # safe
			console.log 'data form ajax', type, data
			return xss_safe.str data
		complete: if cfg.background then null else (xhr) ->
			console.log 'ajax returned'
			$.mobile.hidePageLoadingMsg()
			cfg.complete?()
		success: if cfg.nowait then null else (data, txt, xhr) ->
			console.log 'ajax success', data
			if data? and 'd' of data
				cfg.callback? data.d
			else
				alert 'Network Error'
				console.log 'err', xhr, xhr.statusText # error
		error: (xhr) ->
			alert 'Network Error'
			console.log 'err', xhr, xhr.statusText
	return false;
weather_svc = (callback) ->
	$.ajax # ajax call
		url:'gapi?&hl=en-us&weather=san+jose,ca'
		dataType: 'json'
		dataFilter: (data, type) -> # safe
			xss_safe.json JSON.stringify xml2json data # return json str, jq xhr will parse it auto
		success: (j, xhr) ->
			callback j
		error: (xhr) -> console.log 'get weather failed', xhr
date_svc =
	fmt: (d) -> if d > 9 then d.toString() else '0' + d
	dateToWcf: (dt) ->
		o = new Date().getTimezoneOffset() / 60
		return "\/Date(#{ + (Date.parse(dt) - o * 3600000)}#{if o > 0 then '-' else '+'}#{if o>9 then '' else '0'}#{o}00)\/"
	dateFromWcf: (str) ->
		m = str.match /^\/Date\((\d+)([+-]\d{2})(\d{2})\)\/$/
		return null if m.length isnt 4
		ts = Number m[1]
		new Date ts # ts is local already
		#h = Number m[2]
		#console.log 'wcf to date', str, ts, h, new Date(ts - h * 3600000)
		#new Date(ts - h * 3600000)
	dateFromStr: (dt) ->
		new Date dt.replace /-/g, '/'
	dateToStr: (dt) ->
		dt = new Date dt
		"#{dt.getFullYear()}-#{@fmt(dt.getMonth()+1)}-#{@fmt dt.getDate()} #{@fmt dt.getHours()}:#{@fmt dt.getMinutes()}:#{@fmt dt.getSeconds()}"
	dateFromWcfToStr: (str) ->
		@dateToStr @dateFromWcf str
	dateToUTC: (dt) ->
		dt = new Date dt
		"#{dt.getUTCFullYear()}-#{@fmt(dt.getUTCMonth()+1)}-#{@fmt dt.getUTCDate()}T#{@fmt dt.getUTCHours()}:#{@fmt dt.getUTCMinutes()}:#{@fmt dt.getUTCSeconds()}"

# ========== profile ==========
try
	app.user = JSON.parse (sessionStorage.user or localStorage.user)
	if app.user?.uid > 0 and app.user?.sid?.length is 32
		location.hash = '#home'
		if not app.offline() then svc 'user',
			method: 'check'
			data:
				uid: app.user.uid
				sid: app.user.sid
			callback: (ok) ->
				console.log 'check', ok
				$.mobile.changePage('#login', transition: 'none') if not ok
				null # end of callback
	else location.hash = '#login'
catch e
	app.user = null
	location.hash = '#login'
console.log 'app.user', app.user
# save app.user
app.save_profile = window.onbeforeunload = ->
	if app.user?.uid # save user app.user
		p = sessionStorage.user = JSON.stringify app.user
		localStorage.user = p if app.autologin
	else
		localStorage.removeItem 'user'
		sessionStorage.removeItem 'user'
	return #"Sure to leave Knight Rider?"
app.reset = ->
	app.db.reset()
	app.user = null
	app.save_profile()
	window.onbeforeunload = $.noop
	location.reload()
# ========== map ==========
# add back and home button to every page except home
$('[data-role="page"] [data-role="header"]:not(.ui-non-nav)').append $('[data-btn-role="back"],[data-btn-role="home"]')
$('#search [data-btn-role="home"]').hide()
# adjust ref height
b = document.body
map_spacers = $ document.querySelectorAll '[data-role="map"]'
$(window).resize ->
	# console.log 'resize', b.clientWidth, b.clientHeight # debug
	app.horizontal = b.clientWidth > b.clientHeight
	$(b)[if app.horizontal then 'addClass' else 'removeClass'] 'horizontal'
	#map_spacers.add('#map').height Math.round (document.body.clientHeight - 93) * if app.horizontal then 1 else 0.45
$(document.body).resize()
map = app.map = null
# build shared map
if not app.offline()
	#$('#home').one pageshow: -> map.el.offset $('#home_map').offset()
	map = app.map = new google.maps.Map $('#map')[0],
		zoom: 15
		mapTypeId: google.maps.MapTypeId.ROADMAP
		navigationControl: true
		navigationControlOptions: 
			style: google.maps.NavigationControlStyle.SMALL
	map.plcsvc = new google.maps.places.PlacesService map
	map.geocoder = new google.maps.Geocoder()
	map.dirsvc = new google.maps.DirectionsService()
	map.dirrdr = new google.maps.DirectionsRenderer()
	map.svbounds = new google.maps.LatLngBounds new google.maps.LatLng(38.052417,-122.728271), new google.maps.LatLng(37.247821,-121.552734)
	# ========== ext map ==========
	(-> # @ is map
		@el = $ '#map'
		# add traffic
		trafficLayer = new google.maps.TrafficLayer()
		trafficLayer.setMap @
		$.extend @,
			setMarkers: (markers_cfg) =>
				#console.log 'markers', markers_cfg
				if not markers_cfg
					markers_cfg = null
				else if not $.isArray markers_cfg
					markers_cfg = [markers_cfg]
				# clear old markers
				@markers.forEach ((marker) -> marker.setMap null) if @markers?
				# set new markers
				if markers_cfg? # not null
					@markers = markers_cfg.map (cfg) ->
						cfg.map = map # auto set map
						new google.maps.Marker cfg # return
				else @markers = null
				@ # end of set markers
			getCurPos: (auto, callback) => # default auto center
				if not callback?
					callback = auto
					auto = true
				if app.offline()
					callback.call @, null, null
				else navigator.geolocation.getCurrentPosition ((pos) =>
					# get geo location
					curlatlng = map.lastlatlng = new google.maps.LatLng pos.coords.latitude, pos.coords.longitude
					#console.log 'curlatlng', curlatlng
					if not curlatlng.equals @getCenter()
						curlatlng.changed = true
					if auto and curlatlng.changed
						# clear markders
						@setMarkers null
						# set center
						@setCenter curlatlng
						map_spacers.each (i, m) => $(m).css 'background-image', "url('//maps.googleapis.com/maps/api/staticmap?center=#{curlatlng.lat()},#{curlatlng.lng()}&zoom=#{$(m).attr('data-map-zoom') or 15}&size=#{$(window).width()}x#{@el.height()}&maptype=roadmap&format=png8&sensor=true&language=en')"
						# get addr
						map.geocoder.geocode latLng: curlatlng, (results, status) =>
							if status is google.maps.GeocoderStatus.OK
								callback.call @, curlatlng, results[0]?.formatted_address
							else
								alert "Geocoder failed due to: #{status}\n App terminated!"
							# set center again
							@setCenter curlatlng
					else callback.call @, curlatlng
				), (-> alert 'App cannot run without geo location!') if navigator.geolocation?
				@ # end of get cur pos
	).call map # end of ext map
	# ========== sharing map binding ==========
	$('[data-role="page"]').bind
		pagebeforeshow: ->
			map.el.addClass 'hidden'
			# offline check
			#check_online()
			$(document.body)[if app.offline() then 'addClass' else 'removeClass'] 'offline'
		pageshow: ->
			$.mobile.fixedToolbars.show()
			@hh = $('[data-role="header"]', @)?.outerHeight() or 0
			@fh = $('[data-role="footer"]', @)?.outerHeight() or 0
			@bh = document.body.clientHeight - @hh - @fh
			map.el.css 'top', @hh
			$('.map', @).add(map.el).height @bh * if app.horizontal then 1 else 0.45
			map.el.removeClass 'hidden' if $(@).hasClass('has-map')
# init map if online

# ========== weather ==========
app.sync_weather = ->
	ref_w = (j) ->
		if j.weather?.current_conditions?
			cur = j.weather.current_conditions
			console.log 'weather', j
			getIcon = (d) -> "//www.google.com" + d.icon.data
			el = $('#weather').html "<div id=\"weather_now\" class=\"weather\"><img src=\"#{getIcon cur}\"/>#{cur.condition.data}<br/>#{cur.temp_f.data}\u00b0F</div>" # \u00b0=°
			el.append (j.weather.forecast_conditions.map (c) ->
				"<div class=\"weather\"><img src=\"#{getIcon c}\"/>#{c.day_of_week.data} #{c.high.data}/#{c.low.data}\u00b0F</div>"
			).join ''
		else
			$('#weather').html '(No Weather Data)'
		@ # end
	if not app.offline() then weather_svc (j, xhr) ->
		localStorage.weather = JSON.stringify j
		ref_w j
	else if localStorage.weather?
		ref_w JSON.parse localStorage.weather
	else ref_w null

# ========== utils ==========
`function xml2json(b,g,h){function j(b,g){if(!b)return null;var c="",a=null;if(b.childNodes&&0<b.childNodes.length)for(var i=0;i<b.childNodes.length;i++){var d=b.childNodes[i],f=d.nodeType,e=d.localName||d.nodeName||"",h=d.text||d.nodeValue||"";if(8!=f)if(3==f||4==f||!e)c+=h.replace(/^\s+|\s+$/g,"");else if(a=a||{},a[e]){if(!(a[e]instanceof Array)||!a[e].length)a[e]=[a[e]];a[e].push(j(d,!0))}else a[e]=j(d,!1)}if(b.attributes&&!k&&0<b.attributes.length){a=a||{};for(d=0;d<b.attributes.length;d++)e=b.attributes[d],f=e.name||"",e=e.value,a[f]?(!(a[f]instanceof Array)&&a[f].length&&(a[f]=[a[f]]),a[f].push(e)):a[f]=e}if(a){if(""!=c){d=new String(c);for(i in a)d[i]=a[i];a=d}if(c=a.text?("object"==typeof a.text?a.text:[a.text||""]).concat([c]):c)a.text=c;c=""}a=a||c;if(l){c&&(a={});if(c=a.text||c||"")a.text=c;!g&&!(a instanceof Array)&&(a=[a])}return a}var l=g,k=h;if(!b)return{};"string"==typeof b&&(b=q(b));if(b.nodeType){if(3==b.nodeType||4==b.nodeType)return b.nodeValue;b=9==b.nodeType?b.documentElement:b;g=j(b,!0);b=b=null;return g}}function q(b){var g;try{var h=new DOMParser;h.async=!1;g=h.parseFromString(b,"text/xml")}catch(j){throw Error("Error parsing XML string");}return g}`
`function sha1(a){for(var d=[],b=0;b<8*a.length;b+=8)d[b>>5]|=(a.charCodeAt(b/8)&255)<<24-b%32;a=8*a.length;d[a>>5]|=128<<24-a%32;d[(a+64>>9<<4)+15]=a;for(var a=Array(80),b=1732584193,e=-271733879,f=-1732584194,g=271733878,i=-1009589776,j=0;j<d.length;j+=16){for(var k=b,l=e,m=f,n=g,o=i,c=0;80>c;c++){a[c]=16>c?d[j+c]:(a[c-3]^a[c-8]^a[c-14]^a[c-16])<<1|(a[c-3]^a[c-8]^a[c-14]^a[c-16])>>>31;var p=h(h(b<<5|b>>>27,20>c?e&f|~e&g:40>c?e^f^g:60>c?e&f|e&g|f&g:e^f^g),h(h(i,a[c]),20>c?1518500249:40>c?1859775393:60>c?-1894007588:-899497514)),i=g,g=f,f=e<<30|e>>>2,e=b,b=p}b=h(b,k);e=h(e,l);f=h(f,m);g=h(g,n);i=h(i,o)}d=[b,e,f,g,i];a="";for(b=0;b<4*d.length;b++)a+="0123456789abcdef".charAt(d[b>>2]>>8*(3-b%4)+4&15)+"0123456789abcdef".charAt(d[b>>2]>>8*(3-b%4)&15);return a};function h(a,d){var b=(a&65535)+(d&65535);return(a>>16)+(d>>16)+(b>>16)<<16|b&65535};`
hash = (str1, str2) ->
	h = 'KnightRider\x58\xb5\x04\x05\xf1\x50\x47\x6f\xf0\x40\xd8\xf4\xed\x9d\xd2\x79\xc0\x6e\xa6\xd9\xffKnightRider'
	sha1(h + str1 + sha1(h + str1 + '\xff' + str2 + h) + str2 + h)
### ----- dev only -----
if localStorage.places?
	pls = JSON.parse localStorage.places
	c = 0
	for id, o of pls
		do (id, o) ->
			c++
			map.plcsvc.getDetails (reference: o.ref), (p, status) ->
				if status is google.maps.places.PlacesServiceStatus.OK
					pp =
						gid: p.id
						name: p.name
						location:
							lat: p.geometry.location.lat()
							lng: p.geometry.location.lng()
						vicinity: p.vicinity
						fulladdr: p.formatted_address
						phone: p.formatted_phone_number
						website: if p.website? then (p.website.replace /^http:\/\//, '') else p.url.replace /^.*cid=(\d+).*$/, 'place:$1'
						rating: if p.rating? then p.rating else null
						gtypes: p.types.join ','
						svctypes: o.t
					console.log p, status, pp
					svc 'place',
						method: 'add'
						data: place: pp
	console.log c
return
# --------------------###
#  ========== local db ==========
if window.openDatabase?
	app.db = openDatabase("KnightRider", "1.0", "Data cache for Knight Rider", 200000);
	if app.db?
		app.db._onerr = (t, e) -> console.error 'local db error', t, e
		app.db.reset = -> app.db.transaction (tx) ->
			tx.executeSql "DROP TABLE IF EXISTS Alerts;"
			tx.executeSql "DROP TABLE IF EXISTS Place;"
		app.db.sync = (svc_name, callback) ->
			console.log 'sync', svc_name
			svc_name = svc_name.toLowerCase()
			app.db.transaction (tx) ->
				tx.executeSql "SELECT modified FROM [#{svc_name}] WHERE id=0", [], (tx, data) ->
					last = data.rows.item 0
					console.log 'last', svc_name, last
					svc svc_name,
						method: 'sync'
						type: 'get'
						background: true
						data:
							last: date_svc.dateToStr last.modified.replace /-/g, '/'
						callback: (data) ->
							console.log 'sync', svc_name, data
							callback? data
			@ # end of sync
		load_values = (rows, trans) ->
			rs = []
			i = rows.length
			while i
				row = $.extend {}, rows.item --i
				row.created = new Date row.created.replace /-/g, '/'
				row.modified = new Date row.modified.replace /-/g, '/'
				trans? row
				rs.unshift row
			rs
		load_places = (rows) ->
			load_values rows, (row) ->
				row.canappt = /true/i.test row.canappt
				row.location = lat: row.lat, lng: row.lng
		load_alerts = (tx, callback) ->
			tx.executeSql "SELECT * FROM [Alerts] WHERE status=1 and expired > DATETIME('now','localtime')
ORDER BY datetime DESC, importance DESC;", [], ((tx, ret) ->
				#console.log 'alerts count', ret.rows.length
				rows = load_values ret.rows, (row) ->
					row.datetime = new Date row.datetime.replace /-/g, '/'
					row.expired = new Date row.expired.replace /-/g, '/'
				console.log 'alerts from db', rows, ret
				callback? rows, 'alerts'
			), app.db._onerr
			@ # end of load alerts
		app.db.sync_alerts = (callback) ->
			if app.offline()
				app.db.transaction load_alerts
			else app.db.sync 'alerts', (data) ->
				app.db.transaction (tx) ->
					if data.length
						ids = data.map (a) -> a.id
						vals = data.map (a) -> [
							a.id
							a.summary
							a.message
							date_svc.dateFromWcfToStr(a.datetime)
							date_svc.dateFromWcfToStr(a.expired)
							a.importance
							a.type
							a.status
							date_svc.dateFromWcfToStr(a.created)
							date_svc.dateFromWcfToStr(a.modified)
						]
						sql = "INSERT INTO [Alerts](id,summary,message,datetime,expired,importance,type,status,created,modified) VALUES (?,?,?,?,?,?,?,?,?,?);" # insert new rows
						console.log 'db', sql, vals
						tx.executeSql "DELETE FROM [Alerts] WHERE id IN (#{ids.join(',')})" # delete old
						vals.forEach (val) -> tx.executeSql sql, val
						tx.executeSql "UPDATE [Alerts] SET modified=DATETIME('now','localtime') WHERE id=0" # update last
						# end of if length
					load_alerts tx, callback
					@ # end of transaction
				@ # end of sync
			@ # end of alerts sync
		app.db.sync_place = -> # sync
			return if app.offline()
			app.db.sync 'place', (data) ->
				if data.length then app.db.transaction (tx) ->
					ids = data.map (p) -> p.id
					vals = data.map (p) -> [
						p.id
						p.gid
						p.name
						p.location.lat
						p.location.lng
						p.vicinity
						p.fulladdr
						p.phone
						p.email
						p.website
						p.rating
						p.gtypes
						p.svctypes
						p.openhours
						p.canappt
						p.status
						date_svc.dateFromWcfToStr(p.created)
						date_svc.dateFromWcfToStr(p.modified)
					]
					sql = "INSERT INTO [Place](id,gid,name,lat,lng,vicinity,fulladdr,phone,email,website,rating,gtypes,svctypes,openhours,canappt,status,created,modified)
VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);" # insert new rows
					console.log 'db', sql, vals
					tx.executeSql "DELETE FROM [Place] WHERE id IN (#{ids.join(',')})" # delete old
					vals.forEach (val) -> tx.executeSql sql, val, null, app.db._onerr
					tx.executeSql "UPDATE [Place] SET modified=DATETIME('now','localtime') WHERE id=0" # update last
		app.db.query_place = (svct, callback) ->
			app.db.transaction (tx) -> tx.executeSql "SELECT * FROM [Place] WHERE status<>0 and svctypes&#{svct}<>0;", [], ((tx, ret) ->
				#console.log 'place query count', ret.rows.length
				rows = load_places ret.rows
				console.log 'place from db', rows, ret
				callback? rows
			), app.db._onerr
			@ # end of query place
		app.db.get_place = (gids, callback) ->
			gids = [gids] if not $.isArray gids
			app.db.transaction (tx) -> tx.executeSql "SELECT * FROM [Place] WHERE gid in ('#{gids.join '\',\''}');", [], ((tx, ret) ->
				rows = load_places ret.rows
				callback? rows
			), app.db._onerr
			@ # end of query place
		# create table
		app.db.transaction (tx) ->
			console.log 'init tables'
			tx.executeSql "CREATE TABLE IF NOT EXISTS [Alerts] (
				id int not null primary key, 
				summary nvarchar(100) not null, 
				message text, 
				datetime datetime, 
				expired datetime, 
				importance tinyint not null, 
				type tinyint not null, 
				status tinyint not null,
				created datetime not null, 
				modified datetime not null
			);"
			#console.log 'init alerts'
			tx.executeSql "CREATE INDEX IF NOT EXISTS [Alerts_ODR] ON [Alerts] (datetime DESC, importance DESC);"
			tx.executeSql "INSERT INTO [Alerts](id,summary,importance,type,status,created,modified)
SELECT 0,'LastUpdate',0,0,0,DATETIME('now','localtime'),DATETIME(0,'unixepoch','localtime')
WHERE NOT EXISTS(SELECT * FROM [Alerts] WHERE id=0);"
			tx.executeSql "CREATE TABLE IF NOT EXISTS [Place] (
				id int not null primary key, 
				gid char(40),
				name nvarchar(100),
				lat float,
				lng float,
				vicinity nvarchar(200),
				fulladdr nvarchar(1000),
				phone varchar(15),
				email varchar(100),
				website varchar(100),
				rating tinyint,
				gtypes varchar(100),
				svctypes tinyint not null,
				openhours text,
				canappt bit not null,
				status tinyint not null,
				created datetime not null,
				modified datetime not null
			);"
			#console.log 'init place'
			tx.executeSql "CREATE UNIQUE INDEX IF NOT EXISTS [Place_GID] ON [Place] (GID);"
			tx.executeSql "CREATE INDEX IF NOT EXISTS [Place_TYP] ON [Place] (svctypes);"
			tx.executeSql "INSERT INTO [Place](id,name,canappt,svctypes,status,created,modified)
SELECT 0,'LastUpdate',0,0,0,DATETIME('now','localtime'),DATETIME(0,'unixepoch','localtime')
WHERE NOT EXISTS(SELECT * FROM [Place] WHERE id=0);"
			#console.log 'finish init tables'
	else alert 'open db err'

# ========== pages ==========
# home page
$('#home').bind
	pagecreate: -> @created = true
	pagebeforeshow: ->
		#console.log 'home pageshow'
		created = @created
		# init nav api and home page
		if app.offline()
			$('#home_addr').text 'You are offline now'
		else if not window.offline_mode
			map.getCurPos (curlatlng, addr) ->
				$('#home_addr').text addr if addr? # set addr info
				@setZoom 15
				@setMarkers position: curlatlng # set cur marker
		# sync weather
		app.sync_weather()
		# sync place
		app.db.sync_place()
		# sync alerts
		app.db.sync_alerts (alerts) ->
			console.log 'alerts', alerts
			alert_el = $('#alerts').empty()
			html = '<li data-role="list-divider" class="ui-body-c list-none">No Alerts</li>'
			html = "<li data-role=\"list-divider\" class=\"ui-body-c list-none\">#{alerts.length} Alerts</li>" + alerts.map((a) ->
				msg = "Summary: #{a.summary}\\nMessage: #{a.message}\\nFrom: #{a.datetime}\\nExpire: #{a.expired}".replace /'/g, "\\'"
				"<li><a href=\"javascript:alert('#{msg}')\">#{a.summary} (#{a.datetime.toLocaleDateString()})</a></li>"
			).join '' if alerts.length > 0
			$('#alerts').html(html).listview().listview 'refresh'
		#@auto = setInterval (->
		#	map.getCurPos (curlatlng, addr) -> $('#home_addr').text addr if addr? # set addr info
		#), 30000 # every 30s
		#maps.getCurPos ((curlatlng) -> @map.mark curlatlng) if @map? and not @map.getCenter()?.equals curlatlng
		@ # end of home page show
	pageshow: ->
		alert_el = $('#alerts')
		alert_el.height document.body.clientHeight - alert_el.offset().top - @fh
	#pagehide: ->
		#@auto = clearInterval @auto

# login dlg
$('#login').bind
	pagecreate: ->
		$('#login_form').submit (e) ->
			#fields = @fields = 
			#$('input, select', @)
			e.preventDefault()
			e.stopPropagation()
			#@fields.mobile 'disable'
			return false if app.offline()
			# start
			inputs = $('input', @).textinput 'disable'
			slider = $('select', @).slider 'disable'
			btns = $('button', @).button 'disable'
			$('#btn_reg').addClass 'ui-disabled'
			email = $('#email').val().trim()
			password = $('#password').val()
			return false if not email or not password
			pk = hash email.toLowerCase(), password
			app.autologin = $('#autologin').val() is 'on'
			svc 'user',
				method: 'login'
				data:
					email: email
					password: pk
				callback: (data) ->
					if data.uid and data.sid?.length is 32
						app.user = uid: data.uid, email: email, sid: data.sid, psw: hash(data.sid + data.uid + pk)
						$.mobile.changePage '#home', transition: 'flip'
					else
						alert 'Login Failed, please try again'
				complete: ->
					btns.button 'enable'
					inputs.textinput 'enable'
					slider.slider 'enable'
					$('#btn_reg').removeClass 'ui-disabled'
			false # end of submit
		@ # end of login
	pagebeforehide: -> $('#login_form_warp').hide()
	pagebeforeshow: -> $('#login_form_warp').hide()
	pageshow: ->
		$('#password').val ''
		$('#login_form_warp').show()
		if not app.offline()
			$('button', @).button 'enable'
			$('#btn_reg').removeClass 'ui-disabled'
			return if not app.user?
			console.log 'logout', app.user
			svc 'user',
				method: 'logout'
				nowait: true
				data:
					uid: app.user.uid
					sid: app.user.sid
			app.user = null
			app.save_profile()
		else
			$('button', @).button 'disable'
			$('#btn_reg').addClass 'ui-disabled'
			alert 'You are offline now!\nLogin need a network.' if app.offline()
		@ # end of show

# reg dlg
$('#reg_form').submit (e) ->
	e.preventDefault()
	e.stopPropagation()
	return false if app.offline()
	if @password.value isnt @password2.value
		alert 'Password does not match!'
		@password2.focus()
		return false
	email = @email.value.trim()
	password = @password.value
	pk = hash email.toLowerCase(), password
	u =
		email: email
		password: pk
		fullname:
			first: @first.value.trim()
			last: @last.value.trim()
		phone: @phone.value.trim()
	console.log 'reg', u
	svc 'user',
		method: 'reg'
		data: (user: u),
		callback: (uid) ->
			console.log 'new id:', uid
			if uid < 1
				alert 'Email already exists!'
			else
				$('#email').val u.email
				$('#reg').dialog 'close'
				alert 'Registration successful!'
	false

# appointment page
$('#appointment').bind pagebeforeshow: ->
	return app.back() if app.offline()
	$('#datetime').val Date(new Date().getTime() + 60 * 60 * 1000).toLocaleString()
	$.mobile.changePage '#login', (transition: 'flip', reverse: true) if not (app.user?.sid?.length is 32)
	false
$('#appt_form').submit (e) ->
	return false if not (app.user?.sid?.length is 32) or (app.user?.uid is 0) or app.offline()
	e.preventDefault()
	e.stopPropagation()
	# validate hours
	appt =
		user: app.user.uid
		place: app.selected_place.id
		contact:
			name: @name.value
			phone: @phone.value
		datetime: date_svc.dateToWcf @datetime.value
		message: @comments.value
	console.log 'appt', appt
	svc 'appointment',
		method: 'add'
		data:
			appt: appt
			sid: app.user.sid
		callback: (success) ->
			console.log 'appt success:', success
			if !success
				$.mobile.changePage '#login', (transition: 'flip', reverse: true)
			else
				$('#appointment').dialog 'close'
				alert 'Appointment sent successful!'
	false

# search menu page
$('#search').bind pageshow: ->
	#@map.keyword = null if @map? # clear app.search_keyword
	$('#btn_custom_search')[if app.offline() then 'addClass' else 'removeClass'] 'ui-disabled'
# bind buttons and menus
$('[data-btn-role="search"]').live vclick: (e) ->
	app.search_keyword = $(@).text()
	#console.log 'vclick', app.search_keyword
	@ # end of vclick

app.custom_search_history_refresh = ->
	$('#custom_history_list li:gt(0)').remove() # remove all except custom_history_list_header
	l = '<li data-role="list-divider" class="ui-body-c list-none">(None)</li>'
	l = app.user.custom_search_history.map((item) ->
		"<li><a href=\"#result\" data-btn-role=\"search\">#{item}</a></li>"
	).join '' if app.user.custom_search_history?.length
	$('#custom_history_list_header').after l
app.place_search_history_refresh = ->
	$('#search_history_list li:gt(0)').remove() # remove all except custom_history_list_header
	l = '<li data-role="list-divider" class="ui-body-c list-none">(None)</li>'
	l = app.user.place_search_history.map((r, i) ->
		img = if r.icon? and not app.offline() then "<img src=\"#{r.icon}\" class=\"ui-li-icon\"/>" else ''
		"<li><a href=\"#detail\" data-btn-role=\"result\" data-index=\"#{i}\">#{img}
<h3 class=\"ui-li-heading\">#{r.name}</h3><p class=\"ui-li-desc\">#{r.vicinity}</p></li>"
	).join '' if app.user.place_search_history?.length
	$('#search_history_list_header').after l

# custom search page
$('#custom_search').bind
	pagecreate: ->
		@created = true
		app.custom_search_history_refresh() # for the 1st show
		if not app.offline() then new google.maps.places.Autocomplete $('#input_search')[0],
			bounds: map.svbounds
			types: ['establishment']
	pagebeforeshow: ->
		app.back() if app.offline()
$('#custom_search').bind 'pageshow pagebeforeshow', -> $('#custom_history_list').listview 'refresh' if @created
$('#custom_search_form').submit ->
	input = $('#input_search')
	keyword = $.trim input.val()
	if keyword
		app.search_keyword = new String(keyword)
		$.mobile.changePage '#result'
		#console.log 'vclick', app.search_keyword
	else input.focus().val ''
	false # end of submit

# search history page
$('#search_history').bind pagecreate: ->
	@created = true
	app.place_search_history_refresh()
	$('#search_history li a').live vclick: ->
		app.selected_place = app.user.place_search_history[Number $(@).attr 'data-index']
$('#search_history').bind 'pageshow pagebeforeshow', -> $('#search_history_list').listview 'refresh' if @created

place_svc_typs =
	'Service Station': 2
	'Gas Station': 4
	'Towing Station': 8
	'Vehicle Repair Station': 16

# result page
$('#result').bind
	pageshow: ->
		result_list = $('#result_list')
		result_list.height document.body.clientHeight - result_list.offset().top
		@ # end of create
	pagebeforeshow: ->
		console.log 'search for', app.search_keyword
		if not app.search_keyword
			app.back()
			return
		$.mobile.showPageLoadingMsg()
		sort_results = (results, cur) ->
			app.result_map = {} # for detail
			console.log 'sort', results, cur
			results.forEach (r) ->
				app.result_map[r.gid] = r # for detail
				dlng = r.location.lng - cur.lng
				dlat = r.location.lat - cur.lat
				r.dist = Math.pow(dlng, 2) + Math.pow(dlat, 2)
			results.sort (a, b) -> a.dist - b.dist
			return results.slice 0, 25 # only A-Z
		#@map.keyword = null # init app.result.keyword
		#app.result.keyword = app.search_keyword
		# clear old results
		result_list = $('#result_list').empty()
		thispage = $ @
		# create new results
		if app.offline()
			if not place_svc_typs[app.search_keyword]?
				alert 'You are offline now.\nCustom Search is disabled'
			else app.db.query_place place_svc_typs[app.search_keyword], (results) ->
				show_ret = (pos) ->
					# sort results
					if pos? then results = sort_results results,
						lat: pos.coords.latitude
						lng: pos.coords.longitude
					else thispage.one pageshow: -> alert 'Cannot get your current location while offline.\n
The results is unsorted and maybe not nearby.\nIn another word, the 1st result does not means the nearest.\n
You need select the place by yourself.'
					$('#result_addr').text "[Offline] #{app.search_keyword} (#{results.length})"
					# add to list in order
					result_list.append results.map((r, i) ->
						seq = if pos? then "<div style=\"float:left\">#{String.fromCharCode 65 + i}</div>" else ''
						#console.log seq, pos
						"<li><a href=\"#detail\" data-btn-role=\"result\" id=\"#{r.gid}\">
#{seq}<h3 class=\"ui-li-heading\">#{r.name}</h3><p class=\"ui-li-desc\">#{r.vicinity}</p></li>"
					).join ''
					result_list.listview 'refresh'
					@ # end of show ret
				navigator.geolocation.getCurrentPosition ((pos) -> show_ret pos), (-> show_ret(app.map?.lastlatlng)) if navigator.geolocation?
				@ # end of query place
		else map.getCurPos (curlatlng, addr) ->
			@setZoom 12
			#@move 'result'
			# search result
			map.plcsvc.search
				#bounds: map.svbounds
				location: curlatlng
				radius: 5000
				keyword: app.search_keyword
				#types: ['store']
				(results, status) -> # search callback
					if status is google.maps.places.PlacesServiceStatus.ZERO_RESULTS
						alert 'Zero Result'
						app.back()
					else if status is google.maps.places.PlacesServiceStatus.OK
						results.forEach (r) ->
							r.gid = r.id
							r.location = lat: r.geometry.location.lat(), lng: r.geometry.location.lng()
						# ----- dev only -----
						###console.log 'search result', results
						pls = if localStorage.places? then JSON.parse(localStorage.places) else {}
						results.forEach (r) ->
							if pls[r.id]?
								pls[r.id].ref |= place_svc_typs[app.search_keyword]
							else
								pls[r.id] = {t:place_svc_typs[app.search_keyword],ref:r.reference}
						localStorage.places = JSON.stringify pls###
						# --------------------
						# sort results
						results = sort_results results,
							lat: curlatlng.lat()
							lng: curlatlng.lng()
						$('#result_addr').text "#{app.search_keyword} (#{results.length})"
						# add to list in order
						result_list.append results.map((r, i) ->
							r.seq = String.fromCharCode 65 + i # from A
							"<li><a href=\"#detail\" data-btn-role=\"result\" id=\"#{r.id}\">
<div style=\"float:left\">#{r.seq}</div><img src=\"#{r.icon?.replace /^http:/, ''}\" class=\"ui-li-icon\"/>
<h3 class=\"ui-li-heading\">#{r.name}</h3><p class=\"ui-li-desc\">#{r.vicinity}</p></li>"
						).join ''
						result_list.listview 'refresh'
						# show marking in rev order
						markers = results.reverse().map (result) ->
							position: result.geometry.location
							icon: "//www.google.com/mapfiles/marker#{result.seq}.png"
							title: result.name
						# add marker
						markers.push
							position: curlatlng
							icon: '//www.google.com/mapfiles/arrow.png'
							title: 'You are here'
						# set markers to map
						map.setMarkers markers
						# save custom search history
						if not place_svc_typs[app.search_keyword]?
							hs = app.user.custom_search_history ?= []
							if hs.length is 0 or hs[0] isnt app.search_keyword
								hs.unshift app.search_keyword
								app.custom_search_history_refresh() # refresh list
					else alert 'Search Error'
					@ # end of search callback
		@ # end of result page show

# detail
proc_rating = (rating) ->
	rating = Number(rating)
	stars = rating.toFixed(1)
	i = rating | 0
	stars += ' ' + new Array(i + 1).join('<img src="res/star.png"/>') if i > 0
	stars += '<img src="res/halfstar.png"/>' if rating - i > 0.4
	stars # end of proc rating
$('#result_list a').live vclick: ->
	#console.log @id
	app.selected_place = app.result_map[@id]
$('#detail').bind
	pagecreate: ->
		$('#apt_cancel').bind vclick: (e) ->
			e.preventDefault()
			e.stopPropagation()
			$('#appointment').dialog('close')
			false # end fo create
	pageshow: ->
		detial_info = $('#detial_info').empty()
		detial_info.height document.body.clientHeight - detial_info.offset().top - @fh
		console.log 'start get detail of', app.selected_place
		window.scrollTop = 0
		if not app.selected_place
			app.back()
			return
		$('[data-role="navbar"]', @)[if app.offline() then 'hide' else 'show']()
		show_detail = (place) ->
			console.log 'show detail', place
			$('#btn_appt')[if not place.canappt then 'addClass' else 'removeClass'] 'ui-disabled' if not app.offline()
			if app.map?
				map.setCenter place.geometry.location
				map.setMarkers position: place.geometry.location
				map.setZoom 15
			$('#detail_place').text place.name
			ln_type = 'Visit its Website'
			if place.website?
				if /^place:\d+/.test place.website
					place.website = place.website.replace 'place:', 'http://maps.google.com/maps/place?cid='
					ln_type = 'View on Google Place'
				if not /^http/.test place.website
					place.website = 'http://' + place.website
			else
				place.website = place.url
				ln_type = 'View on Google Place'
			detial_info.html "<ul>
<li>#{place.fulladdr}</li><li>#{place.phone}</li>
<li>#{place.gtypes.replace(/_/g, ' ').toUpperCase()}</li>
<li>#{if place.rating? then proc_rating(place.rating) else '(No Rating Yet)' }</li>
<li><a href=\"#{place.website}\" target=\"_blank\">#{ln_type}</a></li>
<li>This place #{if place.canappt then 'CAN' else 'CANNOT'} make Appointment</li>
#{if app.offline() then '<li>You are offline now, neigher Appointment nor Direction is available!</li>' else ''}</ul>"
			# save history
			psh = app.user.place_search_history ?= []
			if psh.length is 0 or psh[0].id isnt app.selected_place.id
				psh.some (h, i) ->
					if h.id is app.selected_place.id
						psh.splice i, 1 # del
						return true
					false
				psh.unshift
					gid: place.gid
					reference: app.selected_place.reference
					name: place.name
					vicinity: place.vicinity
					icon: place.icon?.replace /^http:/, ''
				app.place_search_history_refresh()
			#console.log place
			@ # end of show detail
		sel_p = app.selected_place
		if sel_p.gtypes?
			show_detail sel_p
		else app.db.get_place sel_p.gid, (p) ->
			if p.length
				p = p[0]
				$.extend sel_p, p
				show_detail sel_p
			else if not app.offline()
				map.plcsvc.getDetails (reference: sel_p.reference), (p, status) ->
					if status is google.maps.places.PlacesServiceStatus.OK
						sel_p.gid = p.id
						sel_p.fulladdr = p.formatted_address
						sel_p.phone = p.formatted_phone_number
						sel_p.gtypes = p.types.join ','
						sel_p.phone = p.phone
						sel_p.website = p.website
						sel_p.rating = p.rating
						sel_p.canappt = false
						show_detail sel_p
					else alert 'Get Details Failed'
			else
				alert 'You are offline now, and there is no this place\'s data on local database'
				app.back()
		@ # end of show

# direction page
$('#direction').bind
	pagebeforeshow: ->
		if app.offline()
			app.back()
			return
		direction_panel = $('#direction_panel')
		#curloc = -> map.getCurPos (curlatlng, addr) -> @setMarkers position: curlatlng if addr? # set cur marker
		#@auto = setInterval curloc, 10000 # every 10s
		map.getCurPos (curlatlng, addr) ->
			map.dirsvc.route (
				origin: addr
				destination: app.selected_place.vicinity # formatted_address
				travelMode: google.maps.DirectionsTravelMode.DRIVING # or BICYCLING WALKING
				unitSystem: google.maps.DirectionsUnitSystem.IMPERIAL # or METRIC
				provideRouteAlternatives: true
			), (dirResult, dirStatus) ->
				if dirStatus is google.maps.DirectionsStatus.OK
					# Show directions
					map.dirrdr.setMap map
					map.dirrdr.setPanel direction_panel[0]
					map.dirrdr.setDirections(dirResult)
					# show self
					#curloc()
				else alert('Directions failed: ' + dirStatus)
		@ # end of before show
	pageshow: ->
		direction_panel = $('#direction_panel')
		direction_panel.height document.body.clientHeight - direction_panel.offset().top
		@
	pagehide: ->
		#@auto = clearInterval @auto
		map.dirrdr.setMap null
#  ========== end ==========
console.log 9, 'Wilson' # jsmin app.js && rm app.js && mv app.min.js app.js
