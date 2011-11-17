window.$get = (id) -> document.getElementById id
#$find = (path) -> document.querySelector path
#$findAll = (path) -> document.querySelectorAll path
window.maps =
	getCurPos: (callback) ->
		navigator.geolocation.getCurrentPosition ((pos) ->
			# get geo location
			curlatlng = new google.maps.LatLng pos.coords.latitude, pos.coords.longitude
			console.log 'curlatlng', curlatlng
			maps.curlatlng = curlatlng
			callback curlatlng
		), (-> alert 'no geo location!') if navigator.geolocation?
	home: null

# ui helper
# add back and home button to every page except home
$('[data-role="page"] [data-role="header"]:not(.ui-non-nav)').append $('[data-btn-role="back"],[data-btn-role="home"]')
$('#search [data-btn-role="home"]').hide()
# adjust ref height
h = $(document.body).height()
$('.map').height h * 0.35
# end of ui helper

# home page
$('#home').bind
	pagecreate: () ->
		console.log 'home pagecreate'
		# init nav api and home page
		maps.getCurPos (curlatlng) ->
			# init map with location in center
			@map = maps.home = new google.maps.Map $get('home_map'),
				zoom: 15
				mapTypeId: google.maps.MapTypeId.ROADMAP
				navigationControl: true
				navigationControlOptions: 
					style: google.maps.NavigationControlStyle.SMALL
			# add traffic
			trafficLayer = new google.maps.TrafficLayer()
			trafficLayer.setMap maps.home
			@map.mark = (curlatlng) ->
				maps.home.setCenter curlatlng
				# add marker
				marker = new google.maps.Marker
					position: curlatlng,
					map: maps.home
				# get addr and show info window
				geocoder = new google.maps.Geocoder()
				geocoder.geocode latLng: curlatlng, (results, status) ->
					if status is google.maps.GeocoderStatus.OK
						# console.log 'geocode', results
						$('#home_addr').text results[0].formatted_address if results[0]?
					else
						alert "Geocoder failed due to: #{status}"
				@ # end of mark
			@map.mark curlatlng #  maps.home maybe null when pageshow
			@ # end of getCurPos
		@ # end of pagecreate
	pageshow: () ->
		console.log 'home pageshow'
		maps.getCurPos ((curlatlng) -> @map.mark curlatlng) if @map? and not @map.getCenter()?.equals curlatlng

# init history
try
	console.log localStorage.custom_search_history
	maps.history = JSON.parse localStorage.custom_search_history if localStorage.custom_search_history?
	maps.history = [] if not $.isArray maps.history
catch err
	console.log err
	maps.history = []
finally
	maps.history.refresh = () =>
		$('#history_list li:gt(0)').remove() # remove all except history_list_header
		if maps.history.length
			$('#history_list_header').after maps.history.map((item) ->"<li><a href=\"#result\" data-btn-role=\"search\">#{item}</a></li>").join ''
		else
			$('#history_list_header').after '<li data-role="list-divider" class="ui-body-c list-none">(None)</li>'

# search menu page
# $('#search').bind pageshow: () -> @map.keyword = null if @map? # clear maps.search_keyword
# bind buttons and menus
$('[data-btn-role="search"]').live vclick: () ->
	maps.search_keyword = $(@).text()
	console.log 'vclick', maps.search_keyword
	@ # end of vclick
# custom search
$('#search_history').bind
	pagecreate: () ->
		@created = true
		maps.history.refresh() # for the 1st show
$('#search_history').bind 'pageshow pagebeforeshow', () -> $('#history_list').listview 'refresh' if @created
$('#custom_search_form').submit () ->
	input = $('#input_search')
	keyword = $.trim input.val()
	if keyword
		maps.search_keyword = keyword
		$.mobile.changePage '#result'
		console.log 'vclick', maps.history.search_keyword
	else input.focus().val ''
	false # end of submit
# save history
window.onbeforeunload = () ->
	localStorage.custom_search_history = JSON.stringify maps.history
	return #"Sure to leave Knight Rider?"

# result page
$('#result').bind
	pagecreate: () ->
		maps.getCurPos (curlatlng) =>
			@map = maps.result = new google.maps.Map $get('result_map'),
				zoom: 12
				mapTypeId: google.maps.MapTypeId.ROADMAP
				navigationControl: true
				navigationControlOptions: 
					style: google.maps.NavigationControlStyle.SMALL
				center: curlatlng
			@map.keyword = null # init maps.result.keyword
			@map.search = (curlatlng) ->
				console.log 'search for', maps.search_keyword
				return if not maps.search_keyword
				maps.result.keyword = maps.search_keyword
				maps.result.setCenter maps.curlatlng
				# clear old results
				result_list = $('#result_list').empty()
				# clear old markers
				maps.result.markers.forEach ((marker) -> marker.setMap null) if maps.result.markers?
				# search result
				svc = new google.maps.places.PlacesService maps.result
				svc.search
					location: curlatlng
					radius: 5000
					keyword: maps.search_keyword
					#types: ['store']
					(results, status) -> # search callback
						if status is google.maps.places.PlacesServiceStatus.OK
							$('#result_addr').text "#{maps.search_keyword} (#{results.length})"
							result_list.height h - result_list.offset().top
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
							maps.result.markers = results.reverse().map (result) ->
								# console.log result.seq
								new google.maps.Marker
									position: result.geometry.location
									icon: "https://www.google.com/mapfiles/marker#{result.seq}.png"
									map: maps.result
							result_list.listview 'refresh' # end of if OK
							# add marker
							maps.result.markers.push new google.maps.Marker
								position: curlatlng,
								map: maps.result
								icon: 'https://www.google.com/mapfiles/arrow.png'
							# save history
							if maps.history[0] isnt maps.search_keyword
								maps.history.unshift maps.search_keyword
								maps.history.refresh() # refresh list
						@ # end of search callback
				@ # end of search
			@map.search curlatlng
		@ # end of pagecreate
	pagebeforeshow: () ->
		$.mobile.changePage '#search' if not maps.search_keyword
		maps.getCurPos ((curlatlng) -> maps.result.search curlatlng) if @map? and ((not @map.getCenter()?.equals maps.curlatlng) or (maps.result.keyword isnt maps.search_keyword))
		@ # end of pageshow

console.log 1
