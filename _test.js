const GeoJsonPathFinder = require('../index.js'),
      geojson = require('./gothenburg.json'),
      point = require('turf-point'),
      distance = require('@turf/distance').default;

const highwaySpeeds = {
    motorway: 110,
    trunk: 90,
    primary: 80,
    secondary: 70,
    tertiary: 50,
    unclassified: 50,
    road: 50,
    residential: 30,
    service: 30,
    living_street: 20
};

const unknowns = {};
const PathFinder = GeoJsonPathFinder.PathFinder;
const WeightFunctions = GeoJsonPathFinder.WeightFunctions;


function weightFn(a, b, props) {
    let d = distance(point(a), point(b)) * 1000,
        factor = 0.9,
        type = props.highway,
        forwardSpeed,
        backwardSpeed;

    if (props.maxspeed) {
        forwardSpeed = backwardSpeed = Number(props.maxspeed);
    } else {
        let linkIndex = type.indexOf('_link');

        if (linkIndex >= 0) {
            type = type.substring(0, linkIndex);
            factor *= 0.7;
        }
    
        forwardSpeed = backwardSpeed = highwaySpeeds[type] * factor;
    
        if (!forwardSpeed) {
            unknowns[type] = true;
        }
    }
    
    if (props.oneway && props.oneway !== 'no' || props.junction && props.junction === 'roundabout') {
        backwardSpeed = null;
    }

    return {
        forward: forwardSpeed && (d / (forwardSpeed / 3.6)),
        backward: backwardSpeed && (d / (backwardSpeed / 3.6)),
    };
}

 const pathFinder = new PathFinder(geojson, { weightFn: weightFn });
 const points = pathFinder.getIsoDistanceConcaveHull(point([11.9670375, 57.7035236]), 100);
