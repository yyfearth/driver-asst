(function() {
  var h;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  window.$get = function(id) {
    return document.getElementById(id);
  };
  window.maps = {
    getCurPos: function(callback) {
      if (navigator.geolocation != null) {
        return navigator.geolocation.getCurrentPosition((function(pos) {
          var curlatlng;
          curlatlng = new google.maps.LatLng(pos.coords.latitude, pos.coords.longitude);
          console.log('curlatlng', curlatlng);
          maps.curlatlng = curlatlng;
          return callback(curlatlng);
        }), (function() {
          return alert('no geo location!');
        }));
      }
    },
    home: null
  };
  $('[data-role="page"] [data-role="header"]:not(.ui-non-nav)').append($('[data-btn-role="back"],[data-btn-role="home"]'));
  $('#search [data-btn-role="home"]').hide();
  h = $(document.body).height();
  $('.map').height(h * 0.35);
  $('#home').bind({
    pagecreate: function() {
      console.log('home pagecreate');
      maps.getCurPos(function(curlatlng) {
        var trafficLayer;
        this.map = maps.home = new google.maps.Map($get('home_map'), {
          zoom: 15,
          mapTypeId: google.maps.MapTypeId.ROADMAP,
          navigationControl: true,
          navigationControlOptions: {
            style: google.maps.NavigationControlStyle.SMALL
          }
        });
        trafficLayer = new google.maps.TrafficLayer();
        trafficLayer.setMap(maps.home);
        this.map.mark = function(curlatlng) {
          var geocoder, marker;
          maps.home.setCenter(curlatlng);
          marker = new google.maps.Marker({
            position: curlatlng,
            map: maps.home
          });
          geocoder = new google.maps.Geocoder();
          geocoder.geocode({
            latLng: curlatlng
          }, function(results, status) {
            if (status === google.maps.GeocoderStatus.OK) {
              if (results[0] != null) {
                return $('#home_addr').text(results[0].formatted_address);
              }
            } else {
              return alert("Geocoder failed due to: " + status);
            }
          });
          return this;
        };
        this.map.mark(curlatlng);
        return this;
      });
      return this;
    },
    pageshow: function() {
      var _ref;
      console.log('home pageshow');
      if ((this.map != null) && !((_ref = this.map.getCenter()) != null ? _ref.equals(curlatlng) : void 0)) {
        return maps.getCurPos((function(curlatlng) {
          return this.map.mark(curlatlng);
        }));
      }
    }
  });
  try {
    console.log(localStorage.custom_search_history);
    if (localStorage.custom_search_history != null) {
      maps.history = JSON.parse(localStorage.custom_search_history);
    }
    if (!$.isArray(maps.history)) {
      maps.history = [];
    }
  } catch (err) {
    console.log(err);
    maps.history = [];
  } finally {
    maps.history.refresh = __bind(function() {
      $('#history_list li:gt(0)').remove();
      if (maps.history.length) {
        return $('#history_list_header').after(maps.history.map(function(item) {
          return "<li><a href=\"#result\" data-btn-role=\"search\">" + item + "</a></li>";
        }).join(''));
      } else {
        return $('#history_list_header').after('<li data-role="list-divider" class="ui-body-c list-none">(None)</li>');
      }
    }, this);
  }
  $('[data-btn-role="search"]').live({
    vclick: function() {
      maps.search_keyword = $(this).text();
      console.log('vclick', maps.search_keyword);
      return this;
    }
  });
  $('#search_history').bind({
    pagecreate: function() {
      this.created = true;
      return maps.history.refresh();
    }
  });
  $('#search_history').bind('pageshow pagebeforeshow', function() {
    if (this.created) {
      return $('#history_list').listview('refresh');
    }
  });
  $('#custom_search_form').submit(function() {
    var input, keyword;
    input = $('#input_search');
    keyword = $.trim(input.val());
    if (keyword) {
      maps.search_keyword = keyword;
      $.mobile.changePage('#result');
      console.log('vclick', maps.history.search_keyword);
    } else {
      input.focus().val('');
    }
    return false;
  });
  window.onbeforeunload = function() {
    localStorage.custom_search_history = JSON.stringify(maps.history);
  };
  $('#result').bind({
    pagecreate: function() {
      maps.getCurPos(__bind(function(curlatlng) {
        this.map = maps.result = new google.maps.Map($get('result_map'), {
          zoom: 12,
          mapTypeId: google.maps.MapTypeId.ROADMAP,
          navigationControl: true,
          navigationControlOptions: {
            style: google.maps.NavigationControlStyle.SMALL
          },
          center: curlatlng
        });
        this.map.keyword = null;
        this.map.search = function(curlatlng) {
          var result_list, svc;
          console.log('search for', maps.search_keyword);
          if (!maps.search_keyword) {
            return;
          }
          maps.result.keyword = maps.search_keyword;
          maps.result.setCenter(maps.curlatlng);
          result_list = $('#result_list').empty();
          if (maps.result.markers != null) {
            maps.result.markers.forEach((function(marker) {
              return marker.setMap(null);
            }));
          }
          svc = new google.maps.places.PlacesService(maps.result);
          svc.search({
            location: curlatlng,
            radius: 5000,
            keyword: maps.search_keyword
          }, function(results, status) {
            if (status === google.maps.places.PlacesServiceStatus.OK) {
              $('#result_addr').text("" + maps.search_keyword + " (" + results.length + ")");
              result_list.height(h - result_list.offset().top);
              console.log('search result', results);
              results.forEach(function(r) {
                var dlat, dlng;
                r = r.geometry;
                dlng = r.location.lng() - curlatlng.lng();
                dlat = r.location.lat() - curlatlng.lat();
                return r.dist = Math.pow(dlng, 2) + Math.pow(dlat, 2);
              });
              results.sort(function(a, b) {
                return a.geometry.dist - b.geometry.dist;
              });
              results = results.slice(0, 25);
              result_list.append(results.map(function(result, i) {
                result.seq = String.fromCharCode(65 + i);
                return "<li><a href=\"#detail\" data-btn-role=\"result\" id=\"\"><div style=\"float:left\">" + result.seq + "</div><img src=\"" + result.icon + "\" class=\"ui-li-icon\"><h3 class=\"ui-li-heading\">" + result.name + "</h3><p class=\"ui-li-desc\">" + result.vicinity + "</p></li>";
              }).join(''));
              maps.result.markers = results.reverse().map(function(result) {
                return new google.maps.Marker({
                  position: result.geometry.location,
                  icon: "https://www.google.com/mapfiles/marker" + result.seq + ".png",
                  map: maps.result
                });
              });
              result_list.listview('refresh');
              maps.result.markers.push(new google.maps.Marker({
                position: curlatlng,
                map: maps.result,
                icon: 'https://www.google.com/mapfiles/arrow.png'
              }));
              if (maps.history[0] !== maps.search_keyword) {
                maps.history.unshift(maps.search_keyword);
                maps.history.refresh();
              }
            }
            return this;
          });
          return this;
        };
        return this.map.search(curlatlng);
      }, this));
      return this;
    },
    pagebeforeshow: function() {
      var _ref;
      if (!maps.search_keyword) {
        $.mobile.changePage('#search');
      }
      if ((this.map != null) && ((!((_ref = this.map.getCenter()) != null ? _ref.equals(maps.curlatlng) : void 0)) || (maps.result.keyword !== maps.search_keyword))) {
        maps.getCurPos((function(curlatlng) {
          return maps.result.search(curlatlng);
        }));
      }
      return this;
    }
  });
  console.log(1);
}).call(this);
