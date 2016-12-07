-- Engineering geographic features
-- Assumes that the initial_joins have been completed and that "parcel_new" has
-- been read in to the project schema

-- Joining in location data and buffers
DROP TABLE IF EXISTS project.geo_residential CASCADE;
CREATE TABLE project.geo_residential AS
SELECT
res.*,
geo.addr_full,
geo.gid,
geo.point_x,
geo.point_y,
geo.shape_area,
geo.shape_len,
geo.geom,
ST_Buffer(geo.geom, 1000) as buffer_1000,  -- Eliminating 100 buffer--too small
ST_Buffer(geo.geom, 5000) AS buffer_5000,
ST_Buffer(geo.geom, 20000) as buffer_20000
FROM project.parcel_new AS res
JOIN gis.parcel_address AS geo
ON geo.pin = res.pin;
LIMIT 50000;  -- Limiting number of rows for testing FIX ME!
/*ALTER TABLE project.geo_residential ADD gid INTEGER UNIQUE;*/

-- Update all "extra_info" tables to include a geom column and move them into the project schema
-- SEE sql_generator notebook for how these queries were made

-- Copypasta below
DROP TABLE IF EXISTS project."pub_school" CASCADE;
CREATE TABLE project."pub_school" AS
    SELECT
    "Public_Schools"."long" AS long,
    "Public_Schools"."lat" AS lat,
    ST_Transform(ST_SetSRID(ST_MakePoint("Public_Schools"."long", "Public_Schools"."lat"), 4326), 2926) AS geom
FROM extra_info."Public_Schools";
ALTER TABLE project."pub_school" ADD gid INTEGER UNIQUE;

DROP TABLE IF EXISTS project."priv_school" CASCADE;
CREATE TABLE project."priv_school" AS
    SELECT
    "Private_Schools"."long" AS long,
    "Private_Schools"."lat" AS lat,
    ST_Transform(ST_SetSRID(ST_MakePoint("Private_Schools"."long", "Private_Schools"."lat"), 4326), 2926) AS geom
FROM extra_info."Private_Schools";
ALTER TABLE project."priv_school" ADD gid INTEGER UNIQUE;

DROP TABLE IF EXISTS project."landmarks" CASCADE;
CREATE TABLE project."landmarks" AS
    SELECT
    "Landmarks"."long" AS long,
    "Landmarks"."lat" AS lat,
    ST_Transform(ST_SetSRID(ST_MakePoint("Landmarks"."long", "Landmarks"."lat"), 4326), 2926) AS geom
FROM extra_info."Landmarks";
ALTER TABLE project."landmarks" ADD gid INTEGER UNIQUE;

DROP TABLE IF EXISTS project."light_rail" CASCADE;
CREATE TABLE project."light_rail" AS
    SELECT
    "Light_Rail_Map"."Longitude" AS long,
    "Light_Rail_Map"."Latitude" AS lat,
    ST_Transform(ST_SetSRID(ST_MakePoint("Light_Rail_Map"."Longitude", "Light_Rail_Map"."Latitude"), 4326), 2926) AS geom
FROM extra_info."Light_Rail_Map";
ALTER TABLE project."light_rail" ADD gid INTEGER UNIQUE;

DROP TABLE IF EXISTS project."parks" CASCADE;
CREATE TABLE project."parks" AS
    SELECT
    "Parks_Map"."Longitude" AS long,
    "Parks_Map"."Latitude" AS lat,
    ST_Transform(ST_SetSRID(ST_MakePoint("Parks_Map"."Longitude", "Parks_Map"."Latitude"), 4326), 2926) AS geom
FROM extra_info."Parks_Map";
ALTER TABLE project."parks" ADD gid INTEGER UNIQUE;


SELECT count(*) from project.light_rail;

-- The SRID for the extra_info tables is 4326. They didn't provide it in the data. I had to figure it out from trial and error.


-- Joining together all of the spatial data counts
-- SEE sql_generator notebook for how these queries were made

