L.mapbox.accessToken = 'pk.eyJ1IjoiamNzYW5mb3JkIiwiYSI6InRJMHZPZFUifQ.F4DMGoNgU3r2AWLY0Eni-w';

var map = new L.mapbox.Map('map-container', 'jcsanford.j25ef8lg');

var loc = [40, -85];

var marker = L.userMarker(loc, {pulsing: true, accuracy: 400, smallIcon: true});
map.setView(loc, 10);
marker.addTo(map);