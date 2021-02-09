CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.find_points_around_from_geojson`(geojson STRING, startx FLOAT64, starty FLOAT64, max_cost FLOAT64) 
RETURNS STRING LANGUAGE js
OPTIONS (
  library=["$BUCKET_FILE_PATH"]
)
AS """
  const start = {type: "Feature", geometry: { coordinates: [startx, starty], type: "Point" }};
  const pathFinder = new geojsonPathFinder.PathFinder(JSON.parse(geojson));

  return new Promise((resolve, reject) => {
    const nodes = pathFinder.findPointsAround(start, max_cost);
    const nodesJson = JSON.stringify({
      type: "MultiPoint",
      coordinates: nodes
    });
    resolve(nodesJson);
  });
""";

-- get the concave hull
CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.get_isodistance_concave_hull_from_geojson`(geojson STRING, startx FLOAT64, starty FLOAT64, max_cost FLOAT64) 
RETURNS STRING LANGUAGE js
OPTIONS (
  library=["$BUCKET_FILE_PATH"]
)
AS """
  const start = {type: "Feature", geometry: { coordinates: [startx, starty], type: "Point" }};
  const pathFinder = new geojsonPathFinder.PathFinder(JSON.parse(geojson));

  return new Promise((resolve, reject) => {
    const hull = pathFinder.getIsoDistanceConcaveHull(start, max_cost);
    const geometry = JSON.stringify(hull.geometry);
    resolve(geometry);
  });
""";

-- get the convex hull
-- CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.get_isodistance_convex_hull_from_geojson`(geojson STRING, startx FLOAT64, starty FLOAT64, max_cost FLOAT64) 
-- RETURNS STRING LANGUAGE js
-- OPTIONS (
--   library=["$BUCKET_FILE_PATH"]
-- )
-- AS """
--   const start = {type: "Feature", geometry: { coordinates: [startx, starty], type: "Point" }};
--   const pathFinder = new geojsonPathFinder.PathFinder(JSON.parse(geojson));

--   const hull = pathFinder.getIsoDistanceConvexHull(start, max_cost);
  
--   try {
--     return JSON.stringify(hull.geometry);
--   } catch (e) {
--     return(null);
--   }
-- """;

-- get isochrone the concave hull
CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.get_isochrone_concave_hull_from_geojson`(geojson STRING, startx FLOAT64, starty FLOAT64, max_cost FLOAT64) 
RETURNS STRING LANGUAGE js
OPTIONS (
  library=["$BUCKET_FILE_PATH"]
)
AS """
  const start = {type: "Feature", geometry: { coordinates: [startx, starty], type: "Point" }};
  const pathFinder = new geojsonPathFinder.PathFinder(JSON.parse(geojson), { weightFn: geojsonPathFinder.WeightFunctions.travelTimeWeightFn });

  return new Promise((resolve, reject) => {
    const hull = pathFinder.getIsoDistanceConcaveHull(start, max_cost);
    const geometry = JSON.stringify(hull.geometry);
    resolve(geometry);
  });
""";

-- get isochrone the convex hull
-- CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.get_isochrone_convex_hull_from_geojson`(geojson STRING, startx FLOAT64, starty FLOAT64, max_cost FLOAT64) 
-- RETURNS STRING LANGUAGE js
-- OPTIONS (
--   library=["$BUCKET_FILE_PATH"]
-- )
-- AS """
--   const start = {type: "Feature", geometry: { coordinates: [startx, starty], type: "Point" }};
--   const pathFinder = new geojsonPathFinder.PathFinder(JSON.parse(geojson));

--   const hull = pathFinder.getIsoDistanceConvexHull(start, max_cost);
  
--   try {
--     return JSON.stringify(hull.geometry);
--   } catch (e) {
--     return(null);
--   }
-- """;

-- helper to find the nearest point if the input point is not in the dataset
CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.find_nearest_point`(mypoint GEOGRAPHY, mypoints array<GEOGRAPHY>) AS ((
  WITH EXTRACTED_POINTS AS (
    SELECT SAFE.ST_GEOGFROMTEXT(CONCAT('POINT(', point, ')')) mypoints
    FROM unnest(mypoints) geo_object,
      UNNEST(REGEXP_EXTRACT_ALL(ST_ASTEXT(geo_object), r'[^,\(\)]+')) point WITH OFFSET pos
    WHERE pos BETWEEN 1 AND ST_NUMPOINTS(geo_object)
  )
  SELECT ARRAY_AGG(a.mypoints ORDER BY ST_Distance(a.mypoints, mypoint) LIMIT 1)[ORDINAL(1)] as neighbor_id
  FROM EXTRACTED_POINTS a
));