-- Copypasta below
DROP MATERIALIZED VIEW IF EXISTS project."pub_school_counts";
CREATE MATERIALIZED VIEW project."pub_school_counts" AS
SELECT
everyone.ping AS pin,
everyone."count_100" AS "pub_school_counts100",
everyone."count_1000" AS "pub_school_counts1000",
everyone."count_20000" AS "pub_school_counts20000"
FROM (
(
    SELECT
    res.pin AS ping,
    count(ei.geom) AS "count_20000"
    FROM project.geo_residential AS res LEFT JOIN project."pub_school" AS ei
    ON ST_Intersects(ei.geom, res."buffer_20000")
    GROUP BY res.pin
) AS big LEFT JOIN
(
    SELECT
    res.pin,
    count(ei.geom) AS "count_1000"
    FROM project.geo_residential AS res LEFT JOIN project."pub_school" AS ei
    ON ST_Intersects(ei.geom, res."buffer_1000")
    GROUP BY res.pin
) AS middle ON big.ping = middle.pin LEFT JOIN
(
    SELECT
    res.pin,
    count(ei.geom) AS "count_100"
    FROM project.geo_residential AS res LEFT JOIN project."pub_school" AS ei
    ON ST_Intersects(ei.geom, res."buffer_100")
    GROUP BY res.pin
) AS little ON big.ping = little.pin
) AS everyone;

DROP MATERIALIZED VIEW IF EXISTS project."priv_school_counts";
CREATE MATERIALIZED VIEW project."priv_school_counts" AS
SELECT
everyone.ping AS pin,
everyone."count_100" AS "priv_school_counts100",
everyone."count_1000" AS "priv_school_counts1000",
everyone."count_20000" AS "priv_school_counts20000"
FROM (
(
    SELECT
    res.pin AS ping,
    count(ei.geom) AS "count_20000"
    FROM project.geo_residential AS res LEFT JOIN project."priv_school" AS ei
    ON ST_Intersects(ei.geom, res."buffer_20000")
    GROUP BY res.pin
) AS big LEFT JOIN
(
    SELECT
    res.pin,
    count(ei.geom) AS "count_1000"
    FROM project.geo_residential AS res LEFT JOIN project."priv_school" AS ei
    ON ST_Intersects(ei.geom, res."buffer_1000")
    GROUP BY res.pin
) AS middle ON big.ping = middle.pin LEFT JOIN
(
    SELECT
    res.pin,
    count(ei.geom) AS "count_100"
    FROM project.geo_residential AS res LEFT JOIN project."priv_school" AS ei
    ON ST_Intersects(ei.geom, res."buffer_100")
    GROUP BY res.pin
) AS little ON big.ping = little.pin
) AS everyone;

DROP MATERIALIZED VIEW IF EXISTS project."landmarks_counts";
CREATE MATERIALIZED VIEW project."landmarks_counts" AS
SELECT
everyone.ping AS pin,
everyone."count_100" AS "landmarks_counts100",
everyone."count_1000" AS "landmarks_counts1000",
everyone."count_20000" AS "landmarks_counts20000"
FROM (
(
    SELECT
    res.pin AS ping,
    count(ei.geom) AS "count_20000"
    FROM project.geo_residential AS res LEFT JOIN project."landmarks" AS ei
    ON ST_Intersects(ei.geom, res."buffer_20000")
    GROUP BY res.pin
) AS big LEFT JOIN
(
    SELECT
    res.pin,
    count(ei.geom) AS "count_1000"
    FROM project.geo_residential AS res LEFT JOIN project."landmarks" AS ei
    ON ST_Intersects(ei.geom, res."buffer_1000")
    GROUP BY res.pin
) AS middle ON big.ping = middle.pin LEFT JOIN
(
    SELECT
    res.pin,
    count(ei.geom) AS "count_100"
    FROM project.geo_residential AS res LEFT JOIN project."landmarks" AS ei
    ON ST_Intersects(ei.geom, res."buffer_100")
    GROUP BY res.pin
) AS little ON big.ping = little.pin
) AS everyone;

DROP MATERIALIZED VIEW IF EXISTS project."light_rail_counts";
CREATE MATERIALIZED VIEW project."light_rail_counts" AS
SELECT
everyone.ping AS pin,
everyone."count_100" AS "light_rail_counts100",
everyone."count_1000" AS "light_rail_counts1000",
everyone."count_20000" AS "light_rail_counts20000"
FROM (
(
    SELECT
    res.pin AS ping,
    count(ei.geom) AS "count_20000"
    FROM project.geo_residential AS res LEFT JOIN project."light_rail" AS ei
    ON ST_Intersects(ei.geom, res."buffer_20000")
    GROUP BY res.pin
) AS big LEFT JOIN
(
    SELECT
    res.pin,
    count(ei.geom) AS "count_1000"
    FROM project.geo_residential AS res LEFT JOIN project."light_rail" AS ei
    ON ST_Intersects(ei.geom, res."buffer_1000")
    GROUP BY res.pin
) AS middle ON big.ping = middle.pin LEFT JOIN
(
    SELECT
    res.pin,
    count(ei.geom) AS "count_100"
    FROM project.geo_residential AS res LEFT JOIN project."light_rail" AS ei
    ON ST_Intersects(ei.geom, res."buffer_100")
    GROUP BY res.pin
) AS little ON big.ping = little.pin
) AS everyone;

