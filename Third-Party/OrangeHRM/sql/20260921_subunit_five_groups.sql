-- =============================================================================
-- OrangeHRM: remove Organization root; five top-level groups; keep leaves
-- =============================================================================
-- Target (forest of five roots; current leaves stay leaves):
--
--   Corporate Services
--     Executive Management, Finance, Accounting, Human Resources
--   Technology
--     Engineering, Information Technology
--   Operations
--     Inventory, Regional Operations, Asset Management
--   Commercial
--     Sales, Call Center
--   Healthcare
--     Nursing, Doctors, Students, Nursing-ER, Nursing-NICU, Radiology
--
-- Assumptions
--   ohrm_subunit columns: id, name, unit_id, description, lft, rgt, level
--   Older OrangeHRM builds may lack `level`; confirm with the preflight SELECT.
--   Matching is by `name`. Review the UPDATE if any unit was renamed or duplicated.
--
-- Why levels start at 1, not 0
--   EmployeeJobController feeds the Sub Unit dropdown from Subunit::fetchTree()
--   through SubunitModel, which serializes the `level` column as the option's
--   `_indent`. The widget treats `_indent` 1 as flush left, so visible nesting
--   only begins at 2 (compare SubunitDropdown.vue: `item.level ? item.level + 1
--   : 1`). Groups at level 0 with leaves at level 1 render as one flat list.
--   Groups are therefore level 1 and leaves level 2.
--
-- Side effects
--   Deletes the Organization row after nulling hs_hr_employee.work_station that
--   pointed at it. Does not otherwise change jobs or data-group scoping.
--   OrangeHRM's org UI expects a single root; after this run the five groups are
--   siblings with no root above them. CompanyStructureDao::setOrganizationName()
--   updates `WHERE level = 0`, so Admin > Organization > General Information can
--   no longer rename the tree — it matches no row and silently does nothing.
--   Log out and back in to refresh the cached tree.
--
-- Safety
--   Run against a backed-up database. Snapshot table is created once and is not
--   overwritten on re-run. A commented rollback block is at the end.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Preflight — review current tree before changing anything
-- ---------------------------------------------------------------------------
-- SHOW CREATE TABLE ohrm_subunit;
SELECT id, name, unit_id, lft, rgt, level
FROM ohrm_subunit
ORDER BY lft;

-- ---------------------------------------------------------------------------
-- 2. Snapshot (idempotent: does not overwrite an existing backup)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ohrm_subunit_backup_20260921 AS
SELECT * FROM ohrm_subunit WHERE 1 = 0;

INSERT INTO ohrm_subunit_backup_20260921
SELECT s.*
FROM ohrm_subunit s
WHERE NOT EXISTS (SELECT 1 FROM ohrm_subunit_backup_20260921 LIMIT 1);

-- ---------------------------------------------------------------------------
-- 3–6. Insert groups, clear Organization assignments, delete Organization,
--      apply nested-set layout
-- ---------------------------------------------------------------------------
START TRANSACTION;

-- 3. Insert the four new groups only when absent (avoids MySQL error 1093)
INSERT INTO ohrm_subunit (name, unit_id, description, lft, rgt, level)
SELECT 'Corporate Services', NULL, NULL, 0, 0, 1
FROM (SELECT 1 AS _) AS t
WHERE NOT EXISTS (
    SELECT 1 FROM ohrm_subunit WHERE name = 'Corporate Services'
);

INSERT INTO ohrm_subunit (name, unit_id, description, lft, rgt, level)
SELECT 'Technology', NULL, NULL, 0, 0, 1
FROM (SELECT 1 AS _) AS t
WHERE NOT EXISTS (
    SELECT 1 FROM ohrm_subunit WHERE name = 'Technology'
);

INSERT INTO ohrm_subunit (name, unit_id, description, lft, rgt, level)
SELECT 'Operations', NULL, NULL, 0, 0, 1
FROM (SELECT 1 AS _) AS t
WHERE NOT EXISTS (
    SELECT 1 FROM ohrm_subunit WHERE name = 'Operations'
);

