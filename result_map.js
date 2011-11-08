(function() {
  var $find, $findAll, $get;
  $get = function(id) {
    return document.getElementById(id);
  };
  $find = function(path) {
    return document.querySelector(path);
  };
  $findAll = function(path) {
    return document.querySelectorAll(path);
  };
  if (navigator.geolocation != null) {
    navigator.geolocation.getCurrentPosition((function(position) {
      var curlatlng, map, service;
      curlatlng = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
      map = new google.maps.Map($get('map'), {
        zoom: 15,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        center: curlatlng
      });
      /*marker = new google.maps.Marker
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
      	*/
      service = new google.maps.places.PlacesService(map);
      service.search({
        location: map.getCenter(),
        radius: 5000,
        keyword: 'gas station'
      }, function(results, status) {
        if (status === google.maps.places.PlacesServiceStatus.OK) {
          return results.forEach(function(result) {
            return new google.maps.Marker({
              map: map,
              position: result.geometry.location
            });
          });
        }
      });
      return this;
    }), (function() {
      return alert('no geo location!');
    }));
  }
  console.log(2);
}).call(this);
