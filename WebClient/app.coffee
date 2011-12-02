## Knight Rider
## Wilson @ yyfearth.com
# app init
window.app = # ns
	back: -> history.go -1
	autologin: $('#autologin').val() is 'on'
# svc
svc = (svc, cfg) ->
	if svc.svc? and not cfg?
		cfg = svc
		svc = cfg.svc
	else if typeof svc is 'string'
		cfg.svc = svc
	cfg.type = if cfg.type? and /get/i.test(cfg.type) then 'GET' else 'POST'
	cfg.data = JSON.stringify cfg.data if cfg.type is 'POST'
	# start
	$.mobile.showPageLoadingMsg() if not cfg.nowait

	$.ajax
		url: "svc/#{cfg.svc}.svc/#{cfg.method}"
		type: cfg.type
		dataType: 'json'
		contentType: 'application/json;charset=utf-8'
		data: cfg.data
		processdata: cfg.type isnt 'POST'
		complete: (xhr) ->
			return if cfg.nowait
			$.mobile.hidePageLoadingMsg()
			cfg.complete?()
		success: (data, txt, xhr) ->
			return if cfg.nowait
			if data? and 'd' of data
				cfg.callback? data.d
			else
				alert 'Network Error'
				console.log 'err', xhr, xhr.statusText # error
		error: (xhr) ->
			alert 'Network Error'
			console.log 'err', xhr, xhr.statusText
	return false;
date_svc =
	dateToWcf: (dt) ->
		o = new Date().getTimezoneOffset() / 60
		return "\/Date(#{ + (Date.parse(dt) - o * 3600000)}#{if o > 0 then '-' else '+'}#{if o>9 then '' else '0'}#{o}00)\/"
	dateFromWcf: (str) ->
		m = str.match /^\/Date\((\d+)([+-]\d{2})(\d{2})\)\/$/
		return null if m.length isnt 4
		ts = Number m[1]
		h = Number m[2]
		new Date(ts - h * 3600000)
	dateToStr: (dt) ->
		dt = new Date(dt)
		"#{dt.getFullYear()}-#{dt.getMonth() + 1}-#{dt.getDate()} #{dt.getHours()}:#{dt.getMinutes()}:#{dt.getSeconds()}"
	dateToUTC: (dt) ->
		dt = new Date(dt)
		"#{dt.getUTCFullYear()}-#{dt.getUTCMonth() + 1}-#{dt.getUTCDate()}T#{dt.getUTCHours()}:#{dt.getUTCMinutes()}:#{dt.getUTCSeconds()}"
# retrieve user app.user
try
	app.user = JSON.parse (sessionStorage.user or localStorage.user)
	if app.user?.uid > 0 and app.user?.sid?.length is 32
		location.hash = '#home'
		svc 'user',
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

# add back and home button to every page except home
$('[data-role="page"] [data-role="header"]:not(.ui-non-nav)').append $('[data-btn-role="back"],[data-btn-role="home"]')
$('#search [data-btn-role="home"]').hide()
# adjust ref height
b = document.body
map_spacers = $ document.querySelectorAll '[data-role="map"]'
$(window).resize ->
	console.log 'resize', b.clientWidth, b.clientHeight
	app.horizontal = b.clientWidth > b.clientHeight
	$(b)[if app.horizontal then 'addClass' else 'removeClass'] 'horizontal'
	#map_spacers.add('#map').height Math.round (document.body.clientHeight - 93) * if app.horizontal then 1 else 0.45
$(document.body).resize()
$('#home').one pageshow: -> map.el.offset $('#home_map').offset()
# build shared map
map = app.map = new google.maps.Map $('#map')[0],
	zoom: 15
	mapTypeId: google.maps.MapTypeId.ROADMAP
	navigationControl: true
	navigationControlOptions: 
		style: google.maps.NavigationControlStyle.SMALL
