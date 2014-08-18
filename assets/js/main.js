var reqwest = require('reqwest');

NodeList.prototype.forEach        = Array.prototype.forEach;
HTMLCollection.prototype.forEach  = Array.prototype.forEach;
DOMTokenList.prototype.forEach    = Array.prototype.forEach;

L.mapbox.accessToken = 'pk.eyJ1IjoiamNzYW5mb3JkIiwiYSI6InRJMHZPZFUifQ.F4DMGoNgU3r2AWLY0Eni-w';

var map = new L.mapbox.Map('map-container', 'jcsanford.j25ef8lg', {zoomControl: false});

var current_marker, markers;

function getLocation(type) {
  var loc, url, callback;

  var buttons = document.querySelectorAll('.button');
  buttons.forEach(function (elem) {
    var time = elem.getAttribute('data-time');
    if (time === type) {
      elem.classList.add('active');
    } else {
      elem.classList.remove('active');
    }
  });

  if (current_marker) {
    map.removeLayer(current_marker);
  }
  if (markers) {
    map.removeLayer(markers);
  }

  switch (type) {
    case 'current':
      url = 'current.geojson';
      callback = function(geojson) {
        loc = [geojson.geometry.coordinates[1], geojson.geometry.coordinates[0]];
        if (current_marker) {
          current_marker.setLatLng(loc);
        } else {
          current_marker = L.userMarker(loc, {pulsing: true, accuracy: geojson.properties.accuracy, smallIcon: true});
        }
        current_marker.addTo(map);
        map.setView(loc, 12);
      };
      break;
    case 'day':
    case 'month':
      callback = function(geojson) {
        function addGeoJSON(geojson) {
          var i, len, feature;
          for (i = 0, len = geojson.features.length; i < len; i++) {
            feature = geojson.features[i];
            markers.addLayer(
              L.circleMarker([feature.geometry.coordinates[1], feature.geometry.coordinates[0]], {
                radius: 5,
                fillColor: "#ff7800",
                color: "#000",
                weight: 1,
                opacity: 1,
                fillOpacity: 0.8
              })
            );
          }
        }
        if (markers) {
          markers.clearLayers();
          addGeoJSON(geojson);
        } else {
          markers = L.markerClusterGroup({
            showCoverageOnHover: false,
            disableClusteringAtZoom: 14,
            maxClusterRadius: 40
          });
          addGeoJSON(geojson);
        }
        map.fitBounds(markers.getBounds());
        markers.addTo(map);
      };
      url = type + '.geojson';
      break;
    default:
      return;
  }
  reqwest({
    url: url,
    type: 'json',
    success: callback
  });
}

document.querySelectorAll('.button').forEach(function(elem){
  elem.onclick = buttonClick;
});

function buttonClick(event) {
  event.preventDefault();
  var time = event.target.getAttribute('data-time');
  getLocation(time);
}

getLocation('current');