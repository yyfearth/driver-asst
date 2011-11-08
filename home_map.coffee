$get = (id) -> document.getElementById id
$find = (path) -> document.querySelector path
$findAll = (path) -> document.querySelectorAll path

navigator.geolocation.getCurrentPosition ((position) ->
	# get geo location
	curlatlng = new google.maps.LatLng position.coords.latitude, position.coords.longitude
	# init map with location in center
	map = new google.maps.Map $get('map'),
		zoom: 15
		mapTypeId: google.maps.MapTypeId.ROADMAP
		center: curlatlng
	# add marker
	marker = new google.maps.Marker
		position: map.getCenter(),
		map: map
	# get addr and show info window
	geocoder = new google.maps.Geocoder()
	geocoder.geocode latLng: curlatlng, (results, status) ->
		if status is google.maps.GeocoderStatus.OK
			console.log results
			if results[0]?
				infowindow = new google.maps.InfoWindow
					content: "<div class=\"info-window-content\"><h1>Current Address</h1>#{results[0].formatted_address}</div>"
				infowindow.open map, marker
		else
			alert "Geocoder failed due to: #{status}"
	@ # end of func
), (-> alert 'no geo location!') if navigator.geolocation?

console.log 1