plcsvc = new google.maps.places.PlacesService map
geocoder = new google.maps.Geocoder()
dirSvc = new google.maps.DirectionsService()
dirRenderer = new google.maps.DirectionsRenderer()
svbounds = new google.maps.LatLngBounds new google.maps.LatLng(38.052417,-122.728271), new google.maps.LatLng(37.247821,-121.552734)
# ext map
(-> # @ is map
	@el = $ '#map'
	# add traffic
	trafficLayer = new google.maps.TrafficLayer()
	trafficLayer.setMap @
	$.extend @,
		setMarkers: (markers_cfg) =>
			console.log 'markers', markers_cfg
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
			navigator.geolocation.getCurrentPosition ((pos) =>
				# get geo location
				curlatlng = new google.maps.LatLng pos.coords.latitude, pos.coords.longitude
				console.log 'curlatlng', curlatlng
				if not curlatlng.equals @getCenter()
					curlatlng.changed = true
				if auto and curlatlng.changed
					# clear markders
					@setMarkers null
					# set center
					@setCenter curlatlng
					map_spacers.each (i, m) => $(m).css 'background-image', "url('https://maps.googleapis.com/maps/api/staticmap?center=#{curlatlng.lat()},#{curlatlng.lng()}&zoom=#{$(m).attr('data-map-zoom') or 15}&size=#{$(window).width()}x#{@el.height()}&maptype=roadmap&format=png8&sensor=true&language=en')"
					# get addr
					geocoder.geocode latLng: curlatlng, (results, status) =>
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
# map share
$('[data-role="page"]').bind
	pagebeforeshow: ->
		map.el.css('opacity': 0, 'z-index': 0)
	pageshow: ->
		$.mobile.fixedToolbars.show()
		@hh = $('[data-role="header"]', @)?.outerHeight() or 0
		@fh = $('[data-role="footer"]', @)?.outerHeight() or 0
		@bh = document.body.clientHeight - @hh - @fh
		$('.map', @).add(map.el).height @bh * if app.horizontal then 1 else 0.45
		map.el.css('opacity': 1, 'z-index': 10000) if $(@).hasClass('has-map')
		#map.el[if $(@).hasClass('has-map') then 'show' else 'hide']().css('opacity', 1)
console.log 'user', app.user

# weather api
$.ajax
	url:'gapi?&hl=en-us&weather=san+jose,ca'
	dataType: 'xml'
	success: (xml, xhr) ->
		j = xml2json(xml)
		return if not j.weather?.current_conditions?
		cur = j.weather.current_conditions
		console.log 'w:', j
		getIcon = (d) -> "https://www.google.com" + d.icon.data
		el = $('#weather').html "<div id=\"weather_now\" class=\"weather\">
<img src=\"#{getIcon cur}\"/>#{cur.condition.data}<br/>#{cur.temp_f.data}\u00b0F</div>" # \u00b0=°
		el.append (j.weather.forecast_conditions.map (c) ->
			"<div class=\"weather\"><img src=\"#{getIcon c}\"/>#{c.day_of_week.data} #{c.high.data}/#{c.low.data}\u00b0F</div>"
		).join ''
		@ # end
	error: (xhr) -> console.log 'get weather failed', xhr

# util js
`function xml2json(b,g,h){function j(b,g){if(!b)return null;var c="",a=null;if(b.childNodes&&0<b.childNodes.length)for(var i=0;i<b.childNodes.length;i++){var d=b.childNodes[i],f=d.nodeType,e=d.localName||d.nodeName||"",h=d.text||d.nodeValue||"";if(8!=f)if(3==f||4==f||!e)c+=h.replace(/^\s+|\s+$/g,"");else if(a=a||{},a[e]){if(!(a[e]instanceof Array)||!a[e].length)a[e]=[a[e]];a[e].push(j(d,!0))}else a[e]=j(d,!1)}if(b.attributes&&!k&&0<b.attributes.length){a=a||{};for(d=0;d<b.attributes.length;d++)e=b.attributes[d],f=e.name||"",e=e.value,a[f]?(!(a[f]instanceof Array)&&a[f].length&&(a[f]=[a[f]]),a[f].push(e)):a[f]=e}if(a){if(""!=c){d=new String(c);for(i in a)d[i]=a[i];a=d}if(c=a.text?("object"==typeof a.text?a.text:[a.text||""]).concat([c]):c)a.text=c;c=""}a=a||c;if(l){c&&(a={});if(c=a.text||c||"")a.text=c;!g&&!(a instanceof Array)&&(a=[a])}return a}var l=g,k=h;if(!b)return{};"string"==typeof b&&(b=q(b));if(b.nodeType){if(3==b.nodeType||4==b.nodeType)return b.nodeValue;b=9==b.nodeType?b.documentElement:b;g=j(b,!0);b=b=null;return g}}function q(b){var g;try{var h=new DOMParser;h.async=!1;g=h.parseFromString(b,"text/xml")}catch(j){throw Error("Error parsing XML string");}return g}`
`function sha1(a){for(var d=[],b=0;b<8*a.length;b+=8)d[b>>5]|=(a.charCodeAt(b/8)&255)<<24-b%32;a=8*a.length;d[a>>5]|=128<<24-a%32;d[(a+64>>9<<4)+15]=a;for(var a=Array(80),b=1732584193,e=-271733879,f=-1732584194,g=271733878,i=-1009589776,j=0;j<d.length;j+=16){for(var k=b,l=e,m=f,n=g,o=i,c=0;80>c;c++){a[c]=16>c?d[j+c]:(a[c-3]^a[c-8]^a[c-14]^a[c-16])<<1|(a[c-3]^a[c-8]^a[c-14]^a[c-16])>>>31;var p=h(h(b<<5|b>>>27,20>c?e&f|~e&g:40>c?e^f^g:60>c?e&f|e&g|f&g:e^f^g),h(h(i,a[c]),20>c?1518500249:40>c?1859775393:60>c?-1894007588:-899497514)),i=g,g=f,f=e<<30|e>>>2,e=b,b=p}b=h(b,k);e=h(e,l);f=h(f,m);g=h(g,n);i=h(i,o)}d=[b,e,f,g,i];a="";for(b=0;b<4*d.length;b++)a+="0123456789abcdef".charAt(d[b>>2]>>8*(3-b%4)+4&15)+"0123456789abcdef".charAt(d[b>>2]>>8*(3-b%4)&15);return a};function h(a,d){var b=(a&65535)+(d&65535);return(a>>16)+(d>>16)+(b>>16)<<16|b&65535};`
hash = (str1, str2) ->
	h = 'KnightRider\x58\xb5\x04\x05\xf1\x50\x47\x6f\xf0\x40\xd8\xf4\xed\x9d\xd2\x79\xc0\x6e\xa6\xd9\xffKnightRider'
	sha1(h + str1 + sha1(h + str1 + '\xff' + str2 + h) + str2 + h)

# init web sql db
if window.openDatabase?
	app.db = openDatabase("KnightRider", "1.0", "Data cache for Knight Rider", 200000);
	if app.db?
		app.db._onerr = (e) -> console.error 'local db error', e
		app.db.sync = (svc_name, callback) ->
			svc svc_name,
				method: 'sync'
				type: 'get'
				data:
					last: date_svc.dateToStr new Date app.user.last_sync_alert or 0
				callback: (data) ->
					console.log 'sync', svc_name, data
					app.user.last_sync_alert = new Date().getTime() - 10000 # -10s
					callback? data
			@ # end of sync
		app.db.alerts_sync = ->
			app.db.sync 'alerts', (data) ->
				return if not data.length
				app.db.transaction (tx) ->
					ids = data.map (a) -> a.id
					sql = "DELETE FROM [Alerts] WHERE id IN (#{ids.join(',')})" # delete old
					tx.executeSql sql, [], ((tx) ->
						data.forEach (a) ->
							a.datetime = date_svc.dateFromWcf(a.datetime)
							a.expired  = date_svc.dateFromWcf(a.expired)
							a.created  = date_svc.dateFromWcf(a.created)
							a.modified = date_svc.dateFromWcf(a.modified)
							sql = "INSERT INTO [Alerts](id,summary,message,importance,type,status,datetime,expired,created,modified) VALUES (#{a.id},'#{a.summary}','#{a.message}',#{a.importance},#{a.type},#{a.status},'#{a.datetime}','#{a.expired}','#{a.created}','#{a.modified}')" # insert new
							console.log 'insert', sql
							tx.executeSql sql, [], ((tx, ret) -> 
								# console.log ret
							), app.db._onerr
					), app.db._onerr
		app.db.alerts_refresh = (callback) ->
			app.db.transaction (tx) ->
				tx.executeSql "SELECT * FROM [Alerts]", [], ((tx, ret) ->
					console.log 'alerts from db', ret
					rows = []
					i = ret.rows.length
					while i
						rows.push ret.rows.item --i
					callback? rows
				), app.db._onerr
		# create table
		app.db.transaction (tx) ->
			tx.executeSql "CREATE TABLE IF NOT EXISTS [Alerts] (
				id INT UNIQUE, 
				summary NVARCHAR(100), 
				message TEXT, 
				datetime DATETIME, 
				expired DATETIME, 
				importance TINYINT, 
				type TINYINT, 
				status TINYINT,
				created DATETIME, 
				modified DATETIME
			)", [], app.db.alerts_sync, app.db._onerr
	else alert 'open db err'

# home page
$('#home').bind
	pagecreate: -> @created = true
	pagebeforeshow: ->
		return if $('#map', @).length
		console.log 'home pageshow'
		created = @created
		# init nav api and home page
		map.getCurPos (curlatlng, addr) ->
			$('#home_addr').text addr if addr? # set addr info
			@setZoom 15
			@setMarkers position: curlatlng # set cur marker
		app.db.alerts_refresh (alerts) ->
			alert_el = $('#alerts').empty()
			html = '<li data-role="list-divider" class="ui-body-c list-none">No Alerts</li>'
			html = "<li data-role=\"list-divider\" class=\"ui-body-c list-none\">#{alerts.length} Alerts</li>" + alerts.map((a) ->
				"<li><a href=\"javascript:alert('#{a.message}')\">#{a.summary}</a></li>"
			).join '' if alerts.length > 0
			$('#alerts').html(html).listview().listview 'refresh'
			#@move 'home'
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
			inputs = $('input', @).textinput 'disable'
			slider = $('select', @).slider 'disable'
			btns = $('button', @).button 'disable'
			$('#btn_reg').addClass 'ui-disabled'
			email = $('#email').val().trim()
			password = $('#password').val()
			return false if not email or not password
			pk = hash email.toLowerCase(), password
			app.autologin = $('#autologin').val() is 'on'
			svc
				svc: 'user'
				method: 'login'
				data:
					email: email
					password: pk
				callback: (data) ->
					console.log data
					if data.uid and data.sid?.length is 32
						app.user = uid: data.uid, email: email, sid: data.sid
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
		console.log 'logout', app.user
		return if not app.user?
		svc 'user',
			method: 'logout'
			nowait: true
			data:
				uid: app.user.uid
				sid: app.user.sid
		app.user = null
		app.save_profile()
		@ # end of show

# reg dlg
$('#reg_form').submit (e) ->
	e.preventDefault()
	e.stopPropagation()
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
	$('#datetime').val Date(new Date().getTime() + 60 * 60 * 1000).toLocaleString()
	$.mobile.changePage '#login', (transition: 'flip', reverse: true) if not (app.user?.sid?.length is 32)
	false
$('#appt_form').submit (e) ->
	return false if not (app.user?.sid?.length is 32) or (app.user?.uid is 0)
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
# $('#search').bind pageshow: -> @map.keyword = null if @map? # clear app.search_keyword
# bind buttons and menus
$('[data-btn-role="search"]').live vclick: (e) ->
	app.search_keyword = $(@).text()
	console.log 'vclick', app.search_keyword
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
		"<li><a href=\"#detail\" data-btn-role=\"result\" data-index=\"#{i}\"><img src=\"#{r.icon}\" class=\"ui-li-icon\">
<h3 class=\"ui-li-heading\">#{r.name}</h3><p class=\"ui-li-desc\">#{r.vicinity}</p></li>"
	).join '' if app.user.place_search_history?.length
	$('#search_history_list_header').after l