-- wrapper for GEOGRAPHY to GEOJSON
CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.find_points_around`(lines array<GEOGRAPHY>, start GEOGRAPHY, max_cost FLOAT64) AS ((
  WITH SOME_NETWORK AS (
    SELECT concat('{"type": "FeatureCollection", "features": [{"type": "Feature","geometry":', string_agg(ST_ASGEOJSON(line), '},{"type":"Feature","geometry":'), "}]}") geojson,
    `$PROJECT_ID.$DATASET.find_nearest_point`(start, array_agg(line)) start_nearest,
    FROM unnest(lines) line
  ),
  OUTPUT AS (
    SELECT `$PROJECT_ID.$DATASET.find_points_around_from_geojson`(geojson, ST_X(start_nearest), ST_Y(start_nearest), max_cost) myresult
    FROM SOME_NETWORK
  )

  SELECT * FROM OUTPUT
));

-- wrapper for GEOGRAPHY to GEOJSON
CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.get_isodistance_concave_hull`(lines array<GEOGRAPHY>, start GEOGRAPHY, max_cost FLOAT64) AS ((
  WITH SOME_NETWORK AS (
    SELECT concat('{"type": "FeatureCollection", "features": [{"type": "Feature","geometry":', string_agg(ST_ASGEOJSON(line), '},{"type":"Feature","geometry":'), "}]}") geojson,
    `$PROJECT_ID.$DATASET.find_nearest_point`(start, array_agg(line)) start_nearest,
    FROM unnest(lines) line
  ),
  OUTPUT AS (
    SELECT `$PROJECT_ID.$DATASET.get_isodistance_concave_hull_from_geojson`(geojson, ST_X(start_nearest), ST_Y(start_nearest), max_cost) myresult
    FROM SOME_NETWORK
  )

  SELECT * FROM OUTPUT
));


-- wrapper for GEOGRAPHY to GEOJSON
CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.get_isochrone_concave_hull`(lines array<GEOGRAPHY>, start GEOGRAPHY, max_cost FLOAT64) AS ((
  WITH SOME_NETWORK AS (
    SELECT CONCAT('{"type": "FeatureCollection", "features": [{"type": "Feature", "geometry":', string_agg(ST_ASGEOJSON(line), '}, {"type":"Feature","geometry":'), "}]}") geojson,
    `$PROJECT_ID.$DATASET.find_nearest_point`(start, array_agg(line)) start_nearest,
    FROM UNNEST(lines) line
  ),
  OUTPUT AS (
    SELECT `$PROJECT_ID.$DATASET.get_isochrone_concave_hull_from_geojson`(geojson, ST_X(start_nearest), ST_Y(start_nearest), max_cost) myresult
    FROM SOME_NETWORK
  )

  SELECT * FROM OUTPUT
));

-- wrapper for GEOGRAPHY to GEOJSON
-- CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.get_isodistance_convex_hull`(lines array<GEOGRAPHY>, start GEOGRAPHY, max_cost FLOAT64) AS ((
--   WITH SOME_NETWORK AS (
--     SELECT concat('{"type": "FeatureCollection", "features": [{"type": "Feature","geometry":', string_agg(ST_ASGEOJSON(line), '},{"type":"Feature","geometry":'), "}]}") geojson,
--     `$PROJECT_ID.$DATASET.find_nearest_point`(start, array_agg(line)) start_nearest,
--     FROM unnest(lines) line
--   ),
--   OUTPUT AS (
--     SELECT `$PROJECT_ID.$DATASET.get_isodistance_convex_hull_from_geojson`(geojson, ST_X(start_nearest), ST_Y(start_nearest), max_cost) myresult
--     FROM SOME_NETWORK
--   )

--   SELECT * FROM OUTPUT
-- ));

CREATE OR REPLACE FUNCTION `$PROJECT_ID.$DATASET.get_isodistance_convex_hull`(lines array<GEOGRAPHY>, start GEOGRAPHY, max_cost FLOAT64) AS ((
  SELECT ST_CONVEXHULL(ST_GEOGFROMGEOJSON(`$PROJECT_ID.$DATASET.find_points_around`(lines, start, max_cost)))
));

