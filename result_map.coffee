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
	###marker = new google.maps.Marker
		position: map.getCenter()
		map: map
	# find
	target = 'service station'
	geocoder = new google.maps.Geocoder()
	geocoder.geocode
		address: target
		latLng: map.getCenter()
		(results, status) ->
			if status is google.maps.GeocoderStatus.OK
				console.log results
				results.forEach (result) ->
					result_marker = new google.maps.Marker
						map: map
						position: result.geometry.location
			else
				console.log status
				alert "Geocode was not successful for the following reason: #{status}"
	###
	service = new google.maps.places.PlacesService map;
	service.search
		location: map.getCenter()
		radius: 5000
		keyword: 'gas station'
		#types: ['store']
		(results, status) ->
			if status is google.maps.places.PlacesServiceStatus.OK
				results.forEach (result) ->
					#createMarker(result);
					new google.maps.Marker
						map: map
						position: result.geometry.location
	@ # end of func
), (-> alert 'no geo location!') if navigator.geolocation?

console.log 2