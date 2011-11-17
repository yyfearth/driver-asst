window.app = # ns
	back: () -> history.go -1
# init screen
location.hash = '#home'
# add back and home button to every page except home
$('[data-role="page"] [data-role="header"]:not(.ui-non-nav)').append $('[data-btn-role="back"],[data-btn-role="home"]')
$('#search [data-btn-role="home"]').hide()
# adjust ref height
map_el = $ '#map'
map_el.add(document.querySelectorAll '.map').height Math.round document.body.clientHeight * 0.35
# build shared map
map = app.map = new google.maps.Map map_el[0],
	zoom: 15
	mapTypeId: google.maps.MapTypeId.ROADMAP
	navigationControl: true
	navigationControlOptions: 
		style: google.maps.NavigationControlStyle.SMALL
svc = new google.maps.places.PlacesService map
geocoder = new google.maps.Geocoder()
# ext map
(() -> # @ is map
	@el = map_el;
	# add traffic
	trafficLayer = new google.maps.TrafficLayer()
	trafficLayer.setMap @
	$.extend @,
		move: (id) =>
			@el.detach()
			$("##{id} .map").append @el
			@ # end of move
		setMarkers: (markers_cfg) =>
			console.log 'markers', markers_cfg
			if not markers_cfg
				markers_cfg = null
			else if not $.isArray markers_cfg
				markers_cfg = [markers_cfg]
			# clear old markers
			@markers.forEach ((marker) => # whether markers is null
				marker.setMap null
				delete marker
			) if @markers?
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
				app.curlatlng = curlatlng
				if auto
					# clear markders
					@setMarkers null
					# set center
					@setCenter curlatlng
					# get addr
					geocoder.geocode latLng: curlatlng, (results, status) =>
						if status is google.maps.GeocoderStatus.OK
							callback.call @, curlatlng, results[0]?.formatted_address
						else
							alert "Geocoder failed due to: #{status}\n App terminated!"
				else callback.call @ curlatlng
			), (-> alert 'App cannot run without geo location!') if navigator.geolocation?
			@ # end of get cur pos
).call map # end of ext map
# home page
$('#home').bind
	pageshow: () ->
		console.log 'home pageshow'
		# init nav api and home page
		map.getCurPos (curlatlng, addr) ->
			$('#home_addr').text addr # set addr info
			@setZoom 15
			@setMarkers position: curlatlng # set cur marker
			@move 'home'
		#maps.getCurPos ((curlatlng) -> @map.mark curlatlng) if @map? and not @map.getCenter()?.equals curlatlng
		@ # end of home page show

# init history
try
	console.log localStorage.custom_search_history
	app.history = JSON.parse localStorage.custom_search_history if localStorage.custom_search_history?
	app.history = [] if not $.isArray app.history
catch err
	console.log err
	app.history = []
finally
	app.history.refresh = () =>
		$('#history_list li:gt(0)').remove() # remove all except history_list_header
		if app.history.length
			$('#history_list_header').after app.history.map((item) ->"<li><a href=\"#result\" data-btn-role=\"search\">#{item}</a></li>").join ''
		else
			$('#history_list_header').after '<li data-role="list-divider" class="ui-body-c list-none">(None)</li>'

# search menu page
# $('#search').bind pageshow: () -> @map.keyword = null if @map? # clear app.search_keyword
# bind buttons and menus
$('[data-btn-role="search"]').live vclick: () ->
	app.search_keyword = $(@).text()
	console.log 'vclick', app.search_keyword
	@ # end of vclick
# custom search
$('#search_history').bind
	pagecreate: () ->
		@created = true
		app.history.refresh() # for the 1st show
$('#search_history').bind 'pageshow pagebeforeshow', () -> $('#history_list').listview 'refresh' if @created
$('#custom_search_form').submit () ->
	input = $('#input_search')
	keyword = $.trim input.val()
	if keyword
		app.search_keyword = keyword
		$.mobile.changePage '#result'
		console.log 'vclick', app.history.search_keyword
	else input.focus().val ''
	false # end of submit
# save history
window.onbeforeunload = () ->
	localStorage.custom_search_history = JSON.stringify app.history
	return #"Sure to leave Knight Rider?"

# result page
$('#result').bind
	pageshow: () ->
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
				location: curlatlng
				radius: 5000
				keyword: app.search_keyword
				#types: ['store']
				(results, status) -> # search callback
					if status is google.maps.places.PlacesServiceStatus.OK
						$('#result_addr').text "#{app.search_keyword} (#{results.length})"
						result_list.height document.body.clientHeight - result_list.offset().top
						console.log 'search result', results
						# sort results
						results.forEach (r) ->
							r = r.geometry
							dlng = r.location.lng() - curlatlng.lng()
							dlat = r.location.lat() - curlatlng.lat()
							r.dist = Math.pow(dlng, 2) + Math.pow(dlat, 2)
						results.sort (a, b) -> a.geometry.dist - b.geometry.dist
						results = results.slice 0, 25 # only A-Z
						# add to list in order
						result_list.append results.map((result, i) ->
							result.seq = String.fromCharCode 65 + i # from A
							"<li><a href=\"#detail\" data-btn-role=\"result\" id=\"\">
<div style=\"float:left\">#{result.seq}</div><img src=\"#{result.icon}\" class=\"ui-li-icon\">
<h3 class=\"ui-li-heading\">#{result.name}</h3><p class=\"ui-li-desc\">#{result.vicinity}</p></li>"
						).join ''
						# show marking in rev order
						markers = results.reverse().map (result) ->
							position: result.geometry.location
							icon: "https://www.google.com/mapfiles/marker#{result.seq}.png"
						result_list.listview 'refresh' # end of if OK
						# add marker
						markers.push
							position: curlatlng,
							icon: 'https://www.google.com/mapfiles/arrow.png'
						# set markers to map
						map.setMarkers markers
						# save history
						if app.history[0] isnt app.search_keyword
							app.history.unshift app.search_keyword
							app.history.refresh() # refresh list
					@ # end of search callback
		@ # end of result page show
	#pagebeforeshow: () ->
		#$.mobile.changePage '#search' if not app.search_keyword
		#app.getCurPos ((curlatlng) -> app.result.search curlatlng) if @map? and ((not @map.getCenter()?.equals app.curlatlng) or (maps.result.keyword isnt app.search_keyword))
		#@ # end of pageshow

console.log 1
