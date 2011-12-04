(function() {
  var b, date_svc, hash, map, map_spacers, place_svc_typs, proc_rating, svc, sync_alerts, sync_place, _ref, _ref2, _ref3;
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };
  window.offline_mode = !navigator.onLine;
  window.app = {
    back: function() {
      return history.go(-1);
    },
    autologin: $('#autologin').val() === 'on',
    offline: function() {
      return !navigator.onLine;
    }
  };
  setTimeout((function() {
    if (window.offline_mode && navigator.onLine) {
      if (confirm('You are online now, \npress OK to reload the App and enable online features!')) {
        return location.reload();
      } else {
        return setTimeout(arguments.callee, 60000);
      }
    }
  }), 10000);
  if (app.offline()) {
    $(document.body).addClass('offline');
  }
  svc = function(svc, cfg) {
    if ((svc.svc != null) && !(cfg != null)) {
      cfg = svc;
      svc = cfg.svc;
    } else if (typeof svc === 'string') {
      cfg.svc = svc;
    }
    cfg.type = (cfg.type != null) && /get/i.test(cfg.type) ? 'GET' : 'POST';
    if (cfg.type === 'POST') {
      cfg.data = JSON.stringify(cfg.data);
    }
    if (cfg.background || !cfg.nowait) {
      $.mobile.showPageLoadingMsg();
    }
    $.ajax({
      url: "svc/" + cfg.svc + ".svc/" + cfg.method,
      type: cfg.type,
      dataType: 'json',
      contentType: 'application/json;charset=utf-8',
      data: cfg.data,
      processdata: cfg.type !== 'POST',
      complete: function(xhr) {
        if (cfg.nowait) {
          return;
        }
        $.mobile.hidePageLoadingMsg();
        return typeof cfg.complete === "function" ? cfg.complete() : void 0;
      },
      success: function(data, txt, xhr) {
        if (cfg.nowait) {
          return;
        }
        if ((data != null) && 'd' in data) {
          return typeof cfg.callback === "function" ? cfg.callback(data.d) : void 0;
        } else {
          alert('Network Error');
          return console.log('err', xhr, xhr.statusText);
        }
      },
      error: function(xhr) {
        alert('Network Error');
        return console.log('err', xhr, xhr.statusText);
      }
    });
    return false;
  };
  date_svc = {
    dateToWcf: function(dt) {
      var o;
      o = new Date().getTimezoneOffset() / 60;
      return "\/Date(" + (+(Date.parse(dt) - o * 3600000)) + (o > 0 ? '-' : '+') + (o > 9 ? '' : '0') + o + "00)\/";
    },
    dateFromWcf: function(str) {
      var h, m, ts;
      m = str.match(/^\/Date\((\d+)([+-]\d{2})(\d{2})\)\/$/);
      if (m.length !== 4) {
        return null;
      }
      ts = Number(m[1]);
      h = Number(m[2]);
      return new Date(ts - h * 3600000);
    },
    dateToStr: function(dt) {
      dt = new Date(dt);
      return "" + (dt.getFullYear()) + "-" + (dt.getMonth() + 1) + "-" + (dt.getDate()) + " " + (dt.getHours()) + ":" + (dt.getMinutes()) + ":" + (dt.getSeconds());
    },
    dateFromWcfToStr: function(str) {
      return this.dateToStr(this.dateFromWcf(str));
    },
    dateToUTC: function(dt) {
      dt = new Date(dt);
      return "" + (dt.getUTCFullYear()) + "-" + (dt.getUTCMonth() + 1) + "-" + (dt.getUTCDate()) + "T" + (dt.getUTCHours()) + ":" + (dt.getUTCMinutes()) + ":" + (dt.getUTCSeconds());
    }
  };
  try {
    app.user = JSON.parse(sessionStorage.user || localStorage.user);
    if (((_ref = app.user) != null ? _ref.uid : void 0) > 0 && ((_ref2 = app.user) != null ? (_ref3 = _ref2.sid) != null ? _ref3.length : void 0 : void 0) === 32) {
      location.hash = '#home';
      svc('user', {
        method: 'check',
        data: {
          uid: app.user.uid,
          sid: app.user.sid
        },
        callback: function(ok) {
          console.log('check', ok);
          if (!ok) {
            $.mobile.changePage('#login', {
              transition: 'none'
            });
          }
          return null;
        }
      });
    } else {
      location.hash = '#login';
    }
  } catch (e) {
    app.user = null;
    location.hash = '#login';
  }
  console.log('app.user', app.user);
  app.save_profile = window.onbeforeunload = function() {
    var p, _ref4;
    if ((_ref4 = app.user) != null ? _ref4.uid : void 0) {
      p = sessionStorage.user = JSON.stringify(app.user);
      if (app.autologin) {
        localStorage.user = p;
      }
    } else {
      localStorage.removeItem('user');
      sessionStorage.removeItem('user');
    }
  };
  $('[data-role="page"] [data-role="header"]:not(.ui-non-nav)').append($('[data-btn-role="back"],[data-btn-role="home"]'));
  $('#search [data-btn-role="home"]').hide();
  b = document.body;
  map_spacers = $(document.querySelectorAll('[data-role="map"]'));
  $(window).resize(function() {
    app.horizontal = b.clientWidth > b.clientHeight;
    return $(b)[app.horizontal ? 'addClass' : 'removeClass']('horizontal');
  });
  $(document.body).resize();
  map = app.map = null;
  if (!app.offline()) {
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
    map.plcsvc = new google.maps.places.PlacesService(map);
    map.geocoder = new google.maps.Geocoder();
    map.dirsvc = new google.maps.DirectionsService();
    map.dirrdr = new google.maps.DirectionsRenderer();
    map.svbounds = new google.maps.LatLngBounds(new google.maps.LatLng(38.052417, -122.728271), new google.maps.LatLng(37.247821, -121.552734));
    (function() {
      var trafficLayer;
      this.el = $('#map');
      trafficLayer = new google.maps.TrafficLayer();
      trafficLayer.setMap(this);
      return $.extend(this, {
        setMarkers: __bind(function(markers_cfg) {
          console.log('markers', markers_cfg);
          if (!markers_cfg) {
            markers_cfg = null;
          } else if (!$.isArray(markers_cfg)) {
            markers_cfg = [markers_cfg];
          }
          if (this.markers != null) {
            this.markers.forEach((function(marker) {
              return marker.setMap(null);
            }));
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
          if (app.offline()) {
            callback.call(this, null, null);
          } else {
            if (navigator.geolocation != null) {
              navigator.geolocation.getCurrentPosition((__bind(function(pos) {
                var curlatlng;
                curlatlng = new google.maps.LatLng(pos.coords.latitude, pos.coords.longitude);
                console.log('curlatlng', curlatlng);
                if (!curlatlng.equals(this.getCenter())) {
                  curlatlng.changed = true;
                }
                if (auto && curlatlng.changed) {
                  this.setMarkers(null);
                  this.setCenter(curlatlng);
                  map_spacers.each(__bind(function(i, m) {
                    return $(m).css('background-image', "url('//maps.googleapis.com/maps/api/staticmap?center=" + (curlatlng.lat()) + "," + (curlatlng.lng()) + "&zoom=" + ($(m).attr('data-map-zoom') || 15) + "&size=" + ($(window).width()) + "x" + (this.el.height()) + "&maptype=roadmap&format=png8&sensor=true&language=en')");
                  }, this));
                  return map.geocoder.geocode({
                    latLng: curlatlng
                  }, __bind(function(results, status) {
                    var _ref4;
                    if (status === google.maps.GeocoderStatus.OK) {
                      callback.call(this, curlatlng, (_ref4 = results[0]) != null ? _ref4.formatted_address : void 0);
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
          }
          return this;
        }, this)
      });
    }).call(map);
    $('[data-role="page"]').bind({
      pagebeforeshow: function() {
        map.el.addClass('hidden');
        return $(document.body)[app.offline() ? 'addClass' : 'removeClass']('offline');
      },
      pageshow: function() {
        var _ref4, _ref5;
        $.mobile.fixedToolbars.show();
        this.hh = ((_ref4 = $('[data-role="header"]', this)) != null ? _ref4.outerHeight() : void 0) || 0;
        this.fh = ((_ref5 = $('[data-role="footer"]', this)) != null ? _ref5.outerHeight() : void 0) || 0;
        this.bh = document.body.clientHeight - this.hh - this.fh;
        $('.map', this).add(map.el).height(this.bh * (app.horizontal ? 1 : 0.45));
        if ($(this).hasClass('has-map')) {
          return map.el.removeClass('hidden');
        }
      }
    });
  }
  app.sync_weather = function() {
    var ref_w;
    ref_w = function(j) {
      var cur, el, getIcon, _ref4;
      if (((_ref4 = j.weather) != null ? _ref4.current_conditions : void 0) != null) {
        cur = j.weather.current_conditions;
        console.log('w:', j);
        getIcon = function(d) {
          return "//www.google.com" + d.icon.data;
        };
        el = $('#weather').html("<div id=\"weather_now\" class=\"weather\"><img src=\"" + (getIcon(cur)) + "\"/>" + cur.condition.data + "<br/>" + cur.temp_f.data + "\u00b0F</div>");
        el.append((j.weather.forecast_conditions.map(function(c) {
          return "<div class=\"weather\"><img src=\"" + (getIcon(c)) + "\"/>" + c.day_of_week.data + " " + c.high.data + "/" + c.low.data + "\u00b0F</div>";
        })).join(''));
      } else {
        $('#weather').html('(No Weather Data)');
      }
      return this;
    };
    if (!app.offline()) {
      return $.ajax({
        url: 'gapi?&hl=en-us&weather=san+jose,ca',
        dataType: 'xml',
        success: function(xml, xhr) {
          var j;
          j = xml2json(xml);
          localStorage.weather = JSON.stringify(j);
          return ref_w(j);
        },
        error: function(xhr) {
          return console.log('get weather failed', xhr);
        }
      });
    } else if (localStorage.weather != null) {
      return ref_w(JSON.parse(localStorage.weather));
    } else {
      return ref_w(null);
    }
  };
  function xml2json(b,g,h){function j(b,g){if(!b)return null;var c="",a=null;if(b.childNodes&&0<b.childNodes.length)for(var i=0;i<b.childNodes.length;i++){var d=b.childNodes[i],f=d.nodeType,e=d.localName||d.nodeName||"",h=d.text||d.nodeValue||"";if(8!=f)if(3==f||4==f||!e)c+=h.replace(/^\s+|\s+$/g,"");else if(a=a||{},a[e]){if(!(a[e]instanceof Array)||!a[e].length)a[e]=[a[e]];a[e].push(j(d,!0))}else a[e]=j(d,!1)}if(b.attributes&&!k&&0<b.attributes.length){a=a||{};for(d=0;d<b.attributes.length;d++)e=b.attributes[d],f=e.name||"",e=e.value,a[f]?(!(a[f]instanceof Array)&&a[f].length&&(a[f]=[a[f]]),a[f].push(e)):a[f]=e}if(a){if(""!=c){d=new String(c);for(i in a)d[i]=a[i];a=d}if(c=a.text?("object"==typeof a.text?a.text:[a.text||""]).concat([c]):c)a.text=c;c=""}a=a||c;if(l){c&&(a={});if(c=a.text||c||"")a.text=c;!g&&!(a instanceof Array)&&(a=[a])}return a}var l=g,k=h;if(!b)return{};"string"==typeof b&&(b=q(b));if(b.nodeType){if(3==b.nodeType||4==b.nodeType)return b.nodeValue;b=9==b.nodeType?b.documentElement:b;g=j(b,!0);b=b=null;return g}}function q(b){var g;try{var h=new DOMParser;h.async=!1;g=h.parseFromString(b,"text/xml")}catch(j){throw Error("Error parsing XML string");}return g};
  function sha1(a){for(var d=[],b=0;b<8*a.length;b+=8)d[b>>5]|=(a.charCodeAt(b/8)&255)<<24-b%32;a=8*a.length;d[a>>5]|=128<<24-a%32;d[(a+64>>9<<4)+15]=a;for(var a=Array(80),b=1732584193,e=-271733879,f=-1732584194,g=271733878,i=-1009589776,j=0;j<d.length;j+=16){for(var k=b,l=e,m=f,n=g,o=i,c=0;80>c;c++){a[c]=16>c?d[j+c]:(a[c-3]^a[c-8]^a[c-14]^a[c-16])<<1|(a[c-3]^a[c-8]^a[c-14]^a[c-16])>>>31;var p=h(h(b<<5|b>>>27,20>c?e&f|~e&g:40>c?e^f^g:60>c?e&f|e&g|f&g:e^f^g),h(h(i,a[c]),20>c?1518500249:40>c?1859775393:60>c?-1894007588:-899497514)),i=g,g=f,f=e<<30|e>>>2,e=b,b=p}b=h(b,k);e=h(e,l);f=h(f,m);g=h(g,n);i=h(i,o)}d=[b,e,f,g,i];a="";for(b=0;b<4*d.length;b++)a+="0123456789abcdef".charAt(d[b>>2]>>8*(3-b%4)+4&15)+"0123456789abcdef".charAt(d[b>>2]>>8*(3-b%4)&15);return a};function h(a,d){var b=(a&65535)+(d&65535);return(a>>16)+(d>>16)+(b>>16)<<16|b&65535};;
  hash = function(str1, str2) {
    var h;
    h = 'KnightRider\x58\xb5\x04\x05\xf1\x50\x47\x6f\xf0\x40\xd8\xf4\xed\x9d\xd2\x79\xc0\x6e\xa6\xd9\xffKnightRider';
    return sha1(h + str1 + sha1(h + str1 + '\xff' + str2 + h) + str2 + h);
  };
  /* ----- dev only -----
  if localStorage.places?
  	pls = JSON.parse localStorage.places
  	c = 0
  	for ref, types of pls
  		do (ref, types) ->
  			c++
  			map.plcsvc.getDetails (reference: ref), (p, status) ->
  				if status is google.maps.places.PlacesServiceStatus.OK
  					pp =
  						gid: p.id
  						gref: ref
  						name: p.name
  						location:
  							lat: p.geometry.location.lat()
  							lng: p.geometry.location.lng()
  						vicinity: p.vicinity
  						fulladdr: p.formatted_address
  						phone: p.formatted_phone_number
  						website: if p.website? then (p.website.replace /^http:\/\//, '') else p.url.replace /^.*cid=(\d+).*$/, 'place:$1'
  						rating: if p.rating? then p.rating else null
  						gtypes: p.types.join ','
  						svctypes: types
  					console.log p, status, pp
  					svc 'place',
  						method: 'add'
  						data: place: pp
  	console.log c
  return
  # -------------------- */
  if (window.openDatabase != null) {
    app.db = openDatabase("KnightRider", "1.0", "Data cache for Knight Rider", 200000);
    if (app.db != null) {
      app.db._onerr = function(t, e) {
        return console.error('local db error', t, e);
      };
      app.db.sync = function(svc_name, callback) {
        console.log('sync', svc_name);
        svc_name = svc_name.toLowerCase();
        app.db.transaction(function(tx) {
          return tx.executeSql("SELECT modified FROM [" + svc_name + "] WHERE id=0", [], function(tx, data) {
            var last;
            last = data.rows.item(0);
            console.log('last', svc_name, last);
            return svc(svc_name, {
              method: 'sync',
              type: 'get',
              data: {
                last: date_svc.dateToStr(last.modified)
              },
              callback: function(data) {
                console.log('sync', svc_name, data);
                return app.db.transaction(__bind(function(tx) {
                  return tx.executeSql("UPDATE [" + svc_name + "] SET modified=DATETIME('now') WHERE id=0", [], function() {
                    return typeof callback === "function" ? callback(data) : void 0;
                  });
                }, this));
              }
            });
          });
        });
        return this;
      };
      sync_place = function() {
        if (app.offline()) {
          return;
        }
        return app.db.sync('place', function(data) {
          if (data.length) {
            return app.db.transaction(function(tx) {
              var ids, sql, vals;
              ids = data.map(function(p) {
                return p.id;
              });
              vals = data.map(function(p) {
                return [p.id, p.gid, p.gref, p.name, p.location.lat, p.location.lng, p.vicinity, p.fulladdr, p.phone, p.website, p.rating, p.gtypes, p.svctypes, p.status, date_svc.dateFromWcfToStr(p.created), date_svc.dateFromWcfToStr(p.modified)];
              });
              sql = "INSERT INTO [Place](id,gid,gref,name,lat,lng,vicinity,fulladdr,phone,website,rating,gtypes,svctypes,status,created,modified) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);";
              console.log('db', sql, vals);
              tx.executeSql("DELETE FROM [Place] WHERE id IN (" + (ids.join(',')) + ")");
              return vals.forEach(function(val) {
                return tx.executeSql(sql, val, null, app.db._onerr);
              });
            });
          }
        });
      };
      sync_alerts = function(callback) {
        var load_alerts;
        load_alerts = function(tx) {
          return tx.executeSql("SELECT * FROM [Alerts] WHERE status=1 and expired > DATETIME('now') ORDER BY datetime DESC, importance DESC;", [], (function(tx, ret) {
            var i, rows;
            console.log('alerts count', ret.rows.length);
            rows = [];
            i = ret.rows.length;
            while (i) {
              rows.unshift($.extend({}, ret.rows.item(--i)));
            }
            console.log('alerts from db', rows, ret);
            return typeof callback === "function" ? callback(rows, 'alerts') : void 0;
          }), app.db._onerr);
        };
        if (app.offline()) {
          app.db.transaction(load_alerts);
        } else {
          app.db.sync('alerts', function(data) {
            app.db.transaction(function(tx) {
              var ids, sql, vals;
              if (data.length) {
                ids = data.map(function(a) {
                  return a.id;
                });
                vals = data.map(function(a) {
                  return [a.id, a.summary, a.message, date_svc.dateFromWcfToStr(a.datetime), date_svc.dateFromWcfToStr(a.expired), a.importance, a.type, a.status, date_svc.dateFromWcfToStr(a.created), date_svc.dateFromWcfToStr(a.modified)];
                });
                sql = "INSERT INTO [Alerts](id,summary,message,datetime,expired,importance,type,status,created,modified) VALUES (?,?,?,?,?,?,?,?,?,?);";
                console.log('db', sql, vals);
                tx.executeSql("DELETE FROM [Alerts] WHERE id IN (" + (ids.join(',')) + ")");
                vals.forEach(function(val) {
                  return tx.executeSql(sql, val);
                });
              }
              load_alerts(tx);
              return this;
            });
            return this;
          });
        }
        return this;
      };
      app.db.sync_all = function(callback) {
        console.log('sync all');
        sync_place();
        return sync_alerts(callback);
      };
      app.db.transaction(function(tx) {
        tx.executeSql("CREATE TABLE IF NOT EXISTS [Alerts] (				id int not null primary key, 				summary nvarchar(100) not null, 				message text, 				datetime timestamp, 				expired timestamp, 				importance tinyint not null, 				type tinyint not null, 				status tinyint not null,				created timestamp DEFAULT CURRENT_TIMESTAMP, 				modified timestamp not null			);", [], function(tx) {
          return tx.executeSql("INSERT INTO [Alerts](id,summary,importance,type,status,modified) VALUES (0,'LastUpdate',0,0,0,DATETIME(0,'unixepoch'));");
        });
        return tx.executeSql("CREATE TABLE IF NOT EXISTS [Place] (				id int not null primary key, 				gid char(40),				gref nvarchar(300),				name nvarchar(100),				lat float,				lng float,				vicinity nvarchar(200),				fulladdr nvarchar(1000),				phone varchar(15),				website varchar(100),				rating tinyint,				gtypes varchar(100),				svctypes tinyint not null,				status tinyint not null,				created timestamp DEFAULT CURRENT_TIMESTAMP,				modified timestamp not null			);", [], function(tx) {
          return tx.executeSql("INSERT INTO [Place](id,name,svctypes,status,modified) VALUES (0,'LastUpdate',0,0,DATETIME(0,'unixepoch'));");
        });
      });
    } else {
      alert('open db err');
    }
  }
  $('#home').bind({
    pagecreate: function() {
      return this.created = true;
    },
    pagebeforeshow: function() {
      var created;
      console.log('home pageshow');
      created = this.created;
      if (app.offline()) {
        $('#home_addr').text('You are offline now');
      } else if (!window.offline_mode) {
        map.getCurPos(function(curlatlng, addr) {
          if (addr != null) {
            $('#home_addr').text(addr);
          }
          this.setZoom(15);
          return this.setMarkers({
            position: curlatlng
          });
        });
      }
      app.sync_weather();
      app.db.sync_all(function(data, svc) {
        var alert_el, alerts, html;
        if (svc === 'alerts') {
          alerts = data;
          alert_el = $('#alerts').empty();
          html = '<li data-role="list-divider" class="ui-body-c list-none">No Alerts</li>';
          if (alerts.length > 0) {
            html = ("<li data-role=\"list-divider\" class=\"ui-body-c list-none\">" + alerts.length + " Alerts</li>") + alerts.map(function(a) {
              return "<li><a href=\"javascript:alert('Summary: " + a.summary + "\\nMessage: " + a.message + "\\nFrom: " + a.datetime + "\\nExpire: " + a.expired + "')\">" + a.summary + " (" + (a.datetime.toLocaleDateString()) + ")</a></li>";
            }).join('');
          }
          return $('#alerts').html(html).listview().listview('refresh');
        }
      });
      return this;
    },
    pageshow: function() {
      var alert_el;
      alert_el = $('#alerts');
      return alert_el.height(document.body.clientHeight - alert_el.offset().top - this.fh);
    }
  });
  $('#login').bind({
    pagecreate: function() {
      $('#login_form').submit(function(e) {
        var btns, email, inputs, password, pk, slider;
        e.preventDefault();
        e.stopPropagation();
        if (app.offline()) {
          return false;
        }
        inputs = $('input', this).textinput('disable');
        slider = $('select', this).slider('disable');
        btns = $('button', this).button('disable');
        $('#btn_reg').addClass('ui-disabled');
        email = $('#email').val().trim();
        password = $('#password').val();
        if (!email || !password) {
          return false;
        }
        pk = hash(email.toLowerCase(), password);
        app.autologin = $('#autologin').val() === 'on';
        svc('user', {
          method: 'login',
          data: {
            email: email,
            password: pk
          },
          callback: function(data) {
            var _ref4;
            console.log(data);
            if (data.uid && ((_ref4 = data.sid) != null ? _ref4.length : void 0) === 32) {
              app.user = {
                uid: data.uid,
                email: email,
                sid: data.sid,
                psw: hash(data.sid + data.uid + pk)
              };
              return $.mobile.changePage('#home', {
                transition: 'flip'
              });
            } else {
              return alert('Login Failed, please try again');
            }
          },
          complete: function() {
            btns.button('enable');
            inputs.textinput('enable');
            slider.slider('enable');
            return $('#btn_reg').removeClass('ui-disabled');
          }
        });
        return false;
      });
      return this;
    },
    pagebeforehide: function() {
      return $('#login_form_warp').hide();
    },
    pagebeforeshow: function() {
      return $('#login_form_warp').hide();
    },
    pageshow: function() {
      $('#password').val('');
      $('#login_form_warp').show();
      console.log('logout', app.user);
      if (navigator.onLine) {
        $('button', this).button('enable');
        $('#btn_reg').removeClass('ui-disabled');
        if (!(app.user != null)) {
          return;
        }
        svc('user', {
          method: 'logout',
          nowait: true,
          data: {
            uid: app.user.uid,
            sid: app.user.sid
          }
        });
        app.user = null;
        app.save_profile();
      } else {
        $('button', this).button('disable');
        $('#btn_reg').addClass('ui-disabled');
        if (app.offline()) {
          alert('You are offline now!\nLogin need a network.');
        }
      }
      return this;
    }
  });
  $('#reg_form').submit(function(e) {
    var email, password, pk, u;
    e.preventDefault();
    e.stopPropagation();
    if (app.offline()) {
      return false;
    }
    if (this.password.value !== this.password2.value) {
      alert('Password does not match!');
      this.password2.focus();
      return false;
    }
    email = this.email.value.trim();
    password = this.password.value;
    pk = hash(email.toLowerCase(), password);
    u = {
      email: email,
      password: pk,
      fullname: {
        first: this.first.value.trim(),
        last: this.last.value.trim()
      },
      phone: this.phone.value.trim()
    };
    console.log('reg', u);
    svc('user', {
      method: 'reg',
      data: {
        user: u
      },
      callback: function(uid) {
        console.log('new id:', uid);
        if (uid < 1) {
          return alert('Email already exists!');
        } else {
          $('#email').val(u.email);
          $('#reg').dialog('close');
          return alert('Registration successful!');
        }
      }
    });
    return false;
  });
  $('#appointment').bind({
    pagebeforeshow: function() {
      var _ref4, _ref5;
      if (app.offline()) {
        return app.back();
      }
      $('#datetime').val(Date(new Date().getTime() + 60 * 60 * 1000).toLocaleString());
      if (!(((_ref4 = app.user) != null ? (_ref5 = _ref4.sid) != null ? _ref5.length : void 0 : void 0) === 32)) {
        $.mobile.changePage('#login', {
          transition: 'flip',
          reverse: true
        });
      }
      return false;
    }
  });
  $('#appt_form').submit(function(e) {
    var appt, _ref4, _ref5, _ref6;
    if (!(((_ref4 = app.user) != null ? (_ref5 = _ref4.sid) != null ? _ref5.length : void 0 : void 0) === 32) || (((_ref6 = app.user) != null ? _ref6.uid : void 0) === 0) || app.offline()) {
      return false;
    }
    e.preventDefault();
    e.stopPropagation();
    appt = {
      user: app.user.uid,
      place: app.selected_place.id,
      contact: {
        name: this.name.value,
        phone: this.phone.value
      },
      datetime: date_svc.dateToWcf(this.datetime.value),
      message: this.comments.value
    };
    console.log('appt', appt);
    svc('appointment', {
      method: 'add',
      data: {
        appt: appt,
        sid: app.user.sid
      },
      callback: function(success) {
        console.log('appt success:', success);
        if (!success) {
          return $.mobile.changePage('#login', {
            transition: 'flip',
            reverse: true
          });
        } else {
          $('#appointment').dialog('close');
          return alert('Appointment sent successful!');
        }
      }
    });
    return false;
  });
  $('[data-btn-role="search"]').live({
    vclick: function(e) {
      app.search_keyword = $(this).text();
      console.log('vclick', app.search_keyword);
      return this;
    }
  });
  app.custom_search_history_refresh = function() {
    var l, _ref4;
    $('#custom_history_list li:gt(0)').remove();
    l = '<li data-role="list-divider" class="ui-body-c list-none">(None)</li>';
    if ((_ref4 = app.user.custom_search_history) != null ? _ref4.length : void 0) {
      l = app.user.custom_search_history.map(function(item) {
        return "<li><a href=\"#result\" data-btn-role=\"search\">" + item + "</a></li>";
      }).join('');
    }
    return $('#custom_history_list_header').after(l);
  };
  app.place_search_history_refresh = function() {
    var l, _ref4;
    $('#search_history_list li:gt(0)').remove();
    l = '<li data-role="list-divider" class="ui-body-c list-none">(None)</li>';
    if ((_ref4 = app.user.place_search_history) != null ? _ref4.length : void 0) {
      l = app.user.place_search_history.map(function(r, i) {
        return "<li><a href=\"#detail\" data-btn-role=\"result\" data-index=\"" + i + "\"><img src=\"" + r.icon + "\" class=\"ui-li-icon\"><h3 class=\"ui-li-heading\">" + r.name + "</h3><p class=\"ui-li-desc\">" + r.vicinity + "</p></li>";
      }).join('');
    }
    return $('#search_history_list_header').after(l);
  };
  $('#custom_search').bind({
    pagecreate: function() {
      this.created = true;
      app.custom_search_history_refresh();
      if (!app.offline()) {
        return new google.maps.places.Autocomplete($('#input_search')[0], {
          bounds: map.svbounds,
          types: ['establishment']
        });
      }
    }
  });
  $('#custom_search').bind('pageshow pagebeforeshow', function() {
    if (this.created) {
      return $('#custom_history_list').listview('refresh');
    }
  });
  $('#custom_search_form').submit(function() {
    var input, keyword;
    input = $('#input_search');
    keyword = $.trim(input.val());
    if (keyword) {
      app.search_keyword = new String(keyword);
      app.search_keyword.custom = true;
      $.mobile.changePage('#result');
      console.log('vclick', app.search_keyword);
    } else {
      input.focus().val('');
    }
    return false;
  });
  $('#search_history').bind({
    pagecreate: function() {
      this.created = true;
      app.place_search_history_refresh();
      return $('#search_history li a').live({
        vclick: function() {
          return app.selected_place = app.user.place_search_history[Number($(this).attr('data-index'))];
        }
      });
    }
  });
  $('#search_history').bind('pageshow pagebeforeshow', function() {
    if (this.created) {
      return $('#search_history_list').listview('refresh');
    }
  });
  place_svc_typs = {
    'Service Station': 2,
    'Gas Station': 4,
    'Towing Station': 8,
    'Vehicle Repair Station': 16
  };
  $('#result').bind({
    pagebeforeshow: function() {
      var result_list;
      console.log('search for', app.search_keyword);
      if (!app.search_keyword) {
        app.back();
        return;
      }
      $.mobile.showPageLoadingMsg();
      result_list = $('#result_list').empty();
      if (app.offline()) {
        $('#result_addr').text('You are offline now');
      } else {
        map.getCurPos(function(curlatlng, addr) {
          this.setZoom(12);
          return map.plcsvc.search({
            location: curlatlng,
            radius: 5000,
            keyword: app.search_keyword
          }, function(results, status) {
            var hs, markers, pls, _base, _ref4;
            if (status === google.maps.places.PlacesServiceStatus.ZERO_RESULTS) {
              alert('Zero Result');
              app.back();
            } else if (status === google.maps.places.PlacesServiceStatus.OK) {
              $('#result_addr').text("" + app.search_keyword + " (" + results.length + ")");
              result_list.height(document.body.clientHeight - result_list.offset().top);
              console.log('search result', results);
              pls = localStorage.places != null ? JSON.parse(localStorage.places) : {};
              results.forEach(function(r) {
                if (pls[r.id] != null) {
                  return pls[r.reference] |= place_svc_typs[app.search_keyword];
                } else {
                  return pls[r.reference] = place_svc_typs[app.search_keyword];
                }
              });
              localStorage.places = JSON.stringify(pls);
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
                var _ref4;
                r.seq = String.fromCharCode(65 + i);
                return "<li><a href=\"#detail\" data-btn-role=\"result\" id=\"" + r.id + "\"><div style=\"float:left\">" + r.seq + "</div><img src=\"" + ((_ref4 = r.icon) != null ? _ref4.replace(/^http:/, '') : void 0) + "\" class=\"ui-li-icon\"><h3 class=\"ui-li-heading\">" + r.name + "</h3><p class=\"ui-li-desc\">" + r.vicinity + "</p></li>";
              }).join(''));
              markers = results.reverse().map(function(result) {
                return {
                  position: result.geometry.location,
                  icon: "//www.google.com/mapfiles/marker" + result.seq + ".png",
                  title: result.name
                };
              });
              result_list.listview('refresh');
              markers.push({
                position: curlatlng,
                icon: '//www.google.com/mapfiles/arrow.png',
                title: 'You are here'
              });
              map.setMarkers(markers);
              if (app.search_keyword.custom) {
                hs = (_ref4 = (_base = app.user).custom_search_history) != null ? _ref4 : _base.custom_search_history = [];
                if (hs.length === 0 || hs[0] !== app.search_keyword) {
                  hs.unshift(app.search_keyword);
                  app.custom_search_history_refresh();
                }
              }
            } else {
              alert('Search Error');
            }
            return this;
          });
        });
      }
      return this;
    }
  });
  proc_rating = function(rating) {
    var i, stars;
    rating = Number(rating);
    stars = rating.toFixed(1);
    i = rating | 0;
    if (i > 0) {
      stars += ' ' + new Array(i + 1).join('<img src="res/star.png"/>');
    }
    if (rating - i > 0.4) {
      stars += '<img src="res/halfstar.png"/>';
    }
    return stars;
  };
  $('#result_list a').live({
    vclick: function() {
      console.log(this.id);
      return app.selected_place = app.result_map[this.id];
    }
  });
  $('#detail').bind({
    pagecreate: function() {
      return $('#apt_cancel').bind({
        vclick: function(e) {
          e.preventDefault();
          e.stopPropagation();
          $('#appointment').dialog('close');
          return false;
        }
      });
    },
    pageshow: function() {
      var detial_info, show_detail;
      detial_info = $('#detial_info');
      detial_info.height(document.body.clientHeight - detial_info.offset().top - this.fh);
      console.log('detailof', app.selected_place);
      window.scrollTop = 0;
      if (!app.selected_place) {
        app.back();
        return;
      }
      $('[data-role="navbar"] a', this)[app.offline() ? 'addClass' : 'removeClass']('ui-disabled');
      show_detail = function(place) {
        var ln_type, psh, _base, _ref4, _ref5;
        map.setCenter(place.geometry.location);
        map.setMarkers({
          position: place.geometry.location
        });
        map.setZoom(15);
        $('#detail_place').text(place.name);
        ln_type = 'Visit its Website';
        if (place.website != null) {
          if (/^place:\d+/.test(place.website)) {
            place.website = place.website.replace('place:', 'http://maps.google.com/maps/place?cid=');
            ln_type = 'View on Google Place';
          }
          if (!/^http/.test(place.website)) {
            place.website = 'http://' + place.website;
          }
        } else {
          place.website = place.url;
          ln_type = 'View on Google Place';
        }
        detial_info.html("<ul><li>" + place.formatted_address + "</li><li>" + place.formatted_phone_number + "</li><li>" + (place.types.join(', ').replace(/_/g, ' ').toUpperCase()) + "</li><li>" + (place.rating != null ? proc_rating(place.rating) : '(No Rating Yet)') + "</li><li><a href=\"" + place.website + "\" target=\"_blank\">" + ln_type + "</a></li></ul>");
        psh = (_ref4 = (_base = app.user).place_search_history) != null ? _ref4 : _base.place_search_history = [];
        if (psh.length === 0 || psh[0].id !== app.selected_place.id) {
          psh.some(function(h, i) {
            if (h.id === app.selected_place.id) {
              psh.splice(i, 1);
              return true;
            }
            return false;
          });
          psh.unshift({
            id: place.id,
            reference: app.selected_place.reference,
            name: place.name,
            vicinity: place.vicinity,
            icon: (_ref5 = place.icon) != null ? _ref5.replace(/^http:/, '') : void 0
          });
          app.place_search_history_refresh();
        }
        console.log(place);
        return this;
      };
      if (app.selected_place.__detail) {
        show_detail(app.selected_place.__detail);
      } else if (app.offline()) {
        alert('todo: offline mode');
      } else {
        map.plcsvc.getDetails({
          reference: app.selected_place.reference
        }, function(place, status) {
          if (status === google.maps.places.PlacesServiceStatus.OK) {
            app.selected_place.__detail = place;
            return show_detail(place);
          }
        });
      }
      return this;
    }
  });
  $('#direction').bind({
    pagebeforeshow: function() {
      var direction_panel;
      if (app.offline()) {
        return app.back();
      }
      direction_panel = $('#direction_panel');
      direction_panel.height(document.body.clientHeight - direction_panel.offset().top);
      return map.getCurPos(function(curlatlng, addr) {
        return map.dirsvc.route({
          origin: addr,
          destination: app.selected_place.vicinity,
          travelMode: google.maps.DirectionsTravelMode.DRIVING,
          unitSystem: google.maps.DirectionsUnitSystem.IMPERIAL,
          provideRouteAlternatives: true
        }, function(dirResult, dirStatus) {
          if (dirStatus === google.maps.DirectionsStatus.OK) {
            map.dirrdr.setMap(map);
            map.dirrdr.setPanel(direction_panel[0]);
            return map.dirrdr.setDirections(dirResult);
          } else {
            return alert('Directions failed: ' + dirStatus);
          }
        });
      });
    },
    pagehide: function() {
      return map.dirrdr.setMap(null);
    }
  });
  console.log('Wilson', 7);
}).call(this);
