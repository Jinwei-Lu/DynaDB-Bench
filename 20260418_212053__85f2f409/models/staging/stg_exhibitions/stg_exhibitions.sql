CREATE OR REPLACE VIEW "stg_exhibitions" AS
SELECT
  "Exhibition_Catalog_Code",
  "ExhibitionTitle",
  "start_date",
  "END_DATE",
  "curator_in_charge_stafftag",
  "location_in_hall",
  "BUDGET_USD",
  "actual_cost",
  "IS_TRAVELING",
  ("attendance_figures" ->> 'ACTUAL_VISITORS')::NUMERIC AS actual_visitors,
  ("attendance_figures" ->> 'expected_attendance')::NUMERIC AS expected_attendance
FROM "Exhibitions"
WHERE "EXHIBITION_STATUS" = 'Archived'
  AND "BUDGET_USD" > 0;