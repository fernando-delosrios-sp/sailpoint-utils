-- =============================================================================
-- OrangeHRM: company root, Executive Management under Corporate Services
-- =============================================================================
-- CompanyStructureService::getSubunitArray() drops the first subunit and copies
-- `level` onto `_indent`. Indent 1 is flush left. With no level-0 row, Corporate
-- Services is that first node, so the Sub Unit dropdown hides it.
--
-- This script keeps the company name from ohrm_organization_gen_info at level 0
-- (id 1 when that id is free). The dropdown hides that row. The five groups stay
-- level 1, and Executive Management stays a level-2 leaf of Corporate Services,
-- as in 20260921_subunit_five_groups.sql. Employee work_station ids are unchanged.
--
-- Idempotent. Do not re-run 20260921_subunit_five_groups.sql afterwards: its
-- nested-set rewrite overlaps this root.
-- =============================================================================

START TRANSACTION;

INSERT INTO ohrm_subunit (id, name, unit_id, description, lft, rgt, level)
SELECT 1, g.name, NULL, NULL, 0, 0, 0
FROM ohrm_organization_gen_info g
WHERE NOT EXISTS (SELECT 1 FROM ohrm_subunit WHERE level = 0)
  AND NOT EXISTS (SELECT 1 FROM ohrm_subunit WHERE id = 1)
LIMIT 1;

INSERT INTO ohrm_subunit (name, unit_id, description, lft, rgt, level)
SELECT g.name, NULL, NULL, 0, 0, 0
FROM ohrm_organization_gen_info g
WHERE NOT EXISTS (SELECT 1 FROM ohrm_subunit WHERE level = 0)
  AND NOT EXISTS (SELECT 1 FROM ohrm_subunit WHERE name = g.name)
LIMIT 1;

UPDATE ohrm_subunit s
JOIN ohrm_organization_gen_info g ON g.id = 1
SET s.name = g.name
WHERE s.level = 0
  AND s.name <> g.name;

UPDATE ohrm_subunit s
JOIN ohrm_organization_gen_info g ON g.id = 1
SET
    s.lft = CASE s.name
        WHEN g.name THEN 1
        WHEN 'Corporate Services' THEN 2
        WHEN 'Executive Management' THEN 3
        WHEN 'Finance' THEN 5
        WHEN 'Accounting' THEN 7
        WHEN 'Human Resources' THEN 9
        WHEN 'Technology' THEN 12
        WHEN 'Engineering' THEN 13
        WHEN 'Information Technology' THEN 15
        WHEN 'Operations' THEN 18
        WHEN 'Inventory' THEN 19
        WHEN 'Regional Operations' THEN 21
        WHEN 'Asset Management' THEN 23
        WHEN 'Commercial' THEN 26
        WHEN 'Sales' THEN 27
        WHEN 'Call Center' THEN 29
        WHEN 'Healthcare' THEN 32
        WHEN 'Nursing' THEN 33
        WHEN 'Doctors' THEN 35
        WHEN 'Students' THEN 37
        WHEN 'Nursing-ER' THEN 39
        WHEN 'Nursing-NICU' THEN 41
        WHEN 'Radiology' THEN 43
    END,
    s.rgt = CASE s.name
        WHEN g.name THEN 46
        WHEN 'Corporate Services' THEN 11
        WHEN 'Executive Management' THEN 4
        WHEN 'Finance' THEN 6
        WHEN 'Accounting' THEN 8
        WHEN 'Human Resources' THEN 10
        WHEN 'Technology' THEN 17
        WHEN 'Engineering' THEN 14
        WHEN 'Information Technology' THEN 16
        WHEN 'Operations' THEN 25
        WHEN 'Inventory' THEN 20
        WHEN 'Regional Operations' THEN 22
        WHEN 'Asset Management' THEN 24
        WHEN 'Commercial' THEN 31
        WHEN 'Sales' THEN 28
        WHEN 'Call Center' THEN 30
        WHEN 'Healthcare' THEN 45
        WHEN 'Nursing' THEN 34
        WHEN 'Doctors' THEN 36
        WHEN 'Students' THEN 38
        WHEN 'Nursing-ER' THEN 40
        WHEN 'Nursing-NICU' THEN 42
        WHEN 'Radiology' THEN 44
    END,
    s.level = CASE s.name
        WHEN g.name THEN 0
        WHEN 'Corporate Services' THEN 1
        WHEN 'Technology' THEN 1
        WHEN 'Operations' THEN 1
        WHEN 'Commercial' THEN 1
        WHEN 'Healthcare' THEN 1
        ELSE 2
    END
WHERE s.name = g.name
   OR s.name IN (
        'Executive Management', 'Corporate Services', 'Finance', 'Accounting', 'Human Resources',
        'Technology', 'Engineering', 'Information Technology',
        'Operations', 'Inventory', 'Regional Operations', 'Asset Management',
        'Commercial', 'Sales', 'Call Center',
        'Healthcare', 'Nursing', 'Doctors', 'Students', 'Nursing-ER', 'Nursing-NICU', 'Radiology'
    );

COMMIT;

-- Expect: parent Corporate Services, level 2.
SELECT
    c.name,
    c.level,
    p.name AS parent_name
FROM ohrm_subunit c
LEFT JOIN ohrm_subunit p
    ON p.lft < c.lft AND p.rgt > c.rgt AND p.level = c.level - 1
WHERE c.name = 'Executive Management';
