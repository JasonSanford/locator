var xhr = require('xhr');

L.mapbox.accessToken = 'pk.eyJ1IjoiamNzYW5mb3JkIiwiYSI6InRJMHZPZFUifQ.F4DMGoNgU3r2AWLY0Eni-w';

var map = new L.mapbox.Map('map-container', 'jcsanford.j25ef8lg');

function getLocation(type) {
  switch (type) {
    case 'current':
      var xhr_options = {
        uri: 'current.geojson',
        json: true,
        method: 'get'
      };
      function callback(error, resp, geojson) {
        if (error) {
          console.log(error);
          return;
        }
        var loc = [geojson.geometry.coordinates[1], geojson.geometry.coordinates[0]];
        var marker = L.userMarker(loc, {pulsing: true, accuracy: geojson.properties.accuracy, smallIcon: true});
        map.setView(loc, 12);
        marker.addTo(map);
      }
      xhr(xhr_options, callback);
  }
}

getLocation('current');