INSERT INTO ohrm_subunit (name, unit_id, description, lft, rgt, level)
SELECT 'Commercial', NULL, NULL, 0, 0, 1
FROM (SELECT 1 AS _) AS t
WHERE NOT EXISTS (
    SELECT 1 FROM ohrm_subunit WHERE name = 'Commercial'
);

-- 4. Clear employees assigned to Organization before deleting the row
UPDATE hs_hr_employee
SET work_station = NULL
WHERE work_station IN (
    SELECT id FROM (
        SELECT id FROM ohrm_subunit WHERE name = 'Organization'
    ) AS org_ids
);

-- 5. Remove Organization root
DELETE FROM ohrm_subunit
WHERE name = 'Organization';

-- 6. Write final nested-set values (22 nodes; MAX(rgt) = 44; groups level 1,
--    leaves level 2 — see the header note on dropdown indentation)
--    Corporate Services 1/10  — EM 2/3, Finance 4/5, Accounting 6/7, HR 8/9
--    Technology 11/16         — Engineering 12/13, IT 14/15
--    Operations 17/24         — Inventory 18/19, Regional Ops 20/21, Asset Mgmt 22/23
--    Commercial 25/30         — Sales 26/27, Call Center 28/29
--    Healthcare 31/44         — Nursing 32/33 … Radiology 42/43
UPDATE ohrm_subunit
SET
    lft = CASE name
        WHEN 'Corporate Services' THEN 1
        WHEN 'Executive Management' THEN 2
        WHEN 'Finance' THEN 4
        WHEN 'Accounting' THEN 6
        WHEN 'Human Resources' THEN 8
        WHEN 'Technology' THEN 11
        WHEN 'Engineering' THEN 12
        WHEN 'Information Technology' THEN 14
        WHEN 'Operations' THEN 17
        WHEN 'Inventory' THEN 18
        WHEN 'Regional Operations' THEN 20
        WHEN 'Asset Management' THEN 22
        WHEN 'Commercial' THEN 25
        WHEN 'Sales' THEN 26
        WHEN 'Call Center' THEN 28
        WHEN 'Healthcare' THEN 31
        WHEN 'Nursing' THEN 32
        WHEN 'Doctors' THEN 34
        WHEN 'Students' THEN 36
        WHEN 'Nursing-ER' THEN 38
        WHEN 'Nursing-NICU' THEN 40
        WHEN 'Radiology' THEN 42
    END,
    rgt = CASE name
        WHEN 'Corporate Services' THEN 10
        WHEN 'Executive Management' THEN 3
        WHEN 'Finance' THEN 5
        WHEN 'Accounting' THEN 7
        WHEN 'Human Resources' THEN 9
        WHEN 'Technology' THEN 16
        WHEN 'Engineering' THEN 13
        WHEN 'Information Technology' THEN 15
        WHEN 'Operations' THEN 24
        WHEN 'Inventory' THEN 19
        WHEN 'Regional Operations' THEN 21
        WHEN 'Asset Management' THEN 23
        WHEN 'Commercial' THEN 30
        WHEN 'Sales' THEN 27
        WHEN 'Call Center' THEN 29
        WHEN 'Healthcare' THEN 44
        WHEN 'Nursing' THEN 33
        WHEN 'Doctors' THEN 35
        WHEN 'Students' THEN 37
        WHEN 'Nursing-ER' THEN 39
        WHEN 'Nursing-NICU' THEN 41
        WHEN 'Radiology' THEN 43
    END,
    level = CASE name
        WHEN 'Corporate Services' THEN 1
        WHEN 'Technology' THEN 1
        WHEN 'Operations' THEN 1
        WHEN 'Commercial' THEN 1
        WHEN 'Healthcare' THEN 1
        WHEN 'Executive Management' THEN 2
        WHEN 'Finance' THEN 2
        WHEN 'Accounting' THEN 2
        WHEN 'Human Resources' THEN 2
        WHEN 'Engineering' THEN 2
        WHEN 'Information Technology' THEN 2
        WHEN 'Inventory' THEN 2
        WHEN 'Regional Operations' THEN 2
        WHEN 'Asset Management' THEN 2
        WHEN 'Sales' THEN 2
        WHEN 'Call Center' THEN 2
        WHEN 'Nursing' THEN 2
        WHEN 'Doctors' THEN 2
        WHEN 'Students' THEN 2
        WHEN 'Nursing-ER' THEN 2
        WHEN 'Nursing-NICU' THEN 2
        WHEN 'Radiology' THEN 2
    END
