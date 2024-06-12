ALTER TABLE excel_raw
ALTER COLUMN "Row" SET DATA TYPE bigint USING "Row"::bigint;

ALTER TABLE excel_raw
ALTER COLUMN "Column" SET DATA TYPE bigint USING "Column"::bigint;

ALTER TABLE excel_raw
ALTER COLUMN "Cell1 Whole - Number of EIF3 Spots Cyto Selected- per cell  - Mean per Well" 
SET DATA TYPE float USING "Cell1 Whole - Number of EIF3 Spots Cyto Selected- per cell  - Mean per Well" ::float;

ALTER TABLE excel_raw
ALTER COLUMN "Cell1 Whole - Number of G3BP1 Spots Cyto Selected- per Cell  - Mean per Well" 
SET DATA TYPE float USING "Cell1 Whole - Number of G3BP1 Spots Cyto Selected- per Cell  - Mean per Well" ::float;


ALTER TABLE excel_raw
ALTER COLUMN "Cell1 Whole - Number of FUS GFP Spots Cyto Selected- per Cell  - Mean per Well" 
SET DATA TYPE float USING "Cell1 Whole - Number of FUS GFP Spots Cyto Selected- per Cell  - Mean per Well" ::float;



ALTER TABLE xml_raw
ALTER COLUMN "Row" SET DATA TYPE bigint USING "Row"::bigint;

ALTER TABLE xml_raw
ALTER COLUMN "col" SET DATA TYPE bigint USING "col"::bigint;

ALTER TABLE xml_raw
ALTER COLUMN "concentration" SET DATA TYPE float USING "concentration"::float;


ALTER TABLE excel_raw
RENAME COLUMN "Cell1 Whole - Number of EIF3 Spots Cyto Selected- per cell  - Mean per Well" TO eif3_spots_for_mean;

ALTER TABLE excel_raw
RENAME COLUMN "Cell1 Whole - Number of G3BP1 Spots Cyto Selected- per Cell  - Mean per Well" TO g3bp1_spots_for_mean;


ALTER TABLE excel_raw
RENAME COLUMN "Cell1 Whole - Number of FUS GFP Spots Cyto Selected- per Cell  - Mean per Well" TO fus_gfp_spots_for_mean;



CREATE TABLE data_mart AS
WITH control_values AS (
    SELECT
       excel_raw.platename,
        AVG(CASE WHEN compound = 'n' THEN eif3_spots_for_mean END) AS avg_neg_eif3,
        AVG(CASE WHEN compound = 'p' THEN eif3_spots_for_mean END) AS avg_pos_eif3,
        AVG(CASE WHEN compound = 'n' THEN g3bp1_spots_for_mean END) AS avg_neg_g3bp1,
        AVG(CASE WHEN compound = 'p' THEN g3bp1_spots_for_mean END) AS avg_pos_g3bp1,
        AVG(CASE WHEN compound = 'n' THEN fus_gfp_spots_for_mean END) AS avg_neg_fus,
        AVG(CASE WHEN compound = 'p' THEN fus_gfp_spots_for_mean END) AS avg_pos_fus
    FROM xml_raw
	JOIN excel_raw
	ON xml_raw.platename = excel_raw.platename
	AND xml_raw."Row" = excel_raw."Row"
	AND xml_raw."col"  = excel_raw."Column"
	GROUP BY excel_raw.platename
	
)
SELECT
    xml_raw.platename,
    xml_raw.compound,
    xml_raw.concentration,
    excel_raw.eif3_spots_for_mean,
    excel_raw.g3bp1_spots_for_mean,
    excel_raw.fus_gfp_spots_for_mean,
    100 * (excel_raw.eif3_spots_for_mean - ctrl.avg_neg_eif3) / (ctrl.avg_pos_eif3 - ctrl.avg_neg_eif3) AS eif3_percent_inhibition,
    100 * (excel_raw.g3bp1_spots_for_mean - ctrl.avg_neg_g3bp1) / (ctrl.avg_pos_g3bp1 - ctrl.avg_neg_g3bp1) AS g3bp1_percent_inhibition,
    100 * (excel_raw.fus_gfp_spots_for_mean - ctrl.avg_neg_fus) / (ctrl.avg_pos_fus - ctrl.avg_neg_fus) AS fus_percent_inhibition
FROM xml_raw
JOIN excel_raw
    ON xml_raw.platename = excel_raw.platename
    AND xml_raw."Row" = excel_raw."Row"
    AND xml_raw."col" = excel_raw."Column"
JOIN control_values ctrl
    ON excel_raw.platename = ctrl.platename
WHERE xml_raw.compound IS NOT NULL
    AND xml_raw.compound NOT IN ('n', 'p')
    AND xml_raw.concentration > 0
ORDER BY xml_raw."Row", xml_raw."col";

select * from data_mart;




