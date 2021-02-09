var { PathFinder, weightFunctions } = require('../'),
    geojson = require('./gothenburg.json'),
    test = require('tap').test,
    point = require('turf-point'),
    distance = require('@turf/distance').default;



test('can find points around', function(t) {
  var network = {
    type: 'FeatureCollection',
    features: [
      {
        "type": "Feature",
        "id": "way/4040439",
        "properties": {
          "@id": "way/4040439",
          "destination": "Stockholm",
          "highway": "motorway",
          "int_ref": "E 20",
          "lanes": "1",
          "maxspeed": "70",
          "oneway": "yes",
          "ref": "E 20"
        },
        "geometry": {
          "type": "LineString",
          "coordinates": [
            [11.9954516, 57.7125743],
            [11.9951772, 57.7126966],
            [11.9949331, 57.7128759],
            [11.9947498, 57.7130504],
            [11.9946059, 57.7132345],
            [11.9945035, 57.7133906],
            [11.9943956, 57.713617],
            [11.9943423, 57.7137643],
            [11.9941813, 57.7143737],
            [11.9941731, 57.7145507],
            [11.9941817, 57.7147226],
            [11.9942333, 57.7149052],
            [11.9943042, 57.7150519],
            [11.9944625, 57.7152119],
            [11.994582, 57.7153329],
            [11.9947089, 57.7154192],
            [11.9948565, 57.7155021],
            [11.9953, 57.715754],
            [11.9954849, 57.7158702],
            [11.9956848, 57.7159575]
          ]
        }
      },
      {
        "type": "Feature",
        "id": "way/4040441",
        "properties": {
          "@id": "way/4040441",
          "bus:lanes": "||designated",
          "highway": "motorway",
          "int_ref": "E 20",
          "lanes": "3",
          "oneway": "yes",
          "ref": "E 20"
        },
        "geometry": {
          "type": "LineString",
          "coordinates": [
            [12.0035028, 57.7211424],
            [12.0026194, 57.7205026]
          ]
        }
      },
    ]
  };

  var start = {
    type: "Feature", 
    geometry: {
      type: "Point",
      coordinates: [11.9956848, 57.7159575], 
    }
  }

  var pathfinder = new PathFinder(geojson),
  points = pathfinder.findPointsAround(start, 0.05);

  t.ok(points);
  t.type(points, Array);
  t.equal(points.length, 5, 'found 5 points');
  t.end();
});

test('can find isochrone', function(t) {
  var start = {
    type: "Feature", 
    geometry: {
      type: "Point",
      coordinates: [11.9956848, 57.7159575], 
    }
  }

  var pathfinder = new PathFinder(geojson),
  hull = pathfinder.getIsoDistanceConcaveHull(start, 3);

  t.ok(hull);
  t.type(hull, Object);
  t.equal(hull.type, 'Feature');
  t.equal(hull.geometry.type, 'Polygon');
  t.end();
});

test('can\'t find isochrone', function(t) {
  var network = {
      type: 'FeatureCollection',
      features: [
          {
              type: 'Feature',
              geometry: {
                  type: 'LineString',
                  coordinates: [[0, 0], [1, 0]]
              }
          },
          {
              type: 'Feature',
              geometry: {
                  type: 'LineString',
                  coordinates: [[1, 0], [1, 1]]
              }
          }
      ]
  };

  var start = {
    type: "Feature", 
    geometry: {
      type: "Point",
      coordinates: [0, 0], 
    }
  }

  var pathfinder = new PathFinder(network),
  hull = pathfinder.getIsoDistanceConcaveHull(start, 3);
  t.equal(hull, null);
  t.end();
});