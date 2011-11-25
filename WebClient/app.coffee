## Knight Rider
## Wilson @ yyfearth.com
# app init
window.app = # ns
	back: -> history.go -1
# init screen
location.hash = '#home'
# add back and home button to every page except home
$('[data-role="page"] [data-role="header"]:not(.ui-non-nav)').append $('[data-btn-role="back"],[data-btn-role="home"]')
$('#search [data-btn-role="home"]').hide()
# adjust ref height
map_spacers = $ document.querySelectorAll '[data-role="map"]'
map_spacers.add('#map').height Math.round document.body.clientHeight * 0.35
$('#home').one pageshow: -> map.el.offset $('#home_map').offset()
# build shared map
map = app.map = new google.maps.Map $('#map')[0],
	zoom: 15
	mapTypeId: google.maps.MapTypeId.ROADMAP
	navigationControl: true
	navigationControlOptions: 
		style: google.maps.NavigationControlStyle.SMALL
svc = new google.maps.places.PlacesService map
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
		move: (id) =>
			#@el.detach()
			#$("##{id} .map").append @el
			@ # end of move
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
				if auto #and curlatlng.changed
					# clear markders
					@setMarkers null
					# set center
					@setCenter curlatlng
					map_spacers.each (i, m) => $(m).css 'background-image', "url('https://maps.googleapis.com/maps/api/staticmap?center=#{curlatlng.lat()},#{curlatlng.lng()}&zoom=#{$(m).attr('data-map-zoom') or 15}&size=#{$(window).width()}x#{@el.height()}&maptype=roadmap&format=png8&sensor=true')"
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
$('[data-role="page"]').bind
	pagebeforeshow: ->
		map.el.css('opacity', 0).show()
	pageshow: ->
		map.el[if $(@).hasClass('has-map') then 'show' else 'hide']().css('opacity', 1)


# home page
$('#home').bind
	pageshow: ->
		#map.el.show()
	pagebeforeshow: ->
		return if $('#map', @).length
		console.log 'home pageshow'
		# init nav api and home page
		map.getCurPos (curlatlng, addr) ->
			$('#home_addr').text addr # set addr info
			@setZoom 15
			@setMarkers position: curlatlng # set cur marker
			@move 'home'
		#maps.getCurPos ((curlatlng) -> @map.mark curlatlng) if @map? and not @map.getCenter()?.equals curlatlng
		@ # end of home page show
	pagehide: ->
		#map.el.hide()


# util js
`function xml2json(b,g,h){function j(b,g){if(!b)return null;var c="",a=null;if(b.childNodes&&0<b.childNodes.length)for(var i=0;i<b.childNodes.length;i++){var d=b.childNodes[i],f=d.nodeType,e=d.localName||d.nodeName||"",h=d.text||d.nodeValue||"";if(8!=f)if(3==f||4==f||!e)c+=h.replace(/^\s+|\s+$/g,"");else if(a=a||{},a[e]){if(!(a[e]instanceof Array)||!a[e].length)a[e]=[a[e]];a[e].push(j(d,!0))}else a[e]=j(d,!1)}if(b.attributes&&!k&&0<b.attributes.length){a=a||{};for(d=0;d<b.attributes.length;d++)e=b.attributes[d],f=e.name||"",e=e.value,a[f]?(!(a[f]instanceof Array)&&a[f].length&&(a[f]=[a[f]]),a[f].push(e)):a[f]=e}if(a){if(""!=c){d=new String(c);for(i in a)d[i]=a[i];a=d}if(c=a.text?("object"==typeof a.text?a.text:[a.text||""]).concat([c]):c)a.text=c;c=""}a=a||c;if(l){c&&(a={});if(c=a.text||c||"")a.text=c;!g&&!(a instanceof Array)&&(a=[a])}return a}var l=g,k=h;if(!b)return{};"string"==typeof b&&(b=q(b));if(b.nodeType){if(3==b.nodeType||4==b.nodeType)return b.nodeValue;b=9==b.nodeType?b.documentElement:b;g=j(b,!0);b=b=null;return g}}function q(b){var g;try{var h=new DOMParser;h.async=!1;g=h.parseFromString(b,"text/xml")}catch(j){throw Error("Error parsing XML string");}return g}`
# weather api
$.ajax
	url:'/gapi?weather=san+jose,ca'
	dataType: 'xml'
	success: (xml, xhr) ->
		j = xml2json(xml)
		cur = j.weather.current_conditions
		console.log 'w:', j
		getIcon = (d) -> "https://www.google.com" + d.icon.data
		el = $('#weather').html "<img src=\"#{getIcon cur}\"/>#{cur.temp_f.data}\u00b0F #{cur.condition.data} " # \u00b0=°
		el.append (j.weather.forecast_conditions.map (c) ->
			"<img src=\"#{getIcon c}\"/>#{c.day_of_week.data} #{c.high.data}/#{c.low.data}\u00b0F "
		).join ''
		@ # end
	error: (xhr) -> console.log 'get weather failed', xhr