DROP MATERIALIZED VIEW IF EXISTS project."parks_counts";
CREATE MATERIALIZED VIEW project."parks_counts" AS
SELECT
everyone.ping AS pin,
everyone."count_100" AS "parks_counts100",
everyone."count_1000" AS "parks_counts1000",
everyone."count_20000" AS "parks_counts20000"
FROM (
(
    SELECT
    res.pin AS ping,
    count(ei.geom) AS "count_20000"
    FROM project.geo_residential AS res LEFT JOIN project."parks" AS ei
    ON ST_Intersects(ei.geom, res."buffer_20000")
    GROUP BY res.pin
) AS big LEFT JOIN
(
    SELECT
    res.pin,
    count(ei.geom) AS "count_1000"
    FROM project.geo_residential AS res LEFT JOIN project."parks" AS ei
    ON ST_Intersects(ei.geom, res."buffer_1000")
    GROUP BY res.pin
) AS middle ON big.ping = middle.pin LEFT JOIN
(
    SELECT
    res.pin,
    count(ei.geom) AS "count_100"
    FROM project.geo_residential AS res LEFT JOIN project."parks" AS ei
    ON ST_Intersects(ei.geom, res."buffer_100")
    GROUP BY res.pin
) AS little ON big.ping = little.pin
) AS everyone;

-- Finally join them all into the geo_residential table on
DROP MATERIALIZED VIEW IF EXISTS project.complete_residential;
CREATE MATERIALIZED VIEW project.complete_residential AS
SELECT
geo_res."Major",
geo_res."Minor",
geo_res."PropType",
geo_res."Area",
geo_res."DistrictName",
geo_res."ParcSqFtLot",
geo_res."CurrentZoning",
geo_res."Topography",
geo_res."StreetSurface",
geo_res."InadequateParking",
geo_res."PcntUnusable",
geo_res."MtRainier",
geo_res."Olympics",
geo_res."Cascades",
geo_res."SeattleSkyline",
geo_res."PugetSound",
geo_res."LakeWashington",
geo_res."LakeSammamish",
geo_res."LotDepthFactor",
geo_res."TrafficNoise",
geo_res."AirportNoise",
geo_res."PowerLines",
geo_res."HistoricSite",
geo_res."SteepSlopeHazard",
geo_res."WaterProblems",
geo_res."SqFtTotLiving",
geo_res."no_stories",
geo_res."bath_count",
geo_res."bedroom_count",
geo_res."year_built",
geo_res."year_renovated",
geo_res."heat_system",
geo_res."brick_stone",
geo_res."sq_ft_upper_floor",
geo_res."sale_date",
geo_res."sale_price",
geo_res."sale_reason",
geo_res."appr_land_val",
geo_res."appr_imprv_val",
geo_res."appr_tot_val",
geo_res."appr_date",
geo_res."major_str",
geo_res."minor_str",
geo_res."pin",
geo_res."addr_full",
parc_add.lat,
parc_add.lon,
ei1."landmarks_counts100",
ei1."landmarks_counts1000",
ei1."landmarks_counts20000",
ei2."light_rail_counts100",
ei2."light_rail_counts1000",
ei2."light_rail_counts20000",
ei3."parks_counts100",
ei3."parks_counts1000",
ei3."parks_counts20000",
ei4."priv_school_counts100",
ei4."priv_school_counts1000",
ei4."priv_school_counts20000",
ei5."pub_school_counts100",
ei5."pub_school_counts1000",
ei5."pub_school_counts20000"
FROM project.geo_residential AS geo_res
LEFT JOIN gis.parcel_address AS parc_add
ON geo_res.pin = parc_add.pin
LEFT JOIN project.landmarks_counts AS ei1
ON geo_res.pin = ei1.pin
LEFT JOIN project.light_rail_counts AS ei2
ON geo_res.pin = ei2.pin
LEFT JOIN project.parks_counts AS ei3
ON geo_res.pin = ei3.pin
LEFT JOIN project.priv_school_counts AS ei4
ON geo_res.pin = ei4.pin
LEFT JOIN project.pub_school_counts AS ei5
ON geo_res.pin = ei5.pin;
