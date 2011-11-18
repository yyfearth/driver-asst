(function() {
  var dirRenderer, dirSvc, geocoder, map, map_spacers, svbounds, svc;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  window.app = {
    back: function() {
      return history.go(-1);
    }
  };
  location.hash = '#home';
  $('[data-role="page"] [data-role="header"]:not(.ui-non-nav)').append($('[data-btn-role="back"],[data-btn-role="home"]'));
  $('#search [data-btn-role="home"]').hide();
  map_spacers = $(document.querySelectorAll('[data-role="map"]'));
  map_spacers.add('#map').height(Math.round(document.body.clientHeight * 0.35));
  $('#home').one({
    pageshow: function() {
      return map.el.offset($('#home_map').offset());
    }
  });
  map = app.map = new google.maps.Map($('#map')[0], {
    zoom: 15,
    mapTypeId: google.maps.MapTypeId.ROADMAP,
    navigationControl: true,
    navigationControlOptions: {
      style: google.maps.NavigationControlStyle.SMALL
    }
  });
  svc = new google.maps.places.PlacesService(map);
  geocoder = new google.maps.Geocoder();
  dirSvc = new google.maps.DirectionsService();
  dirRenderer = new google.maps.DirectionsRenderer();
  svbounds = new google.maps.LatLngBounds(new google.maps.LatLng(38.052417, -122.728271), new google.maps.LatLng(37.247821, -121.552734));
  (function() {
    var trafficLayer;
    this.el = $('#map');
    trafficLayer = new google.maps.TrafficLayer();
    trafficLayer.setMap(this);
    return $.extend(this, {
      move: __bind(function(id) {
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
            if (!curlatlng.equals(this.getCenter())) {
              curlatlng.changed = true;
            }
            if (auto) {
              this.setMarkers(null);
              this.setCenter(curlatlng);
              map_spacers.each(__bind(function(i, m) {
                return $(m).css('background-image', "url('https:#maps.googleapis.com/maps/api/staticmap?center=" + (curlatlng.lat()) + "," + (curlatlng.lng()) + "&zoom=" + ($(m).attr('data-map-zoom') || 15) + "&size=" + ($(window).width()) + "x" + (this.el.height()) + "&maptype=roadmap&format=png8&sensor=true')");
              }, this));
              return geocoder.geocode({
                latLng: curlatlng
              }, __bind(function(results, status) {
                var _ref;
                if (status === google.maps.GeocoderStatus.OK) {
                  callback.call(this, curlatlng, (_ref = results[0]) != null ? _ref.formatted_address : void 0);
                } else {
                  alert("Geocoder failed due to: " + status + "\n App terminated!");
                }
                return this.setCenter(curlatlng);
              }, this));
            } else {
              return callback.call(this, curlatlng);
            }
          }, this)), (function() {
            return alert('App cannot run without geo location!');
          }));
        }
        return this;
      }, this)
    });
  }).call(map);
  $('[data-role="page"]').bind({
    pagebeforeshow: function() {
      return map.el.css('opacity', 0).show();
    },
    pageshow: function() {
      return map.el[$(this).hasClass('has-map') ? 'show' : 'hide']().css('opacity', 1);
    }
  });
  $('#home').bind({
    pageshow: function() {},
    pagebeforeshow: function() {
      if ($('#map', this).length) {
        return;
      }
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
    },
    pagehide: function() {}
  });
  function xml2json(b,g,h){function j(b,g){if(!b)return null;var c="",a=null;if(b.childNodes&&0<b.childNodes.length)for(var i=0;i<b.childNodes.length;i++){var d=b.childNodes[i],f=d.nodeType,e=d.localName||d.nodeName||"",h=d.text||d.nodeValue||"";if(8!=f)if(3==f||4==f||!e)c+=h.replace(/^\s+|\s+$/g,"");else if(a=a||{},a[e]){if(!(a[e]instanceof Array)||!a[e].length)a[e]=[a[e]];a[e].push(j(d,!0))}else a[e]=j(d,!1)}if(b.attributes&&!k&&0<b.attributes.length){a=a||{};for(d=0;d<b.attributes.length;d++)e=b.attributes[d],f=e.name||"",e=e.value,a[f]?(!(a[f]instanceof Array)&&a[f].length&&(a[f]=[a[f]]),a[f].push(e)):a[f]=e}if(a){if(""!=c){d=new String(c);for(i in a)d[i]=a[i];a=d}if(c=a.text?("object"==typeof a.text?a.text:[a.text||""]).concat([c]):c)a.text=c;c=""}a=a||c;if(l){c&&(a={});if(c=a.text||c||"")a.text=c;!g&&!(a instanceof Array)&&(a=[a])}return a}var l=g,k=h;if(!b)return{};"string"==typeof b&&(b=q(b));if(b.nodeType){if(3==b.nodeType||4==b.nodeType)return b.nodeValue;b=9==b.nodeType?b.documentElement:b;g=j(b,!0);b=b=null;return g}}function q(b){var g;try{var h=new DOMParser;h.async=!1;g=h.parseFromString(b,"text/xml")}catch(j){throw Error("Error parsing XML string");}return g};
  $.ajax({
    url: '/gapi?weather=san+jose,ca',
    dataType: 'xml',
    success: function(xml, xhr) {
      var cur, getIcon, j;
      j = xml2json(xml);
      cur = j.weather.current_conditions;
      console.log('w:', j);
      getIcon = function(d) {
        return "https://www.google.com" + d.icon.data;
      };
      $('#weather').html("<img src=\"" + (getIcon(cur)) + "\"/>" + cur.temp_f.data + "\u00b0F " + cur.condition.data);
      return this;
    },
    error: function(xhr) {
      return console.log('get weather failed', xhr);
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
      app.history.refresh();
      return new google.maps.places.Autocomplete($('#input_search')[0], {
        bounds: svbounds,
        types: ['establishment']
      });
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
            app.result_map = {};
            results.forEach(function(r) {
              var dlat, dlng;
              app.result_map[r.id] = r;
              r = r.geometry;
              dlng = r.location.lng() - curlatlng.lng();
              dlat = r.location.lat() - curlatlng.lat();
              return r.dist = Math.pow(dlng, 2) + Math.pow(dlat, 2);
            });
            results.sort(function(a, b) {
              return a.geometry.dist - b.geometry.dist;
            });
            results = results.slice(0, 25);
            result_list.append(results.map(function(r, i) {
              r.seq = String.fromCharCode(65 + i);
              return "<li><a href=\"#detail\" data-btn-role=\"result\" id=\"" + r.id + "\"><div style=\"float:left\">" + r.seq + "</div><img src=\"" + r.icon + "\" class=\"ui-li-icon\"><h3 class=\"ui-li-heading\">" + r.name + "</h3><p class=\"ui-li-desc\">" + r.vicinity + "</p></li>";
            }).join(''));
            markers = results.reverse().map(function(result) {
              return {
                position: result.geometry.location,
                icon: "https:#www.google.com/mapfiles/marker" + result.seq + ".png"
              };
            });
            result_list.listview('refresh');
            markers.push({
              position: curlatlng,
              icon: 'https:#www.google.com/mapfiles/arrow.png'
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
  $('#result_list a').live({
    vclick: function() {
      console.log(this.id);
      return app.selected_place = app.result_map[this.id];
    }
  });
  $('#detail').bind({
    pageshow: function() {
      console.log('detailof', app.selected_place);
      if (!app.selected_place) {
        app.back();
        return;
      }
      $('#apt_cancel').bind({
        vclick: function() {
          return $('#appointment').dialog('close');
        }
      });
      return svc.getDetails({
        reference: app.selected_place.reference
      }, function(place, status) {
        if (status === google.maps.places.PlacesServiceStatus.OK) {
          map.setCenter(place.geometry.location);
          map.setMarkers({
            position: place.geometry.location
          });
          map.setZoom(15);
          $('#detail_place').text(place.name);
          $('#detial_info').text(JSON.stringify(place, null, '  '));
          return console.log(place);
        }
      });
    }
  });
  $('#direction').bind({
    pageshow: function() {
      return map.getCurPos(function(curlatlng, addr) {
        this.setZoom(14);
        return dirSvc.route({
          origin: addr,
          destination: app.selected_place.vicinity,
          travelMode: google.maps.DirectionsTravelMode.DRIVING,
          unitSystem: google.maps.DirectionsUnitSystem.IMPERIAL,
          provideRouteAlternatives: true
        }, function(dirResult, dirStatus) {
          if (dirStatus === google.maps.DirectionsStatus.OK) {
            dirRenderer.setMap(map);
            dirRenderer.setPanel($('#direction_panel')[0]);
            return dirRenderer.setDirections(dirResult);
          } else {
            return alert('Directions failed: ' + dirStatus);
          }
        });
      });
    },
    pagehide: function() {
      return dirRenderer.setMap(null);
    }
  });
  console.log(1);
}).call(this);
