-- Alter appraisal history table to only have the most recent appraised value
-- Possible TODO / FIXME: use historical assessed values also
DROP MATERIALIZED VIEW IF EXISTS project.appr_hist CASCADE;
CREATE MATERIALIZED VIEW project.appr_hist AS
SELECT * FROM assessor_data."RealPropApplHist_V" AS T1
WHERE NOT EXISTS (
    SELECT *
    FROM assessor_data."RealPropApplHist_V" AS T2
    WHERE T2."Major" = T1."Major" AND T2."Minor" = T1."Minor" AND T2."UpdateDate" > T1."UpdateDate"
)


-- Start with a base table that is filtered to residential only properties
DROP MATERIALIZED VIEW IF EXISTS project.residential;
CREATE MATERIALIZED VIEW project.residential AS
SELECT
parc."Major",
parc."Minor",
parc."PropType",
parc."Area",
parc."DistrictName",
parc."SqFtLot" AS "ParcSqFtLot",
parc."CurrentZoning",
parc."Topography",
parc."StreetSurface",
parc."InadequateParking",
parc."PcntUnusable",
parc."MtRainier",
parc."Olympics",
parc."Cascades",
parc."SeattleSkyline",
parc."PugetSound",
parc."LakeWashington",
parc."LakeSammamish",
parc."LotDepthFactor",
parc."TrafficNoise",
parc."AirportNoise",
parc."PowerLines",
parc."HistoricSite",
parc."SteepSlopeHazard",
parc."WaterProblems",
rb."SqFtTotLiving",
rb."Stories" AS no_stories,
rb."BathFullCount" AS bath_count,
rb."Bedrooms" AS bedroom_count,
rb."YrBuilt" AS year_built,
rb."YrRenovated" AS year_renovated,
rb."HeatSystem" AS heat_system,
rb."BrickStone" AS brick_stone,
rb."SqFtUpperFloor" AS sq_ft_upper_floor,
rpsale."DocumentDate" AS sale_date,
rpsale."SalePrice" AS sale_price,
rpsale."SaleReason" AS sale_reason,
appr_hist."UpdateDate" AS appr_date,
appr_hist."LandVal" AS appr_land_val,
appr_hist."ImpsVal" AS appr_imprv_val,
appr_hist."LandVal" + appr_hist."ImpsVal" as appr_tot_val
FROM assessor_data."Parcel" as parc
JOIN assessor_data."ResBldg" AS rb
ON parc."Major" = rb."Major" AND parc."Minor" = rb."Minor"
JOIN assessor_data."RPSale" AS rpsale
ON parc."Major" = rpsale."Major" AND parc."Minor" = rpsale."Minor"
JOIN project.appr_hist AS appr_hist
ON parc."Major" = appr_hist."Major" AND parc."Minor" = appr_hist."Minor"
WHERE parc."PropType" = 'R';
-- From table above, created new CHAR columns for pins

-- ========================================
-- READ IN "parcel_new" table from pandas HERE!
-- Then go to feature_development.sql file
-- ========================================