# custom search page
$('#custom_search').bind pagecreate: ->
	@created = true
	app.custom_search_history_refresh() # for the 1st show
	new google.maps.places.Autocomplete $('#input_search')[0],
		bounds: svbounds
		types: ['establishment']
$('#custom_search').bind 'pageshow pagebeforeshow', -> $('#custom_history_list').listview 'refresh' if @created
$('#custom_search_form').submit ->
	input = $('#input_search')
	keyword = $.trim input.val()
	if keyword
		app.search_keyword = new String(keyword)
		app.search_keyword.custom = true
		$.mobile.changePage '#result'
		console.log 'vclick', app.search_keyword
	else input.focus().val ''
	false # end of submit

# search history page
$('#search_history').bind pagecreate: ->
	@created = true
	app.place_search_history_refresh()
	$('#search_history li a').live vclick: ->
		app.selected_place = app.user.place_search_history[Number $(@).attr 'data-index']
$('#search_history').bind 'pageshow pagebeforeshow', -> $('#search_history_list').listview 'refresh' if @created

# result page
$('#result').bind
	pagebeforeshow: ->
		console.log 'search for', app.search_keyword
		if not app.search_keyword
			app.back(); return
		$.mobile.showPageLoadingMsg()
		#@map.keyword = null # init app.result.keyword
		#app.result.keyword = app.search_keyword
		# clear old results
		result_list = $('#result_list').empty()
		# create new results
		map.getCurPos (curlatlng, addr) ->
			@setZoom 12
			#@move 'result'
			# search result
			plcsvc.search
				#bounds: svbounds
				location: curlatlng
				radius: 5000
				keyword: app.search_keyword
				#types: ['store']
				(results, status) -> # search callback
					if status is google.maps.places.PlacesServiceStatus.ZERO_RESULTS
						alert 'Zero Result'
						app.back()
					else if status is google.maps.places.PlacesServiceStatus.OK
						$('#result_addr').text "#{app.search_keyword} (#{results.length})"
						result_list.height document.body.clientHeight - result_list.offset().top
						console.log 'search result', results
						# sort results
						app.result_map = {}
						results.forEach (r) ->
							app.result_map[r.id] = r
							r = r.geometry
							dlng = r.location.lng() - curlatlng.lng()
							dlat = r.location.lat() - curlatlng.lat()
							r.dist = Math.pow(dlng, 2) + Math.pow(dlat, 2)
						results.sort (a, b) -> a.geometry.dist - b.geometry.dist
						results = results.slice 0, 25 # only A-Z
						# add to list in order
						result_list.append results.map((r, i) ->
							r.seq = String.fromCharCode 65 + i # from A
							"<li><a href=\"#detail\" data-btn-role=\"result\" id=\"#{r.id}\">
<div style=\"float:left\">#{r.seq}</div><img src=\"#{r.icon?.replace /^http:/, 'https:'}\" class=\"ui-li-icon\">
<h3 class=\"ui-li-heading\">#{r.name}</h3><p class=\"ui-li-desc\">#{r.vicinity}</p></li>"
						).join ''
						# show marking in rev order
						markers = results.reverse().map (result) ->
							position: result.geometry.location
							icon: "https://www.google.com/mapfiles/marker#{result.seq}.png"
							title: result.name
						result_list.listview 'refresh'
						# add marker
						markers.push
							position: curlatlng
							icon: 'https://www.google.com/mapfiles/arrow.png'
							title: 'You are here'
						# set markers to map
						map.setMarkers markers
						# save custom search history
						if app.search_keyword.custom
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
	console.log @id
	app.selected_place = app.result_map[@id]
