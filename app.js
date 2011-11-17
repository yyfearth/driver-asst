(function() {
  var geocoder, map, map_el, svc;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  window.app = {
    back: function() {
      return history.go(-1);
    }
  };
  location.hash = '#home';
  $('[data-role="page"] [data-role="header"]:not(.ui-non-nav)').append($('[data-btn-role="back"],[data-btn-role="home"]'));
  $('#search [data-btn-role="home"]').hide();
  map_el = $('#map');
  map_el.add(document.querySelectorAll('.map')).height(Math.round(document.body.clientHeight * 0.35));
  map = app.map = new google.maps.Map(map_el[0], {
    zoom: 15,
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    navigationControl: true,
    navigationControlOptions: {
      style: google.maps.NavigationControlStyle.SMALL
    }
  });
  svc = new google.maps.places.PlacesService(map);
  geocoder = new google.maps.Geocoder();
  (function() {
    var trafficLayer;
    this.el = map_el;
    trafficLayer = new google.maps.TrafficLayer();
    trafficLayer.setMap(this);
    return $.extend(this, {
      move: __bind(function(id) {
        this.el.detach();
        $("#" + id + " .map").append(this.el);
        return this;
      }, this),
      setMarkers: __bind(function(markers_cfg) {
        console.log('markers', markers_cfg);
        if (!markers_cfg) {
          markers_cfg = null;
        } else if (!$.isArray(markers_cfg)) {
          markers_cfg = [markers_cfg];
        }
        if (this.markers != null) {
          this.markers.forEach((__bind(function(marker) {
            marker.setMap(null);
            return delete marker;
          }, this)));
        }
        if (markers_cfg != null) {
          this.markers = markers_cfg.map(function(cfg) {
            cfg.map = map;
            return new google.maps.Marker(cfg);
          });
        } else {
          this.markers = null;
        }
        return this;
      }, this),
      getCurPos: __bind(function(auto, callback) {
        if (!(callback != null)) {
          callback = auto;
          auto = true;
        }
        if (navigator.geolocation != null) {
          navigator.geolocation.getCurrentPosition((__bind(function(pos) {
            var curlatlng;
            curlatlng = new google.maps.LatLng(pos.coords.latitude, pos.coords.longitude);
            console.log('curlatlng', curlatlng);
            app.curlatlng = curlatlng;
            if (auto) {
              this.setMarkers(null);
              this.setCenter(curlatlng);
              return geocoder.geocode({
                latLng: curlatlng
              }, __bind(function(results, status) {
                var _ref;
                if (status === google.maps.GeocoderStatus.OK) {
                  return callback.call(this, curlatlng, (_ref = results[0]) != null ? _ref.formatted_address : void 0);
                } else {
                  return alert("Geocoder failed due to: " + status + "\n App terminated!");
                }
              }, this));
            } else {
              return callback.call(this(curlatlng));
            }
          }, this)), (function() {
            return alert('App cannot run without geo location!');
          }));
        }
        return this;
      }, this)
    });
  }).call(map);
  $('#home').bind({
    pageshow: function() {
      console.log('home pageshow');
      map.getCurPos(function(curlatlng, addr) {
        $('#home_addr').text(addr);
        this.setZoom(15);
        this.setMarkers({
          position: curlatlng
        });
        return this.move('home');
      });
      return this;
    }
  });
  try {
    console.log(localStorage.custom_search_history);
    if (localStorage.custom_search_history != null) {
      app.history = JSON.parse(localStorage.custom_search_history);
    }
    if (!$.isArray(app.history)) {
      app.history = [];
    }
  } catch (err) {
    console.log(err);
    app.history = [];
  } finally {
    app.history.refresh = __bind(function() {
      $('#history_list li:gt(0)').remove();
      if (app.history.length) {
        return $('#history_list_header').after(app.history.map(function(item) {
          return "<li><a href=\"#result\" data-btn-role=\"search\">" + item + "</a></li>";
        }).join(''));
      } else {
        return $('#history_list_header').after('<li data-role="list-divider" class="ui-body-c list-none">(None)</li>');
      }
    }, this);
  }
  $('[data-btn-role="search"]').live({
    vclick: function() {
      app.search_keyword = $(this).text();
      console.log('vclick', app.search_keyword);
      return this;
    }
  });
  $('#search_history').bind({
    pagecreate: function() {
      this.created = true;
      return app.history.refresh();
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
      app.search_keyword = keyword;
      $.mobile.changePage('#result');
      console.log('vclick', app.history.search_keyword);
    } else {
      input.focus().val('');
    }
    return false;
  });
  window.onbeforeunload = function() {
    localStorage.custom_search_history = JSON.stringify(app.history);
  };
  $('#result').bind({
    pageshow: function() {
      var result_list;
      console.log('search for', app.search_keyword);
      if (!app.search_keyword) {
        app.back();
        return;
      }
      result_list = $('#result_list').empty();
      map.getCurPos(function(curlatlng, addr) {
        this.setZoom(12);
        this.move('result');
        return svc.search({
          location: curlatlng,
          radius: 5000,
          keyword: app.search_keyword
        }, function(results, status) {
          var markers;
          if (status === google.maps.places.PlacesServiceStatus.OK) {
            $('#result_addr').text("" + app.search_keyword + " (" + results.length + ")");
            result_list.height(document.body.clientHeight - result_list.offset().top);
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
            markers = results.reverse().map(function(result) {
              return {
                position: result.geometry.location,
                icon: "https://www.google.com/mapfiles/marker" + result.seq + ".png"
              };
            });
            result_list.listview('refresh');
            markers.push({
              position: curlatlng,
              icon: 'https://www.google.com/mapfiles/arrow.png'
            });
            map.setMarkers(markers);
            if (app.history[0] !== app.search_keyword) {
              app.history.unshift(app.search_keyword);
              app.history.refresh();
            }
          }
          return this;
        });
      });
      return this;
    }
  });
  console.log(1);
}).call(this);
