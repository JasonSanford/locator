var reqwest = require('reqwest');

NodeList.prototype.forEach        = Array.prototype.forEach;
HTMLCollection.prototype.forEach  = Array.prototype.forEach;
DOMTokenList.prototype.forEach    = Array.prototype.forEach;

L.mapbox.accessToken = 'pk.eyJ1IjoiamNzYW5mb3JkIiwiYSI6InRJMHZPZFUifQ.F4DMGoNgU3r2AWLY0Eni-w';

var map = new L.mapbox.Map('map-container', 'jcsanford.j25ef8lg', {zoomControl: false});

var current_marker, span_points;

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
  if (span_points) {
    map.removeLayer(span_points);
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
        if (span_points) {
          span_points.clearLayers();
          span_points.addData(geojson);
        } else {
          span_points = L.geoJson(geojson);
        }
        span_points.addTo(map);
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