WHERE name IN (
    'Corporate Services', 'Executive Management', 'Finance', 'Accounting', 'Human Resources',
    'Technology', 'Engineering', 'Information Technology',
    'Operations', 'Inventory', 'Regional Operations', 'Asset Management',
    'Commercial', 'Sales', 'Call Center',
    'Healthcare', 'Nursing', 'Doctors', 'Students', 'Nursing-ER', 'Nursing-NICU', 'Radiology'
);

COMMIT;

-- ---------------------------------------------------------------------------
-- 7. Verification
-- ---------------------------------------------------------------------------
-- Expect: COUNT(*) = 22, MAX(rgt) = 44, five roots at level 1, 17 leaves at
-- level 2, nothing left at level 0, no Organization
SELECT
    COUNT(*) AS node_count,
    MAX(rgt) AS max_rgt,
    (2 * COUNT(*)) AS expected_max_rgt,
    SUM(CASE WHEN level = 1 THEN 1 ELSE 0 END) AS root_count,
    SUM(CASE WHEN level = 2 THEN 1 ELSE 0 END) AS leaf_count,
    SUM(CASE WHEN level = 0 THEN 1 ELSE 0 END) AS level_zero_rows,
    SUM(CASE WHEN name = 'Organization' THEN 1 ELSE 0 END) AS organization_rows
FROM ohrm_subunit;

-- Expect: empty (no broken intervals)
SELECT id, name, lft, rgt
FROM ohrm_subunit
WHERE rgt <= lft;

-- Expect: empty (no duplicate lft)
SELECT lft, COUNT(*) AS cnt
FROM ohrm_subunit
GROUP BY lft
HAVING COUNT(*) > 1;

-- Expect: empty (no duplicate rgt)
SELECT rgt, COUNT(*) AS cnt
FROM ohrm_subunit
GROUP BY rgt
HAVING COUNT(*) > 1;

-- Rendered tree
SELECT CONCAT(REPEAT('  ', level - 1), name) AS tree, id, lft, rgt, level
FROM ohrm_subunit
ORDER BY lft;

-- ---------------------------------------------------------------------------
-- 8. Rollback (commented — restore from snapshot and remove inserted groups)
-- ---------------------------------------------------------------------------
/*
START TRANSACTION;

DELETE FROM ohrm_subunit
WHERE name IN ('Corporate Services', 'Technology', 'Operations', 'Commercial');

-- Restore every snapshot row (including Organization) by primary key
REPLACE INTO ohrm_subunit
SELECT * FROM ohrm_subunit_backup_20260921;

-- If any leaf was updated in place rather than deleted, realign from snapshot
UPDATE ohrm_subunit s
INNER JOIN ohrm_subunit_backup_20260921 b ON b.id = s.id
SET s.lft = b.lft, s.rgt = b.rgt, s.level = b.level, s.unit_id = b.unit_id, s.description = b.description;

COMMIT;

-- The snapshot is the original level-0-root shape, so indent from level here
SELECT CONCAT(REPEAT('  ', level), name) AS tree, id, lft, rgt, level
FROM ohrm_subunit
ORDER BY lft;
*/