$('#detail').bind
	pagecreate: ->
		$('#apt_cancel').bind vclick: (e) ->
			e.preventDefault()
			e.stopPropagation()
			$('#appointment').dialog('close')
			false # end fo create
	pageshow: ->
		detial_info = $('#detial_info')
		detial_info.height document.body.clientHeight - detial_info.offset().top - @fh
		console.log 'detailof', app.selected_place
		window.scrollTop = 0
		if not app.selected_place
			app.back()
			return
		show_detail = (place) ->
			map.setCenter place.geometry.location
			map.setMarkers position: place.geometry.location
			map.setZoom 15
			$('#detail_place').text place.name
			detial_info.html "<ul>
<li>#{place.formatted_address}</li><li>#{place.formatted_phone_number}</li>
<li>#{place.types.join(', ').replace(/_/g, ' ').toUpperCase()}</li>
<li>#{if place.rating? then proc_rating(place.rating) else '(No Rating Data)' }</li>
<li><a href=\"#{place.website or place.url}\" target=\"_blank\">
#{if place.website? then 'Visit its Website' else 'View on Google Place'}</a></li></ul>"
			# save history
			psh = app.user.place_search_history ?= []
			if psh.length is 0 or psh[0].id isnt app.selected_place.id
				psh.some (h, i) ->
					if h.id is app.selected_place.id
						psh.splice i, 1 # del
						return true
					false
				psh.unshift
					id: place.id
					reference: app.selected_place.reference
					name: place.name
					vicinity: place.vicinity
					icon: place.icon?.replace /^http:/, 'https:'
				app.place_search_history_refresh()
			console.log place
			@ # end of show detail
		if app.selected_place.__detail
			show_detail app.selected_place.__detail
		else plcsvc.getDetails (reference: app.selected_place.reference), (place, status) ->
			if status is google.maps.places.PlacesServiceStatus.OK
				app.selected_place.__detail = place
				show_detail place
		@ # end of show

# direction page
$('#direction').bind
	pagebeforeshow: ->
		direction_panel = $('#direction_panel')
		direction_panel.height document.body.clientHeight - direction_panel.offset().top
		#curloc = -> map.getCurPos (curlatlng, addr) -> @setMarkers position: curlatlng if addr? # set cur marker
		#@auto = setInterval curloc, 10000 # every 10s
		map.getCurPos (curlatlng, addr) ->
			dirSvc.route (
				origin: addr
				destination: app.selected_place.vicinity # formatted_address
				travelMode: google.maps.DirectionsTravelMode.DRIVING # or BICYCLING WALKING
				unitSystem: google.maps.DirectionsUnitSystem.IMPERIAL # or METRIC
				provideRouteAlternatives: true
			), (dirResult, dirStatus) ->
				if dirStatus is google.maps.DirectionsStatus.OK
					# Show directions
					dirRenderer.setMap map
					dirRenderer.setPanel direction_panel[0]
					dirRenderer.setDirections(dirResult)
					# show self
					#curloc()
				else alert('Directions failed: ' + dirStatus)
	pagehide: ->
		#@auto = clearInterval @auto
		dirRenderer.setMap null
console.log 2 # jsmin app.js && rm app.js && mv app.min.js app.js
