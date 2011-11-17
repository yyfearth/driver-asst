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
svbounds = new google.maps.LatLngBounds new google.maps.LatLng(38.052417,-122.728271), new google.maps.LatLng(37.247821,-121.552734)
# ext map
(-> # @ is map
	@el = $ '#map';
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
		map.el.show()
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
		map.el.hide()

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
					if status is google.maps.places.PlacesServiceStatus.OK
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
		console.log 'detail', app.selected_place
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

				console.log place
			
console.log 1
