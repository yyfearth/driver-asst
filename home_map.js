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
      var curlatlng, geocoder, map, marker;
      curlatlng = new google.maps.LatLng(position.coords.latitude, position.coords.longitude);
      map = new google.maps.Map($get('map'), {
        zoom: 15,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        center: curlatlng
      });
      marker = new google.maps.Marker({
        position: map.getCenter(),
        map: map
      });
      geocoder = new google.maps.Geocoder();
      geocoder.geocode({
        latLng: curlatlng
      }, function(results, status) {
        var infowindow;
        if (status === google.maps.GeocoderStatus.OK) {
          console.log(results);
          if (results[0] != null) {
            infowindow = new google.maps.InfoWindow({
              content: "<div class=\"info-window-content\"><h1>Current Address</h1>" + results[0].formatted_address + "</div>"
            });
            return infowindow.open(map, marker);
          }
        } else {
          return alert("Geocoder failed due to: " + status);
        }
      });
      return this;
    }), (function() {
      return alert('no geo location!');
    }));
  }
  console.log(1);
}).call(this);