# init history
try
	console.log localStorage.custom_search_history
	app.history = JSON.parse localStorage.custom_search_history if localStorage.custom_search_history?
	app.history = [] if not $.isArray app.history
catch err
	console.log err
	app.history = []
finally
	app.history.refresh = =>
		$('#history_list li:gt(0)').remove() # remove all except history_list_header
		if app.history.length
			$('#history_list_header').after app.history.map((item) ->"<li><a href=\"#result\" data-btn-role=\"search\">#{item}</a></li>").join ''
		else
			$('#history_list_header').after '<li data-role="list-divider" class="ui-body-c list-none">(None)</li>'

# search menu page
# $('#search').bind pageshow: -> @map.keyword = null if @map? # clear app.search_keyword
# bind buttons and menus
$('[data-btn-role="search"]').live vclick: ->
	app.search_keyword = $(@).text()
	console.log 'vclick', app.search_keyword
	@ # end of vclick
# custom search
$('#search_history').bind
	pagecreate: ->
		@created = true
		app.history.refresh() # for the 1st show
		new google.maps.places.Autocomplete $('#input_search')[0],
			bounds: svbounds
			types: ['establishment']
$('#search_history').bind 'pageshow pagebeforeshow', -> $('#history_list').listview 'refresh' if @created
$('#custom_search_form').submit ->
	input = $('#input_search')
	keyword = $.trim input.val()
	if keyword
		app.search_keyword = keyword
		$.mobile.changePage '#result'
		console.log 'vclick', app.history.search_keyword
	else input.focus().val ''
	false # end of submit
# save history
window.onbeforeunload = ->
	localStorage.custom_search_history = JSON.stringify app.history
	return #"Sure to leave Knight Rider?"

# result page
$('#result').bind
	pageshow: ->
		console.log 'search for', app.search_keyword
		if not app.search_keyword
			app.back(); return
		#@map.keyword = null # init app.result.keyword
		#app.result.keyword = app.search_keyword
		# clear old results
		result_list = $('#result_list').empty()
		# create new results
		map.getCurPos (curlatlng, addr) ->
			@setZoom 12
			@move 'result'
			# search result
			svc.search
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
<div style=\"float:left\">#{r.seq}</div><img src=\"#{r.icon}\" class=\"ui-li-icon\">
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
						# save history
						if app.history[0] isnt app.search_keyword
							app.history.unshift app.search_keyword
							app.history.refresh() # refresh list
					else alert 'Search Error'
					@ # end of search callback
		@ # end of result page show
	#pageshow: ->
		#result_list.listview 'refresh' # end of if OK
		#$.mobile.changePage '#search' if not app.search_keyword
		#app.getCurPos ((curlatlng) -> app.result.search curlatlng) if @map? and ((not @map.getCenter()?.equals app.curlatlng) or (maps.result.keyword isnt app.search_keyword))
		#@ # end of pageshow
$('#result_list a').live vclick: ->
	console.log @id
	app.selected_place = app.result_map[@id]

$('#detail').bind
	pageshow: ->
		console.log 'detailof', app.selected_place
		if not app.selected_place
			app.back()
			return
		$('#apt_cancel').bind vclick: -> $('#appointment').dialog('close')
		svc.getDetails (reference: app.selected_place.reference), (place, status) ->
			if status is google.maps.places.PlacesServiceStatus.OK
				map.setCenter place.geometry.location
				map.setMarkers position: place.geometry.location
				map.setZoom 15
				$('#detail_place').text place.name
				$('#detial_info').text JSON.stringify place, null, '  '
				console.log place

$('#direction').bind
	pageshow: ->
		map.getCurPos (curlatlng, addr) ->
			@setZoom 14
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
					dirRenderer.setPanel $('#direction_panel')[0]
					dirRenderer.setDirections(dirResult)
				else  alert('Directions failed: ' + dirStatus)
	pagehide: ->
		dirRenderer.setMap null
console.log 1
